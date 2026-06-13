import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/staff_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  late final StaffController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(StaffController());
    _controller.fetchStaff();
  }

  @override
  void dispose() {
    Get.delete<StaffController>();
    super.dispose();
  }

  Future<void> _confirmDelete(Map<String, dynamic> staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Subadmin'),
        content: Text('Disable "${staff['name']}"? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await _controller.deleteStaff(staff['deli_id'] as int);
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Staff Management', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _controller.fetchStaff,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Subadmin'),
        onPressed: () async {
          await Get.toNamed(AppRoutes.staffForm);
          _controller.fetchStaff();
        },
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_controller.errorMessage.value!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _controller.fetchStaff, child: const Text('Retry')),
              ],
            ),
          );
        }
        final list = _controller.staffList;
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('No subadmins yet', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.fetchStaff,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final staff = list[index];
              final isAdmin = staff['role'] == 'admin';
              final isLocked = staff['is_locked'] == true;
              final perms = (staff['permissions'] as List?)?.cast<String>() ?? [];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? AppColors.primary
                        : isLocked
                            ? Colors.grey
                            : AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (staff['name'] as String? ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        color: isAdmin ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff['name'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('LOCKED', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                        ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ADMIN', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(staff['mobile'] as String? ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      if (!isAdmin && perms.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: perms.map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(p, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: isAdmin
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (action) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (action == 'edit') {
                              await Get.toNamed(AppRoutes.staffForm, arguments: staff);
                              _controller.fetchStaff();
                            } else if (action == 'lock') {
                              final err = await _controller.updateStaff(
                                deliId: staff['deli_id'] as int,
                                isLocked: !isLocked,
                              );
                              if (err != null) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
                                );
                              }
                            } else if (action == 'delete') {
                              await _confirmDelete(staff);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                            PopupMenuItem(
                              value: 'lock',
                              child: Row(children: [
                                Icon(isLocked ? Icons.lock_open_outlined : Icons.lock_outline, size: 18),
                                const SizedBox(width: 8),
                                Text(isLocked ? 'Unlock' : 'Lock'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.block_outlined, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Disable', style: TextStyle(color: Colors.redAccent))]),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
