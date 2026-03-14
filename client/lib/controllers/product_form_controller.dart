import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';

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

  final productType = 'SINGLE'.obs;
  final defaultUnit = ''.obs;
  final orderLimit = ''.obs;
  final bufferLimit = ''.obs;

  // Step 2 – tax, status, packages.
  final hsnCode = ''.obs;
  final gstPercent = ''.obs;
  final isPublished = true.obs;
  final inStock = true.obs;

  final code = ''.obs;

  final packages = <PackageUiModel>[].obs;

  bool get isEditMode => productId != null;

  @override
  void onInit() {
    super.onInit();
    if (productId != null) {
      _loadProduct();
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

  bool validateStep2() {
    if (hsnCode.value.trim().isEmpty) return false;
    // For PACK_WISE products, require at least one active package.
    if (productType.value == 'PACK_WISE') {
      final hasActive =
          packages.any((p) => p.isActive); // at least one active package.
      if (!hasActive) return false;
    }
    return true;
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
          gstPercent.value = productJson['gst_percent']?.toString() ?? '';
          isPublished.value =
              (productJson['is_published']?.toString() ?? '0') == '1';
          inStock.value = (productJson['in_stock']?.toString() ?? '0') == '1';

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
      final payload = <String, dynamic>{
        // Basic info
        'product_name': name.value.trim(),
        'product_code': code.value.trim().isEmpty ? null : code.value.trim(),
        'keywords': keywords.value.trim().isEmpty ? null : keywords.value.trim(),
        'description': description.value.trim(),
        'brand': brand.value.trim(),
        'ctype_id': ctypeId.value.trim(),
        'seq_no': int.tryParse(seqNo.value.trim()) ?? 0,

        // Inventory
        'inventory_type': productType.value,
        'inventory_unit_type': defaultUnit.value.trim().isEmpty
            ? null
            : defaultUnit.value.trim(),
        'order_limit': int.tryParse(orderLimit.value.trim()) ?? 0,
        'buffer_limit': int.tryParse(bufferLimit.value.trim()) ?? 0,

        // Tax & status
        'hsn_code': hsnCode.value.trim(),
        'gst_percent': double.tryParse(gstPercent.value.trim()) ?? 0.0,
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
          Get.snackbar(
            'Success',
            data['message']?.toString() ?? 'Product saved successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
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

