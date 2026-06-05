import 'dart:convert';
import 'auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api_config.dart';

class ReceiveFromProductionSummary {
  final int receiveId;
  final int itemsCount;
  final String itemsPreview;
  final String status;
  final String date;

  ReceiveFromProductionSummary({
    required this.receiveId,
    required this.itemsCount,
    required this.itemsPreview,
    required this.status,
    required this.date,
  });
}

class ReceiveFromProductionListController extends GetxController {
  final receives = <ReceiveFromProductionSummary>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReceives();
  }

  Future<void> fetchReceives() async {
    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse(ApiConfig.receives),
            headers: AuthController.getHeaders,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List receivesData = data['data'] ?? [];
          receives.value = receivesData.map((item) {
            final createdAt = item['created_at'] ?? '';
            final formattedDate = _formatDate(createdAt);
            final count = item['items_count'] ?? 0;
            final preview = item['items_preview'] ?? '';

            return ReceiveFromProductionSummary(
              receiveId: item['id'] ?? 0,
              itemsCount: count is int ? count : 0,
              itemsPreview: preview.toString(),
              status: item['status'] ?? 'DRAFT',
              date: formattedDate,
            );
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load receives');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[RECEIVE_LIST] Failed to fetch: $e');
      Get.snackbar(
        'Error',
        'Failed to load receives: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
