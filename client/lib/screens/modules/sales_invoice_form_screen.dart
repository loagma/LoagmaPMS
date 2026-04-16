import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_invoice_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

InputDecoration _inputDecoration({
  required String labelText,
  String? hintText,
  Widget? suffixIcon,
}) {
  return AppInputDecoration.standard(
    labelText: labelText,
    hintText: hintText,
    suffixIcon: suffixIcon,
  ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always);
}

Future<void> _pickDate(
  BuildContext context, {
  required String currentValue,
  required ValueChanged<String> onPicked,
}) async {
  DateTime initialDate = DateTime.now();
  final parsed = DateTime.tryParse(currentValue.trim());
  if (parsed != null) initialDate = parsed;

  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked == null) return;
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  onPicked('${picked.year}-$m-$d');
}

class SalesInvoiceFormScreen extends StatelessWidget {
  final int? invoiceId;
  final bool startInViewOnly;

  const SalesInvoiceFormScreen({
    super.key,
    this.invoiceId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SalesInvoiceFormController(
        invoiceId: invoiceId,
        startInViewOnly: startInViewOnly,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Sales Invoice' : 'Create Sales Invoice',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final canEdit =
                controller.viewOnly.value &&
                controller.invoiceStatus.value == 'DRAFT';
            if (!canEdit) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => controller.viewOnly.value = false,
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final readOnly = controller.isReadOnly;

        return Form(
          key: controller.formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ContentCard(
                        title: 'Invoice Header',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => TextFormField(
                                      initialValue: controller.invoiceNo.value,
                                      readOnly: readOnly,
                                      decoration: _inputDecoration(
                                        labelText: 'Invoice No *',
                                      ),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? 'Required'
                                          : null,
                                      onChanged: (v) =>
                                          controller.invoiceNo.value = v,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        controller.orderId.value?.toString() ??
                                        '',
                                    readOnly: readOnly,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _inputDecoration(
                                      labelText: 'Order ID *',
                                    ),
                                    validator: (v) => (v ?? '').trim().isEmpty
                                        ? 'Required'
                                        : null,
                                    onChanged: (v) => controller.orderId.value =
                                        int.tryParse(v.trim()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        controller.customerUserId.value
                                            ?.toString() ??
                                        '',
                                    readOnly: readOnly,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _inputDecoration(
                                      labelText: 'Customer User ID',
                                    ),
                                    onChanged: (v) =>
                                        controller.customerUserId.value =
                                            int.tryParse(v.trim()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(
                                    () => TextFormField(
                                      controller: TextEditingController(
                                        text: controller.invoiceDate.value,
                                      ),
                                      readOnly: true,
                                      decoration: _inputDecoration(
                                        labelText: 'Invoice Date *',
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.calendar_today_rounded,
                                          ),
                                          onPressed: readOnly
                                              ? null
                                              : () => _pickDate(
                                                  context,
                                                  currentValue: controller
                                                      .invoiceDate
                                                      .value,
                                                  onPicked: (v) =>
                                                      controller
                                                              .invoiceDate
                                                              .value =
                                                          v,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => TextFormField(
                                      controller: TextEditingController(
                                        text: controller.dueDate.value,
                                      ),
                                      readOnly: true,
                                      decoration: _inputDecoration(
                                        labelText: 'Due Date',
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.calendar_today_rounded,
                                          ),
                                          onPressed: readOnly
                                              ? null
                                              : () => _pickDate(
                                                  context,
                                                  currentValue:
                                                      controller.dueDate.value,
                                                  onPicked: (v) =>
                                                      controller.dueDate.value =
                                                          v,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(
                                    () => DropdownButtonFormField<String>(
                                      value: controller.invoiceStatus.value,
                                      decoration: _inputDecoration(
                                        labelText: 'Invoice Status',
                                      ),
                                      items:
                                          const ['DRAFT', 'ISSUED', 'CANCELLED']
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(s),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: readOnly
                                          ? null
                                          : (v) =>
                                                controller.invoiceStatus.value =
                                                    v ?? 'DRAFT',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.paymentStatus.value,
                                decoration: _inputDecoration(
                                  labelText: 'Payment Status',
                                ),
                                items: const ['PENDING', 'PARTIAL', 'PAID']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: readOnly
                                    ? null
                                    : (v) => controller.paymentStatus.value =
                                          v ?? 'PENDING',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ContentCard(
                        title: 'Totals',
                        child: Column(
                          children: [
                            _numField(
                              'Subtotal *',
                              controller.subtotal,
                              readOnly,
                            ),
                            const SizedBox(height: 6),
                            _numField(
                              'Discount',
                              controller.discountTotal,
                              readOnly,
                            ),
                            const SizedBox(height: 6),
                            _numField(
                              'Delivery Charge',
                              controller.deliveryCharge,
                              readOnly,
                            ),
                            const SizedBox(height: 6),
                            _numField('Tax', controller.taxTotal, readOnly),
                            const SizedBox(height: 6),
                            _numField(
                              'Grand Total *',
                              controller.grandTotal,
                              readOnly,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: controller.notes.value,
                              readOnly: readOnly,
                              decoration: _inputDecoration(labelText: 'Notes'),
                              maxLines: 2,
                              onChanged: (v) => controller.notes.value = v,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => ActionButtonBar(
                  buttons: [
                    ActionButton(
                      label: readOnly ? 'Back' : 'Cancel',
                      onPressed: controller.isSaving.value
                          ? null
                          : () => Get.back(),
                    ),
                    if (!readOnly)
                      ActionButton(
                        label: 'Save',
                        isPrimary: true,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.save,
                      )
                    else if (controller.invoiceStatus.value == 'DRAFT')
                      ActionButton(
                        label: 'Edit Draft',
                        isPrimary: true,
                        onPressed: () => controller.viewOnly.value = false,
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

  Widget _numField(String label, RxString value, bool readOnly) {
    return Obx(
      () => TextFormField(
        initialValue: value.value,
        readOnly: readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _inputDecoration(labelText: label),
        validator: (v) {
          if (label.contains('*') &&
              (double.tryParse((v ?? '').trim()) == null)) {
            return 'Invalid number';
          }
          return null;
        },
        onChanged: (v) => value.value = v,
      ),
    );
  }
}
