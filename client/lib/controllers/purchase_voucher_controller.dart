import 'dart:async';
import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/charge_constants.dart';
import '../models/product_model.dart';
import '../models/purchase_order_model.dart';
import '../theme/app_colors.dart';
import 'purchase_voucher_list_controller.dart';

class PurchaseVoucherController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? voucherId;
  final bool? startInReportMode;
  final activeVoucherId = RxnInt();
  final status = 'DRAFT'.obs;
  final viewOnly = false.obs;

  // Header
  final docNoPrefix = '25-26/'.obs;
  final docNoNumber = ''.obs;
  final vendorId = Rxn<int>();
  final vendorName = ''.obs;
  final docDate = ''.obs;
  final billNo = ''.obs;
  final narration = ''.obs;
  final doNotUpdateInventory = false.obs;
  final purchaseType = 'Regular'.obs;
  final gstReverseCharge = 'N'.obs;
  final billDate = ''.obs;
  final purchaseAgentId = ''.obs;

  // Master data
  final suppliers = <Map<String, dynamic>>[].obs;
  final salesmen = <Map<String, dynamic>>[].obs;
  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;
  static const List<String> chargeTypeNames = addonChargeTypeNames;

  final items = <PVItemRow>[].obs;
  final charges = <PVChargeRow>[].obs;

  /// Linked purchase orders for this voucher.
  final linkedPurchaseOrderIds = <int>[].obs;
  final linkedPoNumbers = <String>[].obs;

  /// Controls whether product searches show only vendor-assigned products
  /// (via /supplier-products) or the full product catalogue.
  final showAllProducts = false.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final _productTaxCache = <int, List<Map<String, dynamic>>>{};
  final Map<PVItemRow, Timer> _quantityValidationTimers = {};

  /// Parsed numeric sequence from docNoNumber/docNo used for navigation.
  final RxnInt currentSeq = RxnInt();

  PurchaseVoucherController({this.voucherId, this.startInReportMode});

  int? _safeInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  @override
  void onInit() {
    super.onInit();
    activeVoucherId.value = voucherId;
    viewOnly.value = startInReportMode ?? false;
    _loadSuppliers();
    _loadSalesmen();
    _loadUnitTypes();
    _loadProducts();
    if (voucherId == null) {
      docDate.value = _formatDate(DateTime.now());
      _loadNextDocNoNumberForNew();
      addItemRow();
      addChargeRow();
    } else {
      _loadVoucherData();
    }
  }

  bool get isEditMode => activeVoucherId.value != null;
  bool get isReportMode => viewOnly.value;
  bool get canEditFromReport => isReportMode && status.value.toUpperCase() == 'DRAFT';

  void enterEditMode() {
    viewOnly.value = false;
  }

  bool _isFixedTaxKey(String key) {
    final normalized = key.trim().toUpperCase();
    return normalized == 'SGST' ||
        normalized == 'CGST' ||
        normalized == 'IGST' ||
        normalized == 'CESS' ||
        normalized == 'ROFF';
  }

  double _customTaxTotalFromKeys(PVItemRow row, double taxable) {
    if (taxable <= 0) return 0;
    var total = 0.0;
    for (final key in row.availableTaxKeys) {
      if (_isFixedTaxKey(key)) continue;
      final percent = double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
      if (percent <= 0) continue;
      total += taxable * percent / 100;
    }
    return total;
  }

  String get netTotal {
    double itemsTotal = 0;
    for (var row in items) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final price = double.tryParse(row.unitPrice.value) ?? 0;
      final taxable = qty * price;
      final sgst = double.tryParse(row.sgst.value) ?? 0;
      final cgst = double.tryParse(row.cgst.value) ?? 0;
      final igst = double.tryParse(row.igst.value) ?? 0;
      final cess = double.tryParse(row.cess.value) ?? 0;
      final roff = double.tryParse(row.roff.value) ?? 0;
      final customTaxes = _customTaxTotalFromKeys(row, taxable);
      itemsTotal += taxable + sgst + cgst + igst + cess + roff + customTaxes;
    }
    double chargesTotal = 0;
    for (var row in charges) {
      final amt = double.tryParse(row.amount.value) ?? 0;
      final name = row.name.value.toLowerCase();
      chargesTotal += name.contains('discount') ? -amt : amt;
    }
    return (itemsTotal + chargesTotal).toStringAsFixed(3);
  }

  void recalcItemRow(PVItemRow row) {
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final price = double.tryParse(row.unitPrice.value) ?? 0;
    row.taxableAmount.value = (qty * price).toStringAsFixed(2);

    if (row.autoTaxRecompute.value) {
      final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
      row.sgst.value = _taxAmountFromPercent(taxable, row.sgstPercent.value);
      row.cgst.value = _taxAmountFromPercent(taxable, row.cgstPercent.value);
      row.igst.value = _taxAmountFromPercent(taxable, row.igstPercent.value);
      row.cess.value = _taxAmountFromPercent(taxable, row.cessPercent.value);
      row.roff.value = _taxAmountFromPercent(taxable, row.roffPercent.value);
    }

    final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
    final sgst = double.tryParse(row.sgst.value) ?? 0;
    final cgst = double.tryParse(row.cgst.value) ?? 0;
    final igst = double.tryParse(row.igst.value) ?? 0;
    final cess = double.tryParse(row.cess.value) ?? 0;
    final roff = double.tryParse(row.roff.value) ?? 0;
    final customTaxes = _customTaxTotalFromKeys(row, taxable);
    final value = taxable + sgst + cgst + igst + cess + roff + customTaxes;
    row.value.value = value.toStringAsFixed(2);
  }

  void scheduleQuantityValidation(PVItemRow row) {
    _quantityValidationTimers[row]?.cancel();
    _quantityValidationTimers[row] = Timer(const Duration(milliseconds: 450), () async {
      if (Get.isDialogOpen == true) return;
      await onQuantityEditCompleted(row);
    });
  }

  bool _isLinkedOverrun(PVItemRow row) {
    if (row.sourcePurchaseOrderItemId.value == null) return false;
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
    return qty > left + 0.0000001;
  }

  double _availableWriteoffQty(PVItemRow row) {
    if (row.sourcePurchaseOrderItemId.value == null) return 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final remainingAfterReceipt = left - qty;
    return remainingAfterReceipt > 0 ? remainingAfterReceipt : 0;
  }

  Future<void> openWriteOffDialog(PVItemRow row, {bool writeAll = false}) async {
    if (row.sourcePurchaseOrderItemId.value == null) {
      _showError('Write off is available only for linked PO lines');
      return;
    }

    final maxQty = _availableWriteoffQty(row);
    if (maxQty <= 0.0000001) {
      _showError('No remaining quantity available for write off');
      return;
    }

    if (writeAll) {
      row.writeoffQty.value = maxQty.toStringAsFixed(3);
      row.isWriteoff.value = maxQty > 0;
      return;
    }

    final qtyController = TextEditingController(
      text: (double.tryParse(row.writeoffQty.value) ?? 0) > 0
          ? (double.tryParse(row.writeoffQty.value) ?? 0).toStringAsFixed(3)
          : maxQty.toStringAsFixed(3),
    );
    final reasonController = TextEditingController(text: row.writeoffReason.value);

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: const Text('Write Off Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remaining available: ${maxQty.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
              ],
              decoration: const InputDecoration(labelText: 'Write Off Qty'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: {'clear': true}),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Get.back(result: {'qty': maxQty, 'reason': reasonController.text}),
            child: const Text('Write Off All'),
          ),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text.trim()) ?? 0;
              Get.back(result: {'qty': qty, 'reason': reasonController.text});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    qtyController.dispose();
    reasonController.dispose();

    if (result == null) return;
    if (result['clear'] == true) {
      row.writeoffQty.value = '0';
      row.isWriteoff.value = false;
      row.writeoffReason.value = '';
      return;
    }

    final qty = ((result['qty'] as num?)?.toDouble()) ?? 0;
    if (qty <= 0.0000001) {
      row.writeoffQty.value = '0';
      row.isWriteoff.value = false;
      row.writeoffReason.value = '';
      return;
    }
    if (qty > maxQty + 0.0000001) {
      _showError('Write off cannot exceed ${maxQty.toStringAsFixed(3)} for this line');
      return;
    }

    row.writeoffQty.value = qty.toStringAsFixed(3);
    row.isWriteoff.value = true;
    row.writeoffReason.value = (result['reason']?.toString() ?? '').trim();
  }

  Future<void> onQuantityEditCompleted(PVItemRow row) async {
    if (row.sourcePurchaseOrderItemId.value == null) {
      row.isOverrunApproved.value = false;
      row.overrunQty.value = '0';
      row.overrunReason.value = '';
      row.lastAcceptedQuantity.value = row.quantity.value;
      return;
    }

    final qty = double.tryParse(row.quantity.value) ?? 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
    final used = double.tryParse(row.usedQty.value) ?? 0;
    if (qty <= left + 0.0000001) {
      row.isOverrunApproved.value = false;
      row.overrunQty.value = '0';
      row.overrunReason.value = '';
      row.lastAcceptedQuantity.value = row.quantity.value;
      return;
    }

    final overrun = qty - left;
    final accepted = await Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Quantity above PO balance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  row.productName.value.trim().isEmpty
                      ? 'This line exceeds the remaining PO quantity.'
                      : '${row.productName.value.trim()} exceeds the remaining PO quantity.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      _QuantitySummaryTile(label: 'Allowed left', value: left.toStringAsFixed(1), accent: AppColors.primaryDark),
                      const SizedBox(height: 8),
                      _QuantitySummaryTile(label: 'Entered now', value: qty.toStringAsFixed(1), accent: AppColors.primaryDark),
                      const SizedBox(height: 8),
                      _QuantitySummaryTile(label: 'Over by', value: overrun.toStringAsFixed(1), accent: Colors.deepOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Keep PO limit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Get.back(result: true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                        child: const Text('Accept over quantity'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (accepted == true) {
      row.isOverrunApproved.value = true;
      row.overrunQty.value = overrun.toStringAsFixed(3);
      row.lastAcceptedQuantity.value = row.quantity.value;
      return;
    }

    final fallback = row.lastAcceptedQuantity.value.trim().isNotEmpty
        ? row.lastAcceptedQuantity.value
        : left.toStringAsFixed(3);
    row.setQuantity(fallback);
    row.isOverrunApproved.value = false;
    row.overrunQty.value = '0';
    row.overrunReason.value = '';
    recalcItemRow(row);
  }

  @override
  void onClose() {
    for (final timer in _quantityValidationTimers.values) {
      timer.cancel();
    }
    _quantityValidationTimers.clear();
    for (final row in items) {
      row.dispose();
    }
    super.onClose();
  }

  String _taxAmountFromPercent(double taxable, String percentRaw) {
    final percent = double.tryParse(percentRaw) ?? 0;
    if (taxable <= 0 || percent <= 0) return '';
    return (taxable * percent / 100).toStringAsFixed(2);
  }

  void onTaxAmountManuallyChanged(PVItemRow row, String key, String value) {
    final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
    final amount = double.tryParse(value) ?? 0;
    final percent = (taxable > 0 && amount > 0) ? (amount * 100 / taxable) : 0;

    switch (key.toUpperCase()) {
      case 'SGST':
        row.sgstPercent.value = percent.toStringAsFixed(4);
        row.taxFieldValues['SGST'] = row.sgstPercent.value;
        break;
      case 'CGST':
        row.cgstPercent.value = percent.toStringAsFixed(4);
        row.taxFieldValues['CGST'] = row.cgstPercent.value;
        break;
      case 'IGST':
        row.igstPercent.value = percent.toStringAsFixed(4);
        row.taxFieldValues['IGST'] = row.igstPercent.value;
        break;
      case 'CESS':
        row.cessPercent.value = percent.toStringAsFixed(4);
        row.taxFieldValues['CESS'] = row.cessPercent.value;
        break;
      case 'ROFF':
      case 'ROUND':
        row.roffPercent.value = percent.toStringAsFixed(4);
        row.taxFieldValues['ROFF'] = row.roffPercent.value;
        break;
    }

    row.autoTaxRecompute.value = true;
    recalcItemRow(row);
  }

  /// Resolves voucher line taxes only from product_taxes for selected product.
  Future<void> applyResolvedTaxesToVoucherRow(
    PVItemRow row, {
    required int productId,
  }) async {
    _clearVoucherTaxBreakdown(row);

    final productTaxes = await _fetchProductTaxRows(productId);
    final applied = _applyTaxRowsToVoucherAmounts(row, productTaxes);

    if (!applied) {
      recalcItemRow(row);
    }
  }

  void _clearVoucherTaxBreakdown(PVItemRow row) {
    row.sgst.value = '';
    row.cgst.value = '';
    row.igst.value = '';
    row.cess.value = '';
    row.roff.value = '';
    row.sgstPercent.value = '';
    row.cgstPercent.value = '';
    row.igstPercent.value = '';
    row.cessPercent.value = '';
    row.roffPercent.value = '';
    row.autoTaxRecompute.value = false;
    row.taxFieldValues.clear();
    row.availableTaxKeys.clear();
  }

  bool _applyTaxRowsToVoucherAmounts(
    PVItemRow row,
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return false;

    var applied = false;
    final fixedKeys = <String>{};
    final customKeys = <String>[];

    for (final map in rows) {
      final tax = map['tax'] as Map<String, dynamic>?;
      final rawName = (tax?['tax_name'] ?? map['tax_name'] ?? '').toString().trim();
      final rawSub = (tax?['tax_sub_category'] ?? map['tax_sub_category'] ?? '')
          .toString()
          .trim();
      final taxName = rawName.toUpperCase();
      final taxSub = rawSub.toUpperCase();
      final percent = (map['tax_percent'] ?? 0) is num
          ? (map['tax_percent'] as num).toDouble()
          : double.tryParse(map['tax_percent']?.toString() ?? '') ?? 0;
      if (percent <= 0) continue;

      final canonical = _canonicalTaxKey(taxName, taxSub);
      final label = canonical ??
          (rawName.isNotEmpty
              ? rawName
              : (rawSub.isNotEmpty ? rawSub : 'Tax'));
      row.taxFieldValues[label] = percent.toStringAsFixed(2);

      if (canonical == null && !customKeys.contains(label)) {
        customKeys.add(label);
      }

      if (canonical == 'SGST') {
        row.sgstPercent.value = percent.toStringAsFixed(4);
        fixedKeys.add('SGST');
        applied = true;
      } else if (canonical == 'CGST') {
        row.cgstPercent.value = percent.toStringAsFixed(4);
        fixedKeys.add('CGST');
        applied = true;
      } else if (canonical == 'IGST') {
        row.igstPercent.value = percent.toStringAsFixed(4);
        fixedKeys.add('IGST');
        applied = true;
      } else if (canonical == 'CESS') {
        row.cessPercent.value = percent.toStringAsFixed(4);
        fixedKeys.add('CESS');
        applied = true;
      } else if (canonical == 'ROFF') {
        row.roffPercent.value = percent.toStringAsFixed(4);
        fixedKeys.add('ROFF');
        applied = true;
      } else {
        applied = true;
      }
    }

    if (applied) {
      final ordered = ['SGST', 'CGST', 'IGST', 'CESS', 'ROFF']
          .where(fixedKeys.contains)
          .toList();
      ordered.addAll(customKeys);
      row.availableTaxKeys.assignAll(ordered);
      row.autoTaxRecompute.value = true;
      recalcItemRow(row);
    }
    return applied;
  }

  bool _matchesTax(String taxName, String taxSub, String key) {
    return taxName.contains(key) || taxSub.contains(key);
  }

  String? _canonicalTaxKey(String taxName, String taxSub) {
    if (_matchesTax(taxName, taxSub, 'SGST')) return 'SGST';
    if (_matchesTax(taxName, taxSub, 'CGST')) return 'CGST';
    if (_matchesTax(taxName, taxSub, 'IGST')) return 'IGST';
    if (_matchesTax(taxName, taxSub, 'CESS')) return 'CESS';
    if (_matchesTax(taxName, taxSub, 'ROFF') || taxName.contains('ROUND')) {
      return 'ROFF';
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchProductTaxRows(int productId) async {
    final cached = _productTaxCache[productId];
    if (cached != null) return cached;

    final uri = Uri.parse(ApiConfig.productTaxes).replace(
      queryParameters: {'product_id': productId.toString(), 'limit': '100'},
    );
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    final List list = data['data'] ?? [];
    final rows = list
        .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _productTaxCache[productId] = rows;
    return rows;
  }


  Future<void> _loadVoucherData() async {
    final id = activeVoucherId.value;
    if (id == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseVouchers}/$id'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final vData = data['data'] as Map<String, dynamic>?;
          _applyVoucherData(vData);
        }
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Load failed: $e');
      _showError('Failed to load voucher data');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.suppliers),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          suppliers.value = list
              .map((e) => {
                    'id': (e as Map)['id'],
                    'supplier_code': (e)['supplier_code']?.toString(),
                    'supplier_name': (e)['supplier_name']?.toString() ?? (e)['name']?.toString(),
                  })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Suppliers error: $e');
    }
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.unitTypes),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List types = data['data'] ?? [];
          unitTypes.value = types.cast<String>();
        }
      }
    } catch (_) {
      unitTypes.value = ['Nos', 'KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  Future<void> _loadSalesmen() async {
    try {
      Future<List<Map<String, dynamic>>> fetch(Uri uri) async {
        final response = await http.get(
          uri,
          headers: {'Accept': 'application/json'},
        );
        if (response.statusCode != 200) return [];
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return [];
        final List list = data['data'] ?? [];
        return list
            .map((e) => {
                  'id': (e as Map)['id']?.toString(),
                  'name': (e)['name']?.toString() ?? 'User ${(e)['id'] ?? ''}',
                })
            .where((e) => (e['id'] ?? '').toString().isNotEmpty)
            .toList();
      }

      final filteredUri = Uri.parse(ApiConfig.users)
          .replace(queryParameters: {'role': 'Salesman', 'limit': '500'});
      var list = await fetch(filteredUri);
      if (list.isEmpty) {
        final fallbackUri =
            Uri.parse(ApiConfig.users).replace(queryParameters: {'limit': '500'});
        list = await fetch(fallbackUri);
      }
      salesmen.value = list;
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Salesmen error: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?limit=50'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Products error: $e');
    }
  }

  /// For a brand new purchase voucher, fetch the latest existing voucher and
  /// set [docNoNumber] to the next consecutive number.
  Future<void> _loadNextDocNoNumberForNew() async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseVouchers).replace(
        queryParameters: {
          'limit': '1',
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final List list = data['data'] ?? [];
      if (list.isEmpty) {
        docNoNumber.value = '1';
        currentSeq.value = 1;
        return;
      }
      final last = list.first as Map<String, dynamic>;
      // Prefer explicit doc_no_number, then numeric suffix of doc_no, then id.
      final base = _sequenceFromVoucherSummary(last);
      final next = (base ?? 0) + 1;
      docNoNumber.value = next.toString();
      currentSeq.value = next;
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Next doc no error: $e');
    }
  }

  int? _sequenceFromVoucherSummary(Map<String, dynamic> summary) {
    int? base = int.tryParse(summary['doc_no_number']?.toString() ?? '');
    if (base == null) {
      final rawDoc = summary['doc_no']?.toString();
      if (rawDoc != null && rawDoc.isNotEmpty) {
        final match = RegExp(r'(\d+)$').firstMatch(rawDoc);
        if (match != null) {
          base = int.tryParse(match.group(1)!);
        }
      }
    }
    base ??= (summary['id'] is int)
        ? summary['id'] as int
        : int.tryParse(summary['id']?.toString() ?? '');
    return base;
  }

  Future<int?> _fetchLatestVoucherSequence() async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseVouchers).replace(
        queryParameters: {
          'limit': '1',
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      final List list = data['data'] ?? [];
      if (list.isEmpty) return null;
      final last = list.first as Map<String, dynamic>;
      return _sequenceFromVoucherSummary(last);
    } catch (_) {
      return null;
    }
  }

  Future<void> _resetToNewVoucherForm() async {
    activeVoucherId.value = null;
    docNoPrefix.value = '25-26/';
    docNoNumber.value = '';
    vendorId.value = null;
    vendorName.value = '';
    docDate.value = _formatDate(DateTime.now());
    billNo.value = '';
    narration.value = '';
    doNotUpdateInventory.value = false;
    purchaseType.value = 'Regular';
    gstReverseCharge.value = 'N';
    billDate.value = '';
    purchaseAgentId.value = '';
    linkedPurchaseOrderIds.clear();
    linkedPoNumbers.clear();
    _productTaxCache.clear();

    items.clear();
    charges.clear();
    addItemRow();
    addChargeRow();

    await _loadNextDocNoNumberForNew();
  }

  /// Load products for the current vendor.
  /// If [includeAll] is false and a vendor is selected, we hit /supplier-products
  /// so that only products assigned to that vendor are returned. Otherwise we
  /// fall back to the generic /products list.
  Future<void> loadProductsForVendor({
    String? search,
    bool? includeAll,
  }) async {
    final useAll = includeAll ?? showAllProducts.value;
    final vendor = vendorId.value;

    if (!useAll && vendor != null) {
      try {
        final uri = Uri.parse(ApiConfig.supplierProducts).replace(
          queryParameters: {
            'limit': '50',
            'supplier_id': vendor.toString(),
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        );
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          debugPrint(
              '[PURCHASE_VOUCHER] Vendor products status ${response.statusCode}');
          return;
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] != true) return;
        final List data = decoded['data'] ?? [];
        products.value = data
            .map<Product?>((e) {
              final map = e as Map<String, dynamic>;
              final dynamic productRaw = map['product'];
              final product =
                  productRaw is Map<String, dynamic> ? productRaw : null;
              final id = _safeInt(
                map['product_id'] ?? product?['product_id'] ?? product?['id'],
              );
              if (id == null) return null;

              final name = product?['name']?.toString() ??
                  map['product_name']?.toString() ??
                  map['supplier_product_name']?.toString() ??
                  'Product $id';

                List<ProductTaxInfo> parseTaxes(dynamic raw) {
                if (raw is! List) return const [];
                return raw
                  .whereType<Map>()
                  .map((item) => ProductTaxInfo.fromJson(
                    Map<String, dynamic>.from(item)))
                  .toList();
                }

              return Product(
                id: id,
                name: name,
                code: product?['product_code']?.toString(),
                hsnCode: product?['hsn_code']?.toString() ??
                    map['hsn_code']?.toString() ??
                    map['hsn']?.toString(),
                productType: (product?['product_type'] ?? 'SINGLE')
                    .toString()
                    .toUpperCase(),
                defaultUnit: product?['default_unit']?.toString(),
                taxes: parseTaxes(product?['taxes'] ?? map['taxes']),
              );
            })
            .whereType<Product>()
            .toList();
        return;
      } catch (e) {
        debugPrint('[PURCHASE_VOUCHER] Vendor products error: $e');
        // fall through to all-products load
      }
    }

    // Fallback: generic products list (optionally filtered by search).
    try {
      final base = ApiConfig.products;
      final uri = search != null && search.trim().isNotEmpty
          ? Uri.parse(base).replace(
              queryParameters: {
                'limit': '50',
                'search': search.trim(),
              },
            )
          : Uri.parse('$base?limit=50');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Products error: $e');
    }
  }

  void _applyVoucherData(Map<String, dynamic>? vData) {
    if (vData == null) return;
    linkedPurchaseOrderIds.clear();
    linkedPoNumbers.clear();
    final v = vData['voucher'] as Map<String, dynamic>?;
    if (v != null) {
      final idRaw = v['id'];
      activeVoucherId.value = idRaw is int
          ? idRaw
          : int.tryParse(idRaw?.toString() ?? '');
      docNoPrefix.value = v['doc_no_prefix']?.toString() ?? '25-26/';
      docNoNumber.value = v['doc_no_number']?.toString() ?? '';
      // update numeric sequence from docNoNumber or doc_no
      int? base = int.tryParse(docNoNumber.value);
      if (base == null) {
        final raw = v['doc_no']?.toString();
        if (raw != null && raw.isNotEmpty) {
          final match = RegExp(r'(\d+)$').firstMatch(raw);
          if (match != null) {
            base = int.tryParse(match.group(1)!);
          }
        }
      }
      currentSeq.value = base;

      vendorId.value = int.tryParse(v['vendor_id']?.toString() ?? v['supplier_id']?.toString() ?? '');
      vendorName.value = v['vendor_name']?.toString() ?? v['supplier_name']?.toString() ?? '';
      docDate.value = v['doc_date']?.toString().split(' ').first ?? _formatDate(DateTime.now());
      billNo.value = v['bill_no']?.toString() ?? '';
      narration.value = v['narration']?.toString() ?? '';
      doNotUpdateInventory.value = v['do_not_update_inventory'] == true;
      purchaseType.value = v['purchase_type']?.toString() ?? 'Regular';
      gstReverseCharge.value = v['gst_reverse_charge']?.toString() ?? 'N';
      billDate.value = v['bill_date']?.toString() ?? '';
      purchaseAgentId.value = v['purchase_agent_id']?.toString() ?? '';
      status.value = v['status']?.toString() ?? 'DRAFT';

      final headerPoId = int.tryParse(v['purchase_order_id']?.toString() ?? '');
      if (headerPoId != null && !linkedPurchaseOrderIds.contains(headerPoId)) {
        linkedPurchaseOrderIds.add(headerPoId);
      }
    }

    final itemsData = (vData['items'] as List?) ?? [];
    for (final row in items) {
      row.dispose();
    }
    items.clear();
    for (var item in itemsData) {
      final map = item as Map<String, dynamic>;
      final row = PVItemRow();
      final srcPoId = int.tryParse(map['source_purchase_order_id']?.toString() ?? '');
      final srcPoItemId = int.tryParse(map['source_purchase_order_item_id']?.toString() ?? '');
      final srcPoNo = map['source_po_number']?.toString() ?? '';
      row.sourcePurchaseOrderId.value = srcPoId;
      row.sourcePurchaseOrderItemId.value = srcPoItemId;
      row.sourcePoNumber.value = srcPoNo;
      if (srcPoId != null && !linkedPurchaseOrderIds.contains(srcPoId)) {
        linkedPurchaseOrderIds.add(srcPoId);
      }
      if (srcPoNo.isNotEmpty && !linkedPoNumbers.contains(srcPoNo)) {
        linkedPoNumbers.add(srcPoNo);
      }
      final pid = int.tryParse(map['product_id']?.toString() ?? '');
      if (pid != null) {
        row.product.value = Product(
          id: pid,
          name: map['product_name']?.toString() ?? '',
          hsnCode: map['hsn_code']?.toString() ?? map['hsn']?.toString(),
          productType: 'SINGLE',
        );
      }
      row.productCode.value = map['product_code']?.toString() ?? '';
      row.hsnCode.value = map['hsn_code']?.toString() ?? map['hsn']?.toString() ?? '';
      row.productName.value = map['product_name']?.toString() ?? '';
      row.alias.value = map['alias']?.toString() ?? '';
      row.setQuantity(map['quantity']?.toString() ?? '');
      row.lastAcceptedQuantity.value = row.quantity.value;
      row.unitType.value = map['unit']?.toString() ?? 'Nos';
      row.unitPrice.value = map['unit_price']?.toString() ?? '0';
      row.orderedQty.value = map['ordered_qty']?.toString() ?? map['po_ordered_qty']?.toString() ?? '';
      row.usedQty.value = map['used_qty']?.toString() ?? map['po_used_qty']?.toString() ?? '';
      row.leftQty.value = map['left_qty']?.toString() ?? map['po_left_qty']?.toString() ?? '';
      row.isOverrunApproved.value = map['is_overrun_approved'] == true;
      row.overrunQty.value = map['overrun_qty']?.toString() ?? '0';
      row.overrunReason.value = map['overrun_reason']?.toString() ?? '';
      row.writeoffQty.value = map['writeoff_qty']?.toString() ?? '0';
      row.isWriteoff.value = map['is_writeoff'] == true;
      row.writeoffReason.value = map['writeoff_reason']?.toString() ?? '';
      row.taxableAmount.value = map['taxable_amount']?.toString() ?? '0';
      row.sgst.value = map['sgst']?.toString() ?? '0';
      row.cgst.value = map['cgst']?.toString() ?? '0';
      row.igst.value = map['igst']?.toString() ?? '0';
      row.cess.value = map['cess']?.toString() ?? '0';
      row.roff.value = map['roff']?.toString() ?? '0';
      _deriveTaxPercentsFromCurrentAmounts(row);
      _syncAvailableTaxKeysFromCurrentValues(row);
      row.value.value = map['value']?.toString() ?? '0';
      row.purchaseAccount.value = map['purchase_account']?.toString() ?? 'Def Purchase Accounts';
      row.gstItcEligibility.value = map['gst_itc_eligibility']?.toString() ?? '';
      items.add(row);
    }

    final chargesData = (vData['charges'] as List?) ?? [];
    charges.clear();
    for (var ch in chargesData) {
      final map = ch as Map<String, dynamic>;
      final row = PVChargeRow();
      row.name.value = map['name']?.toString() ?? 'Others';
      row.amount.value = map['amount']?.toString() ?? '0';
      row.remarks.value = map['remarks']?.toString() ?? '';
      charges.add(row);
    }
    if (items.isEmpty) addItemRow();
    if (charges.isEmpty) addChargeRow();
  }

  /// Load voucher by numeric sequence (doc number).
  Future<void> loadVoucherBySequence(int seq) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.purchaseVouchers).replace(
        queryParameters: {
          'limit': '1',
          'search': seq.toString(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        await _resetToNewVoucherForm();
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        await _resetToNewVoucherForm();
        return;
      }
      final List list = data['data'] ?? [];
      if (list.isEmpty) {
        await _resetToNewVoucherForm();
        return;
      }
      final summary = list.first as Map<String, dynamic>;
      final idVal = summary['id'];
      final id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
      if (id == null) {
        await _resetToNewVoucherForm();
        return;
      }
      activeVoucherId.value = id;

      // Fetch full details by id so we get voucher/items/charges.
      final detailResp = await http.get(
        Uri.parse('${ApiConfig.purchaseVouchers}/$id'),
        headers: {'Accept': 'application/json'},
      );
      if (detailResp.statusCode != 200) {
        await _resetToNewVoucherForm();
        return;
      }
      final detailData = jsonDecode(detailResp.body) as Map<String, dynamic>;
      if (detailData['success'] != true) {
        await _resetToNewVoucherForm();
        return;
      }
      final vData = detailData['data'] as Map<String, dynamic>?;
      _applyVoucherData(vData);
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Load by sequence error: $e');
      await _resetToNewVoucherForm();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPreviousVoucher() async {
    final current = currentSeq.value;
    if (current == null || current <= 1) return;
    await loadVoucherBySequence(current - 1);
  }

  Future<void> goToNextVoucher() async {
    final current = currentSeq.value;
    if (current == null) return;

    final latest = await _fetchLatestVoucherSequence();
    if (latest != null && current >= latest) {
      await _resetToNewVoucherForm();
      return;
    }

    await loadVoucherBySequence(current + 1);
  }

  Future<void> searchProducts(String query) =>
      loadProductsForVendor(search: query);

  void setDocNoPrefix(String v) => docNoPrefix.value = v;
  void setDocNoNumber(String v) => docNoNumber.value = v;
  void setVendor(int? id, String name) {
    vendorId.value = id;
    vendorName.value = name;
  }

  void setDocDate(String v) => docDate.value = v;
  void setBillNo(String v) => billNo.value = v;
  void setNarration(String v) => narration.value = v;
  void setDoNotUpdateInventory(bool v) => doNotUpdateInventory.value = v;
  void setPurchaseType(String v) => purchaseType.value = v;
  void setGstReverseCharge(String v) => gstReverseCharge.value = v;
  void setBillDate(String v) => billDate.value = v;
  void setPurchaseAgentId(String? v) => purchaseAgentId.value = (v ?? '').trim();

  void addItemRow() {
    final row = PVItemRow();
    if (unitTypes.isNotEmpty && row.unitType.value == 'Nos') {
      if (unitTypes.contains('Nos')) row.unitType.value = 'Nos';
      else row.unitType.value = unitTypes.first;
    }
    items.add(row);
  }

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) {
      final row = items.removeAt(index);
      _quantityValidationTimers.remove(row)?.cancel();
      row.dispose();
    }
  }

  void addChargeRow() {
    charges.add(PVChargeRow());
  }

  bool _isPlaceholderChargeRow(PVChargeRow row) {
    return row.name.value.trim().isEmpty &&
        (double.tryParse(row.amount.value) ?? 0) == 0 &&
        row.remarks.value.trim().isEmpty;
  }

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) charges.removeAt(index);
  }

  List<Product> getProductsExcluding(Iterable<int> excludeIds) =>
      products.where((p) => !excludeIds.contains(p.id)).toList();

  bool _isPlaceholderItemRow(PVItemRow row) {
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final unitPrice = double.tryParse(row.unitPrice.value) ?? 0;
    final hasAnyText = row.productCode.value.trim().isNotEmpty ||
        row.productName.value.trim().isNotEmpty ||
        row.alias.value.trim().isNotEmpty;
    return row.product.value == null && qty <= 0 && unitPrice <= 0 && !hasAnyText;
  }

  void _addLinkedPurchaseOrderMeta(int poId, String poNumber) {
    if (!linkedPurchaseOrderIds.contains(poId)) {
      linkedPurchaseOrderIds.add(poId);
    }
    if (poNumber.trim().isNotEmpty && !linkedPoNumbers.contains(poNumber.trim())) {
      linkedPoNumbers.add(poNumber.trim());
    }
  }

  /// Fetches a single purchase order by id (with items) for linking.
  Future<PurchaseOrder?> fetchPurchaseOrderById(int poId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseOrders}/$poId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      final poData = data['data'] as Map<String, dynamic>?;
      if (poData == null) return null;
      return PurchaseOrder.fromJson(poData);
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Fetch PO error: $e');
      return null;
    }
  }

  /// Fetches purchase orders list for the link dialog (id, po_number, supplier, status).
  /// If [search] is provided, it is sent to the backend so the API can filter
  /// by supplier name, PO number or id.
  Future<List<Map<String, dynamic>>> fetchPurchaseOrdersForLink({
    String? search,
    int? supplierId,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
        queryParameters: {
          'limit': '50',
          'exclude_closed': '1',
          if (supplierId != null) 'supplier_id': supplierId.toString(),
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => (e['status']?.toString().toUpperCase() ?? '') != 'CLOSED')
          .map((e) => {
                'id': e['id'],
                'supplier_id': e['supplier_id'],
                'po_number': e['po_number']?.toString(),
                'supplier_name': e['supplier_name']?.toString() ?? (e['supplier'] as Map?)?['supplier_name']?.toString(),
                'doc_date': e['doc_date']?.toString(),
                'status': e['status']?.toString(),
              })
          .toList();
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Fetch PO list error: $e');
      return [];
    }
  }

  /// Appends line items from one or more purchase orders into this voucher.
  Future<void> loadFromPurchaseOrders(List<PurchaseOrder> orders) async {
    if (orders.isEmpty) return;

    final existingVendor = vendorId.value;
    final targetVendor = orders.first.supplierId;

    final mixedVendor = orders.any((o) => o.supplierId != targetVendor);
    if (mixedVendor) {
      _showError('Please select purchase orders of the same vendor');
      return;
    }
    if (existingVendor != null && existingVendor != targetVendor) {
      _showError('Selected purchase orders do not match current vendor');
      return;
    }

    if (existingVendor == null) {
      setVendor(targetVendor, orders.first.supplierName ?? 'Vendor');
    }

    if (narration.value.trim().isEmpty) {
      final firstNarration = orders.first.narration?.trim() ?? '';
      if (firstNarration.isNotEmpty) {
        setNarration(firstNarration);
      }
    }

    if (items.length == 1 && _isPlaceholderItemRow(items.first)) {
      items.clear();
    }

    final importedCharges = <PVChargeRow>[];

    var addedCount = 0;
    for (final po in orders) {
      final poId = po.id;
      if (poId == null) {
        continue;
      }
      _addLinkedPurchaseOrderMeta(poId, po.poNumber);

      for (final item in po.items) {
        final row = PVItemRow();
        row.sourcePurchaseOrderId.value = poId;
        row.sourcePurchaseOrderItemId.value = item.id;
        row.sourcePoNumber.value = po.poNumber;
        row.product.value = Product(
          id: item.productId,
          name: item.productName?.trim().isEmpty == true
              ? 'Product ${item.productId}'
              : (item.productName ?? 'Product ${item.productId}'),
          hsnCode: item.hsnCode,
          productType: 'SINGLE',
          defaultUnit: item.unit,
        );
        row.productName.value = row.product.value!.name;
        row.productCode.value = '${item.productId}';
        row.hsnCode.value = row.product.value?.hsnCode ?? '';
        row.alias.value = '${item.productName ?? ''} : ${item.unit ?? 'Nos'}';
        row.setQuantity(item.quantity.toStringAsFixed(2));
        row.lastAcceptedQuantity.value = row.quantity.value;
        row.orderedQty.value = item.quantity.toStringAsFixed(3);
        row.usedQty.value = item.usedQty.toStringAsFixed(3);
        row.leftQty.value = item.leftQty.toStringAsFixed(3);
        row.writeoffQty.value = '0';
        row.isWriteoff.value = false;
        row.writeoffReason.value = '';
        row.unitType.value = item.unit ?? (unitTypes.isNotEmpty ? unitTypes.first : 'Nos');
        row.unitPrice.value = item.price.toStringAsFixed(2);
        row.taxableAmount.value = (item.quantity * item.price).toStringAsFixed(2);
        await applyResolvedTaxesToVoucherRow(
          row,
          productId: item.productId,
        );
        items.add(row);
        addedCount++;
      }

      for (final charge in po.chargesJson) {
        importedCharges.add(
          PVChargeRow()
            ..name.value = charge.name.trim().isEmpty ? 'Others' : charge.name.trim()
            ..amount.value = charge.amount.toStringAsFixed(2)
            ..remarks.value = charge.remarks?.trim() ?? '',
        );
      }
    }

    if (items.isEmpty) {
      addItemRow();
    }

    charges
      ..clear()
      ..addAll(importedCharges);

    if (charges.isEmpty) {
      addChargeRow();
    }

    _showSuccess('Added $addedCount items from ${orders.length} purchase order(s)');
  }

  Future<void> loadFromPurchaseOrder(PurchaseOrder po) async {
    await loadFromPurchaseOrders([po]);
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (vendorId.value == null) {
      _showError('Please select Vendor');
      return false;
    }
    if (docDate.value.trim().isEmpty) {
      _showError('Please enter Doc Date');
      return false;
    }
    if (items.isEmpty) {
      _showError('Please add at least one item');
      return false;
    }
    for (var row in items) {
      if (row.product.value == null) {
        _showError('Please select product for all items');
        return false;
      }
      final qty = double.tryParse(row.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Please enter valid quantity for all items');
        return false;
      }
      if (_isLinkedOverrun(row) && !row.isOverrunApproved.value) {
        _showError('Over quantity requires explicit acceptance on the line item');
        return false;
      }
      final writeoff = double.tryParse(row.writeoffQty.value) ?? 0;
      if (writeoff < 0) {
        _showError('Write off quantity cannot be negative');
        return false;
      }
      final maxWriteoff = _availableWriteoffQty(row);
      if (writeoff > maxWriteoff + 0.0000001) {
        _showError('Write off exceeds remaining quantity for a linked PO item');
        return false;
      }
      final price = double.tryParse(row.unitPrice.value);
      if (price == null || price < 0) {
        _showError('Please enter valid unit price for all items');
        return false;
      }
    }
    return true;
  }

  String? _extractRowLevelError(Map<String, dynamic> errors) {
    String? best;
    errors.forEach((key, value) {
      final match = RegExp(r'^items\.(\d+)\.(.+)$').firstMatch(key);
      if (match == null) return;
      final rowIndex = (int.tryParse(match.group(1) ?? '') ?? 0) + 1;
      final field = match.group(2) ?? 'field';
      String msg;
      if (value is List && value.isNotEmpty) {
        msg = value.first.toString();
      } else {
        msg = value.toString();
      }
      best ??= 'Row $rowIndex ($field): $msg';
    });
    return best;
  }

  Future<void> _saveVoucher(String saveStatus) async {
    if (!_validateForm()) return;

    isSaving.value = true;
    try {
      final payload = {
        'doc_no_prefix': docNoPrefix.value,
        'doc_no_number': docNoNumber.value.trim().isEmpty ? null : docNoNumber.value,
        if (linkedPurchaseOrderIds.isNotEmpty) 'purchase_order_id': linkedPurchaseOrderIds.first,
        'vendor_id': vendorId.value,
        'doc_date': docDate.value.trim().isEmpty ? _formatDate(DateTime.now()) : docDate.value,
        'bill_no': billNo.value.trim(),
        'narration': narration.value.trim(),
        'do_not_update_inventory': doNotUpdateInventory.value,
        'purchase_type': purchaseType.value,
        'gst_reverse_charge': gstReverseCharge.value,
        if (billDate.value.trim().isNotEmpty) 'bill_date': billDate.value.trim(),
        if (purchaseAgentId.value.trim().isNotEmpty) 'purchase_agent_id': purchaseAgentId.value.trim(),
        'status': saveStatus,
        'items': items.map((row) {
          final qty = double.tryParse(row.quantity.value) ?? 0;
          final price = double.tryParse(row.unitPrice.value) ?? 0;
          final taxable = qty * price;
          final sgst = double.tryParse(row.sgst.value) ?? 0;
          final cgst = double.tryParse(row.cgst.value) ?? 0;
          final igst = double.tryParse(row.igst.value) ?? 0;
          final cess = double.tryParse(row.cess.value) ?? 0;
          final roff = double.tryParse(row.roff.value) ?? 0;
          final customTaxes = _customTaxTotalFromKeys(row, taxable);
          return {
            'product_id': row.product.value!.id,
            'product_name': row.productName.value,
            'product_code': row.productCode.value,
            if (row.hsnCode.value.trim().isNotEmpty) 'hsn_code': row.hsnCode.value,
            'alias': row.alias.value,
            'unit': row.unitType.value,
            'quantity': qty,
            if (row.sourcePurchaseOrderItemId.value != null)
              'source_purchase_order_item_id': row.sourcePurchaseOrderItemId.value,
            if (row.orderedQty.value.trim().isNotEmpty)
              'ordered_qty': double.tryParse(row.orderedQty.value) ?? 0,
            if (row.usedQty.value.trim().isNotEmpty)
              'used_qty': double.tryParse(row.usedQty.value) ?? 0,
            if (row.leftQty.value.trim().isNotEmpty)
              'left_qty': double.tryParse(row.leftQty.value) ?? 0,
            'is_overrun_approved': row.isOverrunApproved.value,
            'overrun_qty': double.tryParse(row.overrunQty.value) ?? 0,
            'is_writeoff': row.isWriteoff.value,
            'writeoff_qty': double.tryParse(row.writeoffQty.value) ?? 0,
            if (row.overrunReason.value.trim().isNotEmpty)
              'overrun_reason': row.overrunReason.value.trim(),
            if (row.writeoffReason.value.trim().isNotEmpty)
              'writeoff_reason': row.writeoffReason.value.trim(),
            'unit_price': price,
            'taxable_amount': taxable,
            'sgst': sgst,
            'cgst': cgst,
            'igst': igst,
            'cess': cess,
            'roff': roff,
            'value': taxable + sgst + cgst + igst + cess + roff + customTaxes,
            'purchase_account': row.purchaseAccount.value,
            'gst_itc_eligibility': row.gstItcEligibility.value,
            if (row.sourcePurchaseOrderId.value != null)
              'source_purchase_order_id': row.sourcePurchaseOrderId.value,
            if (row.sourcePoNumber.value.trim().isNotEmpty)
              'source_po_number': row.sourcePoNumber.value.trim(),
          };
        }).toList(),
        'charges': charges.map((row) {
          final amt = double.tryParse(row.amount.value) ?? 0;
          final name = row.name.value.toLowerCase();
          return {
            'name': row.name.value,
            'amount': amt,
            'calculated_amount': name.contains('discount') ? -amt : amt,
            'remarks': row.remarks.value,
          };
        }).toList(),
      };

        final currentVoucherId = activeVoucherId.value;
        final isEdit = currentVoucherId != null;
      final url = isEdit
          ? '${ApiConfig.purchaseVouchers}/$currentVoucherId'
          : ApiConfig.createPurchaseVoucher;

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _showError(
          'Server error ${response.statusCode}. Backend may not be ready.',
        );
        return;
      }

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        final successMessage = isEdit
            ? 'Voucher updated'
            : saveStatus == 'DRAFT'
                ? 'Voucher saved as draft'
                : 'Purchase voucher posted';

        // Show prominent success toast with adequate buffering time.
        await Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
          fontSize: 16,
          timeInSecForIosWeb: 3,
        );

        // Buffer to ensure toast is fully visible before navigation.
        await Future.delayed(const Duration(milliseconds: 1200));

        // Trigger refresh on list controller if it's available
        try {
          final listController = Get.find<PurchaseVoucherListController>();
          listController.markForRefresh();
        } catch (_) {
          // List controller not initialized, which is fine
        }

        Get.back(result: true);
      } else {
        final msg = data['message'] ?? 'Failed to save voucher';
        final err = data['error'];
        final errs = data['errors'];
        if (errs is Map<String, dynamic>) {
          final rowError = _extractRowLevelError(errs);
          if (rowError != null) {
            _showError(rowError);
            return;
          }
        }
        final detail = err != null
            ? (err is String ? err : err.toString())
            : (errs != null ? errs.toString() : null);
        _showError(detail != null ? '$msg: $detail' : msg);
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveDraft() => _saveVoucher('DRAFT');

  void _deriveTaxPercentsFromCurrentAmounts(PVItemRow row) {
    final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
    if (taxable <= 0) {
      row.autoTaxRecompute.value = false;
      return;
    }

    double asPct(String amountRaw) {
      final amount = double.tryParse(amountRaw) ?? 0;
      if (amount <= 0) return 0;
      return (amount * 100) / taxable;
    }

    row.sgstPercent.value = asPct(row.sgst.value).toStringAsFixed(4);
    row.cgstPercent.value = asPct(row.cgst.value).toStringAsFixed(4);
    row.igstPercent.value = asPct(row.igst.value).toStringAsFixed(4);
    row.cessPercent.value = asPct(row.cess.value).toStringAsFixed(4);
    row.roffPercent.value = asPct(row.roff.value).toStringAsFixed(4);
    row.autoTaxRecompute.value = true;
  }

  void _syncAvailableTaxKeysFromCurrentValues(PVItemRow row) {
    final keys = <String>[];
    bool has(String value) {
      final parsed = double.tryParse(value.trim());
      return parsed != null && parsed != 0;
    }

    row.taxFieldValues.clear();

    if (has(row.sgst.value) || has(row.sgstPercent.value)) {
      keys.add('SGST');
      row.taxFieldValues['SGST'] =
          has(row.sgstPercent.value) ? row.sgstPercent.value : row.sgst.value;
    }
    if (has(row.cgst.value) || has(row.cgstPercent.value)) {
      keys.add('CGST');
      row.taxFieldValues['CGST'] =
          has(row.cgstPercent.value) ? row.cgstPercent.value : row.cgst.value;
    }
    if (has(row.igst.value) || has(row.igstPercent.value)) {
      keys.add('IGST');
      row.taxFieldValues['IGST'] =
          has(row.igstPercent.value) ? row.igstPercent.value : row.igst.value;
    }
    if (has(row.cess.value) || has(row.cessPercent.value)) {
      keys.add('CESS');
      row.taxFieldValues['CESS'] =
          has(row.cessPercent.value) ? row.cessPercent.value : row.cess.value;
    }
    if (has(row.roff.value) || has(row.roffPercent.value)) {
      keys.add('ROFF');
      row.taxFieldValues['ROFF'] =
          has(row.roffPercent.value) ? row.roffPercent.value : row.roff.value;
    }

    row.availableTaxKeys.assignAll(keys);
  }

  void clearVoucherTaxesForRow(PVItemRow row) {
    _clearVoucherTaxBreakdown(row);
    recalcItemRow(row);
  }

  Future<void> confirmPost() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Post Voucher'),
        content: const Text(
          'Are you sure you want to post this purchase voucher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveVoucher('POSTED');
  }
}

