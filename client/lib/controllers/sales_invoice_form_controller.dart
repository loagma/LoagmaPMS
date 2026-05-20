import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_order_model.dart';
import '../services/customer_api_service.dart';

class SILineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final productCode = ''.obs;
  final unit = 'Nos'.obs;
  final orderedQty = '0'.obs;
  final qtyDelivered = '0'.obs;
  final price = '0'.obs;

  SILineRow({
    int? productId,
    String? productName,
    String? productCode,
    String? unit,
    String? orderedQty,
    String? qtyDelivered,
    String? price,
  }) {
    if (productId != null) this.productId.value = productId;
    if (productName != null) this.productName.value = productName;
    if (productCode != null) this.productCode.value = productCode;
    if (unit != null) this.unit.value = unit;
    if (orderedQty != null) this.orderedQty.value = orderedQty;
    if (qtyDelivered != null) this.qtyDelivered.value = qtyDelivered;
    if (price != null) this.price.value = price;
  }

  double get deliveredQtyDouble => double.tryParse(qtyDelivered.value) ?? 0;
  double get orderedQtyDouble => double.tryParse(orderedQty.value) ?? 0;
  double get priceDouble => double.tryParse(price.value) ?? 0;
  double get lineTotal => deliveredQtyDouble * priceDouble;
}

class SalesInvoiceFormController extends GetxController {
  final int? soId;
  final bool viewOnly;

  final isLoading = false.obs;
  final isSaving = false.obs;

  // Step 1: customer selection
  final selectedCustomerId = Rxn<int>();
  final selectedCustomerName = ''.obs;

  // Step 2: source order
  final sourceOrderId = Rxn<int>();
  final sourceOrderNumber = ''.obs;

  // Customer (from loaded order)
  final customerId = Rxn<int>();
  final customerName = ''.obs;

  // Invoice header
  final invoiceNumber = ''.obs;
  final invoicePrefix = 'INV/25-26/'.obs;
  final orderDate = ''.obs;
  final billDt = ''.obs;
  final billDepartment = ''.obs;
  final billNarration = ''.obs;
  final billVehicle = ''.obs;
  final billStatement = ''.obs;
  final billRoff = '0'.obs;
  final billDocYear = ''.obs;

  final items = <SILineRow>[].obs;

  SalesInvoiceFormController({this.soId, this.viewOnly = false});

  @override
  void onInit() {
    super.onInit();
    // Default invoice date to today
    billDt.value = _today();
    // Default doc year to current financial year
    billDocYear.value = _currentFinancialYear();

    if (soId != null) {
      _loadOrder(soId!);
    } else {
      unawaited(_fetchNextInvoiceNumber());
    }
  }

  double get grandTotal {
    double total = 0;
    for (final r in items) {
      total += r.lineTotal;
    }
    final roff = double.tryParse(billRoff.value) ?? 0;
    return total + roff;
  }

