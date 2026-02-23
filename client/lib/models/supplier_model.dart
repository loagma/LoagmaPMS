class Supplier {
  final int id;
  final String supplierCode;
  final String name;
  final String? legalName;
  final String? businessType;
  final String? industry;
  final String? gstin;
  final String? pan;
  final String? tan;
  final String? cin;
  final String? vatNumber;
  final String? registrationNumber;
  final String? website;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final String? fax;
  final String? contactPerson;
  final String? contactPersonEmail;
  final String? contactPersonPhone;
  final String? contactPersonDesignation;
  final String? billingAddressLine1;
  final String? billingAddressLine2;
  final String? billingCity;
  final String? billingState;
  final String? billingCountry;
  final String? billingPostalCode;
  final String? shippingAddressLine1;
  final String? shippingAddressLine2;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingCountry;
  final String? shippingPostalCode;
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
    required this.name,
    this.legalName,
    this.businessType,
    this.industry,
    this.gstin,
    this.pan,
    this.tan,
    this.cin,
    this.vatNumber,
    this.registrationNumber,
    this.website,
    this.email,
    this.phone,
    this.alternatePhone,
    this.fax,
    this.contactPerson,
    this.contactPersonEmail,
    this.contactPersonPhone,
    this.contactPersonDesignation,
    this.billingAddressLine1,
    this.billingAddressLine2,
    this.billingCity,
    this.billingState,
    this.billingCountry,
    this.billingPostalCode,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingCity,
    this.shippingState,
    this.shippingCountry,
    this.shippingPostalCode,
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
      name: json['name']?.toString() ?? '',
      legalName: json['legal_name']?.toString(),
      businessType: json['business_type']?.toString(),
      industry: json['industry']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      tan: json['tan']?.toString(),
      cin: json['cin']?.toString(),
      vatNumber: json['vat_number']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      website: json['website']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      alternatePhone: json['alternate_phone']?.toString(),
      fax: json['fax']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      contactPersonEmail: json['contact_person_email']?.toString(),
      contactPersonPhone: json['contact_person_phone']?.toString(),
      contactPersonDesignation:
          json['contact_person_designation']?.toString(),
      billingAddressLine1: json['billing_address_line1']?.toString(),
      billingAddressLine2: json['billing_address_line2']?.toString(),
      billingCity: json['billing_city']?.toString(),
      billingState: json['billing_state']?.toString(),
      billingCountry: json['billing_country']?.toString(),
      billingPostalCode: json['billing_postal_code']?.toString(),
      shippingAddressLine1: json['shipping_address_line1']?.toString(),
      shippingAddressLine2: json['shipping_address_line2']?.toString(),
      shippingCity: json['shipping_city']?.toString(),
      shippingState: json['shipping_state']?.toString(),
      shippingCountry: json['shipping_country']?.toString(),
      shippingPostalCode: json['shipping_postal_code']?.toString(),
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
      'name': name,
      'legal_name': legalName,
      'business_type': businessType,
      'industry': industry,
      'gstin': gstin,
      'pan': pan,
      'tan': tan,
      'cin': cin,
      'vat_number': vatNumber,
      'registration_number': registrationNumber,
      'website': website,
      'email': email,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'fax': fax,
      'contact_person': contactPerson,
      'contact_person_email': contactPersonEmail,
      'contact_person_phone': contactPersonPhone,
      'contact_person_designation': contactPersonDesignation,
      'billing_address_line1': billingAddressLine1,
      'billing_address_line2': billingAddressLine2,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_country': billingCountry,
      'billing_postal_code': billingPostalCode,
      'shipping_address_line1': shippingAddressLine1,
      'shipping_address_line2': shippingAddressLine2,
      'shipping_city': shippingCity,
      'shipping_state': shippingState,
      'shipping_country': shippingCountry,
      'shipping_postal_code': shippingPostalCode,
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
