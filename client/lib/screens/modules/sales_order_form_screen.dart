import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_order_form_controller.dart';
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

Future<void> _printSalesOrder(SalesOrderFormController controller) async {
  try {
    await ReportExportService.printSalesOrder(controller);
  } catch (e) {
    Get.snackbar(
      'Print failed',
      'Could not generate sales order PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

Future<void> _shareSalesOrder(SalesOrderFormController controller) async {
  try {
    await ReportExportService.shareSalesOrder(controller);
  } catch (e) {
    Get.snackbar(
      'Share failed',
      'Could not share sales order PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
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
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              tooltip: 'Print/PDF',
              onPressed: () async => _printSalesOrder(controller),
            );
          }),
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Share/Export',
              onPressed: () async => _shareSalesOrder(controller),
            );
          }),
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
                      const SizedBox(height: _sectionGap),
                      _ItemsCard(controller: controller),
                      const SizedBox(height: _sectionGap),
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
                const SizedBox(height: _sectionGap),
                _ItemsCard(controller: controller, readOnly: true),
                const SizedBox(height: _sectionGap),
                _SummaryCard(controller: controller),
              ],
            ),
          ),
        ),
        ActionButtonBar(
          buttons: [
            ActionButton(label: 'Back', onPressed: () => Get.back()),
            ActionButton(
              label: 'Print/PDF',
              onPressed: () async => _printSalesOrder(controller),
            ),
            ActionButton(
              label: 'Share',
              onPressed: () async => _shareSalesOrder(controller),
            ),
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
          _twoFieldRow(
            left: TextFormField(
              initialValue: controller.currentOrderId.value?.toString() ?? '',
              readOnly: true,
              decoration: _inputDecoration(labelText: 'Order ID'),
            ),
            right: Obx(() {
              final currentValue = controller.customerUserId.value;
              final options = controller.customers
                  .where((e) => e['id'] != null)
                  .map((e) {
                    final id = e['id'] as int;
                    final name = (e['name'] ?? '').toString();
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        name.trim().isEmpty ? '$id' : '$name (#$id)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList();

              if (currentValue != null &&
                  !options.any((o) => o.value == currentValue)) {
                options.insert(
                  0,
                  DropdownMenuItem<int>(
                    value: currentValue,
                    child: Text('Customer #$currentValue'),
                  ),
                );
              }

              return DropdownButtonFormField<int>(
                initialValue: currentValue,
                decoration: _inputDecoration(labelText: 'Customer User ID *'),
                items: options,
                validator: (v) => v == null ? 'Required' : null,
                onChanged: readOnly
                    ? null
                    : (v) => controller.customerUserId.value = v,
              );
            }),
          ),
          const SizedBox(height: _fieldVerticalGap),
          _twoFieldRow(
            left: Obx(
              () => TextFormField(
                controller: TextEditingController(text: controller.orderDate.value),
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
            right: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.orderState.value,
                decoration: _inputDecoration(labelText: 'Order State'),
                items: const ['registered', 'dispatched', 'delivered', 'cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (v) => controller.orderState.value = v ?? 'registered',
              ),
            ),
          ),
          const SizedBox(height: _fieldVerticalGap),
          _twoFieldRow(
            left: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.paymentStatus.value,
                decoration: _inputDecoration(labelText: 'Payment Status'),
                items: const ['not_paid', 'pending', 'partially_paid', 'paid']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (v) => controller.paymentStatus.value = v ?? 'not_paid',
              ),
            ),
            right: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.paymentMethod.value,
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
          const SizedBox(height: _fieldVerticalGap),
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
                controller: controller,
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
  final SalesOrderFormController controller;
  final int index;
  final SalesOrderLineRow row;
  final bool readOnly;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.controller,
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
                child: Obx(() {
                  final selectedId = int.tryParse(row.productIdCtrl.text.trim());
                  final productOptions = controller.products
                      .where((p) => p['id'] != null)
                      .map((p) {
                        final id = p['id'] as int;
                        final name = (p['name'] ?? '').toString();
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            name.trim().isEmpty ? '$id' : '$name (#$id)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })
                      .toList();

                  if (selectedId != null &&
                      !productOptions.any((o) => o.value == selectedId)) {
                    productOptions.insert(
                      0,
                      DropdownMenuItem<int>(
                        value: selectedId,
                        child: Text('Product #$selectedId'),
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: selectedId,
                    isExpanded: true,
                    decoration: _inputDecoration(labelText: 'Product ID *'),
                    items: productOptions,
                    validator: (v) => v == null ? 'Required' : null,
                    onChanged: readOnly
                        ? null
                        : (v) => row.productIdCtrl.text = v?.toString() ?? '',
                  );
                }),
              ),
              const SizedBox(width: _fieldGap),
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
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    tooltip: 'Delete item',
                  ),
                ),
            ],
          ),
          const SizedBox(height: _fieldVerticalGap),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.quantityCtrl,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(labelText: 'Qty *'),
                  validator: (v) =>
                      (int.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: TextFormField(
                  controller: row.itemPriceCtrl,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(labelText: 'Rate *'),
                  validator: (v) =>
                      (double.tryParse((v ?? '').trim()) ?? 0) < 0 ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: _fieldGap),
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
