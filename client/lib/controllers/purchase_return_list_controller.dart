import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_return_model.dart';

class PurchaseReturnListController extends GetxController {
  final returns = <PurchaseReturnSummary>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchReturns();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchReturns({
    bool loadMore = false,
    String? vendorId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        returns.clear();
      }

      final queryParams = <String, String>{
        'per_page': limit.toString(),
        'page': currentPage.value.toString(),
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      };

      final uri = Uri.parse(
        ApiConfig.purchaseReturns,
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final payload = data['data'];
          final List items;
          Map<String, dynamic>? pagination;

          if (payload is Map<String, dynamic>) {
            items = (payload['data'] as List? ?? const <dynamic>[]).toList();
            pagination = payload;
          } else if (payload is List) {
            items = payload;
            pagination = data['pagination'] as Map<String, dynamic>?;
          } else {
            items = const <dynamic>[];
            pagination = null;
          }

          final list = items
              .map(
                (item) => PurchaseReturnSummary.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

          if (loadMore) {
            returns.addAll(list);
          } else {
            returns.value = list;
          }

          if (pagination != null) {
            final total = (pagination['total'] as num?)?.toInt() ?? 0;
            hasMore.value = returns.length < total;
          } else {
            hasMore.value = list.length >= limit;
          }
          if (hasMore.value) currentPage.value++;
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchase returns');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PR LIST] Fetch failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load purchase returns: $e',
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
    fetchReturns();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    fetchReturns();
  }

  @override
  Future<void> refresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchReturns();
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

  Future<void> deletePurchaseReturn(PurchaseReturnSummary summary) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.purchaseReturns}/${summary.id}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Purchase return deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
        await refresh();
      } else {
        Get.snackbar(
          'Error',
          data['message']?.toString() ?? 'Failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      debugPrint('[PR LIST] Delete error: $e');
      Get.snackbar(
        'Error',
        'Failed to delete: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
