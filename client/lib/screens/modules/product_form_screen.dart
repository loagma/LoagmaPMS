import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_form_controller.dart';
import '../../models/category_model.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

Category? _firstWhereOrNull(List<Category> list, bool Function(Category) test) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}

class ProductFormScreen extends StatelessWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  Future<Category?> _pickCategory(
    BuildContext context, {
    required String title,
    required List<Category> items,
    bool allowNone = false,
  }) async {
    return showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        String query = '';

        List<Category> filtered() {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return items;
          final isNumeric = int.tryParse(q) != null;
          return items.where((c) {
            final nameMatch = c.name.toLowerCase().contains(q);
            if (isNumeric) {
              final idStr = c.catId.toString();
              return nameMatch || idStr.contains(q);
            }
            return nameMatch;
          }).toList();
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final list = filtered();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length + (allowNone ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (allowNone && index == 0) {
                              return ListTile(
                                leading: const Icon(Icons.block_rounded),
                                title: const Text('None (category only)'),
                                onTap: () => Navigator.of(context).pop(null),
                              );
                            }
                            final item = list[index - (allowNone ? 1 : 0)];
                            return ListTile(
                              title: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('ID: ${item.catId}'),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                              onTap: () => Navigator.of(context).pop(item),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductFormController(productId: productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Product' : 'Add Product',
        subtitle: 'Product master',
        onBackPressed: () => Get.back(),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading product...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Form(
          key: controller.formKey,
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StepChip(
                        label: 'Basic & Inventory',
                        step: 1,
                        controller: controller,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StepChip(
                        label: 'Tax, Status & Packages',
                        step: 2,
                        controller: controller,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: controller.currentStep.value == 1
                        ? const _ProductStepOne()
                        : const _ProductStepTwo(),
                  );
                }),
              ),
              Obx(
                () => ActionButtonBar(
                  buttons: [
                    if (controller.currentStep.value == 2)
                      ActionButton(
                        label: 'Previous',
                        onPressed: controller.isSaving.value
                            ? null
                            : () => controller.goToStep(1),
                      )
                    else
                      ActionButton(
                        label: 'Cancel',
                        onPressed: controller.isSaving.value
                            ? null
                            : () => Get.back(),
                      ),
                    ActionButton(
                      label: controller.currentStep.value == 1
                          ? 'Next'
                          : (controller.isEditMode ? 'Update' : 'Create'),
                      isPrimary: true,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              if (controller.currentStep.value == 1) {
                                if (!controller.validateStep1() ||
                                    !(controller.formKey.currentState
                                            ?.validate() ??
                                        false)) {
                                  return;
                                }
                                controller.goToStep(2);
                                return;
                              }
                              // Step 2 -> save
                              if (!(controller.formKey.currentState
                                      ?.validate() ??
                                  false)) {
                                return;
                              }
                              final ok = await controller.save();
                              if (ok) {
                                Get.offAllNamed(AppRoutes.dashboard);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.step,
    required this.controller,
  });

  final String label;
  final int step;
  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isActive = controller.currentStep.value == step;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primaryDark : AppColors.textMuted,
            ),
          ),
        ),
      );
    });
  }
}

