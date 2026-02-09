import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';

class BomScreen extends StatelessWidget {
  const BomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('BOM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: const Center(
        child: Text(
          'Bill of Materials module\n(implement details here)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

