import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/category_list_controller.dart';
import '../../models/category_model.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({
    super.key,
    this.initialParentCatId,
    this.initialParentName,
  });

  /// When opening subcategories from the main list, pass these so navigation is reliable.
  final int? initialParentCatId;
  final String? initialParentName;

  @override
  Widget build(BuildContext context) {
    int parentCatId = 0;
    String? parentName;

    if (initialParentCatId != null) {
      parentCatId = initialParentCatId!;
      parentName = initialParentName;
    } else {
      final args = Get.arguments;
      if (args is Map) {
        parentCatId = args['parentCatId'] is int
            ? args['parentCatId'] as int
            : int.tryParse(args['parentCatId']?.toString() ?? '0') ?? 0;
        parentName = args['parentName']?.toString();
      }
    }

    // Use a tag so subcategories screen has its own controller and doesn't replace the root list.
    final String tag = parentCatId != 0
        ? 'category_list_parent_$parentCatId'
        : 'category_list_root';
    final controller = Get.put(
      CategoryListController(parentCatId: parentCatId, parentName: parentName),
      tag: tag,
    );

    final String title = controller.isViewingSubcategories
        ? 'Subcategories${controller.parentName != null ? ' of ${controller.parentName}' : ''}'
        : 'Categories';
    final String subtitle = controller.isViewingSubcategories
        ? 'Manage subcategories'
        : 'Manage categories and subcategories';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: title,
        subtitle: subtitle,
        onBackPressed: () => Get.back(),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: () => controller.toggleActiveFilter(
                !controller.showOnlyActive.value,
              ),
              icon: Icon(
                controller.showOnlyActive.value
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
              ),
              label: Text(
                controller.showOnlyActive.value ? 'Active only' : 'All',
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshCategories,
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
              onChanged: controller.onSearchChanged,
              onSubmitted: controller.onSearchSubmit,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
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
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.categories.isEmpty) {
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
                        'Loading categories...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshCategories,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ContentCard(
                          child: EmptyState(
                            icon: Icons.category_rounded,
                            message: controller.searchQuery.value.isNotEmpty
                                ? 'No categories found for "${controller.searchQuery.value}"'
                                : controller.isViewingSubcategories
                                    ? 'No subcategories added yet.'
                                    : 'No categories added yet.',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refreshCategories,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.categories.length,
                        itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () async {
                        if (controller.isViewingSubcategories) {
                          final result = await Get.toNamed(
                            AppRoutes.categoryForm,
                            arguments: category.catId,
                          );
                          if (result == true) controller.refreshCategories();
                        } else {
                          Get.to(
                            () => CategoryListScreen(
                              initialParentCatId: category.catId,
                              initialParentName: category.name,
                            ),
                          );
                        }
                      },
                      onEdit: () async {
                        final result = await Get.toNamed(
                          AppRoutes.categoryForm,
                          arguments: category.catId,
                        );
                        if (result == true) controller.refreshCategories();
                      },
                      onDelete: () async {
                        final confirm = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Delete category?'),
                            content: Text(
                              'Delete "${category.name}"? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Get.back(result: true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await controller.deleteCategory(category.catId);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            Obx(() {
              final total = controller.totalCount.value;
              final pages = controller.totalPages.value;
              if (pages <= 1 && total <= CategoryListController.pageLimit) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: controller.currentPage.value > 1
                          ? () => controller.goToPage(
                                controller.currentPage.value - 1,
                              )
                          : null,
                      tooltip: 'Previous page',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Page ${controller.currentPage.value} of ${controller.totalPages.value} (${controller.totalCount.value} total)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: controller.currentPage.value <
                              controller.totalPages.value
                          ? () => controller.goToPage(
                                controller.currentPage.value + 1,
                              )
                          : null,
                      tooltip: 'Next page',
                    ),
                  ],
                ),
              );
            }),
          ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.toNamed(
            AppRoutes.categoryForm,
            arguments: controller.isViewingSubcategories
                ? {'parentCatId': controller.parentCatId}
                : null,
          );
          if (result == true) controller.refreshCategories();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
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
                    color: category.isActive
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.isTopLevel
                            ? 'ID: ${category.catId}'
                            : 'ID: ${category.catId}  •  Parent ID: ${category.parentCatId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: category.isActive
                              ? Colors.green
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
