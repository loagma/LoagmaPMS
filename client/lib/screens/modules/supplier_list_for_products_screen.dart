import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_list_for_products_controller.dart';
import '../../models/supplier_model.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

/// First level: list of suppliers. Tap a supplier to see their product listing.
class SupplierListForProductsScreen extends StatelessWidget {
  const SupplierListForProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierListForProductsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit supplier products'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshSuppliers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.suppliers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading suppliers...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.suppliers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No suppliers found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add suppliers from the Create Supplier module',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshSuppliers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.suppliers.length,
            itemBuilder: (context, index) {
              final supplier = controller.suppliers[index];
              return Obx(() => _SupplierTile(
                    supplier: supplier,
                    productCount: controller.productCountFor(supplier.id),
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.supplierProductListForSupplier,
                        arguments: {
                          'supplier_id': supplier.id,
                          'supplier_name': supplier.supplierName,
                        },
                      );
                    },
                  ));
            },
          ),
        );
      }),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final int productCount;
  final VoidCallback onTap;

  const _SupplierTile({
    required this.supplier,
    required this.productCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.business_rounded, color: AppColors.primary),
        ),
        title: Text(
          supplier.supplierName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              supplier.supplierCode,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              productCount == 1
                  ? '1 product assigned'
                  : '$productCount products assigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: productCount > 0
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
        onTap: onTap,
      ),
    );
  }
}
