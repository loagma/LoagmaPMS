import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/category_model.dart';

class CategoryListController extends GetxController {
  final int parentCatId;
  final String? parentName;

  final categories = <Category>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final showOnlyActive = true.obs;

  final searchController = TextEditingController();

  CategoryListController({this.parentCatId = 0, this.parentName});

  bool get isViewingSubcategories => parentCatId != 0;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchCategories() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.categories).replace(
        queryParameters: {
          'parent_cat_id': parentCatId.toString(),
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
          if (showOnlyActive.value) 'only_active': '1',
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          categories.value = list
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load categories');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[CATEGORY_LIST] Failed to fetch categories: $e');
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
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
    fetchCategories();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchCategories();
  }

  Future<void> toggleActiveFilter(bool onlyActive) async {
    showOnlyActive.value = onlyActive;
    await fetchCategories();
  }

  Future<void> refreshCategories() => fetchCategories();

  Future<bool> deleteCategory(int catId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.categories}/$catId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Category deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchCategories();
        return true;
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to delete category',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[CATEGORY_LIST] Delete error: $e');
      Get.snackbar(
        'Error',
        'Failed to delete: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
