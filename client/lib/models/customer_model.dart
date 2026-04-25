class Customer {
  final int id;
  final String name;
  final String? email;
  final String? contactNumber;
  final String? alternatePhone;
  final String? gstNo;
  final String? panNo;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? notes;
  final String status;
  final String? createdAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.contactNumber,
    this.alternatePhone,
    this.gstNo,
    this.panNo,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.notes,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Customer(
      id: id,
      name: json['name']?.toString().trim() ?? 'Customer $id',
      email: json['email']?.toString().trim(),
      contactNumber: json['contactNumber']?.toString().trim() ??
          json['contact_number']?.toString().trim() ??
          json['phone']?.toString().trim(),
      alternatePhone: json['alternatePhone']?.toString().trim() ??
          json['alternate_phone']?.toString().trim(),
      gstNo: json['gstNo']?.toString().trim() ??
          json['gst_no']?.toString().trim(),
      panNo: json['panNo']?.toString().trim() ??
          json['pan_no']?.toString().trim(),
      addressLine1: json['addressLine1']?.toString().trim() ??
          json['address_line1']?.toString().trim() ??
          json['address']?.toString().trim(),
      city: json['city']?.toString().trim(),
      state: json['state']?.toString().trim(),
      country: json['country']?.toString().trim(),
      pincode: json['pincode']?.toString().trim(),
      notes: json['notes']?.toString().trim(),
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (contactNumber != null && contactNumber!.isNotEmpty) 'contactNumber': contactNumber,
    if (alternatePhone != null && alternatePhone!.isNotEmpty) 'alternatePhone': alternatePhone,
    if (gstNo != null && gstNo!.isNotEmpty) 'gstNo': gstNo,
    if (panNo != null && panNo!.isNotEmpty) 'panNo': panNo,
    if (addressLine1 != null && addressLine1!.isNotEmpty) 'addressLine1': addressLine1,
    if (city != null && city!.isNotEmpty) 'city': city,
    if (state != null && state!.isNotEmpty) 'state': state,
    if (country != null && country!.isNotEmpty) 'country': country,
    if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'status': status,
    'role': 'Customer',
  };
}
