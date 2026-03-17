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
                          () => TextFormField(
                            initialValue: controller.unit.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Unit *',
                              hintText: 'e.g. KG, PCS',
                            ),
                            onChanged: (v) => controller.unit.value = v,
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
                            initialValue: controller.price.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Price',
                              hintText: 'Optional price for this pack',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => controller.price.value = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return null;
                              }
                              final value = double.tryParse(v.trim());
                              if (value == null || value < 0) {
                                return 'Enter valid price';
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

