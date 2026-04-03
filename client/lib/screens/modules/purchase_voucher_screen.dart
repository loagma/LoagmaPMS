import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_voucher_controller.dart';
import '../../models/purchase_order_model.dart';
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
    return AlertDialog(
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
          child: const Text('Link Selected'),
        ),
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
      title: 'Supplier & Dates',
      titleAction: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(() {
            if (controller.linkedPurchaseOrderIds.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Linked Purchase Orders',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: controller.linkedPoNumbers.isNotEmpty
                        ? controller.linkedPoNumbers
                            .map((poNo) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryLight),
                                  ),
                                  child: Text(
                                    poNo,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ))
                            .toList()
                        : controller.linkedPurchaseOrderIds
                            .map((id) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryLight),
                                  ),
                                  child: Text(
                                    'PO #$id',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ))
                            .toList(),
                  ),
                ],
              ),
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
                child: SizedBox(
                  height: 52,
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.docNoPrefix.value,
                        decoration: AppInputDecoration.standard(
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
                  height: 52,
                  child: Obx(() {
                    final seq = controller.currentSeq.value;
                    final docNo = controller.docNoNumber.value.trim();
                    final labelText = docNo.isNotEmpty
                        ? docNo
                        : (seq != null ? seq.toString() : '');
                    return InputDecorator(
                      decoration: AppInputDecoration.standard(
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
          const SizedBox(height: 16),
          Obx(() {
            final list = controller.suppliers;
            return DropdownButtonFormField<int>(
              value: controller.vendorId.value,
              decoration: AppInputDecoration.standard(labelText: 'Supplier *'),
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
          const SizedBox(height: 6),
          Obx(() => TextFormField(
                initialValue: controller.narration.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Narration',
                  hintText: 'Optional notes...',
                ).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                minLines: 2,
                maxLines: 2,
                onChanged: controller.setNarration,
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.docDate.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Document Date *',
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onChanged: controller.setDocDate,
                    )),
              ),
                    const SizedBox(width: 6),
              Expanded(
                child: Obx(() => TextFormField(
                      initialValue: controller.billNo.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Bill No',
                        hintText: 'Supplier invoice no',
                      ),
                      onChanged: controller.setBillNo,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 6),
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
          const SizedBox(height: 6),
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
              const SizedBox(width: 6),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
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
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'From PO: $sourcePo',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
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
          const SizedBox(height: 5),
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
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
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
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
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
                        if (p == null || p < 0) return 'Must be >= 0';
                        return null;
                      },
                      onChanged: (value) {
                        row.unitPrice.value = value;
                        controller.recalcItemRow(row);
                      },
                    )),
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
              value: tax.toStringAsFixed(2),
            );
          }),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Obx(() => _readOnlyAmountField(
                label: 'Product Total',
                value: (double.tryParse(row.value.value) ?? 0)
                    .toStringAsFixed(2),
              )),
        ),
      ],
    );
  }

  Widget _readOnlyAmountField({
    required String label,
    required String value,
  }) {
    return InputDecorator(
      decoration: AppInputDecoration.standard(labelText: label),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13),
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
                  await controller.applyResolvedTaxesToVoucherRow(
                    row,
                    productId: product.id,
                  );
                  state.didChange(product);
                }
              },
              child: InputDecorator(
                decoration: AppInputDecoration.standard(
                  labelText: 'Product *',
                  hintText: 'Tap to search and select product',
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
                              decoration: AppInputDecoration.standard(
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
                              decoration: AppInputDecoration.standard(
                                labelText: 'Amount',
                                hintText: '0.00',
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
          .where((e) => e.key.trim().toUpperCase() != 'ROFF')
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
