import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/party_result.dart';
import '../models/sales_return_model.dart';
import '../theme/app_colors.dart';
import '../services/customer_api_service.dart';

class SalesReturnFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? returnId;
  final int? sourceSiId;
  final bool startInViewOnly;

  final customers = <Map<String, dynamic>>[].obs;
  final salesInvoices = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;

  // Header fields
  final docNoPrefix = '25-26/'.obs;
  final docNoNumber = ''.obs;
  final sourceSiIdSelected = Rxn<int>();
  final sourceSiNumber = ''.obs;
  final customerId = Rxn<int>();
  final customerName = ''.obs;
  final customerPhone = ''.obs;
  final customerShopName = ''.obs;
  final docDate = ''.obs;
  final reason = ''.obs;
  final status = 'DRAFT'.obs;

  final items = <SRItemRow>[].obs;
  final charges = <SRChargeRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isSearchingInvoices = false.obs;

  SalesReturnFormController({
    this.returnId,
    this.sourceSiId,
    this.startInViewOnly = false,
  });

  int? _safeInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  double? _safeDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  Map<String, dynamic> _normalizeInvoicePayload(Map<String, dynamic> raw) {
    if (raw['invoice'] is Map<String, dynamic>) {
      final invoice = Map<String, dynamic>.from(raw['invoice'] as Map<String, dynamic>);
      final items = (raw['items'] is List) ? (raw['items'] as List) : const [];
      invoice['items'] = items;
      return invoice;
    }
    return raw;
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    docDate.value = _formatDate(DateTime.now());
    _loadCustomers();
    _loadUnitTypes();
    if (sourceSiId != null) {
      sourceSiIdSelected.value = sourceSiId;
    }
    if (returnId != null) {
      _loadSalesReturn();
    } else {
      if (sourceSiId != null) {
        _loadSalesInvoiceItems(sourceSiId!);
      }
    }
  }

  bool get isEditMode => returnId != null;
  bool get isReadOnly => viewOnly.value;
  bool get canEditFromView => isReadOnly && status.value == 'DRAFT';

  void enterEditMode() { viewOnly.value = false; }

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
      debugPrint('[SR FORM] Load customers error: $e');
    }
  }

  Future<List<PartyResult>> searchCustomers(String query) async {
    try {
      return await CustomerApiService.searchPartyResults(query: query, limit: 50);
    } catch (_) {
      return [];
    }
  }

  String _customerNameById(int? cId) {
    if (cId == null) return '';
    for (final customer in customers) {
      final id = _safeInt(customer['id']);
      if (id == cId) return customer['name']?.toString() ?? '';
    }
    return '';
  }

  Future<void> setCustomerWithName(
    int id,
    String name, {
    String? phone,
    String? shopName,
  }) async {
    if (customerId.value == id) return;
    customerId.value = id;
    customerName.value = name;
    customerPhone.value = phone ?? '';
    customerShopName.value = shopName ?? '';
    sourceSiIdSelected.value = null;
    sourceSiNumber.value = '';
    items.clear();
    charges.clear();
    docNoNumber.value = '';
    await _loadNextDocNoNumberForCustomer(id);
    await _hydrateCustomerDetails(id);
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

  Future<void> setCustomer(int? cId) async {
    if (customerId.value == cId) return;
    customerId.value = cId;
    customerName.value = _customerNameById(cId);
    customerPhone.value = '';
    customerShopName.value = '';
    sourceSiIdSelected.value = null;
    sourceSiNumber.value = '';
    items.clear();
    charges.clear();
    docNoNumber.value = '';
    if (cId != null) {
      await _loadNextDocNoNumberForCustomer(cId);
      await _hydrateCustomerDetails(cId);
    }
  }

  Future<void> _hydrateCustomerDetails(int id) async {
    final customer = await CustomerApiService.fetchCustomerById(id);
    if (customer == null || customerId.value != id) return;
    customerName.value = customer.name;
    customerPhone.value = customer.contactNumber ?? '';
    customerShopName.value = customer.shopName ?? '';
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.unitTypes), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          unitTypes.value = items.cast<String>();
        }
      }
    } catch (e) {
      debugPrint('[SR FORM] Load unit types error: $e');
    }
  }

  Future<void> _loadNextDocNoNumberForCustomer(int cId) async {
    try {
      final uri = Uri.parse(ApiConfig.salesReturnSeries)
          .replace(queryParameters: {'customer_id': cId.toString()});
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final series = data['data'] as Map<String, dynamic>;
          docNoPrefix.value = series['prefix']?.toString() ?? docNoPrefix.value;
          docNoNumber.value = series['number']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('[SR FORM] Load doc number error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchSalesInvoices(String query, {int? customerIdFilter}) async {
    try {
      isSearchingInvoices.value = true;
      final uri = Uri.parse(ApiConfig.salesInvoices).replace(
        queryParameters: {
          'limit': '20',
          if (query.trim().isNotEmpty) 'search': query.trim(),
          if (customerIdFilter != null) 'customer_id': customerIdFilter.toString(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SR FORM] Search invoices error: $e');
      return [];
    } finally {
      isSearchingInvoices.value = false;
    }
  }

  Future<void> loadSalesInvoiceItems(int siId) async {
    await _loadSalesInvoiceItems(siId);
  }

  Future<void> _loadSalesInvoiceItems(int siId) async {
    try {
      isLoading.value = true;
      sourceSiIdSelected.value = siId;

      final response = await http
          .get(Uri.parse('${ApiConfig.salesInvoices}/$siId'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final siData = _normalizeInvoicePayload(data['data'] as Map<String, dynamic>);

          sourceSiNumber.value =
              siData['doc_no']?.toString() ?? siData['doc_no_number']?.toString() ?? '';
          customerId.value = _safeInt(siData['customer_id']);
          customerName.value = siData['customer_name']?.toString() ?? '';
          customerPhone.value = '';
          customerShopName.value = '';
          if (customerId.value != null) {
            await _loadNextDocNoNumberForCustomer(customerId.value!);
            await _hydrateCustomerDetails(customerId.value!);
          }

          items.clear();
          final List siItems = siData['items'] ?? [];
          for (final item in siItems.cast<Map<String, dynamic>>()) {
            final originalQty = _safeDouble(item['quantity'] ?? item['original_quantity']) ?? 0;
            final availableFromApi = _safeDouble(item['available_quantity'] ?? item['remaining_returnable_qty'] ?? item['remaining_qty']);
            final effectiveAvailableQty = (availableFromApi != null && availableFromApi > 0) ? availableFromApi : originalQty;

            final row = SRItemRow()
              ..sourceSiItemId.value = _safeInt(item['id'])
              ..sourceSiId.value = siId
              ..productId.value = _safeInt(item['product_id'])
              ..productName.value = item['product_name']?.toString() ?? ''
              ..productCode.value = item['product_code']?.toString() ?? ''
              ..alias.value = item['alias']?.toString() ?? ''
              ..unitType.value = item['unit']?.toString() ?? 'Nos'
              ..originalQty.value = originalQty.toString()
              ..availableQty.value = effectiveAvailableQty.toString()
              ..returnedQty.value = ''
              ..unitPrice.value = (_safeDouble(item['unit_price'])?.toString()) ?? '0';

            items.add(row);
          }

          if (items.isEmpty) addItemRow();
        }
      }
    } catch (e) {
      debugPrint('[SR FORM] Load SI items error: $e');
      _showError('Failed to load invoice items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSalesReturn() async {
    try {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse('${ApiConfig.salesReturns}/$returnId'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final returnData = data['data'] as Map<String, dynamic>;
          final sr = SalesReturn.fromJson(returnData);

          docNoPrefix.value = sr.header.docNoPrefix;
          docNoNumber.value = sr.header.docNoNumber;
          sourceSiNumber.value = sr.header.sourceSiNumber ?? '';
          sourceSiIdSelected.value = sr.header.sourceSalesInvoiceId;
          customerId.value = sr.header.customerId;
          customerName.value = sr.header.customerName ?? '';
          customerPhone.value = '';
          customerShopName.value = '';
          docDate.value = sr.header.docDate;
          reason.value = sr.header.reason ?? '';
          status.value = sr.header.status ?? 'DRAFT';

          items.clear();
          for (final item in sr.items) {
            final row = SRItemRow()
              ..sourceSiItemId.value = item.sourceSalesInvoiceItemId
              ..productId.value = item.productId
              ..productName.value = item.productName ?? ''
              ..productCode.value = item.productCode ?? ''
              ..alias.value = item.alias ?? ''
              ..unitType.value = item.unit ?? 'Nos'
              ..originalQty.value = item.originalQty.toString()
              ..availableQty.value = (item.availableQty ?? item.originalQty).toString()
              ..returnedQty.value = item.returnedQty.toString()
              ..unitPrice.value = item.unitPrice.toString()
              ..returnReason.value = item.returnReason ?? ''
              ..selected.value = item.returnedQty > 0;
            items.add(row);
          }

          charges.clear();
          for (final charge in sr.charges) {
            final row = SRChargeRow()
              ..name.value = charge.name
              ..amount.value = charge.amount.toString()
              ..remarks.value = charge.remarks ?? '';
            charges.add(row);
          }
        }
      }
    } catch (e) {
      debugPrint('[SR FORM] Load SR error: $e');
      _showError('Failed to load return: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String get totalReturnValue {
    double total = 0;
    for (final row in items) {
      final qty = double.tryParse(row.returnedQty.value) ?? 0;
      final price = double.tryParse(row.unitPrice.value) ?? 0;
      total += qty * price;
    }
    for (final charge in charges) {
      final amt = double.tryParse(charge.amount.value) ?? 0;
      final name = charge.name.value.toLowerCase();
      total += name.contains('discount') ? -amt : amt;
    }
    return total.toStringAsFixed(2);
  }

  void addItemRow() { items.add(SRItemRow()); }

  void setItemSelected(int index, bool selected) {
    if (index < 0 || index >= items.length) return;
    final row = items[index];
    row.selected.value = selected;
    if (!selected) {
      row.returnedQty.value = '';
      row.returnReason.value = '';
    }
  }

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  void addChargeRow() { charges.add(SRChargeRow()); }

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) charges.removeAt(index);
  }

  Future<void> saveSalesReturn({bool post = false}) async {
    if (!formKey.currentState!.validate()) {
      _showError('Please fill all required fields');
      return;
    }

    if (items.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    if (sourceSiIdSelected.value == null) {
      _showError('Please select a source sales invoice');
      return;
    }

    try {
      isSaving.value = true;

      for (var i = 0; i < items.length; i++) {
        final row = items[i];
        if (!row.selected.value) { row.returnedQty.value = ''; continue; }
        final rQty = double.tryParse(row.returnedQty.value) ?? 0;
        if (rQty <= 0) continue;
        final available = double.tryParse(row.availableQty.value) ?? (double.tryParse(row.originalQty.value) ?? 0);
        if (rQty > available) {
          _showError('Row ${i + 1}: return quantity exceeds available quantity ($available)');
          return;
        }
      }

      final itemsList = items
          .where((row) => row.selected.value && (double.tryParse(row.returnedQty.value) ?? 0) > 0)
          .map((row) => {
                'source_sales_invoice_item_id': row.sourceSiItemId.value,
                'product_id': row.productId.value,
                'product_name': row.productName.value,
                'original_quantity': double.tryParse(row.originalQty.value) ?? 0,
                'returned_quantity': double.tryParse(row.returnedQty.value) ?? 0,
                'unit_price': double.tryParse(row.unitPrice.value) ?? 0,
                'return_reason': row.returnReason.value,
              })
          .toList();

      if (itemsList.isEmpty) {
        _showError('Please enter return quantity for at least one item');
        return;
      }

      final chargesList = charges
          .where((row) => row.name.value.isNotEmpty && (double.tryParse(row.amount.value) ?? 0) > 0)
          .map((row) => {
                'name': row.name.value,
                'amount': double.tryParse(row.amount.value) ?? 0,
                'remarks': row.remarks.value,
              })
          .toList();

      final payload = {
        'source_sales_invoice_id': sourceSiIdSelected.value,
        'customer_id': customerId.value,
        'doc_date': docDate.value,
        'reason': reason.value.isNotEmpty ? reason.value : null,
        'status': post ? 'POSTED' : 'DRAFT',
        'items': itemsList,
        if (chargesList.isNotEmpty) 'charges': chargesList,
      };

      final uri = Uri.parse(
        returnId == null ? ApiConfig.createSalesReturn : '${ApiConfig.salesReturns}/$returnId',
      );
      final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};

      final response = returnId == null
          ? await http.post(uri, headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 30))
          : await http.put(uri, headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          _showSuccess(returnId == null ? 'Return saved successfully' : 'Return updated successfully');
          await Future.delayed(const Duration(milliseconds: 500));
          Get.back(result: true);
          return;
        }
      }

      _showError(data['message']?.toString() ?? 'Failed to save return');
    } catch (e) {
      debugPrint('[SR FORM] Save error: $e');
      _showError('Error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteReturn() async {
    if (returnId == null) return;
    try {
      isSaving.value = true;
      final response = await http
          .delete(Uri.parse('${ApiConfig.salesReturns}/$returnId'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccess('Return deleted successfully');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back(result: true);
        return;
      }
      _showError(data['message']?.toString() ?? 'Failed to delete return');
    } catch (e) {
      debugPrint('[SR FORM] Delete error: $e');
      _showError('Error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final row in items) { row.dispose(); }
    super.onClose();
  }
}

class SRItemRow {
  final sourceSiId = Rxn<int>();
  final sourceSiItemId = Rxn<int>();
  final productId = Rxn<int>();
  final productName = ''.obs;
  final productCode = ''.obs;
  final alias = ''.obs;
  final unitType = 'Nos'.obs;
  final originalQty = '0'.obs;
  final availableQty = '0'.obs;
  final returnedQty = ''.obs;
  final unitPrice = '0'.obs;
  final returnReason = ''.obs;
  final remarks = ''.obs;
  final selected = false.obs;

  void dispose() {}
}

class SRChargeRow {
  final name = ''.obs;
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
