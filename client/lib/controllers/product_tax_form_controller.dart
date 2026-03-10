import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/tax_model.dart';

class ProductTaxFormController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final taxes = <Tax>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  final selectedProductId = Rxn<int>();
  final selectedProductName = ''.obs;
  final selectedTaxId = Rxn<int>();
  final taxPercent = '0'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTaxes();
  }

  Future<void> loadTaxes() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(ApiConfig.taxes).replace(
          queryParameters: {'limit': '100', 'is_active': 'true'},
        ),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          taxes.value =
              items.map((e) => Tax.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[PRODUCT_TAX] Load taxes error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setProduct(int id, String name) {
    selectedProductId.value = id;
    selectedProductName.value = name;
  }

  void clearProduct() {
    selectedProductId.value = null;
    selectedProductName.value = '';
  }

  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    final productId = selectedProductId.value;
    final taxId = selectedTaxId.value;
    if (productId == null || taxId == null) {
      Get.snackbar(
        'Error',
        'Please select both product and tax',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    final percent = double.tryParse(taxPercent.value);
    if (percent == null || percent < 0 || percent > 100) {
      Get.snackbar(
        'Error',
        'Tax percent must be between 0 and 100',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    isSaving.value = true;
    try {
      final payload = {
        'product_id': productId,
        'tax_id': taxId,
        'tax_percent': percent,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.productTaxes),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'Tax assigned to product successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          clearProduct();
          selectedTaxId.value = null;
          taxPercent.value = '0';
          return true;
        }
      }
      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to assign tax',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[PRODUCT_TAX] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to assign tax: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
