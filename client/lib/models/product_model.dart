class Product {
  final int id;
  final String name;
  final String? code;
  final String productType; // 'FINISHED' or 'RAW'
  final String? defaultUnit; // 'KG', 'PCS', 'LTR', 'MTR'

  Product({
    required this.id,
    required this.name,
    this.code,
    required this.productType,
    this.defaultUnit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      code: json['product_code'] as String?,
      productType: json['product_type'] as String,
      defaultUnit: json['default_unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'product_code': code,
      'product_type': productType,
      'default_unit': defaultUnit,
    };
  }
}
