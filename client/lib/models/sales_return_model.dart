class SalesReturn {
  final int? id;
  final int orderId;
  final String returnDate;
  final String returnStatus;
  final String? reason;
  final double? totalRefund;
  final List<SalesReturnItem> items;

  const SalesReturn({
    this.id,
    required this.orderId,
    required this.returnDate,
    required this.returnStatus,
    this.reason,
    this.totalRefund,
    this.items = const [],
  });

  factory SalesReturn.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final rawItems =
        (json['items'] ?? json['return_items']) as List<dynamic>? ?? const [];

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return SalesReturn(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']) ?? 0,
      returnDate: (json['return_date'] ?? '').toString(),
      returnStatus: (json['return_status'] ?? 'DRAFT').toString(),
      reason: json['reason']?.toString(),
      totalRefund: parseDouble(json['total_refund']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'return_date': returnDate,
      'return_status': returnStatus,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      if (totalRefund != null) 'total_refund': totalRefund,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class SalesReturnItem {
  final int? itemId;
  final int productId;
  final double originalQty;
  final double returnQty;
  final double refundAmount;
  final String? reason;

  const SalesReturnItem({
    this.itemId,
    required this.productId,
    required this.originalQty,
    required this.returnQty,
    required this.refundAmount,
    this.reason,
  });

  factory SalesReturnItem.fromJson(Map<String, dynamic> json) {
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

    return SalesReturnItem(
      itemId: parseInt(json['item_id'] ?? json['id']),
      productId: parseInt(json['product_id']) ?? 0,
      originalQty: parseDouble(
        json['original_qty'] ?? json['qty_delivered'] ?? json['quantity'],
      ),
      returnQty: parseDouble(json['return_qty'] ?? json['qty_returned']),
      refundAmount: parseDouble(json['refund_amount']),
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      'product_id': productId,
      'original_qty': originalQty.toInt(),
      'return_qty': returnQty.toInt(),
      'refund_amount': refundAmount,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}
