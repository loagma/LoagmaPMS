import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_invoice_model.dart';

class SalesInvoiceListController extends GetxController {
  final invoices = <SalesInvoiceSummary>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchInvoices({
    bool loadMore = false,
    String? customerId,
    String? fromDate,
    String? toDate,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        invoices.clear();
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': currentPage.value.toString(),
        'status': 'billed',
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      };

      final uri = Uri.parse(ApiConfig.salesOrders).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          final list = items
              .whereType<Map<String, dynamic>>()
              .map(SalesInvoiceSummary.fromJson)
              .toList();

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
          throw Exception(data['message'] ?? 'Failed to load invoices');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INV LIST] Fetch failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load invoices: $e',
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
    currentPage.value = 1;
    fetchInvoices();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    fetchInvoices();
  }

  @override
  Future<void> refresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchInvoices();
  }
}
