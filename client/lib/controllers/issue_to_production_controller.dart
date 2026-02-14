import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class IssueToProductionController extends GetxController {
  // Form state
  final formKey = GlobalKey<FormState>();
  final int? issueId; // null for create, non-null for edit

  // Header fields
  final remarks = ''.obs;

  // Materials to issue
  final materials = <IssueMaterialRow>[].obs;

  // Products data
  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  IssueToProductionController({this.issueId});

  @override
  void onInit() {
    super.onInit();
    _loadUnitTypes();
    // Load products first; when editing, load issue data after so we can match stock
    _loadProducts().then((_) {
      if (issueId != null) {
        _loadIssueData();
      }
    });
    if (issueId == null) {
      // Create mode: products loading is enough
    }
  }

  Future<void> _loadIssueData() async {
    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse('${ApiConfig.issues}/$issueId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final issueData = data['data'] as Map<String, dynamic>;
          final issue = issueData['issue'];
          final items = issueData['items'] as List;

          // Set issue master data
          remarks.value = issue['remarks']?.toString() ?? '';

          // Set materials - prefer product from products list (has stock) if available
          materials.clear();
          for (var item in items) {
            final row = IssueMaterialRow();
            final productId = item['raw_material_id'] as int?;
            final productFromList = products
                .where((p) => p.id == productId)
                .firstOrNull;
            row.rawMaterial.value = productFromList ??
                Product(
                  id: productId ?? 0,
                  name: item['raw_material_name']?.toString() ?? '',
                  productType: 'RAW',
                );
            row.quantity.value = item['quantity']?.toString() ?? '';
            row.unitType.value = item['unit_type']?.toString() ?? 'KG';
            materials.add(row);
          }

          debugPrint('[ISSUE] ✅ Loaded issue data for editing');
        }
      }
    } catch (e) {
      debugPrint('[ISSUE] ❌ Failed to load issue data: $e');
      _showError('Failed to load issue data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;

      final uri = Uri.parse('${ApiConfig.products}?limit=50&include_stock=1');
      debugPrint('[ISSUE] GET $uri');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      debugPrint('[ISSUE] Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        _showError('Failed to load products (${response.statusCode})');
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'API error');
      }

      final List data = decoded['data'] ?? [];
      debugPrint('[ISSUE] Total products received: ${data.length}');

      final list = data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      products.value = list;
    } catch (e, st) {
      debugPrint('[ISSUE] Unexpected error while loading products: $e');
      debugPrint('$st');
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
      debugPrint('[ISSUE] Unit types fallback: $e');
      unitTypes.value = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length < 2) return;

    try {
      final url =
          '${ApiConfig.products}?search=${Uri.encodeComponent(query)}&limit=100&include_stock=1';
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          final list = data
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
          products.value = list;
          debugPrint('[ISSUE] ✅ Search found ${list.length} products');
        }
      }
    } catch (e) {
      debugPrint('[ISSUE] ❌ Search error: $e');
    }
  }

  void setRemarks(String value) {
    remarks.value = value;
  }

  void addMaterialRow() {
    materials.add(IssueMaterialRow());
  }

  void removeMaterialRow(int index) {
    if (index >= 0 && index < materials.length) {
      materials.removeAt(index);
    }
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (materials.isEmpty) {
      _showError('Please add at least one material to issue');
      return false;
    }

    return true;
  }

  Future<void> _saveIssue(String saveStatus) async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      final issueData = {
        'status': saveStatus,
        'remarks': remarks.value.trim(),
        'materials': materials.map((row) {
          return {
            'raw_material_id': row.rawMaterial.value!.id,
            'quantity': double.parse(row.quantity.value),
            'unit_type': row.unitType.value,
          };
        }).toList(),
      };

      final isEdit = issueId != null;
      final url = isEdit
          ? '${ApiConfig.issues}/$issueId'
          : ApiConfig.createIssue;

      debugPrint(
        '[ISSUE] ${isEdit ? 'Updating' : 'Creating'}: ${jsonEncode(issueData)}',
      );

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(issueData),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(issueData),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        final message = isEdit
            ? 'Issue updated successfully'
            : (saveStatus == 'DRAFT'
                  ? 'Issue saved as draft'
                  : 'Materials issued successfully');
        debugPrint('[ISSUE] ✅ Success: ${data['data']}');
        Get.back(result: true);
        _showSuccess(message);
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        String? errMsg = data['message']?.toString();
        if (errors != null && errors.isNotEmpty) {
          final firstValue = errors.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            errMsg = firstValue.first.toString();
          } else if (firstValue is String) {
            errMsg = firstValue;
          }
        }
        throw Exception(errMsg ?? 'Failed to save issue');
      }
    } catch (e) {
      debugPrint('[ISSUE] ❌ Save failed: $e');
      _showError('Failed to save issue: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveDraft() async {
    await _saveIssue('DRAFT');
  }

  Future<void> confirmIssue() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Issue Materials'),
        content: const Text(
          'Are you sure you want to issue these materials to production?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Issue Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _saveIssue('ISSUED');
  }

  bool get isEditMode => issueId != null;
}

class IssueMaterialRow {
  final rawMaterial = Rxn<Product>();
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
