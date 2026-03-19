import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'product_form_screen.dart';

class ProductViewScreen extends StatefulWidget {
  final int productId;

  const ProductViewScreen({super.key, required this.productId});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  bool _isLoading = false;
  String? _error;
  Product? _product;
  Map<String, dynamic>? _raw;
  String? _categoryName;
  String? _parentCategoryName;
  String? _hsnActiveLabel;
  List<Map<String, dynamic>> _supplierLinks = [];

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${ApiConfig.products}/${widget.productId}').replace(
        queryParameters: {
          'include_taxes': '1',
          'include_stock': '1',
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final raw = data['data'] as Map<String, dynamic>;
          setState(() {
            _raw = raw;
            _product = Product.fromJson(raw);
          });
          await _loadRelatedMetadata(raw);
          return;
        }
        throw Exception(data['message'] ?? 'Failed to load product');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRelatedMetadata(Map<String, dynamic> raw) async {
    final catId = int.tryParse(raw['cat_id']?.toString() ?? '0') ?? 0;
    final parentCatId = int.tryParse(raw['parent_cat_id']?.toString() ?? '0') ?? 0;
    final hsnCode = raw['hsn_code']?.toString() ?? '';

    await Future.wait([
      _fetchCategoryName(catId).then((value) => _categoryName = value),
      _fetchCategoryName(parentCatId).then((value) => _parentCategoryName = value),
      _fetchHsnStatus(hsnCode).then((value) => _hsnActiveLabel = value),
      _fetchSupplierLinks(widget.productId).then((value) => _supplierLinks = value),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _fetchCategoryName(int categoryId) async {
    if (categoryId <= 0) return null;
    try {
      final uri = Uri.parse('${ApiConfig.categories}/$categoryId');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final category = data['data'] as Map<String, dynamic>;
          return category['name']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchHsnStatus(String hsnCode) async {
    if (hsnCode.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(ApiConfig.hsnCodes).replace(
        queryParameters: {'search': hsnCode},
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          final items = data['data'] as List;
          for (final item in items) {
            if (item is Map<String, dynamic> &&
                item['hsn_code']?.toString() == hsnCode) {
              final isActive = item['is_active']?.toString() == '1' ||
                  item['is_active'] == true;
              return isActive ? 'Active' : 'Inactive';
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchSupplierLinks(int productId) async {
    try {
      final uri = Uri.parse(ApiConfig.supplierProducts).replace(
        queryParameters: {
          'product_id': productId.toString(),
          'limit': '200',
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final raw = _raw ?? const <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Product Details',
        subtitle: product?.name ?? 'View product',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: product == null
                ? null
                : () async {
                    await Get.to(
                      () => ProductFormScreen(productId: product.id),
                    );
                    if (mounted) {
                      await _fetchProduct();
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProduct,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
              : product == null
                  ? ContentCard(
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: _error ?? 'Product not found.',
                        actionLabel: 'Retry',
                        onAction: _fetchProduct,
                      ),
                    )
                  : Column(
                      children: [
                        ContentCard(
                          title: 'Overview',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(label: 'Product ID', value: 'P-${product.id}'),
                              _InfoRow(label: 'Name', value: product.name),
                              if (product.code != null && product.code!.isNotEmpty)
                                _InfoRow(label: 'Code', value: product.code!),
                              if ((raw['brand'] ?? '').toString().trim().isNotEmpty)
                                _InfoRow(label: 'Brand', value: raw['brand'].toString()),
                              if ((raw['description'] ?? '').toString().trim().isNotEmpty)
                                _InfoRow(
                                  label: 'Description',
                                  value: raw['description'].toString(),
                                ),
                              if ((raw['keywords'] ?? '').toString().trim().isNotEmpty)
                                _InfoRow(
                                  label: 'Keywords',
                                  value: raw['keywords'].toString(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ContentCard(
                          title: 'Category & Limits',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                label: 'Category ID',
                                value: raw['cat_id']?.toString() ?? '0',
                              ),
                              if ((_categoryName ?? '').isNotEmpty)
                                _InfoRow(
                                  label: 'Category Name',
                                  value: _categoryName!,
                                ),
                              _InfoRow(
                                label: 'Parent Category ID',
                                value: raw['parent_cat_id']?.toString() ?? '0',
                              ),
                              if ((_parentCategoryName ?? '').isNotEmpty)
                                _InfoRow(
                                  label: 'Parent Category Name',
                                  value: _parentCategoryName!,
                                ),
                              _InfoRow(
                                label: 'Sequence No',
                                value: raw['seq_no']?.toString() ?? '0',
                              ),
                              _InfoRow(
                                label: 'Order Limit',
                                value: raw['order_limit']?.toString() ?? '0',
                              ),
                              _InfoRow(
                                label: 'Buffer Limit',
                                value: raw['buffer_limit']?.toString() ?? '0',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ContentCard(
                          title: 'Inventory & Status',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                label: 'Inventory Type',
                                value: product.productType,
                              ),
                              if ((raw['inventory_unit_type'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                _InfoRow(
                                  label: 'Inventory Unit Type',
                                  value: raw['inventory_unit_type'].toString(),
                                ),
                              if (product.defaultUnit != null)
                                _InfoRow(
                                  label: 'Unit Type',
                                  value: product.defaultUnit!,
                                ),
                              _InfoRow(
                                label: 'HSN Code',
                                value: raw['hsn_code']?.toString() ?? '',
                              ),
                              if ((_hsnActiveLabel ?? '').isNotEmpty)
                                _InfoRow(
                                  label: 'HSN Status',
                                  value: _hsnActiveLabel!,
                                ),
                              _InfoRow(
                                label: 'Published',
                                value: (raw['is_published']?.toString() ?? '0') ==
                                        '1'
                                    ? 'Yes'
                                    : 'No',
                              ),
                              _InfoRow(
                                label: 'In Stock',
                                value: (raw['in_stock']?.toString() ?? '0') == '1'
                                    ? 'Yes'
                                    : 'No',
                              ),
                              _InfoRow(
                                label: 'GST Percent',
                                value: '${product.gstPercent.toStringAsFixed(2)}%',
                              ),
                              if ((raw['ctype_id'] ?? '').toString().trim().isNotEmpty)
                                _InfoRow(
                                  label: 'Cart Type',
                                  value: raw['ctype_id'].toString(),
                                ),
                              if ((raw['default_pack_id'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                _InfoRow(
                                  label: 'Default Pack ID',
                                  value: raw['default_pack_id'].toString(),
                                ),
                              if ((raw['stock_ut_id'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                _InfoRow(
                                  label: 'Stock Unit ID',
                                  value: raw['stock_ut_id'].toString(),
                                ),
                              if (product.stock != null)
                                _InfoRow(
                                  label: 'Stock',
                                  value: product.stock!.toStringAsFixed(2),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ContentCard(
                          title: 'Taxes',
                          child: product.taxes.isEmpty
                              ? const Text(
                                  'No taxes linked to this product.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : Column(
                                  children: product.taxes
                                      .map(
                                        (tax) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            Icons.receipt_long_outlined,
                                          ),
                                          title: Text(
                                            tax.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${tax.category} • ${tax.subCategory}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          trailing: Text(
                                            '${tax.percent.toStringAsFixed(2)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 16),
                        ContentCard(
                          title: 'Packages',
                          child: _PackagesView(packsRaw: raw['packs']),
                        ),
                        const SizedBox(height: 16),
                        ContentCard(
                          title: 'Suppliers',
                          child: _supplierLinks.isEmpty
                              ? const Text(
                                  'No supplier links found.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : Column(
                                  children: _supplierLinks.map((item) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.storefront_outlined),
                                      title: Text(
                                        item['supplier_name']?.toString() ??
                                            'Supplier',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'SKU: ${item['supplier_sku'] ?? '-'} • Product: ${item['supplier_product_name'] ?? '-'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      trailing: Text(
                                        (item['is_active']?.toString() ?? '1') ==
                                                '1'
                                            ? 'Active'
                                            : 'Inactive',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _PackagesView extends StatelessWidget {
  final dynamic packsRaw;

  const _PackagesView({required this.packsRaw});

  Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  Map<String, dynamic>? _normalizePack(dynamic value) {
    final map = _asStringKeyMap(value);
    if (map == null) return null;

    // If nested under a 'pack' key, unwrap once.
    final nested = map['pack'];
    if (nested != null) {
      final nestedMap = _asStringKeyMap(nested);
      if (nestedMap != null) {
        return nestedMap;
      }
    }

    return map;
  }

  List<Map<String, dynamic>> _parsePacks() {
    dynamic source = packsRaw;
    if (source == null) return [];

    if (source is String) {
      final rawText = source.trim();
      if (rawText.isEmpty || rawText == '[]' || rawText == '{}') return [];
      try {
        source = jsonDecode(rawText);
      } catch (_) {
        return [];
      }
    }

    final packs = <Map<String, dynamic>>[];

    if (source is List) {
      for (final item in source) {
        final normalized = _normalizePack(item);
        if (normalized != null) {
          packs.add(normalized);
        }
      }
      return packs;
    }

    final mapSource = _asStringKeyMap(source);
    if (mapSource != null) {
      for (final entry in mapSource.entries) {
        final normalized = _normalizePack(entry.value);
        if (normalized != null) {
          normalized.putIfAbsent('id', () => entry.key);
          normalized.putIfAbsent('pi', () => entry.key);
          packs.add(normalized);
        }
      }
    }

    return packs;
  }

  @override
  Widget build(BuildContext context) {
    final packs = _parsePacks();
    if (packs.isEmpty) {
      return const Text(
        'No packages available.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    return Column(
      children: packs.map((pack) {
        final packId =
            pack['id']?.toString() ?? pack['pi']?.toString() ?? '-';
        final size =
            pack['size']?.toString() ?? pack['ps']?.toString() ?? pack['pack_size']?.toString() ?? '';
        final unit =
            pack['unit']?.toString() ?? pack['pu']?.toString() ?? pack['pack_unit']?.toString() ?? '';
        final desc =
            pack['description']?.toString() ?? pack['name']?.toString() ?? '';
        final market =
            pack['market_price']?.toString() ?? pack['op']?.toString() ?? '';
        final stock =
            pack['stock']?.toString() ?? pack['stk']?.toString() ?? '';
        final tax = pack['tax']?.toString() ?? pack['tx']?.toString() ?? '';
        final isActive =
            pack['is_active']?.toString() ?? pack['in_stk']?.toString() ?? '1';
        dynamic retailPrices = pack['prices'];
        retailPrices ??= pack['rp'];

        String retailText = '';
        if (retailPrices is Map) {
          retailText =
              'new ${retailPrices['new'] ?? ''}, regular ${retailPrices['regular'] ?? ''}, home ${retailPrices['home'] ?? ''}';
        } else if (retailPrices != null && retailPrices.toString().trim().isNotEmpty) {
          retailText = retailPrices.toString();
        }

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(
            desc.isNotEmpty ? desc : '$size $unit',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pack ID: $packId'),
              if (size.isNotEmpty || unit.isNotEmpty) Text('Size: $size $unit'),
              if (stock.isNotEmpty) Text('Stock: $stock'),
              if (tax.isNotEmpty) Text('Tax: $tax'),
              if (market.isNotEmpty) Text('Market: $market'),
              if (retailText.isNotEmpty) Text('Retail: $retailText'),
              Text('Active: ${isActive == '1' ? 'Yes' : 'No'}'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
