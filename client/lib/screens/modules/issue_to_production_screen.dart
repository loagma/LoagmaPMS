import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';

class IssueToProductionScreen extends StatelessWidget {
  const IssueToProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue to production'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: const Center(
        child: Text(
          'Issue to production module\n(implement details here)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

