import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/charge_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/party_result.dart';
import '../models/product_model.dart';
import '../models/sales_order_model.dart';
import '../services/customer_api_service.dart';

class SalesOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? soId;
  final bool startInViewOnly;

  final departments = <Map<String, dynamic>>[].obs;
  final salesmen = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;
  final isBrowsing = false.obs;

  final currentSoNumber = ''.obs;
  final RxnInt currentSoSeq = RxnInt();

  final financialYear = '25-26'.obs;
  final customerId = Rxn<int>();
  final customerName = ''.obs;
  final customerPhone = ''.obs;
  final customerShopName = ''.obs;
  final departmentId = Rxn<String>();
  final salesmanId = Rxn<String>();
  final salesmanName = ''.obs;
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;
  // Bill / Invoice fields
  final billDt = ''.obs;
  final billDepartment = ''.obs;
  final billNarration = ''.obs;
  final billVehicle = ''.obs;
  final billStatement = ''.obs;
  final billRoff = '0'.obs;
  final billDocYear = ''.obs;
  final charges = <SOChargeRow>[].obs;

  final items = <SOLineRow>[].obs;

  int? _adminVendorId;
  String _companyState = '';
  String _customerState = '';

  final isLoading = false.obs;
  final isSaving = false.obs;

  static const List<String> chargeTypeNames = addonChargeTypeNames;

  SalesOrderFormController({this.soId, this.startInViewOnly = false});

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    _ensureDefaultCharges();
    _loadAdminVendorId();
    _loadDepartments();
    _loadSalesmen();
    _loadUnitTypes();
    AuthController.getCompanyState().then((s) => _companyState = s);
    if (soId != null) {
      _loadSalesOrder();
    } else {
      _setDefaultDocDate();
      _loadNextSoNumberForNew();
      billDepartment.value = 'Sales';
      addItem();
    }
  }

  Future<void> _loadAdminVendorId() async {
    _adminVendorId = await AuthController.getAdminId();
  }

  Future<List<Map<String, dynamic>>> _searchAllProducts(String query) async {
    try {
      final params = <String, String>{
        'limit': '50',
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (_adminVendorId != null) 'admin_vendor_id': _adminVendorId.toString(),
        if (salesmanId.value != null && salesmanId.value!.isNotEmpty)
          'supplier_id': salesmanId.value!,
      };
      final uri = Uri.parse(ApiConfig.vendorProducts).replace(queryParameters: params);
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

  // Searches without supplier filter — used by the "Show all products" toggle.
  Future<List<Product>> searchAllProductsUnfiltered(String query) async {
    try {
      final params = <String, String>{
        'limit': '50',
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (_adminVendorId != null) 'admin_vendor_id': _adminVendorId.toString(),
      };
      final uri = Uri.parse(ApiConfig.vendorProducts).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) {
            try { return Product.fromJson(e); } catch (_) { return null; }
          })
          .whereType<Product>()
          .toList();
    } catch (e) {
      debugPrint('[SO FORM] Search all products error: $e');
      return [];
    }
  }

  Future<void> applyProductTaxesToRow(SOLineRow row, int productId) async {
    _clearTaxBreakdown(row);
    _applyFixedGst(row);
  }

  // SGST = 2.5%, CGST = 2.5%, IGST = 5% — fixed for all products.
  // State-based filtering then keeps only SGST+CGST or only IGST.
  void _applyFixedGst(SOLineRow row) {
    final sameState = _isSameState();
    if (sameState) {
      row.sgst.value = '2.50';
      row.cgst.value = '2.50';
      row.taxFieldValues['SGST'] = '2.50';
      row.taxFieldValues['CGST'] = '2.50';
      row.availableTaxKeys.assignAll(['SGST', 'CGST']);
      row.taxPercent.value = '5.00';
    } else {
      row.igst.value = '5.00';
      row.taxFieldValues['IGST'] = '5.00';
      row.availableTaxKeys.assignAll(['IGST']);
      row.taxPercent.value = '5.00';
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

  bool _isSameState() {
    final company = _companyState.trim().toLowerCase();
    final customer = _customerState.trim().toLowerCase();
    if (company.isEmpty || customer.isEmpty) return true;
    return company == customer;
  }

  void _setDefaultDocDate() {
    final now = DateTime.now();
    docDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _autoSetExpectedDate(docDate.value);
  }

  void _autoSetExpectedDate(String fromDate) {
    final parsed = DateTime.tryParse(fromDate);
    if (parsed == null) return;
    final next = parsed.add(const Duration(days: 1));
    expectedDate.value =
        '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
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
          // Auto-select 'Sales' department if none is set yet
          if (departmentId.value == null) {
            final sales = departments.firstWhereOrNull(
              (d) => (d['name'] ?? '').toString().toLowerCase() == 'sales',
            );
            if (sales != null) {
              departmentId.value = sales['id']?.toString();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SO FORM] Load departments error: $e');
    }
  }

  Future<void> _loadSalesmen() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.salesmen).replace(queryParameters: {'role': 'salesman', 'limit': '500'}),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      salesmen.value = (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'id': e['id']?.toString(),
                'name': (e['name'] ?? '').toString(),
              })
          .where((e) => (e['id'] ?? '').isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[SO FORM] Load salesmen error: $e');
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
      debugPrint('[SO] Load unit types error: $e');
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
    salesmanId.value = so.salesmanId;
    if (so.salesmanId != null) {
      final match = salesmen.firstWhereOrNull((s) => s['id'] == so.salesmanId);
      salesmanName.value = match?['name']?.toString() ?? '';
    } else {
      salesmanName.value = '';
    }
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
    billDt.value = so.billDt ?? '';
    billDepartment.value = so.department ?? '';
    billNarration.value = so.billNarration ?? '';
    billVehicle.value = so.billVehicle ?? '';
    billStatement.value = so.billStatement ?? '';
    billRoff.value = so.billRoff?.toStringAsFixed(2) ?? '0';
    billDocYear.value = so.docYear ?? '';
    _loadChargesFromModel(so.chargesJson);
    unawaited(_hydrateCustomerDetails(so.customerId));
    items.clear();
    for (final item in so.items) {
      items.add(SOLineRow(
        productId: item.productId,
        productName: item.productName,
        hsnCode: item.hsnCode,
        quantity: item.quantity.toString(),
        qtyDelivered: item.usedQty.toString(),
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
    isBrowsing.value = false;
    customerId.value = null;
    customerName.value = '';
    customerPhone.value = '';
    customerShopName.value = '';
    _customerState = '';
    departmentId.value = null;
    salesmanId.value = null;
    salesmanName.value = '';
    docDate.value = '';
    expectedDate.value = '';
    status.value = 'DRAFT';
    narration.value = '';
    billDt.value = '';
    billDepartment.value = 'Sales';
    billNarration.value = '';
    billVehicle.value = '';
    billStatement.value = '';
    billRoff.value = '0';
    billDocYear.value = '';
    currentSoNumber.value = '';
    _ensureDefaultCharges(reset: true);
    items.clear();
    _setDefaultDocDate();
    await _loadNextSoNumberForNew();
    addItem();
    viewOnly.value = false;
  }

  Future<void> loadBySequence(int seq) async {
    isBrowsing.value = true;
    try {
      isLoading.value = true;
      final id = await _findSalesOrderIdBySequence(seq);
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

  Future<void> goToVoucherByNumber(int n) async {
    try {
      isLoading.value = true;
      final id = await _findSalesOrderIdBySequence(n);
      if (id == null) {
        final currentNext = currentSoSeq.value;
        if (currentNext != null && n < currentNext) {
          await _resetToNewForm();
          currentSoSeq.value = n;
          currentSoNumber.value = n.toString();
          return;
        }
        _showError('Voucher #$n not found');
        return;
      }
      final detailResp = await http
          .get(Uri.parse('${ApiConfig.salesOrders}/$id'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (detailResp.statusCode != 200) { _showError('Voucher #$n not found'); return; }
      final detailData = jsonDecode(detailResp.body) as Map<String, dynamic>;
      if (detailData['success'] != true) { _showError('Voucher #$n not found'); return; }
      final so = SalesOrder.fromJson(detailData['data'] as Map<String, dynamic>);
      isBrowsing.value = true;
      await _applySalesOrderToState(so);
    } catch (e) {
      _showError('Voucher #$n not found');
    } finally {
      isLoading.value = false;
    }
  }

  Future<int?> _findSalesOrderIdBySequence(int seq) async {
    try {
      const pageSize = 100;
      var page = 1;
      while (true) {
        final uri = Uri.parse(ApiConfig.salesOrders).replace(
          queryParameters: {'limit': pageSize.toString(), 'page': page.toString()},
        );
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return null;
        final List list = data['data'] ?? [];
        if (list.isEmpty) return null;
        for (final item in list.whereType<Map<String, dynamic>>()) {
          if (_sequenceFromRaw(item['so_number']?.toString(), item['id']) == seq) {
            final idVal = item['id'];
            return idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
          }
        }
        if (list.length < pageSize) return null;
        page++;
      }
    } catch (e) {
      debugPrint('[SO FORM] Find sequence error: $e');
      return null;
    }
  }

  Future<void> resetToNewForm() => _resetToNewForm();

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
          salesmanId.value = so.salesmanId;
          if (so.salesmanId != null) {
            final sm = salesmen.firstWhereOrNull((s) => s['id'] == so.salesmanId);
            salesmanName.value = sm?['name']?.toString() ?? '';
          } else {
            salesmanName.value = '';
          }
          docDate.value = so.docDate;
          expectedDate.value = so.expectedDate ?? '';
          status.value = so.status;
          narration.value = so.narration ?? '';
          currentSoNumber.value = so.soNumber;
          billDt.value = so.billDt ?? '';
          billDepartment.value = so.department ?? '';
          billNarration.value = so.billNarration ?? '';
          billVehicle.value = so.billVehicle ?? '';
          billStatement.value = so.billStatement ?? '';
          billRoff.value = so.billRoff?.toStringAsFixed(2) ?? '0';
          billDocYear.value = so.docYear ?? '';
          _loadChargesFromModel(so.chargesJson);
          items.clear();
          for (final item in so.items) {
            items.add(SOLineRow(
              productId: item.productId,
              productName: item.productName,
              hsnCode: item.hsnCode,
              quantity: item.quantity.toString(),
              qtyDelivered: item.usedQty.toString(),
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
    _customerState = customer.state?.trim() ?? '';
    // Re-apply taxes on all loaded items since state may have changed
    for (final item in items) {
      final pid = item.productId.value;
      if (pid != null && pid > 0) {
        unawaited(applyProductTaxesToRow(item, pid));
      }
    }
  }
  void setDepartmentId(String? v) => departmentId.value = v;

  void setSalesman(String? id, String name) {
    salesmanId.value = id;
    salesmanName.value = name;
  }

  void setSalesmanId(String? v) {
    salesmanId.value = v;
    if (v == null || v.isEmpty) {
      salesmanName.value = '';
    } else {
      final match = salesmen.firstWhereOrNull((s) => s['id'] == v);
      salesmanName.value = match?['name']?.toString() ?? '';
    }
  }

  Future<List<PartyResult>> searchSalesmen(String query) async {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? salesmen
        : salesmen.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            return name.contains(q);
          }).toList();
    return filtered
        .map((s) => PartyResult(
              id: int.tryParse(s['id']?.toString() ?? '0') ?? 0,
              name: s['name']?.toString() ?? '',
              phone: null,
              shopName: null,
              code: s['id']?.toString(),
              state: null,
            ))
        .toList();
  }
  void setDocDate(String v) {
    docDate.value = v;
    if (expectedDate.value.isEmpty) _autoSetExpectedDate(v);
  }
  void setExpectedDate(String v) => expectedDate.value = v;
  void setStatus(String v) => status.value = v;
  void setNarration(String v) => narration.value = v;

  bool get isBillMode => status.value == 'BILLED';

  void setBillDt(String v) => billDt.value = v;
  void setBillDepartment(String v) => billDepartment.value = v;
  void setBillNarration(String v) => billNarration.value = v;
  void setBillVehicle(String v) => billVehicle.value = v;
  void setBillStatement(String v) => billStatement.value = v;
  void setBillRoff(String v) => billRoff.value = v;
  void setBillDocYear(String v) => billDocYear.value = v;

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
  bool get _isEditable => status.value == 'DRAFT' || status.value == 'PENDING';
  // Controls layout: false = show form layout, true = show report/detail view.
  bool get isReadOnly => !isBrowsing.value && (viewOnly.value || !_isEditable);
  // Controls field editability: true = all inputs disabled.
  bool get isFieldsLocked => viewOnly.value || !_isEditable;

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

    isBrowsing.value = false;
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
        if (salesmanId.value != null && salesmanId.value!.trim().isNotEmpty)
          'supplier_id': salesmanId.value,
        'doc_date': docDate.value,
        if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
        'status': status.value,
        if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
        if (billDt.value.trim().isNotEmpty) 'bill_dt': billDt.value.trim(),
        if (billDepartment.value.trim().isNotEmpty) 'department': billDepartment.value.trim(),
        if (billNarration.value.trim().isNotEmpty) 'bill_narration': billNarration.value.trim(),
        if (billVehicle.value.trim().isNotEmpty) 'bill_vehicle': billVehicle.value.trim(),
        if (billStatement.value.trim().isNotEmpty) 'bill_statement': billStatement.value.trim(),
        'bill_roff': double.tryParse(billRoff.value) ?? 0,
        if (billDocYear.value.trim().isNotEmpty) 'doc_year': billDocYear.value.trim(),
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
            'qty_delivered': double.tryParse(r.qtyDelivered.value) ?? 0,
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
  final qtyDelivered = '0'.obs;
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
    String? qtyDelivered,
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
    if (qtyDelivered != null) this.qtyDelivered.value = qtyDelivered;
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
