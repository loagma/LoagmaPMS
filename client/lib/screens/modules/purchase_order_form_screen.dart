import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_order_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PurchaseOrderFormScreen extends StatelessWidget {
  final int? poId;

  const PurchaseOrderFormScreen({super.key, this.poId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseOrderFormController(poId: poId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Purchase Order' : 'Create Purchase Order',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
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
                flex: 2,
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
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: row.unit.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Unit',
                        hintText: 'PCS',
                      ),
                      onChanged: (v) => row.unit.value = v,
                    )),
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
                        labelText: 'Price (excl. tax) *',
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: row.discountPercent.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Disc %',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => row.discountPercent.value = v,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => TextFormField(
                      enabled: !controller.isReadOnly,
                      initialValue: row.taxPercent.value,
                      decoration: AppInputDecoration.standard(
                        labelText: 'Tax %',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => row.taxPercent.value = v,
                    )),
              ),
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
                        row.productId.value = product['product_id'] as int;
                        row.productName.value =
                            product['name']?.toString() ?? '';
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

  @override
  void initState() {
    super.initState();
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
    final list = await widget.controller.searchProducts(query);
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
