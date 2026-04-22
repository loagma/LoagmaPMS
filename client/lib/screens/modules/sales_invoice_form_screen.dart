import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sales_invoice_form_controller.dart';
import '../../services/report_export_service.dart';
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

const double _fieldGap = 10;
const double _fieldVerticalGap = 6;
const double _sectionGap = 10;

Widget _twoFieldRow({
  required Widget left,
  required Widget right,
}) {
  return Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: _fieldGap),
      Expanded(child: right),
    ],
  );
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

Future<void> _printSalesInvoice(SalesInvoiceFormController controller) async {
  try {
    await ReportExportService.printSalesInvoice(controller);
  } catch (e) {
    Get.snackbar(
      'Print failed',
      'Could not generate sales invoice PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

Future<void> _shareSalesInvoice(SalesInvoiceFormController controller) async {
  try {
    await ReportExportService.shareSalesInvoice(controller);
  } catch (e) {
    Get.snackbar(
      'Share failed',
      'Could not share sales invoice PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
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
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              tooltip: 'Print/PDF',
              onPressed: () async => _printSalesInvoice(controller),
            );
          }),
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Share/Export',
              onPressed: () async => _shareSalesInvoice(controller),
            );
          }),
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
                            _twoFieldRow(
                              left: Obx(
                                () => TextFormField(
                                  initialValue: controller.invoiceNo.value,
                                  readOnly: readOnly,
                                  decoration: _inputDecoration(
                                    labelText: 'Invoice No *',
                                  ),
                                  validator: (v) =>
                                      (v ?? '').trim().isEmpty ? 'Required' : null,
                                  onChanged: (v) => controller.invoiceNo.value = v,
                                ),
                              ),
                              right: Obx(() {
                                final selectedOrderId = controller.orderId.value;
                                final orderOptions = controller.salesOrders
                                    .where((e) => e['order_id'] != null)
                                    .map((e) {
                                      final id = e['order_id'] as int;
                                      final customerId = e['customer_user_id'];
                                      final label = customerId == null
                                          ? 'SO-$id'
                                          : 'SO-$id (Customer #$customerId)';
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(
                                          label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    })
                                    .toList();

                                if (selectedOrderId != null &&
                                    !orderOptions.any(
                                      (o) => o.value == selectedOrderId,
                                    )) {
                                  orderOptions.insert(
                                    0,
                                    DropdownMenuItem<int>(
                                      value: selectedOrderId,
                                      child: Text('SO-$selectedOrderId'),
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<int>(
                                  initialValue: selectedOrderId,
                                  decoration:
                                      _inputDecoration(labelText: 'Order ID *'),
                                  items: orderOptions,
                                  validator: (v) => v == null ? 'Required' : null,
                                  onChanged: readOnly
                                      ? null
                                      : controller.selectOrder,
                                );
                              }),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
                            _twoFieldRow(
                              left: Obx(() {
                                final selectedCustomerId =
                                    controller.customerUserId.value;
                                final customerOptions = controller.customers
                                    .where((e) => e['id'] != null)
                                    .map((e) {
                                      final id = e['id'] as int;
                                      final name = (e['name'] ?? '').toString();
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(
                                          name.trim().isEmpty
                                              ? '$id'
                                              : '$name (#$id)',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    })
                                    .toList();

                                if (selectedCustomerId != null &&
                                    !customerOptions.any(
                                      (o) => o.value == selectedCustomerId,
                                    )) {
                                  customerOptions.insert(
                                    0,
                                    DropdownMenuItem<int>(
                                      value: selectedCustomerId,
                                      child: Text('Customer #$selectedCustomerId'),
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<int>(
                                  initialValue: selectedCustomerId,
                                  decoration: _inputDecoration(
                                    labelText: 'Customer User ID',
                                  ),
                                  items: customerOptions,
                                  onChanged: readOnly
                                      ? null
                                      : (v) =>
                                            controller.customerUserId.value = v,
                                );
                              }),
                              right: Obx(
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
                                              currentValue:
                                                  controller.invoiceDate.value,
                                              onPicked: (v) =>
                                                  controller.invoiceDate.value = v,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
                            _twoFieldRow(
                              left: Obx(
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
                                              currentValue: controller.dueDate.value,
                                              onPicked: (v) =>
                                                  controller.dueDate.value = v,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              right: Obx(
                                () => DropdownButtonFormField<String>(
                                  initialValue: controller.invoiceStatus.value,
                                  decoration: _inputDecoration(
                                    labelText: 'Invoice Status',
                                  ),
                                  items: const ['DRAFT', 'ISSUED', 'CANCELLED']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: readOnly
                                      ? null
                                      : (v) => controller.invoiceStatus.value =
                                            v ?? 'DRAFT',
                                ),
                              ),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
                            _twoFieldRow(
                              left: Obx(
                                () => DropdownButtonFormField<String>(
                                  initialValue: controller.paymentStatus.value,
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
                              right: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _sectionGap),
                      ContentCard(
                        title: 'Totals',
                        child: Column(
                          children: [
                            _twoFieldRow(
                              left: _numField(
                                'Subtotal *',
                                controller.subtotal,
                                readOnly,
                              ),
                              right: _numField(
                                'Discount',
                                controller.discountTotal,
                                readOnly,
                              ),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
                            _twoFieldRow(
                              left: _numField(
                                'Delivery Charge',
                                controller.deliveryCharge,
                                readOnly,
                              ),
                              right: _numField('Tax', controller.taxTotal, readOnly),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
                            _twoFieldRow(
                              left: _numField(
                                'Grand Total *',
                                controller.grandTotal,
                                readOnly,
                              ),
                              right: const SizedBox.shrink(),
                            ),
                            const SizedBox(height: _fieldVerticalGap),
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
                    if (readOnly)
                      ActionButton(
                        label: 'Print/PDF',
                        onPressed: () async => _printSalesInvoice(controller),
                      ),
                    if (readOnly)
                      ActionButton(
                        label: 'Share',
                        onPressed: () async => _shareSalesInvoice(controller),
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
