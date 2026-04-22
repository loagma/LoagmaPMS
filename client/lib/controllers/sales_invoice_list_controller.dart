import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_invoice_model.dart';
import '../theme/app_colors.dart';

class SalesInvoiceListController extends GetxController {
  final invoices = <SalesInvoice>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
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

  Future<void> fetchInvoices() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final params = <String, String>{
        'per_page': '100',
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
      };

      final uri = Uri.parse(ApiConfig.salesInvoices).replace(
        queryParameters: params,
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load sales invoices');
      }

      final payload = body['data'];
      final rawList = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      invoices.value = rawList
          .whereType<Map<String, dynamic>>()
          .map(SalesInvoice.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[SALES INVOICE LIST] $e');
      Get.snackbar(
        'Error',
        'Failed to load sales invoices: $e',
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
    fetchInvoices();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchInvoices();
  }

  Future<void> refresh() async {
    await fetchInvoices();
  }

  Future<void> deleteInvoice(SalesInvoice invoice) async {
    if (invoice.id == null) return;

    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.salesInvoices}/${invoice.id}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        Get.snackbar(
          'Success',
          body['message']?.toString() ?? 'Sales invoice deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
        await refresh();
      } else {
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Delete failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete sales invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.blue;
      case 'ISSUED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return AppColors.textMuted;
    }
  }
}
