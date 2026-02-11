import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/bom_details_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'bom_screen.dart';

class BomDetailsScreen extends StatelessWidget {
  final int bomId;

  const BomDetailsScreen({super.key, required this.bomId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BomDetailsController(bomId: bomId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'BOM Details',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          Obx(() {
            final bom = controller.bomDetails.value;
            if (bom != null && bom['status'] != 'LOCKED') {
              return IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Edit BOM',
                onPressed: () {
                  Get.to(() => BomScreen(bomId: bomId))?.then((result) {
                    if (result == true) {
                      controller.fetchBomDetails();
                    }
                  });
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
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
                  'Loading BOM details...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.bomDetails.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ContentCard(
                child: EmptyState(
                  icon: Icons.error_outline,
                  message: 'BOM not found',
                  actionLabel: 'Go Back',
                  onAction: () => Get.back(),
                ),
              ),
            ),
          );
        }

        final bom = controller.bomDetails.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BomHeaderCard(bom: bom),
              const SizedBox(height: 16),
              _RawMaterialsCard(items: controller.bomItems),
            ],
          ),
        );
      }),
    );
  }
}

class _BomHeaderCard extends StatelessWidget {
  final Map<String, dynamic> bom;

  const _BomHeaderCard({required this.bom});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'LOCKED':
        return Colors.orange;
      case 'DRAFT':
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'LOCKED':
        return Icons.lock;
      case 'DRAFT':
      default:
        return Icons.edit_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = bom['status']?.toString() ?? 'DRAFT';
    final statusColor = _getStatusColor(status);

    return ContentCard(
      title: 'Finished Product',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bom['product_name']?.toString() ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Product ID: ${bom['product_id']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'BOM Version',
            value: bom['bom_version']?.toString() ?? '-',
            icon: Icons.tag,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'BOM ID',
            value: '#${bom['bom_id']}',
            icon: Icons.numbers,
          ),
          if (bom['remarks'] != null &&
              bom['remarks'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Remarks',
              value: bom['remarks'].toString(),
              icon: Icons.note,
            ),
          ],
          if (bom['created_at'] != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Created',
              value: _formatDate(bom['created_at'].toString()),
              icon: Icons.calendar_today,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RawMaterialsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _RawMaterialsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: 'Raw Materials (${items.length})',
      child: items.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No raw materials found',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _RawMaterialItem(item: item, index: index);
              },
            ),
    );
  }
}

class _RawMaterialItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _RawMaterialItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity_per_unit']?.toString() ?? '0';
    final unit = item['unit_type']?.toString() ?? '';
    final wastage = item['wastage_percent']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Material ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${item['raw_material_id']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['raw_material_name']?.toString() ?? 'Unknown Material',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailChip(
                  icon: Icons.scale,
                  label: 'Quantity',
                  value: '$quantity $unit',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailChip(
                  icon: Icons.warning_amber,
                  label: 'Wastage',
                  value: '$wastage%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
