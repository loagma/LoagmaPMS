import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/sales_invoice_controller.dart';
import '../../models/party_result.dart';
import '../../models/product_model.dart';
import '../../models/sales_order_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_return_form_screen.dart';

InputDecoration _siInputDecoration({
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

Future<void> _pickDocumentDate(
  BuildContext context,
  SalesInvoiceController controller,
) async {
  final now = DateTime.now();
  DateTime initialDate = now;
  final raw = controller.docDate.value.trim();
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
  controller.setDocDate('${picked.year}-$month-$day');
}

class SalesInvoiceFormScreen extends StatelessWidget {
  final int? invoiceId;
  final bool? startInReportMode;

  const SalesInvoiceFormScreen({
    super.key,
    this.invoiceId,
    this.startInReportMode,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SalesInvoiceController(
        invoiceId: invoiceId,
        startInReportMode: startInReportMode ?? false,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Sales Invoice',
        subtitle: 'Record sales invoice',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            if (!controller.isReportMode) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: controller.canEditFromReport ? controller.enterEditMode : null,
            );
          }),
          Obx(() {
            if (!controller.isReportMode) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.assignment_return_outlined, color: Colors.white),
              tooltip: 'Create Return',
              onPressed: () async {
                final result = await Get.to(
                  () => SalesReturnFormScreen(
                    sourceSiId: controller.activeInvoiceId.value,
                  ),
                );
                if (result == true) {
                  Get.snackbar(
                    'Success',
                    'Sales return saved',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Enter customer, bill details and line items. Save as draft or post.',
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
                  'Loading...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth - 32;

            if (controller.isReportMode) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: _InvoiceReportView(controller: controller),
                        ),
                      ),
                    ),
                  ),
                  ActionButtonBar(
                    buttons: [
                      ActionButton(label: 'Back', onPressed: () => Get.back()),
                      if (controller.canEditFromReport)
                        ActionButton(
                          label: 'Edit Draft',
                          isPrimary: true,
                          onPressed: controller.enterEditMode,
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
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderCard(controller: controller),
                              const SizedBox(height: _sectionGap),
                              _ItemsCard(controller: controller),
                              const SizedBox(height: _sectionGap),
                              _ChargesCard(controller: controller),
                              const SizedBox(height: _sectionGap),
                              _SummaryCard(controller: controller),
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
                          onPressed: controller.isSaving.value ? null : () => Get.back(),
                        ),
                        ActionButton(
                          label: 'Save as Draft',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value ? null : () => controller.saveDraft(),
                        ),
                        ActionButton(
                          label: 'Post',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value ? null : () => controller.confirmPost(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class _InvoiceReportView extends StatelessWidget {
  final SalesInvoiceController controller;

  const _InvoiceReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
      return Obx(() {
        final docNo = '${controller.docNoPrefix.value}${controller.docNoNumber.value.trim()}';
        final rows = controller.items;
      final customerLabel = controller.customerDisplayLabel.isEmpty
          ? 'Customer'
          : controller.customerDisplayLabel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Sales Invoice',
            child: Column(
              children: [
                _metaRow('Invoice No', docNo.trim().isEmpty ? '-' : docNo),
                _metaRow('Status', controller.status.value),
                _metaRow('Customer', customerLabel),
                _metaRow('Document Date', _normalizeDate(controller.docDate.value)),
                _metaRow('Bill No', controller.billNo.value.trim().isEmpty ? '-' : controller.billNo.value.trim()),
                _metaRow('Bill Date', _normalizeDate(controller.billDate.value)),
                _metaRow('Sale Type', controller.saleType.value.trim().isEmpty ? '-' : controller.saleType.value.trim()),
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
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primaryLighter.withValues(alpha: 0.25),
                  ),
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 62,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('HSN')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Taxable')),
                    DataColumn(label: Text('SGST')),
                    DataColumn(label: Text('CGST')),
                    DataColumn(label: Text('IGST')),
                    DataColumn(label: Text('CESS')),
                    DataColumn(label: Text('ROFF')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: List<DataRow>.generate(rows.length, (i) {
                    final row = rows[i];
                    final qty = double.tryParse(row.quantity.value) ?? 0;
                    final unitPrice = double.tryParse(row.unitPrice.value) ?? 0;
                    final taxable = double.tryParse(row.taxableAmount.value) ?? (qty * unitPrice);
                    final sgst = double.tryParse(row.sgst.value) ?? 0;
                    final cgst = double.tryParse(row.cgst.value) ?? 0;
                    final igst = double.tryParse(row.igst.value) ?? 0;
                    final cess = double.tryParse(row.cess.value) ?? 0;
                    final roff = double.tryParse(row.roff.value) ?? 0;
                    final total = double.tryParse(row.value.value) ?? (taxable + sgst + cgst + igst + cess + roff);

                    return DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(SizedBox(width: 180, child: Text(row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(), maxLines: 2, overflow: TextOverflow.ellipsis))),
                      DataCell(Text(row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim())),
                      DataCell(Text(row.unitType.value.trim().isEmpty ? '-' : row.unitType.value.trim())),
                      DataCell(Text(qty.toStringAsFixed(1))),
                      DataCell(Text(unitPrice.toStringAsFixed(2))),
                      DataCell(Text(taxable.toStringAsFixed(2))),
                      DataCell(Text(sgst.toStringAsFixed(2))),
                      DataCell(Text(cgst.toStringAsFixed(2))),
                      DataCell(Text(igst.toStringAsFixed(2))),
                      DataCell(Text(cess.toStringAsFixed(2))),
                      DataCell(Text(roff.toStringAsFixed(2))),
                      DataCell(Text(total.toStringAsFixed(2))),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          if (controller.charges.isNotEmpty) ...[
            const SizedBox(height: _sectionGap),
            ContentCard(
              title: 'Charges',
              child: Column(
                children: controller.charges
                    .map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _metaRow(
                            row.name.value,
                            (double.tryParse(row.amount.value) ?? 0).toStringAsFixed(2),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SalesInvoiceController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Customer & Dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.docNoPrefix.value,
                        decoration: _siInputDecoration(labelText: 'Financial Year'),
                        isExpanded: true,
                        items: ['25-26/', '24-25/']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.setDocNoPrefix(v);
                        },
                      )),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 47,
                  child: Obx(() {
                    final seq = controller.currentSeq.value;
                    final docNo = controller.docNoNumber.value.trim();
                    final labelText = docNo.isNotEmpty ? docNo : (seq != null ? seq.toString() : '');
                    return InputDecorator(
                      decoration: _siInputDecoration(labelText: 'Invoice No'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              labelText,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 18),
                            tooltip: 'Previous',
                            onPressed: controller.isLoading.value ? null : () => controller.goToPreviousInvoice(),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 18),
                            tooltip: 'Next',
                            onPressed: controller.isLoading.value ? null : () => controller.goToNextInvoice(),
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
          FormField<int>(
            initialValue: controller.customerId.value,
            validator: (v) => v == null ? 'Please select Customer' : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: controller.isReportMode ? null : () async {
                    final party = await showDialog<PartyResult>(
                      context: context,
                      builder: (_) => PartySearchDialog(
                        title: 'Select Customer',
                        hint: 'Search by name, phone or ID...',
                        searchFn: controller.searchCustomers,
                      ),
                    );
                    if (party != null) {
                      controller.setCustomer(
                        party.id,
                        party.name,
                        phone: party.phone,
                        shopName: party.shopName,
                      );
                      state.didChange(party.id);
                      state.validate();
                    }
                  },
                  child: InputDecorator(
                    decoration: _siInputDecoration(labelText: 'Customer *'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final selectedId = controller.customerId.value;
                            if (selectedId == null) {
                              return const Text(
                                'Tap to select...',
                                style: TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            final title = controller.customerDisplayTitle;
                            final subtitle = controller.customerDisplaySubtitle;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
                        if (!controller.isReportMode)
                          const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          Obx(() => TextFormField(
                initialValue: controller.narration.value,
                decoration: _siInputDecoration(labelText: 'Narration').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                minLines: 1,
                maxLines: 1,
                onChanged: controller.setNarration,
              )),
          const SizedBox(height: _sectionGap),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.docDate.value,
                      readOnly: true,
                      decoration: _siInputDecoration(
                        labelText: 'Document Date *',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: () => _pickDocumentDate(context, controller),
                    )),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.billNo.value,
                      decoration: _siInputDecoration(labelText: 'Bill No'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: controller.setBillNo,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SalesInvoiceController controller;

  const _ItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Product Detail',
      child: Obx(() {
        final linkedSoLabels = controller.linkedSoNumbers.isNotEmpty
            ? controller.linkedSoNumbers.toList()
            : controller.linkedSalesOrderIds.map((id) => 'ORD-$id').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Link Sales Order button + linked SO chips
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: controller.isReportMode
                      ? null
                      : () => _showLinkToSalesOrderDialog(context, controller),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Link Sales Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            if (linkedSoLabels.isNotEmpty) ...[
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: linkedSoLabels
                      .map(
                        (soLabel) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Text(
                            soLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (controller.items.isEmpty)
              const EmptyState(
                icon: Icons.shopping_cart_outlined,
                message: 'No items. Tap "Add Product" or link a Sales Order.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  return _ItemRow(
                    controller: controller,
                    index: index,
                    row: controller.items[index],
                    isLast: index == controller.items.length - 1,
                  );
                },
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.topRight,
              child: OutlinedButton.icon(
                onPressed: controller.isReportMode ? null : () => controller.addItemRow(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final SalesInvoiceController controller;
  final int index;
  final SIItemRow row;
  final bool isLast;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final excludeIds = controller.items
        .where((r) => r != row && r.product.value != null)
        .map((r) => r.product.value!.id);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 2 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Colors.redAccent,
                  onPressed: () => controller.removeItemRow(index),
                  tooltip: 'Remove',
                ),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          _ProductPickerField(controller: controller, row: row, excludeIds: excludeIds.toSet()),
          const SizedBox(height: _sectionGap),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: TextFormField(
                    controller: row.quantityController,
                    focusNode: row.quantityFocusNode,
                    decoration: _siInputDecoration(labelText: 'Qty *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Required';
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) return 'Must be > 0';
                      return null;
                    },
                    onChanged: (value) {
                      row.quantity.value = value;
                      controller.recalcItemRow(row);
                    },
                  ),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() {
                    final units = controller.unitTypes.isEmpty ? ['Nos', 'KG', 'PCS', 'LTR'] : controller.unitTypes;
                    final value = units.contains(row.unitType.value) ? row.unitType.value : (units.isNotEmpty ? units.first : 'Nos');
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: _siInputDecoration(labelText: 'Unit').copyWith(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      isDense: true,
                      isExpanded: true,
                      iconSize: 16,
                      items: units.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          )).toList(),
                      onChanged: (v) {
                        if (v != null) row.unitType.value = v;
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => TextFormField(
                        initialValue: row.unitPrice.value,
                        decoration: _siInputDecoration(labelText: 'Unit Price *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final p = double.tryParse(value);
                          if (p == null || p < 0) return 'Must be >= 0';
                          return null;
                        },
                        onChanged: (value) {
                          row.unitPrice.value = value;
                          controller.recalcItemRow(row);
                        },
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Obx(() {
            if (row.product.value == null || row.availableTaxKeys.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [const SizedBox(height: 5), _buildTaxRows(row)],
            );
          }),
          const SizedBox(height: 5),
          _buildTaxTotals(row),
        ],
      ),
    );
  }

  Widget _buildTaxRows(SIItemRow row) {
    return Obx(() {
      final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
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
                Expanded(flex: 3, child: Text('Tax', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Tax %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Tax Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ...row.availableTaxKeys.map((key) {
            final percent = double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
            final amount = taxable * percent / 100;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(key, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text('${percent.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text(amount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildTaxTotals(SIItemRow row) {
    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
            final total = double.tryParse(row.value.value) ?? 0;
            final tax = total - taxable;
            return _readOnlyAmountField(label: 'Total Tax', value: tax);
          }),
        ),
        const SizedBox(width: _fieldGap),
        Expanded(
          child: Obx(() => _readOnlyAmountField(
                label: 'Product Total',
                value: double.tryParse(row.value.value) ?? 0,
              )),
        ),
      ],
    );
  }

  Widget _readOnlyAmountField({required String label, required double value}) {
    final display = value.abs() < 0.000001 ? '' : value.toStringAsFixed(2);
    return InputDecorator(
      decoration: _siInputDecoration(labelText: label),
      child: Text(display, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _ProductPickerField extends StatelessWidget {
  final SalesInvoiceController controller;
  final SIItemRow row;
  final Set<int> excludeIds;

  const _ProductPickerField({
    required this.controller,
    required this.row,
    required this.excludeIds,
  });

  void _applySelection(SIItemRow target, ProductSelection sel) {
    target.product.value = sel.product;
    target.productName.value = sel.product.name;
    target.productCode.value = sel.product.code ?? '${sel.product.id}';
    target.hsnCode.value = sel.product.hsnCode ?? '';
    target.alias.value = '${sel.product.name} : ${target.unitType.value}';
    if (sel.selectedPack != null) {
      target.selectedPackId.value = sel.selectedPack!.id;
      target.selectedPackLabel.value = sel.selectedPack!.label;
      if (sel.selectedPack!.unit != null && controller.unitTypes.contains(sel.selectedPack!.unit)) {
        target.unitType.value = sel.selectedPack!.unit!;
      }
      if (sel.selectedPack!.price != null) {
        target.unitPrice.value = sel.selectedPack!.price!.toString();
      }
    } else {
      final unit = sel.product.defaultUnit?.toString();
      if (unit != null && unit.isNotEmpty && controller.unitTypes.contains(unit)) {
        target.unitType.value = unit;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Product>(
      initialValue: row.product.value,
      validator: (v) => v == null ? 'Please select product' : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: controller.isReportMode
                  ? null
                  : () async {
                      final selections = await showDialog<List<ProductSelection>>(
                        context: context,
                        builder: (ctx) => ProductSearchDialog(
                          title: 'Select Products',
                          searchFn: controller.searchProductsAsModels,
                          excludeIds: excludeIds,
                          allowMultiSelect: true,
                        ),
                      );
                      if (selections == null || selections.isEmpty) return;

                      // Fill the current (triggering) row with the first selection
                      final first = selections.first;
                      _applySelection(row, first);
                      await controller.applyResolvedTaxesToInvoiceRow(row, productId: first.product.id);
                      state.didChange(first.product);

                      // Add new rows for remaining selections
                      for (int i = 1; i < selections.length; i++) {
                        controller.addItemRow();
                        final newRow = controller.items.last;
                        _applySelection(newRow, selections[i]);
                        await controller.applyResolvedTaxesToInvoiceRow(newRow, productId: selections[i].product.id);
                      }
                    },
              child: InputDecorator(
                decoration: _siInputDecoration(labelText: 'Product *'),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        final name = row.product.value?.name ?? '';
                        final packLabel = row.selectedPackLabel.value;
                        final displayText = name.isEmpty
                            ? 'Tap to search...'
                            : (packLabel.isNotEmpty ? '$name · $packLabel' : name);
                        return Text(
                          displayText,
                          style: TextStyle(color: row.product.value == null ? Colors.grey : null),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ),
                    if (!controller.isReportMode)
                      const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}


class _ChargesCard extends StatelessWidget {
  final SalesInvoiceController controller;

  const _ChargesCard({required this.controller});

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
                final row = controller.charges[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: _sectionGap),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: _fieldVerticalGap),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: SalesInvoiceController.chargeTypeNames.contains(row.name.value)
                                  ? row.name.value
                                  : SalesInvoiceController.chargeTypeNames.first,
                              decoration: _siInputDecoration(labelText: 'Name').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: _fieldVerticalGap),
                              ),
                              isExpanded: true,
                              isDense: true,
                              items: SalesInvoiceController.chargeTypeNames
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) row.name.value = v;
                              },
                            )),
                      ),
                      const SizedBox(width: _fieldGap),
                      Expanded(
                        child: Obx(() => TextFormField(
                              initialValue: row.amount.value,
                              decoration: _siInputDecoration(labelText: 'Amount'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => row.amount.value = v,
                            )),
                      ),
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
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.topRight,
              child: OutlinedButton.icon(
                onPressed: controller.addChargeRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(' Addons'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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

class _SummaryCard extends StatelessWidget {
  final SalesInvoiceController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Map<String, double> buildTaxTotalsByLabel() {
        final totals = <String, double>{};
        for (final row in controller.items) {
          final base = double.tryParse(row.taxableAmount.value) ?? 0;
          for (final label in row.availableTaxKeys) {
            final percent = double.tryParse(row.taxFieldValues[label] ?? '') ?? 0;
            if (percent <= 0) continue;
            totals[label] = (totals[label] ?? 0) + (base * percent / 100);
          }
          row.taxFieldValues.forEach((label, value) {
            if (totals.containsKey(label)) return;
            final percent = double.tryParse(value) ?? 0;
            if (percent <= 0) return;
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

      double grossAmount = 0;
      for (final row in controller.items) {
        final qty = double.tryParse(row.quantity.value) ?? 0;
        final price = double.tryParse(row.unitPrice.value) ?? 0;
        grossAmount += qty * price;
      }

      double chargesTotal = 0;
      for (final row in controller.charges) {
        final amt = double.tryParse(row.amount.value) ?? 0;
        final name = row.name.value.toLowerCase();
        chargesTotal += name.contains('discount') ? -amt : amt;
      }

      final taxTotals = buildTaxTotalsByLabel();
      final roundOffTax = taxTotals.entries
          .where((e) => e.key.trim().toUpperCase() == 'ROFF')
          .fold(0.0, (sum, e) => sum + e.value);
      final visibleTaxEntries = taxTotals.entries
          .where((e) => e.key.trim().toUpperCase() != 'ROFF' && e.value > 0)
          .toList();
      final totalInclTax = double.tryParse(controller.netTotal) ?? 0;

      return ContentCard(
        title: 'Summary',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Gross Amount', '₹ ${grossAmount.toStringAsFixed(2)}', false),
            for (final entry in visibleTaxEntries) ...[
              const SizedBox(height: 3),
              _summaryRow(displayTaxLabel(entry.key), '₹ ${entry.value.toStringAsFixed(2)}', false),
            ],
            if (roundOffTax > 0) ...[
              const SizedBox(height: 3),
              _summaryRow('Round off Tax', '₹ ${roundOffTax.toStringAsFixed(2)}', false),
            ],
            if (chargesTotal != 0) ...[
              const SizedBox(height: 3),
              _summaryRow('Add on total', '₹ ${chargesTotal.toStringAsFixed(2)}', false),
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
        Text(label, style: TextStyle(fontSize: isTotal ? 14 : 13, fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: AppColors.primaryDark)),
      ],
    );
  }
}

// ─── Link Sales Order Dialog ──────────────────────────────────────────────────

Future<void> _showLinkToSalesOrderDialog(
  BuildContext context,
  SalesInvoiceController controller,
) async {
  final custId = controller.customerId.value;
  if (custId == null) {
    Get.snackbar(
      'Select Customer',
      'Please select a customer first to view their orders.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  final list = await controller.fetchSalesOrdersForLink(customerId: custId);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _LinkToSODialog(
      list: list,
      customerId: custId,
      controller: controller,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

class _LinkToSODialog extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final int customerId;
  final SalesInvoiceController controller;
  final VoidCallback onClose;

  const _LinkToSODialog({
    required this.list,
    required this.customerId,
    required this.controller,
    required this.onClose,
  });

  @override
  State<_LinkToSODialog> createState() => _LinkToSODialogState();
}

class _LinkToSODialogState extends State<_LinkToSODialog> {
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  final Set<int> _selectedSoIds = <int>{};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.list);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = query.trim();
      setState(() => _loading = true);
      final results = await widget.controller.fetchSalesOrdersForLink(
        search: q.isEmpty ? null : q,
        customerId: widget.customerId,
      );
      if (!mounted) return;

      final lower = q.toLowerCase();
      final filtered = q.isEmpty
          ? results
          : results.where((so) {
              final soNo = (so['so_number'] ?? '').toString().toLowerCase();
              final idStr = (so['id'] ?? '').toString().toLowerCase();
              return soNo.contains(lower) || idStr.contains(lower);
            }).toList();

      setState(() {
        _loading = false;
        _items
          ..clear()
          ..addAll(filtered);
      });
    });
  }

  Future<void> _onLinkSelected(BuildContext context) async {
    if (_selectedSoIds.isEmpty) return;

    final nav = Navigator.of(context);
    setState(() => _loading = true);

    final orderedIds = <int>[];
    for (final so in _items) {
      final id = so['id'] as int?;
      if (id != null && _selectedSoIds.contains(id)) orderedIds.add(id);
    }
    for (final id in _selectedSoIds) {
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    final salesOrders = <SalesOrder>[];
    for (final soId in orderedIds) {
      final so = await widget.controller.fetchSalesOrderById(soId);
      if (so != null) salesOrders.add(so);
    }

    if (!mounted) return;

    if (salesOrders.isEmpty) {
      setState(() => _loading = false);
      Get.snackbar(
        'Error',
        'Could not load selected order details.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Keep loading=true while populating form rows (product fetches happen here)
    await widget.controller.loadFromSalesOrders(salesOrders);

    if (!mounted) return;
    setState(() => _loading = false);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalInset = screenWidth < 600 ? 12.0 : 24.0;
    final availableDialogWidth = screenWidth - (horizontalInset * 2);
    final dialogWidth = availableDialogWidth > 520
        ? 520.0
        : (availableDialogWidth < 280 ? 280.0 : availableDialogWidth);
    final dialogHeight = screenHeight < 720
        ? 330.0
        : (screenHeight * 0.52).clamp(330.0, 380.0);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      title: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedSoIds.isEmpty
                  ? 'Link Sales Order'
                  : 'Link Sales Order (${_selectedSoIds.length} selected)',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading orders...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: _siInputDecoration(
                      labelText: 'Search by Order # or ID',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text(
                              'No orders found for this customer.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final so = _items[index];
                              final id = so['id'] as int?;
                              final soNumber = so['so_number']?.toString() ?? 'Order';
                              final docDate = so['doc_date']?.toString() ?? '';
                              final status = so['status']?.toString() ?? '';
                              final total = so['total_amount'];
                              if (id == null) return const SizedBox.shrink();
                              final formattedDate = _formatSoDate(docDate);
                              final totalStr = total != null
                                  ? '₹ ${(total is num ? total.toDouble() : double.tryParse(total.toString()) ?? 0).toStringAsFixed(2)}'
                                  : '';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryDark),
                                ),
                                title: Text(
                                  soNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  [
                                    if (formattedDate.isNotEmpty) formattedDate,
                                    if (status.isNotEmpty) status,
                                    if (totalStr.isNotEmpty) totalStr,
                                  ].where((e) => e.isNotEmpty).join(' · '),
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Checkbox(
                                  value: _selectedSoIds.contains(id),
                                  onChanged: _loading
                                      ? null
                                      : (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedSoIds.add(id);
                                            } else {
                                              _selectedSoIds.remove(id);
                                            }
                                          });
                                        },
                                ),
                                onTap: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_selectedSoIds.contains(id)) {
                                            _selectedSoIds.remove(id);
                                          } else {
                                            _selectedSoIds.add(id);
                                          }
                                        });
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _loading || _selectedSoIds.isEmpty
              ? null
              : () => _onLinkSelected(context),
          child: const Text('Ok'),
        ),
        TextButton(
          onPressed: _loading ? null : widget.onClose,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _formatSoDate(String rawValue) {
  final raw = rawValue.trim();
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}
