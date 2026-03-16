import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_order_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_order_list_screen.dart';

class PurchaseOrderFormScreen extends StatelessWidget {
  final int? poId;
  final bool startInViewOnly;

  const PurchaseOrderFormScreen({
    super.key,
    this.poId,
    this.startInViewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PurchaseOrderFormController(
        poId: poId,
        startInViewOnly: startInViewOnly,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Purchase Order' : 'Create Purchase Order',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final canEdit = controller.viewOnly.value && controller.status.value == 'DRAFT';
            if (!canEdit) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => controller.viewOnly.value = false,
            );
          }),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: 'View all purchase orders',
            onPressed: () => Get.to(() => const PurchaseOrderListScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill in supplier, dates and add line items with quantity and price.',
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(controller: controller),
                      const SizedBox(height: 16),
                      _ItemsCard(controller: controller),
                      const SizedBox(height: 16),
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
                      onPressed: controller.isSaving.value || controller.isReadOnly
                          ? null
                          : () => controller.save(),
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
  final PurchaseOrderFormController controller;

  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Supplier & Dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Voucher number row – visible in both create and edit modes.
          Obx(() {
            final poNumber = controller.currentPoNumber.value;
            final labelText = controller.isEditMode
                ? (poNumber.isEmpty ? 'Existing (no number)' : poNumber)
                : (poNumber.isEmpty ? 'New (number after save)' : poNumber);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Text(
                    'Voucher No:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                    tooltip: 'Previous Voucher',
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.goToPreviousVoucher(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    tooltip: 'Next Voucher',
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.goToNextVoucher(),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final list = controller.suppliers;
            return DropdownButtonFormField<int>(
              value: controller.supplierId.value,
              decoration: AppInputDecoration.standard(labelText: 'Supplier *'),
              items: list
                  .map((s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          s['supplier_name']?.toString() ?? 'Supplier #${s['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: controller.isReadOnly ? null : (v) => controller.setSupplierId(v),
              validator: (v) => v == null ? 'Please select supplier' : null,
            );
          }),
          const SizedBox(height: 16),
          Obx(() => TextFormField(
                enabled: !controller.isReadOnly,
                initialValue: controller.financialYear.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Financial Year',
                  hintText: 'e.g. 25-26',
                ),
                onChanged: controller.setFinancialYear,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
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
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: controller.expectedDate.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Expected Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onChanged: controller.setExpectedDate,
                    )),
              ),
            ],
          ),
          if (controller.isEditMode) ...[
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.status.value,
                  decoration: AppInputDecoration.standard(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                    DropdownMenuItem(value: 'SENT', child: Text('Sent')),
                    DropdownMenuItem(
                        value: 'PARTIALLY_RECEIVED',
                        child: Text('Partially received')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: controller.isReadOnly
                      ? null
                      : (v) {
                          if (v != null) controller.setStatus(v);
                        },
                )),
          ],
          const SizedBox(height: 16),
          Obx(() => TextFormField(
                enabled: !controller.isReadOnly,
                initialValue: controller.narration.value,
                decoration: AppInputDecoration.standard(
                  labelText: 'Narration',
                  hintText: 'Optional notes...',
                ),
                maxLines: 3,
                onChanged: controller.setNarration,
              )),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _ItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Line Items',
      titleAction: controller.isReadOnly
          ? null
          : TextButton.icon(
              onPressed: controller.addItem,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Item'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
      child: Obx(() {
        if (controller.items.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_cart_outlined,
            message: 'No items. Tap "Add Item" to add lines.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.items.length,
          itemBuilder: (context, index) => _ItemRow(
            controller: controller,
            index: index,
            row: controller.items[index],
          ),
        );
      }),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PurchaseOrderFormController controller;
  final int index;
  final POLineRow row;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              if (!controller.isReadOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.redAccent,
                  onPressed: () => controller.removeItem(index),
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ProductPicker(
            controller: controller,
            row: row,
            readOnly: controller.isReadOnly,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: row.quantity.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Quantity *',
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final q = double.tryParse(v);
                        if (q == null || q <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: (v) => row.quantity.value = v,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(
                  () {
                    final units = controller.unitTypes.isEmpty
                        ? ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML']
                        : controller.unitTypes;
                    final current = row.unit.value;
                    final value = units.contains(current)
                        ? current
                        : units.first;
                    if (value != current && !controller.isReadOnly) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        row.unit.value = value;
                      });
                    }
                    return DropdownButtonFormField<String>(
                      value: value,
                      decoration: AppInputDecoration.standard(labelText: 'Unit')
                          .copyWith(
                            // Reduce horizontal padding so the dropdown can't overflow on small widths.
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
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
                      onChanged: controller.isReadOnly
                          ? null
                          : (v) {
                              if (v != null) row.unit.value = v;
                            },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: row.price.value,
                      decoration: AppInputDecoration.standard(
                        labelText: row.isInclusiveTax.value
                            ? 'Unit Price (with tax) *'
                            : 'Unit Price (without tax) *',
                        hintText: '0.00',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final p = double.tryParse(v);
                        if (p == null || p < 0) return 'Must be ≥ 0';
                        return null;
                      },
                      onChanged: (v) => row.price.value = v,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: false,
                    initialValue: row.lineTotalExclTax.toStringAsFixed(2),
                    decoration: AppInputDecoration.standard(
                      labelText: 'Taxable',
                    ),
                    readOnly: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Without tax',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: false,
                    groupValue: row.isInclusiveTax.value,
                    onChanged: controller.isReadOnly
                        ? null
                        : (v) {
                            if (v != null) {
                              row.isInclusiveTax.value = v;
                            }
                          },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'With tax',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: true,
                    groupValue: row.isInclusiveTax.value,
                    onChanged: controller.isReadOnly
                        ? null
                        : (v) {
                            if (v != null) {
                              row.isInclusiveTax.value = v;
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _taxField(row.sgst, 'SGST'),
              const SizedBox(width: 8),
              _taxField(row.cgst, 'CGST'),
              const SizedBox(width: 8),
              _taxField(row.igst, 'IGST'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _taxField(row.cess, 'Cess'),
              const SizedBox(width: 8),
              _taxField(row.roff, 'Roff'),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                'Price (incl. tax): ₹ ${row.priceInclTax.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )),
          const SizedBox(height: 8),
          Obx(() => Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Line total (excl. tax): ₹ ${row.lineTotalExclTax.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Line total (incl. tax): ₹ ${row.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _taxField(RxString value, String label) {
    return Expanded(
      child: Obx(
        () => TextFormField(
          enabled: !controller.isReadOnly,
          initialValue: value.value,
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
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => value.value = v,
        ),
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  final PurchaseOrderFormController controller;
  final POLineRow row;
  final bool readOnly;

  const _ProductPicker({
    required this.controller,
    required this.row,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
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
                      final product = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => _POProductSearchDialog(controller: controller),
                      );
                      if (product != null) {
                        final rawId = product['product_id'] ?? product['id'];
                        final pid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                        if (pid != null) {
                          row.productId.value = pid;
                          row.productName.value = product['name']?.toString() ?? '';
                          await controller.applyProductTaxesToRow(row, pid);
                          state.didChange(pid);
                          state.validate();
                        }
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
                            row.productName.value.isEmpty
                                ? 'Tap to search...'
                                : row.productName.value,
                            style: TextStyle(
                              color: row.productId.value == null
                                  ? Colors.grey
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    if (!readOnly)
                      const Icon(Icons.search, color: AppColors.textMuted),
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

class _POProductSearchDialog extends StatefulWidget {
  final PurchaseOrderFormController controller;

  const _POProductSearchDialog({required this.controller});

  @override
  State<_POProductSearchDialog> createState() => _POProductSearchDialogState();
}

class _POProductSearchDialogState extends State<_POProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _searched = false;
  bool _showAllProducts = false;

  @override
  void initState() {
    super.initState();
    _showAllProducts = widget.controller.supplierId.value == null;
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searched = true;
    });
    final list = await widget.controller.searchProductsForSupplier(
      query,
      includeAll: _showAllProducts,
    );
    if (mounted) {
      setState(() {
        _results = list;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search product'),
      content: SizedBox(
        width: 360,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type name or ID to search...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (_searchController.text == value) _runSearch(value);
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty && !_searching
                  ? Center(
                      child: Text(
                        _searched
                            ? 'No products found. Try a different search.'
                            : 'Type above to search products.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        final pid = p['product_id'] as int?;
                        final name = p['name']?.toString() ?? 'ID $pid';
                        return ListTile(
                          title: Text(name, overflow: TextOverflow.ellipsis),
                          subtitle: pid != null ? Text('ID: $pid') : null,
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final hasSupplier =
                    widget.controller.supplierId.value != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasSupplier)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Select supplier to filter by assigned products.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: hasSupplier
                          ? () {
                              setState(() {
                                _showAllProducts = !_showAllProducts;
                              });
                              _runSearch(_searchController.text);
                            }
                          : null,
                      child: Text(
                        _showAllProducts
                            ? 'Show only products assigned to this supplier'
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      double subtotalExclTax = 0;
      double totalInclTax = 0;
      for (final row in controller.items) {
        subtotalExclTax += row.lineTotalExclTax;
        totalInclTax += row.lineTotal;
      }
      final taxAmount = totalInclTax - subtotalExclTax;
      return ContentCard(
        title: 'Summary',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Subtotal (excl. tax)', '₹ ${subtotalExclTax.toStringAsFixed(2)}', false),
            if (taxAmount > 0) ...[
              const SizedBox(height: 6),
              _summaryRow('Tax', '₹ ${taxAmount.toStringAsFixed(2)}', false),
            ],
            const SizedBox(height: 8),
            _summaryRow('Total (incl. tax)', '₹ ${totalInclTax.toStringAsFixed(2)}', true),
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
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
