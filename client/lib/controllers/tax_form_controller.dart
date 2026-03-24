import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../constants/tax_constants.dart';
import '../models/tax_model.dart';

class TaxFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? taxId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final taxCategory = ''.obs;
  final taxSubCategory = ''.obs;
  final taxName = ''.obs;
  final isActive = true.obs;

  TaxFormController({this.taxId});

  bool get isEditMode => taxId != null;

  /// Subcategories for the currently selected category.
  /// Returns placeholder list when category has no subcategories.
  List<String> get subCategoryOptions {
    final subs = taxSubCategoriesByCategory[taxCategory.value];
    if (subs == null || subs.isEmpty) {
      return ['—']; // placeholder when no subcategory
    }
    return subs;
  }

  void onCategoryChanged(String? value) {
    if (value == null) return;
    taxCategory.value = value;
    final subs = taxSubCategoriesByCategory[value] ?? [];
    if (subs.isEmpty) {
      taxSubCategory.value = '—';
    } else if (!subs.contains(taxSubCategory.value)) {
      taxSubCategory.value = subs.first;
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (taxId != null) {
      _loadTax();
    } else {
      taxSubCategory.value = '—';
    }
  }

  Future<void> _loadTax() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.taxes}/$taxId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final tax = Tax.fromJson(data['data'] as Map<String, dynamic>);
          taxCategory.value = tax.taxCategory;
          taxSubCategory.value = tax.taxSubCategory;
          taxName.value = tax.taxName;
          isActive.value = tax.isActive;
        }
      }
    } catch (e) {
      debugPrint('[TAX_FORM] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load tax details',
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

    isSaving.value = true;
    try {
      final payload = {
        'tax_category': taxCategory.value.trim(),
        'tax_sub_category': taxSubCategory.value.trim(),
        'tax_name': taxName.value.trim(),
        'is_active': isActive.value,
      };

      final url = isEditMode ? '${ApiConfig.taxes}/$taxId' : ApiConfig.taxes;
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
          final message = data['message']?.toString() ?? 'Tax saved successfully';
          await Future.delayed(const Duration(milliseconds: 450));
          await Fluttertoast.showToast(
            msg: message,
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
        data['message']?.toString() ?? 'Failed to save tax',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[TAX_FORM] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to save tax: $e',
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
