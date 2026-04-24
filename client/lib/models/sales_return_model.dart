int? _srIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _srDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class SalesReturnHeader {
  final int? id;
  final String docNoPrefix;
  final String docNoNumber;
  final int? sourceSalesInvoiceId;
  final String? sourceSiNumber;
  final int? customerId;
  final String? customerName;
  final String docDate;
  final String? reason;
  final bool isPartialReturn;
  final String? status;

  SalesReturnHeader({
    this.id,
    this.docNoPrefix = '25-26/',
    this.docNoNumber = '',
    this.sourceSalesInvoiceId,
    this.sourceSiNumber,
    this.customerId,
    this.customerName,
    this.docDate = '',
    this.reason,
    this.isPartialReturn = true,
    this.status = 'DRAFT',
  });

  factory SalesReturnHeader.fromJson(Map<String, dynamic> json) {
    return SalesReturnHeader(
      id: _srIntOrNull(json['id']),
      docNoPrefix: json['doc_no_prefix']?.toString() ?? '25-26/',
      docNoNumber: json['doc_no_number']?.toString() ?? '',
      sourceSalesInvoiceId: _srIntOrNull(json['source_sales_invoice_id']),
      sourceSiNumber: json['source_si_number']?.toString(),
      customerId: _srIntOrNull(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      docDate: json['doc_date']?.toString() ?? '',
      reason: json['reason']?.toString(),
      isPartialReturn: json['is_partial_return'] != false,
      status: json['status']?.toString() ?? 'DRAFT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doc_no_prefix': docNoPrefix,
      'doc_no_number': docNoNumber,
      if (sourceSalesInvoiceId != null)
        'source_sales_invoice_id': sourceSalesInvoiceId,
      if (sourceSiNumber != null) 'source_si_number': sourceSiNumber,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      'doc_date': docDate,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      'is_partial_return': isPartialReturn,
      if (status != null) 'status': status,
    };
  }
}

class SalesReturnItemRow {
  final int? sourceSalesInvoiceItemId;
  final int? sourceSalesOrderItemId;
  final int? productId;
  final String? productName;
  final String? productCode;
  final String? alias;
  final String? unit;
  final double originalQty;
  final double? availableQty;
  final double returnedQty;
  final double unitPrice;
  final double taxableAmount;
  final double sgst;
  final double cgst;
  final double igst;
  final double cess;
  final double roff;
  final double value;
  final String? returnReason;
  final String? remarks;

  SalesReturnItemRow({
    this.sourceSalesInvoiceItemId,
    this.sourceSalesOrderItemId,
    this.productId,
    this.productName,
    this.productCode,
    this.alias,
    this.unit,
    this.originalQty = 0,
    this.availableQty,
    this.returnedQty = 0,
    this.unitPrice = 0,
    this.taxableAmount = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.igst = 0,
    this.cess = 0,
    this.roff = 0,
    this.value = 0,
    this.returnReason,
    this.remarks,
  });

  factory SalesReturnItemRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final originalQty = d(json['original_quantity'] ?? json['received_qty'], 0);
    final availableQty = d(
      json['available_quantity'] ?? json['remaining_returnable_qty'],
      originalQty,
    );
    final returnedQty = d(json['returned_quantity'] ?? json['return_qty'], 0);
    final unitPrice = d(json['unit_price'], 0);
    final taxable = d(json['taxable_amount'], returnedQty * unitPrice);
    final sgst = d(json['sgst']);
    final cgst = d(json['cgst']);
    final igst = d(json['igst']);
    final cess = d(json['cess']);
    final roff = d(json['roff']);
    final value = d(json['value'], taxable + sgst + cgst + igst + cess + roff);

    return SalesReturnItemRow(
      sourceSalesInvoiceItemId: _srIntOrNull(json['source_sales_invoice_item_id']),
      sourceSalesOrderItemId: _srIntOrNull(json['source_sales_order_item_id']),
      productId: _srIntOrNull(json['product_id']),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      alias: json['alias']?.toString(),
      unit: json['unit']?.toString(),
      originalQty: originalQty,
      availableQty: availableQty,
      returnedQty: returnedQty,
      unitPrice: unitPrice,
      taxableAmount: taxable,
      sgst: sgst,
      cgst: cgst,
      igst: igst,
      cess: cess,
      roff: roff,
      value: value,
      returnReason: json['return_reason']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sourceSalesInvoiceItemId != null)
        'source_sales_invoice_item_id': sourceSalesInvoiceItemId,
      if (sourceSalesOrderItemId != null)
        'source_sales_order_item_id': sourceSalesOrderItemId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (alias != null) 'alias': alias,
      if (unit != null) 'unit': unit,
      'original_quantity': originalQty,
      if (availableQty != null) 'available_quantity': availableQty,
      'returned_quantity': returnedQty,
      'unit_price': unitPrice,
      'taxable_amount': taxableAmount,
      'sgst': sgst,
      'cgst': cgst,
      'igst': igst,
      'cess': cess,
      'roff': roff,
      'value': value,
      if (returnReason != null && returnReason!.isNotEmpty)
        'return_reason': returnReason,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }
}

