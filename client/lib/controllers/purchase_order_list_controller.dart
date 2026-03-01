import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_order_model.dart';
import '../theme/app_colors.dart';

class PurchaseOrderListController extends GetxController {
  final purchaseOrders = <PurchaseOrder>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final limit = 20;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchPurchaseOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchPurchaseOrders({
    bool loadMore = false,
    String? supplierId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (!loadMore) {
        currentPage.value = 1;
        purchaseOrders.clear();
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': currentPage.value.toString(),
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (supplierId != null && supplierId.isNotEmpty) 'supplier_id': supplierId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      };

      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
        queryParameters: queryParams,
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          final list = items
              .map(
                (item) =>
                    PurchaseOrder.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          if (loadMore) {
            purchaseOrders.addAll(list);
          } else {
            purchaseOrders.value = list;
          }

          final pagination = data['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            final total = pagination['total'] as int? ?? 0;
            hasMore.value = purchaseOrders.length < total;
          } else {
            hasMore.value = list.length >= limit;
          }
          if (hasMore.value) currentPage.value++;
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchase orders');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PO LIST] Fetch failed: $e');
      Get.snackbar(
        'Error',
        'Failed to load purchase orders: $e',
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
    fetchPurchaseOrders();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    fetchPurchaseOrders();
  }

  Future<void> refresh() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchPurchaseOrders();
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.blue;
      case 'SENT':
        return Colors.green;
      case 'PARTIALLY_RECEIVED':
        return Colors.orange;
      case 'CLOSED':
        return AppColors.textMuted;
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> deleteOrCancelPurchaseOrder(PurchaseOrder po) async {
    if (po.id == null) return;
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.purchaseOrders}/${po.id}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? (po.status == 'DRAFT' ? 'Purchase order deleted' : 'Purchase order cancelled'),
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
      debugPrint('[PO LIST] Delete error: $e');
      Get.snackbar('Error', 'Failed to delete/cancel', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
