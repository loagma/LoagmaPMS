import 'package:get/get.dart';

class IssueToProductionSummary {
  final int id;
  final String finishedProductName;
  final String status;
  final String date;

  IssueToProductionSummary({
    required this.id,
    required this.finishedProductName,
    required this.status,
    required this.date,
  });
}

class IssueToProductionListController extends GetxController {
  final issues = <IssueToProductionSummary>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // TODO: Wire up API for listing issues to production when backend is ready.
  }
}

