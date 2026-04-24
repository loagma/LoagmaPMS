import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_order_list_screen.dart';

class SalesModuleReportsScreen extends StatelessWidget {
  const SalesModuleReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_SalesReportTile>[
      _SalesReportTile(
        title: 'Sales Orders',
        subtitle: 'View all sales orders',
        icon: Icons.receipt_long_outlined,
        onTap: () => Get.to(() => const SalesOrderListScreen()),
      ),
      _SalesReportTile(
        title: 'Sales Invoices',
        subtitle: 'View all sales invoices',
        icon: Icons.description_outlined,
        onTap: () => Get.toNamed(AppRoutes.salesInvoiceList),
      ),
      _SalesReportTile(
        title: 'Sales Returns',
        subtitle: 'View return and credit note documents',
        icon: Icons.assignment_return_outlined,
        onTap: () => Get.toNamed(AppRoutes.salesReturnList),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Sales Module Reports',
        subtitle: 'Open list reports for sales transactions',
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppColors.surface,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

class _SalesReportTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _SalesReportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
