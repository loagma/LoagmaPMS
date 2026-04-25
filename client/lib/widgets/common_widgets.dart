import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/party_result.dart';
import '../models/product_model.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Consistent AppBar for all module screens
class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const ModuleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions,
  });

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (Get.currentRoute != AppRoutes.dashboard) {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => _handleBack(context),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Consistent card wrapper for content sections
class ContentCard extends StatelessWidget {
  final String? title;
  final Widget? titleAction;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ContentCard({
    super.key,
    this.title,
    this.titleAction,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (titleAction != null) titleAction!,
                ],
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Consistent empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Consistent action button bar at bottom
class ActionButtonBar extends StatelessWidget {
  final List<ActionButton> buttons;

  const ActionButtonBar({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: buttons
              .map(
                (btn) => [
                  Expanded(child: btn),
                  if (btn != buttons.last) const SizedBox(width: 12),
                ],
              )
              .expand((e) => e)
              .toList(),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final Color? backgroundColor;

  const ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Shared product search dialog used across Purchase and Sales modules.
///
/// Shows a card-style list with image placeholder, product name, code,
/// GST/HSN details, and package chips. Caller provides a [searchFn] that
/// returns matching [Product] list for a given query string.
///
/// Usage:
/// ```dart
/// final product = await showDialog<Product>(
///   context: context,
///   builder: (_) => ProductSearchDialog(
///     searchFn: (q) => controller.searchProducts(q),
///     title: 'Select Product',
///     excludeIds: alreadyAdded,
///     // Purchase-only: toggle between supplier and all products
///     showSupplierToggle: true,
///     supplierToggleValue: _showAllProducts,
///     onSupplierToggle: (v) => setState(() => _showAllProducts = v),
///   ),
/// );
/// ```
class ProductSearchDialog extends StatefulWidget {
  final Future<List<Product>> Function(String query) searchFn;
  final String title;
  final Set<int> excludeIds;

  /// When true, shows a toggle button to switch between supplier/all products.
  final bool showSupplierToggle;
  final bool supplierToggleValue;
  final ValueChanged<bool>? onSupplierToggle;

  /// When true, enables multi-product selection.
  /// Dialog returns [List<ProductSelection>] instead of a single [Product].
  final bool allowMultiSelect;

  const ProductSearchDialog({
    super.key,
    required this.searchFn,
    this.title = 'Search Product',
    this.excludeIds = const {},
    this.showSupplierToggle = false,
    this.supplierToggleValue = false,
    this.onSupplierToggle,
    this.allowMultiSelect = false,
  });

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;
  Timer? _debounce;

  // multi-select state: "productId_packId" → ProductSelection
  // For products with no packs, key is "productId_"
  final Map<String, ProductSelection> _selected = {};

  String _selKey(int productId, String packId) => '${productId}_$packId';

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && _searchController.text == value) _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await widget.searchFn(query.trim());
    if (!mounted) return;
    setState(() {
      _results = list.where((p) => !widget.excludeIds.contains(p.id)).toList();
      _loading = false;
    });
  }

  // Used for products with no packs
  void _toggleProduct(Product product) {
    final key = _selKey(product.id, '');
    setState(() {
      if (_selected.containsKey(key)) {
        _selected.remove(key);
      } else {
        _selected[key] = ProductSelection(product: product, selectedPack: null);
      }
    });
  }

  // Toggle a specific pack — each pack gets its own line item
  void _togglePack(Product product, ProductPack pack) {
    final key = _selKey(product.id, pack.id);
    setState(() {
      if (_selected.containsKey(key)) {
        _selected.remove(key);
      } else {
        _selected[key] = ProductSelection(product: product, selectedPack: pack);
      }
    });
  }

  Set<String> _selectedPackIds(int productId) {
    return _selected.entries
        .where((e) => e.key.startsWith('${productId}_'))
        .map((e) => e.value.selectedPack?.id ?? '')
        .toSet();
  }

  bool _isProductSelected(int productId) {
    return _selected.keys.any((k) => k.startsWith('${productId}_'));
  }

  void _confirmSelection() {
    if (_selected.isEmpty) return;
    Navigator.pop(context, _selected.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 600;
    final dialogWidth = isPhone ? size.width : 520.0;
    final dialogHeight = isPhone ? size.height : size.height * 0.88;

    return Dialog(
      insetPadding: isPhone
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: isPhone
          ? const RoundedRectangleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(isPhone: isPhone),
            _buildSearchField(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
            if (widget.allowMultiSelect) _buildMultiSelectFooter(isPhone: isPhone),
            if (widget.showSupplierToggle && !widget.allowMultiSelect) _buildSupplierToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({bool isPhone = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, isPhone ? MediaQuery.of(context).padding.top + 12 : 16, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: isPhone
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.allowMultiSelect && _selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selected.length} selected',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search by name or code...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _runSearch('');
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.primaryLighter.withValues(alpha: 0.25),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onChanged: _onChanged,
      ),
    );
  }

  Widget _buildList() {
    if (!_loading && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (context, i) {
        final product = _results[i];
        if (widget.allowMultiSelect) {
          final selectedPackIds = _selectedPackIds(product.id);
          return _ProductCard(
            product: product,
            allowMultiSelect: true,
            isSelected: _isProductSelected(product.id),
            selectedPackIds: selectedPackIds,
            onToggleSelect: () => _toggleProduct(product),
            onPackToggled: (pack) => _togglePack(product, pack),
            onSelect: (_) {},
          );
        }
        return _ProductCard(
          product: product,
          onSelect: (p) => Navigator.pop(context, p),
        );
      },
    );
  }

  Widget _buildMultiSelectFooter({bool isPhone = false}) {
    final count = _selected.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, isPhone ? 20 : 12),
      decoration: BoxDecoration(
        color: count > 0 ? AppColors.primary.withValues(alpha: 0.06) : Colors.grey[50],
        border: const Border(top: BorderSide(color: AppColors.border)),
        borderRadius: isPhone
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: count > 0 ? _confirmSelection : null,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(
            count == 0 ? 'Select products above' : 'Add $count item${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[200],
            disabledForegroundColor: Colors.grey[500],
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: count > 0 ? 2 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.4),
        border: const Border(top: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            widget.onSupplierToggle?.call(!widget.supplierToggleValue);
            _runSearch(_searchController.text);
          },
          icon: Icon(
            widget.supplierToggleValue
                ? Icons.filter_alt_off_outlined
                : Icons.filter_alt_outlined,
            size: 18,
          ),
          label: Text(
            widget.supplierToggleValue
                ? 'Show supplier products only'
                : 'Show all products',
            style: const TextStyle(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primaryLight),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product> onSelect;

  // multi-select extras
  final bool allowMultiSelect;
  final bool isSelected;
  // Set of pack IDs currently selected for this product
  final Set<String> selectedPackIds;
  final VoidCallback? onToggleSelect;
  // Called when a pack chip is tapped — toggles that pack's selection
  final ValueChanged<ProductPack>? onPackToggled;

  const _ProductCard({
    required this.product,
    required this.onSelect,
    this.allowMultiSelect = false,
    this.isSelected = false,
    this.selectedPackIds = const {},
    this.onToggleSelect,
    this.onPackToggled,
  });

  @override
  Widget build(BuildContext context) {
    final hasPackages = product.packs.isNotEmpty;
    final unitLabel = _unitLabel(product.defaultUnit);

    return InkWell(
      onTap: allowMultiSelect ? null : () => onSelect(product),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: isSelected ? AppColors.primaryLighter.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _ImagePlaceholder(productName: product.name),
                if (allowMultiSelect && isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LOAGMA Code : ${product.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (product.hsnCode != null || product.gstPercent > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (product.hsnCode != null)
                          _InfoChip(label: 'HSN ${product.hsnCode!}'),
                        if (product.gstPercent > 0) ...[
                          const SizedBox(width: 6),
                          _InfoChip(label: 'GST ${product.gstPercent.toStringAsFixed(product.gstPercent % 1 == 0 ? 0 : 1)}%'),
                        ],
                        if (unitLabel != null) ...[
                          const SizedBox(width: 6),
                          _InfoChip(label: unitLabel),
                        ],
                      ],
                    ),
                  ],
                  if (hasPackages) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: product.packs.map((pack) {
                        final isPackSelected = allowMultiSelect
                            ? selectedPackIds.contains(pack.id)
                            : pack.id == product.defaultPackId;
                        return _PackChip(
                          pack: pack,
                          isSelected: isPackSelected,
                          onTap: allowMultiSelect
                              ? () => onPackToggled?.call(pack)
                              : null,
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    _PackChip(
                      isSelected: allowMultiSelect ? isSelected : true,
                      fallbackLabel: unitLabel ?? '1 Unit',
                      onTap: allowMultiSelect ? onToggleSelect : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!allowMultiSelect)
              _SelectButton(onTap: () => onSelect(product))
            else if (!hasPackages)
              _MultiSelectButton(
                isSelected: isSelected,
                onTap: onToggleSelect ?? () {},
              ),
          ],
        ),
      ),
    );
  }

  String? _unitLabel(String? unit) {
    switch (unit?.toUpperCase()) {
      case 'WEIGHT':
        return 'Kg';
      case 'QUANTITY':
        return 'Pcs';
      case 'LITRE':
        return 'L';
      case 'METER':
        return 'M';
      default:
        return unit;
    }
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String productName;

  const _ImagePlaceholder({required this.productName});

  @override
  Widget build(BuildContext context) {
    final initials = productName.trim().isNotEmpty
        ? productName.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 28, color: AppColors.primaryDark),
          const SizedBox(height: 4),
          Text(
            initials,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  final ProductPack? pack;
  final bool isSelected;
  final String fallbackLabel;
  final VoidCallback? onTap;

  const _PackChip({
    this.pack,
    this.isSelected = false,
    this.fallbackLabel = '1 Unit',
    this.onTap,
  });

  String get _label {
    if (pack == null) return fallbackLabel;
    final desc = pack!.label.trim();
    // Build weight string if available
    String? weightStr;
    if (pack!.weight != null) {
      final w = pack!.weight!;
      final wStr = w % 1 == 0 ? w.toInt().toString() : w.toString();
      final u = pack!.unit ?? 'Kg';
      weightStr = '$wStr $u';
    }
    // If description looks like a real name (not just "1 Unit" style fallback), combine it with weight
    if (desc.isNotEmpty && weightStr != null) return '$desc - $weightStr';
    if (desc.isNotEmpty) return desc;
    if (weightStr != null) return weightStr;
    return fallbackLabel;
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.primaryLight,
          width: 1.2,
        ),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.primaryDark,
        ),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      child: chip,
    );
  }
}

class _SelectButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SelectButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MultiSelectButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiSelectButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryLight,
            width: 1.5,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.add,
          size: 18,
          color: isSelected ? Colors.white : AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ─── Party Search Dialog ──────────────────────────────────────────────────────

/// Shared full-screen dialog for searching customers or suppliers.
///
/// Caller provides a [searchFn] that calls the appropriate API and returns
/// a [PartyResult] list for a given query string.
///
/// Usage:
/// ```dart
/// final party = await showDialog<PartyResult>(
///   context: context,
///   builder: (_) => PartySearchDialog(
///     title: 'Select Customer',
///     hint: 'Search by name, phone or ID...',
///     searchFn: (q) => controller.searchCustomers(q),
///   ),
/// );
/// ```
class PartySearchDialog extends StatefulWidget {
  final String title;
  final String hint;
  final IconData headerIcon;
  final Future<List<PartyResult>> Function(String query) searchFn;

  const PartySearchDialog({
    super.key,
    required this.title,
    required this.searchFn,
    this.hint = 'Search by name, phone or ID...',
    this.headerIcon = Icons.person_search_outlined,
  });

  @override
  State<PartySearchDialog> createState() => _PartySearchDialogState();
}

class _PartySearchDialogState extends State<PartySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<PartyResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && _searchController.text == value) _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await widget.searchFn(query.trim());
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 600;
    final dialogWidth = isPhone ? size.width : 480.0;
    final dialogHeight = isPhone ? size.height : size.height * 0.88;

    return Dialog(
      insetPadding: isPhone
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: isPhone
          ? const RoundedRectangleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(isPhone: isPhone),
            _buildSearchField(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({bool isPhone = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        isPhone ? MediaQuery.of(context).padding.top + 12 : 16,
        8,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: isPhone
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(widget.headerIcon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _runSearch('');
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.primaryLighter.withValues(alpha: 0.25),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onChanged: _onChanged,
      ),
    );
  }

  Widget _buildList() {
    if (!_loading && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (context, i) => _PartyCard(
        result: _results[i],
        onSelect: (r) => Navigator.pop(context, r),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final PartyResult result;
  final ValueChanged<PartyResult> onSelect;

  const _PartyCard({required this.result, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _PartyAvatar(name: result.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.shopName != null && result.shopName!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      result.shopName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _InfoBadge(
                        icon: Icons.tag,
                        label: result.code != null
                            ? '${result.code}'
                            : 'ID: ${result.id}',
                      ),
                      if (result.phone != null && result.phone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _InfoBadge(
                          icon: Icons.phone_outlined,
                          label: result.phone!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onSelect(result),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyAvatar extends StatelessWidget {
  final String name;

  const _PartyAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Consistent input decoration theme
class AppInputDecoration {
  static InputDecoration standard({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
