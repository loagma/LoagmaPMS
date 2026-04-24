import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

class SalesInvoiceSummary {
  final int id;
  final String docNo;
  final String customerName;
  final String docDate;
  final String billNo;
  final String status;
  final bool hasWriteoff;

  SalesInvoiceSummary({
    required this.id,
    required this.docNo,
    required this.customerName,
    required this.docDate,
    required this.billNo,
    required this.status,
    required this.hasWriteoff,
  });
}

class SalesInvoiceListController extends GetxController {
  final invoices = <SalesInvoiceSummary>[].obs;
  final isLoading = false.obs;
  final _lastRefreshTime = Rxn<DateTime>();
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();

    ever<DateTime?>(_lastRefreshTime, (timestamp) {
      if (timestamp != null) {
        fetchInvoices();
      }
    });
  }

  void markForRefresh() {
    _lastRefreshTime.value = DateTime.now();
  }

  Future<void> fetchInvoices() async {
    try {
      isLoading.value = true;
      loadError.value = null;

      final response = await http
          .get(
            Uri.parse(ApiConfig.salesInvoices),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List invoicesData = data['data'] ?? [];
          invoices.value = invoicesData.map((item) {
            final prefix = item['doc_no_prefix']?.toString() ?? '';
            final num = item['doc_no_number']?.toString() ?? '';
            final docNo = prefix.isNotEmpty && num.isNotEmpty
                ? '$prefix$num'
                : (item['doc_no']?.toString() ?? '');
            return SalesInvoiceSummary(
              id: item['id'] ?? 0,
              docNo: docNo,
              customerName: item['customer_name']?.toString() ?? '',
              docDate: _formatDate(item['doc_date']?.toString() ?? item['created_at']?.toString() ?? ''),
              billNo: item['bill_no']?.toString() ?? '',
              status: item['status']?.toString() ?? 'DRAFT',
              hasWriteoff: item['has_writeoff'] == true,
            );
          }).toList();
        } else {
          invoices.value = [];
          final message = data['message']?.toString() ?? 'Could not load sales invoices from server.';
          loadError.value = message;
          _showLoadError(message);
        }
      } else {
        String message = 'Server returned ${response.statusCode} while loading sales invoices.';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final backendMessage = body['message']?.toString();
          if (backendMessage != null && backendMessage.isNotEmpty) {
            message = backendMessage;
          }
        } catch (_) {}
        invoices.value = [];
        loadError.value = message;
        _showLoadError(message);
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE_LIST] Failed: $e');
      invoices.value = [];
      const message = 'Could not load sales invoices. Please check backend/API URL.';
      loadError.value = message;
      _showLoadError(message);
    } finally {
      isLoading.value = false;
    }
  }

  void _showLoadError(String message) {
    Get.snackbar(
      'Sales Invoice Report',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
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
