import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/hsn_code_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class HsnCodeFormScreen extends StatelessWidget {
  final int? hsnId;

  const HsnCodeFormScreen({super.key, this.hsnId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HsnCodeFormController(hsnId: hsnId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit HSN Code' : 'Add HSN Code',
        subtitle: 'HSN master',
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
                  'Loading HSN code...',
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
                    title: 'HSN Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () => TextFormField(
                            initialValue: controller.code.value,
                            decoration: AppInputDecoration.standard(
                              labelText: 'HSN Code *',
                              hintText: 'Enter HSN code',
                            ),
                            onChanged: (v) => controller.code.value = v,
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
        );
      }),
    );
  }
}

