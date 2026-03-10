import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/tax_model.dart';

class TaxListController extends GetxController {
  final taxes = <Tax>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchTaxes();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchTaxes({bool loadMore = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        taxes.clear();
      }

      final uri = Uri.parse(ApiConfig.taxes).replace(
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
          final newTaxes =
              items.map((item) => Tax.fromJson(item as Map<String, dynamic>)).toList();

          if (loadMore) {
            taxes.addAll(newTaxes);
          } else {
            taxes.value = newTaxes;
          }

          hasMore.value = newTaxes.length >= limit;
          if (hasMore.value) currentPage.value++;
        } else {
          throw Exception(data['message']?.toString() ?? 'Failed to load taxes');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TAXES] Fetch failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load taxes: $e',
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
    fetchTaxes();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchTaxes();
  }

  Future<void> refreshTaxes() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchTaxes();
  }

  Future<void> loadMoreTaxes() async {
    if (hasMore.value && !isLoading.value) {
      await fetchTaxes(loadMore: true);
    }
  }
}
