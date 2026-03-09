/// Lightweight model for Purchase Voucher UI state and future API payload.
/// Header, item lines, and charge rows.
int? _pvIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

class PurchaseVoucherHeader {
  final int? id;
  final String docNoPrefix;
  final String docNoNumber;
  final int? vendorId;
  final String? vendorName;
  final String docDate;
  final String billNo;
  final String? narration;
  final bool doNotUpdateInventory;
  final String? purchaseType;
  final String? gstReverseCharge;
  final String? billDate;
  final String? purchaseAgentId;
  final String? status;

  PurchaseVoucherHeader({
    this.id,
    this.docNoPrefix = '25-26/',
    this.docNoNumber = '',
    this.vendorId,
    this.vendorName,
    this.docDate = '',
    this.billNo = '',
    this.narration,
    this.doNotUpdateInventory = false,
    this.purchaseType,
    this.gstReverseCharge,
    this.billDate,
    this.purchaseAgentId,
    this.status = 'DRAFT',
  });

  factory PurchaseVoucherHeader.fromJson(Map<String, dynamic> json) {
    return PurchaseVoucherHeader(
      id: _pvIntOrNull(json['id']),
      docNoPrefix: json['doc_no_prefix']?.toString() ?? '25-26/',
      docNoNumber: json['doc_no_number']?.toString() ?? '',
      vendorId: _pvIntOrNull(json['vendor_id'] ?? json['supplier_id']),
      vendorName: json['vendor_name']?.toString() ?? json['supplier_name']?.toString(),
      docDate: json['doc_date']?.toString() ?? '',
      billNo: json['bill_no']?.toString() ?? '',
      narration: json['narration']?.toString(),
      doNotUpdateInventory: json['do_not_update_inventory'] == true,
      purchaseType: json['purchase_type']?.toString(),
      gstReverseCharge: json['gst_reverse_charge']?.toString(),
      billDate: json['bill_date']?.toString(),
      purchaseAgentId: json['purchase_agent_id']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doc_no_prefix': docNoPrefix,
      'doc_no_number': docNoNumber,
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      'doc_date': docDate,
      'bill_no': billNo,
      if (narration != null) 'narration': narration,
      'do_not_update_inventory': doNotUpdateInventory,
      if (purchaseType != null) 'purchase_type': purchaseType,
      if (gstReverseCharge != null) 'gst_reverse_charge': gstReverseCharge,
      if (billDate != null) 'bill_date': billDate,
      if (purchaseAgentId != null) 'purchase_agent_id': purchaseAgentId,
      if (status != null) 'status': status,
    };
  }

}

class PurchaseVoucherItemRow {
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
  final String? purchaseAccountId;
  final String? gstItcEligibility;

  PurchaseVoucherItemRow({
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
    this.purchaseAccountId,
    this.gstItcEligibility,
  });

  factory PurchaseVoucherItemRow.fromJson(Map<String, dynamic> json) {
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
    return PurchaseVoucherItemRow(
      productId: _pvIntOrNull(json['product_id']),
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
      purchaseAccountId: json['purchase_account_id']?.toString(),
      gstItcEligibility: json['gst_itc_eligibility']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      if (purchaseAccountId != null) 'purchase_account_id': purchaseAccountId,
      if (gstItcEligibility != null) 'gst_itc_eligibility': gstItcEligibility,
    };
  }
}

/// Single charge/discount row (Freight, TCS, Discount, etc.)
class PurchaseVoucherChargeRow {
  final String name;
  final double amount;
  final double calculatedAmount;
  final String? remarks;

  PurchaseVoucherChargeRow({
    required this.name,
    this.amount = 0,
    this.calculatedAmount = 0,
    this.remarks,
  });

  factory PurchaseVoucherChargeRow.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }
    final amount = d(json['amount']);
    final calc = d(json['calculated_amount'], amount);
    return PurchaseVoucherChargeRow(
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
