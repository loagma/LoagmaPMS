import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_return_form_controller.dart';
import '../../models/customer_model.dart';
import '../../models/party_result.dart';
import '../../services/customer_api_service.dart';
import '../../services/report_export_service.dart';
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

// ── Date helpers ─────────────────────────────────────────────────────────────

/// Stores dates internally as yyyy-MM-dd, displays as dd/MM/yyyy
String _displayDate(String isoDate) {
  final text = isoDate.trim();
  if (text.isEmpty) return '-';
  final parsed = DateTime.tryParse(text);
  if (parsed != null) {
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return '$d/$m/${parsed.year}';
  }
  // Already in ddmmyyyy or unknown format — return as-is
  return text;
}

Future<void> _pickDate(
  BuildContext context, {
  required String currentValue,
  required ValueChanged<String> onPicked,
}) async {
  DateTime initial = DateTime.now();
  final raw = currentValue.trim();
  if (raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) initial = parsed;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    ),
  );
  if (picked == null) return;
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  onPicked('${picked.year}-$m-$d');
}

Future<void> _showSalesInvoiceSelector(
  BuildContext context,
  SalesReturnFormController controller,
) async {
  final customerId = controller.customerId.value;
  if (customerId == null) {
    Get.snackbar('Select Customer', 'Please select a customer first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white);
    return;
  }

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _SISelectorDialog(controller: controller, customerId: customerId),
  );

  if (result != null) {
    final siId = result['id'] as int?;
    if (siId != null) await controller.loadSalesInvoiceItems(siId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SalesReturnFormScreen extends StatefulWidget {
  final int? returnId;
  final int? sourceSiId;
  final bool startInViewOnly;
  final List<int> allIds;

  const SalesReturnFormScreen({
    super.key,
    this.returnId,
    this.sourceSiId,
    this.startInViewOnly = false,
    this.allIds = const [],
  });

  @override
  State<SalesReturnFormScreen> createState() => _SalesReturnFormScreenState();
}

class _SalesReturnFormScreenState extends State<SalesReturnFormScreen> {
  late final String _tag;
  late final SalesReturnFormController controller;

  @override
  void initState() {
    super.initState();
    _tag = widget.returnId?.toString() ?? 'new_${DateTime.now().microsecondsSinceEpoch}';
    Get.delete<SalesReturnFormController>(tag: _tag, force: true);
    controller = Get.put(
      SalesReturnFormController(
        returnId: widget.returnId,
        sourceSiId: widget.sourceSiId,
        startInViewOnly: widget.startInViewOnly,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<SalesReturnFormController>(tag: _tag, force: true);
    super.dispose();
  }

  int? get _prevId {
    final cur = controller.currentBrowseId.value ?? widget.returnId;
    final idx = cur != null ? widget.allIds.indexOf(cur) : -1;
    return idx > 0 ? widget.allIds[idx - 1] : null;
  }

  int? get _nextId {
    final cur = controller.currentBrowseId.value ?? widget.returnId;
    final idx = cur != null ? widget.allIds.indexOf(cur) : -1;
    return (idx >= 0 && idx < widget.allIds.length - 1) ? widget.allIds[idx + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Obx(() {
        if (controller.isReadOnly) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            heroTag: 'sr_add_item_fab',
            onPressed: controller.addItemRow,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Add Item',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Sales Return' : 'Create Sales Return',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          if (widget.allIds.isNotEmpty)
            Obx(() {
              final prev = _prevId;
              final next = _nextId;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        color: prev != null ? Colors.white : Colors.white38),
                    tooltip: 'Previous return',
                    onPressed: prev != null
                        ? () => controller.loadReturnById(prev)
                        : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        color: next != null ? Colors.white : Colors.white38),
                    tooltip: 'Next return',
                    onPressed: next != null
                        ? () => controller.loadReturnById(next)
                        : null,
                  ),
                ],
              );
            }),
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
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share PDF',
                  onPressed: () => ReportExportService.shareSalesReturn(controller),
                ),
                IconButton(
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  tooltip: 'Print Return',
                  onPressed: () => ReportExportService.printSalesReturn(controller),
                ),
              ],
            );
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
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
                  ActionButton(
                    label: 'Share PDF',
                    onPressed: () => ReportExportService.shareSalesReturn(controller),
                  ),
                  ActionButton(
                    label: 'Print',
                    isPrimary: true,
                    onPressed: () => ReportExportService.printSalesReturn(controller),
                  ),
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
                      _HeaderCard(controller: controller, allIds: widget.allIds),
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
              Obx(() => ActionButtonBar(
                    buttons: [
                      ActionButton(
                        label: 'Cancel',
                        onPressed: controller.isSaving.value ? null : () => Get.back(),
                      ),
                      ActionButton(
                        label: 'Save as Draft',
                        isPrimary: true,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : () => controller.saveSalesReturn(post: false),
                      ),
                      ActionButton(
                        label: 'Post',
                        isPrimary: true,
                        backgroundColor: AppColors.primaryDark,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : () => controller.saveSalesReturn(post: true),
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
// Header card
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatefulWidget {
  final SalesReturnFormController controller;
  final List<int> allIds;

  const _HeaderCard({required this.controller, this.allIds = const []});

  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard> {
  late final TextEditingController _voucherCtrl;
  late final Worker _docNoWorker;

  SalesReturnFormController get controller => widget.controller;

  int? get _prevId {
    final cur = controller.currentBrowseId.value;
    final idx = cur != null ? widget.allIds.indexOf(cur) : widget.allIds.length;
    return idx > 0 ? widget.allIds[idx - 1] : null;
  }

  int? get _nextId {
    final cur = controller.currentBrowseId.value;
    if (cur == null) return widget.allIds.isNotEmpty ? widget.allIds.first : null;
    final idx = cur != null ? widget.allIds.indexOf(cur) : -1;
    return (idx >= 0 && idx < widget.allIds.length - 1) ? widget.allIds[idx + 1] : null;
  }

  @override
  void initState() {
    super.initState();
    _voucherCtrl = TextEditingController();
    _docNoWorker = ever(controller.docNoNumber, (_) => _syncVoucherText());
    _syncVoucherText();
  }

  void _syncVoucherText() {
    final raw = controller.docNoNumber.value.trim();
    final display = raw.isEmpty ? '' : (int.tryParse(raw)?.toString() ?? raw);
    if (_voucherCtrl.text != display) {
      _voucherCtrl.value = TextEditingValue(
        text: display,
        selection: TextSelection.collapsed(offset: display.length),
      );
    }
  }

  void _onVoucherSubmit(String value) {
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) { _syncVoucherText(); return; }
    controller.loadByNumber(n);
  }

  @override
  void dispose() {
    _docNoWorker.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Return Details',
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
          // ── Row 1: Financial Year + Voucher No ───────────────────────────
          Row(
            children: [
              // Financial Year dropdown
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
                      decoration: _srInputDecoration(labelText: 'Financial Year'),
                      isExpanded: true,
                      items: options
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
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
              // Voucher No — typeable
              Expanded(
                flex: 3,
                child: Obx(() {
                  final isNew = !controller.isEditMode && !controller.isBrowsing.value;
                  final prev = _prevId;
                  final next = _nextId;
                  final currentSeq = int.tryParse(RegExp(r'(\d+)$').firstMatch(_voucherCtrl.text)?.group(1) ?? '');
                  final prevSeq = currentSeq != null && currentSeq > 1 ? currentSeq - 1 : null;
                  final nextSeq = currentSeq != null ? currentSeq + 1 : null;
                  return SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded,
                              color: prev != null ? AppColors.primary : Colors.grey.shade400),
                          tooltip: 'Previous return',
                          onPressed: prev != null
                              ? () => controller.loadReturnById(prev)
                              : prevSeq != null
                                  ? () => controller.loadByNumber(prevSeq, allowCreateNewIfMissing: false)
                                  : null,
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
                            decoration: _srInputDecoration(
                              labelText: 'Voucher No',
                              hintText: isNew ? 'NEW' : 'Type # and press Go',
                            ),
                            onSubmitted: _onVoucherSubmit,
                            textInputAction: TextInputAction.go,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded,
                              color: next != null ? AppColors.primary : Colors.grey.shade400),
                          tooltip: 'Next return',
                          onPressed: next != null
                              ? () => controller.loadReturnById(next)
                              : nextSeq != null
                                  ? () => controller.loadByNumber(nextSeq, allowCreateNewIfMissing: false)
                                  : null,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: _headerFieldGap),

          // ── Document Date (first) ─────────────────────────────────────────
          GestureDetector(
            onTap: controller.isReadOnly
                ? null
                : () => _pickDate(context,
                    currentValue: controller.docDate.value,
                    onPicked: (v) => controller.docDate.value = v),
            child: Obx(() => InputDecorator(
                  decoration: _srInputDecoration(
                    labelText: 'Document Date',
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    controller.docDate.value.isEmpty
                        ? 'Select date'
                        : _displayDate(controller.docDate.value),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                  ),
                )),
          ),
          const SizedBox(height: _headerFieldGap),

          // ── Customer picker ───────────────────────────────────────────────
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
                            final selectedId = controller.customerId.value;
                            if (selectedId != null) {
                              await _showCustomerDetailSheet(context, selectedId, controller);
                              return;
                            }
                            final party = await showDialog<PartyResult>(
                              context: context,
                              builder: (_) => PartySearchDialog(
                                title: 'Select Customer',
                                hint: 'Search by name, phone or ID...',
                                searchFn: controller.searchCustomers,
                              ),
                            );
                            if (party != null) {
                              await controller.setCustomerWithName(party.id, party.name,
                                  phone: party.phone, shopName: party.shopName);
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
                              if (selectedId == null) {
                                return const Text('Tap to select...',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis);
                              }
                              final subtitle = [
                                if (controller.customerShopName.value.trim().isNotEmpty)
                                  controller.customerShopName.value.trim(),
                                if (controller.customerPhone.value.trim().isNotEmpty)
                                  controller.customerPhone.value.trim(),
                              ].join(' • ');
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    controller.customerName.value.trim().isEmpty
                                        ? 'Customer'
                                        : controller.customerName.value.trim(),
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          if (!locked)
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
              );
            },
          ),
          const SizedBox(height: _headerFieldGap),

          // ── Source Order / Invoice ────────────────────────────────────────
          Obx(() => GestureDetector(
                onTap: controller.isReadOnly || controller.isEditMode
                    ? null
                    : controller.customerId.value == null
                        ? () => Get.snackbar('Select Customer',
                                'Please select a customer first.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange,
                                colorText: Colors.white)
                        : () => _showSalesInvoiceSelector(context, controller),
                child: InputDecorator(
                  decoration: _srInputDecoration(
                    labelText: 'Source Invoice',
                    suffixIcon: controller.isSearchingInvoices.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.primary)))
                        : const Icon(Icons.search),
                  ),
                  child: Text(
                    controller.sourceSiNumber.value.isEmpty
                        ? 'Select an invoice'
                        : controller.sourceSiNumber.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: controller.sourceSiNumber.value.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textDark,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Customer detail sheet (with Change Customer at top)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showCustomerDetailSheet(
  BuildContext context,
  int customerId,
  SalesReturnFormController controller,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomerDetailSheet(customerId: customerId, controller: controller),
  );
}

class _CustomerDetailSheet extends StatefulWidget {
  final int customerId;
  final SalesReturnFormController controller;

  const _CustomerDetailSheet({required this.customerId, required this.controller});

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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            // Change Customer button — always at top
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
                    await widget.controller.setCustomerWithName(
                      party.id, party.name,
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
        if (c.contactNumber?.isNotEmpty == true || c.alternatePhone?.isNotEmpty == true || c.email?.isNotEmpty == true)
          _infoSection('Contact', [
            if (c.contactNumber?.isNotEmpty == true)
              _infoRow(Icons.phone, 'Phone', c.contactNumber!),
            if (c.alternatePhone?.isNotEmpty == true)
              _infoRow(Icons.phone_android, 'Alternate', c.alternatePhone!),
            if (c.email?.isNotEmpty == true)
              _infoRow(Icons.email_outlined, 'Email', c.email!),
          ]),
        if (c.addressLine1?.isNotEmpty == true || c.city?.isNotEmpty == true) ...[
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
      ],
    );
  }

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
    final name = customer.name.isNotEmpty ? customer.name : (customer.shopName ?? '?');
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Items card
// ─────────────────────────────────────────────────────────────────────────────

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
              headingRowColor:
                  WidgetStateProperty.all(AppColors.primaryLighter.withValues(alpha: 0.25)),
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
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Action')),
              ],
              rows: List<DataRow>.generate(controller.items.length, (i) {
                final row = controller.items[i];
                final origQty = double.tryParse(row.originalQty.value) ?? 0;
                final availableQty = double.tryParse(row.availableQty.value) ?? origQty;
                final maxQty = availableQty > 0 ? availableQty : origQty;
                final unitPrice = double.tryParse(row.unitPrice.value) ?? 0;
                final returnedQty = double.tryParse(row.returnedQty.value) ?? 0;
                final lineAmt = returnedQty * unitPrice;
                final details = [
                  if (row.unitType.value.isNotEmpty) row.unitType.value,
                  if (row.productCode.value.isNotEmpty) row.productCode.value,
                ].join(' • ');

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (!row.selected.value) {
                      return AppColors.primaryLighter.withValues(alpha: 0.08);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(Checkbox(
                      value: row.selected.value,
                      onChanged: controller.isReadOnly
                          ? null
                          : (checked) => controller.setItemSelected(i, checked ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )),
                    DataCell(Text('${i + 1}')),
                    DataCell(SizedBox(
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
                            Text(details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    )),
                    DataCell(Text(origQty.toStringAsFixed(2))),
                    DataCell(SizedBox(
                      width: 74,
                      child: TextFormField(
                        initialValue: row.returnedQty.value,
                        onChanged: (v) => row.returnedQty.value = v,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        enabled: row.selected.value,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
                        ],
                        validator: (value) {
                          if (!row.selected.value) return null;
                          final qty = double.tryParse(value?.trim() ?? '') ?? 0;
                          if (qty < 0) return 'Invalid';
                          if (qty > maxQty) return 'Max ${maxQty.toStringAsFixed(2)}';
                          return null;
                        },
                        onTap: row.selected.value
                            ? null
                            : () => controller.setItemSelected(i, true),
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        ),
                      ),
                    )),
                    DataCell(Text(unitPrice > 0 ? unitPrice.toStringAsFixed(2) : '-')),
                    DataCell(Text(
                      lineAmt > 0 ? lineAmt.toStringAsFixed(2) : '-',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(SizedBox(
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
                    )),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => controller.removeItemRow(i),
                      tooltip: 'Remove',
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                    )),
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

// ─────────────────────────────────────────────────────────────────────────────
// Reasons card
// ─────────────────────────────────────────────────────────────────────────────

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
          Obx(() => TextFormField(
                initialValue: controller.reason.value,
                onChanged: (v) => controller.reason.value = v,
                maxLines: 2,
                decoration: _srInputDecoration(
                  labelText: 'Return Reason',
                  hintText: 'e.g., Defective items, over-delivery, quality issue',
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SalesReturnFormController controller;
  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Summary',
      child: Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Return Value',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  Text('₹ ${controller.totalReturnValue}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.status.value == 'DRAFT'
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: controller.status.value == 'DRAFT'
                              ? Colors.blue
                              : Colors.green),
                    ),
                    child: Text(
                      controller.status.value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: controller.status.value == 'DRAFT'
                              ? Colors.blue
                              : Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only report view
// ─────────────────────────────────────────────────────────────────────────────

class _SalesReturnReportView extends StatelessWidget {
  final SalesReturnFormController controller;
  const _SalesReturnReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final docNo =
          '${controller.docNoPrefix.value}${controller.docNoNumber.value}'.trim();
      final rows = controller.items;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Sales Return Document',
            child: Column(
              children: [
                _metaRow('Return No', docNo.isEmpty ? '-' : docNo),
                _metaRow('Status', controller.status.value),
                _metaRow('Customer', [
                  if (controller.customerName.value.isNotEmpty)
                    controller.customerName.value,
                  if (controller.customerShopName.value.isNotEmpty)
                    controller.customerShopName.value,
                  if (controller.customerPhone.value.isNotEmpty)
                    controller.customerPhone.value,
                ].join(' • ').isNotEmpty
                    ? [
                        if (controller.customerName.value.isNotEmpty)
                          controller.customerName.value,
                        if (controller.customerShopName.value.isNotEmpty)
                          controller.customerShopName.value,
                        if (controller.customerPhone.value.isNotEmpty)
                          controller.customerPhone.value,
                      ].join(' • ')
                    : '-'),
                _metaRow('Source SI',
                    controller.sourceSiNumber.value.isEmpty
                        ? '-'
                        : controller.sourceSiNumber.value),
                _metaRow('Document Date',
                    controller.docDate.value.isEmpty
                        ? '-'
                        : _displayDate(controller.docDate.value)),
                _metaRow('Reason',
                    controller.reason.value.isEmpty ? '-' : controller.reason.value,
                    isLast: true),
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
                  headingRowColor: WidgetStateProperty.all(
                      AppColors.primaryLighter.withValues(alpha: 0.25)),
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
                    DataColumn(label: Text('Rate'), numeric: true),
                    DataColumn(label: Text('Amount'), numeric: true),
                    DataColumn(label: Text('Reason')),
                  ],
                  rows: List<DataRow>.generate(rows.length, (i) {
                    final row = rows[i];
                    final origQty = double.tryParse(row.originalQty.value) ?? 0;
                    final returnQty = double.tryParse(row.returnedQty.value) ?? 0;
                    final unitPrice = double.tryParse(row.unitPrice.value) ?? 0;
                    final lineAmt = returnQty * unitPrice;
                    return DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(SizedBox(
                        width: 140,
                        child: Text(
                            row.productName.value.isEmpty ? '-' : row.productName.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(Text(origQty.toStringAsFixed(2))),
                      DataCell(Text(returnQty.toStringAsFixed(2))),
                      DataCell(Text(unitPrice > 0 ? unitPrice.toStringAsFixed(2) : '-')),
                      DataCell(Text(
                        lineAmt > 0 ? lineAmt.toStringAsFixed(2) : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )),
                      DataCell(SizedBox(
                        width: 120,
                        child: Text(
                            row.returnReason.value.isEmpty ? '-' : row.returnReason.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice selector dialog
// ─────────────────────────────────────────────────────────────────────────────

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
    final results = await widget.controller.searchSalesInvoices(query,
        customerIdFilter: widget.customerId);
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
                const Text('Select Invoice',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text('Billed invoices only',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.primary)))
                    : searchResults.isEmpty
                        ? Container(
                            key: const ValueKey('sr_invoice_empty'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLighter.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primaryLight.withValues(alpha: 0.45)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    color: AppColors.textMuted, size: 30),
                                const SizedBox(height: 8),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'Start typing to filter invoices'
                                      : 'No invoices found for this search',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500),
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
                              final billNo = si['bill_number']?.toString() ?? '';
                              final soNumber = si['so_number']?.toString() ?? '';
                              final docNo = billNo.isNotEmpty ? billNo : soNumber;
                              final status =
                                  (si['status']?.toString() ?? '').toUpperCase();
                              final docDate = si['doc_date']?.toString() ?? '';
                              final total = si['total_amount'];
                              final totalStr = total != null
                                  ? '₹ ${(double.tryParse(total.toString()) ?? 0).toStringAsFixed(2)}'
                                  : '';
                              final isBilled = status == 'BILLED';

                              return Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => Navigator.pop(ctx, si),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.primaryLight
                                              .withValues(alpha: 0.45)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isBilled
                                                ? Icons.receipt_rounded
                                                : Icons.local_shipping_outlined,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        docNo.isEmpty ? 'Order' : docNo,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.textDark),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isBilled
                                                            ? Colors.green
                                                                .withValues(alpha: 0.12)
                                                            : Colors.orange
                                                                .withValues(alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(status,
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                              color: isBilled
                                                                  ? Colors.green.shade700
                                                                  : Colors
                                                                      .orange.shade700)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  [
                                                    if (docDate.isNotEmpty)
                                                      _displayDate(docDate),
                                                    if (totalStr.isNotEmpty) totalStr,
                                                  ].join(' • '),
                                                  style: const TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right_rounded,
                                              color: AppColors.textMuted),
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
