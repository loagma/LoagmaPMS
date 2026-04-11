import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/purchase_voucher_controller.dart';
import '../../models/purchase_order_model.dart';
import '../../models/product_model.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

InputDecoration _pvInputDecoration({
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

Future<void> _pickDocumentDate(
  BuildContext context,
  PurchaseVoucherController controller,
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

Future<void> _printVoucherReport(PurchaseVoucherController controller) async {
  try {
    await ReportExportService.printPurchaseVoucher(controller);
  } catch (e) {
    Get.snackbar(
      'Print failed',
      'Could not generate voucher PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

Future<void> _shareVoucherReport(PurchaseVoucherController controller) async {
  try {
    await ReportExportService.sharePurchaseVoucher(controller);
  } catch (e) {
    Get.snackbar(
      'Share failed',
      'Could not share voucher PDF: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

class PurchaseVoucherScreen extends StatelessWidget {
  final int? voucherId;
  final bool? startInReportMode;

  const PurchaseVoucherScreen({
    super.key,
    this.voucherId,
    this.startInReportMode,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PurchaseVoucherController(
        voucherId: voucherId,
        startInReportMode: startInReportMode ?? false,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Purchase Voucher' : 'Purchase Voucher',
        subtitle: 'Record purchase invoice',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            if (!controller.isReportMode) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              tooltip: 'Print/PDF',
              onPressed: () async => _printVoucherReport(controller),
            );
          }),
          Obx(() {
            if (!controller.isReportMode) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Share/Export',
              onPressed: () async => _shareVoucherReport(controller),
            );
          }),
          Obx(() {
            if (!controller.canEditFromReport) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: controller.enterEditMode,
            );
          }),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Enter vendor, bill details and line items. Save as draft or post. Use Link to fill from a Purchase Order.',
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
            final maxWidth = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth - 32;

            if (controller.isReportMode) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: _VoucherReportView(controller: controller),
                        ),
                      ),
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
                        onPressed: () async => _printVoucherReport(controller),
                      ),
                      ActionButton(
                        label: 'Share',
                        onPressed: () async => _shareVoucherReport(controller),
                      ),
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
                              const SizedBox(height: 6),
                              _ExtraGstCard(controller: controller),
                              const SizedBox(height: 6),
                              _ItemsCard(controller: controller),
                              const SizedBox(height: 6),
                              _ChargesCard(controller: controller),
                              const SizedBox(height: 6),
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
                          onPressed: controller.isSaving.value
                              ? null
                              : () => Get.back(),
                        ),
                        ActionButton(
                          label: 'Save as Draft',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.saveDraft(),
                        ),
                        ActionButton(
                          label: 'Post',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.confirmPost(),
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

class _VoucherReportView extends StatelessWidget {
  final PurchaseVoucherController controller;

  const _VoucherReportView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final docNo =
          '${controller.docNoPrefix.value}${controller.docNoNumber.value.trim()}';
      final rows = controller.items;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentCard(
            title: 'Purchase Voucher Invoice',
            child: Column(
              children: [
                _metaRow('Voucher No', docNo.trim().isEmpty ? '-' : docNo),
                _metaRow('Status', controller.status.value),
                _metaRow('Supplier', controller.vendorName.value.trim().isEmpty ? '-' : controller.vendorName.value.trim()),
                _metaRow('Document Date', _normalizeDate(controller.docDate.value)),
                _metaRow('Bill No', controller.billNo.value.trim().isEmpty ? '-' : controller.billNo.value.trim()),
                _metaRow('Bill Date', _normalizeDate(controller.billDate.value)),
                _metaRow('Purchase Type', controller.purchaseType.value.trim().isEmpty ? '-' : controller.purchaseType.value.trim()),
                _metaRow('GST Reverse Charge', controller.gstReverseCharge.value.trim().isEmpty ? '-' : controller.gstReverseCharge.value.trim()),
                _metaRow('Purchase Agent', controller.purchaseAgentId.value.trim().isEmpty ? '-' : controller.purchaseAgentId.value.trim()),
                _metaRow('Linked PO', controller.linkedPoNumbers.isEmpty ? '-' : controller.linkedPoNumbers.join(', ')),
                _metaRow('Narration', controller.narration.value.trim().isEmpty ? '-' : controller.narration.value.trim(), isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ContentCard(
            title: 'Items',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1220),
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
                    DataColumn(label: Text('PO')),
                    DataColumn(label: Text('Used')),
                    DataColumn(label: Text('Left')),
                    DataColumn(label: Text('Over')),
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
                    final used = double.tryParse(row.usedQty.value) ?? 0;
                    final left = double.tryParse(row.leftQty.value) ?? 0;
                    final overrun = double.tryParse(row.overrunQty.value) ?? 0;
                    final overrunActive = overrun > 0.000001 || row.isOverrunApproved.value;

                    return DataRow(
                      color: overrunActive
                          ? WidgetStateProperty.all(
                              Colors.orange.withValues(alpha: 0.08),
                            )
                          : null,
                      cells: [
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
                        DataCell(Text(row.sourcePoNumber.value.trim().isEmpty ? '-' : row.sourcePoNumber.value.trim())),
                        DataCell(Text(used.toStringAsFixed(1))),
                        DataCell(Text(left.toStringAsFixed(1))),
                        DataCell(
                          overrunActive
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.45)),
                                  ),
                                  child: Text(
                                    '+${overrun.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : const Text('-'),
                        ),
                        DataCell(Text(total.toStringAsFixed(2))),
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
                          child: _metaRow(
                            row.name.value,
                            (double.tryParse(row.amount.value) ?? 0)
                                .toStringAsFixed(2),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 6),
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

  
}

Future<void> _showLinkToPurchaseOrderDialog(
  BuildContext context,
  PurchaseVoucherController controller,
) async {
  final supplierId = controller.vendorId.value;
  if (supplierId == null) {
    Get.snackbar(
      'Select Supplier',
      'Please select supplier first to view purchase orders.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  final list = await controller.fetchPurchaseOrdersForLink(
    supplierId: supplierId,
  );
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _LinkToPODialog(
      list: list,
      supplierId: supplierId,
      controller: controller,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

class _LinkToPODialog extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final int supplierId;
  final PurchaseVoucherController controller;
  final VoidCallback onClose;

  const _LinkToPODialog({
    required this.list,
    required this.supplierId,
    required this.controller,
    required this.onClose,
  });

  @override
  State<_LinkToPODialog> createState() => _LinkToPODialogState();
}

class _LinkToPODialogState extends State<_LinkToPODialog> {
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  final Set<int> _selectedPoIds = <int>{};
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
      final results = await widget.controller.fetchPurchaseOrdersForLink(
        search: q.isEmpty ? null : q,
        supplierId: widget.supplierId,
      );
      if (!mounted) return;

      // Additional client-side filter by supplier name, PO number or ID.
      final lower = q.toLowerCase();
      final filtered = q.isEmpty
          ? results
          : results.where((po) {
              final poNo =
                  (po['po_number'] ?? '').toString().toLowerCase();
              final supplier =
                  (po['supplier_name'] ?? '').toString().toLowerCase();
              final idStr = (po['id'] ?? '').toString().toLowerCase();
              return poNo.contains(lower) ||
                  supplier.contains(lower) ||
                  idStr.contains(lower);
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
    if (_selectedPoIds.isEmpty) return;

    final nav = Navigator.of(context);
    setState(() => _loading = true);
    final orderedIds = <int>[];
    for (final po in _items) {
      final id = po['id'] as int?;
      if (id != null && _selectedPoIds.contains(id)) {
        orderedIds.add(id);
      }
    }
    for (final id in _selectedPoIds) {
      if (!orderedIds.contains(id)) {
        orderedIds.add(id);
      }
    }

    final purchaseOrders = <PurchaseOrder>[];
    for (final poId in orderedIds) {
      final po = await widget.controller.fetchPurchaseOrderById(poId);
      if (po != null) {
        purchaseOrders.add(po);
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (purchaseOrders.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not load selected purchase order details.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    await widget.controller.loadFromPurchaseOrders(purchaseOrders);
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
              _selectedPoIds.isEmpty
                  ? 'Link to Purchase Order'
                  : 'Link to Purchase Order (${_selectedPoIds.length} selected)',
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
                      'Loading purchase orders...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: _pvInputDecoration(
                      labelText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text(
                              'No purchase orders found. Try a different supplier name, PO no or ID.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final po = _items[index];
                              final id = po['id'] as int?;
                              final poNumber = po['po_number']?.toString() ?? 'PO';
                              final supplier = po['supplier_name']?.toString() ?? '';
                              final docDate = po['doc_date']?.toString() ?? '';
                              final status = po['status']?.toString() ?? '';
                              if (id == null) return const SizedBox.shrink();
                              final formattedDate = _formatPurchaseOrderDate(docDate);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                                  child: const Icon(Icons.description_outlined, color: AppColors.primaryDark),
                                ),
                                title: Text(
                                  poNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  [
                                    if (supplier.isNotEmpty) supplier,
                                    if (formattedDate.isNotEmpty) formattedDate,
                                    status,
                                  ]
                                      .where((e) => e.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Checkbox(
                                  value: _selectedPoIds.contains(id),
                                  onChanged: _loading
                                      ? null
                                      : (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedPoIds.add(id);
                                            } else {
                                              _selectedPoIds.remove(id);
                                            }
                                          });
                                        },
                                ),
                                onTap: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_selectedPoIds.contains(id)) {
                                            _selectedPoIds.remove(id);
                                          } else {
                                            _selectedPoIds.add(id);
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
          onPressed: _loading || _selectedPoIds.isEmpty
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

String _formatPurchaseOrderDate(String rawValue) {
  final raw = rawValue.trim();
  if (raw.isEmpty) return '';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    if (raw.length >= 10 && raw.contains('T')) {
      return raw.substring(0, 10);
    }
    return raw;
  }

  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}

class _HeaderCard extends StatelessWidget {
  final PurchaseVoucherController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Supplier & Dates',
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
                        decoration: _pvInputDecoration(
                          labelText: 'Financial Year',
                        ),
                        isExpanded: true,
                        items: ['25-26/', '24-25/']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.setDocNoPrefix(v);
                        },
                      )),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 47,
                  child: Obx(() {
                    final seq = controller.currentSeq.value;
                    final docNo = controller.docNoNumber.value.trim();
                    final labelText = docNo.isNotEmpty
                        ? docNo
                        : (seq != null ? seq.toString() : '');
                    return InputDecorator(
                      decoration: _pvInputDecoration(
                        labelText: 'Voucher No',
                      ),
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
                            constraints: const BoxConstraints.tightFor(
                              width: 26,
                              height: 26,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.keyboard_arrow_left_rounded,
                              size: 18,
                            ),
                            tooltip: 'Previous Voucher',
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.goToPreviousVoucher(),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(
                              width: 26,
                              height: 26,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 18,
                            ),
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
          const SizedBox(height: 10),
          Obx(() {
            final list = controller.suppliers;
            return DropdownButtonFormField<int>(
              value: controller.vendorId.value,
              decoration: _pvInputDecoration(labelText: 'Supplier *'),
              isExpanded: true,
              items: list
                  .map((s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          '${s['supplier_code'] ?? s['id']} - ${s['supplier_name'] ?? 'Vendor'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  final s = list.cast<Map<String, dynamic>>().firstWhere(
                        (e) => e['id'] == v,
                        orElse: () => {'supplier_name': 'Vendor'},
                      );
                  controller.setVendor(v, s['supplier_name']?.toString() ?? '');
                }
              },
              validator: (v) => v == null ? 'Please select Vendor' : null,
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            final linkedPoLabels = controller.linkedPoNumbers.isNotEmpty
                ? controller.linkedPoNumbers.toList()
                : controller.linkedPurchaseOrderIds
                    .map((id) => 'PO #$id')
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.vendorId.value == null
                      ? null
                      : () => _showLinkToPurchaseOrderDialog(context, controller),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Link Purchase Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (linkedPoLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: linkedPoLabels
                          .map(
                            (poLabel) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryLight),
                              ),
                              child: Text(
                                poLabel,
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
              ],
            );
          }),
          const SizedBox(height: 10),
          Obx(() => TextFormField(
                initialValue: controller.narration.value,
                decoration: _pvInputDecoration(
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.docDate.value,
                      readOnly: true,
                      decoration: _pvInputDecoration(
                        labelText: 'Document Date *',
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: () => _pickDocumentDate(context, controller),
                    )),
              ),
                    const SizedBox(width: 6),
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.billNo.value,
                      decoration: _pvInputDecoration(
                        labelText: 'Bill No',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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

class _ExtraGstCard extends StatelessWidget {
  final PurchaseVoucherController controller;

  const _ExtraGstCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Extra / GST',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: (() {
                        final current = controller.purchaseAgentId.value.trim();
                        final hasValue = controller.salesmen
                            .any((s) => s['id']?.toString() == current);
                        return hasValue ? current : null;
                      })(),
                      decoration: _pvInputDecoration(
                        labelText: 'Salesman',
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      isExpanded: true,
                      items: controller.salesmen
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id']?.toString(),
                                child: Text(
                                  s['name']?.toString() ?? 'Salesman',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: controller.setPurchaseAgentId,
                    )),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final upper = newValue.text.toUpperCase();
                      return newValue.copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(offset: upper.length),
                        composing: TextRange.empty,
                      );
                    }),
                  ],
                  decoration: _pvInputDecoration(
                    labelText: 'Vehicle No',
                  ),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final PurchaseVoucherController controller;

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
                message: 'No items. Tap "Add Product" to add lines.',
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
                onPressed: () => controller.addItemRow(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  final PurchaseVoucherController controller;
  final int index;
  final PVItemRow row;
  final bool isLast;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
    required this.isLast,
  });

  String _formatQtyDisplay(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null) return '0.0';
    return parsed.toStringAsFixed(1);
  }

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          Obx(() {
            final sourcePo = row.sourcePoNumber.value.trim();
            if (sourcePo.isEmpty) return const SizedBox.shrink();
            final used = _formatQtyDisplay(row.usedQty.value);
            final left = _formatQtyDisplay(row.leftQty.value);
            final overrun = _formatQtyDisplay(row.overrunQty.value);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.42)),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _infoChip(
                      'PO: $sourcePo',
                      textColor: AppColors.primaryDark,
                      bg: Colors.white,
                    ),
                    _infoChip(
                      'Used $used',
                      textColor: AppColors.textMuted,
                      bg: Colors.white,
                    ),
                    _infoChip(
                      'Left $left',
                      textColor: AppColors.textMuted,
                      bg: Colors.white,
                    ),
                    if (row.isOverrunApproved.value)
                      _infoChip(
                        'Over +$overrun',
                        textColor: Colors.deepOrange,
                        bg: Colors.orange.withValues(alpha: 0.14),
                        borderColor: Colors.orange,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 5),
          _ProductPickerField(
            controller: controller,
            row: row,
            excludeIds: excludeIds.toSet(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TextFormField(
                    controller: row.quantityController,
                    focusNode: row.quantityFocusNode,
                    decoration: _pvInputDecoration(
                      labelText: 'Qty *',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,4}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) return 'Must be > 0';
                      return null;
                    },
                    onChanged: (value) {
                      row.quantity.value = value;
                      controller.recalcItemRow(row);
                      controller.scheduleQuantityValidation(row);
                    },
                    onEditingComplete: () async {
                      FocusScope.of(context).unfocus();
                      await controller.onQuantityEditCompleted(row);
                    },
                    onFieldSubmitted: (_) async {
                      await controller.onQuantityEditCompleted(row);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Obx(() {
                    final units = controller.unitTypes.isEmpty
                        ? ['Nos', 'KG', 'PCS', 'LTR']
                        : controller.unitTypes;
                    final value = units.contains(row.unitType.value)
                        ? row.unitType.value
                        : (units.isNotEmpty ? units.first : 'Nos');
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: _pvInputDecoration(
                        labelText: 'Unit',
                      ).copyWith(
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
                      onChanged: (v) {
                        if (v != null) {
                          row.unitType.value = v;
                        }
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Obx(() => TextFormField(
                        initialValue: row.unitPrice.value,
                        decoration: _pvInputDecoration(
                          labelText: 'Unit Price *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
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
            if (row.product.value == null || row.availableTaxKeys.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 5),
                _buildTaxRows(row),
              ],
            );
          }),
          const SizedBox(height: 5),
          _buildTaxTotals(row),
        ],
      ),
    );
  }

  Widget _buildTaxRows(PVItemRow row) {
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
                Expanded(
                  flex: 3,
                  child: Text('Tax',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Tax %',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Tax Amount',
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ...row.availableTaxKeys.map((key) {
            final percent =
                double.tryParse(row.taxFieldValues[key] ?? '') ?? 0;
            final amount = taxable * percent / 100;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(key, style: const TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${percent.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(amount.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildTaxTotals(PVItemRow row) {
    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
            final total = double.tryParse(row.value.value) ?? 0;
            final tax = total - taxable;
            return _readOnlyAmountField(
              label: 'Total Tax',
              value: tax,
            );
          }),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() => _readOnlyAmountField(
                label: 'Product Total',
                value: double.tryParse(row.value.value) ?? 0,
              )),
        ),
      ],
    );
  }

  Widget _readOnlyAmountField({
    required String label,
    required double value,
  }) {
    final display = value.abs() < 0.000001 ? '' : value.toStringAsFixed(2);
    return InputDecorator(
      decoration: _pvInputDecoration(labelText: label),
      child: Text(
        display,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _infoChip(
    String label, {
    required Color textColor,
    required Color bg,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? AppColors.primaryLight.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.1,
        ),
      ),
    );
  }
}

class _ProductPickerField extends StatelessWidget {
  final PurchaseVoucherController controller;
  final PVItemRow row;
  final Set<int> excludeIds;

  const _ProductPickerField({
    required this.controller,
    required this.row,
    required this.excludeIds,
  });

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
              onTap: () async {
                final product = await showDialog<Product>(
                  context: context,
                  builder: (ctx) => _PVProductSearchDialog(
                    controller: controller,
                    excludeIds: excludeIds,
                    current: row.product.value,
                  ),
                );
                if (product != null) {
                  row.product.value = product;
                  row.productName.value = product.name;
                  row.productCode.value = product.code ?? '${product.id}';
                  row.hsnCode.value = product.hsnCode ?? '';
                  row.alias.value = '${product.name} : ${row.unitType.value}';
                  final unit = product.defaultUnit?.toString();
                  if (unit != null && unit.isNotEmpty && controller.unitTypes.contains(unit)) {
                    row.unitType.value = unit;
                  }
                  await controller.applyResolvedTaxesToVoucherRow(
                    row,
                    productId: product.id,
                  );
                  state.didChange(product);
                }
              },
              child: InputDecorator(
                decoration: _pvInputDecoration(
                  labelText: 'Product *',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            row.product.value == null
                                ? 'Tap to search...'
                                : row.product.value!.name,
                            style: TextStyle(
                              color: row.product.value == null
                                  ? Colors.grey
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
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

class _PVProductSearchDialog extends StatefulWidget {
  final PurchaseVoucherController controller;
  final Set<int> excludeIds;
  final Product? current;

  const _PVProductSearchDialog({
    required this.controller,
    required this.excludeIds,
    this.current,
  });

  @override
  State<_PVProductSearchDialog> createState() => _PVProductSearchDialogState();
}

class _PVProductSearchDialogState extends State<_PVProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filtered = [];
  bool _showAllProducts = false;
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _showAllProducts = widget.controller.vendorId.value == null;
    widget.controller.showAllProducts.value = _showAllProducts;
    _initialLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromController() async {
    _filtered = widget.controller.products
        .where((p) => !widget.excludeIds.contains(p.id))
        .take(50)
        .toList();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initialLoad() async {
    await _runSearch(null);
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      if (_searchController.text != query) return;
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String? rawQuery) async {
    final query = rawQuery?.trim();
    await widget.controller.loadProductsForVendor(
      search: (query == null || query.isEmpty) ? null : query,
      includeAll: _showAllProducts,
    );
    if (!mounted) return;
    final currentText = _searchController.text.trim();
    final requestText = query ?? '';
    if (currentText != requestText) return;
    await _refreshFromController();
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _showAllProducts = !_showAllProducts;
      widget.controller.showAllProducts.value = _showAllProducts;
    });
    await _runSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: _pvInputDecoration(
                labelText: 'Name or code',
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No products',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final p = _filtered[i];
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text('ID: ${p.id}'),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final hasVendor =
                    widget.controller.vendorId.value != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasVendor)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Select vendor to filter by assigned products.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: hasVendor ? _toggleViewMode : null,
                      child: Text(
                        _showAllProducts
                            ? 'Show only products assigned to this vendor'
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
    );
  }
}

class _ChargesCard extends StatelessWidget {
  final PurchaseVoucherController controller;

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
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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
                              value: PurchaseVoucherController.chargeTypeNames
                                      .contains(row.name.value)
                                  ? row.name.value
                                  : PurchaseVoucherController.chargeTypeNames.first,
                              decoration: _pvInputDecoration(
                                labelText: 'Name',
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                              ),
                              isExpanded: true,
                              isDense: true,
                              items: PurchaseVoucherController.chargeTypeNames
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) row.name.value = v;
                              },
                            )),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Obx(() => TextFormField(
                              initialValue: row.amount.value,
                              decoration: _pvInputDecoration(
                                labelText: 'Amount',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (v) => row.amount.value = v,
                            )),
                      ),
                      const SizedBox(width: 2),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
  final PurchaseVoucherController controller;

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
            _summaryRow(
              'Gross Amount',
              '₹ ${grossAmount.toStringAsFixed(2)}',
              false,
            ),
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
              _summaryRow(
                'Round off Tax',
                '₹ ${roundOffTax.toStringAsFixed(2)}',
                false,
              ),
            ],
            if (chargesTotal != 0) ...[
              const SizedBox(height: 3),
              _summaryRow(
                'Add on total',
                '₹ ${chargesTotal.toStringAsFixed(2)}',
                false,
              ),
            ],
            const SizedBox(height: 5),
            _summaryRow(
              'Total',
              '₹ ${totalInclTax.toStringAsFixed(2)}',
              true,
            ),
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

