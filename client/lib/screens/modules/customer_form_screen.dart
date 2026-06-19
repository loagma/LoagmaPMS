import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/customer_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CustomerFormScreen extends StatelessWidget {
  final int? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerFormController(customerId: customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Customer' : 'Add Customer',
        subtitle: 'Loagma',
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
                Text('Loading...', style: TextStyle(color: AppColors.textMuted)),
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BasicInfoCard(controller: controller),
                      const SizedBox(height: 10),
                      _ContactCard(controller: controller),
                      const SizedBox(height: 10),
                      _AddressCard(controller: controller),
                      const SizedBox(height: 10),
                      _TaxCard(controller: controller),
                      const SizedBox(height: 10),
                      _NotesCard(controller: controller),
                    ],
                  ),
                ),
              ),
              Obx(() => ActionButtonBar(
                    buttons: [
                      ActionButton(
                        label: 'Cancel',
                        onPressed: controller.isSaving.value ? null : () => Get.back(),
                      ),
                      ActionButton(
                        label: controller.isEditMode ? 'Update' : 'Save',
                        isPrimary: true,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.isSaving.value ? null : controller.save,
                      ),
                    ],
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  final CustomerFormController controller;
  const _BasicInfoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Basic Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => DropdownButtonFormField<String>(
                value: controller.status.value,
                decoration: AppInputDecoration.standard(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
                ],
                onChanged: (v) { if (v != null) controller.status.value = v; },
              )),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.nameController,
            decoration: AppInputDecoration.standard(
              labelText: 'Customer Name *',
              hintText: 'Full name or company name',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.shopNameController,
            decoration: AppInputDecoration.standard(
              labelText: 'Shop Name',
              hintText: 'Business or shop name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final CustomerFormController controller;
  const _ContactCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.contactController,
                  decoration: AppInputDecoration.standard(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller.altPhoneController,
                  decoration: AppInputDecoration.standard(labelText: 'Alt. Phone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.emailController,
            decoration: AppInputDecoration.standard(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerFormController controller;
  const _AddressCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.addressController,
            decoration: AppInputDecoration.standard(
              labelText: 'Address',
              hintText: 'Street, Building, Landmark',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      controller: controller.pincodeController,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Pincode',
                        suffixIcon: controller.isPincodeLoading.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller.cityController,
                  decoration: AppInputDecoration.standard(labelText: 'City'),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.stateController,
                  decoration: AppInputDecoration.standard(labelText: 'State'),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller.countryController,
                  decoration: AppInputDecoration.standard(labelText: 'Country'),
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final CustomerFormController controller;
  const _TaxCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Tax & Registration',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller.gstNoController,
              decoration: AppInputDecoration.standard(labelText: 'GST No'),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller.panNoController,
              decoration: AppInputDecoration.standard(labelText: 'PAN No'),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final CustomerFormController controller;
  const _NotesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Notes',
      child: TextFormField(
        controller: controller.notesController,
        decoration: AppInputDecoration.standard(
          labelText: 'Notes',
          hintText: 'Optional notes about this customer...',
        ),
        maxLines: 3,
      ),
    );
  }
}
