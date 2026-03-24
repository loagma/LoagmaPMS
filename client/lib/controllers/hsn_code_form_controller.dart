import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/hsn_code_model.dart';

class HsnCodeFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? hsnId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final previewId = RxnInt();
  final code = ''.obs;
  final isActive = true.obs;

  HsnCodeFormController({this.hsnId});

  bool get isEditMode => hsnId != null;

  @override
  void onInit() {
    super.onInit();
    if (hsnId != null) {
      previewId.value = hsnId;
      _loadCode();
    } else {
      _loadNextIdPreview();
    }
  }

  Future<void> _loadNextIdPreview() async {
    try {
      final uri = Uri.parse(ApiConfig.hsnCodes).replace(
        queryParameters: const {
          'include_next_id': '1',
          'limit': '1',
        },
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;

      final meta = data['meta'];
      if (meta is Map<String, dynamic>) {
        final rawNextId = meta['next_id'];
        final nextId = int.tryParse(rawNextId?.toString() ?? '');
        if (nextId != null) {
          previewId.value = nextId;
        }
      }
    } catch (e) {
      debugPrint('[HSN_FORM] Next ID preview error: $e');
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
          previewId.value = model.id;
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
          final message =
              data['message']?.toString() ?? 'HSN code saved successfully';
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

