import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

/// One product row when assigning multiple products to a supplier.
class SupplierProductRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
}

class SupplierProductFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? supplierProductId;
  /// Pre-select this supplier when opening the assign form (e.g. from supplier's product list).
  final int? presetSupplierId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final suppliers = <SupplierItem>[].obs;
  /// Only used in edit mode for single-product dropdown; assign mode uses search.
  final products = <Product>[].obs;

  final selectedSupplierId = Rx<int?>(null);
  final selectedProductId = Rx<int?>(null);
  final supplierSku = ''.obs;
  final supplierProductName = ''.obs;
  final description = ''.obs;
  final packSize = ''.obs;
  final packUnit = ''.obs;
  final minOrderQty = ''.obs;
  final price = ''.obs;
  final currency = 'INR'.obs;
  final taxPercent = ''.obs;
  final discountPercent = ''.obs;
  final leadTimeDays = ''.obs;
  final notes = ''.obs;
  final isPreferred = false.obs;
  final isActive = true.obs;

  /// In assign mode: multiple product rows. In edit mode: single assignment.
  final productRows = <SupplierProductRow>[].obs;

  SupplierProductFormController({
    this.supplierProductId,
    this.presetSupplierId,
  });

  bool get isEditMode => supplierProductId != null;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadSuppliers();
    if (presetSupplierId != null) {
      selectedSupplierId.value = presetSupplierId;
    }
    if (isEditMode) {
      await _loadProducts();
      await _loadSupplierProduct();
    } else {
      productRows.add(SupplierProductRow());
    }
  }

  void addProductRow() => productRows.add(SupplierProductRow());
  void removeProductRow(int index) {
    if (index >= 0 && index < productRows.length) productRows.removeAt(index);
  }

  /// Search products via API (no full list). Used by product picker.
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
      debugPrint('[SUPPLIER_PRODUCT_FORM] Search products error: $e');
      return [];
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.suppliers}?limit=200&status=ACTIVE'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          suppliers.value = items
              .map((e) => SupplierItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Suppliers error: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?limit=200'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          products.value = items
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Products error: $e');
    }
  }

  Future<void> _loadSupplierProduct() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/supplier-products/$supplierProductId',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final sp = data['data'] as Map<String, dynamic>;
          _applySupplierProduct(sp);
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Load error: $e');
      _showError('Failed to load supplier product');
    } finally {
      isLoading.value = false;
    }
  }

  void _applySupplierProduct(Map<String, dynamic> sp) {
    selectedSupplierId.value = sp['supplier_id'] as int?;
    selectedProductId.value = sp['product_id'] as int?;
    final product = sp['product'] as Map<String, dynamic>?;
    supplierProductName.value = product?['name']?.toString() ?? '';
    supplierSku.value = sp['supplier_sku'] as String? ?? '';
    supplierProductName.value = sp['supplier_product_name'] as String? ?? '';
    description.value = sp['description'] as String? ?? '';
    packSize.value = sp['pack_size']?.toString() ?? '';
    packUnit.value = sp['pack_unit'] as String? ?? '';
    minOrderQty.value = sp['min_order_qty']?.toString() ?? '';
    price.value = sp['price']?.toString() ?? '';
    currency.value = sp['currency'] as String? ?? 'INR';
    taxPercent.value = sp['tax_percent']?.toString() ?? '';
    discountPercent.value = sp['discount_percent']?.toString() ?? '';
    leadTimeDays.value = sp['lead_time_days']?.toString() ?? '';
    notes.value = sp['notes'] as String? ?? '';
    isPreferred.value = sp['is_preferred'] == 1 || sp['is_preferred'] == true;
    isActive.value = sp['is_active'] == 1 || sp['is_active'] == true;
  }

  Future<void> saveSupplierProduct() async {
    if (isEditMode) {
      if (!formKey.currentState!.validate()) return;
      await _saveSingle();
      return;
    }
    // Assign mode: one or multiple products
    final supplierId = selectedSupplierId.value;
    if (supplierId == null) {
      _showError('Please select a supplier');
      return;
    }
    final productIds = productRows
        .map((r) => r.productId.value)
        .whereType<int>()
        .toSet()
        .toList();
    if (productIds.isEmpty) {
      _showError('Please add at least one product');
      return;
    }
    try {
      isSaving.value = true;
      final response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/supplier-products/bulk'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'supplier_id': supplierId,
              'product_ids': productIds,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          _showSuccess(data['message'] as String? ?? 'Products assigned successfully');
          Get.back(result: true);
        } else {
          _showError(data['message'] as String? ?? 'Failed to assign products');
        }
      } else {
        _showError(data['message'] as String? ?? 'Failed to assign products');
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Save bulk error: $e');
      _showError('Failed to assign products');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveSingle() async {
    try {
      isSaving.value = true;
      final payload = <String, dynamic>{
        'supplier_id': selectedSupplierId.value,
        'product_id': selectedProductId.value,
      };
      final url = '${ApiConfig.apiBaseUrl}/supplier-products/$supplierProductId';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        if (data['success'] == true) {
          _showSuccess('Supplier product updated successfully');
          Get.back(result: true);
        } else {
          _showError(data['message'] as String? ?? 'Failed to update');
        }
      } else {
        _showError(data['message'] as String? ?? 'Validation failed.');
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Save single error: $e');
      _showError('Failed to save');
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
      colorText: AppColors.primaryDark,
      duration: const Duration(seconds: 2),
    );
  }
}

class SupplierItem {
  final int id;
  final String supplierName;

  SupplierItem({required this.id, required this.supplierName});

  factory SupplierItem.fromJson(Map<String, dynamic> json) {
    return SupplierItem(
      id: json['id'] as int,
      supplierName: json['supplier_name'] as String,
    );
  }
}
