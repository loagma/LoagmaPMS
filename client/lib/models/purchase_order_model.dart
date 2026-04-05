class PurchaseOrder {
  final int? id;
  final String poNumber;
  final String? financialYear;
  final int supplierId;
  final String? supplierName;
  final String docDate;
  final String? expectedDate;
  final String status;
  final String? narration;
  final String? salesmanId;
  final String? departmentId;
  final double? totalAmount;
  final double? chargesTotal;
  final double? totalWithCharges;
  final List<PurchaseOrderCharge> chargesJson;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    this.id,
    required this.poNumber,
    this.financialYear,
    required this.supplierId,
    this.supplierName,
    required this.docDate,
    this.expectedDate,
    required this.status,
    this.narration,
    this.salesmanId,
    this.departmentId,
    this.totalAmount,
    this.chargesTotal,
    this.totalWithCharges,
    this.chargesJson = const [],
    this.items = const [],
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['purchase_order_id'];
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
    } else if (json['purchase_order_items'] is List) {
      rawItems = json['purchase_order_items'] as List<dynamic>;
    } else {
      rawItems = const [];
    }

    final List<dynamic> rawCharges;
    if (json['charges_json'] is List) {
      rawCharges = json['charges_json'] as List<dynamic>;
    } else {
      rawCharges = const [];
    }

    final supplier = json['supplier'] is Map ? json['supplier'] as Map<String, dynamic> : null;
    final supplierName = supplier?['supplier_name']?.toString() ?? supplier?['name']?.toString() ?? json['supplier_name']?.toString();

    return PurchaseOrder(
      id: id,
      poNumber: json['po_number']?.toString() ?? '',
      financialYear: json['financial_year']?.toString(),
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? supplier?['id']?.toString() ?? '') ?? 0,
      supplierName: supplierName,
      docDate: json['doc_date']?.toString() ?? '',
      expectedDate: json['expected_date']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      narration: json['narration']?.toString(),
      salesmanId: json['salesman_id']?.toString() ?? json['salesmanId']?.toString(),
      departmentId: json['department_id']?.toString() ?? json['departmentId']?.toString(),
      totalAmount: parseDouble(json['total_amount']),
        chargesTotal: parseDouble(json['charges_total']),
        totalWithCharges: parseDouble(json['total_with_charges']),
        chargesJson: rawCharges
          .whereType<Map<String, dynamic>>()
          .map(PurchaseOrderCharge.fromJson)
          .toList(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PurchaseOrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'po_number': poNumber,
      if (financialYear != null) 'financial_year': financialYear,
      'supplier_id': supplierId,
      'doc_date': docDate,
      if (expectedDate != null) 'expected_date': expectedDate,
      'status': status,
      if (narration != null) 'narration': narration,
      if (salesmanId != null) 'salesman_id': salesmanId,
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

class PurchaseOrderCharge {
  final String name;
  final double amount;
  final double? calculatedAmount;
  final String? remarks;

  const PurchaseOrderCharge({
    required this.name,
    required this.amount,
    this.calculatedAmount,
    this.remarks,
  });

  factory PurchaseOrderCharge.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return PurchaseOrderCharge(
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

String? _productNameFromJson(Map<String, dynamic> json) {
  final nested = json['product'];
  if (nested is Map) {
    final name = (nested as Map<String, dynamic>)['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
  }
  return json['product_name']?.toString() ?? json['name']?.toString();
}

class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId;
  final int productId;
  final String? productName;
  final String? hsnCode;
  final int? lineNo;
  final String? unit;
  final double quantity;
  /// Unit price excluding tax.
  final double price;
  final double? discountPercent;
  final double? taxPercent;
  final double? lineTotal;
  /// Unit price including tax (from API or computed as price * (1 + taxPercent/100)).
  final double? priceInclTax;
  /// Line total excluding tax (from API or computed).
  final double? lineTotalExclTax;
  final String? description;

  PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.productId,
    this.productName,
    this.hsnCode,
    this.lineNo,
    this.unit,
    required this.quantity,
    required this.price,
    this.discountPercent,
    this.taxPercent,
    this.lineTotal,
    this.priceInclTax,
    this.lineTotalExclTax,
    this.description,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    final idValue = json['id'] ?? json['purchase_order_item_id'];
    final int? id = idValue == null
        ? null
        : (idValue is int ? idValue : int.tryParse(idValue.toString()));

    final poIdValue = json['purchase_order_id'];
    final int? poId = poIdValue == null
        ? null
        : (poIdValue is int ? poIdValue : int.tryParse(poIdValue.toString()));

    final price = parseDouble(json['price']);
    final taxPct = parseDouble(json['tax_percent'], defaultValue: 0);
    final qty = parseDouble(json['quantity']);
    final discountPct = parseDouble(json['discount_percent'], defaultValue: 0);
    final lineTotalVal = parseDouble(json['line_total']);
    double round2(double v) => (v * 100).round() / 100;
    final lineTotalExclTaxVal = json['line_total_excl_tax'] != null
        ? parseDouble(json['line_total_excl_tax'])
        : round2(qty * price * (1 - discountPct / 100));
    final priceInclTaxVal = json['price_incl_tax'] != null
        ? parseDouble(json['price_incl_tax'])
        : round2(price * (1 + taxPct / 100));

    return PurchaseOrderItem(
      id: id,
      purchaseOrderId: poId,
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      productName: _productNameFromJson(json),
      hsnCode: json['hsn_code']?.toString() ??
          json['hsn']?.toString() ??
          (json['product'] is Map<String, dynamic>
              ? (json['product'] as Map<String, dynamic>)['hsn_code']?.toString()
              : null),
      lineNo: int.tryParse(json['line_no']?.toString() ?? ''),
      unit: json['unit']?.toString(),
      quantity: qty,
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
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (lineNo != null) 'line_no': lineNo,
      if (unit != null) 'unit': unit,
      'quantity': quantity,
      'price': price,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (lineTotal != null) 'line_total': lineTotal,
      if (description != null) 'description': description,
    };
  }
}

