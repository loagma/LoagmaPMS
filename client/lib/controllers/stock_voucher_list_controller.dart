import 'dart:convert';
import 'auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api_config.dart';

class StockVoucherSummary {
  final int voucherId;
  final String voucherType;
  final int itemsCount;
  final String itemsPreview;
  final String status;
  final String date;

  StockVoucherSummary({
    required this.voucherId,
    required this.voucherType,
    required this.itemsCount,
    required this.itemsPreview,
    required this.status,
    required this.date,
  });
}

class StockVoucherListController extends GetxController {
  final vouchers = <StockVoucherSummary>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse(ApiConfig.stockVouchers),
            headers: AuthController.getHeaders,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List vouchersData = data['data'] ?? [];
          vouchers.value = vouchersData.map((item) {
            final createdAt = item['created_at'] ?? '';
            final formattedDate = _formatDate(createdAt);
            final count = item['items_count'] ?? 0;
            final preview = item['items_preview'] ?? '';

            return StockVoucherSummary(
              voucherId: item['id'] ?? 0,
              voucherType: item['voucher_type'] ?? 'IN',
              itemsCount: count is int ? count : 0,
              itemsPreview: preview.toString(),
              status: item['status'] ?? 'DRAFT',
              date: formattedDate,
            );
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load vouchers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[STOCK_VOUCHER_LIST] Failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load vouchers: $e',
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
