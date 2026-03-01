import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_order_model.dart';
import '../theme/app_colors.dart';

class PurchaseOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? poId;

  final suppliers = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;

  final financialYear = '25-26'.obs;
  final supplierId = Rxn<int>();
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;

  final items = <POLineRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  PurchaseOrderFormController({this.poId});

  @override
  void onInit() {
    super.onInit();
    _loadSuppliers();
    if (poId != null) {
      _loadPurchaseOrder();
    } else {
      _setDefaultDocDate();
      items.add(POLineRow());
    }
  }

  /// Search products via API (used by product picker; no full list).
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
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
                'name': (e)['name']?.toString() ?? (e)['product_name']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('[PO FORM] Search products error: $e');
      return [];
    }
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
    items.add(POLineRow());
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  bool get isEditMode => poId != null;
  bool get isReadOnly => status.value != 'DRAFT';

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
        'items': validItems.asMap().entries.map((e) {
          final r = e.value;
          final productId = r.productId.value!;
          final qty = double.tryParse(r.quantity.value) ?? 0;
          final price = double.tryParse(r.price.value) ?? 0;
          final discount = double.tryParse(r.discountPercent.value);
          final tax = double.tryParse(r.taxPercent.value);
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
        _showSuccess(isCreate ? 'Purchase order created' : 'Purchase order updated');
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }
}

class POLineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final quantity = '1'.obs;
  final price = '0'.obs;
  final discountPercent = ''.obs;
  final taxPercent = ''.obs;
  final unit = ''.obs;
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

  /// Price including tax (computed).
  double get priceInclTax {
    final p = priceExclTax;
    final t = double.tryParse(taxPercent.value) ?? 0;
    return p * (1 + t / 100);
  }

  /// Line total excluding tax.
  double get lineTotalExclTax {
    final qty = double.tryParse(quantity.value) ?? 0;
    final p = priceExclTax;
    final d = double.tryParse(discountPercent.value) ?? 0;
    return qty * p * (1 - d / 100);
  }

  /// Line total including tax.
  double get lineTotal {
    final qty = double.tryParse(quantity.value) ?? 0;
    final p = priceExclTax;
    final d = double.tryParse(discountPercent.value) ?? 0;
    final t = double.tryParse(taxPercent.value) ?? 0;
    return qty * p * (1 - d / 100) * (1 + t / 100);
  }
}
