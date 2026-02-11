import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/issue_to_production_list_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'issue_to_production_details_screen.dart';
import 'issue_to_production_screen.dart';

class IssueToProductionListScreen extends StatelessWidget {
  const IssueToProductionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IssueToProductionListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Issue to Production',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.fetchIssues,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.issues.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading issues...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.issues.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchIssues,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ContentCard(
                    child: EmptyState(
                      icon: Icons.outbox_rounded,
                      message: 'No issues to production created yet.',
                      actionLabel: 'Create Issue',
                      onAction: () async {
                        final result = await Get.to(
                          () => const IssueToProductionScreen(),
                        );
                        if (result == true) {
                          controller.fetchIssues();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchIssues,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.issues.length,
            itemBuilder: (context, index) {
              final issue = controller.issues[index];
              return _IssueCard(
                issue: issue,
                onTap: () async {
                  final result = await Get.to(
                    () =>
                        IssueToProductionDetailsScreen(issueId: issue.issueId),
                  );
                  if (result == true) {
                    controller.fetchIssues();
                  }
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const IssueToProductionScreen());
          if (result == true) {
            controller.fetchIssues();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueToProductionSummary issue;
  final VoidCallback onTap;

  const _IssueCard({required this.issue, required this.onTap});

  Color _getStatusColor() {
    switch (issue.status) {
      case 'DRAFT':
        return Colors.blue;
      case 'ISSUED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.finishedProductName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            issue.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          issue.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
