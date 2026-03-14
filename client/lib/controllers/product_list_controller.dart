import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';

class ProductListController extends GetxController {
  final products = <Product>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchProducts() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final uri = Uri.parse(ApiConfig.products).replace(
        queryParameters: {
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          products.value = list
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load products');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PRODUCT_LIST] Failed to fetch products: $e');
      Get.snackbar(
        'Error',
        'Failed to load products: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query.trim();
    fetchProducts();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchProducts();
  }

  Future<void> refreshProducts() => fetchProducts();
}

