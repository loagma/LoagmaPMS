import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ReceiveFromProductionScreen extends StatelessWidget {
  const ReceiveFromProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Receive from Production',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ContentCard(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              message:
                  'Receive from production module\n(implement details here)',
            ),
          ),
        ),
      ),
    );
  }
}
