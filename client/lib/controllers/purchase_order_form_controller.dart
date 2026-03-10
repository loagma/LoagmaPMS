import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_order_model.dart';
import '../theme/app_colors.dart';

class PurchaseOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? poId;
  final bool startInViewOnly;

  final suppliers = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;

  final financialYear = '25-26'.obs;
  final supplierId = Rxn<int>();
  final docDate = ''.obs;
  final expectedDate = ''.obs;
  final status = 'DRAFT'.obs;
  final narration = ''.obs;

  final items = <POLineRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  PurchaseOrderFormController({this.poId, this.startInViewOnly = false});

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    _loadSuppliers();
    _loadUnitTypes();
    if (poId != null) {
      _loadPurchaseOrder();
    } else {
      _setDefaultDocDate();
      addItem();
    }
  }

  /// Search all products via /products (no supplier filter).
  Future<List<Map<String, dynamic>>> _searchAllProducts(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.products).replace(
        queryParameters: {
          'limit': '50',
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .map((e) => {
                'product_id': (e as Map)['product_id'] ?? (e)['id'],
                'name': (e)['name']?.toString() ??
                    (e)['product_name']?.toString() ??
                    '',
              })
          .toList();
    } catch (e) {
      debugPrint('[PO FORM] Search products error: $e');
      return [];
    }
  }

  /// Supplier-aware product search.
  /// If a supplier is selected and [includeAll] is false, we hit /supplier-products
  /// so that only products assigned to that supplier are returned.
  /// Otherwise we fall back to the generic /products search.
  Future<List<Map<String, dynamic>>> searchProductsForSupplier(
    String query, {
    bool includeAll = false,
  }) async {
    final supplier = supplierId.value;
    if (!includeAll && supplier != null) {
      try {
        final uri = Uri.parse(ApiConfig.supplierProducts).replace(
          queryParameters: {
            'limit': '50',
            'supplier_id': supplier.toString(),
            if (query.trim().isNotEmpty) 'search': query.trim(),
          },
        );
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return [];
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return [];
        final List list = data['data'] ?? [];
        return list.map((e) {
          final map = e as Map<String, dynamic>;
          final product = map['product'] as Map<String, dynamic>?;
          final rawId =
              map['product_id'] ?? product?['product_id'] ?? product?['id'];
          final name = product?['name']?.toString() ??
              map['product_name']?.toString() ??
              map['supplier_product_name']?.toString() ??
              'Product ${rawId ?? ''}';
          return {
            'product_id': rawId,
            'name': name,
          };
        }).toList();
      } catch (e) {
        debugPrint('[PO FORM] Supplier search error: $e');
        // fall through to all-products search
      }
    }
    return _searchAllProducts(query);
  }

  /// Backwards-compatible wrapper for existing callers that always want all products.
  Future<List<Map<String, dynamic>>> searchProducts(String query) =>
      _searchAllProducts(query);

  /// Fetches product taxes for a product and applies them to the given row.
  /// Maps tax_name/tax_sub_category to sgst, cgst, igst, cess, roff.
  /// Sets taxPercent to the sum of all tax percentages for API compatibility.
  Future<void> applyProductTaxesToRow(POLineRow row, int productId) async {
    try {
      final uri = Uri.parse(ApiConfig.productTaxes).replace(
        queryParameters: {'product_id': productId.toString(), 'limit': '50'},
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final List list = data['data'] ?? [];
      double totalPercent = 0;
      for (final e in list) {
        final map = e as Map<String, dynamic>;
        final tax = map['tax'] as Map<String, dynamic>?;
        final taxName = (tax?['tax_name'] ?? tax?['tax_sub_category'] ?? '')
            .toString()
            .toUpperCase();
        final taxSub = (tax?['tax_sub_category'] ?? '')
            .toString()
            .toUpperCase();
        final percent = (map['tax_percent'] ?? 0) is num
            ? (map['tax_percent'] as num).toDouble()
            : double.tryParse(map['tax_percent']?.toString() ?? '') ?? 0;
        totalPercent += percent;
        if (_matchesTax(taxName, taxSub, 'SGST')) {
          row.sgst.value = percent.toStringAsFixed(2);
        } else if (_matchesTax(taxName, taxSub, 'CGST')) {
          row.cgst.value = percent.toStringAsFixed(2);
        } else if (_matchesTax(taxName, taxSub, 'IGST')) {
          row.igst.value = percent.toStringAsFixed(2);
        } else if (_matchesTax(taxName, taxSub, 'CESS')) {
          row.cess.value = percent.toStringAsFixed(2);
        } else if (_matchesTax(taxName, taxSub, 'ROFF') ||
            taxName.contains('ROUND')) {
          row.roff.value = percent.toStringAsFixed(2);
        }
      }
      if (totalPercent > 0) {
        row.taxPercent.value = totalPercent.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('[PO FORM] Fetch product taxes error: $e');
    }
  }

  bool _matchesTax(String taxName, String taxSub, String key) {
    return taxName.contains(key) || taxSub.contains(key);
  }

  void _setDefaultDocDate() {
    final now = DateTime.now();
    docDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.suppliers),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          suppliers.value = list
              .map((e) => {
                    'id': (e as Map)['id'],
                    'supplier_code': (e)['supplier_code']?.toString(),
                    'supplier_name': (e)['supplier_name']?.toString() ?? (e)['name']?.toString(),
                  })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PO FORM] Load suppliers error: $e');
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

  Future<void> _loadPurchaseOrder() async {
    if (poId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseOrders}/$poId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final poData = data['data'] as Map<String, dynamic>;
          final po = PurchaseOrder.fromJson(poData);
          financialYear.value = po.financialYear ?? '25-26';
          supplierId.value = po.supplierId;
          docDate.value = po.docDate;
          expectedDate.value = po.expectedDate ?? '';
          status.value = po.status;
          narration.value = po.narration ?? '';
          items.clear();
          for (final item in po.items) {
            items.add(POLineRow(
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity.toString(),
              price: item.price.toString(),
              discountPercent: item.discountPercent?.toString() ?? '',
              taxPercent: item.taxPercent?.toString() ?? '',
              unit: item.unit ?? '',
              description: item.description ?? '',
            ));
          }
          if (items.isEmpty) items.add(POLineRow());
        }
      }
    } catch (e) {
      debugPrint('[PO FORM] Load PO error: $e');
      _showError('Failed to load purchase order');
    } finally {
      isLoading.value = false;
    }
  }

  void setFinancialYear(String v) => financialYear.value = v;
  void setSupplierId(int? v) => supplierId.value = v;
  void setDocDate(String v) => docDate.value = v;
  void setExpectedDate(String v) => expectedDate.value = v;
  void setStatus(String v) => status.value = v;
  void setNarration(String v) => narration.value = v;

  void addItem() {
    final row = POLineRow();
    if (unitTypes.isNotEmpty && row.unit.value.isEmpty) {
      row.unit.value = unitTypes.first;
    }
    items.add(row);
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  bool get isEditMode => poId != null;
  bool get isReadOnly => viewOnly.value || status.value != 'DRAFT';

  bool validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (supplierId.value == null) {
      _showError('Please select a supplier');
      return false;
    }
    if (docDate.value.trim().isEmpty) {
      _showError('Please enter document date');
      return false;
    }
    final validItems = items.where((r) => r.productId.value != null).toList();
    if (validItems.isEmpty) {
      _showError('Please add at least one line item');
      return false;
    }
    for (final r in validItems) {
      final qty = double.tryParse(r.quantity.value);
      if (qty == null || qty <= 0) {
        _showError('Quantity must be greater than 0 for all lines');
        return false;
      }
      final price = double.tryParse(r.price.value);
      if (price == null || price < 0) {
        _showError('Price must be >= 0 for all lines');
        return false;
      }
    }
    return true;
  }

  Future<void> save() async {
    if (!validateForm()) return;

    isSaving.value = true;
    try {
      final validItems = items
          .where((r) => r.productId.value != null && r.quantity.value.trim().isNotEmpty)
          .toList();
      if (validItems.isEmpty) {
        _showError('Please add at least one line item');
        isSaving.value = false;
        return;
      }

      final payload = {
        'financial_year': financialYear.value,
        'supplier_id': supplierId.value,
        'doc_date': docDate.value,
        if (expectedDate.value.trim().isNotEmpty) 'expected_date': expectedDate.value.trim(),
        'status': status.value,
        if (narration.value.trim().isNotEmpty) 'narration': narration.value.trim(),
        'items': validItems.asMap().entries.map((e) {
          final r = e.value;
          final productId = r.productId.value!;
          final qty = double.tryParse(r.quantity.value) ?? 0;
          final price = double.tryParse(r.price.value) ?? 0;
          final discount = double.tryParse(r.discountPercent.value);
          final sgst = double.tryParse(r.sgst.value) ?? 0;
          final cgst = double.tryParse(r.cgst.value) ?? 0;
          final igst = double.tryParse(r.igst.value) ?? 0;
          final cess = double.tryParse(r.cess.value) ?? 0;
          final roff = double.tryParse(r.roff.value) ?? 0;
          final taxFromBreakdown = sgst + cgst + igst + cess + roff;
          final tax = taxFromBreakdown > 0
              ? taxFromBreakdown
              : (double.tryParse(r.taxPercent.value));
          return {
            'product_id': productId,
            'line_no': e.key + 1,
            if (r.unit.value.trim().isNotEmpty) 'unit': r.unit.value.trim(),
            'quantity': qty,
            'price': price,
            if (discount != null && discount > 0) 'discount_percent': discount,
            if (tax != null && tax > 0) 'tax_percent': tax,
            if (r.description.value.trim().isNotEmpty) 'description': r.description.value.trim(),
          };
        }).toList(),
      };

      final isCreate = poId == null;
      final url = isCreate
          ? ApiConfig.purchaseOrders
          : '${ApiConfig.purchaseOrders}/$poId';

      final response = isCreate
          ? await http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        _showSuccess(isCreate ? 'Purchase order created' : 'Purchase order updated');
        Get.back(result: true);
      } else {
        _showError(data['message']?.toString() ?? 'Failed to save');
      }
    } catch (e) {
      debugPrint('[PO FORM] Save error: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }
}

class POLineRow {
  final productId = Rxn<int>();
  final productName = ''.obs;
  final quantity = '1'.obs;
  final price = '0'.obs;
  final discountPercent = ''.obs;
  final taxPercent = ''.obs;
  // Whether the entered unit price is inclusive of tax (true) or exclusive (false).
  final isInclusiveTax = false.obs;
  // Detailed tax breakdown (frontend only for now, default 0).
  final sgst = '0'.obs;
  final cgst = '0'.obs;
  final igst = '0'.obs;
  final cess = '0'.obs;
  final roff = '0'.obs;
  final unit = 'PCS'.obs;
  final description = ''.obs;

  POLineRow({
    int? productId,
    String? productName,
    String? quantity,
    String? price,
    String? discountPercent,
    String? taxPercent,
    String? unit,
    String? description,
  }) {
    if (productId != null) this.productId.value = productId;
    if (productName != null) this.productName.value = productName;
    if (quantity != null) this.quantity.value = quantity;
    if (price != null) this.price.value = price;
    if (discountPercent != null) this.discountPercent.value = discountPercent;
    if (taxPercent != null) this.taxPercent.value = taxPercent;
    if (unit != null) this.unit.value = unit;
    if (description != null) this.description.value = description;
  }

  /// Price excluding tax (stored).
  double get priceExclTax => double.tryParse(price.value) ?? 0;

  /// Total tax percent from breakdown (sgst+cgst+igst+cess+roff) or taxPercent.
  double get _effectiveTaxPercent {
    final sgst = double.tryParse(this.sgst.value) ?? 0;
    final cgst = double.tryParse(this.cgst.value) ?? 0;
    final igst = double.tryParse(this.igst.value) ?? 0;
    final cess = double.tryParse(this.cess.value) ?? 0;
    final roff = double.tryParse(this.roff.value) ?? 0;
    final fromBreakdown = sgst + cgst + igst + cess + roff;
    if (fromBreakdown > 0) return fromBreakdown;
    return double.tryParse(taxPercent.value) ?? 0;
  }

  /// Price including tax (computed).
  double get priceInclTax {
    final raw = double.tryParse(price.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) {
      return raw;
    }
    return raw * (1 + t / 100);
  }

  /// Line total excluding tax.
  double get lineTotalExclTax {
    final qty = double.tryParse(quantity.value) ?? 0;
    final p = isInclusiveTax.value
        ? _priceExclFromInclusive()
        : (double.tryParse(price.value) ?? 0);
    final d = double.tryParse(discountPercent.value) ?? 0;
    return qty * p * (1 - d / 100);
  }

  /// Line total including tax.
  double get lineTotal {
    final qty = double.tryParse(quantity.value) ?? 0;
    final pExcl = isInclusiveTax.value
        ? _priceExclFromInclusive()
        : (double.tryParse(price.value) ?? 0);
    final d = double.tryParse(discountPercent.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (isInclusiveTax.value) {
      final pIncl = double.tryParse(price.value) ?? 0;
      return qty * pIncl * (1 - d / 100);
    }
    return qty * pExcl * (1 - d / 100) * (1 + t / 100);
  }

  double _priceExclFromInclusive() {
    final pIncl = double.tryParse(price.value) ?? 0;
    final t = _effectiveTaxPercent;
    if (t <= 0) return pIncl;
    return pIncl / (1 + t / 100);
  }
}
