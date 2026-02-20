import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/inventory_controller.dart';
import '../../models/inventory_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'inventory_details_screen.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Inventory Management',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: controller.clearSearch,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.onSearch,
            ),
          ),

          // Product List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading inventory...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.products.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ContentCard(
                          child: EmptyState(
                            icon: Icons.inventory_2_outlined,
                            message: controller.searchQuery.value.isNotEmpty
                                ? 'No products found for "${controller.searchQuery.value}"'
                                : 'No inventory items yet.',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshProducts,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoading.value &&
                        controller.hasMore.value &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.loadMoreProducts();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        controller.products.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.products.length) {
                        // Loading indicator for pagination
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final product = controller.products[index];
                      return _ProductCard(
                        product: product,
                        onTap: () async {
                          final result = await Get.to(
                            () => InventoryDetailsScreen(
                              vendorProductId: product.id,
                            ),
                          );
                          if (result == true) {
                            controller.refreshProducts();
                          }
                        },
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final VendorProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  Color _getStockStatusColor() {
    if (product.inStock == '0') {
      return Colors.red;
    }

    // Check if any pack has low stock
    final hasLowStock = product.packs.any(
      (pack) => pack.stock > 0 && pack.stock < 10,
    );
    if (hasLowStock) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _getStockStatusText() {
    if (product.inStock == '0') {
      return 'Out of Stock';
    }

    final hasLowStock = product.packs.any(
      (pack) => pack.stock > 0 && pack.stock < 10,
    );
    if (hasLowStock) {
      return 'Low Stock';
    }

    return 'In Stock';
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
              // Status Indicator
              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: _getStockStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product ID
                    Text(
                      'VP-${product.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Product Name
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Stock Status and Pack Count
                    Row(
                      children: [
                        // Stock Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor().withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStockStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStockStatusColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Pack Count
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.packs.length} pack${product.packs.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    // Show pack sizes preview with stock
                    if (product.packs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...product.packs.take(3).map((pack) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${pack.displayName}: ${pack.stock.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                          if (product.packs.length > 3)
                            Text(
                              '+${product.packs.length - 3} more',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
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
