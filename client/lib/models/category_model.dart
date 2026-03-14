class Category {
  final int catId;
  final String name;
  final int parentCatId;
  final bool isActive;
  final int type;
  final String? imageSlug;
  final String? imageName;
  final int imgLastUpdated;

  Category({
    required this.catId,
    required this.name,
    required this.parentCatId,
    required this.isActive,
    required this.type,
    this.imageSlug,
    this.imageName,
    required this.imgLastUpdated,
  });

  bool get isTopLevel => parentCatId == 0;

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawId = json['cat_id'];
    final int catId;
    if (rawId is int) {
      catId = rawId;
    } else if (rawId is String) {
      catId = int.parse(rawId);
    } else {
      throw FormatException('Invalid cat_id: $rawId');
    }

    final rawParent = json['parent_cat_id'];
    final int parentCatId;
    if (rawParent is int) {
      parentCatId = rawParent;
    } else if (rawParent is String) {
      parentCatId = int.parse(rawParent);
    } else {
      parentCatId = 0;
    }

    return Category(
      catId: catId,
      name: json['name']?.toString() ?? '',
      parentCatId: parentCatId,
      isActive: (json['is_active'] is bool)
          ? json['is_active'] as bool
          : json['is_active'].toString() == '1',
      type: _intFromJson(json['type']),
      imageSlug: json['image_slug']?.toString(),
      imageName: json['image_name']?.toString(),
      imgLastUpdated: _intFromJson(json['img_last_updated']),
    );
  }

  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cat_id': catId,
      'name': name,
      'parent_cat_id': parentCatId,
      'is_active': isActive,
      'type': type,
      'image_slug': imageSlug ?? ' ',
      'image_name': imageName,
      'img_last_updated': imgLastUpdated,
    };
  }
}
