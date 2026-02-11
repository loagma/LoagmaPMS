class BomMaster {
  final int? bomId;
  final int productId;
  final String? productName;
  final String bomVersion;
  final String status; // 'DRAFT', 'APPROVED', 'LOCKED'
  final String? remarks;
  final int? createdBy;
  final int? approvedBy;
  final String? createdAt;
  final String? updatedAt;

  BomMaster({
    this.bomId,
    required this.productId,
    this.productName,
    required this.bomVersion,
    required this.status,
    this.remarks,
    this.createdBy,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BomMaster.fromJson(Map<String, dynamic> json) {
    return BomMaster(
      bomId: json['bom_id'] as int?,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      bomVersion: json['bom_version'] as String,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      createdBy: json['created_by'] as int?,
      approvedBy: json['approved_by'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bomId != null) 'bom_id': bomId,
      'product_id': productId,
      if (productName != null) 'product_name': productName,
      'bom_version': bomVersion,
      'status': status,
      if (remarks != null) 'remarks': remarks,
      if (createdBy != null) 'created_by': createdBy,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class BomItem {
  final int? bomItemId;
  final int? bomId;
  final int rawMaterialId;
  final double quantityPerUnit;
  final String unitType; // 'KG', 'PCS', 'LTR', 'MTR'
  final double wastagePercent;

  BomItem({
    this.bomItemId,
    this.bomId,
    required this.rawMaterialId,
    required this.quantityPerUnit,
    required this.unitType,
    this.wastagePercent = 0.0,
  });

  factory BomItem.fromJson(Map<String, dynamic> json) {
    return BomItem(
      bomItemId: json['bom_item_id'] as int?,
      bomId: json['bom_id'] as int?,
      rawMaterialId: json['raw_material_id'] as int,
      quantityPerUnit: (json['quantity_per_unit'] as num).toDouble(),
      unitType: json['unit_type'] as String,
      wastagePercent: (json['wastage_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bomItemId != null) 'bom_item_id': bomItemId,
      if (bomId != null) 'bom_id': bomId,
      'raw_material_id': rawMaterialId,
      'quantity_per_unit': quantityPerUnit,
      'unit_type': unitType,
      'wastage_percent': wastagePercent,
    };
  }
}
