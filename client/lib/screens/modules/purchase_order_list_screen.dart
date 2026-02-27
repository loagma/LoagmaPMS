import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_order_list_controller.dart';
import '../../models/purchase_order_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_order_form_screen.dart';

class PurchaseOrderListScreen extends StatelessWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseOrderListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Purchase Orders',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => controller.fetchOrders(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading purchase orders...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchOrders,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    child: EmptyState(
                      icon: Icons.description_outlined,
                      message: 'No purchase orders created yet.',
                      actionLabel: 'Create Purchase Order',
                      onAction: () async {
                        final result = await Get.to(
                          () => const PurchaseOrderFormScreen(),
                        );
                        if (result == true) {
                          controller.fetchOrders();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchOrders,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PurchaseOrderCard(
                  order: order,
                  onTap: () async {
                    if (order.id == null) return;
                    final result = await Get.to(
                      () => PurchaseOrderFormScreen(
                        purchaseOrderId: order.id,
                      ),
                    );
                    if (result == true) {
                      controller.fetchOrders();
                    }
                  },
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(
            () => const PurchaseOrderFormScreen(),
          );
          if (result == true) {
            controller.fetchOrders();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create PO'),
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;

  const _PurchaseOrderCard({
    required this.order,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Colors.blue;
      case 'PARTIALLY_RECEIVED':
        return Colors.orange;
      case 'CLOSED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'DRAFT':
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Icons.send_rounded;
      case 'PARTIALLY_RECEIVED':
        return Icons.local_shipping_outlined;
      case 'CLOSED':
        return Icons.check_circle_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      case 'DRAFT':
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Card(
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.poNumber.isNotEmpty
                              ? order.poNumber
                              : (order.id != null
                                  ? 'PO-${order.id}'
                                  : 'Purchase Order'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (order.supplierName != null &&
                            order.supplierName!.isNotEmpty)
                          Text(
                            order.supplierName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(order.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.docDate,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (order.totalAmount != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.totalAmount!.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

