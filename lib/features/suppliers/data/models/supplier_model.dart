import '../../domain/entities/supplier_entity.dart';

/// Supplier Model with JSON serialization for Supabase
class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    super.showroomId,
    required super.code,
    required super.name,
    super.supplierType = 'spare_parts',
    super.contactPerson,
    required super.phone,
    super.alternatePhone,
    super.email,
    super.address,
    super.city,
    super.state,
    super.pincode,
    super.gstin,
    super.pan,
    super.bankName,
    super.bankAccountNumber,
    super.bankIfsc,
    super.paymentTermsDays = 30,
    super.creditLimit = 0,
    super.openingBalance = 0,
    super.isActive = true,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      showroomId: json['showroom_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      supplierType: json['supplier_type'] as String? ?? 'spare_parts',
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String,
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      paymentTermsDays: (json['payment_terms_days'] as num?)?.toInt() ?? 30,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showroom_id': showroomId,
      'code': code,
      'name': name,
      'supplier_type': supplierType,
      'contact_person': contactPerson,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gstin': gstin,
      'pan': pan,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'payment_terms_days': paymentTermsDays,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Payload for an INSERT — lets the database assign the id and timestamps.
  Map<String, dynamic> toInsertJson() {
    final json = toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    return json;
  }

  factory SupplierModel.fromEntity(SupplierEntity entity) {
    return SupplierModel(
      id: entity.id,
      showroomId: entity.showroomId,
      code: entity.code,
      name: entity.name,
      supplierType: entity.supplierType,
      contactPerson: entity.contactPerson,
      phone: entity.phone,
      alternatePhone: entity.alternatePhone,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      gstin: entity.gstin,
      pan: entity.pan,
      bankName: entity.bankName,
      bankAccountNumber: entity.bankAccountNumber,
      bankIfsc: entity.bankIfsc,
      paymentTermsDays: entity.paymentTermsDays,
      creditLimit: entity.creditLimit,
      openingBalance: entity.openingBalance,
      isActive: entity.isActive,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SupplierModel copyWith({
    String? showroomId,
    String? code,
    String? name,
    String? supplierType,
    String? contactPerson,
    String? phone,
    String? alternatePhone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? pan,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    int? paymentTermsDays,
    double? creditLimit,
    double? openingBalance,
    bool? isActive,
    String? notes,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id,
      showroomId: showroomId ?? this.showroomId,
      code: code ?? this.code,
      name: name ?? this.name,
      supplierType: supplierType ?? this.supplierType,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
