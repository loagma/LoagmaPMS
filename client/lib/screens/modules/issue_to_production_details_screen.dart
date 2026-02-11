import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'issue_to_production_screen.dart';

class IssueToProductionDetailsScreen extends StatefulWidget {
  final int issueId;

  const IssueToProductionDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueToProductionDetailsScreen> createState() =>
      _IssueToProductionDetailsScreenState();
}

class _IssueToProductionDetailsScreenState
    extends State<IssueToProductionDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? issueData;
  List<dynamic> materials = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIssueDetails();
  }

  Future<void> _loadIssueDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http
          .get(
            Uri.parse('${ApiConfig.issues}/${widget.issueId}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          setState(() {
            issueData = data['data']['issue'];
            materials = data['data']['items'] ?? [];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load issue');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load issue: $e';
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.blue;
      case 'ISSUED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = issueData?['status'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Issue Details',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Get.to(
                () => IssueToProductionScreen(issueId: widget.issueId),
              );
              if (result == true) {
                _loadIssueDetails();
              }
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadIssueDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadIssueDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Finished Product Info
                    ContentCard(
                      title: 'Finished Product',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Product',
                            value: issueData?['finished_product_name'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Quantity to Produce',
                            value:
                                issueData?['quantity_to_produce']?.toString() ??
                                'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Materials List
                    ContentCard(
                      title: 'Raw Materials',
                      child: materials.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No materials added',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: materials.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.primaryLight,
                              ),
                              itemBuilder: (context, index) {
                                final material = materials[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              material['raw_material_name'] ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${material['quantity']} ${material['unit_type']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Info
                    ContentCard(
                      title: 'Additional Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issueData?['remarks'] != null &&
                              issueData!['remarks'].toString().isNotEmpty)
                            _InfoRow(
                              label: 'Remarks',
                              value: issueData!['remarks'],
                            ),
                          if (issueData?['remarks'] != null &&
                              issueData!['remarks'].toString().isNotEmpty)
                            const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Created At',
                            value: _formatDate(issueData?['created_at']),
                          ),
                          if (issueData?['issued_at'] != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Issued At',
                              value: _formatDate(issueData?['issued_at']),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
