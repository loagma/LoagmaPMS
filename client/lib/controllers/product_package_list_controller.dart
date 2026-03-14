import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_package_model.dart';

class ProductPackageListController extends GetxController {
  final packages = <ProductPackage>[].obs;
  final isLoading = false.obs;
  final productId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final uri = Uri.parse(ApiConfig.productPackages).replace(
        queryParameters: {
          if (productId.value != null) 'product_id': productId.value.toString(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          packages.value = list
              .map((e) => ProductPackage.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load packages');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PACKAGE_LIST] Failed to fetch packages: $e');
      Get.snackbar(
        'Error',
        'Failed to load product packages: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPackages() => fetchPackages();
}

