import 'package:get/get.dart';

import '../screens/auth/dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/modules/bom_screen.dart';
import '../screens/modules/issue_to_production_screen.dart';
import '../screens/modules/receive_from_production_screen.dart';
import '../screens/modules/stock_voucher_screen.dart';
import '../screens/modules/inventory_list_screen.dart';
import '../screens/modules/reports_screen.dart';
import '../screens/modules/supplier_list_screen.dart';
import '../screens/modules/supplier_form_screen.dart';
import '../screens/modules/supplier_product_form_screen.dart';
import '../screens/modules/supplier_product_list_screen.dart';
import '../screens/modules/supplier_list_for_products_screen.dart';
import '../screens/modules/purchase_order_list_screen.dart';
import '../screens/modules/purchase_order_form_screen.dart';

/// Central route names. Use these instead of raw strings.
abstract class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String otp = '/otp';
  static const String dashboard = '/dashboard';
  static const String issueToProduction = '/issue-to-production';
  static const String receiveFromProduction = '/receive-from-production';
  static const String bom = '/bom';
  static const String stockVoucher = '/stock-voucher';
  static const String inventory = '/inventory';
  static const String reports = '/reports';
  static const String suppliers = '/suppliers';
  static const String supplierForm = '/supplier-form';
  static const String supplierProducts = '/supplier-products';
  static const String supplierProductForm = '/supplier-product-form';
  static const String supplierProductList = '/supplier-product-list';
  static const String supplierProductListForSupplier = '/supplier-product-list-for-supplier';
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrderForm = '/purchase-order-form';
}

/// All app routes. Used by [GetMaterialApp] in [main.dart].
final List<GetPage<dynamic>> appPages = [
  GetPage(name: AppRoutes.login, page: () => LoginScreen()),
  GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),
  GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
  GetPage(
    name: AppRoutes.issueToProduction,
    page: () => const IssueToProductionScreen(),
  ),
  GetPage(
    name: AppRoutes.receiveFromProduction,
    page: () => const ReceiveFromProductionScreen(),
  ),
  GetPage(name: AppRoutes.bom, page: () => const BomScreen()),
  GetPage(name: AppRoutes.stockVoucher, page: () => const StockVoucherScreen()),
  GetPage(name: AppRoutes.inventory, page: () => const InventoryListScreen()),
  GetPage(name: AppRoutes.reports, page: () => const ReportsScreen()),
  GetPage(name: AppRoutes.suppliers, page: () => const SupplierListScreen()),
  GetPage(name: AppRoutes.supplierForm, page: () => const SupplierFormScreen()),
  GetPage(
    name: AppRoutes.supplierProducts,
    page: () => const SupplierProductFormScreen(),
  ),
  GetPage(
    name: AppRoutes.supplierProductForm,
    page: () => const SupplierProductFormScreen(),
  ),
  GetPage(
    name: AppRoutes.supplierProductList,
    page: () => const SupplierListForProductsScreen(),
  ),
  GetPage(
    name: AppRoutes.supplierProductListForSupplier,
    page: () => const SupplierProductListScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseOrders,
    page: () => const PurchaseOrderListScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseOrderForm,
    page: () => const PurchaseOrderFormScreen(),
  ),
];
