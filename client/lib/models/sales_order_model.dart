class SalesOrder {
  final int? orderId;
  final int? customerUserId;
  final double? orderTotal;
  final String orderState;
  final String paymentStatus;
  final String paymentMethod;
  final String? orderDate;
  final String? remarks;
  final List<SalesOrderItem> items;

  const SalesOrder({
    this.orderId,
    this.customerUserId,
    this.orderTotal,
    required this.orderState,
    required this.paymentStatus,
    required this.paymentMethod,
    this.orderDate,
    this.remarks,
    this.items = const [],
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] ?? json['order_items']) as List<dynamic>? ?? const [];

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return SalesOrder(
      orderId: parseInt(json['order_id'] ?? json['id']),
      customerUserId: parseInt(
        json['buyer_userid'] ?? json['customer_user_id'],
      ),
      orderTotal: parseDouble(json['order_total']),
      orderState: (json['order_state'] ?? 'registered').toString(),
      paymentStatus: (json['payment_status'] ?? 'not_paid').toString(),
      paymentMethod: (json['payment_method'] ?? 'cod').toString(),
      orderDate:
          json['short_datetime']?.toString() ?? json['order_date']?.toString(),
      remarks: json['remarks']?.toString() ?? json['feedback']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SalesOrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (orderId != null) 'order_id': orderId,
      if (customerUserId != null) 'buyer_userid': customerUserId,
      if (orderTotal != null) 'order_total': orderTotal,
      'order_state': orderState,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      if (orderDate != null) 'order_date': orderDate,
      if (remarks != null) 'remarks': remarks,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class SalesOrderItem {
  final int? itemId;
  final int productId;
  final int? vendorProductId;
  final double quantity;
  final double qtyLoaded;
  final double qtyDelivered;
  final double qtyReturned;
  final double itemPrice;
  final double itemTotal;

  const SalesOrderItem({
    this.itemId,
    required this.productId,
    this.vendorProductId,
    required this.quantity,
    this.qtyLoaded = 0,
    this.qtyDelivered = 0,
    this.qtyReturned = 0,
    required this.itemPrice,
    required this.itemTotal,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
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

    return SalesOrderItem(
      itemId: parseInt(json['item_id'] ?? json['id']),
      productId: parseInt(json['product_id']) ?? 0,
      vendorProductId: parseInt(json['vendor_product_id']),
      quantity: parseDouble(json['quantity']),
      qtyLoaded: parseDouble(json['qty_loaded']),
      qtyDelivered: parseDouble(json['qty_delivered']),
      qtyReturned: parseDouble(json['qty_returned']),
      itemPrice: parseDouble(json['item_price']),
      itemTotal: parseDouble(json['item_total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      'product_id': productId,
      if (vendorProductId != null) 'vendor_product_id': vendorProductId,
      'quantity': quantity.toInt(),
      'qty_loaded': qtyLoaded.toInt(),
      'qty_delivered': qtyDelivered.toInt(),
      'qty_returned': qtyReturned.toInt(),
      'item_price': itemPrice,
      'item_total': itemTotal,
    };
  }
}
