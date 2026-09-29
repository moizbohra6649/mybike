import '../../domain/entities/customer_entity.dart';

/// Customer Data Model — Supabase JSON ↔ Entity mapper
class CustomerModel {
  const CustomerModel._();

  static CustomerEntity fromJson(Map<String, dynamic> json) {
    return CustomerEntity(
      id: json['id']?.toString() ?? '',
      showroomId: json['showroom_id']?.toString() ?? '',
      customerNumber: json['customer_number']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? json['name']?.toString() ?? 'Customer',
      lastName: json['last_name']?.toString() ?? '',
      mobilePrimary: json['mobile_primary']?.toString() ?? json['mobile']?.toString() ?? '',
      mobileSecondary: json['mobile_secondary']?.toString(),
      email: json['email']?.toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
      gender: json['gender']?.toString(),
      addressLine1: json['address_line_1']?.toString(),
      addressLine2: json['address_line_2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pinCode: json['pin_code']?.toString(),
      landmark: json['landmark']?.toString(),
      kycStatus: json['kyc_status']?.toString() ?? 'pending',
      kycVerifiedBy: json['kyc_verified_by']?.toString(),
      kycVerifiedAt: json['kyc_verified_at'] != null
          ? DateTime.tryParse(json['kyc_verified_at'].toString())
          : null,
      customerType: json['customer_type']?.toString() ?? 'individual',
      source: json['source']?.toString(),
      preferredContactMethod: json['preferred_contact_method']?.toString() ?? 'phone',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> toJson(CustomerEntity entity) {
    return {
      'id': entity.id,
      'showroom_id': entity.showroomId,
      'customer_number': entity.customerNumber,
      'first_name': entity.firstName,
      'last_name': entity.lastName,
      'mobile_primary': entity.mobilePrimary,
      'mobile_secondary': entity.mobileSecondary,
      'email': entity.email,
      'date_of_birth': entity.dateOfBirth?.toIso8601String().substring(0, 10),
      'gender': entity.gender,
      'address_line_1': entity.addressLine1,
      'address_line_2': entity.addressLine2,
      'city': entity.city,
      'state': entity.state,
      'pin_code': entity.pinCode,
      'landmark': entity.landmark,
      'kyc_status': entity.kycStatus,
      'kyc_verified_by': entity.kycVerifiedBy,
      'kyc_verified_at': entity.kycVerifiedAt?.toIso8601String(),
      'customer_type': entity.customerType,
      'source': entity.source,
      'preferred_contact_method': entity.preferredContactMethod,
      'is_active': entity.isActive,
      'notes': entity.notes,
      'created_at': entity.createdAt.toIso8601String(),
      'updated_at': entity.updatedAt.toIso8601String(),
    };
  }

  /// Partial JSON for create/update (excludes auto-generated fields)
  static Map<String, dynamic> toInsertJson(CustomerEntity entity) {
    final json = toJson(entity);
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }
}
