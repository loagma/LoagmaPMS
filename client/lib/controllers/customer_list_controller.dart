import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/customer_model.dart';
import '../theme/app_colors.dart';

class CustomerListController extends GetxController {
  final customers = <Customer>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchCustomers({bool loadMore = false}) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      if (!loadMore) {
        currentPage.value = 1;
        customers.clear();
      }

      final uri = Uri.parse(ApiConfig.users).replace(
        queryParameters: {
          'role': 'Customer',
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
          final parsed = items
              .whereType<Map<String, dynamic>>()
              .map((e) => Customer.fromJson(e))
              .toList();
          if (loadMore) {
            customers.addAll(parsed);
          } else {
            customers.value = parsed;
          }
          hasMore.value = parsed.length >= limit;
          if (hasMore.value) currentPage.value++;
        }
      }
    } catch (e) {
      debugPrint('[CUSTOMERS] Fetch error: $e');
      Get.snackbar(
        'Error',
        'Failed to load customers',
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
    fetchCustomers();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchCustomers();
  }

  @override
  Future<void> refresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchCustomers();
  }

  Future<void> loadMore() async {
    if (hasMore.value && !isLoading.value) {
      await fetchCustomers(loadMore: true);
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.orange;
      case 'SUSPENDED':
        return Colors.redAccent;
      default:
        return AppColors.textMuted;
    }
  }
}
