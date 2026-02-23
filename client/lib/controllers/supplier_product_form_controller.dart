import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class SupplierProductFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? supplierProductId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final suppliers = <SupplierItem>[].obs;
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

  SupplierProductFormController({this.supplierProductId});

  bool get isEditMode => supplierProductId != null;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadSuppliers();
    await _loadProducts();
    if (isEditMode) {
      await _loadSupplierProduct();
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
    if (!formKey.currentState!.validate()) return;

    try {
      isSaving.value = true;

      final payload = {
        'supplier_id': selectedSupplierId.value,
        'product_id': selectedProductId.value,
        'supplier_sku': supplierSku.value.trim().isEmpty
            ? null
            : supplierSku.value.trim(),
        'supplier_product_name': supplierProductName.value.trim().isEmpty
            ? null
            : supplierProductName.value.trim(),
        'description': description.value.trim().isEmpty
            ? null
            : description.value.trim(),
        'pack_size': packSize.value.trim().isEmpty
            ? null
            : double.tryParse(packSize.value.trim()),
        'pack_unit': packUnit.value.trim().isEmpty
            ? null
            : packUnit.value.trim(),
        'min_order_qty': minOrderQty.value.trim().isEmpty
            ? null
            : double.tryParse(minOrderQty.value.trim()),
        'price': price.value.trim().isEmpty
            ? null
            : double.tryParse(price.value.trim()),
        'currency': currency.value,
        'tax_percent': taxPercent.value.trim().isEmpty
            ? null
            : double.tryParse(taxPercent.value.trim()),
        'discount_percent': discountPercent.value.trim().isEmpty
            ? null
            : double.tryParse(discountPercent.value.trim()),
        'lead_time_days': leadTimeDays.value.trim().isEmpty
            ? null
            : int.tryParse(leadTimeDays.value.trim()),
        'notes': notes.value.trim().isEmpty ? null : notes.value.trim(),
        'is_preferred': isPreferred.value ? 1 : 0,
        'is_active': isActive.value ? 1 : 0,
      };

      final url = isEditMode
          ? '${ApiConfig.apiBaseUrl}/supplier-products/$supplierProductId'
          : '${ApiConfig.apiBaseUrl}/supplier-products';

      final response = isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          _showSuccess(
            isEditMode
                ? 'Supplier product updated successfully'
                : 'Supplier product created successfully',
          );
          Get.back(result: true);
        } else {
          _showError(data['message'] ?? 'Failed to save supplier product');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_FORM] Save error: $e');
      _showError('Failed to save supplier product');
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
