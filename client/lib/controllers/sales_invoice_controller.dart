import 'dart:async';
import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/charge_constants.dart';
import '../models/party_result.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import 'sales_invoice_list_controller.dart';

class SalesInvoiceController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? invoiceId;
  final bool? startInReportMode;
  final activeInvoiceId = RxnInt();
  final status = 'DRAFT'.obs;
  final viewOnly = false.obs;

  // Header
  final docNoPrefix = '25-26/'.obs;
  final docNoNumber = ''.obs;
  final customerId = Rxn<int>();
  final customerName = ''.obs;
  final docDate = ''.obs;
  final billNo = ''.obs;
  final narration = ''.obs;
  final doNotUpdateInventory = false.obs;
  final saleType = 'Regular'.obs;
  final billDate = ''.obs;

  // Master data
  final customers = <Map<String, dynamic>>[].obs;
  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;
  static const List<String> chargeTypeNames = addonChargeTypeNames;

  final items = <SIItemRow>[].obs;
  final charges = <SIChargeRow>[].obs;

  final linkedSalesOrderIds = <int>[].obs;
  final linkedSoNumbers = <String>[].obs;

  final showAllProducts = false.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final _productTaxCache = <int, List<Map<String, dynamic>>>{};
  final Map<SIItemRow, Timer> _quantityValidationTimers = {};

  final RxnInt currentSeq = RxnInt();

  SalesInvoiceController({this.invoiceId, this.startInReportMode});

  int? _safeInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  @override
  void onInit() {
    super.onInit();
    activeInvoiceId.value = invoiceId;
    viewOnly.value = startInReportMode ?? false;
    _loadCustomers();
    _loadUnitTypes();
    _loadProducts();
    if (invoiceId == null) {
      docDate.value = _formatDate(DateTime.now());
      _loadNextDocNoNumberForNew();
      addItemRow();
      addChargeRow();
    } else {
      _loadInvoiceData();
    }
  }

  bool get isEditMode => activeInvoiceId.value != null;
  bool get isReportMode => viewOnly.value;
  bool get canEditFromReport => isReportMode && status.value.toUpperCase() == 'DRAFT';

  void enterEditMode() {
    viewOnly.value = false;
  }

  bool _isFixedTaxKey(String key) {
    final normalized = key.trim().toUpperCase();
    return normalized == 'SGST' || normalized == 'CGST' || normalized == 'IGST' ||
        normalized == 'CESS' || normalized == 'ROFF';
  }

  double _customTaxTotalFromKeys(SIItemRow row, double taxable) {
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

  void recalcItemRow(SIItemRow row) {
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

  void scheduleQuantityValidation(SIItemRow row) {
    _quantityValidationTimers[row]?.cancel();
    _quantityValidationTimers[row] = Timer(const Duration(milliseconds: 450), () async {
      if (Get.isDialogOpen == true) return;
      await onQuantityEditCompleted(row);
    });
  }

  bool _isLinkedOverrun(SIItemRow row) {
    if (row.sourceSalesOrderItemId.value == null) return false;
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
    return qty > left + 0.0000001;
  }

  double _availableWriteoffQty(SIItemRow row) {
    if (row.sourceSalesOrderItemId.value == null) return 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final remainingAfterDelivery = left - qty;
    return remainingAfterDelivery > 0 ? remainingAfterDelivery : 0;
  }

  Future<void> openWriteOffDialog(SIItemRow row, {bool writeAll = false}) async {
    if (row.sourceSalesOrderItemId.value == null) {
      _showError('Write off is available only for linked SO lines');
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
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))],
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
          TextButton(onPressed: () => Get.back(result: {'clear': true}), child: const Text('Clear')),
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

  Future<void> onQuantityEditCompleted(SIItemRow row) async {
    if (row.sourceSalesOrderItemId.value == null) {
      row.isOverrunApproved.value = false;
      row.overrunQty.value = '0';
      row.overrunReason.value = '';
      row.lastAcceptedQuantity.value = row.quantity.value;
      return;
    }

    final qty = double.tryParse(row.quantity.value) ?? 0;
    final left = double.tryParse(row.leftQty.value) ?? 0;
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
                        'Quantity above SO balance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  row.productName.value.trim().isEmpty
                      ? 'This line exceeds the remaining SO quantity.'
                      : '${row.productName.value.trim()} exceeds the remaining SO quantity.',
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
                      _SIQuantitySummaryTile(label: 'Allowed left', value: left.toStringAsFixed(1), accent: AppColors.primaryDark),
                      const SizedBox(height: 8),
                      _SIQuantitySummaryTile(label: 'Entered now', value: qty.toStringAsFixed(1), accent: AppColors.primaryDark),
                      const SizedBox(height: 8),
                      _SIQuantitySummaryTile(label: 'Over by', value: overrun.toStringAsFixed(1), accent: Colors.deepOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Keep SO limit'),
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

  void onTaxAmountManuallyChanged(SIItemRow row, String key, String value) {
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

  Future<void> applyResolvedTaxesToInvoiceRow(SIItemRow row, {required int productId}) async {
    _clearInvoiceTaxBreakdown(row);
    final productTaxes = await _fetchProductTaxRows(productId);
    final applied = _applyTaxRowsToInvoiceAmounts(row, productTaxes);
    if (!applied) recalcItemRow(row);
  }

  void _clearInvoiceTaxBreakdown(SIItemRow row) {
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

  bool _applyTaxRowsToInvoiceAmounts(SIItemRow row, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return false;
    var applied = false;
    final fixedKeys = <String>{};
    final customKeys = <String>[];

    for (final map in rows) {
      final tax = map['tax'] as Map<String, dynamic>?;
      final rawName = (tax?['tax_name'] ?? map['tax_name'] ?? '').toString().trim();
      final rawSub = (tax?['tax_sub_category'] ?? map['tax_sub_category'] ?? '').toString().trim();
      final taxName = rawName.toUpperCase();
      final taxSub = rawSub.toUpperCase();
      final percent = (map['tax_percent'] ?? 0) is num
          ? (map['tax_percent'] as num).toDouble()
          : double.tryParse(map['tax_percent']?.toString() ?? '') ?? 0;
      if (percent <= 0) continue;

      final canonical = _canonicalTaxKey(taxName, taxSub);
      final label = canonical ?? (rawName.isNotEmpty ? rawName : (rawSub.isNotEmpty ? rawSub : 'Tax'));
      row.taxFieldValues[label] = percent.toStringAsFixed(2);
      if (canonical == null && !customKeys.contains(label)) customKeys.add(label);

      if (canonical == 'SGST') { row.sgstPercent.value = percent.toStringAsFixed(4); fixedKeys.add('SGST'); applied = true; }
      else if (canonical == 'CGST') { row.cgstPercent.value = percent.toStringAsFixed(4); fixedKeys.add('CGST'); applied = true; }
      else if (canonical == 'IGST') { row.igstPercent.value = percent.toStringAsFixed(4); fixedKeys.add('IGST'); applied = true; }
      else if (canonical == 'CESS') { row.cessPercent.value = percent.toStringAsFixed(4); fixedKeys.add('CESS'); applied = true; }
      else if (canonical == 'ROFF') { row.roffPercent.value = percent.toStringAsFixed(4); fixedKeys.add('ROFF'); applied = true; }
      else { applied = true; }
    }

    if (applied) {
      final ordered = ['SGST', 'CGST', 'IGST', 'CESS', 'ROFF'].where(fixedKeys.contains).toList();
      ordered.addAll(customKeys);
      row.availableTaxKeys.assignAll(ordered);
      row.autoTaxRecompute.value = true;
      recalcItemRow(row);
    }
    return applied;
  }

  bool _matchesTax(String taxName, String taxSub, String key) =>
      taxName.contains(key) || taxSub.contains(key);

  String? _canonicalTaxKey(String taxName, String taxSub) {
    if (_matchesTax(taxName, taxSub, 'SGST')) return 'SGST';
    if (_matchesTax(taxName, taxSub, 'CGST')) return 'CGST';
    if (_matchesTax(taxName, taxSub, 'IGST')) return 'IGST';
    if (_matchesTax(taxName, taxSub, 'CESS')) return 'CESS';
    if (_matchesTax(taxName, taxSub, 'ROFF') || taxName.contains('ROUND')) return 'ROFF';
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
    final rows = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    _productTaxCache[productId] = rows;
    return rows;
  }

  Future<void> _loadInvoiceData() async {
    final id = activeInvoiceId.value;
    if (id == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.salesInvoices}/$id'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final vData = data['data'] as Map<String, dynamic>?;
          _applyInvoiceData(vData);
        }
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE] Load failed: $e');
      _showError('Failed to load invoice data');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadCustomers() async {
    try {
      Future<List<Map<String, dynamic>>> fetch(Uri uri) async {
        final response = await http.get(uri, headers: {'Accept': 'application/json'});
        if (response.statusCode != 200) return [];
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return [];
        final List list = data['data'] ?? [];
        return list
            .map((e) => {
                  'id': (e as Map)['id'],
                  'name': (e)['name']?.toString() ?? 'User ${(e)['id'] ?? ''}',
                })
            .where((e) => e['id'] != null)
            .toList();
      }

      final filteredUri = Uri.parse(ApiConfig.users)
          .replace(queryParameters: {'role': 'Customer', 'limit': '500'});
      var list = await fetch(filteredUri);
      if (list.isEmpty) {
        final fallbackUri = Uri.parse(ApiConfig.users).replace(queryParameters: {'limit': '500'});
        list = await fetch(fallbackUri);
      }
      customers.value = list;
    } catch (e) {
      debugPrint('[SALES_INVOICE] Customers error: $e');
    }
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.unitTypes), headers: {'Accept': 'application/json'});
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

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.products}?limit=50'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE] Products error: $e');
    }
  }

  Future<void> loadProductsForCustomer({String? search, bool? includeAll}) async {
    // For sales, always use generic products list (no customer-specific products endpoint)
    try {
      final base = ApiConfig.products;
      final uri = search != null && search.trim().isNotEmpty
          ? Uri.parse(base).replace(queryParameters: {'limit': '50', 'search': search.trim()})
          : Uri.parse('$base?limit=50');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE] Products error: $e');
    }
  }

  Future<void> searchProducts(String query) => loadProductsForCustomer(search: query);

  Future<List<Product>> searchProductsAsModels(String query) async {
    await loadProductsForCustomer(search: query.isEmpty ? null : query);
    return List<Product>.from(products);
  }

  Future<void> _loadNextDocNoNumberForNew() async {
    try {
      final uri = Uri.parse(ApiConfig.salesInvoices).replace(queryParameters: {'limit': '1'});
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
      final base = _sequenceFromInvoiceSummary(last);
      final next = (base ?? 0) + 1;
      docNoNumber.value = next.toString();
      currentSeq.value = next;
    } catch (e) {
      debugPrint('[SALES_INVOICE] Next doc no error: $e');
    }
  }

  int? _sequenceFromInvoiceSummary(Map<String, dynamic> summary) {
    int? base = int.tryParse(summary['doc_no_number']?.toString() ?? '');
    if (base == null) {
      final rawDoc = summary['doc_no']?.toString();
      if (rawDoc != null && rawDoc.isNotEmpty) {
        final match = RegExp(r'(\d+)$').firstMatch(rawDoc);
        if (match != null) base = int.tryParse(match.group(1)!);
      }
    }
    base ??= (summary['id'] is int) ? summary['id'] as int : int.tryParse(summary['id']?.toString() ?? '');
    return base;
  }

  Future<int?> _fetchLatestInvoiceSequence() async {
    try {
      final uri = Uri.parse(ApiConfig.salesInvoices).replace(queryParameters: {'limit': '1'});
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      final List list = data['data'] ?? [];
      if (list.isEmpty) return null;
      return _sequenceFromInvoiceSummary(list.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _resetToNewInvoiceForm() async {
    activeInvoiceId.value = null;
    docNoPrefix.value = '25-26/';
    docNoNumber.value = '';
    customerId.value = null;
    customerName.value = '';
    docDate.value = _formatDate(DateTime.now());
    billNo.value = '';
    narration.value = '';
    doNotUpdateInventory.value = false;
    saleType.value = 'Regular';
    billDate.value = '';
    linkedSalesOrderIds.clear();
    linkedSoNumbers.clear();
    _productTaxCache.clear();
    items.clear();
    charges.clear();
    addItemRow();
    addChargeRow();
    await _loadNextDocNoNumberForNew();
  }

  void _applyInvoiceData(Map<String, dynamic>? vData) {
    if (vData == null) return;
    linkedSalesOrderIds.clear();
    linkedSoNumbers.clear();
    final v = vData['invoice'] as Map<String, dynamic>? ?? vData;
    activeInvoiceId.value = _safeInt(v['id']);
    docNoPrefix.value = v['doc_no_prefix']?.toString() ?? '25-26/';
    docNoNumber.value = v['doc_no_number']?.toString() ?? '';
    int? base = int.tryParse(docNoNumber.value);
    if (base == null) {
      final raw = v['doc_no']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final match = RegExp(r'(\d+)$').firstMatch(raw);
        if (match != null) base = int.tryParse(match.group(1)!);
      }
    }
    currentSeq.value = base;
    customerId.value = _safeInt(v['customer_id']);
    customerName.value = v['customer_name']?.toString() ?? '';
    docDate.value = v['doc_date']?.toString().split(' ').first ?? _formatDate(DateTime.now());
    billNo.value = v['bill_no']?.toString() ?? '';
    narration.value = v['narration']?.toString() ?? '';
    doNotUpdateInventory.value = v['do_not_update_inventory'] == true;
    saleType.value = v['sale_type']?.toString() ?? 'Regular';
    billDate.value = v['bill_date']?.toString() ?? '';
    status.value = v['status']?.toString() ?? 'DRAFT';

    final itemsData = (vData['items'] as List?) ?? [];
    for (final row in items) { row.dispose(); }
    items.clear();
    for (var item in itemsData) {
      final map = item as Map<String, dynamic>;
      final row = SIItemRow();
      row.sourceSalesOrderId.value = _safeInt(map['source_sales_order_id']);
      row.sourceSalesOrderItemId.value = _safeInt(map['source_sales_order_item_id']);
      row.sourceSoNumber.value = map['source_so_number']?.toString() ?? '';
      final pid = _safeInt(map['product_id']);
      if (pid != null) {
        row.product.value = Product(id: pid, name: map['product_name']?.toString() ?? '', hsnCode: map['hsn_code']?.toString(), productType: 'SINGLE');
      }
      row.productCode.value = map['product_code']?.toString() ?? '';
      row.hsnCode.value = map['hsn_code']?.toString() ?? '';
      row.productName.value = map['product_name']?.toString() ?? '';
      row.alias.value = map['alias']?.toString() ?? '';
      row.setQuantity(map['quantity']?.toString() ?? '');
      row.lastAcceptedQuantity.value = row.quantity.value;
      row.unitType.value = map['unit']?.toString() ?? 'Nos';
      row.unitPrice.value = map['unit_price']?.toString() ?? '0';
      row.orderedQty.value = map['ordered_qty']?.toString() ?? '';
      row.usedQty.value = map['used_qty']?.toString() ?? '';
      row.leftQty.value = map['left_qty']?.toString() ?? '';
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
      row.saleAccount.value = map['sale_account']?.toString() ?? 'Def Sales Accounts';
      items.add(row);
    }

    final chargesData = (vData['charges'] as List?) ?? [];
    charges.clear();
    for (var ch in chargesData) {
      final map = ch as Map<String, dynamic>;
      final row = SIChargeRow();
      row.name.value = map['name']?.toString() ?? 'Others';
      row.amount.value = map['amount']?.toString() ?? '0';
      row.remarks.value = map['remarks']?.toString() ?? '';
      charges.add(row);
    }
    if (items.isEmpty) addItemRow();
    if (charges.isEmpty) addChargeRow();
  }

  Future<void> loadInvoiceBySequence(int seq) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.salesInvoices).replace(queryParameters: {'limit': '1', 'search': seq.toString()});
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) { await _resetToNewInvoiceForm(); return; }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) { await _resetToNewInvoiceForm(); return; }
      final List list = data['data'] ?? [];
      if (list.isEmpty) { await _resetToNewInvoiceForm(); return; }
      final summary = list.first as Map<String, dynamic>;
      final idVal = summary['id'];
      final id = idVal is int ? idVal : _safeInt(idVal);
      if (id == null) { await _resetToNewInvoiceForm(); return; }
      activeInvoiceId.value = id;
      final detailResp = await http.get(Uri.parse('${ApiConfig.salesInvoices}/$id'), headers: {'Accept': 'application/json'});
      if (detailResp.statusCode != 200) { await _resetToNewInvoiceForm(); return; }
      final detailData = jsonDecode(detailResp.body) as Map<String, dynamic>;
      if (detailData['success'] != true) { await _resetToNewInvoiceForm(); return; }
      _applyInvoiceData(detailData['data'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('[SALES_INVOICE] Load by sequence error: $e');
      await _resetToNewInvoiceForm();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPreviousInvoice() async {
    final current = currentSeq.value;
    if (current == null || current <= 1) return;
    await loadInvoiceBySequence(current - 1);
  }

  Future<void> goToNextInvoice() async {
    final current = currentSeq.value;
    if (current == null) return;
    final latest = await _fetchLatestInvoiceSequence();
    if (latest != null && current >= latest) { await _resetToNewInvoiceForm(); return; }
    await loadInvoiceBySequence(current + 1);
  }

  void setDocNoPrefix(String v) => docNoPrefix.value = v;
  void setDocNoNumber(String v) => docNoNumber.value = v;
  void setCustomer(int? id, String name) { customerId.value = id; customerName.value = name; }

  Future<List<PartyResult>> searchCustomers(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.users).replace(queryParameters: {
        'limit': '50',
        'role': 'Customer',
        if (query.trim().isNotEmpty) 'search': query.trim(),
      });
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list.whereType<Map<String, dynamic>>().map((e) {
        final rawId = e['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
        if (id == null) return null;
        return PartyResult(
          id: id,
          name: e['name']?.toString() ?? 'Customer $id',
          phone: e['contactNumber']?.toString(),
        );
      }).whereType<PartyResult>().toList();
    } catch (_) { return []; }
  }
  void setDocDate(String v) => docDate.value = v;
  void setBillNo(String v) => billNo.value = v;
  void setNarration(String v) => narration.value = v;
  void setDoNotUpdateInventory(bool v) => doNotUpdateInventory.value = v;
  void setSaleType(String v) => saleType.value = v;
  void setBillDate(String v) => billDate.value = v;

  void addItemRow() {
    final row = SIItemRow();
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

  void addChargeRow() { charges.add(SIChargeRow()); }
  void removeChargeRow(int index) { if (index >= 0 && index < charges.length) charges.removeAt(index); }

  List<Product> getProductsExcluding(Iterable<int> excludeIds) =>
      products.where((p) => !excludeIds.contains(p.id)).toList();

  void _deriveTaxPercentsFromCurrentAmounts(SIItemRow row) {
    final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
    if (taxable <= 0) { row.autoTaxRecompute.value = false; return; }
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

  void _syncAvailableTaxKeysFromCurrentValues(SIItemRow row) {
    final keys = <String>[];
    bool has(String value) { final parsed = double.tryParse(value.trim()); return parsed != null && parsed != 0; }
    row.taxFieldValues.clear();
    if (has(row.sgst.value) || has(row.sgstPercent.value)) { keys.add('SGST'); row.taxFieldValues['SGST'] = has(row.sgstPercent.value) ? row.sgstPercent.value : row.sgst.value; }
    if (has(row.cgst.value) || has(row.cgstPercent.value)) { keys.add('CGST'); row.taxFieldValues['CGST'] = has(row.cgstPercent.value) ? row.cgstPercent.value : row.cgst.value; }
    if (has(row.igst.value) || has(row.igstPercent.value)) { keys.add('IGST'); row.taxFieldValues['IGST'] = has(row.igstPercent.value) ? row.igstPercent.value : row.igst.value; }
    if (has(row.cess.value) || has(row.cessPercent.value)) { keys.add('CESS'); row.taxFieldValues['CESS'] = has(row.cessPercent.value) ? row.cessPercent.value : row.cess.value; }
    if (has(row.roff.value) || has(row.roffPercent.value)) { keys.add('ROFF'); row.taxFieldValues['ROFF'] = has(row.roffPercent.value) ? row.roffPercent.value : row.roff.value; }
    row.availableTaxKeys.assignAll(keys);
  }

  void clearInvoiceTaxesForRow(SIItemRow row) {
    _clearInvoiceTaxBreakdown(row);
    recalcItemRow(row);
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (customerId.value == null) { _showError('Please select Customer'); return false; }
    if (docDate.value.trim().isEmpty) { _showError('Please enter Doc Date'); return false; }
    if (items.isEmpty) { _showError('Please add at least one item'); return false; }
    for (var row in items) {
      if (row.product.value == null) { _showError('Please select product for all items'); return false; }
      final qty = double.tryParse(row.quantity.value);
      if (qty == null || qty <= 0) { _showError('Please enter valid quantity for all items'); return false; }
      if (_isLinkedOverrun(row) && !row.isOverrunApproved.value) { _showError('Over quantity requires explicit acceptance on the line item'); return false; }
      final price = double.tryParse(row.unitPrice.value);
      if (price == null || price < 0) { _showError('Please enter valid unit price for all items'); return false; }
    }
    return true;
  }

  Future<void> _saveInvoice(String saveStatus) async {
    if (!_validateForm()) return;
    isSaving.value = true;
    try {
      final payload = {
        'doc_no_prefix': docNoPrefix.value,
        'doc_no_number': docNoNumber.value.trim().isEmpty ? null : docNoNumber.value,
        'customer_id': customerId.value,
        'doc_date': docDate.value.trim().isEmpty ? _formatDate(DateTime.now()) : docDate.value,
        'bill_no': billNo.value.trim(),
        'narration': narration.value.trim(),
        'do_not_update_inventory': doNotUpdateInventory.value,
        'sale_type': saleType.value,
        if (billDate.value.trim().isNotEmpty) 'bill_date': billDate.value.trim(),
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
            if (row.selectedPackId.value.trim().isNotEmpty) 'pack_id': row.selectedPackId.value.trim(),
            'quantity': qty,
            if (row.sourceSalesOrderItemId.value != null)
              'source_sales_order_item_id': row.sourceSalesOrderItemId.value,
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
            if (row.overrunReason.value.trim().isNotEmpty) 'overrun_reason': row.overrunReason.value.trim(),
            if (row.writeoffReason.value.trim().isNotEmpty) 'writeoff_reason': row.writeoffReason.value.trim(),
            'unit_price': price,
            'taxable_amount': taxable,
            'sgst': sgst,
            'cgst': cgst,
            'igst': igst,
            'cess': cess,
            'roff': roff,
            'value': taxable + sgst + cgst + igst + cess + roff + customTaxes,
            'sale_account': row.saleAccount.value,
            if (row.sourceSalesOrderId.value != null) 'source_sales_order_id': row.sourceSalesOrderId.value,
            if (row.sourceSoNumber.value.trim().isNotEmpty) 'source_so_number': row.sourceSoNumber.value.trim(),
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

      final currentInvoiceId = activeInvoiceId.value;
      final isEdit = currentInvoiceId != null;
      final url = isEdit ? '${ApiConfig.salesInvoices}/$currentInvoiceId' : ApiConfig.createSalesInvoice;

      final response = isEdit
          ? await http.put(Uri.parse(url), headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}, body: jsonEncode(payload))
          : await http.post(Uri.parse(url), headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}, body: jsonEncode(payload));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _showError('Server error ${response.statusCode}. Backend may not be ready.');
        return;
      }

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        final successMessage = isEdit
            ? 'Invoice updated'
            : saveStatus == 'DRAFT' ? 'Invoice saved as draft' : 'Sales invoice posted';

        await Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
          fontSize: 16,
          timeInSecForIosWeb: 3,
        );
        await Future.delayed(const Duration(milliseconds: 1200));

        try {
          final listController = Get.find<SalesInvoiceListController>();
          listController.markForRefresh();
        } catch (_) {}

        Get.back(result: true);
      } else {
        final msg = data['message'] ?? 'Failed to save invoice';
        _showError(msg.toString());
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE] Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveDraft() => _saveInvoice('DRAFT');

  Future<void> confirmPost() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Post Invoice'),
        content: const Text('Are you sure you want to post this sales invoice?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Post')),
        ],
      ),
    );
    if (confirmed == true) await _saveInvoice('POSTED');
  }
}

class _SIQuantitySummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SIQuantitySummaryTile({required this.label, required this.value, required this.accent});

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

class SIItemRow {
  final sourceSalesOrderId = Rxn<int>();
  final sourceSalesOrderItemId = Rxn<int>();
  final sourceSoNumber = ''.obs;
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
  final saleAccount = 'Def Sales Accounts'.obs;
  final selectedPackId = ''.obs;
  final selectedPackLabel = ''.obs;

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

class SIChargeRow {
  final name = 'Others'.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;
}

void _showSuccess(String message) {
  Get.snackbar('Success', message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2));
}

void _showError(String message) {
  Get.snackbar('Error', message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8);
}
