import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import '../../controllers/sales_order_form_controller.dart';
import '../../models/sales_order_model.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'sales_order_form_screen.dart';

class SalesOrderDetailScreen extends StatefulWidget {
  final int soId;
  final List<int> allIds;
  const SalesOrderDetailScreen({super.key, required this.soId, this.allIds = const []});

  @override
  State<SalesOrderDetailScreen> createState() => _SalesOrderDetailScreenState();
}

class _SalesOrderDetailScreenState extends State<SalesOrderDetailScreen> {
  SalesOrder? _order;
  bool _loading = true;
  String? _error;
  bool _pdfBusy = false;
  late int _currentId;

  @override
  void initState() {
    super.initState();
    _currentId = widget.soId;
    _load();
  }

  int? get _prevId {
    final idx = widget.allIds.indexOf(_currentId);
    return (idx > 0) ? widget.allIds[idx - 1] : null;
  }

  int? get _nextId {
    final idx = widget.allIds.indexOf(_currentId);
    return (idx >= 0 && idx < widget.allIds.length - 1) ? widget.allIds[idx + 1] : null;
  }

  void _goTo(int id) {
    setState(() { _currentId = id; });
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.salesOrders}/$_currentId'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        setState(() {
          _order = SalesOrder.fromJson(body['data'] as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        setState(() { _error = body['message']?.toString() ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Network error: $e'; _loading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'BILLED':      return const Color(0xFF2E7D32);
      case 'DELIVERED':   return const Color(0xFF00796B);
      case 'DISPATCHED':  return const Color(0xFF1565C0);
      case 'REGISTERED':  return const Color(0xFF4527A0);
      case 'CANCELLED':   return const Color(0xFFC62828);
      case 'PENDING':     return const Color(0xFFE65100);
      case 'DRAFT':       return const Color(0xFF546E7A);
      default:            return const Color(0xFF546E7A);
    }
  }

  Future<void> _pdf(bool share) async {
    if (_order == null || _pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final tag = 'pdf_${share ? "share" : "print"}_$_currentId';
      final ctrl = Get.put(
        SalesOrderFormController(soId: _currentId, startInViewOnly: true),
        tag: tag,
      );
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ctrl.isLoading.value;
      }).timeout(const Duration(seconds: 20));
      if (share) {
        await ReportExportService.shareSalesOrder(ctrl);
      } else {
        await ReportExportService.printSalesOrder(ctrl);
      }
      Get.delete<SalesOrderFormController>(tag: tag);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: ModuleAppBar(
        title: _order?.soNumber ?? 'Sales Order',
        subtitle: 'Order Details',
        onBackPressed: () => Get.back(),
        actions: _pdfBusy
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ]
            : [
                if (_prevId != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    tooltip: 'Previous order',
                    onPressed: () => _goTo(_prevId!),
                  ),
                if (_nextId != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    tooltip: 'Next order',
                    onPressed: () => _goTo(_nextId!),
                  ),
                IconButton(
                  icon: const Icon(Icons.print_outlined, color: Colors.white),
                  tooltip: 'Print / Download PDF',
                  onPressed: () => _pdf(false),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: 'Share PDF',
                  onPressed: () => _pdf(true),
                ),
              ],
      ),
      floatingActionButton: (_order != null && (_order!.status.toUpperCase() == 'DRAFT' || _order!.status.toUpperCase() == 'PENDING'))
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Get.to(() => SalesOrderFormScreen(soId: _currentId, startInViewOnly: true, allIds: widget.allIds))
                      ?.then((_) { if (mounted) _load(); }),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _Body(order: _order!, statusColor: _statusColor(_order!.status)),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final SalesOrder order;
  final Color statusColor;
  const _Body({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final subtotal  = o.totalAmount ?? 0;
    final discount  = o.discount ?? 0;
    final delivery  = o.deliveryCharge ?? 0;
    final grandTotal = o.totalWithCharges ?? (subtotal - discount + delivery);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Header card (status + SO number + date) ──
          _HeaderCard(order: o, statusColor: statusColor),
          const SizedBox(height: 12),

          // ── Invoice (only when billed) ──
          if (o.billNumber?.isNotEmpty == true || o.billDt?.isNotEmpty == true) ...[
            ContentCard(
              title: 'Invoice',
              child: Column(children: [
                if (o.billNumber?.isNotEmpty == true)
                  _Row(Icons.receipt_outlined, 'Bill No.', o.billNumber!),
                if (o.billDt?.isNotEmpty == true)
                  _Row(Icons.calendar_today_outlined, 'Bill Date', o.billDt!),
                if (o.department?.isNotEmpty == true)
                  _Row(Icons.business_outlined, 'Department', o.department!),
                if (o.docYear?.isNotEmpty == true)
                  _Row(Icons.date_range_outlined, 'Doc Year', o.docYear!),
                if (o.billVehicle?.isNotEmpty == true)
                  _Row(Icons.local_shipping_outlined, 'Vehicle', o.billVehicle!),
                if (o.billNarration?.isNotEmpty == true)
                  _Row(Icons.notes_outlined, 'Narration', o.billNarration!),
                if (o.billStatement?.isNotEmpty == true)
                  _Row(Icons.description_outlined, 'Statement', o.billStatement!),
                if ((o.billRoff ?? 0) != 0)
                  _Row(Icons.exposure_outlined, 'Round Off',
                      (o.billRoff! >= 0 ? '+' : '') + o.billRoff!.toStringAsFixed(2)),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Customer + Salesman ──
          ContentCard(
            title: 'Customer',
            child: Column(children: [
              _Row(Icons.person_outline, 'Name',
                  o.customerName?.isNotEmpty == true
                      ? o.customerName!
                      : 'Customer #${o.customerId}'),
              if (o.customerPhone?.isNotEmpty == true)
                _Row(Icons.phone_outlined, 'Phone', o.customerPhone!),
              if (o.customerEmail?.isNotEmpty == true)
                _Row(Icons.email_outlined, 'Email', o.customerEmail!),
              if (o.salesmanName?.isNotEmpty == true)
                _Row(Icons.badge_outlined, 'Salesman', o.salesmanName!),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Items ──
          ContentCard(
            title: 'Items  (${o.items.isNotEmpty ? o.items.length : (o.itemsCount ?? 0)})',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: o.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No item details available',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  )
                : Column(
                    children: List.generate(o.items.length, (i) {
                      final isLast = i == o.items.length - 1;
                      return _ItemRow(item: o.items[i], index: i, isLast: isLast);
                    }),
                  ),
          ),
          const SizedBox(height: 12),

          // ── Summary ──
          ContentCard(
            title: 'Summary',
            child: Column(children: [
              if (subtotal > 0)
                _SummaryRow('Subtotal', subtotal),
              if (discount > 0)
                _SummaryRow('Discount', -discount, color: Colors.red.shade700),
              if (delivery > 0)
                _SummaryRow('Delivery', delivery),
              for (final c in o.chargesJson)
                if ((c.calculatedAmount ?? c.amount) != 0)
                  _SummaryRow(c.name, c.calculatedAmount ?? c.amount),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.primaryLight),
              ),
              Row(children: [
                const Text('Grand Total',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
                const Spacer(),
                Text(
                  '₹ ${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarker),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Header card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final SalesOrder order;
  final Color statusColor;
  const _HeaderCard({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.9)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status pill
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  order.status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.4),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              order.soNumber,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 4),
            Text(
              order.docDate,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ]),
          const Spacer(),
          // Grand total callout
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              '₹ ${(order.totalWithCharges ?? order.totalAmount ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarker),
            ),
            if ((order.itemsCount ?? order.items.length) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${order.itemsCount ?? order.items.length} item${(order.itemsCount ?? order.items.length) == 1 ? "" : "s"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ── Item row ─────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final SalesOrderItem item;
  final int index;
  final bool isLast;
  const _ItemRow({required this.item, required this.index, required this.isLast});

  String _qty(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.lineTotal ?? (item.quantity * item.price);
    final hasDiscount = (item.discountPercent ?? 0) > 0;
    final hasTax      = (item.taxPercent ?? 0) > 0;
    final hasDelivered = item.usedQty > 0;
    final hasLeft      = item.leftQty > 0 && item.leftQty != item.quantity;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Number badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Product name
              Text(
                item.productName ?? 'Product #${item.productId}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
              if (item.hsnCode?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('HSN: ${item.hsnCode}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              if (item.description?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item.description!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              const SizedBox(height: 6),

              // Qty × Price = Total
              Row(children: [
                Text(
                  '${_qty(item.quantity)} ${item.unit ?? ''}'.trim(),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const Text('  ×  ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(
                  '₹ ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '₹ ${lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark),
                ),
              ]),

              // Tax / discount tags
              if (hasDiscount || hasTax)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(spacing: 6, children: [
                    if (hasDiscount)
                      _Tag('${item.discountPercent!.toStringAsFixed(1)}% disc',
                          Colors.orange.shade700),
                    if (hasTax)
                      _Tag('GST ${item.taxPercent!.toStringAsFixed(1)}%',
                          AppColors.primary),
                  ]),
                ),

              // Delivery / pending status
              if (hasDelivered || hasLeft)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(spacing: 6, children: [
                    if (hasDelivered)
                      _Tag('Delivered: ${_qty(item.usedQty)}', Colors.green.shade700),
                    if (hasLeft)
                      _Tag('Pending: ${_qty(item.leftQty)}', Colors.orange.shade800),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      if (!isLast)
        const Divider(height: 1, color: AppColors.primaryLight),
      if (!isLast) const SizedBox(height: 12),
    ]);
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  const _SummaryRow(this.label, this.amount, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDark;
    final prefix = amount < 0 ? '-' : '';
    final display = '₹ $prefix${amount.abs().toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(display,
            style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Icon + label row ──────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── Small tag ─────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ]),
      ),
    );
  }
}
