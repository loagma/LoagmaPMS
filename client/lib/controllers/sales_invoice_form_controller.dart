import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/charge_constants.dart';
import 'auth_controller.dart';
import '../models/party_result.dart';
import '../models/product_model.dart';
import '../models/sales_order_model.dart';
import '../services/customer_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Line row — mirrors SOLineRow with full tax support
// ─────────────────────────────────────────────────────────────────────────────

class SILineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final productCode = ''.obs; // HSN code
  final unit = 'PCS'.obs;
  final orderedQty = '0'.obs;
  final qtyDelivered = '1'.obs;
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
  final selectedPackId = ''.obs;
  final selectedPackLabel = ''.obs;

  SILineRow({
    int? productId,
    String? productName,
    String? productCode,
    String? unit,
    String? orderedQty,
    String? qtyDelivered,
    String? price,
    String? discountPercent,
    String? taxPercent,
  }) {
    if (productId != null) this.productId.value = productId;
    if (productName != null) this.productName.value = productName;
    if (productCode != null) this.productCode.value = productCode;
    if (unit != null) this.unit.value = unit;
    if (orderedQty != null) this.orderedQty.value = orderedQty;
    if (qtyDelivered != null) this.qtyDelivered.value = qtyDelivered;
    if (price != null) this.price.value = price;
    if (discountPercent != null) this.discountPercent.value = discountPercent;
    if (taxPercent != null) this.taxPercent.value = taxPercent;
  }

  double get deliveredQtyDouble => double.tryParse(qtyDelivered.value) ?? 0;
  double get orderedQtyDouble => double.tryParse(orderedQty.value) ?? 0;
  double get priceDouble => double.tryParse(price.value) ?? 0;

  double get _effectiveTaxPercent {
    final fromTaxPercent = double.tryParse(taxPercent.value) ?? 0;
    if (fromTaxPercent > 0) return fromTaxPercent;
    final s = double.tryParse(sgst.value) ?? 0;
    final c = double.tryParse(cgst.value) ?? 0;
    final i = double.tryParse(igst.value) ?? 0;
    final cs = double.tryParse(cess.value) ?? 0;
    final r = double.tryParse(roff.value) ?? 0;
    final fromBreakdown = s + c + i + cs + r;
    return fromBreakdown > 0 ? fromBreakdown : 0;
  }

  double get lineTotalExclTax {
    final qty = deliveredQtyDouble;
    final p = isInclusiveTax.value ? _priceExclFromInclusive() : priceDouble;
    final d = double.tryParse(discountPercent.value) ?? 0;
    return qty * p * (1 - d / 100);
  }

  double get lineTotal {
    final qty = deliveredQtyDouble;
    final pExcl = isInclusiveTax.value ? _priceExclFromInclusive() : priceDouble;
    final d = double.tryParse(discountPercent.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) {
      return qty * priceDouble * (1 - d / 100);
    }
    return qty * pExcl * (1 - d / 100) * (1 + t / 100);
  }

  double _priceExclFromInclusive() {
    final t = _effectiveTaxPercent;
    if (t <= 0) return priceDouble;
    return priceDouble / (1 + t / 100);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charge row — mirrors SOChargeRow
// ─────────────────────────────────────────────────────────────────────────────

class SIChargeRow {
  final name = ''.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;

  SIChargeRow({required String name, String? amount, String? remarks}) {
    if (name.isNotEmpty) this.name.value = name;
    if (amount != null) this.amount.value = amount;
    if (remarks != null) this.remarks.value = remarks;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class SalesInvoiceFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? soId;
  final RxBool viewOnly = false.obs;
  final isBrowsing = false.obs;

  static const List<String> chargeTypeNames = addonChargeTypeNames;

  final isLoading = false.obs;
  final isPdfBusy = false.obs;
  final isSaving = false.obs;

  // ── Browse navigation ─────────────────────────────────────────────────────
  final currentBrowseId = Rxn<int>();

  // ── Meta ──────────────────────────────────────────────────────────────────
  final invoiceNumber = ''.obs;
  final invoicePrefix = 'INV/25-26/'.obs;
  final financialYear = '25-26'.obs;
  final currentSoNumber = ''.obs;
  final RxnInt currentSoSeq = RxnInt();

  // ── Customer ──────────────────────────────────────────────────────────────
  final customerId = Rxn<int>();
  final customerName = ''.obs;
  final customerPhone = ''.obs;
  final customerShopName = ''.obs;

  // Step-1 picker (used when creating standalone invoice)
  final selectedCustomerId = Rxn<int>();
  final selectedCustomerName = ''.obs;

  // ── Source order ──────────────────────────────────────────────────────────
  final sourceOrderId = Rxn<int>();
  final sourceOrderNumber = ''.obs;
  final orderDate = ''.obs;
  final availableOrders = <Map<String, dynamic>>[].obs;

  // ── Header fields ─────────────────────────────────────────────────────────
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;
  final departmentId = Rxn<String>();
  final salesmanId = Rxn<String>();
  final salesmanName = ''.obs;

  // ── Bill / Invoice fields ─────────────────────────────────────────────────
  final billDt = ''.obs;
  final billDepartment = ''.obs;
  final billNarration = ''.obs;
  final billVehicle = ''.obs;
  final billStatement = ''.obs;
  final billRoff = '0'.obs;
  final billDocYear = ''.obs;

  // ── Lists ─────────────────────────────────────────────────────────────────
  final departments = <Map<String, dynamic>>[].obs;
  final salesmen = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final charges = <SIChargeRow>[].obs;
  final items = <SILineRow>[].obs;

  // ── Tax state ─────────────────────────────────────────────────────────────
  int? _adminVendorId;
  late final Future<void> _adminVendorIdReady;
  String _companyState = '';
  String _customerState = '';

  final bool _startViewOnly;

  SalesInvoiceFormController({this.soId, bool viewOnly = false}) : _startViewOnly = viewOnly;

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = _startViewOnly;
    _ensureDefaultCharges();
    _adminVendorIdReady = _loadAdminVendorId();
    _loadDepartments();
    _loadSalesmen();
    _loadUnitTypes();
    AuthController.getCompanyState().then((s) => _companyState = s);

    // Default invoice date to today
    billDt.value = _today();
    billDocYear.value = _currentFinancialYear();
    billDepartment.value = 'Sales';

    if (soId != null) {
      currentBrowseId.value = soId;
      _loadOrder(soId!);
    } else {
      _setDefaultDocDate();
      unawaited(_fetchNextInvoiceNumber());
      addItem();
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isEditMode => soId != null;
  bool get _isEditable => status.value == 'DRAFT' || status.value == 'PENDING';
  bool get isReadOnly => !isBrowsing.value && (viewOnly.value || !_isEditable);
  bool get isFieldsLocked => viewOnly.value || !_isEditable;
  bool get isBillMode => status.value == 'BILLED';

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

  double get itemsSubtotalExclTax {
    double v = 0;
    for (final r in items) { v += r.lineTotalExclTax; }
    return v;
  }

  double get itemsTaxTotal {
    double v = 0;
    for (final r in items) { v += (r.lineTotal - r.lineTotalExclTax); }
    return v;
  }

  double get addOnTotal {
    double v = 0;
    for (final c in charges) { v += double.tryParse(c.amount.value) ?? 0; }
    return v;
  }

  double get roffTotal => _sumTaxAmountByKey('ROFF');

  double get grandTotal => itemsSubtotalExclTax + itemsTaxTotal + addOnTotal;

  double _sumTaxAmountByKey(String key) {
    double total = 0;
    for (final row in items) {
      final percent = double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
      if (percent <= 0) continue;
      total += row.lineTotalExclTax * percent / 100;
    }
    return total;
  }

  // ── Initialization helpers ─────────────────────────────────────────────────

  Future<void> _loadAdminVendorId() async {
    _adminVendorId = await AuthController.getAdminId();
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

  Future<void> _loadDepartments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: AuthController.getHeaders,
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
          if (departmentId.value == null) {
            final sales = departments.firstWhereOrNull(
              (d) => (d['name'] ?? '').toString().toLowerCase() == 'sales',
            );
            if (sales != null) departmentId.value = sales['id']?.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[SI FORM] Load departments error: $e');
    }
  }

  Future<void> _loadSalesmen() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.salesmen).replace(queryParameters: {'role': 'salesman', 'limit': '500'}),
        headers: AuthController.getHeaders,
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      salesmen.value = (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => {'id': e['id']?.toString(), 'name': (e['name'] ?? '').toString()})
          .where((e) => (e['id'] ?? '').isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Load salesmen error: $e');
    }
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.unitTypes),
        headers: AuthController.getHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List types = data['data'] ?? [];
          unitTypes.value = types.cast<String>();
        }
      }
    } catch (e) {
      debugPrint('[SI] Load unit types error: $e');
    }
  }

  Future<void> _fetchNextInvoiceNumber() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.salesInvoiceSeries), headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        invoicePrefix.value = data['prefix']?.toString() ?? 'INV/25-26/';
        invoiceNumber.value = data['full_number']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('[SI FORM] Fetch series error: $e');
    }
  }

  // ── Tax ───────────────────────────────────────────────────────────────────

  Future<void> applyProductTaxesToRow(SILineRow row, int productId) async {
    _clearTaxBreakdown(row);
    _applyFixedGst(row);
  }

  void _applyFixedGst(SILineRow row) {
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

  void _clearTaxBreakdown(SILineRow row) {
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

  // ── Customer ──────────────────────────────────────────────────────────────

  void setCustomer(int id, String name, {String? phone, String? shopName}) {
    customerId.value = id;
    customerName.value = name;
    customerPhone.value = phone ?? '';
    customerShopName.value = shopName ?? '';
    selectedCustomerId.value = id;
    selectedCustomerName.value = name;
    unawaited(_hydrateCustomerDetails(id));
    // Clear any previously linked order
    sourceOrderId.value = null;
    sourceOrderNumber.value = '';
    unawaited(_refreshAvailableOrders());
  }

  Future<void> _refreshAvailableOrders() async {
    availableOrders.value = await searchOrders('');
  }

  void selectCustomer(int id, String name) => setCustomer(id, name);

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
    for (final item in items) {
      final pid = item.productId.value;
      if (pid != null && pid > 0) {
        unawaited(applyProductTaxesToRow(item, pid));
      }
    }
  }

  // ── Salesman ──────────────────────────────────────────────────────────────

  void setSalesman(String? id, String name) {
    salesmanId.value = id;
    salesmanName.value = name;
  }

  Future<List<PartyResult>> searchSalesmen(String query) async {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? salesmen
        : salesmen.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(q)).toList();
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

  // ── Setters ───────────────────────────────────────────────────────────────

  void setFinancialYear(String v) => financialYear.value = v;
  void setDepartmentId(String? v) => departmentId.value = v;
  void setDocDate(String v) {
    docDate.value = v;
    if (expectedDate.value.isEmpty) _autoSetExpectedDate(v);
  }

  void setExpectedDate(String v) => expectedDate.value = v;
  void setStatus(String v) => status.value = v;
  void setNarration(String v) => narration.value = v;
  void setBillDt(String v) => billDt.value = v;
  void setBillDepartment(String v) => billDepartment.value = v;
  void setBillNarration(String v) => billNarration.value = v;
  void setBillVehicle(String v) => billVehicle.value = v;
  void setBillStatement(String v) => billStatement.value = v;
  void setBillRoff(String v) => billRoff.value = v;
  void setBillDocYear(String v) => billDocYear.value = v;

  // ── Items ─────────────────────────────────────────────────────────────────

  void addItem() {
    final row = SILineRow(qtyDelivered: '1');
    if (unitTypes.isNotEmpty) row.unit.value = unitTypes.first;
    items.add(row);
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  void applyProduct(SILineRow row, int productId, String name, String? code, String? unit, double price) {
    row.productId.value = productId;
    row.productName.value = name;
    row.productCode.value = code ?? '';
    row.unit.value = unit?.isNotEmpty == true ? unit! : 'Nos';
    row.price.value = price.toString();
    row.orderedQty.value = '0';
    row.qtyDelivered.value = '1';
    unawaited(applyProductTaxesToRow(row, productId));
  }

  // ── Charges ───────────────────────────────────────────────────────────────

  void _ensureDefaultCharges({bool reset = false}) {
    if (!reset && charges.isNotEmpty) return;
    charges.assignAll([SIChargeRow(name: 'Hamali', amount: '0')]);
  }

  void addChargeRow() => charges.add(SIChargeRow(name: chargeTypeNames.first, amount: '0'));

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) charges.removeAt(index);
    if (charges.isEmpty) _ensureDefaultCharges(reset: true);
  }

  // ── Product search ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchProducts(
    String query, {
    bool includeSupplierFilter = true,
  }) async {
    await _adminVendorIdReady;
    try {
      final params = <String, String>{
        'limit': '50',
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (_adminVendorId != null) 'admin_vendor_id': _adminVendorId.toString(),
        if (includeSupplierFilter &&
            salesmanId.value != null &&
            salesmanId.value!.isNotEmpty)
          'supplier_id': salesmanId.value!,
      };
      final uri = Uri.parse(ApiConfig.vendorProducts).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      return (data['data'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('[SI FORM] Search products error: $e');
      return [];
    }
  }

  Future<List<Product>> searchProductsAsModels(String query) async {
    var raw = await searchProducts(query, includeSupplierFilter: true);
    if (raw.isEmpty &&
        salesmanId.value != null &&
        salesmanId.value!.isNotEmpty) {
      raw = await searchProducts(query, includeSupplierFilter: false);
    }
    return raw
        .map((e) { try { return Product.fromJson(e); } catch (_) { return null; } })
        .whereType<Product>()
        .toList();
  }

  Future<List<Product>> searchAllProductsUnfiltered(String query) async {
    await _adminVendorIdReady;
    try {
      final raw = await searchProducts(query, includeSupplierFilter: false);
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) { try { return Product.fromJson(e); } catch (_) { return null; } })
          .whereType<Product>()
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Search all products error: $e');
      return [];
    }
  }

  // ── Order search ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      final params = <String, String>{
        'limit': '50',
        'exclude_closed': 'true',
        if (query.isNotEmpty) 'search': query,
        if (selectedCustomerId.value != null)
          'customer_id': selectedCustomerId.value.toString(),
      };
      final uri = Uri.parse(ApiConfig.salesOrders).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      return (data['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((o) {
            final s = o['status']?.toString().toLowerCase() ?? '';
            return ['pending', 'registered', 'confirmed', 'draft'].contains(s);
          })
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Search orders error: $e');
      return [];
    }
  }

  // ── Load order ────────────────────────────────────────────────────────────

  Future<void> loadOrder(int orderId) => _loadOrder(orderId);

  Future<void> _loadOrder(int orderId) async {
    try {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse('${ApiConfig.salesOrders}/$orderId'), headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final so = SalesOrder.fromJson(data['data'] as Map<String, dynamic>);
      await _applyOrder(so);
      if (so.billNumber != null && so.billNumber!.isNotEmpty) {
        invoiceNumber.value = so.billNumber!;
      } else if (invoiceNumber.value.isEmpty) {
        await _fetchNextInvoiceNumber();
      }
      if (so.billNumber == null || so.billNumber!.isEmpty) {
        Get.snackbar(
          'Order Linked',
          '${so.soNumber} — ${so.items.length} item(s) loaded. Fill invoice details and save.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('[SI FORM] Load order error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInvoiceById(int orderId) async {
    isBrowsing.value = true;
    currentBrowseId.value = orderId;
    try {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse('${ApiConfig.salesOrders}/$orderId'), headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final so = SalesOrder.fromJson(data['data'] as Map<String, dynamic>);
      await _applyOrder(so);
      if (so.billNumber != null && so.billNumber!.isNotEmpty) {
        invoiceNumber.value = so.billNumber!;
      }
    } catch (e) {
      debugPrint('[SI FORM] Browse invoice error: $e');
    } finally {
      isLoading.value = false;
      isBrowsing.value = false;
    }
  }

  Future<void> loadByNumber(int n, {bool allowCreateNewIfMissing = true}) async {
    try {
      isLoading.value = true;
      final id = await _findInvoiceOrderIdByNumber(n);
      if (id == null) {
        final currentNext = _currentInvoiceSequence();
        if (allowCreateNewIfMissing && currentNext != null && n < currentNext) {
          await resetToNewForm();
          invoiceNumber.value = _formatInvoiceNumber(n);
          return;
        }
        if (!allowCreateNewIfMissing) return;
        _showError('Invoice #$n not found');
        return;
      }
      await loadInvoiceById(id);
    } catch (e) {
      _showError('Invoice #$n not found');
    } finally {
      isLoading.value = false;
    }
  }

  int? _currentInvoiceSequence() {
    final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber.value.trim());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int _invoiceSuffixWidth() {
    final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber.value.trim());
    return match?.group(1)?.length ?? 3;
  }

  String _formatInvoiceNumber(int n) {
    return '${invoicePrefix.value}${n.toString().padLeft(_invoiceSuffixWidth(), '0')}';
  }

  int? _invoiceSuffix(String? invoiceNumber) {
    if (invoiceNumber == null || invoiceNumber.isEmpty) return null;
    final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<int?> _findInvoiceOrderIdByNumber(int n) async {
    try {
      const pageSize = 100;
      var page = 1;
      while (true) {
        final uri = Uri.parse(ApiConfig.salesOrders).replace(
          queryParameters: {'limit': pageSize.toString(), 'page': page.toString(), 'has_invoice': 'true'},
        );
        final response = await http
            .get(uri, headers: AuthController.getHeaders)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return null;
        final List list = data['data'] ?? [];
        if (list.isEmpty) return null;
        for (final item in list.whereType<Map<String, dynamic>>()) {
          if (_invoiceSuffix(item['bill_number']?.toString()) == n) {
            final idVal = item['id'];
            return idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
          }
        }
        if (list.length < pageSize) return null;
        page++;
      }
    } catch (e) {
      debugPrint('[SI FORM] Find invoice error: $e');
      return null;
    }
  }

  Future<void> resetToNewForm() async {
    isBrowsing.value = false;
    currentBrowseId.value = null;
    sourceOrderId.value = null;
    sourceOrderNumber.value = '';
    currentSoNumber.value = '';
    currentSoSeq.value = null;
    customerId.value = null;
    selectedCustomerId.value = null;
    customerName.value = '';
    selectedCustomerName.value = '';
    customerPhone.value = '';
    customerShopName.value = '';
    docDate.value = '';
    expectedDate.value = '';
    status.value = 'DRAFT';
    narration.value = '';
    invoiceNumber.value = '';
    billDt.value = _today();
    billDepartment.value = 'Sales';
    billNarration.value = '';
    billVehicle.value = '';
    billStatement.value = '';
    billRoff.value = '0';
    billDocYear.value = _currentFinancialYear();
    items.clear();
    _ensureDefaultCharges(reset: true);
    _setDefaultDocDate();
    await _fetchNextInvoiceNumber();
    addItem();
    viewOnly.value = false;
  }

  Future<void> _applyOrder(SalesOrder so) async {
    sourceOrderId.value = so.id;
    sourceOrderNumber.value = so.soNumber;
    currentSoNumber.value = so.soNumber;
    orderDate.value = so.docDate;

    // Header fields from SO
    financialYear.value = so.financialYear ?? _currentFinancialYear();
    customerId.value = so.customerId;
    customerName.value = so.customerName ?? '';
    selectedCustomerId.value = so.customerId;
    selectedCustomerName.value = so.customerName ?? '';
    departmentId.value = so.departmentId;
    salesmanId.value = so.salesmanId;
    if (so.salesmanId != null && salesmen.isNotEmpty) {
      final match = salesmen.firstWhereOrNull((s) => s['id'] == so.salesmanId);
      salesmanName.value = match?['name']?.toString() ?? '';
    }
    docDate.value = so.docDate;
    expectedDate.value = so.expectedDate ?? '';
    // Keep status as DRAFT for a new invoice being created from a SO.
    // Only restore the actual status when loading an already-billed order.
    if (so.billNumber != null && so.billNumber!.isNotEmpty) {
      status.value = so.status;
      narration.value = so.narration ?? '';
    } else {
      status.value = 'DRAFT';
      // Don't copy SO narration into invoice — leave blank for user to fill
    }

    // Bill fields
    if (so.billDt != null && so.billDt!.isNotEmpty) billDt.value = so.billDt!;
    if (so.department != null && so.department!.isNotEmpty) billDepartment.value = so.department!;
    billNarration.value = so.billNarration ?? '';
    billVehicle.value = so.billVehicle ?? '';
    billStatement.value = so.billStatement ?? '';
    billRoff.value = so.billRoff?.toStringAsFixed(2) ?? '0';
    if (so.docYear != null && so.docYear!.isNotEmpty) billDocYear.value = so.docYear!;

    // Charges
    if (so.chargesJson.isNotEmpty) {
      charges.assignAll(so.chargesJson.map((c) => SIChargeRow(
            name: c.name,
            amount: c.amount.toStringAsFixed(2),
            remarks: c.remarks ?? '',
          )));
    } else {
      _ensureDefaultCharges(reset: true);
    }

    // Items
    items.clear();
    for (final item in so.items) {
      final delivered = item.usedQty > 0 ? item.usedQty : item.quantity;
      items.add(SILineRow(
        productId: item.productId,
        productName: item.productName,
        productCode: item.hsnCode,
        unit: item.unit ?? 'Nos',
        orderedQty: item.quantity.toString(),
        qtyDelivered: delivered.toString(),
        price: item.price.toString(),
        discountPercent: item.discountPercent?.toString() ?? '',
        taxPercent: item.taxPercent?.toString() ?? '',
      ));
    }
    if (items.isEmpty && !viewOnly.value) addItem();
    await _hydrateLineItemTaxes();

    if (customerName.value.isEmpty && customerId.value != null) {
      unawaited(_hydrateCustomerDetails(customerId.value));
    }
  }

  Future<void> _hydrateLineItemTaxes() async {
    for (final row in items) {
      final pid = row.productId.value;
      if (pid == null || pid <= 0) continue;
      await applyProductTaxesToRow(row, pid);
    }
  }

  // ── Validate & Save ───────────────────────────────────────────────────────

  bool validateForm() {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    final effectiveCustomerId = customerId.value ?? selectedCustomerId.value;
    if (effectiveCustomerId == null) {
      _showError('Please select a customer');
      return false;
    }
    if (docDate.value.trim().isEmpty) {
      _showError('Please enter document date');
      return false;
    }
    if (billDt.value.trim().isEmpty) {
      _showError('Please enter invoice date');
      return false;
    }
    if (invoiceNumber.value.trim().isEmpty) {
      _showError('Invoice number not loaded yet — please wait a moment and try again');
      return false;
    }
    final validItems = items.where((r) => r.productId.value != null).toList();
    if (validItems.isEmpty) {
      _showError('Please add at least one line item');
      return false;
    }
    for (final r in validItems) {
      final qty = r.deliveredQtyDouble;
      if (qty <= 0) {
        _showError('Qty must be > 0 for ${r.productName.value.isEmpty ? "item" : r.productName.value}');
        return false;
      }
      if (r.orderedQtyDouble > 0 && qty > r.orderedQtyDouble) {
        _showError('Delivered qty cannot exceed ordered qty for ${r.productName.value}');
        return false;
      }
    }
    return true;
  }

  Future<void> cancelInvoice() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel invoice?'),
        content: Text(
          'Cancel invoice ${invoiceNumber.value.trim()}? '
          'The linked sales order will revert to DRAFT and can be re-edited or re-invoiced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (sourceOrderId.value == null) return;

    isSaving.value = true;
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.salesOrders}/${sourceOrderId.value}'),
        headers: AuthController.jsonHeaders,
        body: jsonEncode({'cancel_invoice': true}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccess('Invoice cancelled. The sales order has been reverted to DRAFT.');
        await Future.delayed(const Duration(milliseconds: 800));
        Get.back(result: true);
      } else {
        _showError(data['message']?.toString() ?? 'Failed to cancel invoice (${response.statusCode})');
      }
    } catch (e) {
      _showError('Failed to cancel invoice: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> save() async {
    if (!validateForm()) return;
    isBrowsing.value = false;
    isSaving.value = true;
    try {
      if (sourceOrderId.value != null) {
        await _putExistingOrder(sourceOrderId.value!);
      } else {
        await _createNewOrderAsBilled();
      }
    } catch (e) {
      debugPrint('[SI FORM] Save error: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildItemPayload(SILineRow r, int lineNo) {
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
      'product_id': r.productId.value,
      'line_no': lineNo,
      if (r.productCode.value.trim().isNotEmpty) 'hsn_code': r.productCode.value.trim(),
      if (r.unit.value.trim().isNotEmpty) 'unit': r.unit.value.trim(),
      if (r.selectedPackId.value.trim().isNotEmpty) 'pack_id': r.selectedPackId.value.trim(),
      'quantity': r.orderedQtyDouble > 0 ? r.orderedQtyDouble : r.deliveredQtyDouble,
      'qty_delivered': r.deliveredQtyDouble,
      'price': r.priceDouble,
      if (discount != null && discount > 0) 'discount_percent': discount,
      if (tax != null && tax > 0) 'tax_percent': tax,
    };
  }

  Future<void> _putExistingOrder(int orderId) async {
    final effectiveCustomerId = customerId.value ?? selectedCustomerId.value;
    final validItems = items.where((r) => r.productId.value != null).toList();
    final payload = {
      'financial_year': financialYear.value,
      'customer_id': effectiveCustomerId,
      if (departmentId.value != null && departmentId.value!.trim().isNotEmpty)
        'department_id': departmentId.value,
      if (salesmanId.value != null && salesmanId.value!.trim().isNotEmpty)
        'supplier_id': salesmanId.value,
      'doc_date': docDate.value,
      if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
      'status': _isEditable ? 'billed' : status.value.toLowerCase(),
      if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
      'bill_number': invoiceNumber.value.trim(),
      'bill_dt': billDt.value.trim(),
      if (billDepartment.value.trim().isNotEmpty) 'department': billDepartment.value.trim(),
      if (billNarration.value.trim().isNotEmpty) 'bill_narration': billNarration.value.trim(),
      if (billVehicle.value.trim().isNotEmpty) 'bill_vehicle': billVehicle.value.trim(),
      if (billStatement.value.trim().isNotEmpty) 'bill_statement': billStatement.value.trim(),
      'bill_roff': double.tryParse(billRoff.value) ?? 0,
      if (billDocYear.value.trim().isNotEmpty) 'doc_year': billDocYear.value.trim(),
      'charges': charges.map((c) => {
        'name': c.name.value,
        'amount': double.tryParse(c.amount.value) ?? 0,
        if (c.remarks.value.trim().isNotEmpty) 'remarks': c.remarks.value.trim(),
      }).toList(),
      'items': validItems.asMap().entries.map((e) => _buildItemPayload(e.value, e.key + 1)).toList(),
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.salesOrders}/$orderId'),
      headers: AuthController.jsonHeaders,
      body: jsonEncode(payload),
    );
    debugPrint('[SI FORM] PUT $orderId → ${response.statusCode}: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      _showSuccess('Invoice ${invoiceNumber.value} saved successfully');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.back(result: true);
    } else {
      _showError(data['message']?.toString() ?? 'Failed to save invoice (${response.statusCode})');
    }
  }

  Future<void> _createNewOrderAsBilled() async {
    final effectiveCustomerId = customerId.value ?? selectedCustomerId.value;
    final validItems = items.where((r) => r.productId.value != null).toList();
    final payload = {
      'financial_year': financialYear.value,
      'customer_id': effectiveCustomerId,
      if (departmentId.value != null && departmentId.value!.trim().isNotEmpty)
        'department_id': departmentId.value,
      if (salesmanId.value != null && salesmanId.value!.trim().isNotEmpty)
        'supplier_id': salesmanId.value,
      'doc_date': docDate.value,
      if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
      'status': 'billed',
      if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
      'bill_number': invoiceNumber.value.trim(),
      'bill_dt': billDt.value.trim(),
      if (billDepartment.value.trim().isNotEmpty) 'department': billDepartment.value.trim(),
      if (billNarration.value.trim().isNotEmpty) 'bill_narration': billNarration.value.trim(),
      if (billVehicle.value.trim().isNotEmpty) 'bill_vehicle': billVehicle.value.trim(),
      if (billStatement.value.trim().isNotEmpty) 'bill_statement': billStatement.value.trim(),
      'bill_roff': double.tryParse(billRoff.value) ?? 0,
      if (billDocYear.value.trim().isNotEmpty) 'doc_year': billDocYear.value.trim(),
      'charges': charges.map((c) => {
        'name': c.name.value,
        'amount': double.tryParse(c.amount.value) ?? 0,
        if (c.remarks.value.trim().isNotEmpty) 'remarks': c.remarks.value.trim(),
      }).toList(),
      'items': validItems.asMap().entries.map((e) => _buildItemPayload(e.value, e.key + 1)).toList(),
    };

    final response = await http.post(
      Uri.parse(ApiConfig.salesOrders),
      headers: AuthController.jsonHeaders,
      body: jsonEncode(payload),
    );
    debugPrint('[SI FORM] POST → ${response.statusCode}: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      _showSuccess('Invoice ${invoiceNumber.value} created successfully');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.back(result: true);
    } else {
      _showError(data['message']?.toString() ?? 'Failed to create invoice (${response.statusCode})');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _currentFinancialYear() {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final s = startYear.toString().substring(2);
    final e = (startYear + 1).toString().substring(2);
    return '$s-$e';
  }

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success', msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);
  }
}
