class ProductPackage {
  final int id;
  final int productId;
  final double packSize;
  final String unit;
  final double? price;

  ProductPackage({
    required this.id,
    required this.productId,
    required this.packSize,
    required this.unit,
    this.price,
  });

  factory ProductPackage.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.parse(rawId);
    } else {
      throw FormatException('Invalid package id: $rawId');
    }

    final rawProductId = json['product_id'];
    final int productId;
    if (rawProductId is int) {
      productId = rawProductId;
    } else if (rawProductId is String) {
      productId = int.parse(rawProductId);
    } else {
      throw FormatException('Invalid product id: $rawProductId');
    }

    return ProductPackage(
      id: id,
      productId: productId,
      packSize: (json['pack_size'] as num).toDouble(),
      unit: json['unit']?.toString() ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'pack_size': packSize,
      'unit': unit,
      'price': price,
    };
  }
}

