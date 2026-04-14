// Purchase Return Model - Represents goods/services returned to supplier
// Linked to Purchase Voucher (source document)

int? _prIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _prDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Purchase Return Header - Main document properties
class PurchaseReturnHeader {
  final int? id;
  final String docNoPrefix;
  final String docNoNumber;
  final int? sourcePurchaseVoucherId;
  final String? sourcePvNumber;
  final int? vendorId;
  final String? vendorName;
  final String docDate;
  final String? reason; // Specific reason for return
  final bool isPartialReturn;
  final String? status; // 'DRAFT', 'POSTED'

  PurchaseReturnHeader({
    this.id,
    this.docNoPrefix = '25-26/',
    this.docNoNumber = '',
    this.sourcePurchaseVoucherId,
    this.sourcePvNumber,
    this.vendorId,
    this.vendorName,
    this.docDate = '',
    this.reason,
    this.isPartialReturn = true,
    this.status = 'DRAFT',
  });

  factory PurchaseReturnHeader.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnHeader(
      id: _prIntOrNull(json['id']),
      docNoPrefix: json['doc_no_prefix']?.toString() ?? '25-26/',
      docNoNumber: json['doc_no_number']?.toString() ?? '',
      sourcePurchaseVoucherId: _prIntOrNull(json['source_purchase_voucher_id']),
      sourcePvNumber: json['source_pv_number']?.toString(),
      vendorId: _prIntOrNull(json['vendor_id'] ?? json['supplier_id']),
      vendorName:
          json['vendor_name']?.toString() ?? json['supplier_name']?.toString(),
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
      if (sourcePurchaseVoucherId != null)
        'source_purchase_voucher_id': sourcePurchaseVoucherId,
      if (sourcePvNumber != null) 'source_pv_number': sourcePvNumber,
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      'doc_date': docDate,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      'is_partial_return': isPartialReturn,
      if (status != null) 'status': status,
    };
  }
}

/// Purchase Return Item Row - Individual returned items
class PurchaseReturnItemRow {
  final int? sourcePurchaseVoucherItemId;
  final int? sourcePurchaseOrderItemId;
  final int? productId;
  final String? productName;
  final String? productCode;
  final String? alias;
  final String? unit;
  final double originalQty; // Qty received in PV
  final double? availableQty; // Remaining qty allowed for return
  final double returnedQty; // Qty being returned
  final double unitPrice;
  final double taxableAmount;
  final double sgst;
  final double cgst;
  final double igst;
  final double cess;
  final double roff;
  final double value; // Total return value for this item
  final String?
  returnReason; // Specific reason why item is returned (damage, defect, excess, etc.)
  final String? remarks;

  PurchaseReturnItemRow({
    this.sourcePurchaseVoucherItemId,
    this.sourcePurchaseOrderItemId,
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

  factory PurchaseReturnItemRow.fromJson(Map<String, dynamic> json) {
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

    return PurchaseReturnItemRow(
      sourcePurchaseVoucherItemId: _prIntOrNull(
        json['source_purchase_voucher_item_id'],
      ),
      sourcePurchaseOrderItemId: _prIntOrNull(
        json['source_purchase_order_item_id'],
      ),
      productId: _prIntOrNull(json['product_id']),
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
      if (sourcePurchaseVoucherItemId != null)
        'source_purchase_voucher_item_id': sourcePurchaseVoucherItemId,
      if (sourcePurchaseOrderItemId != null)
        'source_purchase_order_item_id': sourcePurchaseOrderItemId,
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

/// Purchase Return Charge Row - Additional charges on return (restocking fee, etc.)
class PurchaseReturnChargeRow {
  final String name;
  final double amount;
  final double calculatedAmount;
  final String? remarks;

  PurchaseReturnChargeRow({
    required this.name,
    this.amount = 0,
    this.calculatedAmount = 0,
    this.remarks,
  });

  factory PurchaseReturnChargeRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final amount = d(json['amount']);
    final calc = d(json['calculated_amount'], amount);
    return PurchaseReturnChargeRow(
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

/// Complete Purchase Return Document Model
class PurchaseReturn {
  final int? id;
  final PurchaseReturnHeader header;
  final List<PurchaseReturnItemRow> items;
  final List<PurchaseReturnChargeRow> charges;
  final double? totalItemValue; // Sum of item values
  final double? chargesTotal; // Sum of charges
  final double? totalValue; // Total return value (items + charges)

  PurchaseReturn({
    this.id,
    required this.header,
    this.items = const [],
    this.charges = const [],
    this.totalItemValue,
    this.chargesTotal,
    this.totalValue,
  });

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    final headerData = json['header'] is Map
        ? json['header'] as Map<String, dynamic>
        : json;

    final List<dynamic> rawItems = json['items'] is List
        ? json['items'] as List<dynamic>
        : [];
    final List<dynamic> rawCharges = json['charges'] is List
        ? json['charges'] as List<dynamic>
        : [];

    return PurchaseReturn(
      id: _prIntOrNull(json['id']),
      header: PurchaseReturnHeader.fromJson(headerData),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PurchaseReturnItemRow.fromJson)
          .toList(),
      charges: rawCharges
          .whereType<Map<String, dynamic>>()
          .map(PurchaseReturnChargeRow.fromJson)
          .toList(),
      totalItemValue: _prDoubleOrNull(json['total_item_value']),
      chargesTotal: _prDoubleOrNull(json['charges_total']),
      totalValue: _prDoubleOrNull(json['total_value']),
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

/// Lightweight model for list view
class PurchaseReturnSummary {
  final int id;
  final String docNumber;
  final String? vendorName;
  final String docDate;
  final String status;
  final double totalValue;

  PurchaseReturnSummary({
    required this.id,
    required this.docNumber,
    this.vendorName,
    required this.docDate,
    required this.status,
    this.totalValue = 0,
  });

  factory PurchaseReturnSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnSummary(
      id: _prIntOrNull(json['id']) ?? 0,
      docNumber: json['doc_no']?.toString() ?? json['doc_no_number'] ?? '',
      vendorName: json['vendor_name']?.toString(),
      docDate: json['doc_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      totalValue: _prDoubleOrNull(json['net_total']) ?? _prDoubleOrNull(json['total_value']) ?? 0,
    );
  }
}
