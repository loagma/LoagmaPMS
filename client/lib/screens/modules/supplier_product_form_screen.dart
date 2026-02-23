import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_product_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SupplierProductFormScreen extends StatelessWidget {
  const SupplierProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final controller = Get.put(
      SupplierProductFormController(supplierProductId: args?['id'] as int?),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditMode
              ? 'Edit Supplier Product'
              : 'Add Supplier Product',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBasicInfoCard(controller),
              const SizedBox(height: 16),
              _buildPricingCard(controller),
              const SizedBox(height: 16),
              _buildAdditionalInfoCard(controller),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isSaving.value
              ? null
              : controller.saveSupplierProduct,
          backgroundColor: AppColors.primary,
          icon: controller.isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(controller.isSaving.value ? 'Saving...' : 'Save'),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Basic Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => DropdownButtonFormField<int>(
              value: controller.selectedSupplierId.value,
              decoration: AppInputDecoration.standard(labelText: 'Supplier *'),
              items: controller.suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier.id,
                  child: Text(supplier.supplierName),
                );
              }).toList(),
              validator: (value) => value == null ? 'Required' : null,
              onChanged: (value) {
                if (value != null) controller.selectedSupplierId.value = value;
              },
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButtonFormField<int>(
              value: controller.selectedProductId.value,
              decoration: AppInputDecoration.standard(labelText: 'Product *'),
              items: controller.products.map((product) {
                return DropdownMenuItem(
                  value: product.id,
                  child: Text(product.name),
                );
              }).toList(),
              validator: (value) => value == null ? 'Required' : null,
              onChanged: (value) {
                if (value != null) controller.selectedProductId.value = value;
              },
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.supplierSku.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Supplier SKU',
                hintText: 'ABC-123',
              ),
              onChanged: (value) => controller.supplierSku.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.supplierProductName.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Supplier Product Name',
                hintText: 'Product name as per supplier',
              ),
              onChanged: (value) =>
                  controller.supplierProductName.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.description.value,
              decoration: AppInputDecoration.standard(labelText: 'Description'),
              maxLines: 3,
              onChanged: (value) => controller.description.value = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Pricing & Packaging',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.packSize.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Pack Size',
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => controller.packSize.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.packUnit.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Pack Unit',
                      hintText: 'kg',
                    ),
                    onChanged: (value) => controller.packUnit.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.minOrderQty.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Min Order Quantity',
                hintText: '10',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => controller.minOrderQty.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.price.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Price *',
                      hintText: '100.00',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onChanged: (value) => controller.price.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.currency.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Currency',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'INR', child: Text('INR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.currency.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.taxPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Tax %',
                      hintText: '18',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => controller.taxPercent.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.discountPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Discount %',
                      hintText: '5',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        controller.discountPercent.value = value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Additional Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TextFormField(
              initialValue: controller.leadTimeDays.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Lead Time (Days)',
                hintText: '7',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => controller.leadTimeDays.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.notes.value,
              decoration: AppInputDecoration.standard(labelText: 'Notes'),
              maxLines: 3,
              onChanged: (value) => controller.notes.value = value,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Preferred Product',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              value: controller.isPreferred.value,
              onChanged: (value) => controller.isPreferred.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              value: controller.isActive.value,
              onChanged: (value) => controller.isActive.value = value,
            ),
          ),
        ],
      ),
    );
  }
}
