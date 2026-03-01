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
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.purchaseOrders.isEmpty) {
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

        if (controller.purchaseOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ContentCard(
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  message: 'No purchase orders yet.',
                  actionLabel: 'Create Purchase Order',
                  onAction: () => Get.to(() => const PurchaseOrderFormScreen())?.then((_) {
                    controller.refresh();
                  }),
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
                  hintText: 'Search by PO number...',
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
                  itemCount: controller.purchaseOrders.length,
                  itemBuilder: (context, index) {
                    final po = controller.purchaseOrders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _POCard(
                        po: po,
                        statusColor: controller.statusColor(po.status),
                        onTap: () {
                          if (po.id != null) {
                            Get.to(() => PurchaseOrderFormScreen(poId: po.id))
                                ?.then((_) => controller.refresh());
                          }
                        },
                        onDeleteOrCancel: (ctx) => _showDeleteCancelDialog(ctx, controller, po),
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
        onPressed: () => Get.to(() => const PurchaseOrderFormScreen())?.then((_) {
          controller.refresh();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New PO'),
      ),
    );
  }
}

void _showDeleteCancelDialog(BuildContext context, PurchaseOrderListController controller, PurchaseOrder po) {
  final isDraft = po.status.toUpperCase() == 'DRAFT';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDraft ? 'Delete purchase order?' : 'Cancel purchase order?'),
      content: Text(
        isDraft
            ? 'Delete ${po.poNumber}? This cannot be undone.'
            : 'Cancel ${po.poNumber}? The order will be marked as CANCELLED.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await controller.deleteOrCancelPurchaseOrder(po);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(isDraft ? 'Delete' : 'Cancel'),
        ),
      ],
    ),
  );
}

class _POCard extends StatelessWidget {
  final PurchaseOrder po;
  final Color statusColor;
  final VoidCallback onTap;
  final void Function(BuildContext)? onDeleteOrCancel;

  const _POCard({
    required this.po,
    required this.statusColor,
    required this.onTap,
    this.onDeleteOrCancel,
  });

  @override
  Widget build(BuildContext context) {
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
                      Icons.receipt_long_outlined,
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
                          po.poNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          po.supplierName ?? 'Supplier #${po.supplierId}',
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
                    child: Text(
                      po.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (onDeleteOrCancel != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => onDeleteOrCancel!(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    po.docDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (po.totalAmount != null)
                    Text(
                      '₹ ${po.totalAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
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
