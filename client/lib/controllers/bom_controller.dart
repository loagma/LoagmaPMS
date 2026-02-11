import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../theme/app_colors.dart';

class BomController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final finishedProducts = <Map<String, dynamic>>[].obs;
  final rawMaterialProducts = <Map<String, dynamic>>[].obs;

  final selectedFinishedProduct = Rxn<Map<String, dynamic>>();
  final bomVersion = ''.obs;
  final status = 'DRAFT'.obs;
  final remarks = ''.obs;

  final rawMaterials = <RawMaterialRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
  }

  Future<void> _loadProducts({String? search}) async {
    try {
      isLoading.value = true;

      var url = ApiConfig.products;
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}&limit=100';
      } else {
        url += '?limit=50';
      }

      debugPrint('[BOM] Fetching: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'API error');
      }

      final List products = data['data'] ?? [];
      final allProducts = products.cast<Map<String, dynamic>>();

      finishedProducts.value = allProducts;
      rawMaterialProducts.value = allProducts;

      debugPrint('[BOM] ✅ Loaded ${allProducts.length} products');
    } catch (e) {
      debugPrint('[BOM] ❌ Error: $e');
      _showError('Failed to load products');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length >= 2) {
      await _loadProducts(search: query);
    } else if (query.isEmpty) {
      await _loadProducts();
    }
  }

  void setFinishedProduct(Map<String, dynamic>? product) {
    selectedFinishedProduct.value = product;
  }

  void setBomVersion(String version) {
    bomVersion.value = version;
  }

  void setStatus(String newStatus) {
    status.value = newStatus;
  }

  void setRemarks(String text) {
    remarks.value = text;
  }

  void addRawMaterial() {
    rawMaterials.add(RawMaterialRow());
  }

  void removeRawMaterial(int index) {
    if (index >= 0 && index < rawMaterials.length) {
      rawMaterials.removeAt(index);
    }
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (selectedFinishedProduct.value == null) {
      _showError('Please select a finished product');
      return false;
    }

    if (bomVersion.value.trim().isEmpty) {
      _showError('Please enter BOM version');
      return false;
    }

    if (rawMaterials.isEmpty) {
      _showError('Please add at least one raw material');
      return false;
    }

    return true;
  }

  Future<void> saveAsDraft() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      status.value = 'DRAFT';
      _showSuccess('BOM saved as draft');
    } catch (e) {
      _showError('Failed to save BOM: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> approveBom() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Approve BOM'),
        content: const Text('Are you sure you want to approve this BOM?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      status.value = 'APPROVED';
      _showSuccess('BOM approved successfully');
    } catch (e) {
      _showError('Failed to approve BOM: $e');
    } finally {
      isSaving.value = false;
    }
  }

  bool get isLocked => status.value == 'LOCKED';
  bool get isReadOnly => isLocked;
}

class RawMaterialRow {
  final rawMaterial = Rxn<Map<String, dynamic>>();
  final quantityPerUnit = ''.obs;
  final unitType = 'KG'.obs;
  final wastagePercent = '0'.obs;
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
