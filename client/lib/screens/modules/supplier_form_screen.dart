import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_form_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SupplierFormScreen extends StatelessWidget {
  final int? supplierId;

  const SupplierFormScreen({super.key, this.supplierId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierFormController(supplierId: supplierId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Supplier' : 'Add Supplier',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Create a supplier profile and map supplier products.',
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
                  'Loading supplier...',
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
              final maxWidth = constraints.maxWidth > 700
                  ? 700.0
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
                              _SupplierBasicsCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierContactCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierAddressCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierTaxCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierBankingCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierTermsCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierProductsCard(controller: controller),
                              const SizedBox(height: 16),
                              _SupplierNotesCard(controller: controller),
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
                          label: controller.isEditMode ? 'Update' : 'Save',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.saveSupplier,
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

class _SupplierBasicsCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierBasicsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Supplier Basics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.status.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'SUSPENDED',
                        child: Text('Suspended'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.status.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.supplierName.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Supplier Name *',
                hintText: 'ABC Traders',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
              onChanged: (value) => controller.supplierName.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.shortName.value,
              decoration: AppInputDecoration.standard(labelText: 'Short Name'),
              onChanged: (value) => controller.shortName.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.businessType.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Business Type',
                      hintText: 'Manufacturer / Distributor',
                    ),
                    onChanged: (value) => controller.businessType.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.department.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Department',
                      hintText: 'Food & Beverages',
                    ),
                    onChanged: (value) => controller.department.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Preferred Supplier',
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
        ],
      ),
    );
  }
}

class _SupplierContactCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierContactCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Contact Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.email.value,
                    decoration: AppInputDecoration.standard(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => controller.email.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.phone.value,
                    decoration: AppInputDecoration.standard(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => controller.phone.value = value,
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
                    initialValue: controller.alternatePhone.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Alternate Phone',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) =>
                        controller.alternatePhone.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.website.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Website',
                    ),
                    onChanged: (value) => controller.website.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.contactPerson.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Contact Person',
              ),
              onChanged: (value) => controller.contactPerson.value = value,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.contactPersonDesignation.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Designation',
                    ),
                    onChanged: (value) =>
                        controller.contactPersonDesignation.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.contactPersonEmail.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Contact Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) =>
                        controller.contactPersonEmail.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              initialValue: controller.contactPersonPhone.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Contact Phone',
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => controller.contactPersonPhone.value = value,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierAddressCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierAddressCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => TextFormField(
                    controller: controller.pincodeController,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Pincode *',
                      hintText: '400001',
                      suffixIcon: controller.isLoadingPincode.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ).copyWith(counterText: ''),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (value) {
                      controller.pincode.value = value;
                      if (value.length == 6) {
                        controller.lookupPincode(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Obx(() {
                  if (controller.isLoadingPincode.value) {
                    return Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (controller.areas.isEmpty) {
                    return TextFormField(
                      key: ValueKey('area_text_${controller.area.value}'),
                      initialValue: controller.area.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Area',
                        hintText: 'Enter area name',
                      ),
                      onChanged: (value) => controller.area.value = value,
                    );
                  }

                  return DropdownButtonFormField<String>(
                    key: ValueKey('area_dropdown_${controller.areas.length}'),
                    value: controller.area.value.isEmpty
                        ? null
                        : controller.area.value,
                    decoration: AppInputDecoration.standard(labelText: 'Area'),
                    isExpanded: true,
                    items: controller.areas
                        .map(
                          (area) => DropdownMenuItem(
                            value: area,
                            child: Text(area, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.area.value = value;
                    },
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              key: ValueKey('address_${controller.addressLine1.value}'),
              initialValue: controller.addressLine1.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Address Line',
                hintText: 'Building, Street, Landmark',
              ),
              maxLines: 2,
              onChanged: (value) => controller.addressLine1.value = value,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    key: ValueKey('city_${controller.city.value}'),
                    initialValue: controller.city.value,
                    decoration: AppInputDecoration.standard(labelText: 'City'),
                    enabled: controller.city.value.isEmpty,
                    onChanged: (value) => controller.city.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    key: ValueKey('state_${controller.state.value}'),
                    initialValue: controller.state.value,
                    decoration: AppInputDecoration.standard(labelText: 'State'),
                    enabled: controller.state.value.isEmpty,
                    onChanged: (value) => controller.state.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              key: ValueKey('country_${controller.country.value}'),
              initialValue: controller.country.value,
              decoration: AppInputDecoration.standard(labelText: 'Country'),
              enabled: controller.country.value.isEmpty,
              onChanged: (value) => controller.country.value = value,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTaxCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierTaxCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Tax & Registration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.gstNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'GST No',
                    ),
                    onChanged: (value) => controller.gstNo.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.panNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'PAN No',
                    ),
                    onChanged: (value) => controller.panNo.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.tanNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'TAN No',
                    ),
                    onChanged: (value) => controller.tanNo.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.cinNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'CIN No',
                    ),
                    onChanged: (value) => controller.cinNo.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.vatNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'VAT No',
                    ),
                    onChanged: (value) => controller.vatNo.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.registrationNo.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Registration No',
                    ),
                    onChanged: (value) =>
                        controller.registrationNo.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              initialValue: controller.fssaiNo.value,
              decoration: AppInputDecoration.standard(labelText: 'FSSAI No'),
              onChanged: (value) => controller.fssaiNo.value = value,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierBankingCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierBankingCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Banking Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.bankName.value,
                    decoration: AppInputDecoration.standard(labelText: 'Bank'),
                    onChanged: (value) => controller.bankName.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.bankBranch.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Branch',
                    ),
                    onChanged: (value) => controller.bankBranch.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              initialValue: controller.bankAccountName.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Account Name',
              ),
              onChanged: (value) => controller.bankAccountName.value = value,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              initialValue: controller.bankAccountNumber.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Account Number',
              ),
              onChanged: (value) => controller.bankAccountNumber.value = value,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.ifscCode.value,
                    decoration: AppInputDecoration.standard(labelText: 'IFSC'),
                    onChanged: (value) => controller.ifscCode.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.swiftCode.value,
                    decoration: AppInputDecoration.standard(labelText: 'SWIFT'),
                    onChanged: (value) => controller.swiftCode.value = value,
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

