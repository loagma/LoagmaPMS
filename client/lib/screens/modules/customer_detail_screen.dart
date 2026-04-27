import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/customer_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Customer Details',
        subtitle: 'Loagma',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Edit Customer',
            onPressed: () async {
              final result = await Get.to(
                () => CustomerFormScreen(customerId: customer.id),
              );
              if (result == true) Get.back(result: true);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(customer: customer),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone_outlined,
              children: [
                _InfoRow(label: 'Phone', value: customer.contactNumber),
                _InfoRow(label: 'Alternate Phone', value: customer.alternatePhone),
                _InfoRow(label: 'Email', value: customer.email),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Address',
              icon: Icons.location_on_outlined,
              children: [
                _InfoRow(label: 'Address', value: customer.addressLine1),
                _InfoRow(label: 'City', value: customer.city),
                _InfoRow(label: 'State', value: customer.state),
                _InfoRow(label: 'Country', value: customer.country),
                _InfoRow(label: 'Pincode', value: customer.pincode),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Tax & Identity',
              icon: Icons.receipt_long_outlined,
              children: [
                _InfoRow(label: 'GST No', value: customer.gstNo),
                _InfoRow(label: 'PAN No', value: customer.panNo),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Other Details',
              icon: Icons.info_outline_rounded,
              children: [
                _InfoRow(label: 'Date of Birth', value: customer.dob),
                _InfoRow(label: 'Register Date', value: customer.registerDate),
                _InfoRow(label: 'Customer ID', value: customer.id.toString()),
                if (customer.notes != null && customer.notes!.isNotEmpty)
                  _InfoRow(label: 'Notes', value: customer.notes),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Edit Customer'),
        onPressed: () async {
          final result = await Get.to(
            () => CustomerFormScreen(customerId: customer.id),
          );
          if (result == true) Get.back(result: true);
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Customer customer;

  const _HeaderCard({required this.customer});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.grey;
      case 'BLOCKED':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(customer.status);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (customer.shopName != null && customer.shopName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.shopName!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      customer.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final nonEmpty = children.whereType<_InfoRow>().where((r) => r.value != null && r.value!.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
