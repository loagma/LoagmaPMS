import 'dart:convert';
import 'auth_controller.dart';

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
  final isPincodeLoading = false.obs;
  final status = 'ACTIVE'.obs;

  final nameController        = TextEditingController();
  final shopNameController    = TextEditingController();
  final emailController       = TextEditingController();
  final contactController     = TextEditingController();
  final altPhoneController    = TextEditingController();
  final gstNoController       = TextEditingController();
  final panNoController       = TextEditingController();
  final addressController     = TextEditingController();
  final cityController        = TextEditingController();
  final stateController       = TextEditingController();
  final countryController     = TextEditingController();
  final pincodeController     = TextEditingController();
  final notesController       = TextEditingController();

  bool get isEditMode => customerId != null;

  CustomerFormController({this.customerId});

  @override
  void onInit() {
    super.onInit();
    pincodeController.addListener(_onPincodeChanged);
    if (customerId != null) _loadCustomer();
  }

  String _lastLookedUpPincode = '';

  void _onPincodeChanged() {
    final pin = pincodeController.text.trim();
    if (pin.length == 6 && pin != _lastLookedUpPincode) {
      _lastLookedUpPincode = pin;
      _lookupPincode(pin);
    }
  }

  Future<void> _lookupPincode(String pin) async {
    try {
      isPincodeLoading.value = true;
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pin'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final offices = data[0]['PostOffice'] as List;
          if (offices.isNotEmpty) {
            final office = offices[0] as Map<String, dynamic>;
            cityController.text    = office['District']?.toString() ?? '';
            stateController.text   = office['State']?.toString() ?? '';
            countryController.text = office['Country']?.toString() ?? 'India';
          }
        }
      }
    } catch (e) {
      debugPrint('[CUSTOMER FORM] Pincode lookup error: $e');
    } finally {
      isPincodeLoading.value = false;
    }
  }

  @override
  void onClose() {
    pincodeController.removeListener(_onPincodeChanged);
    nameController.dispose();
    shopNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    altPhoneController.dispose();
    gstNoController.dispose();
    panNoController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> _loadCustomer() async {
    try {
      isLoading.value = true;
      final c = await CustomerApiService.fetchCustomerById(customerId!);
      if (c != null) {
        nameController.text     = c.name;
        shopNameController.text = c.shopName ?? '';
        emailController.text    = c.email ?? '';
        contactController.text  = c.contactNumber ?? '';
        altPhoneController.text = c.alternatePhone ?? '';
        gstNoController.text    = c.gstNo ?? '';
        panNoController.text    = c.panNo ?? '';
        addressController.text  = c.addressLine1 ?? '';
        cityController.text     = c.city ?? '';
        stateController.text    = c.state ?? '';
        countryController.text  = c.country ?? '';
        pincodeController.text  = c.pincode ?? '';
        notesController.text    = c.notes ?? '';
        status.value            = c.status;
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
      final name        = nameController.text.trim();
      final shopName    = shopNameController.text.trim();
      final email       = emailController.text.trim();
      final phone       = contactController.text.trim();
      final altPhone    = altPhoneController.text.trim();
      final gstNo       = gstNoController.text.trim();
      final panNo       = panNoController.text.trim();
      final address     = addressController.text.trim();
      final city        = cityController.text.trim();
      final state       = stateController.text.trim();
      final country     = countryController.text.trim();
      final pincode     = pincodeController.text.trim();
      final notes       = notesController.text.trim();

      final payload = {
        'name': name,
        if (shopName.isNotEmpty) 'shop_name': shopName,
        if (shopName.isNotEmpty) 'shopName': shopName,
        'status': status.value,
        if (email.isNotEmpty) 'email': email,
        if (phone.isNotEmpty) 'phone': phone,
        if (phone.isNotEmpty) 'contactNumber': phone,
        if (altPhone.isNotEmpty) 'alternate_phone': altPhone,
        if (altPhone.isNotEmpty) 'alternatePhone': altPhone,
        if (gstNo.isNotEmpty) 'gst_no': gstNo,
        if (gstNo.isNotEmpty) 'gstNo': gstNo,
        if (panNo.isNotEmpty) 'pan_no': panNo,
        if (panNo.isNotEmpty) 'panNo': panNo,
        if (address.isNotEmpty) 'address_line1': address,
        if (address.isNotEmpty) 'addressLine1': address,
        if (city.isNotEmpty) 'city': city,
        if (state.isNotEmpty) 'state': state,
        if (country.isNotEmpty) 'country': country,
        if (pincode.isNotEmpty) 'pincode': pincode,
        if (notes.isNotEmpty) 'notes': notes,
      };

      final url = isEditMode
          ? '${ApiConfig.customers}/$customerId'
          : ApiConfig.customers;

      final response = isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: AuthController.jsonHeaders,
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: AuthController.jsonHeaders,
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
