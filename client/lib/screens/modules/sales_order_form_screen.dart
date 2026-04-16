import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_order_form_controller.dart';
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

class SalesOrderFormScreen extends StatelessWidget {
  final int? orderId;
  final bool startInViewOnly;

  const SalesOrderFormScreen({
    super.key,
    this.orderId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SalesOrderFormController(
        orderId: orderId,
        startInViewOnly: startInViewOnly,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Sales Order' : 'Create Sales Order',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final canEdit =
                controller.viewOnly.value &&
                controller.orderState.value == 'registered';
            if (!canEdit) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => controller.viewOnly.value = false,
            );
          }),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill header and line items, then save the sales order.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isReadOnly) {
          return _SalesOrderReadOnlyView(controller: controller);
        }

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
                      _HeaderCard(controller: controller),
                      const SizedBox(height: 8),
                      _ItemsCard(controller: controller),
                      const SizedBox(height: 8),
                      _SummaryCard(controller: controller),
                    ],
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
                      label: 'Save',
                      isPrimary: true,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.save,
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

class _SalesOrderReadOnlyView extends StatelessWidget {
  final SalesOrderFormController controller;

  const _SalesOrderReadOnlyView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(controller: controller, readOnly: true),
                const SizedBox(height: 8),
                _ItemsCard(controller: controller, readOnly: true),
                const SizedBox(height: 8),
                _SummaryCard(controller: controller),
              ],
            ),
          ),
        ),
        ActionButtonBar(
          buttons: [
            ActionButton(label: 'Back', onPressed: () => Get.back()),
            if (controller.orderState.value == 'registered')
              ActionButton(
                label: 'Edit Draft',
                isPrimary: true,
                onPressed: () => controller.viewOnly.value = false,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SalesOrderFormController controller;
  final bool readOnly;

  const _HeaderCard({required this.controller, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Order Header',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      controller.currentOrderId.value?.toString() ?? '',
                  readOnly: true,
                  decoration: _inputDecoration(labelText: 'Order ID'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue:
                      controller.customerUserId.value?.toString() ?? '',
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(labelText: 'Customer User ID *'),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Required';
                    return null;
                  },
                  onChanged: (v) =>
                      controller.customerUserId.value = int.tryParse(v.trim()),
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
                      text: controller.orderDate.value,
                    ),
                    readOnly: true,
                    decoration: _inputDecoration(
                      labelText: 'Order Date *',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_rounded),
                        onPressed: readOnly
                            ? null
                            : () => _pickDate(
                                context,
                                currentValue: controller.orderDate.value,
                                onPicked: (v) => controller.orderDate.value = v,
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
                    value: controller.orderState.value,
                    decoration: _inputDecoration(labelText: 'Order State'),
                    items:
                        const [
                              'registered',
                              'dispatched',
                              'delivered',
                              'cancelled',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: readOnly
                        ? null
                        : (v) =>
                              controller.orderState.value = v ?? 'registered',
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
                  () => DropdownButtonFormField<String>(
                    value: controller.paymentStatus.value,
                    decoration: _inputDecoration(labelText: 'Payment Status'),
                    items:
                        const ['not_paid', 'pending', 'partially_paid', 'paid']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: readOnly
                        ? null
                        : (v) =>
                              controller.paymentStatus.value = v ?? 'not_paid',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.paymentMethod.value,
                    decoration: _inputDecoration(labelText: 'Payment Method'),
                    items: const ['cod', 'online', 'bank']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: readOnly
                        ? null
                        : (v) => controller.paymentMethod.value = v ?? 'cod',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: controller.remarks.value,
            readOnly: readOnly,
            decoration: _inputDecoration(labelText: 'Remarks'),
            maxLines: 2,
            onChanged: (v) => controller.remarks.value = v,
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SalesOrderFormController controller;
  final bool readOnly;

  const _ItemsCard({required this.controller, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Items',
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
              _ItemRow(
                index: i,
                row: controller.items[i],
                readOnly: readOnly,
                onDelete: () => controller.removeItem(i),
              ),
            if (controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No line items'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final SalesOrderLineRow row;
  final bool readOnly;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.index,
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
                  controller: row.vendorProductIdCtrl,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(labelText: 'Vendor Product ID'),
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
                  controller: row.quantityCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(labelText: 'Qty *'),
                  validator: (v) =>
                      (double.tryParse((v ?? '').trim()) ?? 0) <= 0
                      ? 'Invalid'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.itemPriceCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(labelText: 'Rate *'),
                  validator: (v) => (double.tryParse((v ?? '').trim()) ?? 0) < 0
                      ? 'Invalid'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: row.lineTotal.toStringAsFixed(2),
                  readOnly: true,
                  decoration: _inputDecoration(labelText: 'Line Total'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SalesOrderFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Summary',
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              controller.subtotal.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
