import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../theme/app_colors.dart';

class SupplierFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? supplierId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final supplierCode = ''.obs;
  final name = ''.obs;
  final legalName = ''.obs;
  final businessType = ''.obs;
  final industry = ''.obs;
  final gstin = ''.obs;
  final pan = ''.obs;
  final tan = ''.obs;
  final cin = ''.obs;
  final vatNumber = ''.obs;
  final registrationNumber = ''.obs;
  final website = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final alternatePhone = ''.obs;
  final fax = ''.obs;
  final contactPerson = ''.obs;
  final contactPersonEmail = ''.obs;
  final contactPersonPhone = ''.obs;
  final contactPersonDesignation = ''.obs;
  final billingAddressLine1 = ''.obs;
  final billingAddressLine2 = ''.obs;
  final billingCity = ''.obs;
  final billingState = ''.obs;
  final billingCountry = ''.obs;
  final billingPostalCode = ''.obs;
  final shippingAddressLine1 = ''.obs;
  final shippingAddressLine2 = ''.obs;
  final shippingCity = ''.obs;
  final shippingState = ''.obs;
  final shippingCountry = ''.obs;
  final shippingPostalCode = ''.obs;
  final bankName = ''.obs;
  final bankBranch = ''.obs;
  final bankAccountName = ''.obs;
  final bankAccountNumber = ''.obs;
  final ifscCode = ''.obs;
  final swiftCode = ''.obs;
  final paymentTermsDays = ''.obs;
  final creditLimit = ''.obs;
  final rating = ''.obs;
  final isPreferred = false.obs;
  final status = 'ACTIVE'.obs;
  final notes = ''.obs;

  final products = <Product>[].obs;
  final supplierProducts = <SupplierProductRow>[].obs;

  SupplierFormController({this.supplierId});

  bool get isEditMode => supplierId != null;

  @override
  void onInit() {
    super.onInit();
    if (supplierId != null) {
      _initEdit();
    } else {
      _loadProducts();
      supplierProducts.add(SupplierProductRow());
    }
  }

  Future<void> _initEdit() async {
    await _loadProducts();
    await _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.suppliers}/$supplierId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final supplier =
              Supplier.fromJson(data['data'] as Map<String, dynamic>);
          _applySupplier(supplier);
          await _loadSupplierProducts();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Load error: $e');
      _showError('Failed to load supplier details');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSupplierProducts() async {
    if (supplierId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.suppliers}/$supplierId/products'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          supplierProducts.clear();
          for (final item in items) {
            final sp = SupplierProduct.fromJson(
              item as Map<String, dynamic>,
            );
            final row = SupplierProductRow.fromSupplierProduct(sp);
            row.product.value = _findProductById(sp.productId);
            supplierProducts.add(row);
          }
          if (supplierProducts.isEmpty) {
            supplierProducts.add(SupplierProductRow());
          }
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Products load error: $e');
    }
  }

  void _applySupplier(Supplier supplier) {
    supplierCode.value = supplier.supplierCode;
    name.value = supplier.name;
    legalName.value = supplier.legalName ?? '';
    businessType.value = supplier.businessType ?? '';
    industry.value = supplier.industry ?? '';
    gstin.value = supplier.gstin ?? '';
    pan.value = supplier.pan ?? '';
    tan.value = supplier.tan ?? '';
    cin.value = supplier.cin ?? '';
    vatNumber.value = supplier.vatNumber ?? '';
    registrationNumber.value = supplier.registrationNumber ?? '';
    website.value = supplier.website ?? '';
    email.value = supplier.email ?? '';
    phone.value = supplier.phone ?? '';
    alternatePhone.value = supplier.alternatePhone ?? '';
    fax.value = supplier.fax ?? '';
    contactPerson.value = supplier.contactPerson ?? '';
    contactPersonEmail.value = supplier.contactPersonEmail ?? '';
    contactPersonPhone.value = supplier.contactPersonPhone ?? '';
    contactPersonDesignation.value = supplier.contactPersonDesignation ?? '';
    billingAddressLine1.value = supplier.billingAddressLine1 ?? '';
    billingAddressLine2.value = supplier.billingAddressLine2 ?? '';
    billingCity.value = supplier.billingCity ?? '';
    billingState.value = supplier.billingState ?? '';
    billingCountry.value = supplier.billingCountry ?? '';
    billingPostalCode.value = supplier.billingPostalCode ?? '';
    shippingAddressLine1.value = supplier.shippingAddressLine1 ?? '';
    shippingAddressLine2.value = supplier.shippingAddressLine2 ?? '';
    shippingCity.value = supplier.shippingCity ?? '';
    shippingState.value = supplier.shippingState ?? '';
    shippingCountry.value = supplier.shippingCountry ?? '';
    shippingPostalCode.value = supplier.shippingPostalCode ?? '';
    bankName.value = supplier.bankName ?? '';
    bankBranch.value = supplier.bankBranch ?? '';
    bankAccountName.value = supplier.bankAccountName ?? '';
    bankAccountNumber.value = supplier.bankAccountNumber ?? '';
    ifscCode.value = supplier.ifscCode ?? '';
    swiftCode.value = supplier.swiftCode ?? '';
    paymentTermsDays.value =
        supplier.paymentTermsDays?.toString() ?? '';
    creditLimit.value = supplier.creditLimit?.toStringAsFixed(2) ?? '';
    rating.value = supplier.rating?.toStringAsFixed(1) ?? '';
    isPreferred.value = supplier.isPreferred;
    status.value = supplier.status;
    notes.value = supplier.notes ?? '';
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?limit=200'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          products.value = items
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Products error: $e');
    }
  }

  void addSupplierProduct() => supplierProducts.add(SupplierProductRow());

  void removeSupplierProduct(int index) {
    if (index >= 0 && index < supplierProducts.length) {
      supplierProducts.removeAt(index);
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          products.value = items
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Search error: $e');
    }
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    if (supplierProducts.isEmpty) {
      _showError('Please add at least one supplier product');
      return false;
    }
    for (final row in supplierProducts) {
      if (row.product.value == null) {
        _showError('Please select product for all supplier items');
        return false;
      }
    }
    return true;
  }

  Future<void> saveSupplier() async {
    if (!_validateForm()) return;

    isSaving.value = true;
    try {
      final payload = _buildPayload();
      final isEdit = supplierId != null;
      final url = isEdit
          ? '${ApiConfig.suppliers}/$supplierId'
          : ApiConfig.suppliers;

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
        _showError('Server error ${response.statusCode}');
        return;
      }

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        Get.back(result: true);
        _showSuccess(isEdit ? 'Supplier updated' : 'Supplier created');
      } else {
        final msg = data['message'] ?? 'Failed to save supplier';
        final err = data['error'];
        final errs = data['errors'];
        final detail = err != null
            ? (err is String ? err : err.toString())
            : (errs != null ? errs.toString() : null);
        _showError(detail != null ? '$msg: $detail' : msg);
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'supplier_code': supplierCode.value.trim(),
      'name': name.value.trim(),
      'legal_name': legalName.value.trim(),
      'business_type': businessType.value.trim(),
      'industry': industry.value.trim(),
      'gstin': gstin.value.trim(),
      'pan': pan.value.trim(),
      'tan': tan.value.trim(),
      'cin': cin.value.trim(),
      'vat_number': vatNumber.value.trim(),
      'registration_number': registrationNumber.value.trim(),
      'website': website.value.trim(),
      'email': email.value.trim(),
      'phone': phone.value.trim(),
      'alternate_phone': alternatePhone.value.trim(),
      'fax': fax.value.trim(),
      'contact_person': contactPerson.value.trim(),
      'contact_person_email': contactPersonEmail.value.trim(),
      'contact_person_phone': contactPersonPhone.value.trim(),
      'contact_person_designation': contactPersonDesignation.value.trim(),
      'billing_address_line1': billingAddressLine1.value.trim(),
      'billing_address_line2': billingAddressLine2.value.trim(),
      'billing_city': billingCity.value.trim(),
      'billing_state': billingState.value.trim(),
      'billing_country': billingCountry.value.trim(),
      'billing_postal_code': billingPostalCode.value.trim(),
      'shipping_address_line1': shippingAddressLine1.value.trim(),
      'shipping_address_line2': shippingAddressLine2.value.trim(),
      'shipping_city': shippingCity.value.trim(),
      'shipping_state': shippingState.value.trim(),
      'shipping_country': shippingCountry.value.trim(),
      'shipping_postal_code': shippingPostalCode.value.trim(),
      'bank_name': bankName.value.trim(),
      'bank_branch': bankBranch.value.trim(),
      'bank_account_name': bankAccountName.value.trim(),
      'bank_account_number': bankAccountNumber.value.trim(),
      'ifsc_code': ifscCode.value.trim(),
      'swift_code': swiftCode.value.trim(),
      'payment_terms_days': _intOrNull(paymentTermsDays.value),
      'credit_limit': _doubleOrNull(creditLimit.value),
      'rating': _doubleOrNull(rating.value),
      'is_preferred': isPreferred.value ? 1 : 0,
      'status': status.value,
      'notes': notes.value.trim(),
      'products': supplierProducts.map((row) => row.toJson()).toList(),
    };
  }

  int? _intOrNull(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  double? _doubleOrNull(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Product? _findProductById(int productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }
}

class SupplierProductRow {
  final product = Rxn<Product>();
  final supplierSku = ''.obs;
  final supplierProductName = ''.obs;
  final packSize = ''.obs;
  final packUnit = ''.obs;
  final minOrderQty = ''.obs;
  final price = ''.obs;
  final currency = 'INR'.obs;
  final taxPercent = ''.obs;
  final discountPercent = ''.obs;
  final leadTimeDays = ''.obs;
  final isPreferred = false.obs;
  final isActive = true.obs;

  SupplierProductRow();

  factory SupplierProductRow.fromSupplierProduct(SupplierProduct sp) {
    final row = SupplierProductRow();
    row.supplierSku.value = sp.supplierSku ?? '';
    row.supplierProductName.value = sp.supplierProductName ?? '';
    row.packSize.value = sp.packSize?.toString() ?? '';
    row.packUnit.value = sp.packUnit ?? '';
    row.minOrderQty.value = sp.minOrderQty?.toString() ?? '';
    row.price.value = sp.price?.toString() ?? '';
    row.currency.value = sp.currency ?? 'INR';
    row.taxPercent.value = sp.taxPercent?.toString() ?? '';
    row.discountPercent.value = sp.discountPercent?.toString() ?? '';
    row.leadTimeDays.value = sp.leadTimeDays?.toString() ?? '';
    row.isPreferred.value = sp.isPreferred;
    row.isActive.value = sp.isActive;
    return row;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.value?.id,
      'supplier_sku': supplierSku.value.trim(),
      'supplier_product_name': supplierProductName.value.trim(),
      'pack_size': _doubleOrNull(packSize.value),
      'pack_unit': packUnit.value.trim(),
      'min_order_qty': _doubleOrNull(minOrderQty.value),
      'price': _doubleOrNull(price.value),
      'currency': currency.value.trim(),
      'tax_percent': _doubleOrNull(taxPercent.value),
      'discount_percent': _doubleOrNull(discountPercent.value),
      'lead_time_days': _intOrNull(leadTimeDays.value),
      'is_preferred': isPreferred.value ? 1 : 0,
      'is_active': isActive.value ? 1 : 0,
    };
  }

  int? _intOrNull(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  double? _doubleOrNull(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }
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
