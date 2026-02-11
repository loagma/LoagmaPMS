import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

class BomDetailsController extends GetxController {
  final int bomId;

  final isLoading = false.obs;
  final bomDetails = Rxn<Map<String, dynamic>>();
  final bomItems = <Map<String, dynamic>>[].obs;

  BomDetailsController({required this.bomId});

  @override
  void onInit() {
    super.onInit();
    fetchBomDetails();
  }

  Future<void> fetchBomDetails() async {
    try {
      isLoading.value = true;

      final uri = Uri.parse('${ApiConfig.boms}/$bomId');
      debugPrint('[BOM DETAILS] GET $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      debugPrint('[BOM DETAILS] Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load BOM details (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final bomData = data['data'] as Map<String, dynamic>;

        // Convert bom object to map if needed
        final bom = bomData['bom'];
        if (bom is Map) {
          bomDetails.value = Map<String, dynamic>.from(bom);
        } else {
          // If it's an object, convert to map
          bomDetails.value = {
            'bom_id': bom.bom_id,
            'product_id': bom.product_id,
            'product_name': bom.product_name,
            'bom_version': bom.bom_version,
            'status': bom.status,
            'remarks': bom.remarks,
            'created_at': bom.created_at,
            'updated_at': bom.updated_at,
          };
        }

        final items = bomData['items'] as List;
        bomItems.value = items.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return {
              'bom_item_id': item.bom_item_id,
              'raw_material_id': item.raw_material_id,
              'raw_material_name': item.raw_material_name,
              'quantity_per_unit': item.quantity_per_unit,
              'unit_type': item.unit_type,
              'wastage_percent': item.wastage_percent,
            };
          }
        }).toList();

        debugPrint('[BOM DETAILS] ✅ Loaded BOM with ${bomItems.length} items');
      } else {
        throw Exception(data['message'] ?? 'Failed to load BOM');
      }
    } catch (e) {
      debugPrint('[BOM DETAILS] ❌ Error: $e');
      _showError('Failed to load BOM details: $e');
    } finally {
      isLoading.value = false;
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
}
