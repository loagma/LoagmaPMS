import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/hsn_code_list_controller.dart';
import '../../controllers/hsn_code_form_controller.dart';
import '../../models/hsn_code_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'hsn_code_form_screen.dart';

class HsnCodeListScreen extends StatelessWidget {
  const HsnCodeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HsnCodeListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'HSN Codes',
        subtitle: 'Manage HSN master',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: () =>
                  controller.toggleActiveFilter(!controller.showOnlyActive.value),
              icon: Icon(
                controller.showOnlyActive.value
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
              ),
              label: Text(
                controller.showOnlyActive.value ? 'Active only' : 'All',
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshCodes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by HSN code...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: controller.clearSearch,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: controller.onSearch,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.codes.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading HSN codes...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.codes.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshCodes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ContentCard(
                          child: EmptyState(
                            icon: Icons.qr_code_rounded,
                            message: controller.searchQuery.value.isNotEmpty
                                ? 'No HSN codes found for \"${controller.searchQuery.value}\"'
                                : 'No HSN codes added yet.',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshCodes,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.codes.length,
                  itemBuilder: (context, index) {
                    final code = controller.codes[index];
                    return _HsnCard(
                      code: code,
                      onTap: () async {
                        final result = await Get.to(
                          () => HsnCodeFormScreen(hsnId: code.id),
                          binding: BindingsBuilder(() {
                            Get.put(HsnCodeFormController(hsnId: code.id));
                          }),
                        );
                        if (result == true) controller.refreshCodes();
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const HsnCodeFormScreen());
          if (result == true) controller.refreshCodes();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _HsnCard extends StatelessWidget {
  final HsnCode code;
  final VoidCallback onTap;

  const _HsnCard({required this.code, required this.onTap});

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
                height: 50,
                decoration: BoxDecoration(
                  color: code.isActive
                      ? AppColors.primary
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: code.isActive
                            ? Colors.green
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
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

