import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class IssueToProductionController extends GetxController {
  // Form state
  final formKey = GlobalKey<FormState>();

  // Header fields
  final finishedProduct = Rxn<Product>();
  final quantityToProduce = ''.obs;
  final remarks = ''.obs;

  // Materials to issue
  final materials = <IssueMaterialRow>[].obs;

  // Products data
  final products = <Product>[].obs;

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;

      final uri = Uri.parse(ApiConfig.products);
      debugPrint('[ISSUE] GET $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );

      debugPrint('[ISSUE] Response status: ${response.statusCode}');
      debugPrint('[ISSUE] Response body length: ${response.body.length} bytes');

      if (response.statusCode != 200) {
        _showError('Failed to load products (${response.statusCode})');
        return;
      }

      List<dynamic> data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
        } else {
          data = <dynamic>[];
        }
      } on FormatException {
        final body = response.body;
        final start = body.indexOf('[');
        final end = body.lastIndexOf(']');
        if (start != -1 && end != -1 && end > start) {
          final arrayJson = body.substring(start, end + 1);
          final decoded = jsonDecode(arrayJson);
          if (decoded is List) {
            data = decoded;
          } else {
            data = <dynamic>[];
          }
        } else {
          rethrow;
        }
      }

      debugPrint('[ISSUE] Total products received: ${data.length}');

      final list = data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      products.value = list;
    } catch (e, st) {
      debugPrint('[ISSUE] Unexpected error while loading products: $e');
      debugPrint('$st');
      _showError('Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFinishedProduct(Product? product) {
    finishedProduct.value = product;
  }

  void setQuantityToProduce(String value) {
    quantityToProduce.value = value;
  }

  void setRemarks(String value) {
    remarks.value = value;
  }

  void addMaterialRow() {
    materials.add(IssueMaterialRow());
  }

  void removeMaterialRow(int index) {
    if (index >= 0 && index < materials.length) {
      materials.removeAt(index);
    }
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (finishedProduct.value == null) {
      _showError('Please select finished product');
      return false;
    }

    if (quantityToProduce.value.trim().isEmpty ||
        double.tryParse(quantityToProduce.value) == null ||
        double.parse(quantityToProduce.value) <= 0) {
      _showError('Please enter valid quantity to produce');
      return false;
    }

    if (materials.isEmpty) {
      _showError('Please add at least one material to issue');
      return false;
    }

    return true;
  }

  Future<void> saveDraft() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      _showSuccess('Issue to production saved as draft');
    } catch (e) {
      _showError('Failed to save draft: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmIssue() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      _showSuccess('Materials issued to production');
    } catch (e) {
      _showError('Failed to issue materials: $e');
    } finally {
      isSaving.value = false;
    }
  }
}

class IssueMaterialRow {
  final rawMaterial = Rxn<Product>();
  final quantity = ''.obs;
  final unitType = 'KG'.obs;
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

