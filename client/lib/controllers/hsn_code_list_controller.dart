import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/hsn_code_model.dart';

class HsnCodeListController extends GetxController {
  final codes = <HsnCode>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final showOnlyActive = true.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCodes();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchCodes() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.hsnCodes).replace(
        queryParameters: {
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
          codes.value =
              list.map((e) => HsnCode.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load HSN codes');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[HSN_LIST] Failed to fetch HSN codes: $e');
      Get.snackbar(
        'Error',
        'Failed to load HSN codes: $e',
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
    fetchCodes();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchCodes();
  }

  Future<void> toggleActiveFilter(bool onlyActive) async {
    showOnlyActive.value = onlyActive;
    await fetchCodes();
  }

  Future<void> refreshCodes() => fetchCodes();
}

