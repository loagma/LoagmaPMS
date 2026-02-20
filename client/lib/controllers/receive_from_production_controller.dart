import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class ReceiveFromProductionController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? receiveId;

  final items = <ReceiveItemRow>[].obs;
  final remarks = ''.obs;

  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  ReceiveFromProductionController({this.receiveId});

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _loadUnitTypes();
    if (receiveId != null) {
      _loadReceiveData();
    } else {
      // Create mode: add one empty row by default
      addItemRow();
    }
  }

  Future<void> _loadReceiveData() async {
    if (receiveId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.receives}/$receiveId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final receiveData = data['data'] as Map<String, dynamic>;
          final receive = receiveData['receive'];
          final itemsData = receiveData['items'] as List? ?? [];
          remarks.value = receive['remarks']?.toString() ?? '';
          items.clear();
          for (var item in itemsData) {
            final row = ReceiveItemRow();
            row.finishedProduct.value = Product(
              id: item['finished_product_id'],
              name: item['finished_product_name'] ?? '',
              productType: 'FINISHED',
            );
            row.quantity.value = item['quantity']?.toString() ?? '';
            row.unitType.value = item['unit_type']?.toString() ?? 'KG';
            items.add(row);
          }
        }
      }
    } catch (e) {
      debugPrint('[RECEIVE] Load failed: $e');
      _showError('Failed to load receive data');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isEditMode => receiveId != null;

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      final uri = Uri.parse('${ApiConfig.products}?limit=50');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        _showError('Failed to load products (${response.statusCode})');
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'API error');
      }

      final List data = decoded['data'] ?? [];
      products.value = data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('[RECEIVE] Error: $e\n$st');
      _showError('Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.unitTypes),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List types = data['data'] ?? [];
          unitTypes.value = types.cast<String>();
        }
      }
    } catch (e) {
      unitTypes.value = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
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
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[RECEIVE] Search error: $e');
    }
  }

  void setRemarks(String value) => remarks.value = value;

  void addItemRow() => items.add(ReceiveItemRow());

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  List<Product> getProductsExcluding(Iterable<int> excludeIds) =>
      products.where((p) => !excludeIds.contains(p.id)).toList();

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (items.isEmpty) {
      _showError('Please add at least one finished product');
      return false;
    }
    for (var row in items) {
      if (row.finishedProduct.value == null) {
        _showError('Please select finished product for all items');
        return false;
      }
      final qty = double.tryParse(row.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Please enter valid quantity for all items');
        return false;
      }
    }
    return true;
  }

  Future<void> _saveReceive(String saveStatus) async {
    if (!_validateForm()) return;

    isSaving.value = true;
    try {
      final payload = {
        'status': saveStatus,
        'remarks': remarks.value.trim(),
        'items': items.map((row) {
          return {
            'finished_product_id': row.finishedProduct.value!.id,
            'quantity': double.parse(row.quantity.value),
            'unit_type': row.unitType.value,
          };
        }).toList(),
      };

      final isEdit = receiveId != null;
      final url = isEdit
          ? '${ApiConfig.receives}/$receiveId'
          : ApiConfig.createReceive;

      final response = isEdit
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

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _showError(
          'Server error ${response.statusCode}. Ensure migrations are run.',
        );
        return;
      }

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        Get.back(result: true);
        _showSuccess(
          isEdit
              ? 'Receive updated'
              : saveStatus == 'DRAFT'
              ? 'Receive saved as draft'
              : 'Production receive recorded',
        );
      } else {
        final msg = data['message'] ?? 'Failed to save receive';
        final err = data['error'];
        final errs = data['errors'];
        final detail = err != null
            ? (err is String ? err : err.toString())
            : (errs != null ? errs.toString() : null);
        debugPrint('[RECEIVE] API error: $msg | $detail');
        _showError(detail != null ? '$msg: $detail' : msg);
      }
    } catch (e) {
      debugPrint('[RECEIVE] Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveDraft() => _saveReceive('DRAFT');

  Future<void> confirmReceive() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Receive'),
        content: const Text(
          'Are you sure you want to record these finished goods as received from production?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm Receive'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveReceive('RECEIVED');
  }
}

class ReceiveItemRow {
  final finishedProduct = Rxn<Product>();
  final quantity = ''.obs;
  final unitType = 'KG'.obs;
}

void _showSuccess(String message) {
  Get.snackbar(
    'Success',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.primary,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
  );
}

void _showError(String message) {
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
  );
}
