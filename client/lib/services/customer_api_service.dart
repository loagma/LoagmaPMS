import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/customer_model.dart';
import '../models/party_result.dart';

class CustomerApiService {
  CustomerApiService._();

  static Future<List<Customer>> fetchCustomers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.customers).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return [];
      }

      final List items = data['data'] ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(Customer.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Customer?> fetchCustomerById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.customers}/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return null;
      }

      final raw = data['data'];
      if (raw is! Map<String, dynamic>) {
        return null;
      }

      return Customer.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<List<PartyResult>> searchPartyResults({
    String query = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.customers).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return [];
      }

      final List items = data['data'] ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final customer = Customer.fromJson(e);
            return PartyResult(
              id: customer.id,
              name: customer.name,
              phone: customer.contactNumber,
              shopName: customer.shopName,
              code: customer.id.toString(),
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
