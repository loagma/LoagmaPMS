import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/sales_return_list_controller.dart';
import '../../models/sales_return_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_return_form_screen.dart';

class SalesReturnListScreen extends StatefulWidget {
  const SalesReturnListScreen({super.key});

  @override
  State<SalesReturnListScreen> createState() => _SalesReturnListScreenState();
}

class _SalesReturnListScreenState extends State<SalesReturnListScreen> {
  late final SalesReturnListController controller;
  bool _filtersExpanded = false;
  String _localFrom = '';
  String _localTo = '';
  String _localStatus = '';

  static const _statusOptions = ['', 'DRAFT', 'POSTED', 'CANCELLED'];
  static const _statusLabels = {
    '': 'All',
    'DRAFT': 'Draft',
    'POSTED': 'Posted',
    'CANCELLED': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    controller = Get.put(SalesReturnListController());
  }

  bool get _hasActiveFilters =>
      _localFrom.isNotEmpty || _localTo.isNotEmpty || _localStatus.isNotEmpty;

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final initial = isFrom
        ? (_localFrom.isNotEmpty ? DateTime.tryParse(_localFrom) ?? DateTime.now() : DateTime.now())
        : (_localTo.isNotEmpty ? DateTime.tryParse(_localTo) ?? DateTime.now() : DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted = DateFormat('yyyy-MM-dd').format(picked);
    setState(() {
      if (isFrom) {
        _localFrom = formatted;
      } else {
        _localTo = formatted;
      }
    });
  }

  void _applyFilters() {
    controller.fetchReturns(
      status: _localStatus.isEmpty ? null : _localStatus,
      fromDate: _localFrom.isEmpty ? null : _localFrom,
      toDate: _localTo.isEmpty ? null : _localTo,
    );
    setState(() => _filtersExpanded = false);
  }

  void _resetFilters() {
    setState(() {
      _localFrom = '';
      _localTo = '';
      _localStatus = '';
      _filtersExpanded = false;
    });
    controller.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Sales Returns',
        subtitle: 'Track returned goods and credit notes',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter toggle row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by return number or customer…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: controller.clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: controller.onSearch,
                  )),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: _hasActiveFilters ? Colors.orange : AppColors.textMuted,
                      ),
                      tooltip: 'Filters',
                      onPressed: () =>
                          setState(() => _filtersExpanded = !_filtersExpanded),
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Collapsible filter bar
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _filtersExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DateButton(
                                  label: _localFrom.isEmpty ? 'From Date' : _localFrom,
                                  icon: Icons.calendar_today_outlined,
                                  onTap: () => _pickDate(context, isFrom: true),
                                  isSet: _localFrom.isNotEmpty,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DateButton(
                                  label: _localTo.isEmpty ? 'To Date' : _localTo,
                                  icon: Icons.calendar_today_outlined,
                                  onTap: () => _pickDate(context, isFrom: false),
                                  isSet: _localTo.isNotEmpty,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _localStatus,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  items: _statusOptions
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              _statusLabels[s]!,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _localStatus = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _applyFilters,
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Apply'),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: _resetFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textMuted,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.returns.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading returns…',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (controller.returns.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 300,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ContentCard(
                          child: EmptyState(
                            icon: Icons.assignment_return_outlined,
                            message: 'No sales returns found.',
                            actionLabel: 'Create Return',
                            onAction: () async {
                              final result =
                                  await Get.to(() => const SalesReturnFormScreen());
                              if (result == true) controller.refresh();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: controller.returns.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.returns.length) {
                      if (!controller.isLoading.value) {
                        controller.fetchReturns(loadMore: true);
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final ret = controller.returns[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReturnCard(
                        return_: ret,
                        statusColor: controller.statusColor(ret.status),
                        onTap: () {
                          Get.to(
                            () => SalesReturnFormScreen(
                              returnId: ret.id,
                              startInViewOnly: true,
                            ),
                          )?.then((_) => controller.refresh());
                        },
                        onDelete: (ctx) =>
                            _showDeleteDialog(ctx, controller, ret),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Get.to(() => const SalesReturnFormScreen())?.then((_) {
              controller.refresh();
            }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Return'),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

void _showDeleteDialog(
  BuildContext context,
  SalesReturnListController controller,
  SalesReturnSummary return_,
) {
  final isDraft = return_.status.toUpperCase() == 'DRAFT';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDraft ? 'Delete sales return?' : 'Cannot delete'),
      content: Text(
        isDraft
            ? 'Delete return ${return_.docNumber}? This cannot be undone.'
            : 'Only DRAFT returns can be deleted. This return is ${return_.status}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        if (isDraft)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteSalesReturn(return_);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
      ],
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSet;

  const _DateButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: isSet ? AppColors.primary : AppColors.textMuted),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSet ? AppColors.primary : AppColors.textMuted,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSet
              ? AppColors.primary
              : AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _ReturnCard extends StatelessWidget {
  final SalesReturnSummary return_;
  final Color statusColor;
  final VoidCallback onTap;
  final void Function(BuildContext)? onDelete;

  const _ReturnCard({
    required this.return_,
    required this.statusColor,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String formatDocDate(String raw) {
      if (raw.isEmpty) return '-';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            return_.docNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            return_.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${return_.customerName ?? '-'}  |  ${formatDocDate(return_.docDate)}  |  ₹ ${return_.totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (return_.status == 'DRAFT')
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => onDelete?.call(context),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              IconButton(
                tooltip: 'Open',
                onPressed: onTap,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
