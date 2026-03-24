import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_package_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductPackageFormScreen extends StatelessWidget {
  final int? productId;
  final int? packageId;

  const ProductPackageFormScreen({
    super.key,
    this.productId,
    this.packageId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ProductPackageFormController(
        productId: productId,
        packageId: packageId,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Package' : 'Add Package',
        subtitle: 'Pack size configuration',
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
                  'Loading package...',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    title: 'Package Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () => TextFormField(
                            initialValue: controller.productId?.toString() ?? controller.productIdInput.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Product ID *',
                              hintText: 'Enter product id',
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: controller.productId != null,
                            onChanged: (v) => controller.productIdInput.value = v,
                            validator: (v) {
                              if (controller.productId != null) {
                                return null;
                              }
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final value = int.tryParse(v.trim());
                              if (value == null || value <= 0) {
                                return 'Enter valid product id';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => TextFormField(
                            initialValue: controller.description.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Package Description *',
                              hintText: 'Enter package description',
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
                            initialValue: controller.packSize.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Pack Size *',
                              hintText: 'e.g. 1.0',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => controller.packSize.value = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final value = double.tryParse(v.trim());
                              if (value == null || value <= 0) {
                                return 'Enter valid size';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            value: controller.unit.value,
                            decoration:
                                AppInputDecoration.standard(labelText: 'Unit *'),
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
                              if (v != null) controller.unit.value = v;
                            },
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
                            initialValue: controller.marketPrice.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Market Price *',
                              hintText: 'Enter market price',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => controller.marketPrice.value = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final value = double.tryParse(v.trim());
                              if (value == null || value < 0) {
                                return 'Enter valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => TextFormField(
                            initialValue: controller.retailPrices.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Retail Prices (Comma Separated)',
                              hintText: '100.00, 95.00, 90.00',
                            ),
                            onChanged: (v) => controller.retailPrices.value = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final parts = v.split(',').map((e) => e.trim()).toList();
                              if (parts.length != 3) {
                                return 'Enter 3 values: New, Regular, Home';
                              }
                              final valid = parts.every((e) => double.tryParse(e) != null);
                              if (!valid) {
                                return 'Retail prices must be numeric';
                              }
                              return null;
                            },
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
        );
      }),
    );
  }
}

