import 'package:get/get.dart';

import '../screens/auth/dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/modules/bom_list_screen.dart';
import '../screens/modules/issue_to_production_list_screen.dart';
import '../screens/modules/receive_from_production_screen.dart';

/// Central route names. Use these instead of raw strings.
abstract class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String otp = '/otp';
  static const String dashboard = '/dashboard';
  static const String issueToProduction = '/issue-to-production';
  static const String receiveFromProduction = '/receive-from-production';
  static const String bom = '/bom';
}

/// All app routes. Used by [GetMaterialApp] in [main.dart].
final List<GetPage<dynamic>> appPages = [
  GetPage(
    name: AppRoutes.login,
    page: () => LoginScreen(),
  ),
  GetPage(
    name: AppRoutes.otp,
    page: () => const OtpScreen(),
  ),
  GetPage(
    name: AppRoutes.dashboard,
    page: () => const DashboardScreen(),
  ),
  GetPage(
    name: AppRoutes.issueToProduction,
    page: () => const IssueToProductionListScreen(),
  ),
  GetPage(
    name: AppRoutes.receiveFromProduction,
    page: () => const ReceiveFromProductionScreen(),
  ),
  GetPage(
    name: AppRoutes.bom,
    page: () => const BomListScreen(),
  ),
];
