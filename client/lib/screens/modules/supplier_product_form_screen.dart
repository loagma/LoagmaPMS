import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_product_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SupplierProductFormScreen extends StatelessWidget {
  const SupplierProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final controller = Get.put(
      SupplierProductFormController(
        supplierProductId: args?['id'] as int?,
        presetSupplierId: args?['supplier_id'] as int?,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditMode
              ? 'Edit Supplier Product'
              : 'Assign Product(s) to Supplier',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final form = Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSupplierCard(controller),
              const SizedBox(height: 16),
              if (controller.isEditMode)
                _buildEditModeProductCard(controller)
              else
                _buildAssignModeProductsCard(controller),
              const SizedBox(height: 80),
            ],
          ),
        );

        return Stack(
          children: [
            form,
            if (controller.isSaving.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isSaving.value
              ? null
              : controller.saveSupplierProduct,
          backgroundColor: AppColors.primary,
          icon: controller.isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(controller.isSaving.value ? 'Saving...' : 'Save'),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Supplier',
      child: Obx(
        () => DropdownButtonFormField<int>(
          value: controller.selectedSupplierId.value,
          decoration: AppInputDecoration.standard(labelText: 'Supplier *'),
          items: controller.suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier.id,
              child: Text(supplier.supplierName),
            );
          }).toList(),
          validator: (value) => value == null ? 'Required' : null,
          onChanged: (value) {
            if (value != null) controller.selectedSupplierId.value = value;
          },
        ),
      ),
    );
  }

  Widget _buildEditModeProductCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Product',
      child: _ProductSearchPicker(
        controller: controller,
        productId: controller.selectedProductId,
        productName: controller.supplierProductName,
        labelText: 'Product *',
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildAssignModeProductsCard(SupplierProductFormController controller) {
    return ContentCard(
      title: 'Products',
      titleAction: TextButton.icon(
        onPressed: controller.addProductRow,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add product'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      child: Obx(() {
        if (controller.productRows.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Tap "Add product" to add products, then search and select each one.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.productRows.length,
          itemBuilder: (context, index) {
            final row = controller.productRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ProductSearchPicker(
                      controller: controller,
                      productId: row.productId,
                      productName: row.productName,
                      labelText: 'Product ${index + 1}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.redAccent,
                    onPressed: () => controller.removeProductRow(index),
                    tooltip: 'Remove',
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

/// Product picker that opens a search dialog (API search, no full list).
class _ProductSearchPicker extends StatelessWidget {
  final SupplierProductFormController controller;
  final Rx<int?> productId;
  final RxString productName;
  final String labelText;
  final String? Function(int?)? validator;

  const _ProductSearchPicker({
    required this.controller,
    required this.productId,
    required this.productName,
    this.labelText = 'Product',
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: productId.value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openSearchDialog(context),
              child: InputDecorator(
                decoration: AppInputDecoration.standard(
                  labelText: labelText,
                  hintText: 'Tap to search and select product',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            productName.value.isEmpty
                                ? 'Tap to search...'
                                : productName.value,
                            style: TextStyle(
                              color: productId.value == null
                                  ? Colors.grey
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
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

  Future<void> _openSearchDialog(BuildContext context) async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ProductSearchDialog(controller: controller),
    );
    if (selected != null && context.mounted) {
      productId.value = selected['product_id'] as int;
      productName.value = selected['name']?.toString() ?? '';
    }
  }
}

class _ProductSearchDialog extends StatefulWidget {
  final SupplierProductFormController controller;

  const _ProductSearchDialog({required this.controller});

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
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
