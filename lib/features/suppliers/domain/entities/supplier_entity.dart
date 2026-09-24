import 'package:equatable/equatable.dart';

/// Supplier / Vendor Master Domain Entity
///
/// Covers every party the dealership procures from — vehicle OEMs, spare-part
/// distributors, accessory and riding-gear dealers, and service vendors.
class SupplierEntity extends Equatable {
  final String id;

  /// Owning branch. `null` means the vendor is shared by every showroom.
  final String? showroomId;
  final String code;
  final String name;

  /// 'oem', 'spare_parts', 'accessories', 'service' or 'other'.
  final String supplierType;
  final String? contactPerson;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstin;
  final String? pan;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final int paymentTermsDays;
  final double creditLimit;
  final double openingBalance;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierEntity({
    required this.id,
    this.showroomId,
    required this.code,
    required this.name,
    this.supplierType = 'spare_parts',
    this.contactPerson,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstin,
    this.pan,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.paymentTermsDays = 30,
    this.creditLimit = 0,
    this.openingBalance = 0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// A vendor with no branch set is shared by every showroom.
  bool get isShared => showroomId == null;

  String get location =>
      [city, state].where((part) => part != null && part.isNotEmpty).join(', ');

  String get fullAddress =>
      [address, city, state, pincode].where((part) => part != null && part.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [
        id,
        showroomId,
        code,
        name,
        supplierType,
        contactPerson,
        phone,
        alternatePhone,
        email,
        address,
        city,
        state,
        pincode,
        gstin,
        pan,
        bankName,
        bankAccountNumber,
        bankIfsc,
        paymentTermsDays,
        creditLimit,
        openingBalance,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}