class SalesReturnChargeRow {
  final String name;
  final double amount;
  final double calculatedAmount;
  final String? remarks;

  SalesReturnChargeRow({
    required this.name,
    this.amount = 0,
    this.calculatedAmount = 0,
    this.remarks,
  });

  factory SalesReturnChargeRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final amount = d(json['amount']);
    final calc = d(json['calculated_amount'], amount);
    return SalesReturnChargeRow(
      name: json['name']?.toString() ?? '',
      amount: amount,
      calculatedAmount: calc,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'calculated_amount': calculatedAmount,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }
}

class SalesReturn {
  final int? id;
  final SalesReturnHeader header;
  final List<SalesReturnItemRow> items;
  final List<SalesReturnChargeRow> charges;
  final double? totalItemValue;
  final double? chargesTotal;
  final double? totalValue;

  SalesReturn({
    this.id,
    required this.header,
    this.items = const [],
    this.charges = const [],
    this.totalItemValue,
    this.chargesTotal,
    this.totalValue,
  });

  factory SalesReturn.fromJson(Map<String, dynamic> json) {
    final headerData = json['header'] is Map
        ? json['header'] as Map<String, dynamic>
        : json;

    final List<dynamic> rawItems = json['items'] is List
        ? json['items'] as List<dynamic>
        : [];
    final List<dynamic> rawCharges = json['charges'] is List
        ? json['charges'] as List<dynamic>
        : [];

    return SalesReturn(
      id: _srIntOrNull(json['id']),
      header: SalesReturnHeader.fromJson(headerData),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnItemRow.fromJson)
          .toList(),
      charges: rawCharges
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnChargeRow.fromJson)
          .toList(),
      totalItemValue: _srDoubleOrNull(json['total_item_value']),
      chargesTotal: _srDoubleOrNull(json['charges_total']),
      totalValue: _srDoubleOrNull(json['total_value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      ...header.toJson(),
      if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
      if (charges.isNotEmpty)
        'charges': charges.map((e) => e.toJson()).toList(),
      if (totalItemValue != null) 'total_item_value': totalItemValue,
      if (chargesTotal != null) 'charges_total': chargesTotal,
      if (totalValue != null) 'total_value': totalValue,
    };
  }
}

class SalesReturnSummary {
  final int id;
  final String docNumber;
  final String? customerName;
  final String docDate;
  final String status;
  final double totalValue;

  SalesReturnSummary({
    required this.id,
    required this.docNumber,
    this.customerName,
    required this.docDate,
    required this.status,
    this.totalValue = 0,
  });

  factory SalesReturnSummary.fromJson(Map<String, dynamic> json) {
    return SalesReturnSummary(
      id: _srIntOrNull(json['id']) ?? 0,
      docNumber: json['doc_no']?.toString() ?? json['doc_no_number'] ?? '',
      customerName: json['customer_name']?.toString(),
      docDate: json['doc_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      totalValue: _srDoubleOrNull(json['net_total']) ?? _srDoubleOrNull(json['total_value']) ?? 0,
    );
  }
}
