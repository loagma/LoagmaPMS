class ProductPack {
  final String id;
  final String label;
  final double? weight;
  final String? unit;
  final double? price;

  ProductPack({
    required this.id,
    required this.label,
    this.weight,
    this.unit,
    this.price,
  });

  factory ProductPack.fromJson(Map<String, dynamic> json) {
    final rawId = json['pack_id'] ?? json['id'] ?? '';
    final label = json['pack_name'] ?? json['label'] ?? json['name'] ?? rawId.toString();
    double? weight;
    if (json['pack_wt'] != null) {
      weight = (json['pack_wt'] as num?)?.toDouble();
    } else if (json['weight'] != null) {
      weight = (json['weight'] as num?)?.toDouble();
    }
    double? price;
    if (json['price'] != null) {
      price = (json['price'] as num?)?.toDouble();
    }
    return ProductPack(
      id: rawId.toString(),
      label: label.toString(),
      weight: weight,
      unit: json['unit']?.toString() ?? json['pack_ut']?.toString(),
      price: price,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? code;
  final String? hsnCode;
  final String productType; // 'SINGLE' or 'PACK_WISE'
  final String? defaultUnit; // 'WEIGHT', 'QUANTITY', 'LITRE', 'METER'
  final double? stock; // Available stock (optional, when include_stock=1)
  final double gstPercent;
  final List<ProductTaxInfo> taxes;
  final String? description;
  final String? brand;
  final List<ProductPack> packs;
  final String? defaultPackId;

  Product({
    required this.id,
    required this.name,
    this.code,
    this.hsnCode,
    required this.productType,
    this.defaultUnit,
    this.stock,
    this.gstPercent = 0,
    this.taxes = const [],
    this.description,
    this.brand,
    this.packs = const [],
    this.defaultPackId,
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

    double gstPercent = 0;
    if (json['gst_percent'] != null) {
      if (json['gst_percent'] is num) {
        gstPercent = (json['gst_percent'] as num).toDouble();
      } else if (json['gst_percent'] is String) {
        gstPercent = double.tryParse(json['gst_percent'] as String) ?? 0;
      }
    }

    final List<ProductTaxInfo> taxes = [];
    if (json['taxes'] is List) {
      for (final item in (json['taxes'] as List)) {
        if (item is Map<String, dynamic>) {
          taxes.add(ProductTaxInfo.fromJson(item));
        }
      }
    }

    String? readHsn(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    final nested = json['product'];
    final nestedProduct = nested is Map<String, dynamic> ? nested : null;
    final hsnCode = readHsn(
      json['hsn_code'] ??
          json['hsnCode'] ??
          json['hsn'] ??
          nestedProduct?['hsn_code'] ??
          nestedProduct?['hsnCode'] ??
          nestedProduct?['hsn'],
    );

    final List<ProductPack> packs = [];
    final packsRaw = json['packs'];
    if (packsRaw is List) {
      for (final item in packsRaw) {
        if (item is Map<String, dynamic>) {
          packs.add(ProductPack.fromJson(item));
        }
      }
    }

    return Product(
      id: id,
      name: productName.toString().trim(),
      code: json['product_code']?.toString(),
      hsnCode: hsnCode,
      productType: productType.toString().toUpperCase(),
      defaultUnit: json['default_unit'] ?? json['inventory_unit_type'],
      stock: stock,
      gstPercent: gstPercent,
      taxes: taxes,
      description: json['description']?.toString().trim(),
      brand: json['brand']?.toString().trim(),
      packs: packs,
      defaultPackId: json['default_pack_id']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'product_code': code,
      'hsn_code': hsnCode,
      'product_type': productType,
      'default_unit': defaultUnit,
      'gst_percent': gstPercent,
      'taxes': taxes.map((t) => t.toJson()).toList(),
      if (description != null) 'description': description,
      if (brand != null) 'brand': brand,
    };
  }
}

class ProductTaxInfo {
  final int id;
  final String name;
  final String category;
  final String subCategory;
  final double percent;

  ProductTaxInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.percent,
  });

  factory ProductTaxInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['tax_id'] ?? json['id'];
    final int id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    double percent = 0;
    if (json['tax_percent'] != null) {
      if (json['tax_percent'] is num) {
        percent = (json['tax_percent'] as num).toDouble();
      } else if (json['tax_percent'] is String) {
        percent = double.tryParse(json['tax_percent'] as String) ?? 0;
      }
    }

    return ProductTaxInfo(
      id: id,
      name: json['tax_name']?.toString() ?? '',
      category: json['tax_category']?.toString() ?? '',
      subCategory: json['tax_sub_category']?.toString() ?? '',
      percent: percent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_id': id,
      'tax_name': name,
      'tax_category': category,
      'tax_sub_category': subCategory,
      'tax_percent': percent,
    };
  }
}
