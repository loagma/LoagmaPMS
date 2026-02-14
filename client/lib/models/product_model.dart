class Product {
  final int id;
  final String name;
  final String? code;
  final String productType; // 'FINISHED' or 'RAW'
  final String? defaultUnit; // 'WEIGHT', 'QUANTITY', 'LITRE', 'METER'
  final double? stock; // Available stock (optional, when include_stock=1)

  Product({
    required this.id,
    required this.name,
    this.code,
    required this.productType,
    this.defaultUnit,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle product_id - can be int or string
    final productId = json['product_id'] ?? json['id'];
    final int id;
    if (productId is int) {
      id = productId;
    } else if (productId is String) {
      id = int.parse(productId);
    } else {
      throw FormatException('Invalid product_id: $productId');
    }

    // Handle product_name - support both 'name' and 'product_name'
    final productName = json['name'] ?? json['product_name'];
    if (productName == null || productName.toString().trim().isEmpty) {
      throw FormatException('Product name is required');
    }

    // Handle product_type - support both 'inventory_type' and 'product_type'
    final productType =
        json['inventory_type'] ?? json['product_type'] ?? 'SINGLE';

    double? stock;
    if (json['stock'] != null) {
      if (json['stock'] is num) {
        stock = (json['stock'] as num).toDouble();
      } else if (json['stock'] is String) {
        stock = double.tryParse(json['stock'] as String);
      }
    }

    return Product(
      id: id,
      name: productName.toString().trim(),
      code: json['product_code']?.toString(),
      productType: productType.toString().toUpperCase(),
      defaultUnit: json['default_unit'] ?? json['inventory_unit_type'],
      stock: stock,
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
