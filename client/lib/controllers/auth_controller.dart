import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_config.dart';

class AuthController extends GetxController {
  var mobile = ''.obs;
  var isLoading = false.obs;

  // Master OTP — also set as MASTER_OTP on the server side (.env)
  static const _masterOtp = '5555';

  // SharedPreferences keys
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyDeliId   = 'deli_staff_deli_id';
  static const _keyAdminId  = 'deli_staff_admin_id';
  static const _keyRole     = 'deli_staff_role';
  static const _keyName     = 'deli_staff_name';
  static const _keyMobile   = 'deli_staff_mobile';
  static const _keyState    = 'deli_staff_state';

  // ── Persistence helpers ──────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, value);
  }

  static Future<void> _saveStaffData({
    required int deliId,
    required int adminId,
    required String role,
    required String name,
    required String mobile,
    required String state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDeliId, deliId);
    await prefs.setInt(_keyAdminId, adminId);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyMobile, mobile);
    await prefs.setString(_keyState, state);
    await prefs.setBool(_keyLoggedIn, true);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyDeliId);
    await prefs.remove(_keyAdminId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyMobile);
    await prefs.remove(_keyState);
  }

  // ── Stored session getters ────────────────────────────────────────────────

  static Future<int?> getDeliId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDeliId);
  }

  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAdminId);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getStaffName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getStoredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobile);
  }

  static Future<String> getCompanyState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyState) ?? '';
  }

  /// Fetches org + bank details from admin table via admin_id stored at login.
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final adminId = await getAdminId();
      if (adminId == null) return null;
      final uri = Uri.parse(ApiConfig.adminInfo).replace(queryParameters: {'admin_id': adminId.toString()});
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      return data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Controller methods ────────────────────────────────────────────────────

  void setMobile(String number) {
    mobile.value = number;
  }

  /// Calls POST /api/auth/login with the stored mobile and provided OTP.
  /// Returns null on success, or an error message string on failure.
  Future<String?> verifyOtpViaApi(String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobile': mobile.value, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        await _saveStaffData(
          deliId:  (data['deli_id']  as num).toInt(),
          adminId: (data['admin_id'] as num).toInt(),
          role:    data['role']?.toString()   ?? '',
          name:    data['name']?.toString()   ?? '',
          mobile:  data['mobile']?.toString() ?? mobile.value,
          state:   data['state']?.toString()  ?? '',
        );
        return null; // success
      }

      return body['message']?.toString() ?? 'Login failed';
    } on Exception catch (e) {
      return 'Network error: $e';
    }
  }

  /// Quick local check used for offline / test flows (OTP == masterOtp).
  bool verifyOtpLocal(String otp) => otp == _masterOtp;

  void reset() {
    mobile.value = '';
    isLoading.value = false;
  }
}
