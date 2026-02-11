import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/issue_to_production_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class IssueToProductionScreen extends StatelessWidget {
  const IssueToProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IssueToProductionController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Issue to Production',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Select finished product, quantity to produce and materials to issue based on BOM.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
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
                  'Loading products...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth - 32;

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _IssueHeaderCard(controller: controller),
                              const SizedBox(height: 16),
                              _IssueMaterialsCard(controller: controller),
                            ],
                          ),
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
                          label: 'Save as Draft',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.saveDraft(),
                        ),
                        ActionButton(
                          label: 'Issue Now',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.confirmIssue(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

class _IssueHeaderCard extends StatelessWidget {
  final IssueToProductionController controller;

  const _IssueHeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Production Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _ProductDropdown(
              label: 'Finished Product *',
              initialValue: controller.finishedProduct.value,
              items: controller.products,
              onChanged: (product) => controller.setFinishedProduct(product),
              validator: (value) {
                if (value == null) {
                  return 'Please select a finished product';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.quantityToProduce.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Quantity to Produce *',
                hintText: 'e.g., 100.0',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
              onChanged: controller.setQuantityToProduce,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.remarks.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Remarks',
                hintText: 'Optional notes...',
              ),
              maxLines: 3,
              onChanged: controller.setRemarks,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueMaterialsCard extends StatelessWidget {
  final IssueToProductionController controller;

  const _IssueMaterialsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Materials to Issue',
      child: Obx(() {
        if (controller.materials.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_outlined,
            message: 'No materials added yet.',
            actionLabel: 'Add Material',
            onAction: () => controller.addMaterialRow(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.materials.length,
              itemBuilder: (context, index) {
                return _IssueMaterialRow(
                  controller: controller,
                  index: index,
                  row: controller.materials[index],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => controller.addMaterialRow(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Material'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _IssueMaterialRow extends StatelessWidget {
  final IssueToProductionController controller;
  final int index;
  final IssueMaterialRow row;

  const _IssueMaterialRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Material ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.redAccent,
                onPressed: () => controller.removeMaterialRow(index),
                tooltip: 'Remove',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => _ProductDropdown(
              label: 'Raw Material *',
              initialValue: row.rawMaterial.value,
              items: controller.products
                  .where((p) =>
                      controller.finishedProduct.value == null ||
                      p.id != controller.finishedProduct.value!.id)
                  .toList(),
              onChanged: (product) => row.rawMaterial.value = product,
              validator: (value) {
                if (value == null) {
                  return 'Please select raw material';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => TextFormField(
                    initialValue: row.quantity.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Issue Quantity *',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                    onChanged: (value) => row.quantity.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: row.unitType.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Unit *',
                    ),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'KG',
                        child: Text('KG', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'PCS',
                        child: Text('PCS', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'LTR',
                        child: Text('LTR', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'MTR',
                        child: Text('MTR', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) row.unitType.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDropdown extends StatelessWidget {
  final String label;
  final Product? initialValue;
  final List<Product> items;
  final ValueChanged<Product?>? onChanged;
  final String? Function(Product?)? validator;

  const _ProductDropdown({
    required this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Product>(
      value: initialValue,
      decoration: AppInputDecoration.standard(labelText: label),
      items: items
          .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }
}
