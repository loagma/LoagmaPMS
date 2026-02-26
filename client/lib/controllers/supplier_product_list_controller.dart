import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

class SupplierProductListController extends GetxController {
  final searchController = TextEditingController();
  final isLoading = false.obs;
  final supplierProducts = <SupplierProductItem>[].obs;

  /// When set, only products for this supplier are shown.
  final int? supplierId;
  final String? supplierName;

  SupplierProductListController({this.supplierId, this.supplierName});

  @override
  void onInit() {
    super.onInit();
    loadSupplierProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadSupplierProducts() async {
    try {
      isLoading.value = true;
      final queryParams = <String, String>{'limit': '200'};
      if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/supplier-products')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          supplierProducts.value = items
              .map(
                (e) => SupplierProductItem.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_LIST] Load error: $e');
      _showError('Failed to load supplier products');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchSupplierProducts(String query) async {
    if (query.length < 2) {
      await loadSupplierProducts();
      return;
    }

    try {
      isLoading.value = true;
      final queryParams = <String, String>{
        'search': query,
        'limit': '200',
      };
      if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/supplier-products')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          supplierProducts.value = items
              .map(
                (e) => SupplierProductItem.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_LIST] Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSupplierProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/supplier-products/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            data['message'] as String? ?? 'Supplier product removed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2),
          );
          await loadSupplierProducts();
        } else {
          _showError(data['message'] as String? ?? 'Failed to delete');
        }
      } else {
        _showError('Failed to delete supplier product');
      }
    } catch (e) {
      debugPrint('[SUPPLIER_PRODUCT_LIST] Delete error: $e');
      _showError('Failed to delete supplier product');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 3),
    );
  }
}

class SupplierProductItem {
  final int id;
  final int supplierId;
  final int productId;
  final String supplierName;
  final String? productName;
  final String? supplierSku;
  final String? supplierProductName;
  final String? description;
  final double? packSize;
  final String? packUnit;
  final double? minOrderQty;
  final double? price;
  final String? currency;
  final double? taxPercent;
  final double? discountPercent;
  final int? leadTimeDays;
  final bool isPreferred;
  final bool isActive;

  SupplierProductItem({
    required this.id,
    required this.supplierId,
    required this.productId,
    required this.supplierName,
    this.productName,
    this.supplierSku,
    this.supplierProductName,
    this.description,
    this.packSize,
    this.packUnit,
    this.minOrderQty,
    this.price,
    this.currency,
    this.taxPercent,
    this.discountPercent,
    this.leadTimeDays,
    required this.isPreferred,
    required this.isActive,
  });

  factory SupplierProductItem.fromJson(Map<String, dynamic> json) {
    return SupplierProductItem(
      id: json['id'] as int,
      supplierId: json['supplier_id'] as int,
      productId: json['product_id'] as int,
      supplierName: json['supplier_name'] as String? ?? 'Unknown',
      productName: json['product_name'] as String?,
      supplierSku: json['supplier_sku'] as String?,
      supplierProductName: json['supplier_product_name'] as String?,
      description: json['description'] as String?,
      packSize: json['pack_size'] != null
          ? double.tryParse(json['pack_size'].toString())
          : null,
      packUnit: json['pack_unit'] as String?,
      minOrderQty: json['min_order_qty'] != null
          ? double.tryParse(json['min_order_qty'].toString())
          : null,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      currency: json['currency'] as String?,
      taxPercent: json['tax_percent'] != null
          ? double.tryParse(json['tax_percent'].toString())
          : null,
      discountPercent: json['discount_percent'] != null
          ? double.tryParse(json['discount_percent'].toString())
          : null,
      leadTimeDays: json['lead_time_days'] as int?,
      isPreferred: json['is_preferred'] == 1 || json['is_preferred'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
