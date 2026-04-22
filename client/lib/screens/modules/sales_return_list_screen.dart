import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sales_return_list_controller.dart';
import '../../models/sales_return_model.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SalesReturnListScreen extends StatelessWidget {
  const SalesReturnListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesReturnListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Sales Returns',
        subtitle: 'Track and manage returned quantities',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.returns.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (controller.returns.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    child: EmptyState(
                      icon: Icons.assignment_return_outlined,
                      message: 'No posted sales returns yet.',
                      actionLabel: 'Create Sales Return',
                      onAction: () {
                        Get.toNamed(AppRoutes.salesReturnForm)?.then((_) {
                          controller.refresh();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search by order id...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: controller.onSearch,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.returns.length,
                  itemBuilder: (context, index) {
                    final salesReturn = controller.returns[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReturnCard(
                        salesReturn: salesReturn,
                        statusColor: controller.statusColor(salesReturn.returnStatus),
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.salesReturnForm,
                            arguments: {
                              'returnId': salesReturn.orderId,
                              'viewOnly': true,
                            },
                          )?.then((_) => controller.refresh());
                        },
                        onReset: () async {
                          await controller.resetReturn(salesReturn);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.salesReturnForm)?.then((_) {
          controller.refresh();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Return'),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final SalesReturn salesReturn;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _ReturnCard({
    required this.salesReturn,
    required this.statusColor,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${salesReturn.orderId}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            salesReturn.returnStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Return Date: ${salesReturn.returnDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (salesReturn.totalRefund != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Refund: ${salesReturn.totalRefund!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reset return',
                onPressed: () {
                  _showResetDialog(context, onReset);
                },
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset sales return?'),
        content: const Text(
          'This will clear returned quantities for the order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
