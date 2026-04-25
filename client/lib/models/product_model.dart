import 'dart:convert';

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
    // Support both old field names (pack_id/pack_name/pack_wt/pack_ut)
    // and actual DB format (id/description/size/unit/market_price)
    final rawId = json['id'] ??
        json['pack_id'] ??
        json['pi'] ??
        json['packId'] ??
        json['pack_id_str'] ??
        '';

    // Label: prefer description (actual DB field), fall back to pack_name/label/name
    final label = (json['description']?.toString().trim().isNotEmpty == true
            ? json['description']
            : null) ??
        json['pack_name'] ??
        json['label'] ??
        json['name'] ??
        rawId.toString();

    // Weight/size: prefer 'size' (actual DB field), fall back to pack_wt/weight
    double? weight;
    final sizeRaw = json['size'] ?? json['pack_wt'] ?? json['weight'];
    if (sizeRaw != null) {
      if (sizeRaw is num) {
        weight = sizeRaw.toDouble();
      } else {
        weight = double.tryParse(sizeRaw.toString());
      }
    }

    // Price: prefer market_price (actual DB field), fall back to price
    double? price;
    final priceRaw = json['market_price'] ?? json['price'];
    if (priceRaw != null) {
      if (priceRaw is num) {
        price = priceRaw.toDouble();
      } else {
        price = double.tryParse(priceRaw.toString());
      }
    }

    return ProductPack(
      id: rawId.toString(),
      label: label.toString(),
      weight: weight,
      unit: json['unit']?.toString() ??
          json['pack_ut']?.toString() ??
          json['pu']?.toString(),
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

    final packs = _parsePacks(json['packs']);

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

List<ProductPack> _parsePacks(dynamic packsRaw) {
  final parsed = <ProductPack>[];
  final usedIds = <String>{};

  void addPack(Map<String, dynamic> map, {String? mapKey, required int index}) {
    final pack = ProductPack.fromJson(map);
    var id = pack.id.trim();
    if (id.isEmpty) {
      final base = mapKey?.trim().isNotEmpty == true
          ? mapKey!.trim()
          : _packFallbackBase(pack, map, index);
      id = base;
    }

    var uniqueId = id;
    var dedupe = 1;
    while (usedIds.contains(uniqueId)) {
      dedupe++;
      uniqueId = '${id}_$dedupe';
    }
    usedIds.add(uniqueId);

    parsed.add(
      ProductPack(
        id: uniqueId,
        label: pack.label,
        weight: pack.weight,
        unit: pack.unit,
        price: pack.price,
      ),
    );
  }

  void parseList(List<dynamic> list) {
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic>) {
        addPack(item, index: i);
      } else if (item is Map) {
        addPack(Map<String, dynamic>.from(item), index: i);
      }
    }
  }

  void parseMap(Map<dynamic, dynamic> map) {
    var i = 0;
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final normalized = Map<String, dynamic>.from(value);
        normalized['pi'] ??= key?.toString();
        addPack(normalized, mapKey: key?.toString(), index: i);
      } else if (value is Map) {
        final normalized = Map<String, dynamic>.from(value);
        normalized['pi'] ??= key?.toString();
        addPack(normalized, mapKey: key?.toString(), index: i);
      }
      i++;
    });
  }

  if (packsRaw is List) {
    parseList(packsRaw);
  } else if (packsRaw is Map) {
    parseMap(packsRaw);
  } else if (packsRaw is String) {
    final text = packsRaw.trim();
    if (text.isEmpty || text == '[]' || text == '{}') return parsed;
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        parseList(decoded);
      } else if (decoded is Map) {
        parseMap(decoded);
      }
    } catch (_) {
      // Ignore malformed packs payload.
    }
  }

  return parsed;
}

String _packFallbackBase(ProductPack pack, Map<String, dynamic> raw, int index) {
  final label = pack.label.trim().isNotEmpty ? pack.label.trim() : 'pack';
  final unit = (pack.unit ?? raw['pu']?.toString() ?? '').trim();
  final sizeValue = pack.weight ?? double.tryParse(raw['ps']?.toString() ?? '');
  final size = sizeValue == null
      ? ''
      : (sizeValue % 1 == 0 ? sizeValue.toInt().toString() : sizeValue.toString());
  final suffix = [size, unit].where((e) => e.isNotEmpty).join('_');
  final normalizedLabel = label.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  if (suffix.isNotEmpty) return '${normalizedLabel}_$suffix';
  return '${normalizedLabel}_${index + 1}';
}

class ProductSelection {
  final Product product;
  final ProductPack? selectedPack;

  const ProductSelection({required this.product, this.selectedPack});
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
