import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SalesHomeScreen extends StatelessWidget {
  const SalesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = _salesTiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Sales',
        subtitle: 'Sales transactions',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ListView.separated(
          itemCount: tiles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final tile = tiles[index];
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
                child: Icon(tile.icon, color: AppColors.primary, size: 22),
              ),
              title: Text(
                tile.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Text(
                tile.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: tile.onTap,
            );
          },
        ),
      ),
    );
  }
}

class _SalesTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _SalesTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

List<_SalesTile> get _salesTiles => [
  _SalesTile(
    title: 'Sales Order',
    subtitle: 'Create sales order',
    icon: Icons.receipt_long_outlined,
    onTap: () => Get.toNamed(AppRoutes.salesOrders),
  ),
  _SalesTile(
    title: 'Sales Invoice',
    subtitle: 'Create sales invoice',
    icon: Icons.description_outlined,
    onTap: () => Get.toNamed(AppRoutes.salesInvoice),
  ),
  _SalesTile(
    title: 'Sales Return',
    subtitle: 'Return goods or create credit note',
    icon: Icons.assignment_return_outlined,
    onTap: () => Get.toNamed(AppRoutes.salesReturnForm),
  ),
];
