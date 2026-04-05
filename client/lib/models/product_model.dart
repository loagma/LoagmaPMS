class Product {
  final int id;
  final String name;
  final String? code;
  final String? hsnCode;
  final String productType; // 'FINISHED' or 'RAW'
  final String? defaultUnit; // 'WEIGHT', 'QUANTITY', 'LITRE', 'METER'
  final double? stock; // Available stock (optional, when include_stock=1)
  final double gstPercent;
  final List<ProductTaxInfo> taxes;

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
