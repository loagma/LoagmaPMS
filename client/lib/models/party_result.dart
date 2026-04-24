class PartyResult {
  final int id;
  final String name;
  final String? phone;
  final String? code;

  const PartyResult({
    required this.id,
    required this.name,
    this.phone,
    this.code,
  });
}
