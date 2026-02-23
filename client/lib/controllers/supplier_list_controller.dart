import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/supplier_model.dart';
import '../theme/app_colors.dart';

class SupplierListController extends GetxController {
  final suppliers = <Supplier>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 10;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchSuppliers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchSuppliers({bool loadMore = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        suppliers.clear();
      }

      final uri = Uri.parse(ApiConfig.suppliers).replace(
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
          final List items = data['data'] ?? [];
          final newSuppliers = items
              .map(
                (item) =>
                    Supplier.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          if (loadMore) {
            suppliers.addAll(newSuppliers);
          } else {
            suppliers.value = newSuppliers;
          }

          hasMore.value = newSuppliers.length >= limit;
          if (hasMore.value) currentPage.value++;
        } else {
          throw Exception(data['message'] ?? 'Failed to load suppliers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SUPPLIERS] Fetch failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load suppliers: $e',
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
    fetchSuppliers();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchSuppliers();
  }

  Future<void> refreshSuppliers() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchSuppliers();
  }

  Future<void> loadMoreSuppliers() async {
    if (hasMore.value && !isLoading.value) {
      await fetchSuppliers(loadMore: true);
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'SUSPENDED':
        return Colors.redAccent;
      case 'INACTIVE':
        return Colors.orange;
      default:
        return AppColors.textMuted;
    }
  }
}
