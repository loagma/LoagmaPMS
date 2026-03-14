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
        subtitle: 'List and create products',
        icon: Icons.inventory_2_outlined,
        onTap: () => Get.toNamed(AppRoutes.productList),
      ),
      _ProductsTile(
        title: 'Taxes',
        subtitle: 'Manage tax masters',
        icon: Icons.account_balance_outlined,
        onTap: () => Get.toNamed(AppRoutes.taxList),
      ),
      _ProductsTile(
        title: 'Product Taxes',
        subtitle: 'Assign taxes to products',
        icon: Icons.add_link_rounded,
        onTap: () => Get.toNamed(AppRoutes.productTaxForm),
      ),
      _ProductsTile(
        title: 'Categories',
        subtitle: 'Manage categories and subcategories',
        icon: Icons.category_rounded,
        onTap: () => Get.toNamed(AppRoutes.categoryList),
      ),
      _ProductsTile(
        title: 'HSN Codes',
        subtitle: 'Manage HSN code master',
        icon: Icons.qr_code_rounded,
        onTap: () => Get.toNamed(AppRoutes.hsnCodeList),
      ),
      _ProductsTile(
        title: 'Product Packages',
        subtitle: 'Configure product pack sizes',
        icon: Icons.widgets_outlined,
        onTap: () => Get.toNamed(AppRoutes.productPackageList),
      ),
    ];

class _ProductsTileCard extends StatelessWidget {
  final _ProductsTile tile;

  const _ProductsTileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tile.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tile.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                tile.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tile.subtitle,
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

