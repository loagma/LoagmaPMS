import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../controllers/auth_controller.dart';

class StaffController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;
  final staffList = <Map<String, dynamic>>[].obs;
  final errorMessage = RxnString();

  static const List<Map<String, String>> grantableModules = [
    {'key': 'products',   'label': 'Products'},
    {'key': 'suppliers',  'label': 'Suppliers'},
    {'key': 'purchase',   'label': 'Purchase'},
    {'key': 'sales',      'label': 'Sales'},
    {'key': 'customers',  'label': 'Customers'},
    {'key': 'stock',      'label': 'Stock Voucher'},
    {'key': 'production', 'label': 'Production'},
    {'key': 'bom',        'label': 'BOM'},
    {'key': 'inventory',  'label': 'Inventory'},
    {'key': 'reports',    'label': 'Reports'},
  ];

  Future<void> fetchStaff() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final uri = Uri.parse(ApiConfig.staff).replace(queryParameters: {'limit': '100'});
      final response = await http
          .get(uri, headers: AuthController.getHeaders)
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as List<dynamic>;
        staffList.value = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        errorMessage.value = body['message']?.toString() ?? 'Failed to load staff';
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a subadmin. Returns null on success, error message on failure.
  Future<String?> createStaff({
    required String name,
    required String mobile,
    required List<String> permissions,
  }) async {
    isSaving.value = true;
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.staff),
            headers: AuthController.jsonHeaders,
            body: jsonEncode({'name': name, 'mobile': mobile, 'permissions': permissions}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
        await fetchStaff();
        return null;
      }
      return _extractError(body, response.statusCode);
    } catch (e) {
      return 'Network error: $e';
    } finally {
      isSaving.value = false;
    }
  }

  /// Updates a subadmin. Returns null on success, error message on failure.
  Future<String?> updateStaff({
    required int deliId,
    String? name,
    List<String>? permissions,
    bool? isLocked,
  }) async {
    isSaving.value = true;
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (permissions != null) payload['permissions'] = permissions;
      if (isLocked != null) payload['is_locked'] = isLocked;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.staff}/$deliId'),
            headers: AuthController.jsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        await fetchStaff();
        return null;
      }
      return _extractError(body, response.statusCode);
    } catch (e) {
      return 'Network error: $e';
    } finally {
      isSaving.value = false;
    }
  }

  /// Soft-deletes (locks) a subadmin. Returns null on success.
  Future<String?> deleteStaff(int deliId) async {
    isSaving.value = true;
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.staff}/$deliId'),
            headers: AuthController.jsonHeaders,
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        staffList.removeWhere((s) => s['deli_id'] == deliId);
        return null;
      }
      return _extractError(body, response.statusCode);
    } catch (e) {
      return 'Network error: $e';
    } finally {
      isSaving.value = false;
    }
  }

  String _extractError(Map<String, dynamic> body, int statusCode) {
    if (body['errors'] is Map) {
      final errs = body['errors'] as Map;
      return errs.values.expand((v) => v is List ? v : [v]).join('\n');
    }
    return body['message']?.toString() ?? 'Error ($statusCode)';
  }
}