class _SupplierTermsCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierTermsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Terms & Rating',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.paymentTermsDays.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Payment Terms (Days)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        controller.paymentTermsDays.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: controller.creditLimit.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Credit Limit',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => controller.creditLimit.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              initialValue: controller.rating.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Rating (0 - 5)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => controller.rating.value = value,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierProductsCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierProductsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Supplier Products',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.supplierProducts.length,
              itemBuilder: (context, index) {
                return _SupplierProductRow(
                  controller: controller,
                  index: index,
                  row: controller.supplierProducts[index],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.addSupplierProduct,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Supplier Product'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SupplierProductRow extends StatelessWidget {
  final SupplierFormController controller;
  final int index;
  final SupplierProductRow row;

  const _SupplierProductRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final excludeIds = controller.supplierProducts
        .where((r) => r != row && r.product.value != null)
        .map((r) => r.product.value!.id);

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
                  'Product ${index + 1}',
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
                onPressed: () => controller.removeSupplierProduct(index),
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
              key: ValueKey('supplier_product_$index'),
              label: 'Product *',
              initialValue: row.product.value,
              items: controller.products,
              excludeIds: excludeIds.toSet(),
              controller: controller,
              onChanged: (product) => row.product.value = product,
              validator: (value) {
                if (value == null) return 'Select product';
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.supplierSku.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Supplier SKU',
                    ),
                    onChanged: (value) => row.supplierSku.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.supplierProductName.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Supplier Product Name',
                    ),
                    onChanged: (value) => row.supplierProductName.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.packSize.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Pack Size',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => row.packSize.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.packUnit.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Pack Unit',
                    ),
                    onChanged: (value) => row.packUnit.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.minOrderQty.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Min Order Qty',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => row.minOrderQty.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.leadTimeDays.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Lead Time (Days)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => row.leadTimeDays.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.price.value,
                    decoration: AppInputDecoration.standard(labelText: 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => row.price.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.currency.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Currency',
                    ),
                    onChanged: (value) => row.currency.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.taxPercent.value,
                    decoration: AppInputDecoration.standard(labelText: 'Tax %'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => row.taxPercent.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    initialValue: row.discountPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Discount %',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => row.discountPercent.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Preferred',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    value: row.isPreferred.value,
                    onChanged: (value) => row.isPreferred.value = value,
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    value: row.isActive.value,
                    onChanged: (value) => row.isActive.value = value,
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

class _SupplierNotesCard extends StatelessWidget {
  final SupplierFormController controller;

  const _SupplierNotesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Notes',
      child: Obx(
        () => TextFormField(
          initialValue: controller.notes.value,
          decoration: AppInputDecoration.standard(
            labelText: 'Notes',
            hintText: 'Optional notes...',
          ),
          maxLines: 3,
          onChanged: (value) => controller.notes.value = value,
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatefulWidget {
  final String label;
  final Product? initialValue;
  final List<Product> items;
  final Set<int> excludeIds;
  final SupplierFormController controller;
  final ValueChanged<Product?>? onChanged;
  final String? Function(Product?)? validator;

  const _ProductDropdown({
    super.key,
    required this.label,
    required this.initialValue,
    required this.items,
    this.excludeIds = const {},
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  final TextEditingController _searchController = TextEditingController();
  Product? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    if (_selectedValue != null) _searchController.text = _selectedValue!.name;
  }

  @override
  void didUpdateWidget(_ProductDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selectedValue = widget.initialValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_selectedValue != null) {
            _searchController.text = _selectedValue!.name;
          } else {
            _searchController.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (ctx) => _SearchProductDialog(
        controller: widget.controller,
        currentSelection: _selectedValue,
        items: widget.items,
        excludeIds: widget.excludeIds,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedValue = result;
        _searchController.text = result.name;
      });
      widget.onChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Product>(
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: widget.label,
                hintText: 'Tap to search...',
                suffixIcon: SizedBox(
                  width: 48,
                  child: _selectedValue != null && widget.onChanged != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _selectedValue = null;
                                _searchController.clear();
                              });
                              widget.onChanged?.call(null);
                              formFieldState.didChange(null);
                            }
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onChanged == null
                              ? null
                              : _showSearchDialog,
                        ),
                ),
              ),
              readOnly: true,
              onTap: widget.onChanged == null ? null : _showSearchDialog,
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  formFieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchProductDialog extends StatefulWidget {
  final SupplierFormController controller;
  final Product? currentSelection;
  final List<Product> items;
  final Set<int> excludeIds;

  const _SearchProductDialog({
    required this.controller,
    required this.items,
    this.excludeIds = const {},
    this.currentSelection,
  });

  @override
  State<_SearchProductDialog> createState() => _SearchProductDialogState();
}

class _SearchProductDialogState extends State<_SearchProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.items.take(50).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredProducts = widget.items.take(50).toList());
      return;
    }
    if (query.length < 2) return;
    setState(() => _isSearching = true);
    try {
      await widget.controller.searchProducts(query);
      setState(() {
        _filteredProducts = widget.controller.products
            .where((p) => !widget.excludeIds.contains(p.id))
            .toList();
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: 'Search by name or ID',
                hintText: 'Type at least 2 characters...',
                prefixIcon: const Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Start typing to search'
                              : 'No products found',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, i) {
                          final product = _filteredProducts[i];
                          final isSelected =
                              widget.currentSelection?.id == product.id;
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text('ID: ${product.id}'),
                            selected: isSelected,
                            onTap: () => Navigator.pop(context, product),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
