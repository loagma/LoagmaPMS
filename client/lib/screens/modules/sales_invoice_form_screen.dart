import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_invoice_form_controller.dart';
import '../../models/customer_model.dart';
import '../../models/party_result.dart';
import '../../models/product_model.dart';
import '../../services/customer_api_service.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_invoice_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

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
  ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always);
}

const double _fieldGap = 10;
const double _fieldVerticalGap = 6;
const double _sectionGap = 10;

Future<void> _pickSiDate(
  BuildContext context, {
  required String currentValue,
  required ValueChanged<String> onPicked,
}) async {
  final now = DateTime.now();
  DateTime initialDate = now;
  final raw = currentValue.trim();
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
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  onPicked('${picked.year}-$m-$d');
}

String _normalizeDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '-';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text.length >= 10 ? text.substring(0, 10) : text;
  final local = parsed.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SalesInvoiceFormScreen extends StatelessWidget {
  final int? soId;
  final bool startInViewOnly;

  const SalesInvoiceFormScreen({
    super.key,
    this.soId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final tag = soId?.toString() ?? 'new';
    Get.delete<SalesInvoiceFormController>(tag: tag, force: true);
    final controller = Get.put(
      SalesInvoiceFormController(soId: soId, viewOnly: startInViewOnly),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Obx(() {
        if (controller.isReadOnly) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            heroTag: 'si_add_item_fab',
            onPressed: controller.addItem,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Add Product',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Sales Invoice' : 'Create Sales Invoice',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final busy = controller.isPdfBusy.value;
            final hasInvoice = controller.invoiceNumber.value.trim().isNotEmpty;
            if (!hasInvoice) {
              return IconButton(
                icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                tooltip: 'View all invoices',
                onPressed: () => Get.to(() => const SalesInvoiceListScreen()),
              );
            }
            return Row(mainAxisSize: MainAxisSize.min, children: [
              busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.print_outlined, color: Colors.white),
                      tooltip: 'Print / Download PDF',
                      onPressed: () async {
                        controller.isPdfBusy.value = true;
                        try { await ReportExportService.printSalesInvoice(controller); }
                        finally { controller.isPdfBusy.value = false; }
                      },
                    ),
              if (!busy)
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: 'Share PDF',
                  onPressed: () async {
                    controller.isPdfBusy.value = true;
                    try { await ReportExportService.shareSalesInvoice(controller); }
                    finally { controller.isPdfBusy.value = false; }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                tooltip: 'View all invoices',
                onPressed: () => Get.to(() => const SalesInvoiceListScreen()),
              ),
            ]);
          }),
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
                  child: _SalesInvoiceReportView(controller: controller),
                ),
              ),
              ActionButtonBar(
                buttons: [
                  ActionButton(
                    label: 'Back',
                    onPressed: () => Get.back(),
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
              Obx(() => ActionButtonBar(
                    buttons: [
                      ActionButton(
                        label: 'Cancel',
                        onPressed: controller.isSaving.value ? null : () => Get.back(),
                      ),
                      ActionButton(
                        label: 'Save',
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

// ─────────────────────────────────────────────────────────────────────────────
// Report view (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class _SalesInvoiceReportView extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _SalesInvoiceReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final invoiceNo = controller.invoiceNumber.value.trim().isEmpty
          ? '-'
          : controller.invoiceNumber.value.trim();
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
                _metaRow('Invoice No', invoiceNo),
                _metaRow('Status', controller.status.value),
                _metaRow('Customer', customerLabel),
                _metaRow('Document Date', _normalizeDate(controller.docDate.value)),
                _metaRow('Expected Date', _normalizeDate(controller.expectedDate.value)),
                _metaRow('Financial Year', controller.financialYear.value),
                _metaRow('Narration',
                    controller.narration.value.trim().isEmpty ? '-' : controller.narration.value.trim(),
                    isLast: !controller.isBillMode),
                if (controller.isBillMode) ...[
                  _metaRow('Bill Date',
                      controller.billDt.value.isEmpty ? '-' : _normalizeDate(controller.billDt.value)),
                  _metaRow('Department',
                      controller.billDepartment.value.isEmpty ? '-' : controller.billDepartment.value),
                  _metaRow('Bill Narration',
                      controller.billNarration.value.isEmpty ? '-' : controller.billNarration.value),
                  _metaRow('Vehicle',
                      controller.billVehicle.value.isEmpty ? '-' : controller.billVehicle.value),
                  _metaRow('Bill Statement',
                      controller.billStatement.value.isEmpty ? '-' : controller.billStatement.value),
                  _metaRow('Round Off',
                      controller.billRoff.value.isEmpty ? '0' : controller.billRoff.value),
                  _metaRow('Doc Year',
                      controller.billDocYear.value.isEmpty ? '-' : controller.billDocYear.value,
                      isLast: true),
                ],
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
                  dataRowMaxHeight: 62,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('HSN')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Disc %')),
                    DataColumn(label: Text('Tax %')),
                    DataColumn(label: Text('Taxable')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: List<DataRow>.generate(controller.items.length, (i) {
                    final row = controller.items[i];
                    final qty = row.deliveredQtyDouble;
                    final rate = row.priceDouble;
                    final disc = double.tryParse(row.discountPercent.value) ?? 0;
                    final tax = double.tryParse(row.taxPercent.value) ?? 0;
                    return DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(SizedBox(
                          width: 170,
                          child: Text(
                              row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis))),
                      DataCell(Text(row.productCode.value.trim().isEmpty ? '-' : row.productCode.value.trim())),
                      DataCell(Text(row.unit.value.trim().isEmpty ? '-' : row.unit.value.trim())),
                      DataCell(Text(qty.toStringAsFixed(1))),
                      DataCell(Text(rate.toStringAsFixed(2))),
                      DataCell(Text(disc.toStringAsFixed(2))),
                      DataCell(Text(tax.toStringAsFixed(2))),
                      DataCell(Text(row.lineTotalExclTax.toStringAsFixed(2))),
                      DataCell(Text(row.lineTotal.toStringAsFixed(2))),
                    ]);
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
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
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
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer detail sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showCustomerDetailSheet(
  BuildContext context,
  int customerId,
  SalesInvoiceFormController controller,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomerDetailSheet(
      customerId: customerId,
      controller: controller,
    ),
  );
}

class _CustomerDetailSheet extends StatefulWidget {
  final int customerId;
  final SalesInvoiceFormController controller;

  const _CustomerDetailSheet({
    required this.customerId,
    required this.controller,
  });

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  Customer? _customer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await CustomerApiService.fetchCustomerById(widget.customerId);
    if (mounted) setState(() { _customer = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Customer Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _customer == null
                      ? const Center(child: Text('Unable to load customer details'))
                      : _buildContent(scrollCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController scrollCtrl) {
    final c = _customer!;
    final isEdit = !widget.controller.isReadOnly;

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CustomerInfoHeader(customer: c),
        const SizedBox(height: 16),
        _infoSection('Contact', [
          if (c.contactNumber?.isNotEmpty == true)
            _infoRow(Icons.phone, 'Phone', c.contactNumber!),
          if (c.alternatePhone?.isNotEmpty == true)
            _infoRow(Icons.phone_android, 'Alternate', c.alternatePhone!),
          if (c.email?.isNotEmpty == true)
            _infoRow(Icons.email_outlined, 'Email', c.email!),
        ]),
        if (_hasAddress(c)) ...[
          const SizedBox(height: 12),
          _infoSection('Address', [
            if (c.addressLine1?.isNotEmpty == true)
              _infoRow(Icons.location_on_outlined, 'Address', c.addressLine1!),
            if (c.city?.isNotEmpty == true || c.state?.isNotEmpty == true)
              _infoRow(Icons.map_outlined, 'City / State',
                  [c.city, c.state].where((s) => s?.isNotEmpty == true).join(', ')),
            if (c.pincode?.isNotEmpty == true)
              _infoRow(Icons.pin_drop_outlined, 'Pincode', c.pincode!),
          ]),
        ],
        if (c.gstNo?.isNotEmpty == true || c.panNo?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _infoSection('Tax Info', [
            if (c.gstNo?.isNotEmpty == true)
              _infoRow(Icons.receipt_long_outlined, 'GST No', c.gstNo!),
            if (c.panNo?.isNotEmpty == true)
              _infoRow(Icons.credit_card_outlined, 'PAN No', c.panNo!),
          ]),
        ],
        if (isEdit) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Change Customer'),
            onPressed: () async {
              Navigator.of(context).pop();
              final party = await showDialog<PartyResult>(
                context: context,
                builder: (_) => PartySearchDialog(
                  title: 'Select Customer',
                  hint: 'Search by name, phone or ID...',
                  searchFn: widget.controller.searchCustomers,
                ),
              );
              if (party != null) {
                widget.controller.setCustomer(party.id, party.name,
                    phone: party.phone, shopName: party.shopName);
              }
            },
          ),
        ],
      ],
    );
  }

  bool _hasAddress(Customer c) =>
      c.addressLine1?.isNotEmpty == true ||
      c.city?.isNotEmpty == true ||
      c.state?.isNotEmpty == true ||
      c.pincode?.isNotEmpty == true;

  Widget _infoSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _CustomerInfoHeader extends StatelessWidget {
  final Customer customer;
  const _CustomerInfoHeader({required this.customer});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name.isNotEmpty ? customer.name : (customer.shopName ?? '?'));
    final statusColor = customer.status == 'ACTIVE' ? Colors.green : Colors.orange;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.name.isNotEmpty)
                Text(customer.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (customer.shopName?.isNotEmpty == true)
                Text(customer.shopName!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('ID: ${customer.id}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(customer.status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card — full replica of SO _HeaderCard
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Customer & Dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Financial Year + Invoice Number ────────────────────────
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
                      decoration: _siInputDecoration(labelText: 'Financial Year'),
                      isExpanded: true,
                      items: options
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: controller.isReadOnly
                          ? null
                          : (v) { if (v != null) controller.setFinancialYear(v); },
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: Obx(() => InputDecorator(
                        decoration: _siInputDecoration(labelText: 'Invoice No'),
                        child: Text(
                          controller.invoiceNumber.value.isEmpty
                              ? 'Generating…'
                              : controller.invoiceNumber.value,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),

          // ── Customer picker ───────────────────────────────────────────────
          FormField<int>(
            initialValue: controller.customerId.value,
            validator: (v) => v == null ? 'Please select customer' : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final selectedId = controller.customerId.value;
                    if (selectedId != null) {
                      await _showCustomerDetailSheet(context, selectedId, controller);
                      return;
                    }
                    if (controller.isReadOnly) return;
                    final party = await showDialog<PartyResult>(
                      context: context,
                      builder: (_) => PartySearchDialog(
                        title: 'Select Customer',
                        hint: 'Search by name, phone or ID...',
                        searchFn: controller.searchCustomers,
                      ),
                    );
                    if (party != null) {
                      controller.setCustomer(party.id, party.name,
                          phone: party.phone, shopName: party.shopName);
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
                              return const Text('Tap to select...',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis);
                            }
                            final title = controller.customerDisplayTitle;
                            final subtitle = controller.customerDisplaySubtitle;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(title,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(subtitle,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            );
                          }),
                        ),
                        if (!controller.isReadOnly)
                          const Icon(Icons.search, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(state.errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),

          // ── Department ────────────────────────────────────────────────────
          Obx(() {
            final list = controller.departments;
            final current = controller.departmentId.value;
            final hasValue = list.any((d) => d['id']?.toString() == current?.toString());
            final value = hasValue ? current : null;
            return DropdownButtonFormField<String>(
              value: value,
              decoration: _siInputDecoration(labelText: 'Department'),
              items: list
                  .map((d) => DropdownMenuItem<String>(
                        value: d['id']?.toString(),
                        child: Text(d['name']?.toString() ?? 'Department',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: controller.isReadOnly
                  ? null
                  : (v) => controller.setDepartmentId(v),
            );
          }),
          const SizedBox(height: _sectionGap),

          // ── Salesman ──────────────────────────────────────────────────────
          Obx(() {
            final name = controller.salesmanName.value.trim();
            return InkWell(
              onTap: controller.isReadOnly
                  ? null
                  : () async {
                      final party = await showDialog<PartyResult>(
                        context: context,
                        builder: (_) => PartySearchDialog(
                          title: 'Select Salesman',
                          hint: 'Search by name...',
                          headerIcon: Icons.person_outlined,
                          searchFn: controller.searchSalesmen,
                        ),
                      );
                      if (party != null) {
                        controller.setSalesman(party.id.toString(), party.name);
                      }
                    },
              child: InputDecorator(
                decoration: _siInputDecoration(labelText: 'Salesman').copyWith(
                  suffixIcon: controller.isReadOnly
                      ? null
                      : name.isEmpty
                          ? const Icon(Icons.search, size: 18, color: Colors.grey)
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () => controller.setSalesman(null, ''),
                            ),
                ),
                child: Text(
                  name.isEmpty ? 'Tap to select...' : name,
                  style: TextStyle(fontSize: 14, color: name.isEmpty ? Colors.grey : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
          const SizedBox(height: _sectionGap),

          // ── Source Order picker (only for new invoices) ───────────────────
          if (controller.soId == null) ...[
            _OrderField(controller: controller),
            const SizedBox(height: _sectionGap),
          ],

          // ── Document Date + Expected Date ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('si-doc-date-${controller.docDate.value}'),
                      enabled: !controller.isReadOnly,
                      readOnly: true,
                      initialValue: controller.docDate.value,
                      decoration: _siInputDecoration(
                        labelText: 'Document Date *',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: controller.isReadOnly
                          ? null
                          : () => _pickSiDate(context,
                              currentValue: controller.docDate.value,
                              onPicked: controller.setDocDate),
                    )),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('si-expected-date-${controller.expectedDate.value}'),
                      enabled: !controller.isReadOnly,
                      readOnly: true,
                      initialValue: controller.expectedDate.value,
                      decoration: _siInputDecoration(
                        labelText: 'Expected Date',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      onTap: controller.isReadOnly
                          ? null
                          : () => _pickSiDate(context,
                              currentValue: controller.expectedDate.value,
                              onPicked: controller.setExpectedDate),
                    )),
              ),
            ],
          ),

          // ── Status (only in edit mode) ────────────────────────────────────
          if (controller.isEditMode) ...[
            const SizedBox(height: _sectionGap),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.status.value,
                  decoration: _siInputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                    DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'BILLED', child: Text('Billed')),
                    DropdownMenuItem(
                        value: 'PARTIALLY_INVOICED', child: Text('Partially invoiced')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: controller.isReadOnly
                      ? null
                      : (v) { if (v != null) controller.setStatus(v); },
                )),
          ],
          const SizedBox(height: _sectionGap),

          // ── Narration ─────────────────────────────────────────────────────
          Obx(() => TextFormField(
                enabled: !controller.isReadOnly,
                initialValue: controller.narration.value,
                decoration: _siInputDecoration(labelText: 'Narration').copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                minLines: 1,
                maxLines: 1,
                onChanged: controller.setNarration,
              )),

          // ── Bill / Invoice fields — shown only when status is BILLED ──────
          Obx(() {
            if (!controller.isBillMode) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: _sectionGap),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Bill / Invoice Details',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                ),
                const SizedBox(height: _sectionGap),
                // Bill Date
                Obx(() => InkWell(
                      onTap: controller.isReadOnly
                          ? null
                          : () => _pickSiDate(context,
                              currentValue: controller.billDt.value,
                              onPicked: controller.setBillDt),
                      child: InputDecorator(
                        decoration: _siInputDecoration(labelText: 'Bill Date'),
                        child: Text(
                          controller.billDt.value.isEmpty
                              ? 'Select date'
                              : controller.billDt.value,
                          style: TextStyle(
                              fontSize: 14,
                              color: controller.billDt.value.isEmpty
                                  ? Colors.grey
                                  : null),
                        ),
                      ),
                    )),
                const SizedBox(height: _sectionGap),
                _ObsField(obs: controller.billDepartment, label: 'Department', readOnly: controller.isReadOnly),
                const SizedBox(height: _sectionGap),
                _ObsField(obs: controller.billNarration, label: 'Bill Narration', readOnly: controller.isReadOnly),
                const SizedBox(height: _sectionGap),
                _ObsField(obs: controller.billVehicle, label: 'Vehicle', readOnly: controller.isReadOnly),
                const SizedBox(height: _sectionGap),
                _ObsField(obs: controller.billStatement, label: 'Bill Statement', readOnly: controller.isReadOnly),
                const SizedBox(height: _sectionGap),
                _ObsField(
                  obs: controller.billRoff,
                  label: 'Round Off',
                  readOnly: controller.isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,2}'))],
                ),
                const SizedBox(height: _sectionGap),
                _ObsField(obs: controller.billDocYear, label: 'Doc Year (e.g. 25-26)', readOnly: controller.isReadOnly),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order picker field
// ─────────────────────────────────────────────────────────────────────────────

class _OrderField extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _OrderField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
          onTap: controller.isReadOnly ? null : () => _showOrderPicker(context),
          child: InputDecorator(
            decoration: _siInputDecoration(
              labelText: 'Source Order (optional)',
              suffixIcon: controller.isReadOnly
                  ? null
                  : const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
            ),
            child: Text(
              controller.sourceOrderNumber.value.isEmpty
                  ? (controller.isReadOnly ? '-' : 'Tap to link a sales order')
                  : controller.sourceOrderNumber.value,
              style: TextStyle(
                  fontSize: 14,
                  color: controller.sourceOrderNumber.value.isEmpty ? Colors.grey : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
  }

  Future<void> _showOrderPicker(BuildContext context) async {
    // Pre-populate from cached availableOrders; still allows searching
    List<Map<String, dynamic>> results = List.of(controller.availableOrders);
    bool loading = results.isEmpty;
    bool didInit = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> doSearch(String q) async {
            if (!ctx.mounted) return;
            setState(() => loading = true);
            results = await controller.searchOrders(q);
            if (!ctx.mounted) return;
            setState(() => loading = false);
          }

          if (loading && !didInit) {
            didInit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => doSearch(''));
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (_, scroll) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('Select Pending Order',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by order number…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => doSearch(v),
                    ),
                  ),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    message: 'No pending orders found',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scroll,
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final o = results[i];
                                  final orderNo = o['so_number']?.toString() ?? 'ORD-${o['id']}';
                                  final customer = o['customer_name']?.toString() ?? '';
                                  final soStatus = o['status']?.toString() ?? '';
                                  final date = _normalizeDate(o['doc_date']?.toString() ?? '');
                                  final total = o['total_amount'];
                                  final totalStr = total != null
                                      ? '₹ ${(double.tryParse(total.toString()) ?? 0).toStringAsFixed(2)}'
                                      : '';
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        final id = o['id'] is int
                                            ? o['id'] as int
                                            : int.tryParse(o['id']?.toString() ?? '');
                                        if (id != null) {
                                          Navigator.pop(ctx);
                                          controller.loadOrder(id);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.receipt_long_outlined,
                                                  color: AppColors.primary, size: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(orderNo,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                          color: AppColors.primaryDark)),
                                                  if (customer.isNotEmpty)
                                                    Text(customer,
                                                        style: const TextStyle(
                                                            fontSize: 12, color: AppColors.textMuted)),
                                                  Text('$soStatus  •  $date',
                                                      style: const TextStyle(
                                                          fontSize: 11, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                if (totalStr.isNotEmpty)
                                                  Text(totalStr,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.primaryDark)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text('Use',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Items card
// ─────────────────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

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
            if (!controller.isReadOnly) const SizedBox(height: _sectionGap),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item row — full replica of SO _ItemRow
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final SalesInvoiceFormController controller;
  final int index;
  final SILineRow row;
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
            color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item badge + delete
          Row(
            children: [
              Obx(() {
                final hsn = row.productCode.value.trim();
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
                        color: AppColors.primaryDark),
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

          // Product picker
          _ProductPicker(controller: controller, row: row, readOnly: controller.isReadOnly),

          // Tax loading indicator
          Obx(() {
            if (!row.isTaxLoading.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(top: _sectionGap),
              child: Row(
                children: [
                  SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 6),
                  Text('Fetching taxes...',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            );
          }),
          const SizedBox(height: _sectionGap),

          // Qty row: Ordered Qty (read-only from SO) + Qty Delivered + Unit + Unit Price
          Row(
            children: [
              // Ordered Qty — only shown when item came from a linked SO
              Obx(() => row.orderedQtyDouble > 0
                  ? Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                        child: TextFormField(
                          key: ValueKey('oq_${row.orderedQty.value}'),
                          enabled: false,
                          initialValue: row.orderedQty.value,
                          decoration: _siInputDecoration(labelText: 'SO Qty'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              Obx(() => row.orderedQtyDouble > 0
                  ? const SizedBox(width: _fieldGap)
                  : const SizedBox.shrink()),

              // Qty Delivered
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => TextFormField(
                        enabled: !controller.isReadOnly,
                        initialValue: row.qtyDelivered.value,
                        decoration: _siInputDecoration(labelText: 'Inv Qty *'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,3}'))
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final q = double.tryParse(v);
                          if (q == null || q <= 0) return 'Must be > 0';
                          return null;
                        },
                        onChanged: (v) => row.qtyDelivered.value = v,
                      )),
                ),
              ),
              const SizedBox(width: _fieldGap),

              // Unit
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() {
                    final base = controller.unitTypes.isEmpty
                        ? ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML']
                        : controller.unitTypes;
                    final current = row.unit.value.trim();
                    final units = <String>{
                      if (current.isNotEmpty) current,
                      ...base,
                    }.toList();
                    final value = current.isNotEmpty ? current : units.first;
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: _siInputDecoration(labelText: 'Unit').copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                      ),
                      isDense: true,
                      isExpanded: true,
                      iconSize: 16,
                      items: units
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: controller.isReadOnly
                          ? null
                          : (v) { if (v != null) row.unit.value = v; },
                    );
                  }),
                ),
              ),
              const SizedBox(width: _fieldGap),

              // Unit Price
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => TextFormField(
                        enabled: !controller.isReadOnly,
                        initialValue: row.price.value,
                        decoration: _siInputDecoration(labelText: 'Rate *'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
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

          // Tax breakdown rows
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

  Widget _buildTaxRows(SILineRow row) {
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 2,
                  child: Text('Tax %',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 2,
                  child: Text('Tax Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
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
                Expanded(
                    flex: 3,
                    child: Text(key, style: const TextStyle(fontSize: 11))),
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

  Widget _buildTaxTotals(SILineRow row) {
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
      decoration: _siInputDecoration(labelText: label),
      child: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product picker — full replica of SO _ProductPicker
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPicker extends StatefulWidget {
  final SalesInvoiceFormController controller;
  final SILineRow row;
  final bool readOnly;

  const _ProductPicker({
    required this.controller,
    required this.row,
    required this.readOnly,
  });

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  bool _showAllProducts = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final row = widget.row;
    final readOnly = widget.readOnly;

    final hasSupplierFilter =
        controller.salesmanId.value != null && controller.salesmanId.value!.isNotEmpty;

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
                      final selections = await showDialog<List<ProductSelection>>(
                        context: context,
                        useRootNavigator: true,
                        builder: (ctx) => ProductSearchDialog(
                          title: 'Select Products',
                          searchFn: controller.searchProductsAsModels,
                          allProductsSearchFn: hasSupplierFilter
                              ? controller.searchAllProductsUnfiltered
                              : null,
                          allowMultiSelect: true,
                          showSupplierToggle: hasSupplierFilter,
                          supplierToggleValue: _showAllProducts,
                          onSupplierToggle: (v) => setState(() => _showAllProducts = v),
                        ),
                      );
                      if (selections == null || selections.isEmpty) return;

                      final first = selections.first;
                      row.productId.value = first.product.id;
                      row.productName.value = first.product.name;
                      row.productCode.value = first.product.hsnCode ?? '';
                      if (first.selectedPack != null) {
                        row.selectedPackId.value = first.selectedPack!.id;
                        row.selectedPackLabel.value = first.selectedPack!.label;
                        if (first.selectedPack!.unit != null) {
                          row.unit.value = first.selectedPack!.unit!;
                        }
                        if (first.selectedPack!.price != null) {
                          row.price.value = first.selectedPack!.price!.toString();
                        }
                      }
                      await controller.applyProductTaxesToRow(row, first.product.id);
                      state.didChange(first.product.id);
                      state.validate();

                      for (int i = 1; i < selections.length; i++) {
                        final sel = selections[i];
                        controller.addItem();
                        final newRow = controller.items.last;
                        newRow.productId.value = sel.product.id;
                        newRow.productName.value = sel.product.name;
                        newRow.productCode.value = sel.product.hsnCode ?? '';
                        if (sel.selectedPack != null) {
                          newRow.selectedPackId.value = sel.selectedPack!.id;
                          newRow.selectedPackLabel.value = sel.selectedPack!.label;
                          if (sel.selectedPack!.unit != null) {
                            newRow.unit.value = sel.selectedPack!.unit!;
                          }
                          if (sel.selectedPack!.price != null) {
                            newRow.price.value = sel.selectedPack!.price!.toString();
                          }
                        }
                        await controller.applyProductTaxesToRow(newRow, sel.product.id);
                      }
                    },
              child: InputDecorator(
                decoration: _siInputDecoration(labelText: 'Product *'),
                child: Row(
                  children: [
                    Obx(() {
                      final name = row.productName.value;
                      final hasProduct = row.productId.value != null && name.isNotEmpty;
                      final initial = hasProduct ? name.trim()[0].toUpperCase() : null;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: hasProduct
                            ? Container(
                                key: ValueKey(name),
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLighter,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.primaryLight, width: 1),
                                ),
                                child: Center(
                                  child: Text(initial!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark)),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      );
                    }),
                    Expanded(
                      child: Obx(() {
                        final name = row.productName.value;
                        final packLabel = row.selectedPackLabel.value;
                        final displayText = name.isEmpty
                            ? 'Tap to search...'
                            : (packLabel.isNotEmpty ? '$name · $packLabel' : name);
                        return Text(
                          displayText,
                          style: TextStyle(
                              color: row.productId.value == null ? Colors.grey : null),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
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
                child: Text(state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Addon card — full replica of SO _AddonCard
// ─────────────────────────────────────────────────────────────────────────────

class _AddonCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: _fieldVerticalGap),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: SalesInvoiceFormController.chargeTypeNames
                                      .contains(charge.name.value)
                                  ? charge.name.value
                                  : SalesInvoiceFormController.chargeTypeNames.first,
                              decoration:
                                  _siInputDecoration(labelText: 'Name').copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: _fieldVerticalGap),
                              ),
                              isExpanded: true,
                              isDense: true,
                              items: SalesInvoiceFormController.chargeTypeNames
                                  .map((name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: controller.isReadOnly
                                  ? null
                                  : (v) { if (v != null) charge.name.value = v; },
                            )),
                      ),
                      const SizedBox(width: _fieldGap),
                      Expanded(
                        child: TextFormField(
                          enabled: !controller.isReadOnly,
                          initialValue: charge.amount.value,
                          decoration: _siInputDecoration(labelText: 'Amount'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^-?\d+\.?\d{0,2}'))
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
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: _fieldVerticalGap),
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

// ─────────────────────────────────────────────────────────────────────────────
// Summary card — full replica of SO _SummaryCard with tax breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

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
              _summaryRow(displayTaxLabel(entry.key),
                  '₹ ${entry.value.toStringAsFixed(2)}', false),
            ],
            if (roundOffTax > 0) ...[
              const SizedBox(height: 3),
              _summaryRow(
                  'Round off Tax', '₹ ${roundOffTax.toStringAsFixed(2)}', false),
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

// ─────────────────────────────────────────────────────────────────────────────
// Observable text field — syncs from RxString without resetting on keystroke
// ─────────────────────────────────────────────────────────────────────────────

class _ObsField extends StatefulWidget {
  final RxString obs;
  final String label;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _ObsField({
    required this.obs,
    required this.label,
    required this.readOnly,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<_ObsField> createState() => _ObsFieldState();
}

class _ObsFieldState extends State<_ObsField> {
  late final TextEditingController _ctrl;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.obs.value);
    _worker = ever(widget.obs, (String v) {
      if (v != _ctrl.text) {
        _ctrl.text = v;
        _ctrl.selection = TextSelection.collapsed(offset: v.length);
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      enabled: !widget.readOnly,
      maxLines: 1,
      decoration: _siInputDecoration(labelText: widget.label),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.readOnly ? null : (v) => widget.obs.value = v,
    );
  }
}
