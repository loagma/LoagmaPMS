import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductsHomeScreen extends StatelessWidget {
  const ProductsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = _productsTiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Products',
        subtitle: 'Product configuration & masters',
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

class _ProductsTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _ProductsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

List<_ProductsTile> get _productsTiles => [
      _ProductsTile(
        title: 'Products',
        subtitle: 'Create product master',
        icon: Icons.inventory_2_outlined,
        onTap: () => Get.toNamed(AppRoutes.productForm),
      ),
      _ProductsTile(
        title: 'Taxes',
        subtitle: 'Create tax master',
        icon: Icons.account_balance_outlined,
        onTap: () => Get.toNamed(AppRoutes.taxForm),
      ),
      _ProductsTile(
        title: 'Product Taxes',
        subtitle: 'Assign taxes to products',
        icon: Icons.add_link_rounded,
        onTap: () => Get.toNamed(AppRoutes.productTaxForm),
      ),
      _ProductsTile(
        title: 'Categories',
        subtitle: 'Create category and subcategory',
        icon: Icons.category_rounded,
        onTap: () => Get.toNamed(AppRoutes.categoryForm),
      ),
      _ProductsTile(
        title: 'HSN Codes',
        subtitle: 'Create HSN code master',
        icon: Icons.qr_code_rounded,
        onTap: () => Get.toNamed(AppRoutes.hsnCodeForm),
      ),
      _ProductsTile(
        title: 'Product Packages',
        subtitle: 'Create product package',
        icon: Icons.widgets_outlined,
        onTap: () => Get.toNamed(AppRoutes.productPackageForm),
      ),
    ];

