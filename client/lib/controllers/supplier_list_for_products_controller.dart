import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/supplier_model.dart';

class SupplierListForProductsController extends GetxController {
  final suppliers = <Supplier>[].obs;
  final isLoading = false.obs;
  /// supplier_id -> number of products assigned
  final productCountBySupplierId = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  int productCountFor(int supplierId) =>
      productCountBySupplierId[supplierId] ?? 0;

  Future<void> loadSuppliers() async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.suppliers}?limit=500&status=ACTIVE'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          suppliers.value = items
              .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
              .toList();
          await _loadProductCounts();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_LIST_FOR_PRODUCTS] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load suppliers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProductCounts() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.apiBaseUrl}/supplier-products?limit=2000'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          final counts = <int, int>{};
          for (final item in items) {
            final map = item as Map<String, dynamic>;
            final sid = map['supplier_id'] as int?;
            if (sid != null) {
              counts[sid] = (counts[sid] ?? 0) + 1;
            }
          }
          productCountBySupplierId.value = counts;
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_LIST_FOR_PRODUCTS] Product counts error: $e');
    }
  }

  Future<void> refreshSuppliers() async {
    await loadSuppliers();
  }
}
