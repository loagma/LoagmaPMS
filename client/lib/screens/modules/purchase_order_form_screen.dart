import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_order_form_controller.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_order_list_screen.dart';

InputDecoration _poInputDecoration({
  required String labelText,
  String? hintText,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  return AppInputDecoration.standard(
    labelText: labelText,
    hintText: hintText,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
  ).copyWith(
    floatingLabelBehavior: FloatingLabelBehavior.always,
  );
}

const double _fieldGap = 10;
const double _fieldVerticalGap = 6;
const double _sectionGap = 10;

Future<void> _pickPoDate(
  BuildContext context, {
  required String currentValue,
  required ValueChanged<String> onPicked,
}) async {
  final now = DateTime.now();
  DateTime initialDate = now;
  final raw = currentValue.trim();
  if (raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      initialDate = parsed;
    }
  }

  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked == null) return;

  final month = picked.month.toString().padLeft(2, '0');
  final day = picked.day.toString().padLeft(2, '0');
  onPicked('${picked.year}-$month-$day');
}

Future<void> _printPurchaseOrderReport(PurchaseOrderFormController controller) async {
  try {
    await ReportExportService.printPurchaseOrder(controller);
  } catch (e) {
    Get.snackbar(
      'Print failed',
      'Could not generate purchase order PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

Future<void> _sharePurchaseOrderReport(PurchaseOrderFormController controller) async {
  try {
    await ReportExportService.sharePurchaseOrder(controller);
  } catch (e) {
    Get.snackbar(
      'Share failed',
      'Could not share purchase order PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

class PurchaseOrderFormScreen extends StatelessWidget {
  final int? poId;
  final bool startInViewOnly;

  const PurchaseOrderFormScreen({
    super.key,
    this.poId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PurchaseOrderFormController(
        poId: poId,
        startInViewOnly: startInViewOnly,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Purchase Order' : 'Create Purchase Order',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              tooltip: 'Print/PDF',
              onPressed: () async => _printPurchaseOrderReport(controller),
            );
          }),
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Share/Export',
              onPressed: () async => _sharePurchaseOrderReport(controller),
            );
          }),
          Obx(() {
            final canEdit = controller.viewOnly.value && controller.status.value == 'DRAFT';
            if (!canEdit) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => controller.viewOnly.value = false,
            );
          }),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: 'View all purchase orders',
            onPressed: () => Get.to(() => const PurchaseOrderListScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill in supplier, dates and add line items with quantity and price.',
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
                SizedBox(height: 12),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.isReadOnly) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: _PurchaseOrderReportView(controller: controller),
                ),
              ),
              ActionButtonBar(
                buttons: [
                  ActionButton(
                    label: 'Back',
                    onPressed: () => Get.back(),
                  ),
                  ActionButton(
                    label: 'Print/PDF',
                    onPressed: () async => _printPurchaseOrderReport(controller),
                  ),
                  ActionButton(
                    label: 'Share',
                    onPressed: () async => _sharePurchaseOrderReport(controller),
                  ),
                  if (controller.status.value == 'DRAFT')
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
                      const SizedBox(height: 6),
                      _ItemsCard(controller: controller),
                      const SizedBox(height: 6),
                      _AddonCard(controller: controller),
                      const SizedBox(height: 6),
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
                      onPressed: controller.isSaving.value ? null : () => Get.back(),
                    ),
                    ActionButton(
                      label: 'Save',
                      isPrimary: true,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.isSaving.value || controller.isReadOnly
                          ? null
                          : () => controller.save(),
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

class _PurchaseOrderReportView extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _PurchaseOrderReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final poNumber = controller.currentPoNumber.value.trim().isEmpty
          ? (controller.currentPoSeq.value?.toString() ?? '-')
          : controller.currentPoNumber.value.trim();
      final supplier = controller.suppliers.firstWhere(
        (s) => s['id'] == controller.supplierId.value,
        orElse: () => <String, dynamic>{},
      );
      final supplierName = supplier['supplier_name']?.toString() ?? 'Supplier';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Purchase Order Invoice',
            child: Column(
              children: [
                _metaRow('PO Number', poNumber),
                _metaRow('Status', controller.status.value),
                _metaRow('Supplier', supplierName),
                _metaRow('Document Date', _normalizeDate(controller.docDate.value)),
                _metaRow('Expected Date', _normalizeDate(controller.expectedDate.value)),
                _metaRow('Financial Year', controller.financialYear.value.trim().isEmpty ? '-' : controller.financialYear.value.trim()),
                _metaRow('Narration', controller.narration.value.trim().isEmpty ? '-' : controller.narration.value.trim(), isLast: true),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          ContentCard(
            title: 'Items',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1240),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primaryLighter.withValues(alpha: 0.25),
                  ),
                  dataRowMaxHeight: 62,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('HSN')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Used')),
                    DataColumn(label: Text('WO')),
                    DataColumn(label: Text('Left')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Disc %')),
                    DataColumn(label: Text('Tax %')),
                    DataColumn(label: Text('Rate+Tax')),
                    DataColumn(label: Text('Taxable')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Flag')),
                  ],
                  rows: List<DataRow>.generate(controller.items.length, (i) {
                    final row = controller.items[i];
                    final qty = double.tryParse(row.quantity.value) ?? 0;
                    final used = double.tryParse(row.usedQty.value) ?? 0;
                    final writeoff = double.tryParse(row.writeoffQty.value) ?? 0;
                    final left = double.tryParse(row.leftQty.value) ?? 0;
                    final rate = double.tryParse(row.price.value) ?? 0;
                    final disc = double.tryParse(row.discountPercent.value) ?? 0;
                    final tax = double.tryParse(row.taxPercent.value) ?? 0;
                    final overUsed = used > qty + 0.000001;

                    return DataRow(
                      color: overUsed
                          ? WidgetStateProperty.all(
                              Colors.orange.withValues(alpha: 0.08),
                            )
                          : null,
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(SizedBox(width: 170, child: Text(row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(), maxLines: 2, overflow: TextOverflow.ellipsis))),
                        DataCell(Text(row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim())),
                        DataCell(Text(row.unit.value.trim().isEmpty ? '-' : row.unit.value.trim())),
                        DataCell(Text(qty.toStringAsFixed(1))),
                        DataCell(
                          overUsed
                              ? Text(
                                  used.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : Text(used.toStringAsFixed(1)),
                        ),
                        DataCell(Text(writeoff.toStringAsFixed(1))),
                        DataCell(Text(left.toStringAsFixed(1))),
                        DataCell(Text(rate.toStringAsFixed(2))),
                        DataCell(Text(disc.toStringAsFixed(2))),
                        DataCell(Text(tax.toStringAsFixed(2))),
                        DataCell(Text(row.priceInclTax.toStringAsFixed(2))),
                        DataCell(Text(row.lineTotalExclTax.toStringAsFixed(2))),
                        DataCell(Text(row.lineTotal.toStringAsFixed(2))),
                        DataCell(SizedBox(width: 160, child: Text(row.description.value.trim().isEmpty ? '-' : row.description.value.trim(), maxLines: 2, overflow: TextOverflow.ellipsis))),
                        DataCell(
                          overUsed
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.45)),
                                  ),
                                  child: const Text(
                                    'EXTRA',
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : const Text('-'),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          if (controller.charges.isNotEmpty) ...[
            const SizedBox(height: 6),
            ContentCard(
              title: 'Charges',
              child: Column(
                children: controller.charges
                    .map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _reportMetaRow(
                            row.name.value,
                            (double.tryParse(row.amount.value) ?? 0)
                                .toStringAsFixed(2),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: _sectionGap),
          _SummaryCard(controller: controller),
        ],
      );
    });
  }

  String _normalizeDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '-';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      if (text.length >= 10) return text.substring(0, 10);
      return text;
    }
    final local = parsed.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  Widget _metaRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _sectionGap),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _reportMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Supplier & Dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: Obx(() {
                    final fy = controller.financialYear.value.trim();
                    final options = <String>{
                      if (fy.isNotEmpty) fy,
                      '25-26',
                      '24-25',
                    }.toList();
                    return DropdownButtonFormField<String>(
                      value: fy.isEmpty ? null : fy,
                      decoration: _poInputDecoration(
                        labelText: 'Financial Year',
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
                      onChanged: controller.isReadOnly
                          ? null
                          : (v) {
                              if (v != null) controller.setFinancialYear(v);
                            },
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: Obx(() {
                    final poNumber = controller.currentPoNumber.value;
                    final seqValue = controller.currentPoSeq.value;
                    final labelText = controller.isEditMode
                        ? (poNumber.isEmpty ? 'Existing (no number)' : poNumber)
                        : (seqValue != null ? seqValue.toString() : '');
                    return InputDecorator(
                      decoration: _poInputDecoration(labelText: 'Voucher No'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              labelText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 18),
                            tooltip: 'Previous Voucher',
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.goToPreviousVoucher(),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 18),
                            tooltip: 'Next Voucher',
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.goToNextVoucher(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          Obx(() {
            final list = controller.suppliers;
            return DropdownButtonFormField<int>(
              value: controller.supplierId.value,
              decoration: _poInputDecoration(labelText: 'Supplier *'),
              items: list
                  .map((s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          s['supplier_name']?.toString() ?? 'Supplier #${s['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: controller.isReadOnly ? null : (v) => controller.setSupplierId(v),
              validator: (v) => v == null ? 'Please select supplier' : null,
            );
          }),
          const SizedBox(height: _sectionGap),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final list = controller.salesmen;
                  final current = controller.salesmanId.value;
                  final hasValue = list
                      .any((s) => s['id']?.toString() == current?.toString());
                  final value = hasValue ? current : null;
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: _poInputDecoration(
                      labelText: 'Salesman',
                    ),
                    items: list
                        .map((s) => DropdownMenuItem<String>(
                              value: s['id']?.toString(),
                              child: Text(
                                s['name']?.toString() ?? 'Salesman',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: controller.isReadOnly
                        ? null
                        : (v) => controller.setSalesmanId(v),
                  );
                }),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: Obx(() {
                  final list = controller.departments;
                  final current = controller.departmentId.value;
                  final hasValue = list
                      .any((d) => d['id']?.toString() == current?.toString());
                  final value = hasValue ? current : null;
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: _poInputDecoration(
                      labelText: 'Department',
                    ),
                    items: list
                        .map((d) => DropdownMenuItem<String>(
                              value: d['id']?.toString(),
                              child: Text(
                                d['name']?.toString() ?? 'Department',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: controller.isReadOnly
                        ? null
                        : (v) => controller.setDepartmentId(v),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('po-doc-date-${controller.docDate.value}'),
                      enabled: !controller.isReadOnly,
                      readOnly: true,
                      initialValue: controller.docDate.value,
                      decoration: _poInputDecoration(
                        labelText: 'Document Date *',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: controller.isReadOnly
                          ? null
                          : () => _pickPoDate(
                                context,
                                currentValue: controller.docDate.value,
                                onPicked: controller.setDocDate,
                              ),
                    )),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('po-expected-date-${controller.expectedDate.value}'),
                      enabled: !controller.isReadOnly,
                      readOnly: true,
                      initialValue: controller.expectedDate.value,
                      decoration: _poInputDecoration(
                        labelText: 'Expected Date',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      onTap: controller.isReadOnly
                          ? null
                          : () => _pickPoDate(
                                context,
                                currentValue: controller.expectedDate.value,
                                onPicked: controller.setExpectedDate,
                              ),
                    )),
              ),
            ],
          ),
          if (controller.isEditMode) ...[
            const SizedBox(height: _sectionGap),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.status.value,
                  decoration: _poInputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                    DropdownMenuItem(value: 'SENT', child: Text('Sent')),
                    DropdownMenuItem(
                        value: 'PARTIALLY_RECEIVED',
                        child: Text('Partially received')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: controller.isReadOnly
                      ? null
                      : (v) {
                          if (v != null) controller.setStatus(v);
                        },
                )),
          ],
          const SizedBox(height: _sectionGap),
          Obx(() => TextFormField(
                enabled: !controller.isReadOnly,
                initialValue: controller.narration.value,
                decoration: _poInputDecoration(
                  labelText: 'Narration',
                ).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                minLines: 1,
                maxLines: 1,
                onChanged: controller.setNarration,
              )),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _ItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Product Detail',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.items.isEmpty)
              const EmptyState(
                icon: Icons.shopping_cart_outlined,
                message: 'No items. Tap "Add Item" to add lines.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.items.length,
                itemBuilder: (context, index) => _ItemRow(
                  controller: controller,
                  index: index,
                  row: controller.items[index],
                  isLast: index == controller.items.length - 1,
                ),
              ),
            if (!controller.isReadOnly) ...[
              const SizedBox(height: _sectionGap),
              Align(
                alignment: Alignment.topRight,
                child: OutlinedButton.icon(
                  onPressed: controller.addItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: _fieldVerticalGap),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PurchaseOrderFormController controller;
  final int index;
  final POLineRow row;
  final bool isLast;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 2 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
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
              Obx(() {
                final hsn = row.hsnCode.value.trim();
                final hsnText = hsn.isEmpty ? 'NA' : hsn;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Item ${index + 1}  |  HSN: $hsnText',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (!controller.isReadOnly)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.redAccent,
                    onPressed: () => controller.removeItem(index),
                    tooltip: 'Remove',
                  ),
                ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          _ProductPicker(
            controller: controller,
            row: row,
            readOnly: controller.isReadOnly,
          ),
          Obx(() {
            if (!row.isTaxLoading.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(top: _sectionGap),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Fetching taxes...',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: _sectionGap),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => TextFormField(
                        enabled: !controller.isReadOnly,
                        initialValue: row.quantity.value,
                        decoration: _poInputDecoration(
                          labelText: 'Qty *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final q = double.tryParse(v);
                          if (q == null || q <= 0) return 'Must be > 0';
                          return null;
                        },
                        onChanged: (v) => row.quantity.value = v,
                      )),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(
                    () {
                      final units = controller.unitTypes.isEmpty
                          ? ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML']
                          : controller.unitTypes;
                      final current = row.unit.value;
                      final value = units.contains(current) ? current : units.first;
                      if (value != current && !controller.isReadOnly) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          row.unit.value = value;
                        });
                      }
                      return DropdownButtonFormField<String>(
                        value: value,
                        decoration: _poInputDecoration(labelText: 'Unit')
                            .copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        isDense: true,
                        isExpanded: true,
                        iconSize: 16,
                        items: units
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: controller.isReadOnly
                            ? null
                            : (v) {
                                if (v != null) row.unit.value = v;
                              },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => TextFormField(
                        enabled: !controller.isReadOnly,
                        initialValue: row.price.value,
                        decoration: _poInputDecoration(
                          labelText: 'Unit Price *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final p = double.tryParse(v);
                          if (p == null || p < 0) return 'Must be >= 0';
                          return null;
                        },
                        onChanged: (v) => row.price.value = v,
                      )),
                ),
              ),
            ],
          ),
          Obx(() {
            if (row.productId.value == null || row.availableTaxKeys.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 5),
                _buildTaxRows(row),
              ],
            );
          }),
          const SizedBox(height: _sectionGap),
          _buildTaxTotals(row),
        ],
      ),
    );
  }

  Widget _buildTaxRows(POLineRow row) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Tax',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 2,
                child: Text('Tax %',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 2,
                child: Text('Tax Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        ...row.availableTaxKeys.map((key) {
          final percent = double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
          final taxable = row.lineTotalExclTax;
          final amount = taxable * percent / 100;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(key, style: const TextStyle(fontSize: 11))),
                Expanded(
                    flex: 2,
                    child: Text('${percent.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 11))),
                Expanded(
                    flex: 2,
                    child: Text(amount.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaxTotals(POLineRow row) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _readOnlyAmountField(
                label: 'Total Tax',
                value: (row.lineTotal - row.lineTotalExclTax).toStringAsFixed(2),
              )),
        ),
        const SizedBox(width: _fieldGap),
        Expanded(
          child: Obx(() => _readOnlyAmountField(
                label: 'Product Total',
                value: row.lineTotal.toStringAsFixed(2),
              )),
        ),
      ],
    );
  }

  Widget _readOnlyAmountField({required String label, required String value}) {
    return InputDecorator(
      decoration: _poInputDecoration(labelText: label),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _AddonCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _AddonCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Addon',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.charges.length,
              itemBuilder: (context, index) {
                final charge = controller.charges[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: _fieldVerticalGap),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: PurchaseOrderFormController.chargeTypeNames
                                      .contains(charge.name.value)
                                  ? charge.name.value
                                  : PurchaseOrderFormController.chargeTypeNames.first,
                              decoration: _poInputDecoration(
                                labelText: 'Name',
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: _fieldVerticalGap,
                                ),
                              ),
                              isExpanded: true,
                              isDense: true,
                              items: PurchaseOrderFormController.chargeTypeNames
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: controller.isReadOnly
                                  ? null
                                  : (v) {
                                      if (v != null) charge.name.value = v;
                                    },
                            )),
                      ),
                      const SizedBox(width: _fieldGap),
                      Expanded(
                        child: TextFormField(
                          enabled: !controller.isReadOnly,
                          initialValue: charge.amount.value,
                          decoration: _poInputDecoration(
                            labelText: 'Amount',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,2}')),
                          ],
                          onChanged: (v) => charge.amount.value = v,
                        ),
                      ),
                      if (!controller.isReadOnly) ...[
                        const SizedBox(width: _fieldGap),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: Colors.redAccent,
                            onPressed: () => controller.removeChargeRow(index),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (!controller.isReadOnly)
              Align(
                alignment: Alignment.topRight,
                child: OutlinedButton.icon(
                  onPressed: controller.addChargeRow,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(' Addons'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: _fieldVerticalGap),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  final PurchaseOrderFormController controller;
  final POLineRow row;
  final bool readOnly;

  const _ProductPicker({
    required this.controller,
    required this.row,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: row.productId.value,
      validator: (v) => v == null ? 'Please select product' : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: readOnly
                  ? null
                  : () async {
                      final product = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => _POProductSearchDialog(controller: controller),
                      );
                      if (product != null) {
                        final rawId = product['product_id'] ?? product['id'];
                        final pid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                        if (pid != null) {
                          row.productId.value = pid;
                          row.productName.value = product['name']?.toString() ?? '';
                          row.hsnCode.value =
                              product['hsn_code']?.toString() ??
                              product['hsn']?.toString() ??
                              product['hsnCode']?.toString() ??
                              '';
                          await controller.applyProductTaxesToRow(row, pid);
                          state.didChange(pid);
                          state.validate();
                        }
                      }
                    },
              child: InputDecorator(
                decoration: _poInputDecoration(
                  labelText: 'Product *',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            row.productName.value.isEmpty
                                ? 'Tap to search...'
                                : row.productName.value,
                            style: TextStyle(
                              color: row.productId.value == null ? Colors.grey : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    if (!readOnly)
                      const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _POProductSearchDialog extends StatefulWidget {
  final PurchaseOrderFormController controller;

  const _POProductSearchDialog({required this.controller});

  @override
  State<_POProductSearchDialog> createState() => _POProductSearchDialogState();
}

class _POProductSearchDialogState extends State<_POProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _searched = false;
  bool _showAllProducts = false;

  @override
  void initState() {
    super.initState();
    _showAllProducts = widget.controller.supplierId.value == null;
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searched = true;
    });
    final list = await widget.controller.searchProductsForSupplier(
      query,
      includeAll: _showAllProducts,
    );
    if (mounted) {
      setState(() {
        _results = list;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search product'),
      content: SizedBox(
        width: 360,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: _poInputDecoration(
                labelText: 'Search Product',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (_searchController.text == value) _runSearch(value);
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty && !_searching
                  ? Center(
                      child: Text(
                        _searched
                            ? 'No products found. Try a different search.'
                            : 'Type above to search products.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        final pid = p['product_id'] as int?;
                        final name = p['name']?.toString() ?? 'ID $pid';
                        return ListTile(
                          dense: true,
                          title: Text(name, overflow: TextOverflow.ellipsis),
                          subtitle: pid != null ? Text('ID: $pid') : null,
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final hasSupplier = widget.controller.supplierId.value != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasSupplier)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Select supplier to filter by assigned products.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: hasSupplier
                          ? () {
                              setState(() => _showAllProducts = !_showAllProducts);
                              _runSearch(_searchController.text);
                            }
                          : null,
                      child: Text(
                        _showAllProducts
                            ? 'Show only products assigned to this supplier'
                            : 'View all products',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Map<String, double> buildTaxTotalsByLabel() {
        final totals = <String, double>{};
        for (final row in controller.items) {
          final base = row.lineTotalExclTax;
          for (final label in row.availableTaxKeys) {
            final percent = double.tryParse(row.taxFieldValues[label] ?? '') ?? 0;
            totals[label] = (totals[label] ?? 0) + (base * percent / 100);
          }
          row.taxFieldValues.forEach((label, value) {
            if (totals.containsKey(label)) return;
            final percent = double.tryParse(value) ?? 0;
            totals[label] = (totals[label] ?? 0) + (base * percent / 100);
          });
        }
        return totals;
      }

      String displayTaxLabel(String label) {
        final key = label.trim().toUpperCase();
        if (key == 'ROFF') return 'Round off Tax';
        return label;
      }

      final grossAmount = controller.itemsSubtotalExclTax;
      final taxTotals = buildTaxTotalsByLabel();
      final roundOffTax = controller.roffTotal;
      final addOnTotal = controller.addOnTotal;
      final totalInclTax = controller.grandTotal;
      final visibleTaxEntries = taxTotals.entries
          .where((e) => e.key.trim().toUpperCase() != 'ROFF')
          .toList();

      return ContentCard(
        title: 'Summary',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Gross Amount', '₹ ${grossAmount.toStringAsFixed(2)}', false),
            for (final entry in visibleTaxEntries) ...[
              const SizedBox(height: 3),
              _summaryRow(
                displayTaxLabel(entry.key),
                '₹ ${entry.value.toStringAsFixed(2)}',
                false,
              ),
            ],
            if (roundOffTax > 0) ...[
              const SizedBox(height: 3),
              _summaryRow('Round off Tax', '₹ ${roundOffTax.toStringAsFixed(2)}', false),
            ],
            if (addOnTotal != 0) ...[
              const SizedBox(height: 3),
              _summaryRow('Add on total', '₹ ${addOnTotal.toStringAsFixed(2)}', false),
            ],
            const SizedBox(height: 5),
            _summaryRow('Total', '₹ ${totalInclTax.toStringAsFixed(2)}', true),
          ],
        ),
      );
    });
  }

  Widget _summaryRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
