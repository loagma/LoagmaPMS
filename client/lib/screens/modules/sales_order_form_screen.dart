import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_order_form_controller.dart';
import '../../models/customer_model.dart';
import '../../models/party_result.dart';
import '../../models/product_model.dart';
import '../../services/customer_api_service.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_order_list_screen.dart';

InputDecoration _soInputDecoration({
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

Future<void> _pickSoDate(
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

String _displayDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '-';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

class SalesOrderFormScreen extends StatefulWidget {
  final int? soId;
  final bool startInViewOnly;
  final List<int> allIds;

  const SalesOrderFormScreen({
    super.key,
    this.soId,
    this.startInViewOnly = false,
    this.allIds = const [],
  });

  @override
  State<SalesOrderFormScreen> createState() => _SalesOrderFormScreenState();
}

class _SalesOrderFormScreenState extends State<SalesOrderFormScreen> {
  late final String _tag;
  late final SalesOrderFormController controller;
  bool _showAllProducts = false;
  bool _isAddingProduct = false;

  @override
  void initState() {
    super.initState();
    _tag = widget.soId?.toString() ?? 'new_${DateTime.now().microsecondsSinceEpoch}';
    Get.delete<SalesOrderFormController>(tag: _tag, force: true);
    controller = Get.put(
      SalesOrderFormController(
        soId: widget.soId,
        startInViewOnly: widget.startInViewOnly,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<SalesOrderFormController>(tag: _tag, force: true);
    super.dispose();
  }

  Future<void> _addAndSearchProduct() async {
    if (_isAddingProduct) return;
    _isAddingProduct = true;
    try {
      final hasSupplierFilter =
          controller.salesmanId.value != null && controller.salesmanId.value!.isNotEmpty;
      controller.addItem();
      final newRow = controller.items.last;
      final selections = await showDialog<List<ProductSelection>>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => ProductSearchDialog(
          title: 'Select Products',
          searchFn: controller.searchProductsAsModels,
          allProductsSearchFn: hasSupplierFilter ? controller.searchAllProductsUnfiltered : null,
          allowMultiSelect: true,
          showSupplierToggle: hasSupplierFilter,
          supplierToggleValue: _showAllProducts,
          onSupplierToggle: (v) => setState(() => _showAllProducts = v),
        ),
      );
      if (selections == null || selections.isEmpty) {
        controller.items.remove(newRow);
        return;
      }
      for (int i = 0; i < selections.length; i++) {
        final sel = selections[i];
        SOLineRow r;
        if (i == 0) {
          r = newRow;
        } else {
          controller.addItem();
          r = controller.items.last;
        }
        r.productId.value = sel.product.id;
        r.productName.value = sel.product.name;
        r.hsnCode.value = sel.product.hsnCode ?? '';
        r.quantity.value = sel.quantity.toString();
        if (sel.selectedPack != null) {
          r.selectedPackId.value = sel.selectedPack!.id;
          r.selectedPackLabel.value = sel.selectedPack!.label;
          if (sel.selectedPack!.unit != null) r.unit.value = sel.selectedPack!.unit!;
          if (sel.selectedPack!.price != null) r.price.value = sel.selectedPack!.price!.toString();
        }
        await controller.applyProductTaxesToRow(r, sel.product.id);
      }
    } finally {
      _isAddingProduct = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Obx(() {
        if (controller.viewOnly.value || controller.isReadOnly) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            heroTag: 'so_add_item_fab',
            onPressed: _addAndSearchProduct,
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
        title: controller.isEditMode ? 'Sales Order' : 'Create Sales Order',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final s = controller.status.value;
            final canEdit = controller.viewOnly.value && (s == 'DRAFT' || s == 'PENDING');
            if (!canEdit) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => controller.viewOnly.value = false,
            );
          }),
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share PDF',
              onPressed: () => ReportExportService.shareSalesOrder(controller),
            );
          }),
          Obx(() {
            if (!controller.isReadOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              tooltip: 'Print Order',
              onPressed: () => ReportExportService.printSalesOrder(controller),
            );
          }),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: 'View all sales orders',
            onPressed: () => Get.to(() => const SalesOrderListScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill in customer, dates and add line items with quantity and price.',
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
                  child: _SalesOrderReportView(controller: controller),
                ),
              ),
              ActionButtonBar(
                buttons: [
                  ActionButton(
                    label: 'Back',
                    onPressed: () => Get.back(),
                  ),
                  ActionButton(
                    label: 'Share PDF',
                    onPressed: () => ReportExportService.shareSalesOrder(controller),
                  ),
                  ActionButton(
                    label: 'Print',
                    isPrimary: true,
                    onPressed: () => ReportExportService.printSalesOrder(controller),
                  ),
                  if (controller.status.value == 'DRAFT' || controller.status.value == 'PENDING')
                    ActionButton(
                      label: 'Edit',
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
                      onPressed: controller.isSaving.value || controller.isFieldsLocked
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

class _SalesOrderReportView extends StatelessWidget {
  final SalesOrderFormController controller;

  const _SalesOrderReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final soNumber = controller.currentSoNumber.value.trim().isEmpty
          ? (controller.currentSoSeq.value?.toString() ?? '-')
          : controller.currentSoNumber.value.trim();
      final customerLabel = controller.customerDisplayLabel.isEmpty
          ? 'Customer'
          : controller.customerDisplayLabel;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Sales Order Invoice',
            child: Column(
              children: [
                _metaRow('SO Number', soNumber),
                _metaRow('Status', controller.status.value),
                _metaRow('Customer', customerLabel),
                _metaRow('Document Date', _normalizeDate(controller.docDate.value)),
                _metaRow('Expected Date', _normalizeDate(controller.expectedDate.value)),
                _metaRow('Financial Year', controller.financialYear.value.trim().isEmpty ? '-' : controller.financialYear.value.trim()),
                _metaRow('Narration', controller.narration.value.trim().isEmpty ? '-' : controller.narration.value.trim(), isLast: !controller.isBillMode),
                if (controller.isBillMode) ...[
                  _metaRow('Bill Date', controller.billDt.value.isEmpty ? '-' : _normalizeDate(controller.billDt.value)),
                  _metaRow('Department', controller.billDepartment.value.isEmpty ? '-' : controller.billDepartment.value),
                  _metaRow('Bill Narration', controller.billNarration.value.isEmpty ? '-' : controller.billNarration.value),
                  _metaRow('Vehicle', controller.billVehicle.value.isEmpty ? '-' : controller.billVehicle.value),
                  _metaRow('Bill Statement', controller.billStatement.value.isEmpty ? '-' : controller.billStatement.value),
                  _metaRow('Round Off', controller.billRoff.value.isEmpty ? '0' : controller.billRoff.value),
                  _metaRow('Doc Year', controller.billDocYear.value.isEmpty ? '-' : controller.billDocYear.value, isLast: true),
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
                    DataColumn(label: Text('Description')),
                  ],
                  rows: List<DataRow>.generate(controller.items.length, (i) {
                    final row = controller.items[i];
                    final qty = double.tryParse(row.quantity.value) ?? 0;
                    final rate = double.tryParse(row.price.value) ?? 0;
                    final disc = double.tryParse(row.discountPercent.value) ?? 0;
                    final tax = double.tryParse(row.taxPercent.value) ?? 0;

                    return DataRow(
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(SizedBox(width: 170, child: Text(row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(), maxLines: 2, overflow: TextOverflow.ellipsis))),
                        DataCell(Text(row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim())),
                        DataCell(Text(row.unit.value.trim().isEmpty ? '-' : row.unit.value.trim())),
                        DataCell(Text(qty.toStringAsFixed(1))),
                        DataCell(Text(rate.toStringAsFixed(2))),
                        DataCell(Text(disc.toStringAsFixed(2))),
                        DataCell(Text(tax.toStringAsFixed(2))),
                        DataCell(Text(row.lineTotalExclTax.toStringAsFixed(2))),
                        DataCell(Text(row.lineTotal.toStringAsFixed(2))),
                        DataCell(SizedBox(width: 160, child: Text(row.description.value.trim().isEmpty ? '-' : row.description.value.trim(), maxLines: 2, overflow: TextOverflow.ellipsis))),
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
    if (parsed == null) return text;
    final local = parsed.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
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

Future<void> _showCustomerDetailSheet(
  BuildContext context,
  int customerId,
  SalesOrderFormController controller,
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
  final SalesOrderFormController controller;

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
    final isEdit = !widget.controller.isFieldsLocked;
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            if (isEdit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: OutlinedButton.icon(
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
                      widget.controller.setCustomer(
                        party.id,
                        party.name,
                        phone: party.phone,
                        shopName: party.shopName,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CustomerInfoHeader(customer: c),
        const SizedBox(height: 16),
        _infoSection('Contact', [
          if (c.contactNumber?.isNotEmpty == true) _infoRow(Icons.phone, 'Phone', c.contactNumber!),
          if (c.alternatePhone?.isNotEmpty == true) _infoRow(Icons.phone_android, 'Alternate', c.alternatePhone!),
          if (c.email?.isNotEmpty == true) _infoRow(Icons.email_outlined, 'Email', c.email!),
        ]),
        if (_hasAddress(c)) ...[
          const SizedBox(height: 12),
          _infoSection('Address', [
            if (c.addressLine1?.isNotEmpty == true) _infoRow(Icons.location_on_outlined, 'Address', c.addressLine1!),
            if (c.city?.isNotEmpty == true || c.state?.isNotEmpty == true)
              _infoRow(Icons.map_outlined, 'City / State',
                  [c.city, c.state].where((s) => s?.isNotEmpty == true).join(', ')),
            if (c.pincode?.isNotEmpty == true) _infoRow(Icons.pin_drop_outlined, 'Pincode', c.pincode!),
          ]),
        ],
        if (c.gstNo?.isNotEmpty == true || c.panNo?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _infoSection('Tax Info', [
            if (c.gstNo?.isNotEmpty == true) _infoRow(Icons.receipt_long_outlined, 'GST No', c.gstNo!),
            if (c.panNo?.isNotEmpty == true) _infoRow(Icons.credit_card_outlined, 'PAN No', c.panNo!),
          ]),
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
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
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
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
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
          child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.name.isNotEmpty)
                Text(customer.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (customer.shopName?.isNotEmpty == true)
                Text(customer.shopName!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('ID: ${customer.id}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      customer.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
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

class _HeaderCard extends StatefulWidget {
  final SalesOrderFormController controller;

  const _HeaderCard({required this.controller});

  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard> {
  late final TextEditingController _voucherCtrl;
  late final Worker _seqWorker;
  late final Worker _numberWorker;

  SalesOrderFormController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _voucherCtrl = TextEditingController();
    _seqWorker = ever(controller.currentSoSeq, (_) => _syncVoucherText());
    _numberWorker = ever(controller.currentSoNumber, (_) => _syncVoucherText());
    _syncVoucherText();
  }

  void _syncVoucherText() {
    final seq = controller.currentSoSeq.value;
    final soNum = controller.currentSoNumber.value;
    String display = '';
    if (seq != null) {
      display = seq.toString();
    } else if (soNum.isNotEmpty) {
      final match = RegExp(r'(\d+)$').firstMatch(soNum);
      display = match != null ? int.parse(match.group(1)!).toString() : soNum;
    }
    if (_voucherCtrl.text != display) {
      _voucherCtrl.value = TextEditingValue(
        text: display,
        selection: TextSelection.collapsed(offset: display.length),
      );
    }
  }

  void _onVoucherSubmit(String value) {
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      _syncVoucherText();
      return;
    }
    controller.goToVoucherByNumber(n);
  }

  @override
  void dispose() {
    _seqWorker.dispose();
    _numberWorker.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Customer & Dates',
      titleAction: Obx(() {
        final isNew = !controller.isEditMode && !controller.isBrowsing.value;
        if (isNew) return const SizedBox.shrink();
        return TextButton.icon(
          onPressed: controller.isLoading.value ? null : () => controller.resetToNewForm(),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('New'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      }),
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
                      initialValue: fy.isEmpty ? null : fy,
                      decoration: _soInputDecoration(labelText: 'Financial Year'),
                      isExpanded: true,
                      items: options
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: controller.isFieldsLocked
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
                child: Obx(() {
                  final isNew = !controller.isEditMode && !controller.isBrowsing.value;
                  final canPrev = (controller.currentSoSeq.value ?? 0) > 1;
                  final canNext = true;
                  return SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded,
                              color: canPrev ? AppColors.primary : Colors.grey.shade400),
                          tooltip: 'Previous voucher',
                          onPressed: canPrev ? controller.goToPreviousVoucher : null,
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _voucherCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            readOnly: false,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                            decoration: _soInputDecoration(
                              labelText: 'Voucher No',
                              hintText: isNew ? 'NEW' : 'Type # and press Go',
                            ),
                            onSubmitted: _onVoucherSubmit,
                            textInputAction: TextInputAction.go,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded,
                              color: canNext ? AppColors.primary : Colors.grey.shade400),
                          tooltip: 'Next voucher',
                          onPressed: canNext ? controller.goToNextVoucher : null,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
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
                      key: ValueKey('so-doc-date-${controller.docDate.value}'),
                      enabled: !controller.isFieldsLocked,
                      readOnly: true,
                      initialValue: _displayDate(controller.docDate.value),
                      decoration: _soInputDecoration(
                        labelText: 'Document Date *',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: controller.isFieldsLocked
                          ? null
                          : () => _pickSoDate(
                                context,
                                currentValue: controller.docDate.value,
                                onPicked: controller.setDocDate,
                              ),
                    )),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('so-expected-date-${controller.expectedDate.value}'),
                      enabled: !controller.isFieldsLocked,
                      readOnly: true,
                      initialValue: _displayDate(controller.expectedDate.value),
                      decoration: _soInputDecoration(
                        labelText: 'Expected Date',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      onTap: controller.isFieldsLocked
                          ? null
                          : () => _pickSoDate(
                                context,
                                currentValue: controller.expectedDate.value,
                                onPicked: controller.setExpectedDate,
                              ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
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
                    if (controller.isFieldsLocked) return;
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
                    decoration: _soInputDecoration(labelText: 'Customer *'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final selectedId = controller.customerId.value;
                            if (selectedId == null) {
                              return Text(
                                'Tap to select...',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                        if (!controller.isFieldsLocked)
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
            ),
          ),
          const SizedBox(height: _sectionGap),
          Obx(() {
            final list = controller.departments;
            final current = controller.departmentId.value;
            final hasValue = list.any((d) => d['id']?.toString() == current?.toString());
            final value = hasValue ? current : null;
            return DropdownButtonFormField<String>(
              value: value,
              decoration: _soInputDecoration(labelText: 'Department'),
              items: list
                  .map((d) => DropdownMenuItem<String>(
                        value: d['id']?.toString(),
                        child: Text(
                          d['name']?.toString() ?? 'Department',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: controller.isFieldsLocked
                  ? null
                  : (v) => controller.setDepartmentId(v),
            );
          }),
          const SizedBox(height: _sectionGap),
          Obx(() {
            final name = controller.salesmanName.value.trim();
            return InkWell(
              onTap: controller.isFieldsLocked
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
                decoration: _soInputDecoration(labelText: 'Salesman').copyWith(
                  suffixIcon: controller.isFieldsLocked
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
                  style: TextStyle(
                    fontSize: 14,
                    color: name.isEmpty ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
          if (controller.isEditMode) ...[
            const SizedBox(height: _sectionGap),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.status.value,
                  decoration: _soInputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                    DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'BILLED', child: Text('Billed')),
                    DropdownMenuItem(value: 'PARTIALLY_INVOICED', child: Text('Partially invoiced')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: controller.isFieldsLocked
                      ? null
                      : (v) {
                          if (v != null) controller.setStatus(v);
                        },
                )),
          ],
          const SizedBox(height: _sectionGap),
          Obx(() => TextFormField(
                enabled: !controller.isFieldsLocked,
                initialValue: controller.narration.value,
                decoration: _soInputDecoration(labelText: 'Narration').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                minLines: 1,
                maxLines: 1,
                onChanged: controller.setNarration,
              )),
          // Bill / Invoice fields — shown only when status is BILLED
          Obx(() {
            if (!controller.isBillMode) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: _sectionGap),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Bill / Invoice Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: _sectionGap),
                // Bill Date
                Obx(() => InkWell(
                      onTap: controller.isFieldsLocked
                          ? null
                          : () => _pickSoDate(
                                context,
                                currentValue: controller.billDt.value,
                                onPicked: controller.setBillDt,
                              ),
                      child: InputDecorator(
                        decoration: _soInputDecoration(labelText: 'Bill Date'),
                        child: Text(
                          controller.billDt.value.isEmpty ? 'Select date' : _displayDate(controller.billDt.value),
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.billDt.value.isEmpty
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: _sectionGap),
                // Department
                Obx(() => TextFormField(
                      key: ValueKey('dept-${controller.billDepartment.value}'),
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billDepartment.value,
                      decoration: _soInputDecoration(labelText: 'Department'),
                      onChanged: controller.setBillDepartment,
                    )),
                const SizedBox(height: _sectionGap),
                // Bill Narration
                Obx(() => TextFormField(
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billNarration.value,
                      decoration: _soInputDecoration(labelText: 'Bill Narration'),
                      onChanged: controller.setBillNarration,
                    )),
                const SizedBox(height: _sectionGap),
                // Bill Vehicle
                Obx(() => TextFormField(
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billVehicle.value,
                      decoration: _soInputDecoration(labelText: 'Vehicle'),
                      onChanged: controller.setBillVehicle,
                    )),
                const SizedBox(height: _sectionGap),
                // Bill Statement
                Obx(() => TextFormField(
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billStatement.value,
                      decoration: _soInputDecoration(labelText: 'Bill Statement'),
                      onChanged: controller.setBillStatement,
                    )),
                const SizedBox(height: _sectionGap),
                // Round-off
                Obx(() => TextFormField(
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billRoff.value,
                      decoration: _soInputDecoration(labelText: 'Round Off'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onChanged: controller.setBillRoff,
                    )),
                const SizedBox(height: _sectionGap),
                // Doc Year
                Obx(() => TextFormField(
                      enabled: !controller.isFieldsLocked,
                      initialValue: controller.billDocYear.value,
                      decoration: _soInputDecoration(labelText: 'Doc Year (e.g. 25-26)'),
                      onChanged: controller.setBillDocYear,
                    )),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SalesOrderFormController controller;

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
            if (!controller.isFieldsLocked) ...[
              const SizedBox(height: _sectionGap),
            ],
          ],
        );
      }),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final SalesOrderFormController controller;
  final int index;
  final SOLineRow row;
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
              if (!controller.isFieldsLocked)
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
          _ProductPicker(controller: controller, row: row, readOnly: controller.isFieldsLocked),
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
                  Text('Fetching taxes...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                        key: ValueKey('qty_${row.productId.value ?? 'empty'}_${row.selectedPackId.value}'),
                        enabled: !controller.isFieldsLocked,
                        initialValue: row.quantity.value,
                        decoration: _soInputDecoration(labelText: 'Qty *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))],
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
                  child: Obx(() {
                    final base = controller.unitTypes;
                    final current = row.unit.value.trim();
                    // Always include the product's own unit so it's never lost
                    final units = <String>{
                      if (current.isNotEmpty) current,
                      ...base,
                    }.toList();
                    final value = current.isNotEmpty ? current : units.first;
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: _soInputDecoration(labelText: 'Unit').copyWith(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      isDense: true,
                      isExpanded: true,
                      iconSize: 16,
                      items: units
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: controller.isFieldsLocked
                          ? null
                          : (v) {
                              if (v != null) row.unit.value = v;
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
                        enabled: !controller.isFieldsLocked,
                        initialValue: row.price.value,
                        decoration: _soInputDecoration(labelText: 'Unit Price *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
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
          // Qty Delivered — only visible when billing
          Obx(() {
            if (!controller.isBillMode) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextFormField(
                initialValue: row.qtyDelivered.value,
                decoration: _soInputDecoration(labelText: 'Qty Delivered'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))],
                onChanged: (v) => row.qtyDelivered.value = v,
              ),
            );
          }),
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

  Widget _buildTaxRows(SOLineRow row) {
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
          final taxable = row.lineTotalExclTax;
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
  }

  Widget _buildTaxTotals(SOLineRow row) {
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
      decoration: _soInputDecoration(labelText: label),
      child: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _AddonCard extends StatelessWidget {
  final SalesOrderFormController controller;

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
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: SalesOrderFormController.chargeTypeNames.contains(charge.name.value)
                                  ? charge.name.value
                                  : SalesOrderFormController.chargeTypeNames.first,
                              decoration: _soInputDecoration(labelText: 'Name').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: _fieldVerticalGap),
                              ),
                              isExpanded: true,
                              isDense: true,
                              items: SalesOrderFormController.chargeTypeNames
                                  .map((name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: controller.isFieldsLocked
                                  ? null
                                  : (v) {
                                      if (v != null) charge.name.value = v;
                                    },
                            )),
                      ),
                      const SizedBox(width: _fieldGap),
                      Expanded(
                        child: TextFormField(
                          enabled: !controller.isFieldsLocked,
                          initialValue: charge.amount.value,
                          decoration: _soInputDecoration(labelText: 'Amount'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,2}'))],
                          onChanged: (v) => charge.amount.value = v,
                        ),
                      ),
                      if (!controller.isFieldsLocked) ...[
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
            if (!controller.isFieldsLocked)
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

class _ProductPicker extends StatefulWidget {
  final SalesOrderFormController controller;
  final SOLineRow row;
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
  bool _isPickingProduct = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final row = widget.row;
    final readOnly = widget.readOnly;

    final hasSupplierFilter = controller.salesmanId.value != null &&
        controller.salesmanId.value!.isNotEmpty;

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
                      if (_isPickingProduct) return;
                      _isPickingProduct = true;
                      try {
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

                        for (int i = 0; i < selections.length; i++) {
                          final sel = selections[i];
                          SOLineRow r;
                          if (i == 0) {
                            r = row;
                          } else {
                            controller.addItem();
                            r = controller.items.last;
                          }
                          r.productId.value = sel.product.id;
                          r.productName.value = sel.product.name;
                          r.hsnCode.value = sel.product.hsnCode ?? '';
                          r.quantity.value = sel.quantity.toString();
                          if (sel.selectedPack != null) {
                            r.selectedPackId.value = sel.selectedPack!.id;
                            r.selectedPackLabel.value = sel.selectedPack!.label;
                            if (sel.selectedPack!.unit != null) r.unit.value = sel.selectedPack!.unit!;
                            if (sel.selectedPack!.price != null) r.price.value = sel.selectedPack!.price!.toString();
                          }
                          await controller.applyProductTaxesToRow(r, sel.product.id);
                          if (i == 0) {
                            state.didChange(sel.product.id);
                            state.validate();
                          }
                        }
                      } finally {
                        _isPickingProduct = false;
                      }
                    },
              child: InputDecorator(
                decoration: _soInputDecoration(labelText: 'Product *'),
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
                                  border: Border.all(color: AppColors.primaryLight, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    initial!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
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
                          style: TextStyle(color: row.productId.value == null ? Colors.grey : null),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ),
                    if (!readOnly) const Icon(Icons.search, size: 18, color: AppColors.textMuted),
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


class _SummaryCard extends StatelessWidget {
  final SalesOrderFormController controller;

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
              _summaryRow(displayTaxLabel(entry.key), '₹ ${entry.value.toStringAsFixed(2)}', false),
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
