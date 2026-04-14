import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_return_list_controller.dart';
import '../../models/purchase_return_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_return_form_screen.dart';

class PurchaseReturnListScreen extends StatelessWidget {
  const PurchaseReturnListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseReturnListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Purchase Returns',
        subtitle: 'Track returned goods and debit notes',
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
        if (controller.isLoading.value && controller.returns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading returns...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
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
                      message: 'No purchase returns yet.',
                      actionLabel: 'Create Return',
                      onAction: () async {
                        final result = await Get.to(
                          () => const PurchaseReturnFormScreen(),
                        );
                        if (result == true) {
                          controller.refresh();
                        }
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
                  hintText: 'Search by return number or vendor...',
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
                    final ret = controller.returns[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReturnCard(
                        return_: ret,
                        statusColor: controller.statusColor(ret.status),
                        onTap: () {
                          Get.to(
                            () => PurchaseReturnFormScreen(
                              returnId: ret.id,
                              startInViewOnly: true,
                            ),
                          )?.then((_) => controller.refresh());
                        },
                        onDelete: (ctx) =>
                            _showDeleteDialog(ctx, controller, ret),
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
        onPressed: () =>
            Get.to(() => const PurchaseReturnFormScreen())?.then((_) {
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

void _showDeleteDialog(
  BuildContext context,
  PurchaseReturnListController controller,
  PurchaseReturnSummary return_,
) {
  final isDraft = return_.status.toUpperCase() == 'DRAFT';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDraft ? 'Delete purchase return?' : 'Cannot delete'),
      content: Text(
        isDraft
            ? 'Delete return ${return_.docNumber}? This cannot be undone.'
            : 'Only DRAFT returns can be deleted. This return is ${return_.status}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        if (isDraft)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deletePurchaseReturn(return_);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
      ],
    ),
  );
}

class _ReturnCard extends StatelessWidget {
  final PurchaseReturnSummary return_;
  final Color statusColor;
  final VoidCallback onTap;
  final void Function(BuildContext)? onDelete;

  const _ReturnCard({
    required this.return_,
    required this.statusColor,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String formatDocDate(String raw) {
      if (raw.isEmpty) return '-';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            return_.docNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            return_.status,
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
                      '${return_.vendorName ?? '-'}  |  ${formatDocDate(return_.docDate)}  |  ₹ ${return_.totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (return_.status == 'DRAFT')
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => onDelete?.call(context),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              IconButton(
                tooltip: 'Open',
                onPressed: onTap,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
