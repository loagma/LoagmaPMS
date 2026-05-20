import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/sales_invoice_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _dec({required String label, String? hint, Widget? suffix}) {
  return AppInputDecoration.standard(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
  ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always);
}

/// Formats a YYYY-MM-DD string to DD-MM-YYYY for display.
String _fmtDate(String raw) {
  if (raw.isEmpty) return '';
  final parts = raw.split('-');
  if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
  return raw;
}

Future<String?> _pickDate(BuildContext context, String current) async {
  final initial = DateTime.tryParse(current) ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    ),
  );
  if (picked == null) return null;
  return '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
      appBar: ModuleAppBar(
        title: viewOnly ? 'Sales Invoice' : (soId == null ? 'New Invoice' : 'Edit Invoice'),
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            if (controller.isSaving.value) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              );
            }
            if (viewOnly) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              tooltip: 'Save Invoice',
              onPressed: controller.save,
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          children: [
            _HeaderCard(controller: controller, viewOnly: viewOnly),
            const SizedBox(height: 10),
            _ItemsCard(controller: controller, viewOnly: viewOnly),
            const SizedBox(height: 10),
            _SummaryCard(controller: controller),
          ],
        );
      }),
      floatingActionButton: viewOnly
          ? null
          : Obx(() => FloatingActionButton.extended(
                onPressed: controller.isSaving.value ? null : controller.save,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: controller.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save Invoice'),
              )),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),

          // ── Invoice Number (auto, read-only) ──────────────────────────────
          Obx(() => TextFormField(
            key: ValueKey(controller.invoiceNumber.value),
            initialValue: controller.invoiceNumber.value.isEmpty
                ? 'Generating…'
                : controller.invoiceNumber.value,
            readOnly: true,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            decoration: _dec(label: 'Invoice Number'),
          )),
          const SizedBox(height: 10),

          // ── Step 1: Customer picker (only when creating new) ──────────────
          if (controller.soId == null) ...[
            _CustomerPickerField(controller: controller),
            const SizedBox(height: 10),

            // ── Step 2: Order picker (only after customer selected) ──────────
            Obx(() => controller.selectedCustomerId.value == null
                ? const SizedBox.shrink()
                : _OrderPickerField(controller: controller)),
            Obx(() => controller.selectedCustomerId.value == null
                ? const SizedBox.shrink()
                : const SizedBox(height: 10)),
          ],

          // ── Customer display (auto-filled from loaded order) ──────────────
          Obx(() => controller.customerName.value.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    TextFormField(
                      key: ValueKey(controller.customerName.value),
                      initialValue: controller.customerName.value,
                      readOnly: true,
                      decoration: _dec(label: 'Customer'),
                    ),
                    const SizedBox(height: 10),
                  ],
                )),

          // ── Order Date (read-only, formatted) ────────────────────────────
          Obx(() => controller.orderDate.value.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    TextFormField(
                      key: ValueKey(controller.orderDate.value),
                      initialValue: _fmtDate(controller.orderDate.value),
                      readOnly: true,
                      decoration: _dec(label: 'Order Date'),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                  ],
                )),

          // ── Invoice Date (date picker) ────────────────────────────────────
          Obx(() => InkWell(
            onTap: viewOnly
                ? null
                : () async {
                    final v = await _pickDate(context, controller.billDt.value);
                    if (v != null) controller.billDt.value = v;
                  },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: _dec(
                label: 'Invoice Date *',
                suffix: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: viewOnly ? AppColors.textMuted : AppColors.primary,
                ),
              ),
              child: Text(
                controller.billDt.value.isEmpty
                    ? 'Select date'
                    : _fmtDate(controller.billDt.value),
                style: TextStyle(
                  fontSize: 14,
                  color: controller.billDt.value.isEmpty ? Colors.grey : null,
                ),
              ),
            ),
          )),
          const SizedBox(height: 10),

          // ── Department (free text) ─────────────────────────────────────────
          _EditableField(
            obs: controller.billDepartment,
            label: 'Department',
            readOnly: viewOnly,
          ),
          const SizedBox(height: 10),

          // ── Narration ─────────────────────────────────────────────────────
          _EditableField(
            obs: controller.billNarration,
            label: 'Narration',
            readOnly: viewOnly,
            maxLines: 2,
          ),
          const SizedBox(height: 10),

          // ── Vehicle ───────────────────────────────────────────────────────
          _EditableField(
            obs: controller.billVehicle,
            label: 'Vehicle',
            readOnly: viewOnly,
          ),
          const SizedBox(height: 10),

          // ── Statement ─────────────────────────────────────────────────────
          _EditableField(
            obs: controller.billStatement,
            label: 'Statement',
            readOnly: viewOnly,
          ),
          const SizedBox(height: 10),

          // ── Round Off + Doc Year (side by side) ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EditableField(
                  obs: controller.billRoff,
                  label: 'Round Off',
                  readOnly: viewOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}'))],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() {
                  final current = controller.billDocYear.value;
                  final valid = _docYearOptions.contains(current);
                  return DropdownButtonFormField<String>(
                    initialValue: valid ? current : null,
                    decoration: _dec(label: 'Doc Year'),
                    items: _docYearOptions
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: viewOnly ? null : (v) => controller.billDocYear.value = v ?? current,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer picker (step 1)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerPickerField extends StatelessWidget {
  final SalesInvoiceFormController controller;
  const _CustomerPickerField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _dec(
          label: 'Customer *',
          hint: 'Tap to select customer',
          suffix: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        ),
        child: Text(
          controller.selectedCustomerName.value.isEmpty
              ? 'Tap to select customer'
              : controller.selectedCustomerName.value,
          style: TextStyle(
            fontSize: 14,
            color: controller.selectedCustomerName.value.isEmpty ? Colors.grey : null,
          ),
        ),
      ),
    ));
  }

  Future<void> _showPicker(BuildContext context) async {
    List<Map<String, dynamic>> results = [];
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> doSearch(String q) async {
            setState(() => loading = true);
            results = await controller.searchCustomers(q);
            setState(() => loading = false);
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (_, scroll) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name, mobile or customer ID…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => doSearch(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty
                            ? const Center(child: Text('Type to search customers', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                controller: scroll,
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final c = results[i];
                                  final id = int.tryParse(c['id']?.toString() ?? '') ?? 0;
                                  final name = c['name']?.toString() ?? '';
                                  final shop = c['shop_name']?.toString() ?? '';
                                  final phone = c['phone']?.toString() ?? '';
                                  final subtitle = [shop, phone]
                                      .where((s) => s.isNotEmpty)
                                      .join('  •  ');
                                  return ListTile(
                                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      controller.selectCustomer(id, name);
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
// Order picker (step 2 — filtered by selected customer)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderPickerField extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _OrderPickerField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
      onTap: () => _showOrderPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _dec(
          label: 'Source Order (optional)',
          hint: 'Tap to link a sales order',
          suffix: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        ),
        child: Text(
          controller.sourceOrderNumber.value.isEmpty
              ? 'Tap to link a sales order'
              : controller.sourceOrderNumber.value,
          style: TextStyle(
            fontSize: 14,
            color: controller.sourceOrderNumber.value.isEmpty ? Colors.grey : null,
          ),
        ),
      ),
    ));
  }

  Future<void> _showOrderPicker(BuildContext context) async {
    List<Map<String, dynamic>> results = [];
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> doSearch(String q) async {
            setState(() => loading = true);
            results = await controller.searchOrders(q);
            setState(() => loading = false);
          }

          // Auto-load orders on open
          WidgetsBinding.instance.addPostFrameCallback((_) => doSearch(''));

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (_, scroll) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select Pending Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by order number…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => doSearch(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty
                            ? const Center(
                                child: Text(
                                  'No pending orders found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: scroll,
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final o = results[i];
                                  final orderNo = o['so_number']?.toString() ?? 'ORD-${o['id']}';
                                  final customer = o['customer_name']?.toString() ?? '';
                                  final status = o['status']?.toString() ?? '';
                                  final date = _fmtDate(o['doc_date']?.toString() ?? '');
                                  return ListTile(
                                    leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                                    title: Text(
                                      orderNo,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text('$customer  •  $status  •  $date'),
                                    onTap: () {
                                      final orderId = o['id'] is int
                                          ? o['id'] as int
                                          : int.tryParse(o['id']?.toString() ?? '');
                                      if (orderId != null) {
                                        Navigator.pop(ctx);
                                        controller.loadOrder(orderId);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        controller.sourceOrderNumber.value.isEmpty
                            ? 'No items — link a sales order or add items manually.'
                            : 'No items — select a source order above.',
                        style: const TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: controller.items.asMap().entries.map((e) {
                return _ItemRow(
                  index: e.key,
                  row: e.value,
                  viewOnly: viewOnly,
                  onRemove: viewOnly ? null : () => controller.removeItem(e.key),
                  onSelectProduct: viewOnly
                      ? null
                      : () => _showProductPicker(context, controller, e.value),
                );
              }).toList(),
            );
          }),

          // ── Add Item button (hidden in viewOnly) ──────────────────────────
          if (!viewOnly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  controller.addItem();
                  // Auto-open product picker for the new row
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (controller.items.isNotEmpty) {
                      _showProductPicker(context, controller, controller.items.last);
                    }
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                label: const Text('Add Item', style: TextStyle(color: AppColors.primary)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showProductPicker(
    BuildContext context,
    SalesInvoiceFormController controller,
    SILineRow row,
  ) async {
    List<Map<String, dynamic>> results = [];
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
            builder: (_, scroll) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by product name or code…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => doSearch(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty
                            ? const Center(child: Text('Type to search products', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                controller: scroll,
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final p = results[i];
                                  final id = p['id'] is int
                                      ? p['id'] as int
                                      : int.tryParse(p['id']?.toString() ?? '') ?? 0;
                                  final name = p['product_name']?.toString() ?? p['name']?.toString() ?? '';
                                  final code = p['product_code']?.toString() ?? '';
                                  final unit = p['unit']?.toString() ?? 'Nos';
                                  final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
                                  return ListTile(
                                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: code.isNotEmpty ? Text(code) : null,
                                    trailing: price > 0
                                        ? Text('₹${price.toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600))
                                        : null,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      controller.applyProduct(row, id, name, code, unit, price);
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

class _ItemRow extends StatefulWidget {
  final int index;
  final SILineRow row;
  final bool viewOnly;
  final VoidCallback? onRemove;
  final VoidCallback? onSelectProduct;

  const _ItemRow({
    required this.index,
    required this.row,
    required this.viewOnly,
    this.onRemove,
    this.onSelectProduct,
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
      _qtyCtrl.selection = TextSelection.collapsed(offset: _qtyCtrl.text.length);
    }
    if (widget.row.price.value != _priceCtrl.text) {
      _priceCtrl.text = widget.row.price.value;
      _priceCtrl.selection = TextSelection.collapsed(offset: _priceCtrl.text.length);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name row + index badge + remove button
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    final name = row.productName.value;
                    final isEmpty = name.isEmpty;
                    return GestureDetector(
                      onTap: viewOnly ? null : widget.onSelectProduct,
                      child: Text(
                        isEmpty ? (viewOnly ? 'Product' : 'Tap to select product…') : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isEmpty ? AppColors.textMuted : null,
                        ),
                      ),
                    );
                  }),
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    row.unit.value,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                )),
                if (!viewOnly && widget.onRemove != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Ordered Qty (read-only if from SO, hidden if 0) | Qty Delivered
            Row(
              children: [
                Obx(() => row.orderedQtyDouble > 0
                    ? Expanded(
                        child: TextFormField(
                          key: ValueKey('ordered_${row.orderedQty.value}'),
                          initialValue: row.orderedQty.value,
                          readOnly: true,
                          decoration: _dec(label: 'Ordered Qty'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    : const SizedBox.shrink()),
                Obx(() => row.orderedQtyDouble > 0
                    ? const SizedBox(width: 8)
                    : const SizedBox.shrink()),
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    readOnly: viewOnly,
                    decoration: _dec(label: 'Qty Delivered *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                    ],
                    style: const TextStyle(fontSize: 13),
                    onChanged: viewOnly ? null : (v) => row.qtyDelivered.value = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Unit Price (editable for manually added items) | Line Total
            Row(
              children: [
                Expanded(
                  child: Obx(() => row.orderedQtyDouble > 0
                      // From SO: price is read-only
                      ? TextFormField(
                          key: ValueKey('price_${row.price.value}'),
                          initialValue: '₹ ${row.price.value}',
                          readOnly: true,
                          decoration: _dec(label: 'Unit Price'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        )
                      // Manually added: price is editable
                      : TextFormField(
                          controller: _priceCtrl,
                          readOnly: viewOnly,
                          decoration: _dec(label: 'Unit Price *'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: const TextStyle(fontSize: 13),
                          onChanged: viewOnly ? null : (v) => row.price.value = v,
                        )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    final qty = double.tryParse(row.qtyDelivered.value) ?? 0;
                    final price = double.tryParse(row.price.value) ?? 0;
                    final total = qty * price;
                    return TextFormField(
                      key: ValueKey('total_$total'),
                      initialValue: '₹ ${total.toStringAsFixed(2)}',
                      readOnly: true,
                      decoration: _dec(label: 'Line Total'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        fontSize: 13,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SalesInvoiceFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Obx(() {
            double itemsTotal = 0;
            for (final r in controller.items) {
              final qty = double.tryParse(r.qtyDelivered.value) ?? 0;
              final price = double.tryParse(r.price.value) ?? 0;
              itemsTotal += qty * price;
            }
            final roff = double.tryParse(controller.billRoff.value) ?? 0;
            final grand = itemsTotal + roff;

            return Column(
              children: [
                _SummaryRow(label: 'Items Total', value: itemsTotal),
                if (roff != 0) _SummaryRow(label: 'Round Off', value: roff),
                const Divider(height: 20),
                _SummaryRow(label: 'Invoice Total', value: grand, bold: true),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _SummaryRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? AppColors.primaryDark : AppColors.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹ ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editable text field that syncs from observable without reset on keystroke
// ─────────────────────────────────────────────────────────────────────────────

class _EditableField extends StatefulWidget {
  final RxString obs;
  final String label;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _EditableField({
    required this.obs,
    required this.label,
    required this.readOnly,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _ctrl;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.obs.value);
    // Sync when the observable changes externally (e.g. order loaded)
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
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      decoration: _dec(label: widget.label),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.readOnly ? null : (v) => widget.obs.value = v,
    );
  }
}
