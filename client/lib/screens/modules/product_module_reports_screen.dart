import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductModuleReportsScreen extends StatelessWidget {
  const ProductModuleReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ProductReportTile>[
      _ProductReportTile(
        title: 'Products',
        subtitle: 'View all products list',
        icon: Icons.inventory_2_outlined,
        onTap: () => Get.toNamed(AppRoutes.productList),
      ),
      _ProductReportTile(
        title: 'HSN Codes',
        subtitle: 'View all HSN codes list',
        icon: Icons.qr_code_rounded,
        onTap: () => Get.toNamed(AppRoutes.hsnCodeList),
      ),
      _ProductReportTile(
        title: 'Categories',
        subtitle: 'View all categories list',
        icon: Icons.category_rounded,
        onTap: () => Get.toNamed(AppRoutes.categoryList),
      ),
      _ProductReportTile(
        title: 'Product Packages',
        subtitle: 'View all product package list',
        icon: Icons.widgets_outlined,
        onTap: () => Get.toNamed(AppRoutes.productPackageList),
      ),
      _ProductReportTile(
        title: 'Taxes',
        subtitle: 'View all tax definitions list',
        icon: Icons.account_balance_outlined,
        onTap: () => Get.toNamed(AppRoutes.taxList),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Product Module Reports',
        subtitle: 'Open list reports for product masters',
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
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

class _ProductReportTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _ProductReportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
