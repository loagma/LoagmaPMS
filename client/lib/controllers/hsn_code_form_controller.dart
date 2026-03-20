import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/hsn_code_model.dart';

class HsnCodeFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? hsnId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final code = ''.obs;
  final isActive = true.obs;

  HsnCodeFormController({this.hsnId});

  bool get isEditMode => hsnId != null;

  @override
  void onInit() {
    super.onInit();
    if (hsnId != null) {
      _loadCode();
    }
  }

  Future<void> _loadCode() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.hsnCodes}/$hsnId/edit'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final json = data['data'] as Map<String, dynamic>;
          final model = HsnCode.fromJson(json);
          code.value = model.code;
          isActive.value = model.isActive;
        }
      }
    } catch (e) {
      debugPrint('[HSN_FORM] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load HSN code',
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
        'hsn_code': code.value.trim(),
        'is_active': isActive.value,
      };

      final url =
          isEditMode ? '${ApiConfig.hsnCodes}/$hsnId' : ApiConfig.hsnCodes;

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
            data['message']?.toString() ?? 'HSN code saved successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return true;
        }
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to save HSN code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[HSN_FORM] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to save HSN code: $e',
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

