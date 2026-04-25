class PartyResult {
  final int id;
  final String name;
  final String? phone;
  final String? shopName;
  final String? code;

  const PartyResult({
    required this.id,
    required this.name,
    this.phone,
    this.shopName,
    this.code,
  });

  String get displayLabel {
    final parts = <String>[];
    if (name.trim().isNotEmpty) parts.add(name.trim());
    if (shopName != null && shopName!.trim().isNotEmpty) {
      parts.add(shopName!.trim());
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      parts.add(phone!.trim());
    }
    return parts.join(' • ');
  }
}