class _QuantitySummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _QuantitySummaryTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 14, color: accent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class PVItemRow {
  final sourcePurchaseOrderId = Rxn<int>();
  final sourcePurchaseOrderItemId = Rxn<int>();
  final sourcePoNumber = ''.obs;
  final orderedQty = ''.obs;
  final usedQty = ''.obs;
  final leftQty = ''.obs;
  final isOverrunApproved = false.obs;
  final overrunQty = '0'.obs;
  final overrunReason = ''.obs;
  final writeoffQty = '0'.obs;
  final isWriteoff = false.obs;
  final writeoffReason = ''.obs;
  final lastAcceptedQuantity = ''.obs;
  final product = Rxn<Product>();
  final productCode = ''.obs;
  final productName = ''.obs;
  final hsnCode = ''.obs;
  final alias = ''.obs;
  final quantity = ''.obs;
  final quantityController = TextEditingController();
  final quantityFocusNode = FocusNode();
  final unitType = 'Nos'.obs;
  final unitPrice = ''.obs;
  final taxableAmount = '0'.obs;
  final sgst = ''.obs;
  final cgst = ''.obs;
  final igst = ''.obs;
  final cess = ''.obs;
  final roff = ''.obs;
  final sgstPercent = ''.obs;
  final cgstPercent = ''.obs;
  final igstPercent = ''.obs;
  final cessPercent = ''.obs;
  final roffPercent = ''.obs;
  final taxFieldValues = <String, String>{}.obs;
  final availableTaxKeys = <String>[].obs;
  final autoTaxRecompute = false.obs;
  final value = '0'.obs;
  final purchaseAccount = 'Def Purchase Accounts'.obs;
  final gstItcEligibility = ''.obs;

  void setQuantity(String value) {
    quantity.value = value;
    if (quantityController.text == value) return;
    quantityController.value = quantityController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void dispose() {
    quantityController.dispose();
    quantityFocusNode.dispose();
  }
}

class PVChargeRow {
  final name = 'Others'.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;
}

void _showSuccess(String message) {
  Get.snackbar(
    'Success',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.primary,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
  );
}

void _showError(String message) {
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
  );
}
