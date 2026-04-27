/// Simple central configuration for backend API access.
///
/// You can switch between **local** and **production** using a boolean
/// and still override via `--dart-define` when needed.
class ApiConfig {
  ApiConfig._();

//   static const String _localBaseUrl = 'http://192.168.1.4:8000';
  static const String _localBaseUrl = 'http://10.112.146.228:8000';
  static const String _productionBaseUrl = 'https://loagmapms-hd5u.onrender.com';

  /// Pass --dart-define=USE_LOCAL=true to hit local server during dev.
  /// Default is production.
  static const bool _useLocal = bool.fromEnvironment('USE_LOCAL', defaultValue: true);
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl =>
      _envOverride.isNotEmpty ? _envOverride : (_useLocal ? _localBaseUrl : _productionBaseUrl);

  static const String _apiPrefix = '/api';

  /// Full base URL for JSON APIs.
  static String get apiBaseUrl => '$baseUrl$_apiPrefix';

  /// GET ${ApiConfig.apiBaseUrl}/health
  static String get health => '$apiBaseUrl/health';

  /// POST ${ApiConfig.apiBaseUrl}/auth/login  (deli_staff login)
  static String get authLogin => '$apiBaseUrl/auth/login';

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

  /// GET/POST ${ApiConfig.apiBaseUrl}/customers
  static String get customers => '$apiBaseUrl/customers';

  /// GET ${ApiConfig.apiBaseUrl}/business-types
  static String get businessTypes => '$apiBaseUrl/business-types';

  /// GET ${ApiConfig.apiBaseUrl}/departments
  static String get departments => '$apiBaseUrl/departments';

  /// GET ${ApiConfig.apiBaseUrl}/users
  static String get users => '$apiBaseUrl/users';

  /// GET/POST ${ApiConfig.apiBaseUrl}/supplier-products
  static String get supplierProducts => '$apiBaseUrl/supplier-products';

  /// GET/POST ${ApiConfig.apiBaseUrl}/purchase-orders
  static String get purchaseOrders => '$apiBaseUrl/purchase-orders';

  /// GET ${ApiConfig.apiBaseUrl}/purchase-vouchers
  static String get purchaseVouchers => '$apiBaseUrl/purchase-vouchers';

  /// POST ${ApiConfig.apiBaseUrl}/purchase-vouchers
  static String get createPurchaseVoucher => '$apiBaseUrl/purchase-vouchers';

  /// GET/POST ${ApiConfig.apiBaseUrl}/purchase-returns
  static String get purchaseReturns => '$apiBaseUrl/purchase-returns';

  /// GET ${ApiConfig.apiBaseUrl}/purchase-returns/series
  static String get purchaseReturnSeries =>
      '$apiBaseUrl/purchase-returns/series';

  /// POST ${ApiConfig.apiBaseUrl}/purchase-returns
  static String get createPurchaseReturn => '$apiBaseUrl/purchase-returns';

  /// GET/POST ${ApiConfig.apiBaseUrl}/taxes
  static String get taxes => '$apiBaseUrl/taxes';

  /// GET/POST ${ApiConfig.apiBaseUrl}/product-taxes
  static String get productTaxes => '$apiBaseUrl/product-taxes';

  /// GET/POST ${ApiConfig.apiBaseUrl}/hsn-codes
  static String get hsnCodes => '$apiBaseUrl/hsn-codes';

  /// GET/POST ${ApiConfig.apiBaseUrl}/product-packages
  static String get productPackages => '$apiBaseUrl/product-packages';

  /// GET/POST ${ApiConfig.apiBaseUrl}/categories
  static String get categories => '$apiBaseUrl/categories';

  /// GET/POST ${ApiConfig.apiBaseUrl}/sales-orders
  static String get salesOrders => '$apiBaseUrl/sales-orders';

  /// GET/POST ${ApiConfig.apiBaseUrl}/sales-invoices
  static String get salesInvoices => '$apiBaseUrl/sales-invoices';

  /// POST ${ApiConfig.apiBaseUrl}/sales-invoices
  static String get createSalesInvoice => '$apiBaseUrl/sales-invoices';

  /// GET/POST ${ApiConfig.apiBaseUrl}/sales-returns
  static String get salesReturns => '$apiBaseUrl/sales-returns';

  /// GET ${ApiConfig.apiBaseUrl}/sales-returns/series
  static String get salesReturnSeries => '$apiBaseUrl/sales-returns/series';

  /// POST ${ApiConfig.apiBaseUrl}/sales-returns
  static String get createSalesReturn => '$apiBaseUrl/sales-returns';
}
