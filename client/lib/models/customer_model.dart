class Customer {
  final int id;
  final String name;
  final String? shopName;
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
  final String? latitude;
  final String? longitude;
  final String? dob;
  final String? registerDate;
  final String status;
  final String? createdAt;

  Customer({
    required this.id,
    required this.name,
    this.shopName,
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
    this.latitude,
    this.longitude,
    this.dob,
    this.registerDate,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  String get displayName {
    final parts = <String>[];
    if (name.trim().isNotEmpty) parts.add(name.trim());
    if (shopName != null && shopName!.trim().isNotEmpty) {
      parts.add(shopName!.trim());
    }
    if (contactNumber != null && contactNumber!.trim().isNotEmpty) {
      parts.add(contactNumber!.trim());
    }
    return parts.join(' • ');
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Customer(
      id: id,
      name: json['name']?.toString().trim() ??
          json['customer_name']?.toString().trim() ??
          json['shop_name']?.toString().trim() ??
          'Customer $id',
      shopName: json['shop_name']?.toString().trim() ??
          json['shopName']?.toString().trim(),
      email: json['email']?.toString().trim(),
      contactNumber: json['phone']?.toString().trim() ??
          json['contactNumber']?.toString().trim() ??
          json['contact_number']?.toString().trim(),
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
      latitude: json['latitude']?.toString().trim(),
      longitude: json['longitude']?.toString().trim(),
      dob: json['dob']?.toString().trim(),
      registerDate: json['register_date']?.toString().trim() ??
          json['registerDate']?.toString().trim(),
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (shopName != null && shopName!.isNotEmpty) 'shop_name': shopName,
    if (shopName != null && shopName!.isNotEmpty) 'shopName': shopName,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (contactNumber != null && contactNumber!.isNotEmpty) 'phone': contactNumber,
    if (contactNumber != null && contactNumber!.isNotEmpty) 'contactNumber': contactNumber,
    if (alternatePhone != null && alternatePhone!.isNotEmpty) 'alternate_phone': alternatePhone,
    if (alternatePhone != null && alternatePhone!.isNotEmpty) 'alternatePhone': alternatePhone,
    if (gstNo != null && gstNo!.isNotEmpty) 'gst_no': gstNo,
    if (gstNo != null && gstNo!.isNotEmpty) 'gstNo': gstNo,
    if (panNo != null && panNo!.isNotEmpty) 'pan_no': panNo,
    if (panNo != null && panNo!.isNotEmpty) 'panNo': panNo,
    if (addressLine1 != null && addressLine1!.isNotEmpty) 'address_line1': addressLine1,
    if (addressLine1 != null && addressLine1!.isNotEmpty) 'addressLine1': addressLine1,
    if (city != null && city!.isNotEmpty) 'city': city,
    if (state != null && state!.isNotEmpty) 'state': state,
    if (country != null && country!.isNotEmpty) 'country': country,
    if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (latitude != null && latitude!.isNotEmpty) 'latitude': latitude,
    if (longitude != null && longitude!.isNotEmpty) 'longitude': longitude,
    if (dob != null && dob!.isNotEmpty) 'dob': dob,
    if (registerDate != null && registerDate!.isNotEmpty) 'register_date': registerDate,
    'status': status,
  };
}
