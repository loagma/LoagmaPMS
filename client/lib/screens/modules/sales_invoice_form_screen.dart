import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_invoice_form_controller.dart';
import '../../models/party_result.dart';
import '../../services/customer_api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers — identical to SO form
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _siDec({
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

Future<void> _pickDate(
  BuildContext context, {
  required String currentValue,
  required ValueChanged<String> onPicked,
}) async {
  final now = DateTime.now();
  DateTime initial = now;
  final raw = currentValue.trim();
  if (raw.isNotEmpty) {
    final p = DateTime.tryParse(raw);
    if (p != null) initial = p;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked == null) return;
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  onPicked('${picked.year}-$m-$d');
}

String _displayDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '-';
  final p = DateTime.tryParse(t);
  if (p == null) return t.length >= 10 ? t.substring(0, 10) : t;
  final local = p.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

const _docYearOptions = ['25-26', '26-27', '27-28', '28-29'];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SalesInvoiceFormScreen extends StatelessWidget {
  final int? soId;
  final bool viewOnly;

  const SalesInvoiceFormScreen({super.key, this.soId, this.viewOnly = false});

  @override
  Widget build(BuildContext context) {
    final tag = soId?.toString() ?? 'new';
    Get.delete<SalesInvoiceFormController>(tag: tag, force: true);
    final controller = Get.put(
      SalesInvoiceFormController(soId: soId, viewOnly: viewOnly),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Obx(() {
        if (viewOnly || controller.isLoading.value) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            heroTag: 'si_add_item_fab',
            onPressed: () => _showProductPicker(context, controller, null),
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
        title: viewOnly ? 'Sales Invoice' : (soId == null ? 'Create Invoice' : 'Invoice'),
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            if (!controller.isSaving.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 12),
                Text('Loading...', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(controller: controller, viewOnly: viewOnly),
                    const SizedBox(height: 6),
                    _ItemsCard(controller: controller, viewOnly: viewOnly),
                    const SizedBox(height: 6),
                    _SummaryCard(controller: controller),
                  ],
                ),
              ),
            ),
            if (!viewOnly)
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
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final SalesInvoiceFormController controller;
  final bool viewOnly;

  const _HeaderCard({required this.controller, required this.viewOnly});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Invoice Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Invoice Number + Doc Year ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: Obx(() => InputDecorator(
                        decoration: _siDec(labelText: 'Invoice Number'),
                        child: Text(
                          controller.invoiceNumber.value.isEmpty
                              ? 'Generating…'
                              : controller.invoiceNumber.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ),
              ),
              const SizedBox(width: _fieldGap),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: Obx(() {
                    final current = controller.billDocYear.value;
                    final options = <String>{
                      if (current.isNotEmpty) current,
                      ..._docYearOptions,
                    }.toList();
                    return DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: current.isEmpty ? null : current,
                      decoration: _siDec(labelText: 'Doc Year'),
                      isExpanded: true,
                      items: options
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: viewOnly
                          ? null
                          : (v) {
                              if (v != null) controller.billDocYear.value = v;
                            },
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),

          // ── Customer picker ───────────────────────────────────────────────
          FormField<int>(
            initialValue: controller.selectedCustomerId.value,
            validator: (v) => v == null ? 'Please select a customer' : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: viewOnly
                      ? null
                      : () async {
                          final party = await showDialog<PartyResult>(
                            context: context,
                            builder: (_) => PartySearchDialog(
                              title: 'Select Customer',
                              hint: 'Search by name, mobile or customer ID…',
                              searchFn: (q) =>
                                  CustomerApiService.searchPartyResults(query: q),
                            ),
                          );
                          if (party != null) {
                            controller.selectCustomer(party.id, party.name);
                            state.didChange(party.id);
                          }
                        },
                  child: InputDecorator(
                    decoration: _siDec(labelText: 'Customer *'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final id = controller.selectedCustomerId.value;
                            if (id == null) {
                              return const Text(
                                'Tap to select...',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            final name = controller.selectedCustomerName.value.isNotEmpty
                                ? controller.selectedCustomerName.value
                                : controller.customerName.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'ID: $id',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }),
                        ),
                        if (!viewOnly)
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

          // ── Source Order picker (only for new invoices not pre-loaded) ────
          if (controller.soId == null) ...[
            _OrderField(controller: controller, viewOnly: viewOnly),
            const SizedBox(height: _sectionGap),
          ],

          // ── Order Date (read-only when order linked) ──────────────────────
          Obx(() => controller.orderDate.value.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputDecorator(
                      decoration: _siDec(labelText: 'Order Date'),
                      child: Text(
                        _displayDate(controller.orderDate.value),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: _sectionGap),
                  ],
                )),

          // ── Invoice Date ──────────────────────────────────────────────────
          Obx(() => InkWell(
                onTap: viewOnly
                    ? null
                    : () => _pickDate(
                          context,
                          currentValue: controller.billDt.value,
                          onPicked: (v) => controller.billDt.value = v,
                        ),
                child: InputDecorator(
                  decoration: _siDec(
                    labelText: 'Invoice Date *',
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(
                    controller.billDt.value.isEmpty
                        ? 'Select date'
                        : _displayDate(controller.billDt.value),
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.billDt.value.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ),
              )),
          const SizedBox(height: _sectionGap),

          // ── Department ────────────────────────────────────────────────────
          _ObsField(
              obs: controller.billDepartment,
              label: 'Department',
              readOnly: viewOnly),
          const SizedBox(height: _sectionGap),

          // ── Bill Narration ────────────────────────────────────────────────
          _ObsField(
              obs: controller.billNarration,
              label: 'Bill Narration',
              readOnly: viewOnly),
          const SizedBox(height: _sectionGap),

          // ── Vehicle ───────────────────────────────────────────────────────
          _ObsField(
              obs: controller.billVehicle,
              label: 'Vehicle',
              readOnly: viewOnly),
          const SizedBox(height: _sectionGap),

          // ── Statement ─────────────────────────────────────────────────────
          _ObsField(
              obs: controller.billStatement,
              label: 'Bill Statement',
              readOnly: viewOnly),
          const SizedBox(height: _sectionGap),

          // ── Round Off ─────────────────────────────────────────────────────
          _ObsField(
            obs: controller.billRoff,
            label: 'Round Off',
            readOnly: viewOnly,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}'))
            ],
          ),
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
  final bool viewOnly;

  const _OrderField({required this.controller, required this.viewOnly});

  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
          onTap: viewOnly ? null : () => _showOrderPicker(context),
          child: InputDecorator(
            decoration: _siDec(
              labelText: 'Source Order (optional)',
              suffixIcon: viewOnly
                  ? null
                  : const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
            ),
            child: Text(
              controller.sourceOrderNumber.value.isEmpty
                  ? (viewOnly ? '-' : 'Tap to link a sales order')
                  : controller.sourceOrderNumber.value,
              style: TextStyle(
                fontSize: 14,
                color: controller.sourceOrderNumber.value.isEmpty
                    ? Colors.grey
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
  }

  Future<void> _showOrderPicker(BuildContext context) async {
    List<Map<String, dynamic>> results = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> doSearch(String q) async {
            setState(() => loading = true);
            results = await controller.searchOrders(q);
            setState(() => loading = false);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => doSearch(''));

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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('Select Pending Order',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  final orderNo = o['so_number']
                                          ?.toString() ??
                                      'ORD-${o['id']}';
                                  final customer =
                                      o['customer_name']?.toString() ?? '';
                                  final status =
                                      o['status']?.toString() ?? '';
                                  final date = _displayDate(
                                      o['doc_date']?.toString() ?? '');
                                  return ListTile(
                                    leading: const Icon(
                                        Icons.receipt_long_outlined,
                                        color: AppColors.primary),
                                    title: Text(orderNo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        '$customer  •  $status  •  $date'),
                                    onTap: () {
                                      final id = o['id'] is int
                                          ? o['id'] as int
                                          : int.tryParse(
                                              o['id']?.toString() ?? '');
                                      if (id != null) {
                                        Navigator.pop(ctx);
                                        controller.loadOrder(id);
                                      }
                                    },
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
  final bool viewOnly;

  const _ItemsCard({required this.controller, required this.viewOnly});

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
                message: 'No items. Tap "+" to add a product.',
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
                  viewOnly: viewOnly,
                  onPickProduct: () => _showProductPicker(
                      context, controller, controller.items[index]),
                ),
              ),
            if (!viewOnly) const SizedBox(height: _sectionGap),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item row — mirrors SO _ItemRow exactly
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends StatefulWidget {
  final SalesInvoiceFormController controller;
  final int index;
  final SILineRow row;
  final bool isLast;
  final bool viewOnly;
  final VoidCallback onPickProduct;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
    required this.isLast,
    required this.viewOnly,
    required this.onPickProduct,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.row.qtyDelivered.value);
    _priceCtrl = TextEditingController(text: widget.row.price.value);
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    if (widget.row.qtyDelivered.value != _qtyCtrl.text) {
      _qtyCtrl.text = widget.row.qtyDelivered.value;
      _qtyCtrl.selection =
          TextSelection.collapsed(offset: _qtyCtrl.text.length);
    }
    if (widget.row.price.value != _priceCtrl.text) {
      _priceCtrl.text = widget.row.price.value;
      _priceCtrl.selection =
          TextSelection.collapsed(offset: _priceCtrl.text.length);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final viewOnly = widget.viewOnly;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 2 : 5),
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
          // Item header badge + delete button
          Row(
            children: [
              Obx(() {
                final hsn = row.productCode.value.trim();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Item ${widget.index + 1}  |  HSN: ${hsn.isEmpty ? 'NA' : hsn}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (!viewOnly)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.redAccent,
                    onPressed: () =>
                        widget.controller.removeItem(widget.index),
                    tooltip: 'Remove',
                  ),
                ),
            ],
          ),
          const SizedBox(height: _sectionGap),

          // Product picker — mirrors SO _ProductPicker
          _ProductPicker(
            row: row,
            viewOnly: viewOnly,
            onPick: widget.onPickProduct,
          ),
          const SizedBox(height: _sectionGap),

          // Qty row: Ordered Qty (read-only, from SO) + Qty Delivered + Unit badge + Unit Price
          Row(
            children: [
              // Ordered Qty — only shown when item came from a linked SO
              Obx(() => row.orderedQtyDouble > 0
                  ? Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: _fieldVerticalGap),
                        child: TextFormField(
                          key: ValueKey('oq_${row.orderedQty.value}'),
                          enabled: false,
                          initialValue: row.orderedQty.value,
                          decoration: _siDec(labelText: 'Ordered Qty'),
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
                flex: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: TextFormField(
                    controller: _qtyCtrl,
                    enabled: !viewOnly,
                    decoration: _siDec(labelText: 'Qty Delivered *'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,3}'))
                    ],
                    onChanged: viewOnly ? null : (v) => row.qtyDelivered.value = v,
                  ),
                ),
              ),
              const SizedBox(width: _fieldGap),

              // Unit (read-only badge)
              Obx(() {
                final unit = row.unit.value;
                if (unit.isEmpty) return const SizedBox.shrink();
                return Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: _fieldVerticalGap),
                    child: InputDecorator(
                      decoration: _siDec(labelText: 'Unit').copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                      ),
                      child:
                          Text(unit, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                );
              }),
              const SizedBox(width: _fieldGap),

              // Unit Price
              Expanded(
                flex: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: _fieldVerticalGap),
                  child: Obx(() => row.orderedQtyDouble > 0
                      // From SO — price read-only
                      ? TextFormField(
                          key: ValueKey('price_${row.price.value}'),
                          enabled: false,
                          initialValue: row.price.value,
                          decoration: _siDec(labelText: 'Unit Price'),
                          style: const TextStyle(fontSize: 13),
                        )
                      // Manually added — price editable
                      : TextFormField(
                          controller: _priceCtrl,
                          enabled: !viewOnly,
                          decoration: _siDec(labelText: 'Unit Price *'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'))
                          ],
                          onChanged:
                              viewOnly ? null : (v) => row.price.value = v,
                        )),
                ),
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),

          // Line total — mirrors SO _readOnlyAmountField
          Obx(() {
            final qty = double.tryParse(row.qtyDelivered.value) ?? 0;
            final price = double.tryParse(row.price.value) ?? 0;
            final total = qty * price;
            return _readOnlyAmountField(
              label: 'Product Total',
              value: total.toStringAsFixed(2),
            );
          }),
        ],
      ),
    );
  }

  Widget _readOnlyAmountField(
      {required String label, required String value}) {
    return InputDecorator(
      decoration: _siDec(labelText: label),
      child: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product picker — mirrors SO _ProductPicker
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPicker extends StatelessWidget {
  final SILineRow row;
  final bool viewOnly;
  final VoidCallback onPick;

  const _ProductPicker({
    required this.row,
    required this.viewOnly,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: viewOnly ? null : onPick,
      child: InputDecorator(
        decoration: _siDec(labelText: 'Product *'),
        child: Row(
          children: [
            Obx(() {
              final name = row.productName.value;
              final hasProduct =
                  row.productId.value != null && name.isNotEmpty;
              final initial =
                  hasProduct ? name.trim()[0].toUpperCase() : null;
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
                return Text(
                  name.isEmpty ? 'Tap to search...' : name,
                  style: TextStyle(
                      color:
                          row.productId.value == null ? Colors.grey : null),
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ),
            if (!viewOnly)
              const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card — mirrors SO _SummaryCard
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      double itemsTotal = 0;
      for (final r in controller.items) {
        itemsTotal += r.lineTotal;
      }
      final roff = double.tryParse(controller.billRoff.value) ?? 0;
      final grand = itemsTotal + roff;

      return ContentCard(
        title: 'Summary',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow(
                'Gross Amount', '₹ ${itemsTotal.toStringAsFixed(2)}', false),
            if (roff != 0) ...[
              const SizedBox(height: 3),
              _summaryRow(
                  'Round Off', '₹ ${roff.toStringAsFixed(2)}', false),
            ],
            const SizedBox(height: 5),
            _summaryRow('Total', '₹ ${grand.toStringAsFixed(2)}', true),
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
// Product picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showProductPicker(
  BuildContext context,
  SalesInvoiceFormController controller,
  SILineRow? targetRow,
) async {
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> doSearch(String q) async {
          setState(() => loading = true);
          results = await controller.searchProducts(q);
          setState(() => loading = false);
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.95,
          builder: (_, scroll) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('Select Product',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
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
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by product name or code…',
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
                                  icon: Icons.inventory_2_outlined,
                                  message: 'Type to search products',
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scroll,
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final p = results[i];
                                final id = p['id'] is int
                                    ? p['id'] as int
                                    : int.tryParse(
                                            p['id']?.toString() ?? '') ??
                                        0;
                                final name =
                                    p['product_name']?.toString() ??
                                        p['name']?.toString() ??
                                        '';
                                final code =
                                    p['product_code']?.toString() ?? '';
                                final unit =
                                    p['unit']?.toString() ?? 'Nos';
                                final price = double.tryParse(
                                        p['price']?.toString() ?? '') ??
                                    0.0;
                                return ListTile(
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLighter,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.primaryLight,
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: code.isNotEmpty
                                      ? Text(code)
                                      : null,
                                  trailing: price > 0
                                      ? Text(
                                          '₹${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    if (targetRow != null) {
                                      controller.applyProduct(targetRow,
                                          id, name, code, unit, price);
                                    } else {
                                      controller.addItem();
                                      controller.applyProduct(
                                          controller.items.last,
                                          id,
                                          name,
                                          code,
                                          unit,
                                          price);
                                    }
                                  },
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
      decoration: _siDec(labelText: widget.label),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.readOnly ? null : (v) => widget.obs.value = v,
    );
  }
}
