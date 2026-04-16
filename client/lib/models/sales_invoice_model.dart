class SalesInvoice {
  final int? id;
  final String invoiceNo;
  final int orderId;
  final int? customerUserId;
  final String invoiceDate;
  final String? dueDate;
  final String invoiceStatus;
  final String paymentStatus;
  final double subtotal;
  final double discountTotal;
  final double deliveryCharge;
  final double taxTotal;
  final double grandTotal;
  final String? notes;

  const SalesInvoice({
    this.id,
    required this.invoiceNo,
    required this.orderId,
    this.customerUserId,
    required this.invoiceDate,
    this.dueDate,
    required this.invoiceStatus,
    required this.paymentStatus,
    required this.subtotal,
    required this.discountTotal,
    required this.deliveryCharge,
    required this.taxTotal,
    required this.grandTotal,
    this.notes,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return SalesInvoice(
      id: parseInt(json['id']),
      invoiceNo: (json['invoice_no'] ?? '').toString(),
      orderId: parseInt(json['order_id']) ?? 0,
      customerUserId: parseInt(json['customer_user_id']),
      invoiceDate: (json['invoice_date'] ?? '').toString(),
      dueDate: json['due_date']?.toString(),
      invoiceStatus: (json['invoice_status'] ?? 'DRAFT').toString(),
      paymentStatus: (json['payment_status'] ?? 'PENDING').toString(),
      subtotal: parseDouble(json['subtotal']),
      discountTotal: parseDouble(json['discount_total']),
      deliveryCharge: parseDouble(json['delivery_charge']),
      taxTotal: parseDouble(json['tax_total']),
      grandTotal: parseDouble(json['grand_total']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_no': invoiceNo,
      'order_id': orderId,
      if (customerUserId != null) 'customer_user_id': customerUserId,
      'invoice_date': invoiceDate,
      if (dueDate != null && dueDate!.isNotEmpty) 'due_date': dueDate,
      'invoice_status': invoiceStatus,
      'payment_status': paymentStatus,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'delivery_charge': deliveryCharge,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
