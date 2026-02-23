import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import 'bom_list_screen.dart';
import 'issue_to_production_list_screen.dart';
import 'receive_from_production_list_screen.dart';
import 'stock_voucher_list_screen.dart';
import 'inventory_list_screen.dart';
import 'supplier_list_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount;
            if (width >= 900) {
              crossAxisCount = 4;
            } else if (width >= 600) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            final childAspectRatio = width < 400 ? 0.95 : 1.1;

            final reports = <_ReportCard>[
              _ReportCard(
                title: 'Issue to Production',
                subtitle: 'View all issued materials',
                icon: Icons.outbox_rounded,
                onTap: () {
                  Get.to(() => const IssueToProductionListScreen());
                },
              ),
              _ReportCard(
                title: 'Receive from Production',
                subtitle: 'View all received goods',
                icon: Icons.inbox_rounded,
                onTap: () {
                  Get.to(() => const ReceiveFromProductionListScreen());
                },
              ),
              _ReportCard(
                title: 'BOM',
                subtitle: 'View all bill of materials',
                icon: Icons.list_alt_rounded,
                onTap: () {
                  Get.to(() => const BomListScreen());
                },
              ),
              _ReportCard(
                title: 'Stock Voucher',
                subtitle: 'View all stock vouchers',
                icon: Icons.receipt_long_outlined,
                onTap: () {
                  Get.to(() => const StockVoucherListScreen());
                },
              ),
              _ReportCard(
                title: 'Inventory',
                subtitle: 'View all inventory items',
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  Get.to(() => const InventoryListScreen());
                },
              ),
              _ReportCard(
                title: 'Suppliers',
                subtitle: 'View all suppliers',
                icon: Icons.local_shipping_outlined,
                onTap: () {
                  Get.to(() => const SupplierListScreen());
                },
              ),
            ];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: reports.length,
                itemBuilder: (context, index) => reports[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
