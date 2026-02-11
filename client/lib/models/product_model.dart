class Product {
  final int id;
  final String name;
  final String? code;
  final String productType; // 'FINISHED' or 'RAW'
  final String? defaultUnit; // 'WEIGHT', 'QUANTITY', 'LITRE', 'METER'

  Product({
    required this.id,
    required this.name,
    this.code,
    required this.productType,
    this.defaultUnit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle product_id - can be int or string
    final productId = json['product_id'];
    final int id;
    if (productId is int) {
      id = productId;
    } else if (productId is String) {
      id = int.parse(productId);
    } else {
      throw FormatException('Invalid product_id: $productId');
    }

    // Handle product_name
    final productName = json['product_name'];
    if (productName == null || productName.toString().trim().isEmpty) {
      throw FormatException('Product name is required');
    }

    // Handle product_type
    final productType = json['product_type'];
    if (productType == null || productType.toString().trim().isEmpty) {
      throw FormatException('Product type is required');
    }

    return Product(
      id: id,
      name: productName.toString().trim(),
      code: json['product_code']?.toString(),
      productType: productType.toString().toUpperCase(),
      defaultUnit: json['default_unit']?.toString(),
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
