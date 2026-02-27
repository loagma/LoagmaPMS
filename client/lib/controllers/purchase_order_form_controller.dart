import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../models/purchase_order_model.dart';
import '../models/supplier_model.dart';
import '../theme/app_colors.dart';

class PurchaseOrderItemRow {
  final product = Rxn<Product>();
  final quantity = ''.obs;
  final unit = ''.obs;
  final price = ''.obs;
  final discountPercent = ''.obs;
  final taxPercent = ''.obs;
  final lineTotal = 0.0.obs;
}

class PurchaseOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? purchaseOrderId;

  final suppliers = <Supplier>[].obs;
  final products = <Product>[].obs;
  final items = <PurchaseOrderItemRow>[].obs;

  final selectedSupplier = Rxn<Supplier>();
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  PurchaseOrderFormController({this.purchaseOrderId});

  @override
  void onInit() {
    super.onInit();
    _initHeaderDefaults();
    _loadInitialData();

    if (purchaseOrderId != null) {
      _loadPurchaseOrder();
    } else {
      addItemRow();
    }
  }

  void _initHeaderDefaults() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    docDate.value = '$y-$m-$d';
  }

  Future<void> _loadInitialData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _loadProducts(),
        _loadSuppliers(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProducts({String? search}) async {
    try {
      var url = ApiConfig.products;
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}&limit=100';
      } else {
        url += '?limit=50';
      }

      debugPrint('[PO FORM] Fetching products: $url');

      final response = await http
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'API error');
      }

      final List raw = data['data'] ?? [];
      final allProducts = <Product>[];

      for (final item in raw) {
        try {
          allProducts.add(Product.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[PO FORM] Skipping invalid product: $e');
        }
      }

      products.assignAll(allProducts);
      debugPrint('[PO FORM] Loaded ${products.length} products');
    } catch (e) {
      debugPrint('[PO FORM] Failed to load products: $e');
      _showError('Failed to load products');
    }
  }

  Future<void> _loadSuppliers({String? search}) async {
    try {
      var url = ApiConfig.suppliers;
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}&limit=50';
      } else {
        url += '?limit=50';
      }

      debugPrint('[PO FORM] Fetching suppliers: $url');

      final response = await http
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic>) {
        data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
      } else {
        data = <dynamic>[];
      }

      final results = <Supplier>[];
      for (final item in data) {
        try {
          results.add(Supplier.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[PO FORM] Skipping invalid supplier: $e');
        }
      }

      suppliers.assignAll(results);
      debugPrint('[PO FORM] Loaded ${suppliers.length} suppliers');
    } catch (e) {
      debugPrint('[PO FORM] Failed to load suppliers: $e');
      _showError('Failed to load suppliers');
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length >= 2) {
      await _loadProducts(search: query);
    } else if (query.isEmpty) {
      await _loadProducts();
    }
  }

  Future<void> searchSuppliers(String query) async {
    if (query.length >= 2) {
      await _loadSuppliers(search: query);
    }
  }

  Future<void> _loadPurchaseOrder() async {
    if (purchaseOrderId == null) return;
    try {
      isLoading.value = true;

      final uri =
          Uri.parse('${ApiConfig.purchaseOrders}/$purchaseOrderId');
      debugPrint('[PO FORM] GET $uri');

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        _showError('Failed to load purchase order');
        return;
      }

      final decoded = jsonDecode(response.body);
      Map<String, dynamic> data;

      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        final inner = decoded['data'];
        if (inner is Map<String, dynamic> &&
            inner['purchase_order'] != null) {
          data = {
            ...inner['purchase_order'] as Map<String, dynamic>,
            'items': inner['items'] ?? inner['purchase_order_items'] ?? [],
          };
        } else if (inner is Map<String, dynamic>) {
          data = inner;
        } else {
          data = decoded;
        }
      } else if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        _showError('Unexpected response from server');
        return;
      }

      final po = PurchaseOrder.fromJson(data);

      docDate.value = po.docDate;
      expectedDate.value = po.expectedDate ?? '';
      status.value = po.status;
      narration.value = po.narration ?? '';

      // Try to match supplier from list if already loaded
      if (po.supplierId != 0) {
        final existing = suppliers
            .firstWhereOrNull((s) => s.id == po.supplierId);
        if (existing != null) {
          selectedSupplier.value = existing;
        } else if (po.supplierName != null) {
          selectedSupplier.value = Supplier(
            id: po.supplierId,
            supplierCode: 'SUP-${po.supplierId}',
            supplierName: po.supplierName!,
          );
        }
      }

      items.clear();
      for (final item in po.items) {
        final row = PurchaseOrderItemRow();
        final productMatch =
            products.firstWhereOrNull((p) => p.id == item.productId);
        row.product.value = productMatch ??
            Product(
              id: item.productId,
              name: item.productName ?? 'Product ${item.productId}',
              code: null,
              productType: 'SINGLE',
              defaultUnit: item.unit,
              stock: null,
            );
        row.quantity.value = item.quantity.toString();
        row.unit.value = item.unit ?? (row.product.value?.defaultUnit ?? '');
        row.price.value = item.price.toStringAsFixed(2);
        row.discountPercent.value =
            (item.discountPercent ?? 0).toStringAsFixed(2);
        row.taxPercent.value =
            (item.taxPercent ?? 0).toStringAsFixed(2);
        row.lineTotal.value = item.lineTotal ?? 0;
        items.add(row);
      }

      if (items.isEmpty) {
        addItemRow();
      }

      debugPrint('[PO FORM] Loaded purchase order for editing');
    } catch (e) {
      debugPrint('[PO FORM] Failed to load purchase order: $e');
      _showError('Failed to load purchase order');
    } finally {
      isLoading.value = false;
    }
  }

  void setSupplier(Supplier? supplier) {
    selectedSupplier.value = supplier;
  }

  void setDocDate(String value) {
    docDate.value = value;
  }

  void setExpectedDate(String value) {
    expectedDate.value = value;
  }

  void setStatus(String value) {
    status.value = value;
  }

  void setNarration(String value) {
    narration.value = value;
  }

  void addItemRow() {
    items.add(PurchaseOrderItemRow());
  }

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void updateLineTotal(PurchaseOrderItemRow row) {
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final price = double.tryParse(row.price.value) ?? 0;
    final discount =
        double.tryParse(row.discountPercent.value) ?? 0;
    final tax = double.tryParse(row.taxPercent.value) ?? 0;

    var base = qty * price;
    if (discount > 0) {
      base -= base * (discount / 100);
    }
    if (tax > 0) {
      base += base * (tax / 100);
    }
    row.lineTotal.value = base;
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (selectedSupplier.value == null) {
      _showError('Please select a supplier');
      return false;
    }

    if (docDate.value.trim().isEmpty) {
      _showError('Please enter document date');
      return false;
    }

    if (items.isEmpty) {
      _showError('Please add at least one item');
      return false;
    }

    for (final row in items) {
      if (row.product.value == null) {
        _showError('Each item must have a product selected');
        return false;
      }
      final qty = double.tryParse(row.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Each item must have quantity > 0');
        return false;
      }
      final price = double.tryParse(row.price.value);
      if (price == null || price < 0) {
        _showError('Each item must have a valid price');
        return false;
      }
    }

    return true;
  }

  Future<void> saveAsDraft() async {
    await _save('DRAFT');
  }

  Future<void> sendPurchaseOrder() async {
    await _save('SENT');
  }

  Future<void> _save(String saveStatus) async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      final payload = {
        'supplier_id': selectedSupplier.value!.id,
        'doc_date': docDate.value.trim(),
        if (expectedDate.value.trim().isNotEmpty)
          'expected_date': expectedDate.value.trim(),
        'status': saveStatus,
        'narration': narration.value.trim(),
        'items': items.map((row) {
          final qty = double.tryParse(row.quantity.value) ?? 0;
          final price = double.tryParse(row.price.value) ?? 0;
          final discount =
              double.tryParse(row.discountPercent.value) ?? 0;
          final tax = double.tryParse(row.taxPercent.value) ?? 0;

          return {
            'product_id': row.product.value!.id,
            'quantity': qty,
            'price': price,
            'discount_percent': discount,
            'tax_percent': tax,
            'unit': row.unit.value.isNotEmpty
                ? row.unit.value
                : row.product.value!.defaultUnit,
          };
        }).toList(),
      };

      final isEdit = purchaseOrderId != null;
      final url = isEdit
          ? '${ApiConfig.purchaseOrders}/$purchaseOrderId'
          : ApiConfig.purchaseOrders;

      debugPrint(
        '[PO FORM] ${isEdit ? 'Updating' : 'Creating'}: ${jsonEncode(payload)}',
      );

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          (data['success'] == true || data['status'] == 'success')) {
        final message = isEdit
            ? 'Purchase order updated successfully'
            : (saveStatus == 'DRAFT'
                ? 'Purchase order saved as draft'
                : 'Purchase order sent successfully');
        _showSuccess(message);
        debugPrint('[PO FORM] Success: ${data['data']}');

        await Future.delayed(const Duration(seconds: 1));
        Get.back(result: true);
      } else {
        throw Exception(data['message'] ?? 'Failed to save purchase order');
      }
    } catch (e) {
      debugPrint('[PO FORM] Save failed: $e');
      _showError('Failed to save purchase order: $e');
    } finally {
      isSaving.value = false;
    }
  }

  bool get isEditMode => purchaseOrderId != null;

  bool get isReadOnly => status.value != 'DRAFT';
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

