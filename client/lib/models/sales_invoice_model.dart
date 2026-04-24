int? _siIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

class SalesInvoiceHeader {
  final int? id;
  final String docNoPrefix;
  final String docNoNumber;
  final int? customerId;
  final String? customerName;
  final String docDate;
  final String billNo;
  final String? narration;
  final bool doNotUpdateInventory;
  final String? saleType;
  final String? billDate;
  final String? status;

  SalesInvoiceHeader({
    this.id,
    this.docNoPrefix = '25-26/',
    this.docNoNumber = '',
    this.customerId,
    this.customerName,
    this.docDate = '',
    this.billNo = '',
    this.narration,
    this.doNotUpdateInventory = false,
    this.saleType,
    this.billDate,
    this.status = 'DRAFT',
  });

  factory SalesInvoiceHeader.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceHeader(
      id: _siIntOrNull(json['id']),
      docNoPrefix: json['doc_no_prefix']?.toString() ?? '25-26/',
      docNoNumber: json['doc_no_number']?.toString() ?? '',
      customerId: _siIntOrNull(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      docDate: json['doc_date']?.toString() ?? '',
      billNo: json['bill_no']?.toString() ?? '',
      narration: json['narration']?.toString(),
      doNotUpdateInventory: json['do_not_update_inventory'] == true,
      saleType: json['sale_type']?.toString(),
      billDate: json['bill_date']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doc_no_prefix': docNoPrefix,
      'doc_no_number': docNoNumber,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      'doc_date': docDate,
      'bill_no': billNo,
      if (narration != null) 'narration': narration,
      'do_not_update_inventory': doNotUpdateInventory,
      if (saleType != null) 'sale_type': saleType,
      if (billDate != null) 'bill_date': billDate,
      if (status != null) 'status': status,
    };
  }
}

class SalesInvoiceItemRow {
  final int? sourceSalesOrderId;
  final int? sourceSalesOrderItemId;
  final String? sourceSoNumber;
  final double? orderedQty;
  final double? usedQty;
  final double? leftQty;
  final double? overrunQty;
  final double? writeoffQty;
  final bool isOverrunApproved;
  final bool isWriteoff;
  final String? overrunReason;
  final String? writeoffReason;
  final int? overrunApprovedBy;
  final String? overrunApprovedAt;
  final int? productId;
  final String? productName;
  final String? productCode;
  final String? alias;
  final String? unit;
  final double qty;
  final double unitPrice;
  final double taxableAmount;
  final double sgst;
  final double cgst;
  final double igst;
  final double cess;
  final double roff;
  final double value;
  final String? saleAccountId;
  final String? gstApplicability;

  SalesInvoiceItemRow({
    this.sourceSalesOrderId,
    this.sourceSalesOrderItemId,
    this.sourceSoNumber,
    this.orderedQty,
    this.usedQty,
    this.leftQty,
    this.overrunQty,
    this.writeoffQty,
    this.isOverrunApproved = false,
    this.isWriteoff = false,
    this.overrunReason,
    this.writeoffReason,
    this.overrunApprovedBy,
    this.overrunApprovedAt,
    this.productId,
    this.productName,
    this.productCode,
    this.alias,
    this.unit,
    this.qty = 0,
    this.unitPrice = 0,
    this.taxableAmount = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.igst = 0,
    this.cess = 0,
    this.roff = 0,
    this.value = 0,
    this.saleAccountId,
    this.gstApplicability,
  });

  factory SalesInvoiceItemRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }
    final qty = d(json['quantity'], 0);
    final unitPrice = d(json['unit_price'], 0);
    final taxable = d(json['taxable_amount'], qty * unitPrice);
    final sgst = d(json['sgst']);
    final cgst = d(json['cgst']);
    final igst = d(json['igst']);
    final cess = d(json['cess']);
    final roff = d(json['roff']);
    final value = d(json['value'], taxable + sgst + cgst + igst + cess + roff);
    return SalesInvoiceItemRow(
      sourceSalesOrderId: _siIntOrNull(json['source_sales_order_id']),
      sourceSalesOrderItemId: _siIntOrNull(json['source_sales_order_item_id']),
      sourceSoNumber: json['source_so_number']?.toString(),
      orderedQty: json['ordered_qty'] == null ? null : d(json['ordered_qty']),
      usedQty: json['used_qty'] == null ? null : d(json['used_qty']),
      leftQty: json['left_qty'] == null ? null : d(json['left_qty']),
      overrunQty: json['overrun_qty'] == null ? null : d(json['overrun_qty']),
      writeoffQty: json['writeoff_qty'] == null ? null : d(json['writeoff_qty']),
      isOverrunApproved: json['is_overrun_approved'] == true,
      isWriteoff: json['is_writeoff'] == true,
      overrunReason: json['overrun_reason']?.toString(),
      writeoffReason: json['writeoff_reason']?.toString(),
      overrunApprovedBy: _siIntOrNull(json['overrun_approved_by']),
      overrunApprovedAt: json['overrun_approved_at']?.toString(),
      productId: _siIntOrNull(json['product_id']),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      alias: json['alias']?.toString(),
      unit: json['unit']?.toString(),
      qty: qty,
      unitPrice: unitPrice,
      taxableAmount: taxable,
      sgst: sgst,
      cgst: cgst,
      igst: igst,
      cess: cess,
      roff: roff,
      value: value,
      saleAccountId: json['sale_account_id']?.toString(),
      gstApplicability: json['gst_applicability']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sourceSalesOrderId != null) 'source_sales_order_id': sourceSalesOrderId,
      if (sourceSalesOrderItemId != null) 'source_sales_order_item_id': sourceSalesOrderItemId,
      if (sourceSoNumber != null) 'source_so_number': sourceSoNumber,
      if (orderedQty != null) 'ordered_qty': orderedQty,
      if (usedQty != null) 'used_qty': usedQty,
      if (leftQty != null) 'left_qty': leftQty,
      if (overrunQty != null) 'overrun_qty': overrunQty,
      if (writeoffQty != null) 'writeoff_qty': writeoffQty,
      'is_overrun_approved': isOverrunApproved,
      'is_writeoff': isWriteoff,
      if (overrunReason != null) 'overrun_reason': overrunReason,
      if (writeoffReason != null) 'writeoff_reason': writeoffReason,
      if (overrunApprovedBy != null) 'overrun_approved_by': overrunApprovedBy,
      if (overrunApprovedAt != null) 'overrun_approved_at': overrunApprovedAt,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (alias != null) 'alias': alias,
      if (unit != null) 'unit': unit,
      'quantity': qty,
      'unit_price': unitPrice,
      'taxable_amount': taxableAmount,
      'sgst': sgst,
      'cgst': cgst,
      'igst': igst,
      'cess': cess,
      'roff': roff,
      'value': value,
      if (saleAccountId != null) 'sale_account_id': saleAccountId,
      if (gstApplicability != null) 'gst_applicability': gstApplicability,
    };
  }
}

class SalesInvoiceChargeRow {
  final String name;
  final double amount;
  final double calculatedAmount;
  final String? remarks;

  SalesInvoiceChargeRow({
    required this.name,
    this.amount = 0,
    this.calculatedAmount = 0,
    this.remarks,
  });

  factory SalesInvoiceChargeRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }
    final amount = d(json['amount']);
    final calc = d(json['calculated_amount'], amount);
    return SalesInvoiceChargeRow(
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
      if (remarks != null) 'remarks': remarks,
    };
  }
}
