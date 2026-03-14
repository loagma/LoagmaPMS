import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/category_model.dart';

class CategoryFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? categoryId;
  final int? parentCatId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final name = ''.obs;
  final selectedParentCatId = 0.obs;
  final isActive = true.obs;

  final parentCategories = <Category>[].obs;

  CategoryFormController({this.categoryId, this.parentCatId});

  bool get isEditMode => categoryId != null;

  bool get isSubcategoryForm =>
      !isEditMode ? (parentCatId != null && parentCatId != 0) : !currentCategory.isTopLevel;

  Category? _currentCategory;

  Category get currentCategory =>
      _currentCategory ?? Category(catId: 0, name: '', parentCatId: 0, isActive: true, type: 0, imgLastUpdated: 0);

  @override
  void onInit() {
    super.onInit();
    if (categoryId != null) {
      _loadCategory();
    } else {
      selectedParentCatId.value = parentCatId ?? 0;
    }
  }

  Future<void> _loadCategory() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.categories}/$categoryId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final json = data['data'] as Map<String, dynamic>;
          _currentCategory = Category.fromJson(json);
          name.value = _currentCategory!.name;
          selectedParentCatId.value = _currentCategory!.parentCatId;
          isActive.value = _currentCategory!.isActive;
          if (!_currentCategory!.isTopLevel) {
            await _loadParentCategories();
          }
        }
      }
    } catch (e) {
      debugPrint('[CATEGORY_FORM] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load category',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadParentCategories() async {
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
          parentCategories.value = list
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[CATEGORY_FORM] Load parents error: $e');
    }
  }

  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;

    isSaving.value = true;
    try {
      final int parentId = isEditMode ? selectedParentCatId.value : (parentCatId ?? selectedParentCatId.value);
      final payload = {
        'name': name.value.trim(),
        'parent_cat_id': parentId,
        'is_active': isActive.value,
      };

      final url = isEditMode
          ? '${ApiConfig.categories}/$categoryId'
          : ApiConfig.categories;

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
            data['message']?.toString() ?? 'Category saved successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return true;
        }
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to save category',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[CATEGORY_FORM] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to save category: $e',
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
