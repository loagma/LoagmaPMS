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
import '../screens/modules/purchase_order_form_screen.dart';
import '../screens/modules/purchase_voucher_list_screen.dart';
import '../screens/modules/purchase_voucher_screen.dart';
import '../screens/modules/purchase_return_list_screen.dart';
import '../screens/modules/purchase_return_form_screen.dart';
import '../screens/modules/tax_list_screen.dart';
import '../screens/modules/tax_form_screen.dart';
import '../screens/modules/product_tax_form_screen.dart';
import '../screens/modules/products_home_screen.dart';
import '../screens/modules/product_list_screen.dart';
import '../screens/modules/product_form_screen.dart';
import '../screens/modules/hsn_code_list_screen.dart';
import '../screens/modules/hsn_code_form_screen.dart';
import '../screens/modules/product_package_list_screen.dart';
import '../screens/modules/product_package_form_screen.dart';
import '../screens/modules/category_list_screen.dart';
import '../screens/modules/category_form_screen.dart';
import '../screens/modules/product_module_reports_screen.dart';

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
  static const String productModuleReports = '/reports/product-module';
  static const String suppliers = '/suppliers';
  static const String supplierForm = '/supplier-form';
  static const String supplierProducts = '/supplier-products';
  static const String supplierProductForm = '/supplier-product-form';
  static const String supplierProductList = '/supplier-product-list';
  static const String supplierProductListForSupplier = '/supplier-product-list-for-supplier';
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrderForm = '/purchase-order-form';
  static const String purchaseVoucherList = '/purchase-vouchers';
  static const String purchaseVoucher = '/purchase-voucher';
  static const String purchaseReturnList = '/purchase-returns';
  static const String purchaseReturnForm = '/purchase-return';
  static const String taxList = '/taxes';
  static const String taxForm = '/tax-form';
  static const String productTaxForm = '/product-tax-form';
  static const String products = '/products';
  static const String productList = '/product-list';
  static const String productForm = '/product-form';
  static const String hsnCodeList = '/hsn-codes';
  static const String hsnCodeForm = '/hsn-code-form';
  static const String productPackageList = '/product-packages';
  static const String productPackageForm = '/product-package-form';
  static const String categoryList = '/categories';
  static const String categoryForm = '/category-form';
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
  GetPage(
    name: AppRoutes.productModuleReports,
    page: () => const ProductModuleReportsScreen(),
  ),
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
    page: () => const PurchaseOrderFormScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseOrderForm,
    page: () => const PurchaseOrderFormScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseVoucherList,
    page: () => const PurchaseVoucherListScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseVoucher,
    page: () => PurchaseVoucherScreen(
      voucherId: Get.arguments is int ? Get.arguments as int? : null,
    ),
  ),
  GetPage(
    name: AppRoutes.purchaseReturnList,
    page: () => const PurchaseReturnListScreen(),
  ),
  GetPage(
    name: AppRoutes.purchaseReturnForm,
    page: () => PurchaseReturnFormScreen(
      returnId: Get.arguments is int ? Get.arguments as int? : null,
    ),
  ),
  GetPage(
    name: AppRoutes.taxList,
    page: () => const TaxListScreen(),
  ),
  GetPage(
    name: AppRoutes.taxForm,
    page: () => TaxFormScreen(taxId: Get.arguments is int ? Get.arguments as int? : null),
  ),
  GetPage(
    name: AppRoutes.productTaxForm,
    page: () => const ProductTaxFormScreen(),
  ),
  GetPage(
    name: AppRoutes.products,
    page: () => const ProductsHomeScreen(),
  ),
  GetPage(
    name: AppRoutes.productList,
    page: () => const ProductListScreen(),
  ),
  GetPage(
    name: AppRoutes.productForm,
    page: () => ProductFormScreen(
      productId: Get.arguments is int ? Get.arguments as int? : null,
    ),
  ),
  GetPage(
    name: AppRoutes.hsnCodeList,
    page: () => const HsnCodeListScreen(),
  ),
  GetPage(
    name: AppRoutes.hsnCodeForm,
    page: () => HsnCodeFormScreen(
      hsnId: Get.arguments is int ? Get.arguments as int? : null,
    ),
  ),
  GetPage(
    name: AppRoutes.productPackageList,
    page: () => const ProductPackageListScreen(),
  ),
  GetPage(
    name: AppRoutes.productPackageForm,
    page: () {
      final args = Get.arguments;
      int? productId;
      int? packageId;

      if (args is int) {
        productId = args;
      } else if (args is Map) {
        productId = args['productId'] as int?;
        packageId = args['packageId'] as int?;
      }

      return ProductPackageFormScreen(
        productId: productId,
        packageId: packageId,
      );
    },
  ),
  GetPage(
    name: AppRoutes.categoryList,
    page: () => const CategoryListScreen(),
  ),
  GetPage(
    name: AppRoutes.categoryForm,
    page: () => const CategoryFormScreen(),
  ),
];