  // ── Customer search (step 1) ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.customers).replace(queryParameters: {
        'search': query,
        'limit': '30',
      });
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .where((j) => (int.tryParse(j['id']?.toString() ?? '') ?? 0) > 0)
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Search customers error: $e');
      return [];
    }
  }

  void selectCustomer(int id, String name) {
    selectedCustomerId.value = id;
    selectedCustomerName.value = name;
    // Clear previously selected order when customer changes
    sourceOrderId.value = null;
    sourceOrderNumber.value = '';
    items.clear();
  }

  // ── Order search filtered by customer (step 2) ──────────────────────────────

  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      final params = <String, String>{
        'limit': '50',
        'exclude_closed': 'true',
      };
      if (query.isNotEmpty) params['search'] = query;
      if (selectedCustomerId.value != null) {
        params['customer_id'] = selectedCustomerId.value.toString();
      }

      final uri = Uri.parse(ApiConfig.salesOrders).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          // Only show orders that can still be invoiced (not already billed)
          .where((o) => (o['status']?.toString().toLowerCase() ?? '') != 'billed')
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Search orders error: $e');
      return [];
    }
  }

  // ── Product search (for adding extra items) ─────────────────────────────────

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.products).replace(queryParameters: {
        'search': query,
        'limit': '30',
      });
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      return (data['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('[SI FORM] Search products error: $e');
      return [];
    }
  }

  // ── Item management ──────────────────────────────────────────────────────────

  void addItem() {
    items.add(SILineRow(qtyDelivered: '1'));
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
  }

  // ── Load order ──────────────────────────────────────────────────────────────

  Future<void> loadOrder(int orderId) async {
    await _loadOrder(orderId);
  }

  Future<void> _loadOrder(int orderId) async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.salesOrders}/$orderId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;

      final so = SalesOrder.fromJson(data['data'] as Map<String, dynamic>);
      _applyOrder(so);

      if (so.billNumber != null && so.billNumber!.isNotEmpty) {
        invoiceNumber.value = so.billNumber!;
      } else if (invoiceNumber.value.isEmpty) {
        await _fetchNextInvoiceNumber();
      }
    } catch (e) {
      debugPrint('[SI FORM] Load order error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyOrder(SalesOrder so) {
    sourceOrderId.value = so.id;
    sourceOrderNumber.value = so.soNumber;
    customerId.value = so.customerId;
    customerName.value = so.customerName ?? '';
    orderDate.value = so.docDate;

    // Only override billDt if the SO already has an invoice date (viewing existing invoice)
    if (so.billDt != null && so.billDt!.isNotEmpty) {
      billDt.value = so.billDt!;
    }
    // else keep the today default set in onInit

    billDepartment.value = so.department ?? '';
    billNarration.value = so.billNarration ?? '';
    billVehicle.value = so.billVehicle ?? '';
    billStatement.value = so.billStatement ?? '';
    billRoff.value = so.billRoff?.toStringAsFixed(2) ?? '0';

    // Only override docYear if the SO already has one
    if (so.docYear != null && so.docYear!.isNotEmpty) {
      billDocYear.value = so.docYear!;
    }

    // Also sync customer picker to the order's customer
    if (selectedCustomerId.value == null) {
      selectedCustomerId.value = so.customerId;
      selectedCustomerName.value = so.customerName ?? '';
    }

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
      ));
    }

    if (customerName.value.isEmpty && customerId.value != null) {
      unawaited(_hydrateCustomer(customerId.value!));
    }
  }

  Future<void> _hydrateCustomer(int id) async {
    final c = await CustomerApiService.fetchCustomerById(id);
    if (c != null && customerId.value == id) {
      customerName.value = c.name;
    }
  }

  Future<void> _fetchNextInvoiceNumber() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.salesInvoiceSeries),
            headers: {'Accept': 'application/json'},
          )
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

  // ── Validation & save ───────────────────────────────────────────────────────

  bool validate() {
    if (selectedCustomerId.value == null) {
      _showError('Please select a customer');
      return false;
    }
    if (billDt.value.trim().isEmpty) {
      _showError('Invoice date is required');
      return false;
    }
    if (items.isEmpty) {
      _showError('No items to invoice');
      return false;
    }
    for (final r in items) {
      if (r.productId.value == null) {
        _showError('Please select a product for all items');
        return false;
      }
      final qty = r.deliveredQtyDouble;
      if (qty <= 0) {
        _showError('Qty delivered must be greater than 0 for ${r.productName.value.isEmpty ? 'item' : r.productName.value}');
        return false;
      }
      // Only enforce ordered qty limit if item came from a linked SO (orderedQty > 0)
      if (r.orderedQtyDouble > 0 && qty > r.orderedQtyDouble) {
        _showError('Delivered qty cannot exceed ordered qty for ${r.productName.value}');
        return false;
      }
    }
    return true;
  }

  Future<void> save() async {
    if (!validate()) return;
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

  Future<void> _putExistingOrder(int orderId) async {
    final payload = {
      'status': 'billed',
      'bill_number': invoiceNumber.value.trim(),
      'bill_dt': billDt.value.trim(),
      if (billDepartment.value.trim().isNotEmpty) 'department': billDepartment.value.trim(),
      if (billNarration.value.trim().isNotEmpty) 'bill_narration': billNarration.value.trim(),
      if (billVehicle.value.trim().isNotEmpty) 'bill_vehicle': billVehicle.value.trim(),
      if (billStatement.value.trim().isNotEmpty) 'bill_statement': billStatement.value.trim(),
      'bill_roff': double.tryParse(billRoff.value) ?? 0,
      if (billDocYear.value.trim().isNotEmpty) 'doc_year': billDocYear.value.trim(),
      'items': items.map((r) => {
        'product_id': r.productId.value,
        'quantity': r.orderedQtyDouble > 0 ? r.orderedQtyDouble : r.deliveredQtyDouble,
        'qty_delivered': r.deliveredQtyDouble,
        'price': r.priceDouble,
        if (r.unit.value.isNotEmpty) 'unit': r.unit.value,
      }).toList(),
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.salesOrders}/$orderId'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        'Invoice ${invoiceNumber.value} saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back(result: true);
    } else {
      _showError(data['message']?.toString() ?? 'Failed to save invoice');
    }
  }

  Future<void> _createNewOrderAsBilled() async {
    final payload = {
      'customer_id': selectedCustomerId.value,
      'status': 'billed',
      'bill_number': invoiceNumber.value.trim(),
      'bill_dt': billDt.value.trim(),
      'doc_date': billDt.value.trim(),
      if (billDepartment.value.trim().isNotEmpty) 'department': billDepartment.value.trim(),
      if (billNarration.value.trim().isNotEmpty) 'bill_narration': billNarration.value.trim(),
      if (billVehicle.value.trim().isNotEmpty) 'bill_vehicle': billVehicle.value.trim(),
      if (billStatement.value.trim().isNotEmpty) 'bill_statement': billStatement.value.trim(),
      'bill_roff': double.tryParse(billRoff.value) ?? 0,
      if (billDocYear.value.trim().isNotEmpty) 'doc_year': billDocYear.value.trim(),
      'items': items.map((r) => {
        'product_id': r.productId.value,
        'quantity': r.orderedQtyDouble > 0 ? r.orderedQtyDouble : r.deliveredQtyDouble,
        'qty_delivered': r.deliveredQtyDouble,
        'price': r.priceDouble,
        if (r.unit.value.isNotEmpty) 'unit': r.unit.value,
      }).toList(),
    };

    final response = await http.post(
      Uri.parse(ApiConfig.salesOrders),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      Get.snackbar(
        'Success',
        'Invoice ${invoiceNumber.value} created',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back(result: true);
    } else {
      _showError(data['message']?.toString() ?? 'Failed to create invoice');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _currentFinancialYear() {
    final now = DateTime.now();
    // Indian FY: April 1 to March 31
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final s = startYear.toString().substring(2);
    final e = (startYear + 1).toString().substring(2);
    return '$s-$e';
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}
