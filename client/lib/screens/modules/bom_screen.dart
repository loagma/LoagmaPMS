import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/bom_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class BomScreen extends StatelessWidget {
  final int? bomId; // null for create, non-null for edit

  const BomScreen({super.key, this.bomId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BomController(bomId: bomId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit BOM' : 'Create BOM',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Help',
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill in the BOM details and add raw materials required for production',
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
                              _BomHeaderCard(controller: controller),
                              const SizedBox(height: 16),
                              _RawMaterialsCard(controller: controller),
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
                          onPressed: controller.isReadOnly
                              ? null
                              : () => Get.back(),
                        ),
                        ActionButton(
                          label: 'Save as Draft',
                          isPrimary: true,
                          isLoading: controller.isSaving.value,
                          onPressed:
                              controller.isReadOnly || controller.isSaving.value
                              ? null
                              : () => controller.saveAsDraft(),
                        ),
                        ActionButton(
                          label: 'Approve BOM',
                          isPrimary: true,
                          backgroundColor: AppColors.primaryDark,
                          isLoading: controller.isSaving.value,
                          onPressed:
                              controller.isReadOnly || controller.isSaving.value
                              ? null
                              : () => controller.approveBom(),
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

class _BomHeaderCard extends StatelessWidget {
  final BomController controller;

  const _BomHeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Finished Product - Output',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _ProductDropdown(
              key: const ValueKey('finished_product_dropdown'),
              label: 'Finished Product *',
              initialValue: controller.selectedFinishedProduct.value,
              items: controller.finishedProducts,
              controller: controller,
              onChanged: controller.isReadOnly
                  ? null
                  : (product) => controller.setFinishedProduct(product),
              validator: (value) {
                if (value == null) {
                  return 'Please select a finished product';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !controller.isReadOnly,
            initialValue: controller.bomVersion.value,
            decoration: AppInputDecoration.standard(
              labelText: 'BOM Version *',
              hintText: 'e.g., v1.0',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter BOM version';
              }
              return null;
            },
            onChanged: (value) => controller.setBomVersion(value),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.status.value,
              decoration: AppInputDecoration.standard(labelText: 'Status *'),
              items: const [
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                DropdownMenuItem(value: 'LOCKED', child: Text('Locked')),
              ],
              onChanged: controller.isReadOnly
                  ? null
                  : (value) {
                      if (value != null) controller.setStatus(value);
                    },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !controller.isReadOnly,
            initialValue: controller.remarks.value,
            decoration: AppInputDecoration.standard(
              labelText: 'Remarks',
              hintText: 'Optional notes...',
            ),
            maxLines: 3,
            onChanged: (value) => controller.setRemarks(value),
          ),
        ],
      ),
    );
  }
}

class _RawMaterialsCard extends StatelessWidget {
  final BomController controller;

  const _RawMaterialsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Raw Materials - Input',
      child: Obx(() {
        if (controller.rawMaterials.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No raw materials added yet.',
            actionLabel: 'Add Material',
            onAction: controller.isReadOnly
                ? null
                : () => controller.addRawMaterial(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.rawMaterials.length,
              itemBuilder: (context, index) {
                return _RawMaterialRow(
                  controller: controller,
                  index: index,
                  row: controller.rawMaterials[index],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.isReadOnly
                    ? null
                    : () => controller.addRawMaterial(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Material'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RawMaterialRow extends StatelessWidget {
  final BomController controller;
  final int index;
  final RawMaterialRow row;

  const _RawMaterialRow({
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Material ${index + 1}',
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
                  onPressed: () => controller.removeRawMaterial(index),
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
              key: ValueKey('raw_material_dropdown_$index'),
              label: 'Raw Material *',
              initialValue: row.rawMaterial.value,
              items: controller.rawMaterialProducts.where((p) {
                if (controller.selectedFinishedProduct.value != null) {
                  return p['product_id'] !=
                      controller.selectedFinishedProduct.value!['product_id'];
                }
                return true;
              }).toList(),
              controller: controller,
              onChanged: controller.isReadOnly
                  ? null
                  : (product) {
                      row.rawMaterial.value = product;
                      // No auto-select unit for now - keep it simple
                    },
              validator: (value) {
                if (value == null) {
                  return 'Please select a raw material';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  enabled: !controller.isReadOnly,
                  initialValue: row.quantityPerUnit.value,
                  decoration: AppInputDecoration.standard(
                    labelText: 'Quantity per Unit *',
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
                  onChanged: (value) => row.quantityPerUnit.value = value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: row.unitType.value,
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
                    onChanged: controller.isReadOnly
                        ? null
                        : (value) {
                            if (value != null) row.unitType.value = value;
                          },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // TextFormField(
          //   enabled: !controller.isReadOnly,
          //   initialValue: row.wastagePercent.value,
          //   decoration: AppInputDecoration.standard(
          //     labelText: 'Wastage %',
          //     hintText: '0',
          //   ),
          //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
          //   inputFormatters: [
          //     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          //   ],
          //   onChanged: (value) => row.wastagePercent.value = value,
          // ),
        ],
      ),
    );
  }
}

// Searchable Dropdown Widget
class _ProductDropdown extends StatefulWidget {
  final String label;
  final Map<String, dynamic>? initialValue;
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>?>? onChanged;
  final String? Function(Map<String, dynamic>?)? validator;
  final BomController controller;

  const _ProductDropdown({
    super.key,
    required this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    required this.controller,
    this.validator,
  });

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    if (_selectedValue != null) {
      _searchController.text = _selectedValue!['name']?.toString() ?? '';
    }
  }

  @override
  void didUpdateWidget(_ProductDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when initialValue changes from outside
    if (widget.initialValue != oldWidget.initialValue) {
      _selectedValue = widget.initialValue;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_selectedValue != null) {
            _searchController.text = _selectedValue!['name']?.toString() ?? '';
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SearchProductDialog(
        controller: widget.controller,
        currentSelection: _selectedValue,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedValue = result;
        _searchController.text = result['name']?.toString() ?? '';
      });
      widget.onChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Map<String, dynamic>>(
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
  final BomController controller;
  final Map<String, dynamic>? currentSelection;

  const _SearchProductDialog({required this.controller, this.currentSelection});

  @override
  State<_SearchProductDialog> createState() => _SearchProductDialogState();
}

class _SearchProductDialogState extends State<_SearchProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.controller.finishedProducts.take(50).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = widget.controller.finishedProducts
            .take(50)
            .toList();
      });
      return;
    }

    if (query.length < 2) return;

    setState(() => _isSearching = true);

    try {
      await widget.controller.searchProducts(query);
      setState(() {
        _filteredProducts = widget.controller.finishedProducts;
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
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isSelected =
                              widget.currentSelection?['product_id'] ==
                              product['product_id'];

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                product['product_id'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            title: Text(
                              product['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              'ID: ${product['product_id']} • ${product['inventory_type']}',
                              style: const TextStyle(fontSize: 12),
                            ),
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
