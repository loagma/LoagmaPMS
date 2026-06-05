import 'dart:convert';
import '../../controllers/auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'receive_from_production_screen.dart';

class ReceiveFromProductionDetailsScreen extends StatefulWidget {
  final int receiveId;

  const ReceiveFromProductionDetailsScreen({
    super.key,
    required this.receiveId,
  });

  @override
  State<ReceiveFromProductionDetailsScreen> createState() =>
      _ReceiveFromProductionDetailsScreenState();
}

class _ReceiveFromProductionDetailsScreenState
    extends State<ReceiveFromProductionDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? receiveData;
  List<dynamic> items = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http
          .get(
            Uri.parse('${ApiConfig.receives}/${widget.receiveId}'),
            headers: AuthController.getHeaders,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          setState(() {
            receiveData = data['data']['receive'];
            items = data['data']['items'] ?? [];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load receive');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load receive: $e';
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.blue;
      case 'RECEIVED':
        return Colors.green;
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
    final status = receiveData?['status'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Receive Details',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Get.to(
                () => ReceiveFromProductionScreen(receiveId: widget.receiveId),
              );
              if (result == true) {
                _loadDetails();
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
                          onPressed: _loadDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        ContentCard(
                          title: 'Finished Goods',
                          child: items.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No items',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.primaryLight,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
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
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                                                  item['finished_product_name'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${item['quantity']} ${item['unit_type']}',
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

                        ContentCard(
                          title: 'Additional Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                label: 'Receive ID',
                                value: 'RFP-${widget.receiveId}',
                              ),
                              const SizedBox(height: 12),
                              if (receiveData?['remarks'] != null &&
                                  receiveData!['remarks'].toString().isNotEmpty)
                                _InfoRow(
                                  label: 'Remarks',
                                  value: receiveData!['remarks'],
                                ),
                              if (receiveData?['remarks'] != null &&
                                  receiveData!['remarks'].toString().isNotEmpty)
                                const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Created At',
                                value: _formatDate(receiveData?['created_at']),
                              ),
                              if (receiveData?['received_at'] != null) ...[
                                const SizedBox(height: 12),
                                _InfoRow(
                                  label: 'Received At',
                                  value: _formatDate(
                                    receiveData!['received_at'],
                                  ),
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
