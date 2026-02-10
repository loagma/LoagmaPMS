import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/bom_list_controller.dart';
import '../../models/bom_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'bom_screen.dart';

class BomListScreen extends StatelessWidget {
  const BomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BomListController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Bill of Materials',
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
                  'Loading BOMs...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.boms.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ContentCard(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'No BOMs created yet.',
                actionLabel: 'Create BOM',
                onAction: () => Get.to(() => const BomScreen()),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ContentCard(
            title: 'Existing BOMs',
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final bom = controller.boms[index];
                return _BomListTile(bom: bom);
              },
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.primaryLight,
              ),
              itemCount: controller.boms.length,
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const BomScreen()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _BomListTile extends StatelessWidget {
  final BomMaster bom;

  const _BomListTile({required this.bom});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      title: Text(
        'BOM ${bom.bomVersion}',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      subtitle: Text(
        'Status: ${bom.status} • Product ID: ${bom.productId}',
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
        // TODO: Open BOM details / edit screen when backend supports it.
      },
    );
  }
}

