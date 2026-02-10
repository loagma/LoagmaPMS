import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/bom_model.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class BomController extends GetxController {
  // Form state
  final formKey = GlobalKey<FormState>();

  // BOM Header fields
  final finishedProduct = Rxn<Product>();
  final bomVersion = ''.obs;
  final status = 'DRAFT'.obs;
  final remarks = ''.obs;

  // Raw materials list
  final rawMaterials = <BomItemRow>[].obs;

  // Products data (would come from API)
  final finishedProducts = <Product>[].obs;
  final rawMaterialProducts = <Product>[].obs;

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
  }

  // TODO: Replace with actual API call
  void _loadProducts() {
    // Mock data - replace with API call
    finishedProducts.value = [
      Product(id: 1, name: '15kg tin', productType: 'FINISHED'),
      Product(id: 2, name: '4*5 litre ', productType: 'FINISHED'),
    ];
    rawMaterialProducts.value = [
      Product(id: 101, name: 'Empty tin', productType: 'RAW', defaultUnit: 'KG'),
      Product(id: 102, name: 'Empty jar', productType: 'RAW', defaultUnit: 'KG'),
      Product(id: 103, name: 'Empty carton', productType: 'RAW', defaultUnit: 'KG'),
      Product(id: 104, name: 'Oil', productType: 'RAW', defaultUnit: 'KG'),
      Product(id: 105, name: 'Cap', productType: 'RAW', defaultUnit: 'PCS'),
      Product(id: 106, name: '5 litre Label', productType: 'RAW', defaultUnit: 'PCS'),
      Product(id: 107, name: '15 kg Label', productType: 'RAW', defaultUnit: 'PCS'),

    ];
  }

  void setFinishedProduct(Product? product) {
    finishedProduct.value = product;
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
    rawMaterials.add(BomItemRow());
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

    // Check if finished product is selected
    if (finishedProduct.value == null) {
      _showError('Please select a finished product');
      return false;
    }

    // Check if BOM version is filled
    if (bomVersion.value.trim().isEmpty) {
      _showError('Please enter BOM version');
      return false;
    }

    // Check if at least one raw material is added
    if (rawMaterials.isEmpty) {
      _showError('Please add at least one raw material');
      return false;
    }

    // Check for duplicate raw materials
    final materialIds = rawMaterials
        .where((row) => row.rawMaterial.value != null)
        .map((row) => row.rawMaterial.value!.id)
        .toList();
    if (materialIds.length != materialIds.toSet().length) {
      _showError('Duplicate raw materials are not allowed');
      return false;
    }

    // Check if finished product is not in raw materials
    if (finishedProduct.value != null) {
      final finishedProductId = finishedProduct.value!.id;
      if (materialIds.contains(finishedProductId)) {
        _showError('Finished product cannot be added as raw material');
        return false;
      }
    }

    return true;
  }

  Future<void> saveAsDraft() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      status.value = 'DRAFT';
      // await _saveBom();

      _showSuccess('BOM saved as draft');
    } catch (e) {
      _showError('Failed to save BOM: $e');
    } finally {
      isSaving.value = false;
    }
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

    if (!validateForm()) return;

    isSaving.value = true;
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      status.value = 'APPROVED';
      // await _saveBom();

      _showSuccess('BOM approved successfully');
    } catch (e) {
      _showError('Failed to approve BOM: $e');
    } finally {
      isSaving.value = false;
    }
  }

  bool get isLocked => status.value == 'LOCKED';
  bool get isReadOnly => isLocked;
}

// Helper class for managing raw material rows in the UI
class BomItemRow {
  final rawMaterial = Rxn<Product>();
  final quantityPerUnit = ''.obs;
  final unitType = 'KG'.obs;
  final wastagePercent = '0'.obs;

  BomItemRow();

  BomItem toBomItem() {
    return BomItem(
      rawMaterialId: rawMaterial.value!.id,
      quantityPerUnit: double.parse(quantityPerUnit.value),
      unitType: unitType.value,
      wastagePercent: double.tryParse(wastagePercent.value) ?? 0.0,
    );
  }
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
    'Validation Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.textDark,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
  );
}
