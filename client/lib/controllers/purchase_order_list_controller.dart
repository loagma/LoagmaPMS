import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderListController extends GetxController {
  final orders = <PurchaseOrder>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders({
    int? supplierId,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      isLoading.value = true;

      final query = <String, String>{};
      if (supplierId != null && supplierId > 0) {
        query['supplier_id'] = supplierId.toString();
      }
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        query['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        query['to_date'] = toDate;
      }

      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(queryParameters: {
        if (query.isNotEmpty) ...query,
      });

      debugPrint('[PO LIST] GET $uri');

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json; charset=utf-8'},
      );

      debugPrint('[PO LIST] Response status: ${response.statusCode}');
      debugPrint(
        '[PO LIST] Response body length: ${response.body.length} bytes',
      );

      if (response.statusCode != 200) {
        _showError('Failed to load purchase orders (${response.statusCode})');
        return;
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic>) {
        data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
      } else {
        data = <dynamic>[];
      }

      final results = <PurchaseOrder>[];

      for (final item in data) {
        try {
          results.add(
            PurchaseOrder.fromJson(item as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('[PO LIST] Skipping invalid item: $e');
          continue;
        }
      }

      orders.assignAll(results);

      if (results.isEmpty) {
        debugPrint('[PO LIST] No purchase orders found');
      } else {
        debugPrint('[PO LIST] Loaded ${results.length} purchase orders');
      }
    } catch (e, st) {
      debugPrint('[PO LIST] Unexpected error while loading POs: $e');
      debugPrint('$st');
      _showError('Failed to load purchase orders: $e');
    } finally {
      isLoading.value = false;
    }
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

