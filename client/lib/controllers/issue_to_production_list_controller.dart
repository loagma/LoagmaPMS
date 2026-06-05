import 'dart:convert';
import 'auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api_config.dart';

class IssueToProductionSummary {
  final int issueId;
  final int materialsCount;
  final String materialsPreview;
  final String status;
  final String date;

  IssueToProductionSummary({
    required this.issueId,
    required this.materialsCount,
    required this.materialsPreview,
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
            headers: AuthController.getHeaders,
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
            final count = item['materials_count'] ?? 0;
            final preview = item['materials_preview'] ?? '';

            return IssueToProductionSummary(
              issueId: item['issue_id'] ?? 0,
              materialsCount: count is int ? count : 0,
              materialsPreview: preview.toString(),
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
