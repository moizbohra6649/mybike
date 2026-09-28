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

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

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
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('customers').select();
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (kycStatus != null && kycStatus.isNotEmpty && kycStatus != 'all') {
        query = query.eq('kyc_status', kycStatus);
      }
      if (customerType != null && customerType.isNotEmpty && customerType != 'all') {
        query = query.eq('customer_type', customerType);
      }
      final response = await query.order('created_at', ascending: false);
      final results = (response as List).map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((c) =>
            c.fullName.toLowerCase().contains(s) ||
            c.mobilePrimary.contains(s) ||
            c.customerNumber.toLowerCase().contains(s)).toList();
      }
      return results;
    } catch (e) {
      debugPrint('CustomerManagementService.fetchCustomers error: $e');
      return [];
    }
  }

  /// Fetch a single customer by ID
  Future<CustomerEntity?> fetchCustomerById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!.from('customers').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return CustomerModel.fromJson(response);
    } catch (e) {
      debugPrint('CustomerManagementService.fetchCustomerById error: $e');
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
      if (showroomId != null && showroomId.isNotEmpty) {
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
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (customerId != null && customerId.isNotEmpty) {
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
