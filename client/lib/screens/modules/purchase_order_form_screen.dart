import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/purchase_order_form_controller.dart';
import '../../models/product_model.dart';
import '../../models/supplier_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PurchaseOrderFormScreen extends StatelessWidget {
  final int? purchaseOrderId;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrderId});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(PurchaseOrderFormController(purchaseOrderId: purchaseOrderId));

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth - 32;

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
                              _ItemsCard(controller: controller),
                              const SizedBox(height: 16),
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
                          onPressed: controller.isSaving.value || controller.isReadOnly
                              ? null
                              : () => controller.saveAsDraft(),
                        ),
                        ActionButton(
                          label: 'Send PO',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value || controller.isReadOnly
                              ? null
                              : () => controller.sendPurchaseOrder(),
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
          Obx(
            () => _SupplierDropdown(
              label: 'Supplier *',
              initialValue: controller.selectedSupplier.value,
              items: controller.suppliers,
              controller: controller,
              onChanged: controller.isReadOnly ? null : controller.setSupplier,
              validator: (value) {
                if (value == null) return 'Please select supplier';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: controller.docDate.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Document Date *',
                      hintText: 'YYYY-MM-DD',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onChanged: controller.setDocDate,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: controller.expectedDate.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Expected Date',
                      hintText: 'YYYY-MM-DD',
                    ),
                    onChanged: controller.setExpectedDate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.status.value,
              decoration: AppInputDecoration.standard(labelText: 'Status *'),
              items: const [
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'SENT', child: Text('Sent')),
                DropdownMenuItem(
                  value: 'PARTIALLY_RECEIVED',
                  child: Text('Partially received'),
                ),
                DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
              ],
              onChanged: controller.isReadOnly
                  ? null
                  : (value) {
                      if (value != null) controller.setStatus(value);
                    },
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              enabled: !controller.isReadOnly,
              initialValue: controller.narration.value,
              decoration: AppInputDecoration.standard(
                labelText: 'Narration',
                hintText: 'Optional notes to supplier...',
              ),
              maxLines: 3,
              onChanged: controller.setNarration,
            ),
          ),
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
      titleAction: TextButton.icon(
        onPressed: controller.isReadOnly ? null : controller.addItemRow,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Item'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.items.isEmpty)
              const EmptyState(
                icon: Icons.shopping_cart_outlined,
                message: 'No items added yet. Tap "Add Item" to start.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final row = controller.items[index];
                  return _ItemRow(
                    controller: controller,
                    index: index,
                    row: row,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PurchaseOrderFormController controller;
  final int index;
  final PurchaseOrderItemRow row;

  const _ItemRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final excludeIds = controller.items
        .where((r) => r != row && r.product.value != null)
        .map((r) => r.product.value!.id)
        .toSet();

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
              if (!controller.isReadOnly)
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
          Obx(
            () => _ProductDropdown(
              key: ValueKey('po_product_$index'),
              label: 'Product *',
              initialValue: row.product.value,
              items: controller.products
                  .where((p) => !excludeIds.contains(p.id))
                  .toList(),
              controller: controller,
              onChanged: controller.isReadOnly
                  ? null
                  : (product) {
                      row.product.value = product;
                      if (product != null) {
                        row.unit.value = product.defaultUnit ?? '';
                      }
                    },
              validator: (value) {
                if (value == null) return 'Please select product';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: row.quantity.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Quantity *',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,3}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      row.quantity.value = value;
                      controller.updateLineTotal(row);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: row.unit.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Unit',
                      hintText: 'e.g. PCS',
                    ),
                    onChanged: (value) => row.unit.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: row.price.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Price *',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Must be ≥ 0';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      row.price.value = value;
                      controller.updateLineTotal(row);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: row.discountPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Discount %',
                      hintText: '0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) {
                      row.discountPercent.value = value;
                      controller.updateLineTotal(row);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => TextFormField(
                    enabled: !controller.isReadOnly,
                    initialValue: row.taxPercent.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Tax %',
                      hintText: '0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) {
                      row.taxPercent.value = value;
                      controller.updateLineTotal(row);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      row.lineTotal.value.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PurchaseOrderFormController controller;

  const _SummaryCard({required this.controller});

  double _computeTotal() {
    return controller.items.fold(
      0.0,
      (sum, row) => sum + row.lineTotal.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final total = _computeTotal();
        return ContentCard(
          title: 'Summary',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    total.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupplierDropdown extends StatefulWidget {
  final String label;
  final Supplier? initialValue;
  final List<Supplier> items;
  final PurchaseOrderFormController controller;
  final ValueChanged<Supplier?>? onChanged;
  final String? Function(Supplier?)? validator;

  const _SupplierDropdown({
    required this.label,
    required this.initialValue,
    required this.items,
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_SupplierDropdown> createState() => _SupplierDropdownState();
}

class _SupplierDropdownState extends State<_SupplierDropdown> {
  final TextEditingController _searchController = TextEditingController();
  Supplier? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    if (_selectedValue != null) {
      _searchController.text = _selectedValue!.supplierName;
    }
  }

  @override
  void didUpdateWidget(_SupplierDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selectedValue = widget.initialValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_selectedValue != null) {
            _searchController.text = _selectedValue!.supplierName;
          } else {
            _searchController.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() async {
    final result = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => _SearchSupplierDialog(
        controller: widget.controller,
        currentSelection: _selectedValue,
        items: widget.items,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedValue = result;
        _searchController.text = result.supplierName;
      });
      widget.onChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Supplier>(
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: widget.label,
                hintText: 'Tap to search...',
                suffixIcon: SizedBox(
                  width: 48,
                  child: _selectedValue != null && widget.onChanged != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _selectedValue = null;
                                _searchController.clear();
                              });
                              widget.onChanged?.call(null);
                              formFieldState.didChange(null);
                            }
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed:
                              widget.onChanged == null ? null : _showSearchDialog,
                        ),
                ),
              ),
              readOnly: true,
              onTap: widget.onChanged == null ? null : _showSearchDialog,
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  formFieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchSupplierDialog extends StatefulWidget {
  final PurchaseOrderFormController controller;
  final Supplier? currentSelection;
  final List<Supplier> items;

  const _SearchSupplierDialog({
    required this.controller,
    required this.items,
    this.currentSelection,
  });

  @override
  State<_SearchSupplierDialog> createState() => _SearchSupplierDialogState();
}

class _SearchSupplierDialogState extends State<_SearchSupplierDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Supplier> _filteredSuppliers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = widget.items.take(50).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredSuppliers = widget.items.take(50).toList());
      return;
    }
    if (query.length < 2) return;
    setState(() => _isSearching = true);
    try {
      await widget.controller.searchSuppliers(query);
      setState(() {
        _filteredSuppliers = widget.controller.suppliers;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Suppliers',
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
                labelText: 'Search by name or code',
                hintText: 'Type at least 2 characters...',
                prefixIcon: const Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _filteredSuppliers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Start typing to search'
                              : 'No suppliers found',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, i) {
                          final supplier = _filteredSuppliers[i];
                          final isSelected =
                              widget.currentSelection?.id == supplier.id;
                          return ListTile(
                            title: Text(supplier.supplierName),
                            subtitle: Text(
                              'Code: ${supplier.supplierCode}',
                            ),
                            selected: isSelected,
                            onTap: () => Navigator.pop(context, supplier),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatefulWidget {
  final String label;
  final Product? initialValue;
  final List<Product> items;
  final PurchaseOrderFormController controller;
  final ValueChanged<Product?>? onChanged;
  final String? Function(Product?)? validator;

  const _ProductDropdown({
    super.key,
    required this.label,
    required this.initialValue,
    required this.items,
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  final TextEditingController _searchController = TextEditingController();
  Product? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    if (_selectedValue != null) _searchController.text = _selectedValue!.name;
  }

  @override
  void didUpdateWidget(_ProductDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selectedValue = widget.initialValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_selectedValue != null) {
            _searchController.text = _selectedValue!.name;
          } else {
            _searchController.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (ctx) => _SearchProductDialog(
        controller: widget.controller,
        currentSelection: _selectedValue,
        items: widget.items,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedValue = result;
        _searchController.text = result.name;
      });
      widget.onChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Product>(
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: widget.label,
                hintText: 'Tap to search...',
                suffixIcon: SizedBox(
                  width: 48,
                  child: _selectedValue != null && widget.onChanged != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _selectedValue = null;
                                _searchController.clear();
                              });
                              widget.onChanged?.call(null);
                              formFieldState.didChange(null);
                            }
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed:
                              widget.onChanged == null ? null : _showSearchDialog,
                        ),
                ),
              ),
              readOnly: true,
              onTap: widget.onChanged == null ? null : _showSearchDialog,
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  formFieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchProductDialog extends StatefulWidget {
  final PurchaseOrderFormController controller;
  final Product? currentSelection;
  final List<Product> items;

  const _SearchProductDialog({
    required this.controller,
    required this.items,
    this.currentSelection,
  });

  @override
  State<_SearchProductDialog> createState() => _SearchProductDialogState();
}

class _SearchProductDialogState extends State<_SearchProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.items.take(50).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredProducts = widget.items.take(50).toList());
      return;
    }
    if (query.length < 2) return;
    setState(() => _isSearching = true);
    try {
      await widget.controller.searchProducts(query);
      setState(() {
        _filteredProducts = widget.controller.products;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Products',
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
                labelText: 'Search by name or ID',
                hintText: 'Type at least 2 characters...',
                prefixIcon: const Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Start typing to search'
                              : 'No products found',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, i) {
                          final product = _filteredProducts[i];
                          final isSelected =
                              widget.currentSelection?.id == product.id;
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text('ID: ${product.id}'),
                            selected: isSelected,
                            onTap: () => Navigator.pop(context, product),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

