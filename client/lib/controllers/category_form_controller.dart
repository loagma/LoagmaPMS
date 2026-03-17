import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
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
  final addSubcategoryNow = false.obs;
  final subcategoryName = ''.obs;

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
          if (!isEditMode &&
              !isSubcategoryForm &&
              addSubcategoryNow.value &&
              subcategoryName.value.trim().isNotEmpty) {
            final createdCategoryId = _extractCategoryId(data['data']);
            if (createdCategoryId != null && createdCategoryId > 0) {
              final subcategorySaved = await _createSubcategory(
                parentCategoryId: createdCategoryId,
                subcategoryNameText: subcategoryName.value.trim(),
                isSubcategoryActive: isActive.value,
              );

              if (!subcategorySaved) {
                Get.snackbar(
                  'Partial Success',
                  'Category saved, but subcategory could not be saved.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return true;
              }

              _showSuccessToast('Category and subcategory saved successfully');
              return true;
            }
          }

          _showSuccessToast(
            data['message']?.toString() ?? 'Category saved successfully',
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

  int? _extractCategoryId(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final rawId = data['cat_id'];
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  Future<bool> _createSubcategory({
    required int parentCategoryId,
    required String subcategoryNameText,
    required bool isSubcategoryActive,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.categories),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': subcategoryNameText,
          'parent_cat_id': parentCategoryId,
          'is_active': isSubcategoryActive,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('[CATEGORY_FORM] Save subcategory error: $e');
      return false;
    }
  }

  Future<void> _showSuccessToast(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 14,
    );
  }
}
