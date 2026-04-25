import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/customer_model.dart';
import '../services/customer_api_service.dart';
import '../api_config.dart';

class CustomerFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? customerId;

  final isLoading = false.obs;
  final isSaving = false.obs;

  final name = ''.obs;
  final shopName = ''.obs;
  final email = ''.obs;
  final contactNumber = ''.obs;
  final alternatePhone = ''.obs;
  final gstNo = ''.obs;
  final panNo = ''.obs;
  final addressLine1 = ''.obs;
  final city = ''.obs;
  final state = ''.obs;
  final country = ''.obs;
  final pincode = ''.obs;
  final notes = ''.obs;
  final status = 'ACTIVE'.obs;

  bool get isEditMode => customerId != null;

  CustomerFormController({this.customerId});

  @override
  void onInit() {
    super.onInit();
    if (customerId != null) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      isLoading.value = true;
      final c = await CustomerApiService.fetchCustomerById(customerId!);
      if (c != null) {
        name.value = c.name;
        shopName.value = c.shopName ?? '';
        email.value = c.email ?? '';
        contactNumber.value = c.contactNumber ?? '';
        alternatePhone.value = c.alternatePhone ?? '';
        gstNo.value = c.gstNo ?? '';
        panNo.value = c.panNo ?? '';
        addressLine1.value = c.addressLine1 ?? '';
        city.value = c.city ?? '';
        state.value = c.state ?? '';
        country.value = c.country ?? '';
        pincode.value = c.pincode ?? '';
        notes.value = c.notes ?? '';
        status.value = c.status;
      }
    } catch (e) {
      debugPrint('[CUSTOMER FORM] Load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    isSaving.value = true;
    try {
      final payload = {
        'name': name.value.trim(),
        if (shopName.value.trim().isNotEmpty) 'shop_name': shopName.value.trim(),
        if (shopName.value.trim().isNotEmpty) 'shopName': shopName.value.trim(),
        'status': status.value,
        if (email.value.trim().isNotEmpty) 'email': email.value.trim(),
        if (contactNumber.value.trim().isNotEmpty) 'phone': contactNumber.value.trim(),
        if (contactNumber.value.trim().isNotEmpty) 'contactNumber': contactNumber.value.trim(),
        if (alternatePhone.value.trim().isNotEmpty) 'alternate_phone': alternatePhone.value.trim(),
        if (alternatePhone.value.trim().isNotEmpty) 'alternatePhone': alternatePhone.value.trim(),
        if (gstNo.value.trim().isNotEmpty) 'gst_no': gstNo.value.trim(),
        if (gstNo.value.trim().isNotEmpty) 'gstNo': gstNo.value.trim(),
        if (panNo.value.trim().isNotEmpty) 'pan_no': panNo.value.trim(),
        if (panNo.value.trim().isNotEmpty) 'panNo': panNo.value.trim(),
        if (addressLine1.value.trim().isNotEmpty) 'address_line1': addressLine1.value.trim(),
        if (addressLine1.value.trim().isNotEmpty) 'addressLine1': addressLine1.value.trim(),
        if (city.value.trim().isNotEmpty) 'city': city.value.trim(),
        if (state.value.trim().isNotEmpty) 'state': state.value.trim(),
        if (country.value.trim().isNotEmpty) 'country': country.value.trim(),
        if (pincode.value.trim().isNotEmpty) 'pincode': pincode.value.trim(),
        if (notes.value.trim().isNotEmpty) 'notes': notes.value.trim(),
      };

      final url = isEditMode
          ? '${ApiConfig.customers}/$customerId'
          : ApiConfig.customers;

      final response = isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        await Fluttertoast.showToast(
          msg: isEditMode ? 'Customer updated' : 'Customer created',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.back(result: true);
      } else {
        _showError(data['message']?.toString() ?? 'Failed to save customer');
      }
    } catch (e) {
      debugPrint('[CUSTOMER FORM] Save error: $e');
      _showError('Failed to save customer');
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}
