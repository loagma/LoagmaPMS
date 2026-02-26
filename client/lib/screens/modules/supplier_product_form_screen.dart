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
      SupplierProductFormController(
        supplierProductId: args?['id'] as int?,
        presetSupplierId: args?['supplier_id'] as int?,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditMode
              ? 'Edit Supplier Product'
              : 'Assign Product to Supplier',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final form = Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBasicInfoCard(controller),
              const SizedBox(height: 80),
            ],
          ),
        );

        return Stack(
          children: [
            form,
            if (controller.isSaving.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
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
      title: 'Assign Product',
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

}
