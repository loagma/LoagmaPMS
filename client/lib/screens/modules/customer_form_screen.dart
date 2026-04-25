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
          Obx(() => TextFormField(
                key: ValueKey('name_${controller.name.value.isEmpty}'),
                initialValue: controller.name.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Customer Name *',
                  hintText: 'Full name or company name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                onChanged: (v) => controller.name.value = v,
              )),
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
                child: Obx(() => TextFormField(
                      key: ValueKey('phone_${controller.contactNumber.value.isEmpty}'),
                      initialValue: controller.contactNumber.value,
                      decoration: AppInputDecoration.standard(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      onChanged: (v) => controller.contactNumber.value = v,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('alt_phone_${controller.alternatePhone.value.isEmpty}'),
                      initialValue: controller.alternatePhone.value,
                      decoration: AppInputDecoration.standard(labelText: 'Alt. Phone'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      onChanged: (v) => controller.alternatePhone.value = v,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => TextFormField(
                key: ValueKey('email_${controller.email.value.isEmpty}'),
                initialValue: controller.email.value,
                decoration: AppInputDecoration.standard(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => controller.email.value = v,
              )),
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
          Obx(() => TextFormField(
                key: ValueKey('addr_${controller.addressLine1.value.isEmpty}'),
                initialValue: controller.addressLine1.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Address',
                  hintText: 'Street, Building, Landmark',
                ),
                maxLines: 2,
                onChanged: (v) => controller.addressLine1.value = v,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('pincode_${controller.pincode.value.isEmpty}'),
                      initialValue: controller.pincode.value,
                      decoration: AppInputDecoration.standard(labelText: 'Pincode'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      onChanged: (v) => controller.pincode.value = v,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('city_${controller.city.value.isEmpty}'),
                      initialValue: controller.city.value,
                      decoration: AppInputDecoration.standard(labelText: 'City'),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => controller.city.value = v,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('state_${controller.state.value.isEmpty}'),
                      initialValue: controller.state.value,
                      decoration: AppInputDecoration.standard(labelText: 'State'),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => controller.state.value = v,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('country_${controller.country.value.isEmpty}'),
                      initialValue: controller.country.value,
                      decoration: AppInputDecoration.standard(labelText: 'Country'),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => controller.country.value = v,
                    )),
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
            child: Obx(() => TextFormField(
                  key: ValueKey('gst_${controller.gstNo.value.isEmpty}'),
                  initialValue: controller.gstNo.value,
                  decoration: AppInputDecoration.standard(labelText: 'GST No'),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (v) => controller.gstNo.value = v,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => TextFormField(
                  key: ValueKey('pan_${controller.panNo.value.isEmpty}'),
                  initialValue: controller.panNo.value,
                  decoration: AppInputDecoration.standard(labelText: 'PAN No'),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (v) => controller.panNo.value = v,
                )),
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
      child: Obx(() => TextFormField(
            key: ValueKey('notes_${controller.notes.value.isEmpty}'),
            initialValue: controller.notes.value,
            decoration: AppInputDecoration.standard(
              labelText: 'Notes',
              hintText: 'Optional notes about this customer...',
            ),
            maxLines: 3,
            onChanged: (v) => controller.notes.value = v,
          )),
    );
  }
}
