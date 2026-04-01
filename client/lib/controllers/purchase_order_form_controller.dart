import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? poId;
  final bool startInViewOnly;

  final suppliers = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;

  /// Current purchase order number label for navigation/display (e.g. PO-1001 or just 1001).
  final currentPoNumber = ''.obs;
  /// Parsed numeric sequence used for previous/next navigation.
  final RxnInt currentPoSeq = RxnInt();

  final financialYear = '25-26'.obs;
  final supplierId = Rxn<int>();
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;
  final charges = <POChargeRow>[].obs;

  final items = <POLineRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  static const List<String> chargeTypeNames = [
    'Hamali',
    'Freight',
    'Round off',
    'Discount',
    'Others',
  ];

  PurchaseOrderFormController({this.poId, this.startInViewOnly = false});

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    _ensureDefaultCharges();
    _loadSuppliers();
    _loadUnitTypes();
    if (poId != null) {
      _loadPurchaseOrder();
    } else {
      _setDefaultDocDate();
      _loadNextPoNumberForNew();
      addItem();
    }
  }

  /// Search all products via /products (no supplier filter).
  Future<List<Map<String, dynamic>>> _searchAllProducts(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.products).replace(
        queryParameters: {
          'limit': '50',
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .map((e) => {
                'product_id': (e as Map)['product_id'] ?? (e)['id'],
                'name': (e)['name']?.toString() ??
                    (e)['product_name']?.toString() ??
                    '',
              })
          .toList();
    } catch (e) {
      debugPrint('[PO FORM] Search products error: $e');
      return [];
    }
  }

  /// Supplier-aware product search.
  /// If a supplier is selected and [includeAll] is false, we hit /supplier-products
  /// so that only products assigned to that supplier are returned.
  /// Otherwise we fall back to the generic /products search.
  Future<List<Map<String, dynamic>>> searchProductsForSupplier(
    String query, {
    bool includeAll = false,
  }) async {
    final supplier = supplierId.value;
    if (!includeAll && supplier != null) {
      try {
        final uri = Uri.parse(ApiConfig.supplierProducts).replace(
          queryParameters: {
            'limit': '50',
            'supplier_id': supplier.toString(),
            if (query.trim().isNotEmpty) 'search': query.trim(),
          },
        );
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return [];
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return [];
        final List list = data['data'] ?? [];
        return list.map((e) {
          final map = e as Map<String, dynamic>;
          final product = map['product'] as Map<String, dynamic>?;
          final rawId =
              map['product_id'] ?? product?['product_id'] ?? product?['id'];
          final name = product?['name']?.toString() ??
              map['product_name']?.toString() ??
              map['supplier_product_name']?.toString() ??
              'Product ${rawId ?? ''}';
          return {
            'product_id': rawId,
            'name': name,
          };
        }).toList();
      } catch (e) {
        debugPrint('[PO FORM] Supplier search error: $e');
        // fall through to all-products search
      }
    }
    return _searchAllProducts(query);
  }

  /// Backwards-compatible wrapper for existing callers that always want all products.
  Future<List<Map<String, dynamic>>> searchProducts(String query) =>
      _searchAllProducts(query);

  /// Resolves line-item taxes only from product_taxes for selected product.
  /// If no product taxes are found, tax fields remain empty.
  Future<void> applyProductTaxesToRow(POLineRow row, int productId) async {
    row.isTaxLoading.value = true;
    _clearTaxBreakdown(row);
    try {
      final productTaxes = await _fetchProductTaxRows(productId);
      final applied = _applyTaxRowsToRow(row, productTaxes);

      if (!applied) {
        row.taxPercent.value = '';
      }
    } catch (e) {
      debugPrint('[PO FORM] Resolve taxes error: $e');
      row.taxPercent.value = '';
    } finally {
      row.isTaxLoading.value = false;
    }
  }

  void _clearTaxBreakdown(POLineRow row) {
    row.sgst.value = '';
    row.cgst.value = '';
    row.igst.value = '';
    row.cess.value = '';
    row.roff.value = '';
    row.taxFieldValues.clear();
    row.availableTaxKeys.clear();
  }

  bool _applyTaxRowsToRow(POLineRow row, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return false;
    var applied = false;
    var totalPercent = 0.0;
    final fixedKeys = <String>{};
    final customKeys = <String>[];

    for (final map in rows) {
      final tax = map['tax'] as Map<String, dynamic>?;
      final rawName = (tax?['tax_name'] ?? map['tax_name'] ?? '').toString().trim();
      final rawSub =
          (tax?['tax_sub_category'] ?? map['tax_sub_category'] ?? '').toString().trim();
      final taxName = rawName.toUpperCase();
      final taxSub = rawSub.toUpperCase();
      final percent = (map['tax_percent'] ?? 0) is num
          ? (map['tax_percent'] as num).toDouble()
          : double.tryParse(map['tax_percent']?.toString() ?? '') ?? 0;

      if (percent <= 0) continue;
      totalPercent += percent;
      final canonical = _canonicalTaxKey(taxName, taxSub);
      final label = canonical ?? (rawName.isNotEmpty ? rawName : (rawSub.isNotEmpty ? rawSub : 'Tax'));
      row.taxFieldValues[label] = percent.toStringAsFixed(2);
      if (canonical == null && !customKeys.contains(label)) {
        customKeys.add(label);
      }

      if (canonical == 'SGST') {
        row.sgst.value = percent.toStringAsFixed(2);
        fixedKeys.add('SGST');
        applied = true;
      } else if (canonical == 'CGST') {
        row.cgst.value = percent.toStringAsFixed(2);
        fixedKeys.add('CGST');
        applied = true;
      } else if (canonical == 'IGST') {
        row.igst.value = percent.toStringAsFixed(2);
        fixedKeys.add('IGST');
        applied = true;
      } else if (canonical == 'CESS') {
        row.cess.value = percent.toStringAsFixed(2);
        fixedKeys.add('CESS');
        applied = true;
      } else if (canonical == 'ROFF') {
        row.roff.value = percent.toStringAsFixed(2);
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
      row.taxPercent.value = totalPercent.toStringAsFixed(2);
    }
    return applied;
  }

  Future<List<Map<String, dynamic>>> _fetchProductTaxRows(int productId) async {
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
    return list
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => Map<String, dynamic>.from(e))
        .toList();
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

  void _setDefaultDocDate() {
    final now = DateTime.now();
    docDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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
      debugPrint('[PO FORM] Load suppliers error: $e');
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
    } catch (e) {
      unitTypes.value = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  /// For a brand new PO, fetch the latest existing PO and
  /// set [currentPoNumber] to the next consecutive number.
  Future<void> _loadNextPoNumberForNew() async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
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
        currentPoSeq.value = 1;
        currentPoNumber.value = '1';
        return;
      }
      final last = list.first as Map<String, dynamic>;
      final next = _nextSequenceFromRaw(
        last['po_number']?.toString(),
        last['id'],
      );
      currentPoSeq.value = next;
      currentPoNumber.value = next.toString();
    } catch (e) {
      debugPrint('[PO FORM] Next PO number error: $e');
    }
  }

  /// Compute the next integer sequence from a raw po_number or id.
  int _nextSequenceFromRaw(String? poNumber, dynamic id) {
    int? base;
    if (poNumber != null && poNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(poNumber);
      if (match != null) {
        base = int.tryParse(match.group(1)!);
      }
    }
    base ??= (id is int) ? id : int.tryParse(id?.toString() ?? '');
    return (base ?? 0) + 1;
  }

  /// Parse integer sequence from po_number suffix, falling back to id.
  int? _sequenceFromRaw(String? poNumber, dynamic id) {
    if (poNumber != null && poNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(poNumber);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null) return parsed;
      }
    }
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  /// Returns latest voucher sequence from the most recent purchase order.
  Future<int?> _fetchLatestSequence() async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
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
      return _sequenceFromRaw(last['po_number']?.toString(), last['id']);
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyPurchaseOrderToState(PurchaseOrder po) async {
    financialYear.value = po.financialYear ?? '25-26';
    supplierId.value = po.supplierId;
    docDate.value = po.docDate;
    expectedDate.value = po.expectedDate ?? '';
    status.value = po.status;
    narration.value = po.narration ?? '';
    currentPoNumber.value = po.poNumber;
    // Update numeric sequence from poNumber if possible.
    if (po.poNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(po.poNumber);
      if (match != null) {
        currentPoSeq.value = int.tryParse(match.group(1)!);
      }
    }
    _loadChargesFromModel(po.chargesJson);
    items.clear();
    for (final item in po.items) {
      items.add(POLineRow(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity.toString(),
        price: item.price.toString(),
        discountPercent: item.discountPercent?.toString() ?? '',
        taxPercent: item.taxPercent?.toString() ?? '',
        unit: item.unit ?? '',
        description: item.description ?? '',
      ));
    }
    if (items.isEmpty) items.add(POLineRow());
    await _hydrateLineItemTaxes();
  }

  Future<void> _hydrateLineItemTaxes() async {
    for (final row in items) {
      final pid = row.productId.value;
      if (pid == null || pid <= 0) continue;
      await applyProductTaxesToRow(row, pid);
    }
  }

  /// Reset the form to a new purchase order state (when navigating to non-existent voucher).
  Future<void> _resetToNewForm() async {
    supplierId.value = null;
    docDate.value = '';
    expectedDate.value = '';
    status.value = 'DRAFT';
    narration.value = '';
    currentPoNumber.value = '';
    _ensureDefaultCharges(reset: true);
    items.clear();
    _setDefaultDocDate();
    await _loadNextPoNumberForNew();
    addItem();
    viewOnly.value = false;
  }

  /// Load a purchase order by a numeric sequence (voucher number).
  Future<void> loadBySequence(int seq) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
        queryParameters: {
          'limit': '1',
          'search': seq.toString(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        await _resetToNewForm();
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        await _resetToNewForm();
        return;
      }
      final List list = data['data'] ?? [];
      if (list.isEmpty) {
        await _resetToNewForm();
        return;
      }
      final summary = list.first as Map<String, dynamic>;
      final idVal = summary['id'];
      final id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
      if (id == null) {
        await _resetToNewForm();
        return;
      }

      // Fetch full details for that purchase order.
      final detailResp = await http.get(
        Uri.parse('${ApiConfig.purchaseOrders}/$id'),
        headers: {'Accept': 'application/json'},
      );
      if (detailResp.statusCode != 200) {
        await _resetToNewForm();
        return;
      }
      final detailData = jsonDecode(detailResp.body) as Map<String, dynamic>;
      if (detailData['success'] != true) {
        await _resetToNewForm();
        return;
      }
      final poData = detailData['data'] as Map<String, dynamic>;
      final po = PurchaseOrder.fromJson(poData);
      await _applyPurchaseOrderToState(po);
      // Navigated vouchers should start in view-only mode.
      viewOnly.value = true;
    } catch (e) {
      debugPrint('[PO FORM] Load by sequence error: $e');
      await _resetToNewForm();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPreviousVoucher() async {
    final current = currentPoSeq.value;
    if (current == null || current <= 1) return;
    await loadBySequence(current - 1);
  }

  Future<void> goToNextVoucher() async {
    final current = currentPoSeq.value;
    if (current == null) return;

    final latest = await _fetchLatestSequence();
    if (latest != null && current >= latest) {
      await _resetToNewForm();
      return;
    }

    await loadBySequence(current + 1);
  }

  Future<void> _loadPurchaseOrder() async {
    if (poId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseOrders}/$poId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final poData = data['data'] as Map<String, dynamic>;
          final po = PurchaseOrder.fromJson(poData);
          financialYear.value = po.financialYear ?? '25-26';
          supplierId.value = po.supplierId;
          docDate.value = po.docDate;
          expectedDate.value = po.expectedDate ?? '';
          status.value = po.status;
          narration.value = po.narration ?? '';
          currentPoNumber.value = po.poNumber;
          _loadChargesFromModel(po.chargesJson);
          items.clear();
          for (final item in po.items) {
            items.add(POLineRow(
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity.toString(),
              price: item.price.toString(),
              discountPercent: item.discountPercent?.toString() ?? '',
              taxPercent: item.taxPercent?.toString() ?? '',
              unit: item.unit ?? '',
              description: item.description ?? '',
            ));
          }
          if (items.isEmpty) items.add(POLineRow());
          await _hydrateLineItemTaxes();
        }
      }
    } catch (e) {
      debugPrint('[PO FORM] Load PO error: $e');
      _showError('Failed to load purchase order');
    } finally {
      isLoading.value = false;
    }
  }

  void setFinancialYear(String v) => financialYear.value = v;
  void setSupplierId(int? v) => supplierId.value = v;
  void setDocDate(String v) => docDate.value = v;
  void setExpectedDate(String v) => expectedDate.value = v;
  void setStatus(String v) => status.value = v;
  void setNarration(String v) => narration.value = v;

  void addItem() {
    final row = POLineRow();
    if (unitTypes.isNotEmpty && row.unit.value.isEmpty) {
      row.unit.value = unitTypes.first;
    }
    items.add(row);
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  bool get isEditMode => poId != null;
  bool get isReadOnly => viewOnly.value || status.value != 'DRAFT';

  double get itemsSubtotalExclTax {
    double value = 0;
    for (final row in items) {
      value += row.lineTotalExclTax;
    }
    return value;
  }

  double get itemsTaxTotal {
    double value = 0;
    for (final row in items) {
      value += (row.lineTotal - row.lineTotalExclTax);
    }
    return value;
  }

  double get sgstTotal => _sumTaxAmountByKey('SGST');
  double get cgstTotal => _sumTaxAmountByKey('CGST');
  double get igstTotal => _sumTaxAmountByKey('IGST');
  double get cessTotal => _sumTaxAmountByKey('CESS');
  double get roffTotal => _sumTaxAmountByKey('ROFF');

  double get itemsTotalInclTax => itemsSubtotalExclTax + itemsTaxTotal;

  double get addOnTotal {
    double total = 0;
    for (final charge in charges) {
      final amount = double.tryParse(charge.amount.value) ?? 0;
      total += amount;
    }
    return total;
  }

  double get grandTotal => itemsTotalInclTax + addOnTotal;

  bool validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (supplierId.value == null) {
      _showError('Please select a supplier');
      return false;
    }
    if (docDate.value.trim().isEmpty) {
      _showError('Please enter document date');
      return false;
    }
    final validItems = items.where((r) => r.productId.value != null).toList();
    if (validItems.isEmpty) {
      _showError('Please add at least one line item');
      return false;
    }
    for (final r in validItems) {
      final qty = double.tryParse(r.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Quantity must be greater than 0 for all lines');
        return false;
      }
      final price = double.tryParse(r.price.value);
      if (price == null || price < 0) {
        _showError('Price must be >= 0 for all lines');
        return false;
      }
    }
    return true;
  }

  Future<void> save() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      final validItems = items
          .where((r) => r.productId.value != null && r.quantity.value.trim().isNotEmpty)
          .toList();
      if (validItems.isEmpty) {
        _showError('Please add at least one line item');
        isSaving.value = false;
        return;
      }

      final payload = {
        'financial_year': financialYear.value,
        'supplier_id': supplierId.value,
        'doc_date': docDate.value,
        if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
        'status': status.value,
        if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
        'charges': charges
          .map((row) => {
              'name': row.name.value,
              'amount': double.tryParse(row.amount.value) ?? 0,
              if (row.remarks.value.trim().isNotEmpty)
              'remarks': row.remarks.value.trim(),
            })
          .toList(),
        'items': validItems.asMap().entries.map((e) {
          final r = e.value;
          final productId = r.productId.value!;
          final qty = double.tryParse(r.quantity.value) ?? 0;
          final price = double.tryParse(r.price.value) ?? 0;
          final discount = double.tryParse(r.discountPercent.value);
          final sgst = double.tryParse(r.sgst.value) ?? 0;
          final cgst = double.tryParse(r.cgst.value) ?? 0;
          final igst = double.tryParse(r.igst.value) ?? 0;
          final cess = double.tryParse(r.cess.value) ?? 0;
          final roff = double.tryParse(r.roff.value) ?? 0;
          final taxFromBreakdown = sgst + cgst + igst + cess + roff;
          final tax = taxFromBreakdown > 0
              ? taxFromBreakdown
              : (double.tryParse(r.taxPercent.value));
          return {
            'product_id': productId,
            'line_no': e.key + 1,
            if (r.unit.value.trim().isNotEmpty) 'unit': r.unit.value.trim(),
            'quantity': qty,
            'price': price,
            if (discount != null && discount > 0) 'discount_percent': discount,
            if (tax != null && tax > 0) 'tax_percent': tax,
            if (r.description.value.trim().isNotEmpty) 'description': r.description.value.trim(),
          };
        }).toList(),
      };

      final isCreate = poId == null;
      final url = isCreate
          ? ApiConfig.purchaseOrders
          : '${ApiConfig.purchaseOrders}/$poId';

      final response = isCreate
          ? await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final successMessage =
            isCreate ? 'Purchase order created' : 'Purchase order updated';

        // Brief buffer so users see submit completion before navigation.
        await Future.delayed(const Duration(milliseconds: 450));
        await Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14,
        );

        Get.back(result: true);
      } else {
        _showError(data['message']?.toString() ?? 'Failed to save');
      }
    } catch (e) {
      debugPrint('[PO FORM] Save error: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  void _loadChargesFromModel(List<PurchaseOrderCharge> source) {
    if (source.isEmpty) {
      _ensureDefaultCharges(reset: true);
      return;
    }
    charges.assignAll(
      source
          .map(
            (charge) => POChargeRow(
              name: charge.name,
              amount: charge.amount.toStringAsFixed(2),
              remarks: charge.remarks ?? '',
            ),
          )
          .toList(),
    );
  }

  void _ensureDefaultCharges({bool reset = false}) {
    if (!reset && charges.isNotEmpty) return;
    charges.assignAll([
      POChargeRow(name: 'Hamali', amount: '0'),
    ]);
  }

  void addChargeRow() {
    charges.add(POChargeRow(name: chargeTypeNames.first, amount: '0'));
  }

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) {
      charges.removeAt(index);
    }
    if (charges.isEmpty) {
      _ensureDefaultCharges(reset: true);
    }
  }

  double _sumTaxAmountByKey(String key) {
    double total = 0;
    for (final row in items) {
      final percent = double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
      if (percent <= 0) continue;
      total += row.lineTotalExclTax * percent / 100;
    }
    return total;
  }
}

class POLineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final quantity = '1'.obs;
  final price = '0'.obs;
  final discountPercent = ''.obs;
  final taxPercent = ''.obs;
  // Whether the entered unit price is inclusive of tax (true) or exclusive (false).
  final isInclusiveTax = false.obs;
  // Detailed tax breakdown (frontend only for now, default 0).
  final sgst = ''.obs;
  final cgst = ''.obs;
  final igst = ''.obs;
  final cess = ''.obs;
  final roff = ''.obs;
  final taxFieldValues = <String, String>{}.obs;
  final availableTaxKeys = <String>[].obs;
  final isTaxLoading = false.obs;
  final unit = 'PCS'.obs;
  final description = ''.obs;

  POLineRow({
    int? productId,
    String? productName,
    String? quantity,
    String? price,
    String? discountPercent,
    String? taxPercent,
    String? unit,
    String? description,
  }) {
    if (productId != null) this.productId.value = productId;
    if (productName != null) this.productName.value = productName;
    if (quantity != null) this.quantity.value = quantity;
    if (price != null) this.price.value = price;
    if (discountPercent != null) this.discountPercent.value = discountPercent;
    if (taxPercent != null) this.taxPercent.value = taxPercent;
    if (unit != null) this.unit.value = unit;
    if (description != null) this.description.value = description;
  }

  /// Price excluding tax (stored).
  double get priceExclTax => double.tryParse(price.value) ?? 0;

  /// Total tax percent from breakdown (sgst+cgst+igst+cess+roff) or taxPercent.
  double get _effectiveTaxPercent {
    final fromTaxPercent = double.tryParse(taxPercent.value) ?? 0;
    if (fromTaxPercent > 0) return fromTaxPercent;

    final sgst = double.tryParse(this.sgst.value) ?? 0;
    final cgst = double.tryParse(this.cgst.value) ?? 0;
    final igst = double.tryParse(this.igst.value) ?? 0;
    final cess = double.tryParse(this.cess.value) ?? 0;
    final roff = double.tryParse(this.roff.value) ?? 0;
    final fromBreakdown = sgst + cgst + igst + cess + roff;
    if (fromBreakdown > 0) return fromBreakdown;
    return 0;
  }

  /// Price including tax (computed).
  double get priceInclTax {
    final raw = double.tryParse(price.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) {
      return raw;
    }
    return raw * (1 + t / 100);
  }

  /// Line total excluding tax.
  double get lineTotalExclTax {
    final qty = double.tryParse(quantity.value) ?? 0;
    final p = isInclusiveTax.value
        ? _priceExclFromInclusive()
        : (double.tryParse(price.value) ?? 0);
    final d = double.tryParse(discountPercent.value) ?? 0;
    return qty * p * (1 - d / 100);
  }

  /// Line total including tax.
  double get lineTotal {
    final qty = double.tryParse(quantity.value) ?? 0;
    final pExcl = isInclusiveTax.value
        ? _priceExclFromInclusive()
        : (double.tryParse(price.value) ?? 0);
    final d = double.tryParse(discountPercent.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) {
      final pIncl = double.tryParse(price.value) ?? 0;
      return qty * pIncl * (1 - d / 100);
    }
    return qty * pExcl * (1 - d / 100) * (1 + t / 100);
  }

  double _priceExclFromInclusive() {
    final pIncl = double.tryParse(price.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (t <= 0) return pIncl;
    return pIncl / (1 + t / 100);
  }
}

class POChargeRow {
  final name = ''.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;

  POChargeRow({
    required String name,
    String? amount,
    String? remarks,
  }) {
    if (name.isNotEmpty) this.name.value = name;
    if (amount != null) this.amount.value = amount;
    if (remarks != null) this.remarks.value = remarks;
  }
}
