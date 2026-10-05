import '../../domain/entities/showroom_entity.dart';

/// Showroom Model with JSON serialization for Supabase
class ShowroomModel extends ShowroomEntity {
  const ShowroomModel({
    required super.id,
    required super.name,
    required super.code,
    required super.address,
    required super.city,
    required super.state,
    required super.pincode,
    required super.phone,
    super.email,
    super.gstin,
    super.pan,
    super.logoUrl,
    super.bankName,
    super.bankAccountNumber,
    super.bankIfsc,
    super.bankBranch,
    super.invoicePrefix = 'MB',
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShowroomModel.fromJson(Map<String, dynamic> json) {
    return ShowroomModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Showroom',
      code: json['code']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      bankIfsc: json['bank_ifsc']?.toString(),
      bankBranch: json['bank_branch']?.toString(),
      invoicePrefix: json['invoice_prefix']?.toString() ?? 'MB',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'pan': pan,
      'logo_url': logoUrl,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'bank_branch': bankBranch,
      'invoice_prefix': invoicePrefix,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShowroomModel.fromEntity(ShowroomEntity entity) {
    return ShowroomModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      phone: entity.phone,
      email: entity.email,
      gstin: entity.gstin,
      pan: entity.pan,
      logoUrl: entity.logoUrl,
      bankName: entity.bankName,
      bankAccountNumber: entity.bankAccountNumber,
      bankIfsc: entity.bankIfsc,
      bankBranch: entity.bankBranch,
      invoicePrefix: entity.invoicePrefix,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
