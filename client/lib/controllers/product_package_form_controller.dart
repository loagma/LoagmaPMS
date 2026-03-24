import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_package_model.dart';

class ProductPackageFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? packageId;
  final int? productId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final description = ''.obs;
  final packSize = ''.obs;
  final unit = 'KG'.obs;
  final marketPrice = ''.obs;
  final retailPrices = ''.obs;
  final productIdInput = ''.obs;

  ProductPackageFormController({
    this.productId,
    this.packageId,
  });

  bool get isEditMode => packageId != null;

  @override
  void onInit() {
    super.onInit();
    if (packageId != null) {
      _loadPackage();
    }
  }

  Future<void> _loadPackage() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.productPackages}/$packageId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final json = data['data'] as Map<String, dynamic>;
          final model = ProductPackage.fromJson(json);
          description.value = model.description;
          packSize.value = model.packSize.toString();
          unit.value = model.unit;
          marketPrice.value =
              (model.marketPrice ?? model.price)?.toString() ?? '';
          retailPrices.value = model.retailPrices ?? '';
        }
      }
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load package',
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
      final effectiveProductId = productId ?? int.tryParse(productIdInput.value.trim());
      if (effectiveProductId == null || effectiveProductId <= 0) {
        Get.snackbar(
          'Validation',
          'Enter a valid Product ID',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final payload = {
        'product_id': effectiveProductId,
        'description': description.value.trim(),
        'pack_size': double.parse(packSize.value.trim()),
        'unit': unit.value.trim(),
        'market_price': double.parse(marketPrice.value.trim()),
        'retail_prices': retailPrices.value.trim().isEmpty
            ? null
            : retailPrices.value.trim(),
      };

      final url = isEditMode
          ? '${ApiConfig.productPackages}/$packageId'
          : ApiConfig.productPackages;

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
          await Future.delayed(const Duration(milliseconds: 450));
          await Fluttertoast.showToast(
            msg: data['message']?.toString() ?? 'Package saved successfully',
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
        data['message']?.toString() ?? 'Failed to save package',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('[PACKAGE_FORM] Save error: $e');
      Get.snackbar(
        'Error',
        'Failed to save package: $e',
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

