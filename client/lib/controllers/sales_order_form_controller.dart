import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/charge_constants.dart';
import '../models/party_result.dart';
import '../models/product_model.dart';
import '../models/sales_order_model.dart';
import '../services/customer_api_service.dart';

class SalesOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? soId;
  final bool startInViewOnly;

  final customers = <Map<String, dynamic>>[].obs;
  final departments = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;

  final currentSoNumber = ''.obs;
  final RxnInt currentSoSeq = RxnInt();

  final financialYear = '25-26'.obs;
  final customerId = Rxn<int>();
  final customerName = ''.obs;
  final customerPhone = ''.obs;
  final customerShopName = ''.obs;
  final departmentId = Rxn<String>();
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;
  final charges = <SOChargeRow>[].obs;

  final items = <SOLineRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  static const List<String> chargeTypeNames = addonChargeTypeNames;

  SalesOrderFormController({this.soId, this.startInViewOnly = false});

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    _ensureDefaultCharges();
    _loadCustomers();
    _loadDepartments();
    _loadUnitTypes();
    if (soId != null) {
      _loadSalesOrder();
    } else {
      _setDefaultDocDate();
      _loadNextSoNumberForNew();
      addItem();
    }
  }

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
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('[SO FORM] Search products error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) =>
      _searchAllProducts(query);

  Future<List<Product>> searchProductsAsModels(String query) async {
    final raw = await _searchAllProducts(query);
    return raw
        .map((e) {
          try {
            return Product.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Product>()
        .toList();
  }

  Future<void> applyProductTaxesToRow(SOLineRow row, int productId) async {
    row.isTaxLoading.value = true;
    _clearTaxBreakdown(row);
    try {
      final productTaxes = await _fetchProductTaxRows(productId);
      final applied = _applyTaxRowsToRow(row, productTaxes);
      if (!applied) {
        row.taxPercent.value = '';
      }
    } catch (e) {
      debugPrint('[SO FORM] Resolve taxes error: $e');
      row.taxPercent.value = '';
    } finally {
      row.isTaxLoading.value = false;
    }
  }

  void _clearTaxBreakdown(SOLineRow row) {
    row.sgst.value = '';
    row.cgst.value = '';
    row.igst.value = '';
    row.cess.value = '';
    row.roff.value = '';
    row.taxFieldValues.clear();
    row.availableTaxKeys.clear();
  }

  bool _applyTaxRowsToRow(SOLineRow row, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return false;
    var applied = false;
    var totalPercent = 0.0;
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

  Future<void> _loadCustomers() async {
    try {
      final list = await CustomerApiService.fetchCustomers(limit: 500);
      customers.value = list
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'phone': c.contactNumber ?? '',
                'shop_name': c.shopName ?? '',
                'display_name': c.displayName,
              })
          .toList();
    } catch (e) {
      debugPrint('[SO FORM] Load customers error: $e');
    }
  }

  String get customerDisplayTitle =>
      customerName.value.trim().isEmpty ? '-' : customerName.value.trim();

  String get customerDisplaySubtitle {
    final parts = <String>[];
    final shop = customerShopName.value.trim();
    final phone = customerPhone.value.trim();
    if (shop.isNotEmpty) parts.add(shop);
    if (phone.isNotEmpty) parts.add(phone);
    return parts.join(' • ');
  }

  String get customerDisplayLabel {
    final parts = <String>[];
    final name = customerName.value.trim();
    final shop = customerShopName.value.trim();
    final phone = customerPhone.value.trim();
    if (name.isNotEmpty) parts.add(name);
    if (shop.isNotEmpty) parts.add(shop);
    if (phone.isNotEmpty) parts.add(phone);
    return parts.join(' • ');
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          departments.value = list
              .map((e) => {
                    'id': (e as Map)['id']?.toString(),
                    'name': (e)['name']?.toString() ?? 'Department ${(e)['id'] ?? ''}',
                  })
              .where((e) => (e['id'] ?? '').toString().isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SO FORM] Load departments error: $e');
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

  Future<void> _loadNextSoNumberForNew() async {
    try {
      final uri = Uri.parse(ApiConfig.salesOrders).replace(
        queryParameters: {'limit': '1'},
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final List list = data['data'] ?? [];
      if (list.isEmpty) {
        currentSoSeq.value = 1;
        currentSoNumber.value = '1';
        return;
      }
      final last = list.first as Map<String, dynamic>;
      final next = _nextSequenceFromRaw(last['so_number']?.toString(), last['id']);
      currentSoSeq.value = next;
      currentSoNumber.value = next.toString();
    } catch (e) {
      debugPrint('[SO FORM] Next SO number error: $e');
    }
  }

  int _nextSequenceFromRaw(String? soNumber, dynamic id) {
    int? base;
    if (soNumber != null && soNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(soNumber);
      if (match != null) {
        base = int.tryParse(match.group(1)!);
      }
    }
    base ??= (id is int) ? id : int.tryParse(id?.toString() ?? '');
    return (base ?? 0) + 1;
  }

  int? _sequenceFromRaw(String? soNumber, dynamic id) {
    if (soNumber != null && soNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(soNumber);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null) return parsed;
      }
    }
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<int?> _fetchLatestSequence() async {
    try {
      final uri = Uri.parse(ApiConfig.salesOrders).replace(
        queryParameters: {'limit': '1'},
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
      return _sequenceFromRaw(last['so_number']?.toString(), last['id']);
    } catch (_) {
      return null;
    }
  }

  Future<void> _applySalesOrderToState(SalesOrder so) async {
    financialYear.value = so.financialYear ?? '25-26';
    customerId.value = so.customerId;
    customerName.value = so.customerName ?? '';
    customerPhone.value = '';
    customerShopName.value = '';
    departmentId.value = so.departmentId;
    docDate.value = so.docDate;
    expectedDate.value = so.expectedDate ?? '';
    status.value = so.status;
    narration.value = so.narration ?? '';
    currentSoNumber.value = so.soNumber;
    if (so.soNumber.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(so.soNumber);
      if (match != null) {
        currentSoSeq.value = int.tryParse(match.group(1)!);
      }
    }
    _loadChargesFromModel(so.chargesJson);
    unawaited(_hydrateCustomerDetails(so.customerId));
    items.clear();
    for (final item in so.items) {
      items.add(SOLineRow(
        productId: item.productId,
        productName: item.productName,
        hsnCode: item.hsnCode,
        quantity: item.quantity.toString(),
        usedQty: item.usedQty.toString(),
        writeoffQty: item.writeoffQty.toString(),
        leftQty: item.leftQty.toString(),
        price: item.price.toString(),
        discountPercent: item.discountPercent?.toString() ?? '',
        taxPercent: item.taxPercent?.toString() ?? '',
        unit: item.unit ?? '',
        description: item.description ?? '',
      ));
    }
    if (items.isEmpty) items.add(SOLineRow());
    await _hydrateLineItemTaxes();
  }

  Future<void> _hydrateLineItemTaxes() async {
    for (final row in items) {
      final pid = row.productId.value;
      if (pid == null || pid <= 0) continue;
      await applyProductTaxesToRow(row, pid);
    }
  }

  Future<void> _resetToNewForm() async {
    customerId.value = null;
    customerName.value = '';
    customerPhone.value = '';
    customerShopName.value = '';
    departmentId.value = null;
    docDate.value = '';
    expectedDate.value = '';
    status.value = 'DRAFT';
    narration.value = '';
    currentSoNumber.value = '';
    _ensureDefaultCharges(reset: true);
    items.clear();
    _setDefaultDocDate();
    await _loadNextSoNumberForNew();
    addItem();
    viewOnly.value = false;
  }

  Future<void> loadBySequence(int seq) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.salesOrders).replace(
        queryParameters: {'limit': '1', 'search': seq.toString()},
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) { await _resetToNewForm(); return; }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) { await _resetToNewForm(); return; }
      final List list = data['data'] ?? [];
      if (list.isEmpty) { await _resetToNewForm(); return; }
      final summary = list.first as Map<String, dynamic>;
      final idVal = summary['id'];
      final id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
      if (id == null) { await _resetToNewForm(); return; }

      final detailResp = await http.get(
        Uri.parse('${ApiConfig.salesOrders}/$id'),
        headers: {'Accept': 'application/json'},
      );
      if (detailResp.statusCode != 200) { await _resetToNewForm(); return; }
      final detailData = jsonDecode(detailResp.body) as Map<String, dynamic>;
      if (detailData['success'] != true) { await _resetToNewForm(); return; }
      final soData = detailData['data'] as Map<String, dynamic>;
      final so = SalesOrder.fromJson(soData);
      await _applySalesOrderToState(so);
      viewOnly.value = true;
    } catch (e) {
      debugPrint('[SO FORM] Load by sequence error: $e');
      await _resetToNewForm();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPreviousVoucher() async {
    final current = currentSoSeq.value;
    if (current == null || current <= 1) return;
    await loadBySequence(current - 1);
  }

  Future<void> goToNextVoucher() async {
    final current = currentSoSeq.value;
    if (current == null) return;
    final latest = await _fetchLatestSequence();
    if (latest != null && current >= latest) {
      await _resetToNewForm();
      return;
    }
    await loadBySequence(current + 1);
  }

  Future<void> _loadSalesOrder() async {
    if (soId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.salesOrders}/$soId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final soData = data['data'] as Map<String, dynamic>;
          final so = SalesOrder.fromJson(soData);
          financialYear.value = so.financialYear ?? '25-26';
          customerId.value = so.customerId;
          departmentId.value = so.departmentId;
          docDate.value = so.docDate;
          expectedDate.value = so.expectedDate ?? '';
          status.value = so.status;
          narration.value = so.narration ?? '';
          currentSoNumber.value = so.soNumber;
          _loadChargesFromModel(so.chargesJson);
          items.clear();
          for (final item in so.items) {
            items.add(SOLineRow(
              productId: item.productId,
              productName: item.productName,
              hsnCode: item.hsnCode,
              quantity: item.quantity.toString(),
              usedQty: item.usedQty.toString(),
              writeoffQty: item.writeoffQty.toString(),
              leftQty: item.leftQty.toString(),
              price: item.price.toString(),
              discountPercent: item.discountPercent?.toString() ?? '',
              taxPercent: item.taxPercent?.toString() ?? '',
              unit: item.unit ?? '',
              description: item.description ?? '',
            ));
          }
          if (items.isEmpty) items.add(SOLineRow());
          await _hydrateLineItemTaxes();
        }
      }
    } catch (e) {
      debugPrint('[SO FORM] Load SO error: $e');
      _showError('Failed to load sales order');
    } finally {
      isLoading.value = false;
    }
  }

  void setFinancialYear(String v) => financialYear.value = v;
  void setCustomerId(int? v) => customerId.value = v;
  void setCustomer(int id, String name, {String? phone, String? shopName}) {
    customerId.value = id;
    customerName.value = name;
    customerPhone.value = phone ?? '';
    customerShopName.value = shopName ?? '';
  }

  Future<List<PartyResult>> searchCustomers(String query) async {
    try {
      return await CustomerApiService.searchPartyResults(query: query, limit: 50);
    } catch (_) {
      return [];
    }
  }

  Future<void> _hydrateCustomerDetails(int? id) async {
    if (id == null) return;
    final customer = await CustomerApiService.fetchCustomerById(id);
    if (customer == null || customerId.value != id) return;
    customerName.value = customer.name;
    customerPhone.value = customer.contactNumber ?? '';
    customerShopName.value = customer.shopName ?? '';
  }
  void setDepartmentId(String? v) => departmentId.value = v;
  void setDocDate(String v) => docDate.value = v;
  void setExpectedDate(String v) => expectedDate.value = v;
  void setStatus(String v) => status.value = v;
  void setNarration(String v) => narration.value = v;

  void addItem() {
    final row = SOLineRow();
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

  bool get isEditMode => soId != null;
  bool get isReadOnly => viewOnly.value || status.value != 'DRAFT';

  double get itemsSubtotalExclTax {
    double value = 0;
    for (final row in items) { value += row.lineTotalExclTax; }
    return value;
  }

  double get itemsTaxTotal {
    double value = 0;
    for (final row in items) { value += (row.lineTotal - row.lineTotalExclTax); }
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
    if (customerId.value == null) {
      _showError('Please select a customer');
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
        'customer_id': customerId.value,
        if (departmentId.value != null && departmentId.value!.trim().isNotEmpty)
          'department_id': departmentId.value,
        'doc_date': docDate.value,
        if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
        'status': status.value,
        if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
        'charges': charges
            .map((row) => {
                  'name': row.name.value,
                  'amount': double.tryParse(row.amount.value) ?? 0,
                  if (row.remarks.value.trim().isNotEmpty) 'remarks': row.remarks.value.trim(),
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
            if (r.hsnCode.value.trim().isNotEmpty) 'hsn_code': r.hsnCode.value.trim(),
            if (r.unit.value.trim().isNotEmpty) 'unit': r.unit.value.trim(),
            if (r.selectedPackId.value.trim().isNotEmpty) 'pack_id': r.selectedPackId.value.trim(),
            'quantity': qty,
            'price': price,
            if (discount != null && discount > 0) 'discount_percent': discount,
            if (tax != null && tax > 0) 'tax_percent': tax,
            if (r.description.value.trim().isNotEmpty) 'description': r.description.value.trim(),
          };
        }).toList(),
      };

      final isCreate = soId == null;
      final url = isCreate ? ApiConfig.salesOrders : '${ApiConfig.salesOrders}/$soId';

      final response = isCreate
          ? await http.post(
              Uri.parse(url),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : await http.put(
              Uri.parse(url),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        final successMessage = isCreate ? 'Sales order created' : 'Sales order updated';
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
      debugPrint('[SO FORM] Save error: $e');
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

  void _loadChargesFromModel(List<SalesOrderCharge> source) {
    if (source.isEmpty) {
      _ensureDefaultCharges(reset: true);
      return;
    }
    charges.assignAll(
      source.map((charge) => SOChargeRow(
            name: charge.name,
            amount: charge.amount.toStringAsFixed(2),
            remarks: charge.remarks ?? '',
          )).toList(),
    );
  }

  void _ensureDefaultCharges({bool reset = false}) {
    if (!reset && charges.isNotEmpty) return;
    charges.assignAll([SOChargeRow(name: 'Hamali', amount: '0')]);
  }

  void addChargeRow() {
    charges.add(SOChargeRow(name: chargeTypeNames.first, amount: '0'));
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

class SOLineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final hsnCode = ''.obs;
  final quantity = '1'.obs;
  final usedQty = '0'.obs;
  final writeoffQty = '0'.obs;
  final leftQty = '0'.obs;
  final price = '0'.obs;
  final discountPercent = ''.obs;
  final taxPercent = ''.obs;
  final isInclusiveTax = false.obs;
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
  final selectedPackId = ''.obs;
  final selectedPackLabel = ''.obs;

  SOLineRow({
    int? productId,
    String? productName,
    String? hsnCode,
    String? quantity,
    String? usedQty,
    String? writeoffQty,
    String? leftQty,
    String? price,
    String? discountPercent,
    String? taxPercent,
    String? unit,
    String? description,
  }) {
    if (productId != null) this.productId.value = productId;
    if (productName != null) this.productName.value = productName;
    if (hsnCode != null) this.hsnCode.value = hsnCode;
    if (quantity != null) this.quantity.value = quantity;
    if (usedQty != null) this.usedQty.value = usedQty;
    if (writeoffQty != null) this.writeoffQty.value = writeoffQty;
    if (leftQty != null) this.leftQty.value = leftQty;
    if (price != null) this.price.value = price;
    if (discountPercent != null) this.discountPercent.value = discountPercent;
    if (taxPercent != null) this.taxPercent.value = taxPercent;
    if (unit != null) this.unit.value = unit;
    if (description != null) this.description.value = description;
  }

  double get priceExclTax => double.tryParse(price.value) ?? 0;

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

  double get priceInclTax {
    final raw = double.tryParse(price.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) return raw;
    return raw * (1 + t / 100);
  }

  double get lineTotalExclTax {
    final qty = double.tryParse(quantity.value) ?? 0;
    final p = isInclusiveTax.value ? _priceExclFromInclusive() : (double.tryParse(price.value) ?? 0);
    final d = double.tryParse(discountPercent.value) ?? 0;
    return qty * p * (1 - d / 100);
  }

  double get lineTotal {
    final qty = double.tryParse(quantity.value) ?? 0;
    final pExcl = isInclusiveTax.value ? _priceExclFromInclusive() : (double.tryParse(price.value) ?? 0);
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

class SOChargeRow {
  final name = ''.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;

  SOChargeRow({required String name, String? amount, String? remarks}) {
    if (name.isNotEmpty) this.name.value = name;
    if (amount != null) this.amount.value = amount;
    if (remarks != null) this.remarks.value = remarks;
  }
}
