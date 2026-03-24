import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_voucher_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PurchaseVoucherScreen extends StatelessWidget {
  final int? voucherId;

  const PurchaseVoucherScreen({super.key, this.voucherId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseVoucherController(voucherId: voucherId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Purchase Voucher' : 'Purchase Voucher',
        subtitle: 'Record purchase invoice',
        onBackPressed: () => Get.back(),
        actions: [
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

        return Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 600
                  ? 600.0
                  : constraints.maxWidth - 32;

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderCard(controller: controller),
                              const SizedBox(height: 16),
                              _ExtraGstCard(controller: controller),
                              const SizedBox(height: 16),
                              _ItemsCard(controller: controller),
                              const SizedBox(height: 16),
                              _ChargesCard(controller: controller),
                              const SizedBox(height: 16),
                              _NetTotalCard(controller: controller),
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
              );
            },
          ),
        );
      }),
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

  Future<void> _onSelectPo(BuildContext context, int poId) async {
    final nav = Navigator.of(context);
    setState(() => _loading = true);
    final po = await widget.controller.fetchPurchaseOrderById(poId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (po == null) {
      Get.snackbar(
        'Error',
        'Could not load purchase order details.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    widget.controller.loadFromPurchaseOrder(po);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Link to Purchase Order',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
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
                    decoration: AppInputDecoration.standard(
                      labelText: 'Search',
                      hintText: 'Supplier name, PO no or ID',
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
                                  [if (supplier.isNotEmpty) supplier, if (docDate.isNotEmpty) docDate, status]
                                      .where((e) => e.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () => _onSelectPo(context, id),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : widget.onClose,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseVoucherController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Document',
      titleAction: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(() {
            if (controller.linkedPurchaseOrderId.value == null) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Text(
                    'Linked to PO: ${controller.linkedPoNumber.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Obx(() {
            final docNo = controller.docNoNumber.value.trim().isEmpty
                ? ''
                : '${controller.docNoPrefix.value}${controller.docNoNumber.value}';
            if (docNo.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doc No: $docNo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                  tooltip: 'Previous Voucher',
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.goToPreviousVoucher(),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  tooltip: 'Next Voucher',
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.goToNextVoucher(),
                ),
              ],
            );
          }),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.docNoPrefix.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Doc No Prefix',
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
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(() => TextFormField(
                      initialValue: controller.docNoNumber.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Doc No *',
                        hintText: 'Auto',
                      ),
                      readOnly: true,
                      enabled: false,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final list = controller.suppliers;
            return DropdownButtonFormField<int>(
              value: controller.vendorId.value,
              decoration: AppInputDecoration.standard(labelText: 'Vendor *'),
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
          const SizedBox(height: 8),
          Obx(() => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.vendorId.value == null
                      ? null
                      : () => _showLinkToPurchaseOrderDialog(context, controller),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Link Purchase Order'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          Obx(() => TextFormField(
                initialValue: controller.narration.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Narration',
                  hintText: 'Optional notes...',
                ),
                maxLines: 2,
                onChanged: controller.setNarration,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.docDate.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Doc Date *',
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onChanged: controller.setDocDate,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.billNo.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Bill No *',
                        hintText: 'Supplier invoice no',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onChanged: controller.setBillNo,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => CheckboxListTile(
                title: const Text(
                  'Do not Update Inventory',
                  style: TextStyle(fontSize: 14),
                ),
                value: controller.doNotUpdateInventory.value,
                onChanged: (v) =>
                    controller.setDoNotUpdateInventory(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.purchaseType.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Invoice Type',
                      ),
                      isExpanded: true,
                      items: ['Regular', 'Return', 'Proforma']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.setPurchaseType(v);
                      },
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.gstReverseCharge.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'GST Reverse Charge',
                      ),
                      isExpanded: true,
                      items: ['Y', 'N']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.setGstReverseCharge(v);
                      },
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
                      value: controller.purchaseAgents
                              .contains(controller.purchaseAgentId.value)
                          ? controller.purchaseAgentId.value
                          : (controller.purchaseAgents.isNotEmpty
                              ? controller.purchaseAgents.first
                              : ''),
                      decoration: AppInputDecoration.standard(
                        labelText: 'Salesman',
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      isExpanded: true,
                      items: controller.purchaseAgents
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.setPurchaseAgentId(v);
                      },
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.billDate.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Bill Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onChanged: controller.setBillDate,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: AppInputDecoration.standard(
                    labelText: 'GST Type',
                    hintText: 'e.g. OE',
                  ),
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: AppInputDecoration.standard(
                    labelText: 'Vehicle No',
                    hintText: 'Optional',
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
      title: 'Item Details',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.items.length,
              itemBuilder: (context, index) {
                return _ItemRow(
                  controller: controller,
                  index: index,
                  row: controller.items[index],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => controller.addItemRow(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
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

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final excludeIds = controller.items
        .where((r) => r != row && r.product.value != null)
        .map((r) => r.product.value!.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.redAccent,
                onPressed: () => controller.removeItemRow(index),
                tooltip: 'Remove',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProductPickerField(
            controller: controller,
            row: row,
            excludeIds: excludeIds.toSet(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => TextFormField(
                      initialValue: row.quantity.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Qty *',
                        hintText: '0.00',
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
                      },
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Obx(() {
                  final units = controller.unitTypes.isEmpty
                      ? ['Nos', 'KG', 'PCS', 'LTR']
                      : controller.unitTypes;
                  final value = units.contains(row.unitType.value)
                      ? row.unitType.value
                      : (units.isNotEmpty ? units.first : 'Nos');
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Unit',
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    isDense: true,
                    isExpanded: true,
                    iconSize: 18,
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: row.unitPrice.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Unit Price *',
                        hintText: '0.00',
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
                        if (p == null || p < 0) return 'Must be ≥ 0';
                        return null;
                      },
                      onChanged: (value) {
                        row.unitPrice.value = value;
                        controller.recalcItemRow(row);
                      },
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      key: ValueKey('taxable_$index'),
                      initialValue: row.taxableAmount.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Taxable',
                      ),
                      readOnly: true,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _smallNumField(row.sgst, 'SGST'),
              const SizedBox(width: 8),
              _smallNumField(row.cgst, 'CGST'),
              const SizedBox(width: 8),
              _smallNumField(row.igst, 'IGST'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _smallNumField(row.cess, 'Cess'),
              const SizedBox(width: 8),
              _smallNumField(row.roff, 'Roff'),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Value: ${row.value.value}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _smallNumField(Rx<String> obs, String label) {
    return Expanded(
      child: TextFormField(
        key: ValueKey('$label${obs.value}'),
        initialValue: obs.value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primaryLight),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          obs.value = v;
          controller.recalcItemRow(row);
        },
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
                  row.alias.value = '${product.name} : ${row.unitType.value}';
                  final unit = product.defaultUnit?.toString();
                  if (unit != null && unit.isNotEmpty && controller.unitTypes.contains(unit)) {
                    row.unitType.value = unit;
                  }
                  controller.recalcItemRow(row);
                  state.didChange(product);
                }
              },
              child: InputDecorator(
                decoration: AppInputDecoration.standard(
                  labelText: 'Product *',
                  hintText: 'Tap to search...',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            row.product.value?.name ?? '',
                            style: TextStyle(
                              color: row.product.value == null
                                  ? Colors.grey
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    if (row.product.value != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          row.product.value = null;
                          row.productName.value = '';
                          row.productCode.value = '';
                          row.alias.value = '';
                          controller.recalcItemRow(row);
                          state.didChange(null);
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
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

  @override
  void initState() {
    super.initState();
    _showAllProducts = widget.controller.vendorId.value == null;
    widget.controller.showAllProducts.value = _showAllProducts;
    _initialLoad();
  }

  @override
  void dispose() {
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
    await widget.controller.loadProductsForVendor(
      search: null,
      includeAll: _showAllProducts,
    );
    await _refreshFromController();
  }

  Future<void> _onSearch(String query) async {
    await widget.controller.loadProductsForVendor(
      search: query.isEmpty ? null : query,
      includeAll: _showAllProducts,
    );
    await _refreshFromController();
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _showAllProducts = !_showAllProducts;
      widget.controller.showAllProducts.value = _showAllProducts;
    });
    await widget.controller.loadProductsForVendor(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      includeAll: _showAllProducts,
    );
    setState(() {
      _filtered = widget.controller.products
          .where((p) => !widget.excludeIds.contains(p.id))
          .take(50)
          .toList();
    });
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
              decoration: AppInputDecoration.standard(
                labelText: 'Name or code',
                hintText: 'Type to search...',
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
                    TextButton(
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
      title: 'Charges / Discounts',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.charges.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No charges. Tap Add to add Freight, TCS, Discount, etc.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.charges.length,
                itemBuilder: (context, index) {
                  final row = controller.charges[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
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
                                decoration: AppInputDecoration.standard(
                                  labelText: 'Name',
                                ).copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() => TextFormField(
                                initialValue: row.amount.value,
                                decoration: AppInputDecoration.standard(
                                  labelText: 'Amount',
                                  hintText: '0',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (v) => row.amount.value = v,
                              )),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Colors.redAccent,
                          onPressed: () => controller.removeChargeRow(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => controller.addChargeRow(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _NetTotalCard extends StatelessWidget {
  final PurchaseVoucherController controller;

  const _NetTotalCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLighter.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Net Total: ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              controller.netTotal,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      );
    });
  }
}
