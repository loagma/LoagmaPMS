import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/bom_model.dart';

class BomListController extends GetxController {
  final boms = <BomMaster>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBoms();
  }

  Future<void> fetchBoms() async {
    try {
      isLoading.value = true;

      final uri = Uri.parse(ApiConfig.boms);
      debugPrint('[BOM LIST] GET $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );

      debugPrint('[BOM LIST] Response status: ${response.statusCode}');
      debugPrint(
        '[BOM LIST] Response body length: ${response.body.length} bytes',
      );

      if (response.statusCode != 200) {
        _showError('Failed to load BOMs (${response.statusCode})');
        return;
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic>) {
        data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
      } else {
        data = <dynamic>[];
      }

      final results = <BomMaster>[];

      for (final item in data) {
        try {
          results.add(BomMaster.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip invalid items silently
          continue;
        }
      }

      boms.assignAll(results);

      if (results.isEmpty) {
        debugPrint('[BOM LIST] No BOMs found');
      } else {
        debugPrint('[BOM LIST] Loaded ${results.length} BOMs');
      }
    } catch (e, st) {
      debugPrint('[BOM LIST] Unexpected error while loading BOMs: $e');
      debugPrint('$st');
      _showError('Failed to load BOMs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

void _showError(String message) {
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
  );
}

