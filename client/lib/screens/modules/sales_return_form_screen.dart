import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_return_form_controller.dart';
import '../../models/party_result.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

InputDecoration _srInputDecoration({
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
  ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always);
}

const double _sectionGap = 10;
const double _headerFieldGap = 10;

Future<void> _pickReturnDate(
  BuildContext context,
  SalesReturnFormController controller,
) async {
  final now = DateTime.now();
  DateTime initialDate = now;
  final raw = controller.docDate.value.trim();
  if (raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) initialDate = parsed;
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
  controller.docDate.value = '${picked.year}-$month-$day';
}

Future<void> _showSalesInvoiceSelector(
  BuildContext context,
  SalesReturnFormController controller,
) async {
  final customerId = controller.customerId.value;
  if (customerId == null) {
    Get.snackbar(
      'Select Customer',
      'Please select a customer first.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _SISelectorDialog(controller: controller, customerId: customerId),
  );

  if (result != null) {
    final siId = result['id'] as int?;
    if (siId != null) {
      await controller.loadSalesInvoiceItems(siId);
    }
  }
}

class SalesReturnFormScreen extends StatelessWidget {
  final int? returnId;
  final int? sourceSiId;
  final bool startInViewOnly;

  const SalesReturnFormScreen({
    super.key,
    this.returnId,
    this.sourceSiId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SalesReturnFormController(
        returnId: returnId,
        sourceSiId: sourceSiId,
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
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit',
                  onPressed: controller.canEditFromView ? controller.enterEditMode : null,
                ),
              ],
            );
          }),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Select a customer first, then choose one of that customer\'s sales invoices and enter return quantities.',
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
                Text('Loading...', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                  child: _SalesReturnReportView(controller: controller),
                ),
              ),
              ActionButtonBar(
                buttons: [
                  ActionButton(label: 'Back', onPressed: () => Get.back()),
                  if (controller.canEditFromView)
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(controller: controller, context: context),
                      const SizedBox(height: _sectionGap),
                      _ItemsCard(controller: controller),
                      const SizedBox(height: _sectionGap),
                      _ReasonsCard(controller: controller),
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
                      onPressed: controller.isSaving.value ? null : () => Get.back(),
                    ),
                    ActionButton(
                      label: 'Save as Draft',
                      isPrimary: true,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.isSaving.value ? null : () => controller.saveSalesReturn(post: false),
                    ),
                    ActionButton(
                      label: 'Post',
                      isPrimary: true,
                      backgroundColor: AppColors.primaryDark,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.isSaving.value ? null : () => controller.saveSalesReturn(post: true),
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

class _HeaderCard extends StatelessWidget {
  final SalesReturnFormController controller;
  final BuildContext context;

  const _HeaderCard({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Return Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormField<int>(
            initialValue: controller.customerId.value,
            validator: (v) => v == null ? 'Please select customer' : null,
            builder: (state) {
              final locked = controller.isReadOnly || controller.isEditMode;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: locked
                        ? null
                        : () async {
                            final party = await showDialog<PartyResult>(
                              context: context,
                              builder: (_) => PartySearchDialog(
                                title: 'Select Customer',
                                hint: 'Search by name, phone or ID...',
                                searchFn: controller.searchCustomers,
                              ),
                            );
                            if (party != null) {
                              await controller.setCustomerWithName(party.id, party.name);
                              state.didChange(party.id);
                              state.validate();
                            }
                          },
                    child: InputDecorator(
                      decoration: _srInputDecoration(labelText: 'Customer *'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              final selectedId = controller.customerId.value;
                              final selectedName = controller.customerName.value;
                              return Text(
                                selectedId == null ? 'Tap to select...' : selectedName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedId == null ? Colors.grey : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                          ),
                          if (!locked)
                            const Icon(Icons.search, size: 18, color: Colors.grey),
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
          ),
          const SizedBox(height: _headerFieldGap),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickReturnDate(context, controller),
                  child: Obx(
                    () => InputDecorator(
                      decoration: _srInputDecoration(labelText: 'Return Date').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        controller.docDate.value.isEmpty ? 'Select date' : controller.docDate.value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _headerFieldGap),
          Obx(
            () => GestureDetector(
              onTap: controller.customerId.value == null
                  ? () {
                      Get.snackbar(
                        'Select Customer',
                        'Please select a customer first.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                    }
                  : () => _showSalesInvoiceSelector(context, controller),
              child: InputDecorator(
                decoration: _srInputDecoration(
                  labelText: 'Source Sales Invoice',
                  suffixIcon: controller.isSearchingInvoices.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                child: Text(
                  controller.sourceSiNumber.value.isEmpty
                      ? 'Select a sales invoice'
                      : controller.sourceSiNumber.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: controller.sourceSiNumber.value.isEmpty ? AppColors.textMuted : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _headerFieldGap),
          Obx(
            () => InputDecorator(
              decoration: _srInputDecoration(labelText: 'Return Number'),
              child: Text(
                controller.customerId.value == null
                    ? 'Select customer first'
                    : '${controller.docNoPrefix.value}${controller.docNoNumber.value}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SalesReturnFormController controller;

  const _ItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Return Items',
      child: Obx(() {
        if (controller.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No items added. Please select a sales invoice first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 820),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.primaryLighter.withValues(alpha: 0.25)),
              dataRowMinHeight: 40,
              dataRowMaxHeight: 56,
              columnSpacing: 6,
              horizontalMargin: 8,
              headingRowHeight: 36,
              columns: const [
                DataColumn(label: Text('')),
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Invoiced')),
                DataColumn(label: Text('Return Qty')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Action')),
              ],
              rows: List<DataRow>.generate(controller.items.length, (i) {
                final row = controller.items[i];
                final origQty = double.tryParse(row.originalQty.value) ?? 0;
                final availableQty = double.tryParse(row.availableQty.value) ?? origQty;
                final maxQty = availableQty > 0 ? availableQty : origQty;
                final details = [
                  if (row.unitType.value.isNotEmpty) row.unitType.value,
                  if (row.productCode.value.isNotEmpty) row.productCode.value,
                ].join(' • ');

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (!row.selected.value) return AppColors.primaryLighter.withValues(alpha: 0.08);
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Checkbox(
                        value: row.selected.value,
                        onChanged: controller.isReadOnly
                            ? null
                            : (checked) => controller.setItemSelected(i, checked ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    DataCell(Text('${i + 1}')),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              row.productName.value.isEmpty ? '-' : row.productName.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (details.isNotEmpty)
                              Text(details, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(origQty.toStringAsFixed(2))),
                    DataCell(
                      SizedBox(
                        width: 74,
                        child: TextFormField(
                          initialValue: row.returnedQty.value,
                          onChanged: (v) => row.returnedQty.value = v,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          enabled: row.selected.value,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                          validator: (value) {
                            if (!row.selected.value) return null;
                            final qty = double.tryParse(value?.trim() ?? '') ?? 0;
                            if (qty < 0) return 'Invalid';
                            if (qty > maxQty) return 'Max ${maxQty.toStringAsFixed(2)}';
                            return null;
                          },
                          onTap: row.selected.value ? null : () => controller.setItemSelected(i, true),
                          decoration: InputDecoration(
                            hintText: '0',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 132,
                        child: TextFormField(
                          initialValue: row.returnReason.value,
                          onChanged: (v) => row.returnReason.value = v,
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'e.g. Damage',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => controller.removeItemRow(i),
                        tooltip: 'Remove',
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      }),
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  final SalesReturnFormController controller;

  const _ReasonsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Return Reason',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TextFormField(
              initialValue: controller.reason.value,
              onChanged: (v) => controller.reason.value = v,
              maxLines: 2,
              decoration: _srInputDecoration(
                labelText: 'Return Reason',
                hintText: 'e.g., Defective items, over-delivery, quality issue',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SalesReturnFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Summary',
      child: Obx(
        () => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Return Value',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  '₹ ${controller.totalReturnValue}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: controller.status.value == 'DRAFT'
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: controller.status.value == 'DRAFT' ? Colors.blue : Colors.green,
                    ),
                  ),
                  child: Text(
                    controller.status.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: controller.status.value == 'DRAFT' ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesReturnReportView extends StatelessWidget {
  final SalesReturnFormController controller;

  const _SalesReturnReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final docNo = '${controller.docNoPrefix.value}${controller.docNoNumber.value}';
      final rows = controller.items;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Sales Return Document',
            child: Column(
              children: [
                _metaRow('Return No', docNo.trim().isEmpty ? '-' : docNo),
                _metaRow('Status', controller.status.value),
                _metaRow('Customer', controller.customerName.value.isEmpty ? '-' : controller.customerName.value),
                _metaRow('Source SI', controller.sourceSiNumber.value.isEmpty ? '-' : controller.sourceSiNumber.value),
                _metaRow('Return Date', controller.docDate.value.isEmpty ? '-' : controller.docDate.value),
                _metaRow('Reason', controller.reason.value.isEmpty ? '-' : controller.reason.value, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          ContentCard(
            title: 'Return Items',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.primaryLighter.withValues(alpha: 0.25)),
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 56,
                  columnSpacing: 6,
                  horizontalMargin: 8,
                  headingRowHeight: 36,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Invoiced')),
                    DataColumn(label: Text('Returned')),
                    DataColumn(label: Text('Reason')),
                  ],
                  rows: List<DataRow>.generate(rows.length, (i) {
                    final row = rows[i];
                    final origQty = double.tryParse(row.originalQty.value) ?? 0;
                    final returnQty = double.tryParse(row.returnedQty.value) ?? 0;

                    return DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(SizedBox(
                        width: 140,
                        child: Text(row.productName.value.isEmpty ? '-' : row.productName.value,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(Text(origQty.toStringAsFixed(2))),
                      DataCell(Text(returnQty.toStringAsFixed(2))),
                      DataCell(SizedBox(
                        width: 120,
                        child: Text(row.returnReason.value.isEmpty ? '-' : row.returnReason.value,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: _sectionGap),
          _SummaryCard(controller: controller),
        ],
      );
    });
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
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SISelectorDialog extends StatefulWidget {
  final SalesReturnFormController controller;
  final int customerId;

  const _SISelectorDialog({required this.controller, required this.customerId});

  @override
  State<_SISelectorDialog> createState() => _SISelectorDialogState();
}

class _SISelectorDialogState extends State<_SISelectorDialog> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search('');
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _search(String query) async {
    setState(() => isSearching = true);
    final results = await widget.controller.searchSalesInvoices(
      query,
      customerIdFilter: widget.customerId,
    );
    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Sales Invoice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                Text(
                  'Showing invoices for selected customer',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: _search,
              decoration: AppInputDecoration.standard(
                labelText: 'Search Invoice',
                hintText: 'Type invoice number...',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSearching
                    ? const Center(
                        key: ValueKey('sr_invoice_loading'),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : searchResults.isEmpty
                    ? Container(
                        key: const ValueKey('sr_invoice_empty'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.45)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              searchController.text.isEmpty
                                  ? 'Start typing to filter invoices'
                                  : 'No invoices found for this search',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey('sr_invoice_list'),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final si = searchResults[i];
                          final docNo = si['doc_no_number']?.toString() ?? '';
                          final customerName = si['customer_name']?.toString() ?? '-';
                          final docDate = si['doc_date']?.toString() ?? '-';

                          return Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.pop(ctx, si),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.45)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description_outlined, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              docNo.isEmpty ? 'Invoice' : docNo,
                                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$customerName • $docDate',
                                              style: const TextStyle(color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
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
