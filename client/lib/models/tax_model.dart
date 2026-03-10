class Tax {
  final int id;
  final String taxCategory;
  final String taxSubCategory;
  final String taxName;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  Tax({
    required this.id,
    required this.taxCategory,
    required this.taxSubCategory,
    required this.taxName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? 0;
    final int id = idValue is int ? idValue : int.tryParse('$idValue') ?? 0;
    return Tax(
      id: id,
      taxCategory: json['tax_category']?.toString() ?? '',
      taxSubCategory: json['tax_sub_category']?.toString() ?? '',
      taxName: json['tax_name']?.toString() ?? '',
      isActive: _boolFromJson(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_category': taxCategory,
      'tax_sub_category': taxSubCategory,
      'tax_name': taxName,
      'is_active': isActive,
    };
  }

  static bool _boolFromJson(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final v = value.toString().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
}

class ProductTax {
  final int id;
  final int productId;
  final int taxId;
  final double taxPercent;
  final Tax? tax;
  final Map<String, dynamic>? product;

  ProductTax({
    required this.id,
    required this.productId,
    required this.taxId,
    required this.taxPercent,
    this.tax,
    this.product,
  });

  factory ProductTax.fromJson(Map<String, dynamic> json) {
    return ProductTax(
      id: _int(json['id']),
      productId: _int(json['product_id']),
      taxId: _int(json['tax_id']),
      taxPercent: _double(json['tax_percent']),
      tax: json['tax'] != null ? Tax.fromJson(json['tax'] as Map<String, dynamic>) : null,
      product: json['product'] as Map<String, dynamic>?,
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
