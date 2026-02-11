import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../theme/app_colors.dart';

class BomController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? bomId; // null for create, non-null for edit

  final finishedProducts = <Map<String, dynamic>>[].obs;
  final rawMaterialProducts = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;

  final selectedFinishedProduct = Rxn<Map<String, dynamic>>();
  final bomVersion = ''.obs;
  final status = 'DRAFT'.obs;
  final remarks = ''.obs;

  final rawMaterials = <RawMaterialRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  BomController({this.bomId});

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _loadUnitTypes();

    // If editing, load BOM data
    if (bomId != null) {
      _loadBomData();
    }
  }

  Future<void> _loadBomData() async {
    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse('${ApiConfig.boms}/$bomId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final bomData = data['data'] as Map<String, dynamic>;
          final bom = bomData['bom'];
          final items = bomData['items'] as List;

          // Set BOM master data
          bomVersion.value = bom['bom_version']?.toString() ?? '';
          status.value = bom['status']?.toString() ?? 'DRAFT';
          remarks.value = bom['remarks']?.toString() ?? '';

          // Set finished product
          selectedFinishedProduct.value = {
            'product_id': bom['product_id'],
            'name': bom['product_name'],
          };

          // Set raw materials
          rawMaterials.clear();
          for (var item in items) {
            final row = RawMaterialRow();
            row.rawMaterial.value = {
              'product_id': item['raw_material_id'],
              'name': item['raw_material_name'],
            };
            row.quantityPerUnit.value =
                item['quantity_per_unit']?.toString() ?? '';
            row.unitType.value = item['unit_type']?.toString() ?? 'KG';
            row.wastagePercent.value =
                item['wastage_percent']?.toString() ?? '0';
            rawMaterials.add(row);
          }

          debugPrint('[BOM] ✅ Loaded BOM data for editing');
        }
      }
    } catch (e) {
      debugPrint('[BOM] ❌ Failed to load BOM data: $e');
      _showError('Failed to load BOM data');
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
          debugPrint('[BOM] ✅ Loaded ${unitTypes.length} unit types');
        }
      }
    } catch (e) {
      debugPrint('[BOM] ❌ Failed to load unit types: $e');
      unitTypes.value = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  Future<void> _loadProducts({String? search}) async {
    try {
      isLoading.value = true;

      var url = ApiConfig.products;
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}&limit=100';
      } else {
        url += '?limit=50';
      }

      debugPrint('[BOM] Fetching: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'API error');
      }

      final List products = data['data'] ?? [];
      final allProducts = products.cast<Map<String, dynamic>>();

      finishedProducts.value = allProducts;
      rawMaterialProducts.value = allProducts;

      debugPrint('[BOM] ✅ Loaded ${allProducts.length} products');
    } catch (e) {
      debugPrint('[BOM] ❌ Error: $e');
      _showError('Failed to load products');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length >= 2) {
      await _loadProducts(search: query);
    } else if (query.isEmpty) {
      await _loadProducts();
    }
  }

  void setFinishedProduct(Map<String, dynamic>? product) {
    selectedFinishedProduct.value = product;
  }

  void setBomVersion(String version) {
    bomVersion.value = version;
  }

  void setStatus(String newStatus) {
    status.value = newStatus;
  }

  void setRemarks(String text) {
    remarks.value = text;
  }

  void addRawMaterial() {
    rawMaterials.add(RawMaterialRow());
  }

  void removeRawMaterial(int index) {
    if (index >= 0 && index < rawMaterials.length) {
      rawMaterials.removeAt(index);
    }
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (selectedFinishedProduct.value == null) {
      _showError('Please select a finished product');
      return false;
    }

    if (bomVersion.value.trim().isEmpty) {
      _showError('Please enter BOM version');
      return false;
    }

    if (rawMaterials.isEmpty) {
      _showError('Please add at least one raw material');
      return false;
    }

    return true;
  }

  Future<void> _saveBom(String saveStatus) async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      final bomData = {
        'product_id': selectedFinishedProduct.value!['product_id'],
        'bom_version': bomVersion.value.trim(),
        'status': saveStatus,
        'remarks': remarks.value.trim(),
        'raw_materials': rawMaterials.map((row) {
          return {
            'raw_material_id': row.rawMaterial.value!['product_id'],
            'quantity_per_unit': double.parse(row.quantityPerUnit.value),
            'unit_type': row.unitType.value,
            'wastage_percent': double.tryParse(row.wastagePercent.value) ?? 0,
          };
        }).toList(),
      };

      final isEdit = bomId != null;
      final url = isEdit ? '${ApiConfig.boms}/$bomId' : ApiConfig.createBom;

      debugPrint(
        '[BOM] ${isEdit ? 'Updating' : 'Saving'}: ${jsonEncode(bomData)}',
      );

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(bomData),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(bomData),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        final message = isEdit
            ? 'BOM updated successfully'
            : (saveStatus == 'DRAFT'
                  ? 'BOM saved as draft'
                  : 'BOM approved successfully');
        _showSuccess(message);
        debugPrint('[BOM] ✅ Success: ${data['data']}');

        await Future.delayed(const Duration(seconds: 1));
        Get.back(result: true);
      } else {
        throw Exception(data['message'] ?? 'Failed to save BOM');
      }
    } catch (e) {
      debugPrint('[BOM] ❌ Save failed: $e');
      _showError('Failed to save BOM: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveAsDraft() async {
    await _saveBom('DRAFT');
  }

  Future<void> approveBom() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Approve BOM'),
        content: const Text('Are you sure you want to approve this BOM?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _saveBom('APPROVED');
  }

  bool get isEditMode => bomId != null;
  bool get isLocked => status.value == 'LOCKED';
  bool get isReadOnly => isLocked;
}

class RawMaterialRow {
  final rawMaterial = Rxn<Map<String, dynamic>>();
  final quantityPerUnit = ''.obs;
  final unitType = 'KG'.obs;
  final wastagePercent = '0'.obs;
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
