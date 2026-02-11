import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api_config.dart';

class IssueToProductionSummary {
  final int issueId;
  final String finishedProductName;
  final String status;
  final String date;

  IssueToProductionSummary({
    required this.issueId,
    required this.finishedProductName,
    required this.status,
    required this.date,
  });
}

class IssueToProductionListController extends GetxController {
  final issues = <IssueToProductionSummary>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchIssues();
  }

  Future<void> fetchIssues() async {
    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse(ApiConfig.issues),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[ISSUE_LIST] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final List issuesData = data['data'] ?? [];
          debugPrint('[ISSUE_LIST] ✅ Loaded ${issuesData.length} issues');

          issues.value = issuesData.map((item) {
            final createdAt = item['created_at'] ?? '';
            final formattedDate = _formatDate(createdAt);

            return IssueToProductionSummary(
              issueId: item['issue_id'] ?? 0,
              finishedProductName: item['finished_product_name'] ?? 'Unknown',
              status: item['status'] ?? 'DRAFT',
              date: formattedDate,
            );
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load issues');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ISSUE_LIST] ❌ Failed to fetch issues: $e');
      Get.snackbar(
        'Error',
        'Failed to load issues: $e',
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
