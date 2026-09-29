import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/customers/domain/entities/customer_entity.dart';
import '../../features/customers/domain/entities/customer_document_entity.dart';
import '../../features/customers/domain/entities/lead_entity.dart';
import '../../features/customers/domain/entities/lead_activity_entity.dart';
import '../../features/customers/domain/entities/booking_entity.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/customers/data/models/customer_document_model.dart';
import '../../features/customers/data/models/lead_model.dart';
import '../../features/customers/data/models/lead_activity_model.dart';
import '../../features/customers/data/models/booking_model.dart';

/// Customer Management Service
///
/// Handles all customer CRM operations:
/// - Customer CRUD with KYC verification
/// - KYC document management
/// - Sales lead pipeline
/// - Lead activity timeline
/// - Vehicle bookings with token advance
///
/// Directly connects to Supabase database for persistent live CRUD.
class CustomerManagementService {
  CustomerManagementService._();
  static final CustomerManagementService instance = CustomerManagementService._();

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ═══════════════════════════════════════════════════════════════════
  // SEED / FALLBACK OPERATIONAL CUSTOMERS
  // ═══════════════════════════════════════════════════════════════════

  static final List<CustomerEntity> seedCustomers = [
    CustomerEntity(
      id: 'a1111111-1111-4111-8111-111111111111',
      showroomId: '643cbe40-8f72-400b-9c8e-a1c372e0be60',
      customerNumber: 'CUST-2026-0001',
      firstName: 'Rajesh',
      lastName: 'Sharma',
      mobilePrimary: '9820112233',
      email: 'rajesh.sharma@gmail.com',
      city: 'Mumbai',
      state: 'Maharashtra',
      pinCode: '400050',
      kycStatus: 'verified',
      customerType: 'individual',
      isActive: true,
      createdAt: DateTime(2026, 3, 15),
      updatedAt: DateTime(2026, 3, 15),
    ),
    CustomerEntity(
      id: 'a2222222-2222-4222-8222-222222222222',
      showroomId: '90cfc09a-5d7f-4890-8a8b-c57c830dbf55',
      customerNumber: 'CUST-2026-0002',
      firstName: 'Sneha',
      lastName: 'Patil',
      mobilePrimary: '9890223344',
      email: 'sneha.patil@yahoo.co.in',
      city: 'Pune',
      state: 'Maharashtra',
      pinCode: '411004',
      kycStatus: 'verified',
      customerType: 'individual',
      isActive: true,
      createdAt: DateTime(2026, 3, 20),
      updatedAt: DateTime(2026, 3, 20),
    ),
    CustomerEntity(
      id: 'a3333333-3333-4333-8333-333333333333',
      showroomId: '589c1835-940d-4fcf-ab35-da31a0502825',
      customerNumber: 'CUST-2026-0003',
      firstName: 'Vikram',
      lastName: 'Iyer',
      mobilePrimary: '9845334455',
      email: 'vikram.iyer@outlook.com',
      city: 'Bengaluru',
      state: 'Karnataka',
      pinCode: '560038',
      kycStatus: 'verified',
      customerType: 'individual',
      isActive: true,
      createdAt: DateTime(2026, 3, 23),
      updatedAt: DateTime(2026, 3, 23),
    ),
    CustomerEntity(
      id: 'a4444444-4444-4444-8444-444444444444',
      showroomId: '14708474-232f-4c6b-8cac-8caff421b623',
      customerNumber: 'CUST-2026-0004',
      firstName: 'Amit',
      lastName: 'Verma',
      mobilePrimary: '9811445566',
      email: 'amit.verma@gmail.com',
      city: 'Delhi',
      state: 'Delhi',
      pinCode: '110001',
      kycStatus: 'verified',
      customerType: 'individual',
      isActive: true,
      createdAt: DateTime(2026, 3, 25),
      updatedAt: DateTime(2026, 3, 25),
    ),
    CustomerEntity(
      id: 'a5555555-5555-4555-8555-555555555555',
      showroomId: '643cbe40-8f72-400b-9c8e-a1c372e0be60',
      customerNumber: 'CUST-2026-0005',
      firstName: 'Rahul',
      lastName: 'Mehta',
      mobilePrimary: '9820556677',
      email: 'rahul.mehta@corporatesolutions.in',
      city: 'Mumbai',
      state: 'Maharashtra',
      pinCode: '400001',
      kycStatus: 'verified',
      customerType: 'corporate',
      isActive: true,
      createdAt: DateTime(2026, 3, 28),
      updatedAt: DateTime(2026, 3, 28),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // CUSTOMER OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch customers with optional filters
  Future<List<CustomerEntity>> fetchCustomers({
    String? showroomId,
    String? search,
    String? kycStatus,
    String? customerType,
  }) async {
    List<CustomerEntity> results = [];

    if (_isSupabaseLive) {
      try {
        var query = SupabaseService.client!.from('customers').select();
        if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
          query = query.eq('showroom_id', showroomId);
        }
        if (kycStatus != null && kycStatus.isNotEmpty && kycStatus != 'all') {
          query = query.eq('kyc_status', kycStatus);
        }
        if (customerType != null && customerType.isNotEmpty && customerType != 'all') {
          query = query.eq('customer_type', customerType);
        }
        final response = await query.order('created_at', ascending: false);
        for (final item in (response as List)) {
          try {
            results.add(CustomerModel.fromJson(item as Map<String, dynamic>));
          } catch (err) {
            debugPrint('CustomerManagementService: error parsing row: $err');
          }
        }
      } catch (e) {
        debugPrint('CustomerManagementService.fetchCustomers error: $e');
      }
    }

    // Fall back to seed customers if database returned empty (e.g. unauthenticated session or offline)
    if (results.isEmpty) {
      results = List<CustomerEntity>.from(seedCustomers);
      if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
        results = results.where((c) => c.showroomId == showroomId).toList();
      }
      if (kycStatus != null && kycStatus.isNotEmpty && kycStatus != 'all') {
        results = results.where((c) => c.kycStatus == kycStatus).toList();
      }
      if (customerType != null && customerType.isNotEmpty && customerType != 'all') {
        results = results.where((c) => c.customerType == customerType).toList();
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      results = results.where((c) =>
          c.fullName.toLowerCase().contains(s) ||
          c.mobilePrimary.contains(s) ||
          c.customerNumber.toLowerCase().contains(s) ||
          (c.city ?? '').toLowerCase().contains(s)).toList();
    }

    return results;
  }

  /// Fetch a single customer by ID
  Future<CustomerEntity?> fetchCustomerById(String id) async {
    if (_isSupabaseLive && _uuidRegex.hasMatch(id)) {
      try {
        final response = await SupabaseService.client!.from('customers').select().eq('id', id).maybeSingle();
        if (response != null) {
          return CustomerModel.fromJson(response);
        }
      } catch (e) {
        debugPrint('CustomerManagementService.fetchCustomerById error: $e');
      }
    }

    // Fallback to seed
    try {
      return seedCustomers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new customer, returns the created entity
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = CustomerModel.toInsertJson(customer);
    if (payload['customer_number'] == null || (payload['customer_number'] as String).isEmpty) {
      payload['customer_number'] = 'CUST-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('customers')
        .insert(payload)
        .select()
        .single();
    return CustomerModel.fromJson(response);
  }

  /// Update an existing customer
  Future<CustomerEntity> updateCustomer(String id, CustomerEntity customer) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = CustomerModel.toInsertJson(customer);
    final response = await SupabaseService.client!
        .from('customers')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return CustomerModel.fromJson(response);
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('customers').delete().eq('id', id);
    } catch (e) {
      debugPrint('CustomerManagementService.deleteCustomer error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // KYC & DOCUMENT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  void resetDevData() {}

  /// Alias for updateCustomerKycStatus
  Future<CustomerEntity> updateKycStatus(String customerId, String status, {String? verifiedBy}) =>
      updateCustomerKycStatus(customerId, status, verifiedBy: verifiedBy);

  /// Fetch documents for a customer
  Future<List<CustomerDocumentEntity>> fetchCustomerDocuments(String customerId) async {
    if (!_isSupabaseLive) return [];

    try {
      final response = await SupabaseService.client!
          .from('customer_documents')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => CustomerDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('CustomerManagementService.fetchCustomerDocuments error: $e');
      return [];
    }
  }

  /// Upload / register a customer document
  Future<CustomerDocumentEntity> uploadDocument(CustomerDocumentEntity doc) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = CustomerDocumentModel.toJson(doc);
    payload.remove('id');
    payload.remove('created_at');

    final response = await SupabaseService.client!
        .from('customer_documents')
        .insert(payload)
        .select()
        .single();
    return CustomerDocumentModel.fromJson(response);
  }

  /// Alias for uploadDocument
  Future<CustomerDocumentEntity> addCustomerDocument(CustomerDocumentEntity doc) =>
      uploadDocument(doc);

  /// Verify a KYC document
  Future<void> verifyDocument(String docId, {String? verifiedBy}) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('customer_documents').update({
        'verification_status': 'verified',
        'verified_by': verifiedBy,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', docId);
    } catch (e) {
      debugPrint('CustomerManagementService.verifyDocument error: $e');
    }
  }

  /// Reject a KYC document
  Future<void> rejectDocument(String docId, String reason, {String? verifiedBy}) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('customer_documents').update({
        'verification_status': 'rejected',
        'rejection_reason': reason,
        'verified_by': verifiedBy,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', docId);
    } catch (e) {
      debugPrint('CustomerManagementService.rejectDocument error: $e');
    }
  }

  /// Update overall customer KYC status
  Future<CustomerEntity> updateCustomerKycStatus(String customerId, String status, {String? verifiedBy}) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final updateData = <String, dynamic>{
      'kyc_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == 'verified') {
      updateData['kyc_verified_by'] = verifiedBy;
      updateData['kyc_verified_at'] = DateTime.now().toIso8601String();
    }

    final response = await SupabaseService.client!
        .from('customers')
        .update(updateData)
        .eq('id', customerId)
        .select()
        .single();
    return CustomerModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch leads with optional filters
  Future<List<LeadEntity>> fetchLeads({
    String? showroomId,
    String? status,
    String? priority,
    String? assignedTo,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('leads').select(
        '*, customers(first_name, last_name), vehicle_models(name), vehicle_variants(name)',
      );
      if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (priority != null && priority.isNotEmpty && priority != 'all') {
        query = query.eq('priority', priority);
      }
      if (assignedTo != null && assignedTo.isNotEmpty) {
        query = query.eq('assigned_to', assignedTo);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      final results = rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final cust = row['customers'] as Map<String, dynamic>?;
        if (cust != null) {
          row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
        }
        final model = row['vehicle_models'] as Map<String, dynamic>?;
        if (model != null) {
          row['interested_model_name'] = model['name'];
        }
        final variant = row['vehicle_variants'] as Map<String, dynamic>?;
        if (variant != null) {
          row['interested_variant_name'] = variant['name'];
        }
        return LeadModel.fromJson(row);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((l) =>
            l.displayName.toLowerCase().contains(s) ||
            l.leadNumber.toLowerCase().contains(s)).toList();
      }
      return results;
    } catch (e) {
      debugPrint('CustomerManagementService.fetchLeads error: $e');
      return [];
    }
  }

  /// Fetch a single lead by ID
  Future<LeadEntity?> fetchLeadById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('leads')
          .select('*, customers(first_name, last_name), vehicle_models(name), vehicle_variants(name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;

      final row = Map<String, dynamic>.from(response);
      final cust = row['customers'] as Map<String, dynamic>?;
      if (cust != null) {
        row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
      }
      final model = row['vehicle_models'] as Map<String, dynamic>?;
      if (model != null) {
        row['interested_model_name'] = model['name'];
      }
      final variant = row['vehicle_variants'] as Map<String, dynamic>?;
      if (variant != null) {
        row['interested_variant_name'] = variant['name'];
      }
      return LeadModel.fromJson(row);
    } catch (e) {
      debugPrint('CustomerManagementService.fetchLeadById error: $e');
      return null;
    }
  }

  /// Create a new lead
  Future<LeadEntity> createLead(LeadEntity lead) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = LeadModel.toInsertJson(lead);
    if (payload['lead_number'] == null || (payload['lead_number'] as String).isEmpty) {
      payload['lead_number'] = 'LEAD-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('leads')
        .insert(payload)
        .select()
        .single();
    return LeadModel.fromJson(response);
  }

  /// Update lead
  Future<LeadEntity> updateLead(String id, LeadEntity lead) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = LeadModel.toInsertJson(lead);
    final response = await SupabaseService.client!
        .from('leads')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return LeadModel.fromJson(response);
  }

  /// Fetch lead activities
  Future<List<LeadActivityEntity>> fetchLeadActivities(String leadId) async {
    if (!_isSupabaseLive) return [];

    try {
      final response = await SupabaseService.client!
          .from('lead_activities')
          .select()
          .eq('lead_id', leadId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => LeadActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CustomerManagementService.fetchLeadActivities error: $e');
      return [];
    }
  }

  /// Add a lead activity
  Future<LeadActivityEntity> addLeadActivity(LeadActivityEntity activity) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = LeadActivityModel.toJson(activity);
    payload.remove('id');
    payload.remove('created_at');

    final response = await SupabaseService.client!
        .from('lead_activities')
        .insert(payload)
        .select()
        .single();
    return LeadActivityModel.fromJson(response);
  }

  /// Convert a lead to booking
  Future<BookingEntity> convertLeadToBooking(String leadId, BookingEntity booking) async {
    if (_isSupabaseLive) {
      try {
        await SupabaseService.client!
            .from('leads')
            .update({'status': 'converted', 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', leadId);
      } catch (e) {
        debugPrint('Note updating lead status on conversion: $e');
      }
    }
    return createBooking(booking.copyWith(leadId: leadId));
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOOKING OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch bookings with optional filters
  Future<List<BookingEntity>> fetchBookings({
    String? showroomId,
    String? status,
    String? customerId,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('bookings').select(
        '*, customers(first_name, last_name), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name, hex_code), showrooms(name)',
      );
      if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (customerId != null && customerId.isNotEmpty && _uuidRegex.hasMatch(customerId)) {
        query = query.eq('customer_id', customerId);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      final results = rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final cust = row['customers'] as Map<String, dynamic>?;
        if (cust != null) {
          row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
        }
        final variant = row['vehicle_variants'] as Map<String, dynamic>?;
        if (variant != null) {
          row['variant_name'] = variant['name'];
          final model = variant['vehicle_models'] as Map<String, dynamic>?;
          if (model != null) {
            row['model_name'] = model['name'];
          }
        }
        final color = row['vehicle_colors'] as Map<String, dynamic>?;
        if (color != null) {
          row['color_name'] = color['name'];
          row['color_hex'] = color['hex_code'];
        }
        final showroom = row['showrooms'] as Map<String, dynamic>?;
        if (showroom != null) {
          row['showroom_name'] = showroom['name'];
        }
        return BookingModel.fromJson(row);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((b) =>
            b.bookingNumber.toLowerCase().contains(s) ||
            (b.customerName?.toLowerCase().contains(s) ?? false)).toList();
      }
      return results;
    } catch (e) {
      debugPrint('CustomerManagementService.fetchBookings error: $e');
      return [];
    }
  }

  /// Fetch a single booking by ID
  Future<BookingEntity?> fetchBookingById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('bookings')
          .select(
            '*, customers(first_name, last_name), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name, hex_code), showrooms(name)',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final row = Map<String, dynamic>.from(response);
      final cust = row['customers'] as Map<String, dynamic>?;
      if (cust != null) {
        row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
      }
      final variant = row['vehicle_variants'] as Map<String, dynamic>?;
      if (variant != null) {
        row['variant_name'] = variant['name'];
        final model = variant['vehicle_models'] as Map<String, dynamic>?;
        if (model != null) {
          row['model_name'] = model['name'];
        }
      }
      final color = row['vehicle_colors'] as Map<String, dynamic>?;
      if (color != null) {
        row['color_name'] = color['name'];
        row['color_hex'] = color['hex_code'];
      }
      final showroom = row['showrooms'] as Map<String, dynamic>?;
      if (showroom != null) {
        row['showroom_name'] = showroom['name'];
      }
      return BookingModel.fromJson(row);
    } catch (e) {
      debugPrint('CustomerManagementService.fetchBookingById error: $e');
      return null;
    }
  }

  /// Create a new booking
  Future<BookingEntity> createBooking(BookingEntity booking) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = BookingModel.toInsertJson(booking);
    if (payload['booking_number'] == null || (payload['booking_number'] as String).isEmpty) {
      payload['booking_number'] = 'BK-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('bookings')
        .insert(payload)
        .select()
        .single();
    return BookingModel.fromJson(response);
  }

  /// Update booking status
  Future<BookingEntity> updateBookingStatus(String id, String status) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == 'cancelled') {
      updateData['cancelled_at'] = DateTime.now().toIso8601String();
    }
    if (status == 'delivered') {
      updateData['actual_delivery_date'] = DateTime.now().toIso8601String().substring(0, 10);
    }

    final response = await SupabaseService.client!
        .from('bookings')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    return BookingModel.fromJson(response);
  }

  /// Allocate a vehicle to a booking
  Future<BookingEntity> allocateVehicleToBooking(String bookingId, String vehicleId) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final response = await SupabaseService.client!
        .from('bookings')
        .update({
          'allocated_vehicle_id': vehicleId,
          'status': 'allocated',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .select()
        .single();
    return BookingModel.fromJson(response);
  }

  /// Cancel a booking with reason
  Future<BookingEntity> cancelBooking(String bookingId, String reason) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final response = await SupabaseService.client!
        .from('bookings')
        .update({
          'status': 'cancelled',
          'cancelled_reason': reason,
          'cancelled_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .select()
        .single();
    return BookingModel.fromJson(response);
  }
}
