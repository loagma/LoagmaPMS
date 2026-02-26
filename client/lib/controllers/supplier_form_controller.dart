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

  // Text editing controllers
  final pincodeController = TextEditingController();

  // Updated fields to match new schema
  final supplierCode = ''.obs;
  final supplierName = ''.obs;
  final shortName = ''.obs;
  final businessType = ''.obs;
  final department = ''.obs;
  final gstNo = ''.obs;
  final panNo = ''.obs;
  final tanNo = ''.obs;
  final cinNo = ''.obs;
  final vatNo = ''.obs;
  final registrationNo = ''.obs;
  final fssaiNo = ''.obs;
  final website = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final alternatePhone = ''.obs;
  final contactPerson = ''.obs;
  final contactPersonEmail = ''.obs;
  final contactPersonPhone = ''.obs;
  final contactPersonDesignation = ''.obs;
  final addressLine1 = ''.obs;
  final area = ''.obs;
  final city = ''.obs;
  final state = ''.obs;
  final country = ''.obs;
  final pincode = ''.obs;

  // Pincode API related
  final isLoadingPincode = false.obs;
  final areas = <String>[].obs;

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

  @override
  void onClose() {
    pincodeController.dispose();
    super.onClose();
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
          final supplier = Supplier.fromJson(
            data['data'] as Map<String, dynamic>,
          );
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
            final sp = SupplierProduct.fromJson(item as Map<String, dynamic>);
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
    supplierName.value = supplier.supplierName;
    shortName.value = supplier.shortName ?? '';
    businessType.value = supplier.businessType ?? '';
    department.value = supplier.department ?? '';
    gstNo.value = supplier.gstNo ?? '';
    panNo.value = supplier.panNo ?? '';
    tanNo.value = supplier.tanNo ?? '';
    cinNo.value = supplier.cinNo ?? '';
    vatNo.value = supplier.vatNo ?? '';
    registrationNo.value = supplier.registrationNo ?? '';
    fssaiNo.value = supplier.fssaiNo ?? '';
    website.value = supplier.website ?? '';
    email.value = supplier.email ?? '';
    phone.value = supplier.phone ?? '';
    alternatePhone.value = supplier.alternatePhone ?? '';
    contactPerson.value = supplier.contactPerson ?? '';
    contactPersonEmail.value = supplier.contactPersonEmail ?? '';
    contactPersonPhone.value = supplier.contactPersonPhone ?? '';
    contactPersonDesignation.value = supplier.contactPersonDesignation ?? '';
    addressLine1.value = supplier.addressLine1 ?? '';
    city.value = supplier.city ?? '';
    state.value = supplier.state ?? '';
    country.value = supplier.country ?? '';
    pincode.value = supplier.pincode ?? '';
    pincodeController.text = supplier.pincode ?? '';
    bankName.value = supplier.bankName ?? '';
    bankBranch.value = supplier.bankBranch ?? '';
    bankAccountName.value = supplier.bankAccountName ?? '';
    bankAccountNumber.value = supplier.bankAccountNumber ?? '';
    ifscCode.value = supplier.ifscCode ?? '';
    swiftCode.value = supplier.swiftCode ?? '';
    paymentTermsDays.value = supplier.paymentTermsDays?.toString() ?? '';
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

  Future<void> lookupPincode(String pin) async {
    if (pin.length != 6) return;

    try {
      isLoadingPincode.value = true;
      areas.clear();

      // Using India Post Pincode API
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pin'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            // Extract unique areas
            final areaSet = <String>{};
            for (final office in postOffices) {
              final name = office['Name']?.toString();
              if (name != null && name.isNotEmpty) {
                areaSet.add(name);
              }
            }
            areas.value = areaSet.toList()..sort();

            // Set first office details
            final firstOffice = postOffices[0];
            city.value = firstOffice['District']?.toString() ?? '';
            state.value = firstOffice['State']?.toString() ?? '';
            country.value = firstOffice['Country']?.toString() ?? 'India';

            // Auto-select first area if only one
            if (areas.length == 1) {
              area.value = areas[0];
            }
          }
        } else {
          _showError('Invalid pincode or no data found');
        }
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Pincode lookup error: $e');
      _showError('Failed to lookup pincode');
    } finally {
      isLoadingPincode.value = false;
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
    return formKey.currentState!.validate();
  }

  Future<void> saveSupplier() async {
    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      final payload = {
        // supplier_code is auto-generated by backend
        'supplier_name': supplierName.value.trim(),
        'short_name': shortName.value.trim().isEmpty
            ? null
            : shortName.value.trim(),
        'business_type': businessType.value.trim().isEmpty
            ? null
            : businessType.value.trim(),
        'department': department.value.trim().isEmpty
            ? null
            : department.value.trim(),
        'gst_no': gstNo.value.trim().isEmpty ? null : gstNo.value.trim(),
        'pan_no': panNo.value.trim().isEmpty ? null : panNo.value.trim(),
        'tan_no': tanNo.value.trim().isEmpty ? null : tanNo.value.trim(),
        'cin_no': cinNo.value.trim().isEmpty ? null : cinNo.value.trim(),
        'vat_no': vatNo.value.trim().isEmpty ? null : vatNo.value.trim(),
        'registration_no': registrationNo.value.trim().isEmpty
            ? null
            : registrationNo.value.trim(),
        'fssai_no': fssaiNo.value.trim().isEmpty ? null : fssaiNo.value.trim(),
        'website': website.value.trim().isEmpty ? null : website.value.trim(),
        'email': email.value.trim().isEmpty ? null : email.value.trim(),
        'phone': phone.value.trim().isEmpty ? null : phone.value.trim(),
        'alternate_phone': alternatePhone.value.trim().isEmpty
            ? null
            : alternatePhone.value.trim(),
        'contact_person': contactPerson.value.trim().isEmpty
            ? null
            : contactPerson.value.trim(),
        'contact_person_email': contactPersonEmail.value.trim().isEmpty
            ? null
            : contactPersonEmail.value.trim(),
        'contact_person_phone': contactPersonPhone.value.trim().isEmpty
            ? null
            : contactPersonPhone.value.trim(),
        'contact_person_designation':
            contactPersonDesignation.value.trim().isEmpty
            ? null
            : contactPersonDesignation.value.trim(),
        'address_line1': addressLine1.value.trim().isEmpty
            ? null
            : addressLine1.value.trim(),
        'city': city.value.trim().isEmpty ? null : city.value.trim(),
        'state': state.value.trim().isEmpty ? null : state.value.trim(),
        'country': country.value.trim().isEmpty ? null : country.value.trim(),
        'pincode': pincode.value.trim().isEmpty ? null : pincode.value.trim(),
        'bank_name': bankName.value.trim().isEmpty
            ? null
            : bankName.value.trim(),
        'bank_branch': bankBranch.value.trim().isEmpty
            ? null
            : bankBranch.value.trim(),
        'bank_account_name': bankAccountName.value.trim().isEmpty
            ? null
            : bankAccountName.value.trim(),
        'bank_account_number': bankAccountNumber.value.trim().isEmpty
            ? null
            : bankAccountNumber.value.trim(),
        'ifsc_code': ifscCode.value.trim().isEmpty
            ? null
            : ifscCode.value.trim(),
        'swift_code': swiftCode.value.trim().isEmpty
            ? null
            : swiftCode.value.trim(),
        'payment_terms_days': paymentTermsDays.value.trim().isEmpty
            ? null
            : int.tryParse(paymentTermsDays.value.trim()),
        'credit_limit': creditLimit.value.trim().isEmpty
            ? null
            : double.tryParse(creditLimit.value.trim()),
        'rating': rating.value.trim().isEmpty
            ? null
            : double.tryParse(rating.value.trim()),
        'is_preferred': isPreferred.value ? 1 : 0,
        'status': status.value,
        'notes': notes.value.trim().isEmpty ? null : notes.value.trim(),
        'supplier_products': supplierProducts
            .where((row) => row.product.value != null)
            .map(
              (row) => {
                'product_id': row.product.value!.id,
                'supplier_sku': row.supplierSku.value.trim().isEmpty
                    ? null
                    : row.supplierSku.value.trim(),
                'supplier_product_name':
                    row.supplierProductName.value.trim().isEmpty
                    ? null
                    : row.supplierProductName.value.trim(),
                'description': row.description.value.trim().isEmpty
                    ? null
                    : row.description.value.trim(),
                'pack_size': row.packSize.value.trim().isEmpty
                    ? null
                    : double.tryParse(row.packSize.value.trim()),
                'pack_unit': row.packUnit.value.trim().isEmpty
                    ? null
                    : row.packUnit.value.trim(),
                'min_order_qty': row.minOrderQty.value.trim().isEmpty
                    ? null
                    : double.tryParse(row.minOrderQty.value.trim()),
                'price': row.price.value.trim().isEmpty
                    ? null
                    : double.tryParse(row.price.value.trim()),
                'currency': row.currency.value.trim().isEmpty
                    ? null
                    : row.currency.value.trim(),
                'tax_percent': row.taxPercent.value.trim().isEmpty
                    ? null
                    : double.tryParse(row.taxPercent.value.trim()),
                'discount_percent': row.discountPercent.value.trim().isEmpty
                    ? null
                    : double.tryParse(row.discountPercent.value.trim()),
                'lead_time_days': row.leadTimeDays.value.trim().isEmpty
                    ? null
                    : int.tryParse(row.leadTimeDays.value.trim()),
                'is_preferred': row.isPreferred.value ? 1 : 0,
                'is_active': row.isActive.value ? 1 : 0,
              },
            )
            .toList(),
      };

      final url = isEditMode
          ? '${ApiConfig.suppliers}/$supplierId'
          : ApiConfig.suppliers;
      final response = isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          _showSuccess(
            isEditMode
                ? 'Supplier updated successfully'
                : 'Supplier created successfully',
          );
          Get.back(result: true);
        } else {
          _showError(data['message'] ?? 'Failed to save supplier');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SUPPLIER_FORM] Save error: $e');
      _showError('Failed to save supplier');
    } finally {
      isSaving.value = false;
    }
  }

  Product? _findProductById(int id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
      colorText: AppColors.primaryDark,
      duration: const Duration(seconds: 2),
    );
  }
}

class SupplierProductRow {
  final product = Rx<Product?>(null);
  final supplierSku = ''.obs;
  final supplierProductName = ''.obs;
  final description = ''.obs;
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
    row.description.value = sp.description ?? '';
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
}
