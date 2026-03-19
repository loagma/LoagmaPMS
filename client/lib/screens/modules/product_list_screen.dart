import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_list_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'product_form_screen.dart';
import 'product_view_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Products',
        subtitle: 'List and manage products',
      ),
      body: Column(
        children: [
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading products...',
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
                                ? 'No products found for \"${controller.searchQuery.value}\"'
                                : 'No products added yet.',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return _ProductCard(
                      product: product,
                      onTap: () async {
                        final result = await Get.to(
                          () => ProductViewScreen(productId: product.id),
                        );
                        if (result == true) {
                          controller.refreshProducts();
                        }
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const ProductFormScreen());
          if (result == true) {
            controller.refreshProducts();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${product.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.code != null && product.code!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.code!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (product.defaultUnit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unit: ${product.defaultUnit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (product.taxes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: product.taxes
                            .map(
                              (tax) => Chip(
                                label: Text(
                                  '${tax.name} ${tax.percent.toStringAsFixed(2)}%',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: AppColors.background,
                                shape: StadiumBorder(
                                  side: BorderSide(color: AppColors.border),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ]
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

