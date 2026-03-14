import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_form_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductFormScreen extends StatelessWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

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
                              if (ok) Get.back(result: true);
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
            Obx(
              () => TextFormField(
                initialValue: controller.ctypeId.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Cart Type *',
                  hintText: 'e.g. Vegetables & Fruits',
                ),
                onChanged: (v) => controller.ctypeId.value = v,
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
              () => TextFormField(
                initialValue: controller.defaultUnit.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Unit Type',
                  hintText: 'WEIGHT, QUANTITY, LITRE, METER',
                ),
                onChanged: (v) => controller.defaultUnit.value = v,
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
                      final selected =
                          await Get.toNamed(AppRoutes.hsnCodeList);
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
                  () => TextFormField(
                    initialValue: controller.gstPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'GST Percent *',
                      hintText: 'e.g. 5, 12, 18',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => controller.gstPercent.value = v,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final value = double.tryParse(v.trim());
                      if (value == null || value < 0 || value > 100) {
                        return 'Enter valid percent (0-100)';
                      }
                      return null;
                    },
                  ),
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
    final unitController = TextEditingController(text: 'KG');
    final marketPriceController = TextEditingController();
    final retailPricesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (ctx) {
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
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                    ),
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

    if (result == true) {
      final id = 'P${DateTime.now().millisecondsSinceEpoch}';
      controller.addPackage(
        PackageUiModel(
          id: id,
          description: descController.text.trim(),
          size: double.parse(sizeController.text.trim()),
          unit: unitController.text.trim(),
          marketPrice: double.parse(marketPriceController.text.trim()),
          retailPricesRaw: retailPricesController.text.trim(),
        ),
      );
    }
  }
}


