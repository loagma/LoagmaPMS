import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

class PurchaseVoucherSummary {
  final int id;
  final String docNo;
  final String vendorName;
  final String docDate;
  final String billNo;
  final String status;

  PurchaseVoucherSummary({
    required this.id,
    required this.docNo,
    required this.vendorName,
    required this.docDate,
    required this.billNo,
    required this.status,
  });
}

class PurchaseVoucherListController extends GetxController {
  final vouchers = <PurchaseVoucherSummary>[].obs;
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
            Uri.parse(ApiConfig.purchaseVouchers),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List vouchersData = data['data'] ?? [];
          vouchers.value = vouchersData.map((item) {
            final prefix = item['doc_no_prefix']?.toString() ?? '';
            final num = item['doc_no_number']?.toString() ?? '';
            final docNo = prefix.isNotEmpty && num.isNotEmpty
                ? '$prefix$num'
                : (item['doc_no']?.toString() ?? '');
            return PurchaseVoucherSummary(
              id: item['id'] ?? 0,
              docNo: docNo,
              vendorName: item['vendor_name']?.toString() ??
                  item['supplier_name']?.toString() ??
                  '',
              docDate: _formatDate(
                  item['doc_date']?.toString() ?? item['created_at']?.toString() ?? ''),
              billNo: item['bill_no']?.toString() ?? '',
              status: item['status']?.toString() ?? 'DRAFT',
            );
          }).toList();
        } else {
          vouchers.value = [];
        }
      } else {
        // Backend may not exist yet; treat as empty list
        vouchers.value = [];
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER_LIST] Failed: $e');
      vouchers.value = [];
      Get.snackbar(
        'Notice',
        'Could not load purchase vouchers. Backend may not be ready.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr.split(' ').first);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
