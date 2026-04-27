import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/sales_order_list_controller.dart';
import '../../models/sales_order_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_order_form_screen.dart';

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  late final SalesOrderListController controller;
  bool _filtersExpanded = false;
  String _localFrom = '';
  String _localTo = '';
  String _localStatus = '';

  static const _statusOptions = [
    '',
    'DRAFT',
    'CONFIRMED',
    'PARTIALLY_INVOICED',
    'CLOSED',
    'CANCELLED',
  ];
  static const _statusLabels = {
    '': 'All',
    'DRAFT': 'Draft',
    'CONFIRMED': 'Confirmed',
    'PARTIALLY_INVOICED': 'Partially Invoiced',
    'CLOSED': 'Closed',
    'CANCELLED': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    controller = Get.put(SalesOrderListController());
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
    setState(() {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      if (isFrom) {
        _localFrom = formatted;
      } else {
        _localTo = formatted;
      }
    });
  }

  void _applyFilters() {
    controller.fetchSalesOrders(
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
        title: 'Sales Orders',
        subtitle: 'Loagma',
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
                      hintText: 'Search by SO number…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: controller.clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
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
                                  onChanged: (v) => setState(() => _localStatus = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _applyFilters,
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              if (controller.isLoading.value && controller.salesOrders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading sales orders…',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (controller.salesOrders.isEmpty) {
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
                            icon: Icons.shopping_cart_outlined,
                            message: 'No sales orders found.',
                            actionLabel: 'Create Sales Order',
                            onAction: () =>
                                Get.to(() => const SalesOrderFormScreen())?.then((_) {
                              controller.refresh();
                            }),
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
                  itemCount: controller.salesOrders.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.salesOrders.length) {
                      if (!controller.isLoading.value) {
                        controller.fetchSalesOrders(loadMore: true);
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final so = controller.salesOrders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SOCard(
                        so: so,
                        statusColor: controller.statusColor(so.status),
                        onTap: () {
                          if (so.id != null) {
                            Get.to(
                              () => SalesOrderFormScreen(
                                soId: so.id,
                                startInViewOnly: true,
                              ),
                            )?.then((_) => controller.refresh());
                          }
                        },
                        onDeleteOrCancel: (ctx) =>
                            _showDeleteCancelDialog(ctx, controller, so),
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
        onPressed: () => Get.to(() => const SalesOrderFormScreen())?.then((_) {
          controller.refresh();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(''),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

void _showDeleteCancelDialog(
  BuildContext context,
  SalesOrderListController controller,
  SalesOrder so,
) {
  final isDraft = so.status.toUpperCase() == 'DRAFT';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDraft ? 'Delete sales order?' : 'Cancel sales order?'),
      content: Text(
        isDraft
            ? 'Delete ${so.soNumber}? This cannot be undone.'
            : 'Cancel ${so.soNumber}? The order will be marked as CANCELLED.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await controller.deleteOrCancelSalesOrder(so);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(isDraft ? 'Delete' : 'Cancel'),
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

class _SOCard extends StatelessWidget {
  final SalesOrder so;
  final Color statusColor;
  final VoidCallback onTap;
  final void Function(BuildContext)? onDeleteOrCancel;

  const _SOCard({
    required this.so,
    required this.statusColor,
    required this.onTap,
    this.onDeleteOrCancel,
  });

  @override
  Widget build(BuildContext context) {
    String _formatDocDate(String raw) {
      if (raw.isEmpty) return '-';
      try {
        final dt = DateTime.tryParse(raw);
        if (dt == null) return raw;
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        return raw;
      }
    }

    return Card(
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          so.soNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          so.customerName ?? 'Customer #${so.customerId}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      so.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (onDeleteOrCancel != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => onDeleteOrCancel!(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDocDate(so.docDate),
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  if (so.totalAmount != null)
                    Text(
                      '₹ ${so.totalAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
