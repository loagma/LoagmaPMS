import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/bom_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class BomScreen extends StatelessWidget {
  const BomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BomController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Bill of Materials',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill in the BOM details and add raw materials required for production',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth - 32;
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
                            _BomHeaderCard(controller: controller),
                            const SizedBox(height: 16),
                            _RawMaterialsCard(controller: controller),
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
                        onPressed: controller.isReadOnly
                            ? null
                            : () => Get.back(),
                      ),
                      ActionButton(
                        label: 'Save as Draft',
                        isPrimary: true,
                        isLoading: controller.isSaving.value,
                        onPressed:
                            controller.isReadOnly || controller.isSaving.value
                            ? null
                            : () => controller.saveAsDraft(),
                      ),
                      ActionButton(
                        label: 'Approve BOM',
                        isPrimary: true,
                        backgroundColor: AppColors.primaryDark,
                        isLoading: controller.isSaving.value,
                        onPressed:
                            controller.isReadOnly || controller.isSaving.value
                            ? null
                            : () => controller.approveBom(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BomHeaderCard extends StatelessWidget {
  final BomController controller;

  const _BomHeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'BOM Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _ProductDropdown(
              label: 'Finished Product *',
              initialValue: controller.finishedProduct.value,
              items: controller.finishedProducts,
              onChanged: controller.isReadOnly
                  ? null
                  : (product) => controller.setFinishedProduct(product),
              validator: (value) {
                if (value == null) {
                  return 'Please select a finished product';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !controller.isReadOnly,
            initialValue: controller.bomVersion.value,
            decoration: AppInputDecoration.standard(
              labelText: 'BOM Version *',
              hintText: 'e.g., v1.0',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter BOM version';
              }
              return null;
            },
            onChanged: (value) => controller.setBomVersion(value),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.status.value,
              decoration: AppInputDecoration.standard(labelText: 'Status *'),
              items: const [
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                DropdownMenuItem(value: 'LOCKED', child: Text('Locked')),
              ],
              onChanged: controller.isReadOnly
                  ? null
                  : (value) {
                      if (value != null) controller.setStatus(value);
                    },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !controller.isReadOnly,
            initialValue: controller.remarks.value,
            decoration: AppInputDecoration.standard(
              labelText: 'Remarks',
              hintText: 'Optional notes...',
            ),
            maxLines: 3,
            onChanged: (value) => controller.setRemarks(value),
          ),
        ],
      ),
    );
  }
}

class _RawMaterialsCard extends StatelessWidget {
  final BomController controller;

  const _RawMaterialsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Raw Materials',
      titleAction: Obx(
        () => TextButton.icon(
          onPressed: controller.isReadOnly
              ? null
              : () => controller.addRawMaterial(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Material'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ),
      child: Obx(() {
        if (controller.rawMaterials.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No raw materials added yet.',
            actionLabel: 'Add Material',
            onAction: controller.isReadOnly
                ? null
                : () => controller.addRawMaterial(),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.rawMaterials.length,
          itemBuilder: (context, index) {
            return _RawMaterialRow(
              controller: controller,
              index: index,
              row: controller.rawMaterials[index],
            );
          },
        );
      }),
    );
  }
}

class _RawMaterialRow extends StatelessWidget {
  final BomController controller;
  final int index;
  final BomItemRow row;

  const _RawMaterialRow({
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
              if (!controller.isReadOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.redAccent,
                  onPressed: () => controller.removeRawMaterial(index),
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
              items: controller.rawMaterialProducts.where((p) {
                if (controller.finishedProduct.value != null) {
                  return p.id != controller.finishedProduct.value!.id;
                }
                return true;
              }).toList(),
              onChanged: controller.isReadOnly
                  ? null
                  : (product) {
                      row.rawMaterial.value = product;
                      if (product != null && product.defaultUnit != null) {
                        row.unitType.value = product.defaultUnit!;
                      }
                    },
              validator: (value) {
                if (value == null) {
                  return 'Please select a raw material';
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
                child: TextFormField(
                  enabled: !controller.isReadOnly,
                  initialValue: row.quantityPerUnit.value,
                  decoration: AppInputDecoration.standard(
                    labelText: 'Quantity per Unit *',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,3}'),
                    ),
                  ],
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
                  onChanged: (value) => row.quantityPerUnit.value = value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: row.unitType.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Unit *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'KG', child: Text('KG')),
                      DropdownMenuItem(value: 'PCS', child: Text('PCS')),
                      DropdownMenuItem(value: 'LTR', child: Text('LTR')),
                      DropdownMenuItem(value: 'MTR', child: Text('MTR')),
                    ],
                    onChanged: controller.isReadOnly
                        ? null
                        : (value) {
                            if (value != null) row.unitType.value = value;
                          },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !controller.isReadOnly,
            initialValue: row.wastagePercent.value,
            decoration: AppInputDecoration.standard(
              labelText: 'Wastage %',
              hintText: '0',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) => row.wastagePercent.value = value,
          ),
        ],
      ),
    );
  }
}

// Product Dropdown Widget
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
      initialValue: initialValue,
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
