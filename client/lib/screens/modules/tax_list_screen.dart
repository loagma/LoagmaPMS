import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/tax_list_controller.dart';
import '../../router/app_router.dart';
import '../../models/tax_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'tax_form_screen.dart';

class TaxListScreen extends StatelessWidget {
  const TaxListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaxListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Taxes',
        subtitle: 'Manage tax definitions',
        onBackPressed: () => Get.back(),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Get.toNamed(AppRoutes.productTaxForm);
              if (result == true) controller.refreshTaxes();
            },
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: const Text('Assign to product'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshTaxes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
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
              Widget content;

              if (controller.isLoading.value && controller.taxes.isEmpty) {
                content = const Center(
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
                        'Loading taxes...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (controller.taxes.isEmpty) {
                content = RefreshIndicator(
                  onRefresh: controller.refreshTaxes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ContentCard(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 64,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  controller.searchQuery.value.isNotEmpty
                                      ? 'No taxes found for "${controller.searchQuery.value}"'
                                      : 'No taxes added yet.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap + to add a new tax',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                content = RefreshIndicator(
                  onRefresh: controller.refreshTaxes,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!controller.isLoading.value &&
                          controller.hasMore.value &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200) {
                        controller.loadMoreTaxes();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          controller.taxes.length +
                          (controller.hasMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.taxes.length) {
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

                        final tax = controller.taxes[index];
                        return _TaxCard(
                          tax: tax,
                          onTap: () async {
                            final result = await Get.to(
                              () => TaxFormScreen(taxId: tax.id),
                            );
                            if (result == true) {
                              controller.refreshTaxes();
                            }
                          },
                        );
                      },
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  content,
                  if (controller.isLoading.value &&
                      controller.taxes.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.03),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const TaxFormScreen());
          if (result == true) {
            controller.refreshTaxes();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final Tax tax;
  final VoidCallback onTap;

  const _TaxCard({
    required this.tax,
    required this.onTap,
  });

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
                  color: tax.isActive
                      ? AppColors.primary
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tax.taxName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tax.taxCategory} / ${tax.taxSubCategory}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (tax.isActive ? Colors.green : AppColors.textMuted)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tax.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tax.isActive ? Colors.green : AppColors.textMuted,
                        ),
                      ),
                    ),
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
