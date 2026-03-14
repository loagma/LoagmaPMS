import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_package_list_controller.dart';
import '../../controllers/product_package_form_controller.dart';
import '../../models/product_package_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'product_package_form_screen.dart';

class ProductPackageListScreen extends StatelessWidget {
  const ProductPackageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductPackageListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(
        title: 'Product Packages',
        subtitle: 'Configure pack sizes',
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.packages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading packages...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.packages.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshPackages,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 250,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    child: EmptyState(
                      icon: Icons.widgets_outlined,
                      message: 'No product packages defined yet.',
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshPackages,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.packages.length,
            itemBuilder: (context, index) {
              final pkg = controller.packages[index];
              return _PackageCard(
                pkg: pkg,
                onTap: () async {
                  final result = await Get.to(
                    () => ProductPackageFormScreen(
                      productId: pkg.productId,
                      packageId: pkg.id,
                    ),
                    binding: BindingsBuilder(() {
                      Get.put(
                        ProductPackageFormController(
                          productId: pkg.productId,
                          packageId: pkg.id,
                        ),
                      );
                    }),
                  );
                  if (result == true) controller.refreshPackages();
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // For now, require navigation with a preselected productId
          final productId = Get.arguments is int ? Get.arguments as int? : null;
          if (productId == null) {
            Get.snackbar(
              'Select product',
              'Open this screen with a selected product to add packages.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return;
          }

          final result = await Get.to(
            () => ProductPackageFormScreen(productId: productId),
            binding: BindingsBuilder(() {
              Get.put(
                ProductPackageFormController(productId: productId),
              );
            }),
          );
          if (result == true) controller.refreshPackages();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ProductPackage pkg;
  final VoidCallback onTap;

  const _PackageCard({required this.pkg, required this.onTap});

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
                height: 50,
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
                      'Product: ${pkg.productId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pkg.packSize} ${pkg.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (pkg.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${pkg.price}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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

