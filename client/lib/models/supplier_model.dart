class Supplier {
  final int id;
  final String supplierCode;
  final String supplierName;
  final String? shortName;
  final String? businessType;
  final String? department;
  final String? gstNo;
  final String? panNo;
  final String? tanNo;
  final String? cinNo;
  final String? vatNo;
  final String? registrationNo;
  final String? fssaiNo;
  final String? website;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final String? contactPerson;
  final String? contactPersonEmail;
  final String? contactPersonPhone;
  final String? contactPersonDesignation;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? bankName;
  final String? bankBranch;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? swiftCode;
  final int? paymentTermsDays;
  final double? creditLimit;
  final double? rating;
  final bool isPreferred;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Supplier({
    required this.id,
    required this.supplierCode,
    required this.supplierName,
    this.shortName,
    this.businessType,
    this.department,
    this.gstNo,
    this.panNo,
    this.tanNo,
    this.cinNo,
    this.vatNo,
    this.registrationNo,
    this.fssaiNo,
    this.website,
    this.email,
    this.phone,
    this.alternatePhone,
    this.contactPerson,
    this.contactPersonEmail,
    this.contactPersonPhone,
    this.contactPersonDesignation,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.bankName,
    this.bankBranch,
    this.bankAccountName,
    this.bankAccountNumber,
    this.ifscCode,
    this.swiftCode,
    this.paymentTermsDays,
    this.creditLimit,
    this.rating,
    this.isPreferred = false,
    this.status = 'ACTIVE',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? 0;
    final int id = idValue is int ? idValue : int.tryParse('$idValue') ?? 0;

    return Supplier(
      id: id,
      supplierCode: json['supplier_code']?.toString() ?? 'SUP-$id',
      supplierName: json['supplier_name']?.toString() ?? '',
      shortName: json['short_name']?.toString(),
      businessType: json['business_type']?.toString(),
      department: json['department']?.toString(),
      gstNo: json['gst_no']?.toString(),
      panNo: json['pan_no']?.toString(),
      tanNo: json['tan_no']?.toString(),
      cinNo: json['cin_no']?.toString(),
      vatNo: json['vat_no']?.toString(),
      registrationNo: json['registration_no']?.toString(),
      fssaiNo: json['fssai_no']?.toString(),
      website: json['website']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      alternatePhone: json['alternate_phone']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      contactPersonEmail: json['contact_person_email']?.toString(),
      contactPersonPhone: json['contact_person_phone']?.toString(),
      contactPersonDesignation: json['contact_person_designation']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      pincode: json['pincode']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankBranch: json['bank_branch']?.toString(),
      bankAccountName: json['bank_account_name']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      swiftCode: json['swift_code']?.toString(),
      paymentTermsDays: _intOrNull(json['payment_terms_days']),
      creditLimit: _doubleOrNull(json['credit_limit']),
      rating: _doubleOrNull(json['rating']),
      isPreferred: _boolFromJson(json['is_preferred']),
      status: json['status']?.toString() ?? 'ACTIVE',
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'short_name': shortName,
      'business_type': businessType,
      'department': department,
      'gst_no': gstNo,
      'pan_no': panNo,
      'tan_no': tanNo,
      'cin_no': cinNo,
      'vat_no': vatNo,
      'registration_no': registrationNo,
      'fssai_no': fssaiNo,
      'website': website,
      'email': email,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'contact_person': contactPerson,
      'contact_person_email': contactPersonEmail,
      'contact_person_phone': contactPersonPhone,
      'contact_person_designation': contactPersonDesignation,
      'address_line1': addressLine1,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'ifsc_code': ifscCode,
      'swift_code': swiftCode,
      'payment_terms_days': paymentTermsDays,
      'credit_limit': creditLimit,
      'rating': rating,
      'is_preferred': isPreferred ? 1 : 0,
      'status': status,
      'notes': notes,
    };
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _boolFromJson(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final v = value.toString().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
}

class SupplierProduct {
  final int id;
  final int supplierId;
  final int productId;
  final String? supplierSku;
  final String? supplierProductName;
  final String? description;
  final double? packSize;
  final String? packUnit;
  final double? minOrderQty;
  final double? price;
  final String? currency;
  final double? taxPercent;
  final double? discountPercent;
  final int? leadTimeDays;
  final double? lastPurchasePrice;
  final String? lastPurchaseDate;
  final bool isPreferred;
  final bool isActive;

  SupplierProduct({
    required this.id,
    required this.supplierId,
    required this.productId,
    this.supplierSku,
    this.supplierProductName,
    this.description,
    this.packSize,
    this.packUnit,
    this.minOrderQty,
    this.price,
    this.currency,
    this.taxPercent,
    this.discountPercent,
    this.leadTimeDays,
    this.lastPurchasePrice,
    this.lastPurchaseDate,
    this.isPreferred = false,
    this.isActive = true,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      id: _int(json['id']),
      supplierId: _int(json['supplier_id']),
      productId: _int(json['product_id']),
      supplierSku: json['supplier_sku']?.toString(),
      supplierProductName: json['supplier_product_name']?.toString(),
      description: json['description']?.toString(),
      packSize: Supplier._doubleOrNull(json['pack_size']),
      packUnit: json['pack_unit']?.toString(),
      minOrderQty: Supplier._doubleOrNull(json['min_order_qty']),
      price: Supplier._doubleOrNull(json['price']),
      currency: json['currency']?.toString(),
      taxPercent: Supplier._doubleOrNull(json['tax_percent']),
      discountPercent: Supplier._doubleOrNull(json['discount_percent']),
      leadTimeDays: Supplier._intOrNull(json['lead_time_days']),
      lastPurchasePrice: Supplier._doubleOrNull(json['last_purchase_price']),
      lastPurchaseDate: json['last_purchase_date']?.toString(),
      isPreferred: Supplier._boolFromJson(json['is_preferred']),
      isActive: Supplier._boolFromJson(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'product_id': productId,
      'supplier_sku': supplierSku,
      'supplier_product_name': supplierProductName,
      'description': description,
      'pack_size': packSize,
      'pack_unit': packUnit,
      'min_order_qty': minOrderQty,
      'price': price,
      'currency': currency,
      'tax_percent': taxPercent,
      'discount_percent': discountPercent,
      'lead_time_days': leadTimeDays,
      'last_purchase_price': lastPurchasePrice,
      'last_purchase_date': lastPurchaseDate,
      'is_preferred': isPreferred ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
