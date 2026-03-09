import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../models/purchase_order_model.dart';
import '../theme/app_colors.dart';

class PurchaseVoucherController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? voucherId;

  // Header
  final docNoPrefix = '25-26/'.obs;
  final docNoNumber = ''.obs;
  final vendorId = Rxn<int>();
  final vendorName = ''.obs;
  final docDate = ''.obs;
  final billNo = ''.obs;
  final narration = ''.obs;
  final doNotUpdateInventory = false.obs;
  final purchaseType = 'Regular'.obs;
  final gstReverseCharge = 'N'.obs;
  final billDate = ''.obs;
  final purchaseAgentId = ''.obs;

  // Master data
  final suppliers = <Map<String, dynamic>>[].obs;
  final products = <Product>[].obs;
  final unitTypes = <String>[].obs;
  final purchaseAgents = <String>['AA SalesMan', 'Default Agent'].obs;
  static const List<String> chargeTypeNames = [
    'Freight',
    'VATInputAmount',
    'T.C.S',
    'Others',
    'Discount',
  ];

  final items = <PVItemRow>[].obs;
  final charges = <PVChargeRow>[].obs;

  /// When set, this voucher was created from the given purchase order.
  final linkedPurchaseOrderId = Rxn<int>();
  final linkedPoNumber = ''.obs;

  /// Controls whether product searches show only vendor-assigned products
  /// (via /supplier-products) or the full product catalogue.
  final showAllProducts = false.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  PurchaseVoucherController({this.voucherId});

  @override
  void onInit() {
    super.onInit();
    _loadSuppliers();
    _loadUnitTypes();
    _loadProducts();
    if (voucherId == null) {
      docDate.value = _formatDate(DateTime.now());
      addItemRow();
      addChargeRow();
    } else {
      _loadVoucherData();
    }
  }

  bool get isEditMode => voucherId != null;

  String get netTotal {
    double itemsTotal = 0;
    for (var row in items) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final price = double.tryParse(row.unitPrice.value) ?? 0;
      final taxable = qty * price;
      final sgst = double.tryParse(row.sgst.value) ?? 0;
      final cgst = double.tryParse(row.cgst.value) ?? 0;
      final igst = double.tryParse(row.igst.value) ?? 0;
      final cess = double.tryParse(row.cess.value) ?? 0;
      final roff = double.tryParse(row.roff.value) ?? 0;
      itemsTotal += taxable + sgst + cgst + igst + cess + roff;
    }
    double chargesTotal = 0;
    for (var row in charges) {
      final amt = double.tryParse(row.amount.value) ?? 0;
      final name = row.name.value.toLowerCase();
      chargesTotal += name.contains('discount') ? -amt : amt;
    }
    return (itemsTotal + chargesTotal).toStringAsFixed(3);
  }

  void recalcItemRow(PVItemRow row) {
    final qty = double.tryParse(row.quantity.value) ?? 0;
    final price = double.tryParse(row.unitPrice.value) ?? 0;
    row.taxableAmount.value = (qty * price).toStringAsFixed(2);
    final taxable = double.tryParse(row.taxableAmount.value) ?? 0;
    final sgst = double.tryParse(row.sgst.value) ?? 0;
    final cgst = double.tryParse(row.cgst.value) ?? 0;
    final igst = double.tryParse(row.igst.value) ?? 0;
    final cess = double.tryParse(row.cess.value) ?? 0;
    final roff = double.tryParse(row.roff.value) ?? 0;
    final value = taxable + sgst + cgst + igst + cess + roff;
    row.value.value = value.toStringAsFixed(2);
  }

  Future<void> _loadVoucherData() async {
    if (voucherId == null) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseVouchers}/$voucherId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final vData = data['data'] as Map<String, dynamic>?;
          final v = vData?['voucher'] as Map<String, dynamic>?;
          if (v != null) {
            docNoPrefix.value = v['doc_no_prefix']?.toString() ?? '25-26/';
            docNoNumber.value = v['doc_no_number']?.toString() ?? '';
            vendorId.value = int.tryParse(v['vendor_id']?.toString() ?? v['supplier_id']?.toString() ?? '');
            vendorName.value = v['vendor_name']?.toString() ?? v['supplier_name']?.toString() ?? '';
            docDate.value = v['doc_date']?.toString().split(' ').first ?? _formatDate(DateTime.now());
            billNo.value = v['bill_no']?.toString() ?? '';
            narration.value = v['narration']?.toString() ?? '';
            doNotUpdateInventory.value = v['do_not_update_inventory'] == true;
            purchaseType.value = v['purchase_type']?.toString() ?? 'Regular';
            gstReverseCharge.value = v['gst_reverse_charge']?.toString() ?? 'N';
            billDate.value = v['bill_date']?.toString() ?? '';
            purchaseAgentId.value = v['purchase_agent_id']?.toString() ?? '';
          }
          final itemsData = (vData?['items'] as List?) ?? [];
          items.clear();
          for (var item in itemsData) {
            final map = item as Map<String, dynamic>;
            final row = PVItemRow();
            final pid = int.tryParse(map['product_id']?.toString() ?? '');
            if (pid != null) row.product.value = Product(id: pid, name: map['product_name']?.toString() ?? '', productType: 'SINGLE');
            row.productCode.value = map['product_code']?.toString() ?? '';
            row.productName.value = map['product_name']?.toString() ?? '';
            row.alias.value = map['alias']?.toString() ?? '';
            row.quantity.value = map['quantity']?.toString() ?? '';
            row.unitType.value = map['unit']?.toString() ?? 'Nos';
            row.unitPrice.value = map['unit_price']?.toString() ?? '0';
            row.taxableAmount.value = map['taxable_amount']?.toString() ?? '0';
            row.sgst.value = map['sgst']?.toString() ?? '0';
            row.cgst.value = map['cgst']?.toString() ?? '0';
            row.igst.value = map['igst']?.toString() ?? '0';
            row.cess.value = map['cess']?.toString() ?? '0';
            row.roff.value = map['roff']?.toString() ?? '0';
            row.value.value = map['value']?.toString() ?? '0';
            row.purchaseAccount.value = map['purchase_account']?.toString() ?? 'Def Purchase Accounts';
            row.gstItcEligibility.value = map['gst_itc_eligibility']?.toString() ?? '';
            items.add(row);
          }
          final chargesData = (vData?['charges'] as List?) ?? [];
          charges.clear();
          for (var ch in chargesData) {
            final map = ch as Map<String, dynamic>;
            final row = PVChargeRow();
            row.name.value = map['name']?.toString() ?? 'Others';
            row.amount.value = map['amount']?.toString() ?? '0';
            row.remarks.value = map['remarks']?.toString() ?? '';
            charges.add(row);
          }
          if (items.isEmpty) addItemRow();
          if (charges.isEmpty) addChargeRow();
        }
      }
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Load failed: $e');
      _showError('Failed to load voucher data');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
      debugPrint('[PURCHASE_VOUCHER] Suppliers error: $e');
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
    } catch (_) {
      unitTypes.value = ['Nos', 'KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?limit=50'),
            headers: {'Accept': 'application/json'},
          )
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
      debugPrint('[PURCHASE_VOUCHER] Products error: $e');
    }
  }

  /// Load products for the current vendor.
  /// If [includeAll] is false and a vendor is selected, we hit /supplier-products
  /// so that only products assigned to that vendor are returned. Otherwise we
  /// fall back to the generic /products list.
  Future<void> loadProductsForVendor({
    String? search,
    bool? includeAll,
  }) async {
    final useAll = includeAll ?? showAllProducts.value;
    final vendor = vendorId.value;

    if (!useAll && vendor != null) {
      try {
        final uri = Uri.parse(ApiConfig.supplierProducts).replace(
          queryParameters: {
            'limit': '50',
            'supplier_id': vendor.toString(),
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        );
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          debugPrint(
              '[PURCHASE_VOUCHER] Vendor products status ${response.statusCode}');
          return;
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] != true) return;
        final List data = decoded['data'] ?? [];
        products.value = data.map((e) {
          final map = e as Map<String, dynamic>;
          final product = map['product'] as Map<String, dynamic>?;
          final rawId =
              map['product_id'] ?? product?['product_id'] ?? product?['id'];
          final id = rawId is int ? rawId : int.parse(rawId.toString());
          final name = product?['name']?.toString() ??
              map['product_name']?.toString() ??
              map['supplier_product_name']?.toString() ??
              'Product $id';
          return Product(
            id: id,
            name: name,
            code: product?['product_code']?.toString(),
            productType:
                (product?['product_type'] ?? 'SINGLE').toString().toUpperCase(),
            defaultUnit: product?['default_unit']?.toString(),
          );
        }).toList();
        return;
      } catch (e) {
        debugPrint('[PURCHASE_VOUCHER] Vendor products error: $e');
        // fall through to all-products load
      }
    }

    // Fallback: generic products list (optionally filtered by search).
    try {
      final base = ApiConfig.products;
      final uri = search != null && search.trim().isNotEmpty
          ? Uri.parse(base).replace(
              queryParameters: {
                'limit': '50',
                'search': search.trim(),
              },
            )
          : Uri.parse('$base?limit=50');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
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
      debugPrint('[PURCHASE_VOUCHER] Products error: $e');
    }
  }

  Future<void> searchProducts(String query) =>
      loadProductsForVendor(search: query);

  void setDocNoPrefix(String v) => docNoPrefix.value = v;
  void setDocNoNumber(String v) => docNoNumber.value = v;
  void setVendor(int? id, String name) {
    vendorId.value = id;
    vendorName.value = name;
  }

  void setDocDate(String v) => docDate.value = v;
  void setBillNo(String v) => billNo.value = v;
  void setNarration(String v) => narration.value = v;
  void setDoNotUpdateInventory(bool v) => doNotUpdateInventory.value = v;
  void setPurchaseType(String v) => purchaseType.value = v;
  void setGstReverseCharge(String v) => gstReverseCharge.value = v;
  void setBillDate(String v) => billDate.value = v;
  void setPurchaseAgentId(String v) => purchaseAgentId.value = v;

  void addItemRow() {
    final row = PVItemRow();
    if (unitTypes.isNotEmpty && row.unitType.value == 'Nos') {
      if (unitTypes.contains('Nos')) row.unitType.value = 'Nos';
      else row.unitType.value = unitTypes.first;
    }
    items.add(row);
  }

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  void addChargeRow() {
    charges.add(PVChargeRow());
  }

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) charges.removeAt(index);
  }

  List<Product> getProductsExcluding(Iterable<int> excludeIds) =>
      products.where((p) => !excludeIds.contains(p.id)).toList();

  /// Fetches a single purchase order by id (with items) for linking.
  Future<PurchaseOrder?> fetchPurchaseOrderById(int poId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.purchaseOrders}/$poId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      final poData = data['data'] as Map<String, dynamic>?;
      if (poData == null) return null;
      return PurchaseOrder.fromJson(poData);
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Fetch PO error: $e');
      return null;
    }
  }

  /// Fetches purchase orders list for the link dialog (id, po_number, supplier, status).
  /// If [search] is provided, it is sent to the backend so the API can filter
  /// by supplier name, PO number or id.
  Future<List<Map<String, dynamic>>> fetchPurchaseOrdersForLink({
    String? search,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.purchaseOrders).replace(
        queryParameters: {
          'limit': '50',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final List list = data['data'] ?? [];
      return list
          .map((e) => {
                'id': (e as Map)['id'],
                'po_number': (e)['po_number']?.toString(),
                'supplier_name': (e)['supplier_name']?.toString() ?? (e)['supplier']?['supplier_name']?.toString(),
                'doc_date': (e)['doc_date']?.toString(),
                'status': (e)['status']?.toString(),
              })
          .toList();
    } catch (e) {
      debugPrint('[PURCHASE_VOUCHER] Fetch PO list error: $e');
      return [];
    }
  }

  /// Fills the voucher from a purchase order (vendor, narration, and all line items).
  void loadFromPurchaseOrder(PurchaseOrder po) {
    linkedPurchaseOrderId.value = po.id;
    linkedPoNumber.value = po.poNumber;
    setVendor(po.supplierId, po.supplierName ?? 'Vendor');
    setNarration(po.narration ?? '');
    if (po.docDate.isNotEmpty) docDate.value = po.docDate.split(' ').first;
    if (po.financialYear != null && po.financialYear!.isNotEmpty) {
      docNoPrefix.value = po.financialYear!.endsWith('/')
          ? po.financialYear!
          : '${po.financialYear}/';
    }
    if (po.poNumber.isNotEmpty) billNo.value = po.poNumber;

    items.clear();
    for (final item in po.items) {
      final row = PVItemRow();
      row.product.value = Product(
        id: item.productId,
        name: item.productName?.trim().isEmpty == true
            ? 'Product ${item.productId}'
            : (item.productName ?? 'Product ${item.productId}'),
        productType: 'SINGLE',
        defaultUnit: item.unit,
      );
      row.productName.value = row.product.value!.name;
      row.productCode.value = '${item.productId}';
      row.alias.value = '${item.productName ?? ''} : ${item.unit ?? 'Nos'}';
      row.quantity.value = item.quantity.toStringAsFixed(2);
      row.unitType.value = item.unit ?? (unitTypes.isNotEmpty ? unitTypes.first : 'Nos');
      row.unitPrice.value = item.price.toStringAsFixed(2);
      row.taxableAmount.value = (item.quantity * item.price).toStringAsFixed(2);
      row.value.value = row.taxableAmount.value;
      items.add(row);
    }
    if (items.isEmpty) addItemRow();
    _showSuccess('Invoice filled from Purchase Order ${po.poNumber}');
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (vendorId.value == null) {
      _showError('Please select Vendor');
      return false;
    }
    if (docDate.value.trim().isEmpty) {
      _showError('Please enter Doc Date');
      return false;
    }
    if (billNo.value.trim().isEmpty) {
      _showError('Please enter Bill No');
      return false;
    }
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
      final price = double.tryParse(row.unitPrice.value);
      if (price == null || price < 0) {
        _showError('Please enter valid unit price for all items');
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
        'doc_no_prefix': docNoPrefix.value,
        'doc_no_number': docNoNumber.value.trim().isEmpty ? null : docNoNumber.value,
        if (linkedPurchaseOrderId.value != null) 'purchase_order_id': linkedPurchaseOrderId.value,
        'vendor_id': vendorId.value,
        'doc_date': docDate.value.trim().isEmpty ? _formatDate(DateTime.now()) : docDate.value,
        'bill_no': billNo.value.trim(),
        'narration': narration.value.trim(),
        'do_not_update_inventory': doNotUpdateInventory.value,
        'purchase_type': purchaseType.value,
        'gst_reverse_charge': gstReverseCharge.value,
        if (billDate.value.trim().isNotEmpty) 'bill_date': billDate.value.trim(),
        if (purchaseAgentId.value.trim().isNotEmpty) 'purchase_agent_id': purchaseAgentId.value.trim(),
        'status': saveStatus,
        'items': items.map((row) {
          final qty = double.tryParse(row.quantity.value) ?? 0;
          final price = double.tryParse(row.unitPrice.value) ?? 0;
          final taxable = qty * price;
          final sgst = double.tryParse(row.sgst.value) ?? 0;
          final cgst = double.tryParse(row.cgst.value) ?? 0;
          final igst = double.tryParse(row.igst.value) ?? 0;
          final cess = double.tryParse(row.cess.value) ?? 0;
          final roff = double.tryParse(row.roff.value) ?? 0;
          return {
            'product_id': row.product.value!.id,
            'product_name': row.productName.value,
            'product_code': row.productCode.value,
            'alias': row.alias.value,
            'unit': row.unitType.value,
            'quantity': qty,
            'unit_price': price,
            'taxable_amount': taxable,
            'sgst': sgst,
            'cgst': cgst,
            'igst': igst,
            'cess': cess,
            'roff': roff,
            'value': taxable + sgst + cgst + igst + cess + roff,
            'purchase_account': row.purchaseAccount.value,
            'gst_itc_eligibility': row.gstItcEligibility.value,
          };
        }).toList(),
        'charges': charges.map((row) {
          final amt = double.tryParse(row.amount.value) ?? 0;
          final name = row.name.value.toLowerCase();
          return {
            'name': row.name.value,
            'amount': amt,
            'calculated_amount': name.contains('discount') ? -amt : amt,
            'remarks': row.remarks.value,
          };
        }).toList(),
      };

      final isEdit = voucherId != null;
      final url = isEdit
          ? '${ApiConfig.purchaseVouchers}/$voucherId'
          : ApiConfig.createPurchaseVoucher;

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
          'Server error ${response.statusCode}. Backend may not be ready.',
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
                  : 'Purchase voucher posted',
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
      debugPrint('[PURCHASE_VOUCHER] Save failed: $e');
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
        content: const Text(
          'Are you sure you want to post this purchase voucher?',
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

class PVItemRow {
  final product = Rxn<Product>();
  final productCode = ''.obs;
  final productName = ''.obs;
  final alias = ''.obs;
  final quantity = ''.obs;
  final unitType = 'Nos'.obs;
  final unitPrice = ''.obs;
  final taxableAmount = '0'.obs;
  final sgst = '0'.obs;
  final cgst = '0'.obs;
  final igst = '0'.obs;
  final cess = '0'.obs;
  final roff = '0'.obs;
  final value = '0'.obs;
  final purchaseAccount = 'Def Purchase Accounts'.obs;
  final gstItcEligibility = ''.obs;
}

class PVChargeRow {
  final name = 'Others'.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;
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
