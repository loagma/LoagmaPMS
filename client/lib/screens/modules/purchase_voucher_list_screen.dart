import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_voucher_list_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_voucher_screen.dart';

class PurchaseVoucherListScreen extends StatelessWidget {
  const PurchaseVoucherListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseVoucherListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Purchase Vouchers',
        subtitle: 'Record purchase invoices',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: controller.fetchVouchers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.vouchers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading vouchers...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.vouchers.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchVouchers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'No purchase vouchers yet.',
                      actionLabel: 'Add Voucher',
                      onAction: () async {
                        final result = await Get.to(
                          () => const PurchaseVoucherScreen(),
                        );
                        if (result == true) {
                          controller.fetchVouchers();
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
          onRefresh: controller.fetchVouchers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.vouchers.length,
            itemBuilder: (context, index) {
              final voucher = controller.vouchers[index];
              return _VoucherCard(
                voucher: voucher,
                onTap: () async {
                  final result = await Get.to(
                    () => PurchaseVoucherScreen(voucherId: voucher.id),
                  );
                  if (result == true) {
                    controller.fetchVouchers();
                  }
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(
            () => const PurchaseVoucherScreen(),
          );
          if (result == true) {
            controller.fetchVouchers();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final PurchaseVoucherSummary voucher;
  final VoidCallback onTap;

  const _VoucherCard({required this.voucher, required this.onTap});

  Color _getStatusColor() {
    switch (voucher.status.toUpperCase()) {
      case 'DRAFT':
        return Colors.blue;
      case 'POSTED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          voucher.docNo.isNotEmpty
                              ? voucher.docNo
                              : 'PV-${voucher.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            voucher.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.vendorName.isNotEmpty
                          ? voucher.vendorName
                          : 'Vendor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (voucher.billNo.isNotEmpty) ...[
                          Text(
                            'Bill: ${voucher.billNo}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voucher.docDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
