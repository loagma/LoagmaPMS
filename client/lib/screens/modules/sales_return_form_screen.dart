import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_return_form_controller.dart';
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

class SalesReturnFormScreen extends StatelessWidget {
  final int? returnId;
  final bool startInViewOnly;

  const SalesReturnFormScreen({
    super.key,
    this.returnId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SalesReturnFormController(
        returnId: returnId,
        startInViewOnly: startInViewOnly,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Sales Return' : 'Create Sales Return',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final canEdit =
                controller.viewOnly.value &&
                controller.returnStatus.value == 'DRAFT';
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
                        title: 'Return Header',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        controller.currentReturnId.value
                                            ?.toString() ??
                                        '',
                                    readOnly: true,
                                    decoration: _inputDecoration(
                                      labelText: 'Return ID',
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
                                  child: Obx(
                                    () => TextFormField(
                                      controller: TextEditingController(
                                        text: controller.returnDate.value,
                                      ),
                                      readOnly: true,
                                      decoration: _inputDecoration(
                                        labelText: 'Return Date *',
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.calendar_today_rounded,
                                          ),
                                          onPressed: readOnly
                                              ? null
                                              : () => _pickDate(
                                                  context,
                                                  currentValue: controller
                                                      .returnDate
                                                      .value,
                                                  onPicked: (v) =>
                                                      controller
                                                              .returnDate
                                                              .value =
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
                                      value: controller.returnStatus.value,
                                      decoration: _inputDecoration(
                                        labelText: 'Return Status',
                                      ),
                                      items:
                                          const ['DRAFT', 'POSTED', 'CANCELLED']
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
                                                controller.returnStatus.value =
                                                    v ?? 'DRAFT',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: controller.reason.value,
                              readOnly: readOnly,
                              decoration: _inputDecoration(labelText: 'Reason'),
                              maxLines: 2,
                              onChanged: (v) => controller.reason.value = v,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ContentCard(
                        title: 'Return Items',
                        titleAction: readOnly
                            ? null
                            : TextButton.icon(
                                onPressed: controller.addItem,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add'),
                              ),
                        child: Obx(
                          () => Column(
                            children: [
                              for (int i = 0; i < controller.items.length; i++)
                                _ReturnItemRow(
                                  row: controller.items[i],
                                  readOnly: readOnly,
                                  onDelete: () => controller.removeItem(i),
                                ),
                              if (controller.items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No return items'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ContentCard(
                        title: 'Summary',
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Refund',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                controller.totalRefund.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
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
                    else if (controller.returnStatus.value == 'DRAFT')
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
}

class _ReturnItemRow extends StatelessWidget {
  final SalesReturnLineRow row;
  final bool readOnly;
  final VoidCallback onDelete;

  const _ReturnItemRow({
    required this.row,
    required this.readOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.productIdCtrl,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(labelText: 'Product ID *'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.originalQtyCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(labelText: 'Original Qty *'),
                  validator: (v) =>
                      (double.tryParse((v ?? '').trim()) ?? -1) < 0
                      ? 'Invalid'
                      : null,
                ),
              ),
              if (!readOnly)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.returnQtyCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(labelText: 'Return Qty *'),
                  validator: (v) =>
                      (double.tryParse((v ?? '').trim()) ?? -1) < 0
                      ? 'Invalid'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.refundAmountCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(labelText: 'Refund Amount *'),
                  validator: (v) =>
                      (double.tryParse((v ?? '').trim()) ?? -1) < 0
                      ? 'Invalid'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: row.reasonCtrl,
            readOnly: readOnly,
            decoration: _inputDecoration(labelText: 'Line Reason'),
          ),
        ],
      ),
    );
  }
}
