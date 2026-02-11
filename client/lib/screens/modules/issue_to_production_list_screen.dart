import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/issue_to_production_list_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ContentCard(
              child: EmptyState(
                icon: Icons.outbox_rounded,
                message: 'No issues to production created yet.',
                actionLabel: 'Create Issue',
                onAction: () => Get.to(() => const IssueToProductionScreen()),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ContentCard(
            title: 'Existing Issues',
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final issue = controller.issues[index];
                return _IssueListTile(issue: issue);
              },
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.primaryLight,
              ),
              itemCount: controller.issues.length,
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const IssueToProductionScreen()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _IssueListTile extends StatelessWidget {
  final IssueToProductionSummary issue;

  const _IssueListTile({required this.issue});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      title: Text(
        issue.finishedProductName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      subtitle: Text(
        'Status: ${issue.status} • Date: ${issue.date}',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primaryDark,
      ),
      onTap: () {
        // TODO: Navigate to view/edit specific issue when backend is ready.
      },
    );
  }
}

