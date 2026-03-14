class HsnCode {
  final int id;
  final String code;
  final bool isActive;

  HsnCode({
    required this.id,
    required this.code,
    required this.isActive,
  });

  factory HsnCode.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['hsn_id'];
    final int id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.parse(rawId);
    } else {
      throw FormatException('Invalid HSN id: $rawId');
    }

    return HsnCode(
      id: id,
      code: json['hsn_code']?.toString() ?? '',
      isActive: (json['is_active'] is bool)
          ? json['is_active'] as bool
          : json['is_active'].toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hsn_code': code,
      'is_active': isActive,
    };
  }
}

