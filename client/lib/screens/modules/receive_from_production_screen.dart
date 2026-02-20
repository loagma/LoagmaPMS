import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/receive_from_production_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ReceiveFromProductionScreen extends StatelessWidget {
  final int? receiveId;

  const ReceiveFromProductionScreen({super.key, this.receiveId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ReceiveFromProductionController(receiveId: receiveId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode
            ? 'Edit Receive'
            : 'Receive from Production',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Add finished goods received from production.',
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
                  'Loading products...',
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
                              _ReceiveItemsCard(controller: controller),
                              const SizedBox(height: 16),
                              _ReceiveRemarksCard(controller: controller),
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
                          label: 'Confirm Receive',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.confirmReceive(),
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

class _ReceiveItemsCard extends StatelessWidget {
  final ReceiveFromProductionController controller;

  const _ReceiveItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Finished Goods Received',
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.items.length,
              itemBuilder: (context, index) {
                return _ReceiveItemRow(
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
                label: const Text('Add Finished Product'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReceiveRemarksCard extends StatelessWidget {
  final ReceiveFromProductionController controller;

  const _ReceiveRemarksCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Remarks',
      child: Obx(
        () => TextFormField(
          initialValue: controller.remarks.value,
          decoration: AppInputDecoration.standard(
            labelText: 'Remarks',
            hintText: 'Optional notes...',
          ),
          maxLines: 3,
          onChanged: controller.setRemarks,
        ),
      ),
    );
  }
}

class _ReceiveItemRow extends StatelessWidget {
  final ReceiveFromProductionController controller;
  final int index;
  final ReceiveItemRow row;

  const _ReceiveItemRow({
    required this.controller,
    required this.index,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final excludeIds = controller.items
        .where((r) => r != row && r.finishedProduct.value != null)
        .map((r) => r.finishedProduct.value!.id);

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
          Obx(
            () => _ProductDropdown(
              key: ValueKey('receive_product_$index'),
              label: 'Finished Product *',
              initialValue: row.finishedProduct.value,
              items: controller.getProductsExcluding(excludeIds),
              excludeIds: excludeIds.toSet(),
              controller: controller,
              onChanged: (product) {
                row.finishedProduct.value = product;
                final unit = product?.defaultUnit?.toString();
                if (unit != null && unit.isNotEmpty) {
                  row.unitType.value = controller.unitTypes.contains(unit)
                      ? unit
                      : (controller.unitTypes.isNotEmpty
                            ? controller.unitTypes.first
                            : 'KG');
                }
              },
              validator: (value) {
                if (value == null) return 'Please select finished product';
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
                    initialValue: row.quantity.value,
                    decoration: AppInputDecoration.standard(
                      labelText: 'Quantity Received *',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) return 'Must be > 0';
                      return null;
                    },
                    onChanged: (value) => row.quantity.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.unitTypes.contains(row.unitType.value)
                        ? row.unitType.value
                        : (controller.unitTypes.isNotEmpty
                              ? controller.unitTypes.first
                              : 'KG'),
                    decoration: AppInputDecoration.standard(
                      labelText: 'Unit *',
                    ),
                    isDense: true,
                    items: controller.unitTypes
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) row.unitType.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDropdown extends StatefulWidget {
  final String label;
  final Product? initialValue;
  final List<Product> items;
  final Set<int> excludeIds;
  final ReceiveFromProductionController controller;
  final ValueChanged<Product?>? onChanged;
  final String? Function(Product?)? validator;

  const _ProductDropdown({
    super.key,
    required this.label,
    required this.initialValue,
    required this.items,
    this.excludeIds = const {},
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
      builder: (context) => _SearchProductDialog(
        controller: widget.controller,
        currentSelection: _selectedValue,
        items: widget.items,
        excludeIds: widget.excludeIds,
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
                          onPressed: widget.onChanged == null
                              ? null
                              : _showSearchDialog,
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
  final ReceiveFromProductionController controller;
  final Product? currentSelection;
  final List<Product> items;
  final Set<int> excludeIds;

  const _SearchProductDialog({
    required this.controller,
    required this.items,
    this.excludeIds = const {},
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
        _filteredProducts = widget.controller.products
            .where((p) => !widget.excludeIds.contains(p.id))
            .toList();
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
                    'Search Finished Products',
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
