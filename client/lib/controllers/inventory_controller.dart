import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/inventory_model.dart';

class InventoryController extends GetxController {
  final products = <VendorProduct>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 10;

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

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        products.clear();
      }

      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/vendor-products').replace(
        queryParameters: {
          'limit': limit.toString(),
          'page': currentPage.value.toString(),
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List productsData = data['data'] ?? [];

          final newProducts = productsData
              .map(
                (item) => VendorProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          if (loadMore) {
            products.addAll(newProducts);
          } else {
            products.value = newProducts;
          }

          // Check if there are more products to load
          hasMore.value = newProducts.length >= limit;

          if (hasMore.value) {
            currentPage.value++;
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load products');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY] Failed to fetch products: $e');
      Get.snackbar(
        'Error',
        'Failed to load inventory: $e',
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

  Future<void> refreshProducts() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchProducts();
  }

  Future<void> loadMoreProducts() async {
    if (hasMore.value && !isLoading.value) {
      await fetchProducts(loadMore: true);
    }
  }

  Future<void> updatePackStock({
    required int vendorProductId,
    required String packId,
    required double stockChange,
    required String reason,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/vendor-products/$vendorProductId/packs/$packId/stock',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'stock_change': stockChange, 'reason': reason}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'Stock updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Refresh the product list
          await refreshProducts();
        } else {
          throw Exception(data['message'] ?? 'Failed to update stock');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY] Failed to update stock: $e');
      Get.snackbar(
        'Error',
        'Failed to update stock: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkStockConsistency(
    int vendorProductId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/vendor-products/$vendorProductId/stock-consistency',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Failed to check consistency');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY] Failed to check consistency: $e');
      Get.snackbar(
        'Error',
        'Failed to check consistency: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }
}
