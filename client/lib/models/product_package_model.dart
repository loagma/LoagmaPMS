class ProductPackage {
  final int id;
  final int productId;
  final String description;
  final double packSize;
  final String unit;
  final double? price;
  final double? marketPrice;
  final String? retailPrices;

  ProductPackage({
    required this.id,
    required this.productId,
    required this.description,
    required this.packSize,
    required this.unit,
    this.price,
    this.marketPrice,
    this.retailPrices,
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
      description: json['description']?.toString() ??
          '${(json['pack_size'] as num).toDouble()} ${json['unit']?.toString() ?? ''}',
      packSize: (json['pack_size'] as num).toDouble(),
      unit: json['unit']?.toString() ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      marketPrice: json['market_price'] != null
          ? (json['market_price'] as num).toDouble()
          : null,
      retailPrices: json['retail_prices']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'description': description,
      'pack_size': packSize,
      'unit': unit,
      'price': price,
      'market_price': marketPrice,
      'retail_prices': retailPrices,
    };
  }
}

