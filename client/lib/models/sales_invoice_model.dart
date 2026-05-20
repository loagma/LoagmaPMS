import 'sales_order_model.dart';

/// A Sales Invoice is the same orders row as a Sales Order, but in 'billed' state.
/// This model wraps SalesOrder and exposes invoice-specific field names.
class SalesInvoice {
  final int id;
  final String invoiceNumber;
  final String orderNumber;
  final int customerId;
  final String? customerName;
  final String invoiceDate;
  final String orderDate;
  final String? department;
  final String? narration;
  final String? vehicle;
  final String? statement;
  final double roff;
  final String? docYear;
  final double totalAmount;
  final List<SalesOrderItem> items;
  final String? salesReturnVoucherNo;
  final String? salesReturnDt;

  SalesInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    required this.invoiceDate,
    required this.orderDate,
    this.department,
    this.narration,
    this.vehicle,
    this.statement,
    this.roff = 0,
    this.docYear,
    this.totalAmount = 0,
    this.items = const [],
    this.salesReturnVoucherNo,
    this.salesReturnDt,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    final so = SalesOrder.fromJson(json);
    return SalesInvoice(
      id: so.id ?? 0,
      invoiceNumber: so.billNumber ?? '',
      orderNumber: so.soNumber,
      customerId: so.customerId,
      customerName: so.customerName,
      invoiceDate: so.billDt ?? so.docDate,
      orderDate: so.docDate,
      department: so.department,
      narration: so.billNarration,
      vehicle: so.billVehicle,
      statement: so.billStatement,
      roff: so.billRoff ?? 0,
      docYear: so.docYear,
      totalAmount: so.totalAmount ?? 0,
      items: so.items,
      salesReturnVoucherNo: so.salesReturnVoucherNo,
      salesReturnDt: so.salesReturnDt,
    );
  }
}

class SalesInvoiceSummary {
  final int id;
  final String invoiceNumber;
  final String orderNumber;
  final int customerId;
  final String? customerName;
  final String invoiceDate;
  final double totalAmount;
  final bool hasReturn;

  SalesInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    required this.invoiceDate,
    this.totalAmount = 0,
    this.hasReturn = false,
  });

  factory SalesInvoiceSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    return SalesInvoiceSummary(
      id: parseInt(json['id']),
      invoiceNumber: json['bill_number']?.toString() ?? '',
      orderNumber: json['so_number']?.toString() ?? 'ORD-${json['id']}',
      customerId: parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      invoiceDate: json['bill_dt']?.toString() ?? json['doc_date']?.toString() ?? '',
      totalAmount: parseDouble(json['total_amount']),
      hasReturn: (json['sales_return_voucher_no'] ?? '').toString().isNotEmpty,
    );
  }
}
