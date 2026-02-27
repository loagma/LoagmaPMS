/// Simple central configuration for backend API access.
///
/// You can switch between **local** and **production** using a boolean
/// and still override via `--dart-define` when needed.
class ApiConfig {
  ApiConfig._();

  /// Whether to use production URLs instead of local.
  ///
  /// Set at build/run time with:
  ///   --dart-define=IS_PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: true,
  );

  /// Local base URL (emulator / device hitting your dev machine).
  /// 10.0.2.2 is Android emulator's "localhost". Replace with your LAN IP
  /// if you want a physical device to connect.
  static const String _localBaseUrl = 'http://10.0.2.2:8000';

  /// Production base URL (change to your real domain).
  static const String _productionBaseUrl = 'https://loagmapms-8oqk.onrender.com';

  /// Base URL for the backend (no trailing slash).
  ///
  /// Priority:
  /// 1) If `API_BASE_URL` is provided via --dart-define, it wins.
  /// 2) Otherwise, uses production or local based on [isProduction].
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: isProduction ? _productionBaseUrl : _localBaseUrl,
  );

  static const String _apiPrefix = '/api';

  /// Full base URL for JSON APIs.
  static String get apiBaseUrl => '$baseUrl$_apiPrefix';

  /// GET ${ApiConfig.apiBaseUrl}/health
  static String get health => '$apiBaseUrl/health';

  /// GET ${ApiConfig.apiBaseUrl}/products
  static String get products => '$apiBaseUrl/products';

  /// GET ${ApiConfig.apiBaseUrl}/boms
  static String get boms => '$apiBaseUrl/boms';

  /// POST ${ApiConfig.apiBaseUrl}/boms
  static String get createBom => '$apiBaseUrl/boms';

  /// GET ${ApiConfig.apiBaseUrl}/unit-types
  static String get unitTypes => '$apiBaseUrl/unit-types';

  /// GET ${ApiConfig.apiBaseUrl}/issues
  static String get issues => '$apiBaseUrl/issues';

  /// POST ${ApiConfig.apiBaseUrl}/issues
  static String get createIssue => '$apiBaseUrl/issues';

  /// GET ${ApiConfig.apiBaseUrl}/receives
  static String get receives => '$apiBaseUrl/receives';

  /// POST ${ApiConfig.apiBaseUrl}/receives
  static String get createReceive => '$apiBaseUrl/receives';

  /// GET ${ApiConfig.apiBaseUrl}/stock-vouchers
  static String get stockVouchers => '$apiBaseUrl/stock-vouchers';

  /// POST ${ApiConfig.apiBaseUrl}/stock-vouchers
  static String get createStockVoucher => '$apiBaseUrl/stock-vouchers';

  /// GET ${ApiConfig.apiBaseUrl}/vendor-products
  static String get vendorProducts => '$apiBaseUrl/vendor-products';

  /// GET/POST ${ApiConfig.apiBaseUrl}/suppliers
  static String get suppliers => '$apiBaseUrl/suppliers';

  /// GET/POST ${ApiConfig.apiBaseUrl}/supplier-products
  static String get supplierProducts => '$apiBaseUrl/supplier-products';

  /// GET/POST ${ApiConfig.apiBaseUrl}/purchase-orders
  static String get purchaseOrders => '$apiBaseUrl/purchase-orders';
}
