import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/sales_invoice_list_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_invoice_form_screen.dart';

class SalesInvoiceListScreen extends StatefulWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  State<SalesInvoiceListScreen> createState() => _SalesInvoiceListScreenState();
}

class _SalesInvoiceListScreenState extends State<SalesInvoiceListScreen> {
  late final SalesInvoiceListController controller;
  bool _filtersExpanded = false;
  String _localFrom = '';
  String _localTo = '';
  String _localStatus = '';

  static const _statusOptions = ['', 'DRAFT', 'POSTED', 'CANCELLED'];
  static const _statusLabels = {'': 'All', 'DRAFT': 'Draft', 'POSTED': 'Posted', 'CANCELLED': 'Cancelled'};

  @override
  void initState() {
    super.initState();
    controller = Get.put(SalesInvoiceListController());
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
    controller.applyFilters(
      from: _localFrom,
      to: _localTo,
      status: _localStatus,
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
    controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Sales Invoices',
        subtitle: 'Record sales invoices',
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: controller.refresh,
            tooltip: 'Refresh',
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
                      hintText: 'Search by invoice #, customer…',
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
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  items: _statusOptions
                                      .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabels[s]!)))
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Apply'),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: _resetFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textMuted,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              if (controller.isLoading.value && controller.invoices.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading invoices…',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (controller.invoices.isEmpty) {
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
                            icon: Icons.receipt_long_outlined,
                            message: 'No sales invoices found.',
                            actionLabel: 'Add Invoice',
                            onAction: () async {
                              final result = await Get.to(() => const SalesInvoiceFormScreen());
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
                  itemCount: controller.invoices.length + (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.invoices.length) {
                      // Load-more trigger
                      if (!controller.isLoading.value) {
                        controller.fetchInvoices(loadMore: true);
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final invoice = controller.invoices[index];
                    return _InvoiceCard(
                      invoice: invoice,
                      statusColor: controller.statusColor(invoice.status),
                      onTap: () async {
                        final result = await Get.to(
                          () => SalesInvoiceFormScreen(
                            invoiceId: invoice.id,
                            startInReportMode: true,
                          ),
                        );
                        if (result == true) controller.refresh();
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
          final result = await Get.to(() => const SalesInvoiceFormScreen());
          if (result == true) controller.refresh();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
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
          color: isSet ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final SalesInvoiceSummary invoice;
  final Color statusColor;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status bar
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: doc no + status badge + writeoff badge
                    Row(
                      children: [
                        Text(
                          invoice.docNo.isNotEmpty ? invoice.docNo : 'SI-${invoice.id}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        _Badge(label: invoice.status, color: statusColor),
                        if (invoice.hasWriteoff) ...[
                          const SizedBox(width: 6),
                          const _Badge(label: 'Write Off', color: Colors.deepOrange),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Customer name
                    Text(
                      invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Bottom row: bill no + date + total
                    Row(
                      children: [
                        if (invoice.billNo.isNotEmpty) ...[
                          const Icon(Icons.receipt_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              invoice.billNo,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          invoice.docDate,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (invoice.netTotal != null) ...[
                          const Spacer(),
                          Text(
                            '₹ ${invoice.netTotal!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
