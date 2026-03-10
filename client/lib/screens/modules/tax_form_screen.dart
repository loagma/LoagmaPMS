import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/tax_constants.dart';
import '../../controllers/tax_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class TaxFormScreen extends StatelessWidget {
  final int? taxId;

  const TaxFormScreen({super.key, this.taxId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaxFormController(taxId: taxId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Tax' : 'Add Tax',
        subtitle: 'Tax definitions',
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
                  'Loading tax...',
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
                    title: 'Tax Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(() {
                          final value = controller.taxCategory.value;
                          final list = List<String>.from(taxCategories);
                          if (value.isNotEmpty && !list.contains(value)) {
                            list.insert(0, value);
                          }
                          final valid = value.isNotEmpty && list.contains(value);
                          return DropdownButtonFormField<String>(
                            value: valid ? value : null,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Tax Category *',
                              hintText: 'Select category',
                            ),
                            isExpanded: true,
                            items: list
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: controller.onCategoryChanged,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          );
                        }),
                        const SizedBox(height: 16),
                        Obx(() {
                          final options = List<String>.from(
                              controller.subCategoryOptions);
                          final value = controller.taxSubCategory.value;
                          if (value.isNotEmpty && !options.contains(value)) {
                            options.insert(0, value);
                          }
                          final valid =
                              value.isNotEmpty && options.contains(value);
                          return DropdownButtonFormField<String>(
                            value: valid ? value : options.first,
                            decoration: AppInputDecoration.standard(
                              labelText: 'Tax Sub Category *',
                              hintText: 'Select subcategory',
                            ),
                            isExpanded: true,
                            items: options
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                controller.taxSubCategory.value = v;
                              }
                            },
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          );
                        }),
                        const SizedBox(height: 16),
                        Obx(() => TextFormField(
                              initialValue: controller.taxName.value,
                              decoration: AppInputDecoration.standard(
                                labelText: 'Tax Name *',
                                hintText: 'e.g. State GST',
                              ),
                              onChanged: (v) => controller.taxName.value = v,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            )),
                        const SizedBox(height: 16),
                        Obx(() => CheckboxListTile(
                              title: const Text('Active'),
                              subtitle: const Text(
                                'Inactive taxes are hidden from product assignment',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: controller.isActive.value,
                              onChanged: (v) {
                                if (v != null) {
                                  controller.isActive.value = v;
                                }
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
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
