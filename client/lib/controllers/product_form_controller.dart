import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/tax_model.dart';

/// UI model for a single package row in the wizard.
class PackageUiModel {
  PackageUiModel({
    required this.id,
    required this.description,
    required this.size,
    required this.unit,
    required this.marketPrice,
    required this.retailPricesRaw,
    this.minLimit,
    this.maxLimit,
    this.barcode,
    this.isActive = true,
  });

  final String id;
  final String description;
  final double size;
  final String unit;
  final double marketPrice;
  final String retailPricesRaw; // e.g. \"100,95,90\"
  final int? minLimit;
  final int? maxLimit;
  final String? barcode;
  final bool isActive;

  Map<String, dynamic> toJson() {
    // Parse comma-separated prices into a small map if valid.
    Map<String, double>? prices;
    final parts = retailPricesRaw.split(',').map((p) => p.trim()).toList();
    if (parts.length == 3) {
      final newPrice = double.tryParse(parts[0]);
      final regularPrice = double.tryParse(parts[1]);
      final homePrice = double.tryParse(parts[2]);
      if (newPrice != null && regularPrice != null && homePrice != null) {
        prices = {
          'new': newPrice,
          'regular': regularPrice,
          'home': homePrice,
        };
      }
    }

    return {
      'id': id,
      'description': description,
      'size': size,
      'unit': unit,
      'market_price': marketPrice,
      if (prices != null) 'prices': prices,
      'min_limit': minLimit,
      'max_limit': maxLimit,
      'barcode': barcode,
      'is_active': isActive,
    };
  }
}

class ProductFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? productId;

  ProductFormController({this.productId});

  // Wizard step: 1 = basic/inventory, 2 = tax/status/packages/images.
  final currentStep = 1.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  // Step 1 – basic info & inventory.
  final name = ''.obs;
  final keywords = ''.obs;
  final description = ''.obs;
  final brand = ''.obs;
  final ctypeId = 'vegetables_fruits'.obs;
  final seqNo = ''.obs;

  // Category (parent_cat_id=0) and Subcategory (parent_cat_id=category.cat_id)
  final categories = <Category>[].obs;
  final subcategories = <Category>[].obs;
  final selectedCategoryId = 0.obs;
  final selectedSubcategoryId = 0.obs;

  final productType = 'SINGLE'.obs;
  final defaultUnit = 'WEIGHT'.obs;
  final orderLimit = ''.obs;
  final bufferLimit = ''.obs;

  // Step 2 – tax, status, packages.
  final hsnCode = ''.obs;
  final availableTaxes = <Tax>[].obs;
  final selectedTaxIds = <int>[].obs;
  final selectedTaxPercents = <int, String>{}.obs;
  final isPublished = true.obs;
  final inStock = true.obs;

  final code = ''.obs;

  final packages = <PackageUiModel>[].obs;

  bool get isEditMode => productId != null;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadCategories();
    await loadAvailableTaxes();
    if (productId != null) {
      await _loadProduct();
    }
  }

  Future<void> loadAvailableTaxes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.taxes).replace(
          queryParameters: {'limit': '100', 'is_active': 'true'},
        ),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          availableTaxes.value = list
              .map((e) => Tax.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Load taxes error: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categories).replace(
          queryParameters: {'parent_cat_id': '0'},
        ),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          categories.value = list
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Load categories error: $e');
    }
  }

  Future<void> loadSubcategoriesForCategory(int parentCatId) async {
    if (parentCatId == 0) {
      subcategories.clear();
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categories).replace(
          queryParameters: {'parent_cat_id': parentCatId.toString()},
        ),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          subcategories.value = list
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          subcategories.clear();
        }
      } else {
        subcategories.clear();
      }
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Load subcategories error: $e');
      subcategories.clear();
    }
  }

  void onCategoryChanged(int? catId) {
    selectedCategoryId.value = catId ?? 0;
    selectedSubcategoryId.value = 0;
    if (catId != null && catId != 0) {
      loadSubcategoriesForCategory(catId);
    } else {
      subcategories.clear();
    }
  }

  void goToStep(int step) {
    if (step < 1 || step > 2) return;
    currentStep.value = step;
  }

  bool validateStep1() {
    // Rely on form validators for now; they run on overall form submit.
    // Here we just check essential fields from controller state.
    return name.value.trim().isNotEmpty;
  }

  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  bool validateStep2() {
    if (hsnCode.value.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'Please select HSN code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    if (selectedTaxIds.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please select at least one tax',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    for (final taxId in selectedTaxIds) {
      final raw = selectedTaxPercents[taxId]?.trim() ?? '';
      if (raw.isEmpty) {
        Get.snackbar(
          'Validation',
          'Enter tax percent for selected taxes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
      final value = double.tryParse(raw);
      if (value == null || value < 0 || value > 100) {
        Get.snackbar(
          'Validation',
          'Tax percent must be between 0 and 100',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    }
    // For PACK_WISE products, require at least one active package.
    if (productType.value == 'PACK_WISE') {
      final hasActive =
          packages.any((p) => p.isActive); // at least one active package.
      if (!hasActive) {
        Get.snackbar(
          'Validation',
          'Add at least one package for pack-wise products',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    }
    return true;
  }

  void toggleTaxSelection(int taxId, bool isSelected) {
    if (isSelected) {
      if (!selectedTaxIds.contains(taxId)) {
        selectedTaxIds.add(taxId);
      }
      selectedTaxPercents.putIfAbsent(taxId, () => '');
    } else {
      selectedTaxIds.remove(taxId);
      selectedTaxPercents.remove(taxId);
    }
    selectedTaxIds.refresh();
    selectedTaxPercents.refresh();
  }

  void updateTaxPercentFromInput(int taxId, String value) {
    selectedTaxPercents[taxId] = value;
    selectedTaxPercents.refresh();
  }

  String taxPercentFor(int taxId) {
    return selectedTaxPercents[taxId] ?? '';
  }

  double get totalSelectedTaxPercent {
    double sum = 0;
    for (final taxId in selectedTaxIds) {
      sum += double.tryParse(selectedTaxPercents[taxId]?.trim() ?? '') ?? 0;
    }
    return sum;
  }

  bool _isSamePercent(double a, double b) => (a - b).abs() < 0.0001;

  Future<Map<int, ProductTax>> _fetchExistingProductTaxes(int savedProductId) async {
    final map = <int, ProductTax>{};
    final response = await http.get(
      Uri.parse(ApiConfig.productTaxes).replace(
        queryParameters: {'product_id': savedProductId.toString(), 'limit': '200'},
      ),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      return map;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      return map;
    }
    final List rows = data['data'] ?? [];
    for (final row in rows) {
      final model = ProductTax.fromJson(row as Map<String, dynamic>);
      map[model.taxId] = model;
    }
    return map;
  }

  Future<bool> _syncProductTaxes(int savedProductId) async {
    try {
      final existingByTaxId = await _fetchExistingProductTaxes(savedProductId);
      final desiredByTaxId = <int, double>{
        for (final taxId in selectedTaxIds)
          taxId: double.tryParse(selectedTaxPercents[taxId]?.trim() ?? '') ?? 0,
      };

      bool allSuccess = true;

      for (final entry in existingByTaxId.entries) {
        final existing = entry.value;
        final desired = desiredByTaxId[entry.key];
        if (desired == null || !_isSamePercent(existing.taxPercent, desired)) {
          final deleteResponse = await http.delete(
            Uri.parse('${ApiConfig.productTaxes}/${existing.id}'),
            headers: {'Accept': 'application/json'},
          );
          if (deleteResponse.statusCode != 200 && deleteResponse.statusCode != 204) {
            allSuccess = false;
          }
        }
      }

      for (final entry in desiredByTaxId.entries) {
        final existing = existingByTaxId[entry.key];
        if (existing != null && _isSamePercent(existing.taxPercent, entry.value)) {
          continue;
        }

        final postResponse = await http.post(
          Uri.parse(ApiConfig.productTaxes),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'product_id': savedProductId,
            'tax_id': entry.key,
            'tax_percent': entry.value,
          }),
        );
        if (postResponse.statusCode != 200 && postResponse.statusCode != 201) {
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Sync product taxes error: $e');
      return false;
    }
  }

  int? _extractSavedProductId(Map<String, dynamic> responseData) {
    final rawData = responseData['data'];
    if (rawData is Map<String, dynamic>) {
      final rawId = rawData['product_id'] ?? rawData['id'];
      if (rawId is int) return rawId;
      if (rawId is String) return int.tryParse(rawId);
    }
    return productId;
  }

  Future<void> _loadSelectedTaxesForProduct(int targetProductId) async {
    try {
      final existingByTaxId = await _fetchExistingProductTaxes(targetProductId);
      selectedTaxIds.assignAll(existingByTaxId.keys);
      selectedTaxPercents.clear();
      for (final entry in existingByTaxId.entries) {
        selectedTaxPercents[entry.key] = entry.value.taxPercent.toString();
      }
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Load selected taxes error: $e');
    }
  }

  void addPackage(PackageUiModel pkg) {
    packages.add(pkg);
  }

  void removePackage(String id) {
    packages.removeWhere((p) => p.id == id);
  }

  Future<void> _loadProduct() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.products}/$productId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final productJson = data['data'] as Map<String, dynamic>;
          final product = Product.fromJson(productJson);

          // Basic info
          name.value = product.name;
          code.value = product.code ?? '';
          keywords.value = productJson['keywords']?.toString() ?? '';
          description.value = productJson['description']?.toString() ?? '';
          brand.value = productJson['brand']?.toString() ?? '';
          ctypeId.value = productJson['ctype_id']?.toString() ?? 'vegetables_fruits';
          seqNo.value = productJson['seq_no']?.toString() ?? '';

          // Category & subcategory (product has cat_id, parent_cat_id)
          final int catId = _intFromJson(productJson['cat_id']);
          final int parentCatId = _intFromJson(productJson['parent_cat_id']);
          if (parentCatId != 0) {
            selectedCategoryId.value = parentCatId;
            selectedSubcategoryId.value = catId;
            loadSubcategoriesForCategory(parentCatId);
          } else {
            selectedCategoryId.value = catId;
            selectedSubcategoryId.value = 0;
            if (catId != 0) loadSubcategoriesForCategory(catId);
          }

          // Inventory
          productType.value =
              (productJson['inventory_type'] ?? product.productType).toString();
          defaultUnit.value =
              (productJson['inventory_unit_type'] ?? product.defaultUnit ?? '')
                  .toString();
          orderLimit.value = productJson['order_limit']?.toString() ?? '0';
          bufferLimit.value = productJson['buffer_limit']?.toString() ?? '0';

          // Tax & status
          hsnCode.value = productJson['hsn_code']?.toString() ?? '';
          isPublished.value =
              (productJson['is_published']?.toString() ?? '0') == '1';
          inStock.value = (productJson['in_stock']?.toString() ?? '0') == '1';

            await _loadSelectedTaxesForProduct(product.id);

          // Packs JSON, if present.
          final packsRaw = productJson['packs'];
          if (packsRaw is String && packsRaw.trim().isNotEmpty) {
            try {
              final decoded = jsonDecode(packsRaw);
              if (decoded is List) {
                packages.assignAll(decoded.map((e) {
                  final m = e as Map<String, dynamic>;
                  final desc = m['description']?.toString() ?? '';
                  final size = (m['size'] as num?)?.toDouble() ?? 0.0;
                  final unit = m['unit']?.toString() ?? '';
                  final marketPrice =
                      (m['market_price'] as num?)?.toDouble() ?? 0.0;
                  final prices = m['prices'] as Map<String, dynamic>?;
                  final retailRaw = prices == null
                      ? ''
                      : [
                          prices['new'],
                          prices['regular'],
                          prices['home'],
                        ]
                          .map((v) => v?.toString() ?? '')
                          .join(', ');
                  return PackageUiModel(
                    id: m['id']?.toString() ?? '',
                    description: desc,
                    size: size,
                    unit: unit,
                    marketPrice: marketPrice,
                    retailPricesRaw: retailRaw,
                    minLimit: m['min_limit'] as int?,
                    maxLimit: m['max_limit'] as int?,
                    barcode: m['barcode']?.toString(),
                    isActive: (m['is_active']?.toString() ?? '1') == '1',
                  );
                }).toList());
              }
            } catch (e) {
              debugPrint('[PRODUCT_FORM] Failed to parse packs JSON: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load product details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    if (!validateStep1() || !validateStep2()) return false;

    isSaving.value = true;
    try {
      final int catId = selectedSubcategoryId.value != 0
          ? selectedSubcategoryId.value
          : selectedCategoryId.value;
      final int parentCatId = selectedSubcategoryId.value != 0
          ? selectedCategoryId.value
          : 0;

      final payload = <String, dynamic>{
        // Basic info
        'product_name': name.value.trim(),
        'product_code': code.value.trim().isEmpty ? null : code.value.trim(),
        'keywords': keywords.value.trim().isEmpty ? null : keywords.value.trim(),
        'description': description.value.trim(),
        'brand': brand.value.trim(),
        'ctype_id': ctypeId.value.trim(),
        'seq_no': int.tryParse(seqNo.value.trim()) ?? 0,

        'cat_id': catId,
        'parent_cat_id': parentCatId,

        // Inventory
        'inventory_type': productType.value,
        'inventory_unit_type': defaultUnit.value.trim().isEmpty
            ? null
            : defaultUnit.value.trim(),
        'order_limit': int.tryParse(orderLimit.value.trim()) ?? 0,
        'buffer_limit': int.tryParse(bufferLimit.value.trim()) ?? 0,

        // Tax & status
        'hsn_code': hsnCode.value.trim(),
        'gst_percent': totalSelectedTaxPercent,
        'is_published': isPublished.value ? 1 : 0,
        'in_stock': inStock.value ? 1 : 0,
      };

      // Packs JSON and default pack id.
      if (packages.isNotEmpty) {
        final packsJson = packages.map((p) => p.toJson()).toList();
        payload['packs'] = packsJson;
        payload['default_pack_id'] = packages.first.id;
      }

      final url =
          isEditMode ? '${ApiConfig.products}/$productId' : ApiConfig.products;

      final response = isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final savedProductId = _extractSavedProductId(data);
          if (savedProductId != null) {
            final taxSyncOk = await _syncProductTaxes(savedProductId);
            if (!taxSyncOk) {
              Get.snackbar(
                'Warning',
                'Product saved, but some tax assignments could not be synced.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }
          }

          await Fluttertoast.showToast(
            msg: data['message']?.toString() ?? 'Product saved successfully',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 14,
          );
          return true;
        }
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to save product',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[PRODUCT_FORM] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to save product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

