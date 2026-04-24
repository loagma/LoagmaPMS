class SalesOrder {
  final int? id;
  final String soNumber;
  final String? financialYear;
  final int customerId;
  final String? customerName;
  final String docDate;
  final String? expectedDate;
  final String status;
  final String? narration;
  final String? departmentId;
  final double? totalAmount;
  final double? chargesTotal;
  final double? totalWithCharges;
  final List<SalesOrderCharge> chargesJson;
  final List<SalesOrderItem> items;

  SalesOrder({
    this.id,
    required this.soNumber,
    this.financialYear,
    required this.customerId,
    this.customerName,
    required this.docDate,
    this.expectedDate,
    required this.status,
    this.narration,
    this.departmentId,
    this.totalAmount,
    this.chargesTotal,
    this.totalWithCharges,
    this.chargesJson = const [],
    this.items = const [],
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['sales_order_id'];
    final int? id = idValue == null
        ? null
        : (idValue is int ? idValue : int.tryParse(idValue.toString()));

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final List<dynamic> rawItems;
    if (json['items'] is List) {
      rawItems = json['items'] as List<dynamic>;
    } else if (json['sales_order_items'] is List) {
      rawItems = json['sales_order_items'] as List<dynamic>;
    } else {
      rawItems = const [];
    }

    final List<dynamic> rawCharges;
    if (json['charges_json'] is List) {
      rawCharges = json['charges_json'] as List<dynamic>;
    } else {
      rawCharges = const [];
    }

    final customer = json['customer'] is Map ? json['customer'] as Map<String, dynamic> : null;
    final customerName = customer?['name']?.toString() ?? json['customer_name']?.toString();

    return SalesOrder(
      id: id,
      soNumber: json['so_number']?.toString() ?? '',
      financialYear: json['financial_year']?.toString(),
      customerId: int.tryParse(json['customer_id']?.toString() ?? customer?['id']?.toString() ?? '') ?? 0,
      customerName: customerName,
      docDate: json['doc_date']?.toString() ?? '',
      expectedDate: json['expected_date']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      narration: json['narration']?.toString(),
      departmentId: json['department_id']?.toString() ?? json['departmentId']?.toString(),
      totalAmount: parseDouble(json['total_amount']),
      chargesTotal: parseDouble(json['charges_total']),
      totalWithCharges: parseDouble(json['total_with_charges']),
      chargesJson: rawCharges
          .whereType<Map<String, dynamic>>()
          .map(SalesOrderCharge.fromJson)
          .toList(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SalesOrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'so_number': soNumber,
      if (financialYear != null) 'financial_year': financialYear,
      'customer_id': customerId,
      'doc_date': docDate,
      if (expectedDate != null) 'expected_date': expectedDate,
      'status': status,
      if (narration != null) 'narration': narration,
      if (departmentId != null) 'department_id': departmentId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (chargesTotal != null) 'charges_total': chargesTotal,
      if (totalWithCharges != null) 'total_with_charges': totalWithCharges,
      if (chargesJson.isNotEmpty)
        'charges_json': chargesJson.map((e) => e.toJson()).toList(),
      if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class SalesOrderCharge {
  final String name;
  final double amount;
  final double? calculatedAmount;
  final String? remarks;

  const SalesOrderCharge({
    required this.name,
    required this.amount,
    this.calculatedAmount,
    this.remarks,
  });

  factory SalesOrderCharge.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return SalesOrderCharge(
      name: json['name']?.toString() ?? 'Charge',
      amount: parseDouble(json['amount']),
      calculatedAmount: json['calculated_amount'] == null
          ? null
          : parseDouble(json['calculated_amount']),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      if (calculatedAmount != null) 'calculated_amount': calculatedAmount,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }
}

String? _soProductNameFromJson(Map<String, dynamic> json) {
  final nested = json['product'];
  if (nested is Map) {
    final name = (nested as Map<String, dynamic>)['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
  }
  return json['product_name']?.toString() ?? json['name']?.toString();
}

class SalesOrderItem {
  final int? id;
  final int? salesOrderId;
  final int productId;
  final String? productName;
  final String? hsnCode;
  final int? lineNo;
  final String? unit;
  final double quantity;
  final double usedQty;
  final double writeoffQty;
  final double leftQty;
  final double price;
  final double? discountPercent;
  final double? taxPercent;
  final double? lineTotal;
  final double? priceInclTax;
  final double? lineTotalExclTax;
  final String? description;

  SalesOrderItem({
    this.id,
    this.salesOrderId,
    required this.productId,
    this.productName,
    this.hsnCode,
    this.lineNo,
    this.unit,
    required this.quantity,
    this.usedQty = 0,
    this.writeoffQty = 0,
    this.leftQty = 0,
    required this.price,
    this.discountPercent,
    this.taxPercent,
    this.lineTotal,
    this.priceInclTax,
    this.lineTotalExclTax,
    this.description,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    final idValue = json['id'] ?? json['sales_order_item_id'];
    final int? id = idValue == null
        ? null
        : (idValue is int ? idValue : int.tryParse(idValue.toString()));

    final soIdValue = json['sales_order_id'];
    final int? soId = soIdValue == null
        ? null
        : (soIdValue is int ? soIdValue : int.tryParse(soIdValue.toString()));

    final price = parseDouble(json['price']);
    final taxPct = parseDouble(json['tax_percent'], defaultValue: 0);
    final qty = parseDouble(json['quantity']);
    final usedQty = parseDouble(json['used_qty'] ?? json['consumed_quantity']);
    final writeoffQty = parseDouble(json['writeoff_qty'] ?? json['written_off_quantity']);
    final leftQtyRaw = json['left_qty'] ?? json['remaining_quantity'];
    final leftQty = leftQtyRaw == null
        ? (qty - usedQty - writeoffQty)
        : parseDouble(leftQtyRaw);
    final discountPct = parseDouble(json['discount_percent'], defaultValue: 0);
    final lineTotalVal = parseDouble(json['line_total']);
    double round2(double v) => (v * 100).round() / 100;
    final lineTotalExclTaxVal = json['line_total_excl_tax'] != null
        ? parseDouble(json['line_total_excl_tax'])
        : round2(qty * price * (1 - discountPct / 100));
    final priceInclTaxVal = json['price_incl_tax'] != null
        ? parseDouble(json['price_incl_tax'])
        : round2(price * (1 + taxPct / 100));

    return SalesOrderItem(
      id: id,
      salesOrderId: soId,
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      productName: _soProductNameFromJson(json),
      hsnCode: json['hsn_code']?.toString() ??
          json['hsn']?.toString() ??
          (json['product'] is Map<String, dynamic>
              ? (json['product'] as Map<String, dynamic>)['hsn_code']?.toString()
              : null),
      lineNo: int.tryParse(json['line_no']?.toString() ?? ''),
      unit: json['unit']?.toString(),
      quantity: qty,
      usedQty: usedQty,
      writeoffQty: writeoffQty,
      leftQty: leftQty < 0 ? 0 : leftQty,
      price: price,
      discountPercent: discountPct,
      taxPercent: taxPct,
      lineTotal: lineTotalVal,
      priceInclTax: priceInclTaxVal,
      lineTotalExclTax: lineTotalExclTaxVal,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (salesOrderId != null) 'sales_order_id': salesOrderId,
      'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (lineNo != null) 'line_no': lineNo,
      if (unit != null) 'unit': unit,
      'quantity': quantity,
      'used_qty': usedQty,
      'writeoff_qty': writeoffQty,
      'left_qty': leftQty,
      'price': price,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (lineTotal != null) 'line_total': lineTotal,
      if (description != null) 'description': description,
    };
  }
}
