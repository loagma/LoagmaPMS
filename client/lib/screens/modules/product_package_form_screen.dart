import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_package_form_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductPackageFormScreen extends StatelessWidget {
  final int? productId;
  final int? packageId;

  const ProductPackageFormScreen({
    super.key,
    this.productId,
    this.packageId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ProductPackageFormController(productId: productId, packageId: packageId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: controller.isEditMode ? 'Edit Package' : 'Add Packages',
        subtitle: controller.isEditMode
            ? 'Pack size configuration'
            : 'Configure one or more packs for a product',
        onBackPressed: () => Get.back(),
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
                Text('Loading package...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                      // ── Product selector (add mode only, when product not pre-set) ──
                      if (!controller.isEditMode && controller.productId == null)
                        _ProductSelector(controller: controller),

                      if (!controller.isEditMode && controller.productId == null)
                        const SizedBox(height: 16),

                      // ── Pack entries ──
                      if (controller.isEditMode)
                        _EditPackCard(controller: controller)
                      else
                        Obx(() => Column(
                          children: [
                            for (int i = 0; i < controller.packEntries.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _AddPackCard(
                                  index: i,
                                  entry: controller.packEntries[i],
                                  canRemove: controller.packEntries.length > 1,
                                  onRemove: () => controller.removeEntry(i),
                                  units: controller.units,
                                ),
                              ),
                            // Add another pack button
                            OutlinedButton.icon(
                              onPressed: controller.addEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Another Pack'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        )),
                    ],
                  ),
                ),
              ),

              // ── Bottom action buttons ──
              Obx(() => ActionButtonBar(
                buttons: [
                  ActionButton(
                    label: 'Cancel',
                    onPressed:
                        controller.isSaving.value ? null : () => Get.back(),
                  ),
                  ActionButton(
                    label: controller.isEditMode ? 'Update' : 'Save All',
                    isPrimary: true,
                    isLoading: controller.isSaving.value,
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            final ok = await controller.save();
                            if (ok) Get.back(result: true);
                          },
                  ),
                ],
              )),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product selector (searchable dropdown)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductSelector extends StatefulWidget {
  final ProductPackageFormController controller;
  const _ProductSelector({required this.controller});

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  final _searchController = TextEditingController();
  Product? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (ctx) => _ProductSearchDialog(
        controller: widget.controller,
        current: _selected,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selected = result;
        _searchController.text = '${result.id} — ${result.name}';
      });
      widget.controller.selectedProduct.value = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Product',
      child: FormField<Product>(
        validator: (_) =>
            widget.controller.selectedProduct.value == null ? 'Please select a product' : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: 'Product *',
                hintText: 'Tap to search product...',
                suffixIcon: SizedBox(
                  width: 48,
                  child: _selected != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selected = null;
                              _searchController.clear();
                            });
                            widget.controller.selectedProduct.value = null;
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _openSearch,
                        ),
                ),
              ),
              readOnly: true,
              onTap: _openSearch,
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product search dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ProductSearchDialog extends StatefulWidget {
  final ProductPackageFormController controller;
  final Product? current;

  const _ProductSearchDialog({required this.controller, this.current});

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final _searchCtrl = TextEditingController();
  List<Product> _filtered = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.controller.products.take(50).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String q) async {
    if (q.isEmpty) {
      setState(() => _filtered = widget.controller.products.take(50).toList());
      return;
    }
    if (q.length < 2) return;
    setState(() => _searching = true);
    await widget.controller.searchProducts(q);
    if (mounted) {
      setState(() {
        _filtered = widget.controller.products.toList();
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 560,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Search Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type to search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('No products found',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = _filtered[i];
                        final isSelected = widget.current?.id == p.id;
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text('ID: ${p.id}'),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                          onTap: () => Navigator.of(ctx).pop(p),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single pack entry card (add mode)
// ─────────────────────────────────────────────────────────────────────────────

class _AddPackCard extends StatelessWidget {
  final int index;
  final PackEntryState entry;
  final bool canRemove;
  final VoidCallback onRemove;
  final List<String> units;

  const _AddPackCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onRemove,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Pack ${index + 1}',
      titleAction: canRemove
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remove pack',
              onPressed: onRemove,
            )
          : null,
      child: _PackFields(entry: entry, units: units),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit pack card (edit mode uses observable fields, not TextEditingControllers)
// ─────────────────────────────────────────────────────────────────────────────

class _EditPackCard extends StatelessWidget {
  final ProductPackageFormController controller;
  const _EditPackCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Package Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => TextFormField(
            key: ValueKey('edit_desc_${controller.editDescription.value}'),
            initialValue: controller.editDescription.value,
            decoration: AppInputDecoration.standard(
                labelText: 'Package Description *',
                hintText: 'e.g. 1 KG Pack'),
            onChanged: (v) => controller.editDescription.value = v,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              flex: 2,
              child: Obx(() => TextFormField(
                key: ValueKey('edit_size_${controller.editPackSize.value}'),
                initialValue: controller.editPackSize.value,
                decoration: AppInputDecoration.standard(
                    labelText: 'Pack Size *', hintText: '1.0'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => controller.editPackSize.value = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final u = controller.units.contains(controller.editUnit.value)
                    ? controller.editUnit.value
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: u,
                  decoration: AppInputDecoration.standard(labelText: 'Unit *'),
                  hint: const Text('Unit'),
                  items: controller.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) { if (v != null) controller.editUnit.value = v; },
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                );
              }),
            ),
          ]),
          const SizedBox(height: 16),
          Obx(() => TextFormField(
            key: ValueKey('edit_mp_${controller.editMarketPrice.value}'),
            initialValue: controller.editMarketPrice.value,
            decoration: AppInputDecoration.standard(
                labelText: 'Market Price (MRP) *', hintText: '100.00'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => controller.editMarketPrice.value = v,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v.trim()) == null) return 'Invalid';
              return null;
            },
          )),
          const SizedBox(height: 16),
          const Text('Retail Prices',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Obx(() => TextFormField(
                key: ValueKey('edit_np_${controller.editNewPrice.value}'),
                initialValue: controller.editNewPrice.value,
                decoration:
                    AppInputDecoration.standard(labelText: 'New', hintText: '0.00'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => controller.editNewPrice.value = v,
                validator: _priceValidator,
              )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() => TextFormField(
                key: ValueKey('edit_rp_${controller.editRegularPrice.value}'),
                initialValue: controller.editRegularPrice.value,
                decoration: AppInputDecoration.standard(
                    labelText: 'Regular', hintText: '0.00'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => controller.editRegularPrice.value = v,
                validator: _priceValidator,
              )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() => TextFormField(
                key: ValueKey('edit_hp_${controller.editHomePrice.value}'),
                initialValue: controller.editHomePrice.value,
                decoration: AppInputDecoration.standard(
                    labelText: 'Home', hintText: '0.00'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => controller.editHomePrice.value = v,
                validator: _priceValidator,
              )),
            ),
          ]),
          const SizedBox(height: 16),
          Obx(() => TextFormField(
            key: ValueKey('edit_mv_${controller.editMaxVariation.value}'),
            initialValue: controller.editMaxVariation.value,
            decoration: AppInputDecoration.standard(
              labelText: 'Max Variation %',
              hintText: 'e.g. 10',
            ).copyWith(helperText: 'Leave empty to allow free price editing'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => controller.editMaxVariation.value = v,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final val = double.tryParse(v.trim());
              if (val == null) return 'Must be a number';
              if (val < 0 || val > 100) return '0–100';
              return null;
            },
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared pack fields widget (used in add mode entries)
// ─────────────────────────────────────────────────────────────────────────────

class _PackFields extends StatelessWidget {
  final PackEntryState entry;
  final List<String> units;
  const _PackFields({required this.entry, required this.units});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: entry.descController,
          decoration: AppInputDecoration.standard(
              labelText: 'Pack Description *', hintText: 'e.g. 1 KG Pack'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.sizeController,
              decoration: AppInputDecoration.standard(
                  labelText: 'Pack Size *', hintText: '1.0'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Invalid size';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final u = units.contains(entry.unit.value) ? entry.unit.value : null;
              return DropdownButtonFormField<String>(
                initialValue: u,
                decoration: AppInputDecoration.standard(labelText: 'Unit *'),
                hint: const Text('Unit'),
                items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) { if (v != null) entry.unit.value = v; },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              );
            }),
          ),
        ]),
        const SizedBox(height: 16),
        TextFormField(
          controller: entry.marketPriceController,
          decoration: AppInputDecoration.standard(
              labelText: 'Market Price (MRP) *', hintText: '100.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (double.tryParse(v.trim()) == null) return 'Invalid price';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text('Retail Prices',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: entry.newPriceController,
              decoration: AppInputDecoration.standard(
                  labelText: 'New', hintText: '0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _priceValidator,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: entry.regularPriceController,
              decoration: AppInputDecoration.standard(
                  labelText: 'Regular', hintText: '0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _priceValidator,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: entry.homePriceController,
              decoration: AppInputDecoration.standard(
                  labelText: 'Home', hintText: '0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _priceValidator,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextFormField(
          controller: entry.maxVariationController,
          decoration: AppInputDecoration.standard(
            labelText: 'Max Variation %',
            hintText: 'e.g. 10',
          ).copyWith(helperText: 'Leave empty to allow free price editing'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final val = double.tryParse(v.trim());
            if (val == null) return 'Must be a number';
            if (val < 0 || val > 100) return '0–100';
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String? _priceValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  if (double.tryParse(v.trim()) == null) return 'Invalid';
  return null;
}