class _ProductStepOne extends StatelessWidget {
  const _ProductStepOne();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductFormController>();

    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(16),
      child: ContentCard(
        title: 'Basic Information & Inventory',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => TextFormField(
                initialValue: controller.name.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Product Name *',
                  hintText: 'Enter product name',
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
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                initialValue: controller.keywords.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Keywords',
                  hintText: 'Comma separated search keywords',
                ),
                onChanged: (v) => controller.keywords.value = v,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                initialValue: controller.description.value,
                maxLines: 3,
                decoration: AppInputDecoration.standard(
                  labelText: 'Description *',
                  hintText: 'Short description for customers',
                ),
                onChanged: (v) => controller.description.value = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                initialValue: controller.brand.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Brand *',
                  hintText: 'Brand name',
                ),
                onChanged: (v) => controller.brand.value = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.categories.isEmpty) {
                return const SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'Loading categories...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              final selected = _firstWhereOrNull(
                controller.categories,
                (c) => c.catId == controller.selectedCategoryId.value,
              );

              return TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: selected == null
                      ? ''
                      : '${selected.name} (ID: ${selected.catId})',
                ),
                decoration: AppInputDecoration.standard(
                  labelText: 'Category *',
                  hintText: 'Tap to select category',
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                onTap: () async {
                  final picked = await (context
                          .findAncestorWidgetOfExactType<ProductFormScreen>()
                      as ProductFormScreen)
                      ._pickCategory(
                    context,
                    title: 'Select Category',
                    items: controller.categories,
                  );
                  if (picked != null) {
                    controller.onCategoryChanged(picked.catId);
                  }
                },
                validator: (_) {
                  if (controller.selectedCategoryId.value == 0) {
                    return 'Please select a category';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedCategoryId.value == 0) {
                return const SizedBox.shrink();
              }
              if (controller.subcategories.isEmpty) {
                return const SizedBox.shrink();
              }
              final selectedSub = _firstWhereOrNull(
                controller.subcategories,
                (c) => c.catId == controller.selectedSubcategoryId.value,
              );

              return TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: selectedSub == null
                      ? ''
                      : '${selectedSub.name} (ID: ${selectedSub.catId})',
                ),
                decoration: AppInputDecoration.standard(
                  labelText: 'Subcategory',
                  hintText: 'Optional – tap to select subcategory',
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                onTap: () async {
                  final picked = await (context
                          .findAncestorWidgetOfExactType<ProductFormScreen>()
                      as ProductFormScreen)
                      ._pickCategory(
                    context,
                    title: 'Select Subcategory',
                    items: controller.subcategories,
                    allowNone: true,
                  );
                  // allowNone=true: null means "none"
                  controller.selectedSubcategoryId.value = picked?.catId ?? 0;
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.ctypeId.value.isEmpty
                    ? 'vegetables_fruits'
                    : controller.ctypeId.value,
                isExpanded: true,
                decoration: AppInputDecoration.standard(
                  labelText: 'Cart Type *',
                  hintText: 'Select cart type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'vegetables_fruits',
                    child: Text('Vegetables & Fruits'),
                  ),
                  DropdownMenuItem(
                    value: 'grocery',
                    child: Text('Grocery'),
                  ),
                  DropdownMenuItem(
                    value: 'dairy',
                    child: Text('Dairy'),
                  ),
                  DropdownMenuItem(
                    value: 'meat_seafood',
                    child: Text('Meat & Seafood'),
                  ),
                  DropdownMenuItem(
                    value: 'bakery',
                    child: Text('Bakery'),
                  ),
                  DropdownMenuItem(
                    value: 'beverages',
                    child: Text('Beverages'),
                  ),
                  DropdownMenuItem(
                    value: 'snacks',
                    child: Text('Snacks'),
                  ),
                  DropdownMenuItem(
                    value: 'household',
                    child: Text('Household'),
                  ),
                  DropdownMenuItem(
                    value: 'personal_care',
                    child: Text('Personal Care'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) controller.ctypeId.value = v;
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                initialValue: controller.seqNo.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Sequence Number',
                  hintText: 'Display order (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(),
                onChanged: (v) => controller.seqNo.value = v,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inventory Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.productType.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Inventory Type *',
                  hintText: 'Select type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'SINGLE',
                    child: Text('Single (no packs)'),
                  ),
                  DropdownMenuItem(
                    value: 'PACK_WISE',
                    child: Text('Pack wise'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) controller.productType.value = v;
                },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.defaultUnit.value.isEmpty
                    ? 'WEIGHT'
                    : controller.defaultUnit.value,
                isExpanded: true,
                decoration: AppInputDecoration.standard(
                  labelText: 'Unit Type (Input Type)',
                  hintText: 'Select unit type',
                ),
                items: const [
                  DropdownMenuItem(value: 'WEIGHT', child: Text('WEIGHT')),
                  DropdownMenuItem(value: 'QUANTITY', child: Text('QUANTITY')),
                  DropdownMenuItem(value: 'LITRE', child: Text('LITRE')),
                  DropdownMenuItem(value: 'METER', child: Text('METER')),
                  DropdownMenuItem(value: 'GM', child: Text('GM')),
                  DropdownMenuItem(value: 'KG', child: Text('KG')),
                  DropdownMenuItem(value: 'ML', child: Text('ML')),
                  DropdownMenuItem(value: 'PIECE', child: Text('PIECE')),
                  DropdownMenuItem(value: 'BOX', child: Text('BOX')),
                  DropdownMenuItem(value: 'PACK', child: Text('PACK')),
                ],
                onChanged: (v) {
                  if (v != null) controller.defaultUnit.value = v;
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order & Buffer Limits',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => TextFormField(
                      initialValue: controller.orderLimit.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Order Limit',
                        hintText: '0 for no limit',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(),
                      onChanged: (v) => controller.orderLimit.value = v,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => TextFormField(
                      initialValue: controller.bufferLimit.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Buffer Limit',
                        hintText: '0 for none',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(),
                      onChanged: (v) => controller.bufferLimit.value = v,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductStepTwo extends StatelessWidget {
  const _ProductStepTwo();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductFormController>();

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ContentCard(
            title: 'Tax & Status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  return TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: controller.hsnCode.value,
                    ),
                    decoration: AppInputDecoration.standard(
                      labelText: 'HSN Code *',
                      hintText: 'Tap to select HSN',
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final selected = await Get.toNamed(
                        AppRoutes.hsnCodeList,
                        arguments: {'pick': true},
                      );
                      if (selected is String && selected.isNotEmpty) {
                        controller.hsnCode.value = selected;
                      }
                    },
                    validator: (v) {
                      final value = controller.hsnCode.value;
                      if (value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 16),
                Obx(
                  () {
                    if (controller.availableTaxes.isEmpty) {
                      return const Text(
                        'No taxes found. Please create taxes first from Tax Master.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Applicable Taxes *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...controller.availableTaxes.map((tax) {
                          final isSelected =
                              controller.selectedTaxIds.contains(tax.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (v) =>
                                          controller.toggleTaxSelection(
                                        tax.id,
                                        v ?? false,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tax.taxName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${tax.taxCategory} • ${tax.taxSubCategory}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: ValueKey(
                                      'tax-percent-${tax.id}-${controller.taxPercentFor(tax.id)}',
                                    ),
                                    initialValue: controller.taxPercentFor(
                                      tax.id,
                                    ),
                                    decoration: AppInputDecoration.standard(
                                      labelText: 'Tax Percent *',
                                      hintText: 'Enter percent (0-100)',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (v) =>
                                        controller.updateTaxPercentFromInput(
                                      tax.id,
                                      v,
                                    ),
                                    validator: (v) {
                                      if (!controller.selectedTaxIds
                                          .contains(tax.id)) {
                                        return null;
                                      }
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final value = double.tryParse(v.trim());
                                      if (value == null ||
                                          value < 0 ||
                                          value > 100) {
                                        return 'Enter valid percent (0-100)';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile(
                    title: const Text('Published'),
                    subtitle: const Text(
                      'Make this product visible to customers',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: controller.isPublished.value,
                    onChanged: (v) => controller.isPublished.value = v,
                  ),
                ),
                Obx(
                  () => SwitchListTile(
                    title: const Text('In Stock'),
                    subtitle: const Text(
                      'Product is available for purchase',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: controller.inStock.value,
                    onChanged: (v) => controller.inStock.value = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ContentCard(
            title: 'Package Management',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add different package sizes and pricing for this product',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.packages.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No packages added yet.\nAdd at least one package to continue for pack-wise products.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: controller.packages
                        .map(
                          (p) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 4,
                            ),
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(
                              p.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${p.size} ${p.unit} • Market: ${p.marketPrice}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  controller.removePackage(p.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _showAddPackageDialog(controller),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Package'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Format for retail prices: NewPrice, RegularPrice, HomePrice\nExample: 100.00, 95.00, 90.00',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPackageDialog(
    ProductFormController controller,
  ) async {
    final descController = TextEditingController();
    final sizeController = TextEditingController();
    String selectedUnit = 'KG';
    final marketPriceController = TextEditingController();
    final retailPricesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Package'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Package Description *',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Package Size *',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final value = double.tryParse(v.trim());
                          if (value == null || value <= 0) {
                            return 'Enter valid size';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'KG', child: Text('KG')),
                          DropdownMenuItem(value: 'GM', child: Text('GM')),
                          DropdownMenuItem(value: 'L', child: Text('L')),
                          DropdownMenuItem(value: 'ML', child: Text('ML')),
                          DropdownMenuItem(value: 'PCS', child: Text('PCS')),
                          DropdownMenuItem(value: 'BOX', child: Text('BOX')),
                          DropdownMenuItem(value: 'PACK', child: Text('PACK')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedUnit = v;
                            });
                          }
                        },
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: marketPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Market Price *',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final value = double.tryParse(v.trim());
                          if (value == null || value < 0) {
                            return 'Enter valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: retailPricesController,
                        decoration: const InputDecoration(
                          labelText: 'Retail Prices (Comma Separated)',
                          hintText: '100.00, 95.00, 90.00',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final id = 'P${DateTime.now().millisecondsSinceEpoch}';
      controller.addPackage(
        PackageUiModel(
          id: id,
          description: descController.text.trim(),
          size: double.parse(sizeController.text.trim()),
          unit: selectedUnit,
          marketPrice: double.parse(marketPriceController.text.trim()),
          retailPricesRaw: retailPricesController.text.trim(),
        ),
      );
    }
  }
}


