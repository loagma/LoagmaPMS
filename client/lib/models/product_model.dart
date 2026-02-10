class Product {
  final int id;
  final String name;
  final String? code;
  final String? defaultUnit; // 'KG', 'PCS', 'LTR', 'MTR', etc.

  Product({
    required this.id,
    required this.name,
    this.code,
    this.defaultUnit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      code: json['product_code'] as String?,
      // defaultUnit: json['default_unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'product_code': code,
      // 'default_unit': defaultUnit,
    };
  }
}
