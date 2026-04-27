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
  final double? netTotal;

  SalesInvoiceSummary({
    required this.id,
    required this.docNo,
    required this.customerName,
    required this.docDate,
    required this.billNo,
    required this.status,
    required this.hasWriteoff,
    this.netTotal,
  });
}

class SalesInvoiceListController extends GetxController {
  final invoices = <SalesInvoiceSummary>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final fromDate = ''.obs;
  final toDate = ''.obs;
  final statusFilter = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final _lastRefreshTime = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
    ever<DateTime?>(_lastRefreshTime, (ts) {
      if (ts != null) fetchInvoices();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void markForRefresh() => _lastRefreshTime.value = DateTime.now();

  Future<void> fetchInvoices({bool loadMore = false}) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      loadError.value = null;

      if (!loadMore) {
        currentPage.value = 1;
        invoices.clear();
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': currentPage.value.toString(),
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (fromDate.value.isNotEmpty) 'from_date': fromDate.value,
        if (toDate.value.isNotEmpty) 'to_date': toDate.value,
        if (statusFilter.value.isNotEmpty) 'status': statusFilter.value,
      };

      final uri = Uri.parse(ApiConfig.salesInvoices).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List invoicesData = data['data'] ?? [];
          final list = invoicesData.map((item) {
            final prefix = item['doc_no_prefix']?.toString() ?? '';
            final num = item['doc_no_number']?.toString() ?? '';
            final docNo = prefix.isNotEmpty && num.isNotEmpty
                ? '$prefix$num'
                : (item['doc_no']?.toString() ?? '');
            final rawTotal = item['net_total'];
            double? netTotal;
            if (rawTotal is int) netTotal = rawTotal.toDouble();
            if (rawTotal is double) netTotal = rawTotal;
            if (rawTotal is String) netTotal = double.tryParse(rawTotal);
            return SalesInvoiceSummary(
              id: item['id'] ?? 0,
              docNo: docNo,
              customerName: item['customer_name']?.toString() ?? '',
              docDate: _formatDate(item['doc_date']?.toString() ?? item['created_at']?.toString() ?? ''),
              billNo: item['bill_no']?.toString() ?? '',
              status: item['status']?.toString() ?? 'DRAFT',
              hasWriteoff: item['has_writeoff'] == true,
              netTotal: netTotal,
            );
          }).toList();

          if (loadMore) {
            invoices.addAll(list);
          } else {
            invoices.value = list;
          }

          final pagination = data['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            final total = (pagination['total'] as num?)?.toInt() ?? 0;
            hasMore.value = invoices.length < total;
          } else {
            hasMore.value = list.length >= limit;
          }
          if (hasMore.value) currentPage.value++;
        } else {
          invoices.value = [];
          final message = data['message']?.toString() ?? 'Could not load sales invoices.';
          loadError.value = message;
          _showLoadError(message);
        }
      } else {
        String message = 'Server returned ${response.statusCode}.';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final m = body['message']?.toString();
          if (m != null && m.isNotEmpty) message = m;
        } catch (_) {}
        invoices.value = [];
        loadError.value = message;
        _showLoadError(message);
      }
    } catch (e) {
      debugPrint('[SALES_INVOICE_LIST] Failed: $e');
      invoices.value = [];
      const message = 'Could not load sales invoices. Check backend/API URL.';
      loadError.value = message;
      _showLoadError(message);
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query.trim();
    fetchInvoices();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchInvoices();
  }

  Future<void> refresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchInvoices();
  }

  void applyFilters({String? from, String? to, String? status}) {
    fromDate.value = from ?? '';
    toDate.value = to ?? '';
    statusFilter.value = status ?? '';
    fetchInvoices();
  }

  void clearFilters() {
    fromDate.value = '';
    toDate.value = '';
    statusFilter.value = '';
    searchController.clear();
    searchQuery.value = '';
    fetchInvoices();
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.blue;
      case 'POSTED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showLoadError(String message) {
    Get.snackbar(
      'Sales Invoices',
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
