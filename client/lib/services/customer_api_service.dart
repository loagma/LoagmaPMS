import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/customer_model.dart';
import '../models/party_result.dart';

class CustomerApiService {
  CustomerApiService._();

  // Nominatim reverse geocode cache keyed by "lat,lng"
  static final Map<String, ({String city, String state})> _geoCache = {};

  /// Reverse geocodes lat/lng using OpenStreetMap Nominatim (no API key needed).
  /// Returns (city, state) — empty strings if unavailable.
  static Future<({String city, String state})> reverseGeocode(
      String lat, String lng) async {
    final key = '$lat,$lng';
    if (_geoCache.containsKey(key)) return _geoCache[key]!;
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'LoagmaPMS/1.0',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return (city: '', state: '');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};
      final city = (addr['city'] ?? addr['town'] ?? addr['district'] ?? addr['county'] ?? '').toString().trim();
      final state = (addr['state'] ?? '').toString().trim();
      final result = (city: city, state: state);
      _geoCache[key] = result;
      return result;
    } catch (_) {
      return (city: '', state: '');
    }
  }

  /// Enriches a Customer with city/state from reverse geocode if they are empty
  /// but lat/lng are present.
  static Future<Customer> enrichWithGeo(Customer customer) async {
    final needsGeo = (customer.city == null || customer.city!.isEmpty) &&
        (customer.state == null || customer.state!.isEmpty) &&
        customer.latitude != null &&
        customer.latitude!.isNotEmpty &&
        customer.longitude != null &&
        customer.longitude!.isNotEmpty;
    if (!needsGeo) return customer;

    final lat = double.tryParse(customer.latitude ?? '');
    final lng = double.tryParse(customer.longitude ?? '');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return customer;

    final geo = await reverseGeocode(lat.toString(), lng.toString());
    if (geo.city.isEmpty && geo.state.isEmpty) return customer;

    return Customer(
      id: customer.id,
      name: customer.name,
      shopName: customer.shopName,
      email: customer.email,
      contactNumber: customer.contactNumber,
      alternatePhone: customer.alternatePhone,
      gstNo: customer.gstNo,
      panNo: customer.panNo,
      addressLine1: customer.addressLine1,
      city: geo.city.isNotEmpty ? geo.city : customer.city,
      state: geo.state.isNotEmpty ? geo.state : customer.state,
      country: customer.country,
      pincode: customer.pincode,
      notes: customer.notes,
      latitude: customer.latitude,
      longitude: customer.longitude,
      dob: customer.dob,
      registerDate: customer.registerDate,
      status: customer.status,
      createdAt: customer.createdAt,
    );
  }

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

      final customer = Customer.fromJson(raw);
      return enrichWithGeo(customer);
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
      // Geocode in parallel (capped — search results are ≤50)
      final futures = items
          .whereType<Map<String, dynamic>>()
          .map((e) async {
            final customer = await enrichWithGeo(Customer.fromJson(e));
            return PartyResult(
              id: customer.id,
              name: customer.name,
              phone: customer.contactNumber,
              shopName: customer.shopName,
              code: customer.id.toString(),
              state: customer.state,
            );
          })
          .toList();
      return Future.wait(futures);
    } catch (_) {
      return [];
    }
  }
}
