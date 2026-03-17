import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/category_form_controller.dart';
import '../../models/category_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CategoryFormScreen extends StatelessWidget {
  const CategoryFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    int? categoryId;
    int? parentCatId;
    if (args is int) {
      categoryId = args;
    } else if (args is Map) {
      final raw = args['parentCatId'];
      if (raw is int) {
        parentCatId = raw;
      } else if (raw != null) {
        parentCatId = int.tryParse(raw.toString());
      }
    }

    final controller = Get.put(
      CategoryFormController(categoryId: categoryId, parentCatId: parentCatId),
    );

    final String title = controller.isEditMode
        ? (controller.isSubcategoryForm ? 'Edit Subcategory' : 'Edit Category')
        : (controller.isSubcategoryForm ? 'Add Subcategory' : 'Add Category');
    final String subtitle =
        controller.isSubcategoryForm ? 'Subcategory' : 'Category';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: title,
        subtitle: subtitle,
        onBackPressed: () => Get.back(),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.isEditMode) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading category...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Form(
              key: controller.formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ContentCard(
                        title: controller.isSubcategoryForm
                            ? 'Subcategory Details'
                            : 'Category Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Obx(
                          () => TextFormField(
                            initialValue: controller.name.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Name *',
                              hintText: 'Enter name',
                            ),
                            onChanged: (v) => controller.name.value = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (!controller.isEditMode &&
                            !controller.isSubcategoryForm) ...[
                          const SizedBox(height: 16),
                          Obx(
                            () => SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Add subcategory now'),
                              subtitle: const Text(
                                'Create one subcategory along with this category',
                              ),
                              value: controller.addSubcategoryNow.value,
                              onChanged: (v) {
                                controller.addSubcategoryNow.value = v;
                                if (!v) {
                                  controller.subcategoryName.value = '';
                                }
                              },
                            ),
                          ),
                          Obx(
                            () => controller.addSubcategoryNow.value
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextFormField(
                                      initialValue:
                                          controller.subcategoryName.value,
                                      decoration: AppInputDecoration.standard(
                                        labelText: 'Subcategory Name *',
                                        hintText: 'Enter subcategory name',
                                      ),
                                      onChanged: (v) =>
                                          controller.subcategoryName.value = v,
                                      validator: (v) {
                                        if (!controller.addSubcategoryNow.value) {
                                          return null;
                                        }
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                        if (controller.isSubcategoryForm &&
                            controller.isEditMode) ...[
                          const SizedBox(height: 16),
                          Obx(() {
                            if (controller.parentCategories.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final validValue =
                                controller.parentCategories
                                    .any((c) =>
                                        c.catId ==
                                        controller.selectedParentCatId.value)
                                ? controller.selectedParentCatId.value
                                : (controller.parentCategories.isNotEmpty
                                    ? controller.parentCategories.first.catId
                                    : null);
                            return DropdownButtonFormField<int>(
                              value: validValue,
                              isExpanded: true,
                              decoration: AppInputDecoration.standard(
                                labelText: 'Parent Category',
                                hintText: 'Select parent',
                              ),
                              items: controller.parentCategories
                                  .map((Category c) => DropdownMenuItem<int>(
                                        value: c.catId,
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  controller.selectedParentCatId.value = v;
                                }
                              },
                            );
                          }),
                        ],
                        const SizedBox(height: 16),
                        Obx(
                          () => CheckboxListTile(
                            title: const Text('Active'),
                            value: controller.isActive.value,
                            onChanged: (v) {
                              if (v != null) controller.isActive.value = v;
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => ActionButtonBar(
                      buttons: [
                        ActionButton(
                          label: 'Cancel',
                          onPressed: controller.isSaving.value
                              ? null
                              : () => Get.back(),
                        ),
                        ActionButton(
                          label: controller.isEditMode ? 'Update' : 'Save',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () async {
                                  final ok = await controller.save();
                                  if (ok) Get.back(result: true);
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => controller.isSaving.value
                  ? Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.28),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  controller.addSubcategoryNow.value &&
                                          !controller.isEditMode &&
                                          !controller.isSubcategoryForm
                                      ? 'Saving category and subcategory...'
                                      : 'Saving category...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }),
    );
  }
}
