import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class StockVoucherController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? voucherId;

  final voucherType = 'IN'.obs;
  final voucherDate = ''.obs;
  final items = <StockVoucherItemRow>[].obs;
  final remarks = ''.obs;

  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  StockVoucherController({this.voucherId});

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _loadUnitTypes();
    if (voucherId == null) {
      voucherDate.value = _formatDate(DateTime.now());
      // Create mode: add one empty row by default
      addItemRow();
    }
    if (voucherId != null) {
      _loadVoucherData();
    }
  }

  bool get isEditMode => voucherId != null;

  Future<void> _loadVoucherData() async {
    if (voucherId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.stockVouchers}/$voucherId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final vData = data['data'] as Map<String, dynamic>;
          final voucher = vData['voucher'];
          voucherType.value = voucher['voucher_type'] ?? 'IN';
          voucherDate.value =
              voucher['voucher_date']?.toString().split(' ').first ??
              _formatDate(DateTime.now());
          remarks.value = voucher['remarks']?.toString() ?? '';
          final itemsData = vData['items'] as List? ?? [];
          items.clear();
          for (var item in itemsData) {
            final row = StockVoucherItemRow();
            row.product.value = Product(
              id: item['product_id'],
              name: item['product_name'] ?? '',
              productType: 'SINGLE',
            );
            row.quantity.value = item['quantity']?.toString() ?? '';
            row.unitType.value = item['unit_type']?.toString() ?? 'KG';
            items.add(row);
          }
        }
      }
    } catch (e) {
      debugPrint('[STOCK_VOUCHER] Load failed: $e');
      _showError('Failed to load voucher data');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?limit=50'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        _showError('Failed to load products (${response.statusCode})');
        return;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == false) throw Exception(decoded['message']);
      final List data = decoded['data'] ?? [];
      products.value = data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STOCK_VOUCHER] Products error: $e');
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
      unitTypes.value = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.length < 2) {
      await _loadProducts();
      return;
    }
    try {
      final url =
          '${ApiConfig.products}?search=${Uri.encodeComponent(query)}&limit=100';
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          products.value = data
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[STOCK_VOUCHER] Search error: $e');
    }
  }

  void setVoucherType(String v) => voucherType.value = v;
  void setVoucherDate(String v) => voucherDate.value = v;
  void setRemarks(String v) => remarks.value = v;

  void addItemRow() => items.add(StockVoucherItemRow());

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  List<Product> getProductsExcluding(Iterable<int> excludeIds) =>
      products.where((p) => !excludeIds.contains(p.id)).toList();

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (items.isEmpty) {
      _showError('Please add at least one item');
      return false;
    }
    for (var row in items) {
      if (row.product.value == null) {
        _showError('Please select product for all items');
        return false;
      }
      final qty = double.tryParse(row.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Please enter valid quantity for all items');
        return false;
      }
    }
    return true;
  }

  Future<void> _saveVoucher(String saveStatus) async {
    if (!_validateForm()) return;

    isSaving.value = true;
    try {
      final payload = {
        'voucher_type': voucherType.value,
        'status': saveStatus,
        'voucher_date': voucherDate.value.trim().isEmpty
            ? _formatDate(DateTime.now())
            : voucherDate.value,
        'remarks': remarks.value.trim(),
        'items': items.map((row) {
          return {
            'product_id': row.product.value!.id,
            'quantity': double.parse(row.quantity.value),
            'unit_type': row.unitType.value,
          };
        }).toList(),
      };

      final isEdit = voucherId != null;
      final url = isEdit
          ? '${ApiConfig.stockVouchers}/$voucherId'
          : ApiConfig.createStockVoucher;

      final response = isEdit
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

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _showError(
          'Server error ${response.statusCode}. Ensure migrations are run.',
        );
        return;
      }

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        Get.back(result: true);
        _showSuccess(
          isEdit
              ? 'Voucher updated'
              : saveStatus == 'DRAFT'
              ? 'Voucher saved as draft'
              : 'Stock voucher posted',
        );
      } else {
        final msg = data['message'] ?? 'Failed to save voucher';
        final err = data['error'];
        final errs = data['errors'];
        final detail = err != null
            ? (err is String ? err : err.toString())
            : (errs != null ? errs.toString() : null);
        _showError(detail != null ? '$msg: $detail' : msg);
      }
    } catch (e) {
      debugPrint('[STOCK_VOUCHER] Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveDraft() => _saveVoucher('DRAFT');

  Future<void> confirmPost() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Post Voucher'),
        content: Text(
          'Are you sure you want to post this stock ${voucherType.value == 'IN' ? 'in' : 'out'} voucher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveVoucher('POSTED');
  }
}

class StockVoucherItemRow {
  final product = Rxn<Product>();
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
