import 'dart:convert';
import 'auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../models/product_package_model.dart';

class PackEntryState {
  final descController     = TextEditingController();
  final sizeController     = TextEditingController();
  final marketPriceController  = TextEditingController();
  final newPriceController     = TextEditingController();
  final regularPriceController = TextEditingController();
  final homePriceController    = TextEditingController();
  final maxVariationController = TextEditingController();
  final unit = 'KG'.obs;

  void dispose() {
    descController.dispose();
    sizeController.dispose();
    marketPriceController.dispose();
    newPriceController.dispose();
    regularPriceController.dispose();
    homePriceController.dispose();
    maxVariationController.dispose();
  }
}

class ProductPackageFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? packageId;
  final int? productId;

  final isLoading         = false.obs;
  final isSaving          = false.obs;
  final isLoadingProducts = false.obs;

  // Units from units_master table (pre-seeded with fallback so dropdown is never empty)
  final units = <String>['KG', 'GM', 'L', 'ML', 'PCS', 'BOX', 'PACK', 'NOS'].obs;

  // Product search dropdown (used when productId is not pre-set)
  final products        = <Product>[].obs;
  final selectedProduct = Rxn<Product>();

  // Add mode: list of pack entries (supports adding multiple at once)
  final packEntries = <PackEntryState>[].obs;

  // Edit mode: single pre-loaded pack fields
  final editDescription  = ''.obs;
  final editPackSize     = ''.obs;
  final editUnit         = 'KG'.obs;
  final editMarketPrice  = ''.obs;
  final editNewPrice     = ''.obs;
  final editRegularPrice = ''.obs;
  final editHomePrice    = ''.obs;
  final editMaxVariation = ''.obs;

  ProductPackageFormController({this.productId, this.packageId});

  bool get isEditMode => packageId != null;

  @override
  void onInit() {
    super.onInit();
    _loadUnits();
    if (isEditMode) {
      _loadPackage();
    } else {
      packEntries.add(PackEntryState());
      if (productId == null) _loadProducts();
    }
  }

  Future<void> _loadUnits() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.unitTypes), headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          final parsed = data.map((e) => e.toString().trim()).where((u) => u.isNotEmpty).toSet().toList();
          if (parsed.isNotEmpty) {
            units.value = parsed;
            // Ensure existing pack entries use a valid unit from the new list
            for (final entry in packEntries) {
              if (!parsed.contains(entry.unit.value)) {
                entry.unit.value = parsed.first;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Units load error: $e');
      // fallback already set in field initializer
    }
  }

  @override
  void onClose() {
    for (final e in packEntries) {
      e.dispose();
    }
    super.onClose();
  }

  void addEntry() => packEntries.add(PackEntryState());

  void removeEntry(int index) {
    if (packEntries.length > 1) {
      packEntries[index].dispose();
      packEntries.removeAt(index);
    }
  }

  Future<void> _loadProducts() async {
    isLoadingProducts.value = true;
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.products}?limit=50'),
              headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value =
              data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Products load error: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length < 2) {
      await _loadProducts();
      return;
    }
    try {
      final url =
          '${ApiConfig.products}?search=${Uri.encodeComponent(query)}&limit=100';
      final response = await http
          .get(Uri.parse(url), headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value =
              data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Search error: $e');
    }
  }

  Future<void> _loadPackage() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.productPackages}/$packageId'),
        headers: AuthController.getHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final json    = data['data'] as Map<String, dynamic>;
          final model   = ProductPackage.fromJson(json);
          editDescription.value  = model.description;
          editPackSize.value     = model.packSize.toString();
          editUnit.value         = model.unit;
          editMarketPrice.value  = (model.marketPrice ?? model.price)?.toString() ?? '';
          // Split retail_prices CSV back into 3 separate fields
          final rp = json['retail_prices']?.toString() ?? '';
          if (rp.isNotEmpty) {
            final parts = rp.split(',').map((e) => e.trim()).toList();
            if (parts.length == 3) {
              editNewPrice.value     = parts[0];
              editRegularPrice.value = parts[1];
              editHomePrice.value    = parts[2];
            }
          }
          editMaxVariation.value = json['mv'] != null ? json['mv'].toString() : '';
        }
      }
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Load error: $e');
      _showError('Failed to load package');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    return isEditMode ? _saveEdit() : _saveNew();
  }

  Future<bool> _saveEdit() async {
    isSaving.value = true;
    try {
      final mvTrimmed = editMaxVariation.value.trim();
      final payload = {
        'description':  editDescription.value.trim(),
        'pack_size':    double.parse(editPackSize.value.trim()),
        'unit':         editUnit.value,
        'market_price': double.parse(editMarketPrice.value.trim()),
        'retail_prices': _buildRetailPricesCsv(
            editNewPrice.value, editRegularPrice.value, editHomePrice.value),
        if (mvTrimmed.isNotEmpty) 'mv': double.parse(mvTrimmed),
        if (mvTrimmed.isEmpty)    'mv': null,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.productPackages}/$packageId'),
        headers: AuthController.jsonHeaders,
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      _showError('Failed to update package: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> _saveNew() async {
    final effectiveProductId = productId ?? selectedProduct.value?.id;
    if (effectiveProductId == null) {
      Get.snackbar('Validation', 'Please select a product',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
      return false;
    }

    isSaving.value = true;
    try {
      int saved = 0;
      for (final entry in packEntries) {
        final mvTrimmed = entry.maxVariationController.text.trim();
        final payload = {
          'product_id':   effectiveProductId,
          'description':  entry.descController.text.trim(),
          'pack_size':    double.parse(entry.sizeController.text.trim()),
          'unit':         entry.unit.value,
          'market_price': double.parse(entry.marketPriceController.text.trim()),
          'retail_prices': _buildRetailPricesCsv(
              entry.newPriceController.text,
              entry.regularPriceController.text,
              entry.homePriceController.text),
          if (mvTrimmed.isNotEmpty) 'mv': double.parse(mvTrimmed),
          if (mvTrimmed.isEmpty)    'mv': null,
        };

        final response = await http.post(
          Uri.parse(ApiConfig.productPackages),
          headers: AuthController.jsonHeaders,
          body: jsonEncode(payload),
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            data['success'] == true) {
          saved++;
        }
      }

      if (saved == packEntries.length) {
        await Fluttertoast.showToast(
          msg: '$saved pack${saved > 1 ? 's' : ''} saved successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      } else {
        _showError('Only $saved / ${packEntries.length} packs saved');
        return false;
      }
    } catch (e) {
      _showError('Failed to save packages: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String? _buildRetailPricesCsv(String newP, String regP, String homeP) {
    final n = newP.trim();
    final r = regP.trim();
    final h = homeP.trim();
    if (n.isEmpty && r.isEmpty && h.isEmpty) return null;
    return '$n,$r,$h';
  }

  bool _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['success'] == true) {
        Fluttertoast.showToast(
          msg: data['message']?.toString() ?? 'Package updated',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      }
    }
    _showError(data['message']?.toString() ?? 'Failed to save package');
    return false;
  }

  void _showError(String msg) => Get.snackbar('Error', msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white);
}
