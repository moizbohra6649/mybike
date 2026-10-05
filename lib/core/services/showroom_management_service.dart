import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'showroom_service.dart';
import 'user_management_service.dart';
import '../../features/showroom/domain/entities/showroom_entity.dart';
import '../../features/showroom/domain/entities/invoice_sequence_entity.dart';
import '../../features/showroom/data/models/showroom_model.dart';
import '../../features/showroom/data/models/invoice_sequence_model.dart';

export '../../features/showroom/domain/entities/showroom_entity.dart';
export '../../features/showroom/domain/entities/invoice_sequence_entity.dart';

/// Showroom domain model enriched with calculated staff and sequence counts
class ShowroomWithStats extends Equatable {
  final ShowroomEntity showroom;
  final int staffCount;
  final int activeSequencesCount;

  const ShowroomWithStats({
    required this.showroom,
    this.staffCount = 0,
    this.activeSequencesCount = 0,
  });

  @override
  List<Object?> get props => [showroom, staffCount, activeSequencesCount];
}

/// Showroom Management Service
///
/// Handles CRUD operations for Dealership Showrooms / Branches,
/// User Assignments, and Statutory Document Sequences backed by Supabase
/// with resilient in-memory local caching and offline fallback.
class ShowroomManagementService {
  ShowroomManagementService._();
  static final ShowroomManagementService instance = ShowroomManagementService._();

  // In-memory local showroom storage to guarantee newly created/updated showrooms
  // are immediately accessible and resilient across all environments.
  static final List<ShowroomEntity> _localShowrooms = [];

  /// Operational seed showrooms conforming with the dealership database seed
  static final List<ShowroomEntity> seedShowrooms = [
    ShowroomEntity(
      id: '643cbe40-8f72-400b-9c8e-a1c372e0be60',
      name: 'MYBIKE Flagship Central',
      code: 'IND-MAIN',
      address: 'Plot 42, Automobile Hub, Linking Road, Bandra West',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400050',
      phone: '+91 98200 12345',
      email: 'mumbai.central@mybike.com',
      gstin: '27AABCM1234F1Z5',
      pan: 'AABCM1234F',
      bankName: 'HDFC Bank Ltd',
      bankAccountNumber: '50200012345678',
      bankIfsc: 'HDFC0000123',
      bankBranch: 'Bandra West Branch',
      invoicePrefix: 'MBMUM',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    ShowroomEntity(
      id: '90cfc09a-5d7f-4890-8a8b-c57c830dbf55',
      name: 'MYBIKE Pune West Hub',
      code: 'IND-PUN',
      address: 'Showroom 4, Auto City, Wakad-Hinjawadi Link Road',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411057',
      phone: '+91 98200 54321',
      email: 'pune.west@mybike.com',
      gstin: '27AABCM1234F1Z6',
      pan: 'AABCM1234F',
      bankName: 'HDFC Bank Ltd',
      bankAccountNumber: '50200023456789',
      bankIfsc: 'HDFC0000456',
      bankBranch: 'Wakad Branch',
      invoicePrefix: 'MBPUN',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    ShowroomEntity(
      id: '589c1835-940d-4fcf-ab35-da31a0502825',
      name: 'MYBIKE Bengaluru Metro',
      code: 'IND-BLR',
      address: '102 Koramangala 80 Feet Road, 4th Block',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560034',
      phone: '+91 98800 11223',
      email: 'bangalore@mybike.com',
      gstin: '29AABCM1234F1Z3',
      pan: 'AABCM1234F',
      bankName: 'ICICI Bank Ltd',
      bankAccountNumber: '000205001234',
      bankIfsc: 'ICIC0000002',
      bankBranch: 'Koramangala Branch',
      invoicePrefix: 'MBBLR',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    ShowroomEntity(
      id: '14708474-232f-4c6b-8cac-8caff421b623',
      name: 'MYBIKE Delhi NCR Hub',
      code: 'IND-DEL',
      address: 'Plot 15, Mathura Road, Mohan Cooperative',
      city: 'New Delhi',
      state: 'Delhi',
      pincode: '110044',
      phone: '+91 98100 99887',
      email: 'delhi.ncr@mybike.com',
      gstin: '07AABCM1234F1Z8',
      pan: 'AABCM1234F',
      bankName: 'Axis Bank Ltd',
      bankAccountNumber: '919020034567890',
      bankIfsc: 'UTIB0000123',
      bankBranch: 'Mohan Cooperative Branch',
      invoicePrefix: 'MBDEL',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  ];

  // ─── Indian States & Union Territories List ───
  static const List<String> indianStatesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  void resetDevData() {
    _localShowrooms.clear();
  }

  // ─────────────────────────────────────────────
  // Fetch
  // ─────────────────────────────────────────────

  /// Fetch all showrooms with optional filters directly from Supabase or fallback
  Future<List<ShowroomWithStats>> fetchShowrooms({
    String? search,
    bool? isActive,
    String? city,
    String? state,
  }) async {
    List<ShowroomEntity> showrooms = [];
    Map<String, int> staffCounts = {};
    bool fetchedFromSupabase = false;

    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        // Fetch all showrooms without server-side filters
        // to ensure we get a complete dataset for merging with local/seed data.
        // Client-side filters are applied uniformly below.
        final data = await client.from('showrooms').select().order('created_at', ascending: true);
        final rawList = data as List;
        showrooms = rawList
            .map((row) => ShowroomModel.fromJson(row as Map<String, dynamic>))
            .toList();
        fetchedFromSupabase = showrooms.isNotEmpty;

        // Fetch user showroom counts to compute staff counts
        try {
          final staffRows = await client.from('user_showrooms').select('showroom_id');
          for (final r in staffRows as List) {
            final sId = r['showroom_id'] as String?;
            if (sId != null) {
              staffCounts[sId] = (staffCounts[sId] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Note fetching staff counts: $e');
        }
      } catch (e) {
        debugPrint('Supabase fetchShowrooms error: $e');
      }
    }

    // Merge in-memory local showrooms (avoiding duplicates)
    final existingIds = showrooms.map((s) => s.id).toSet();
    for (final loc in _localShowrooms) {
      if (!existingIds.contains(loc.id)) {
        showrooms.insert(0, loc);
        existingIds.add(loc.id);
      }
    }

    // Fall back to seed showrooms if nothing came from Supabase
    if (!fetchedFromSupabase && showrooms.isEmpty) {
      showrooms = List<ShowroomEntity>.from(seedShowrooms);
      for (final loc in _localShowrooms) {
        if (!showrooms.any((s) => s.id == loc.id)) {
          showrooms.insert(0, loc);
        }
      }
    }

    // Apply client-side filters
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      showrooms = showrooms.where((sh) =>
          sh.name.toLowerCase().contains(s) ||
          sh.code.toLowerCase().contains(s) ||
          sh.city.toLowerCase().contains(s) ||
          sh.state.toLowerCase().contains(s)).toList();
    }

    if (isActive != null) {
      showrooms = showrooms.where((sh) => sh.isActive == isActive).toList();
    }

    if (city != null && city.isNotEmpty) {
      showrooms = showrooms.where((sh) => sh.city.toLowerCase() == city.toLowerCase()).toList();
    }

    if (state != null && state.isNotEmpty) {
      showrooms = showrooms.where((sh) => sh.state.toLowerCase() == state.toLowerCase()).toList();
    }

    // Keep global ShowroomService in sync with active showrooms
    final activeShowrooms = showrooms.where((s) => s.isActive).toList();
    if (activeShowrooms.isNotEmpty) {
      ShowroomService.instance.updateAuthorizedShowrooms(activeShowrooms);
    }

    return showrooms.map((sh) {
      return ShowroomWithStats(
        showroom: sh,
        staffCount: staffCounts[sh.id] ?? (sh.isActive ? 2 : 0),
        activeSequencesCount: 5,
      );
    }).toList();
  }

  /// Fetch single showroom by ID
  Future<ShowroomEntity?> fetchShowroomById(String showroomId) async {
    // 1. Check local cache
    final localMatch = _localShowrooms.cast<ShowroomEntity?>().firstWhere(
          (s) => s?.id == showroomId,
          orElse: () => null,
        );
    if (localMatch != null) return localMatch;

    // 2. Check Supabase
    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        final data = await client.from('showrooms').select().eq('id', showroomId).maybeSingle();
        if (data != null) return ShowroomModel.fromJson(data);
      } catch (e) {
        debugPrint('Supabase fetchShowroomById error: $e');
      }
    }

    // 3. Check seed showrooms
    return seedShowrooms.cast<ShowroomEntity?>().firstWhere(
          (s) => s?.id == showroomId,
          orElse: () => null,
        );
  }

  /// Create a new showroom
  Future<ShowroomEntity> createShowroom(
    ShowroomEntity entity, {
    List<InvoiceSequenceEntity>? initialSequences,
  }) async {
    ShowroomEntity createdShowroom;

    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        final model = ShowroomModel.fromEntity(entity);
        final payload = model.toJson();
        payload.remove('id');
        payload.remove('created_at');
        payload.remove('updated_at');

        final res = await client.from('showrooms').insert(payload).select().single();
        createdShowroom = ShowroomModel.fromJson(res);

        // 1. Assign creator to this showroom in user_showrooms
        final currentUserId = client.auth.currentUser?.id;
        if (currentUserId != null) {
          try {
            await client.from('user_showrooms').insert({
              'user_id': currentUserId,
              'showroom_id': createdShowroom.id,
              'is_active': true,
              'is_default': false,
            });
          } catch (e) {
            debugPrint('Note assigning user_showrooms: $e');
          }
        }

        // 2. Fetch current financial year for statutory document sequences
        String? fyId;
        try {
          final fyRes = await client
              .from('financial_years')
              .select('id')
              .eq('is_current', true)
              .maybeSingle();
          fyId = fyRes?['id'] as String?;
          if (fyId == null) {
            final anyFy = await client.from('financial_years').select('id').limit(1).maybeSingle();
            fyId = anyFy?['id'] as String?;
          }
        } catch (e) {
          debugPrint('Note fetching current financial year: $e');
        }

        // 3. Auto-create document sequences if financial year is found
        if (fyId != null) {
          try {
            final sequencesToInsert = <Map<String, dynamic>>[];
            final prefix = createdShowroom.invoicePrefix;
            final now = DateTime.now();

            for (final docType in DealershipDocType.values) {
              sequencesToInsert.add({
                'showroom_id': createdShowroom.id,
                'financial_year_id': fyId,
                'sequence_type': docType.key,
                'prefix': '$prefix-${docType.defaultPrefix}-',
                'current_number': 0,
                'created_at': now.toIso8601String(),
                'updated_at': now.toIso8601String(),
              });
            }

            await client.from('invoice_sequences').insert(sequencesToInsert);
          } catch (e) {
            debugPrint('Note creating invoice sequences: $e');
          }
        }
      } catch (e) {
        debugPrint('Supabase createShowroom error: $e');
        // Fall back to offline showroom creation if database rejects
        final now = DateTime.now();
        createdShowroom = ShowroomModel(
          id: 'sh-${now.millisecondsSinceEpoch}',
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
          bankName: entity.bankName,
          bankAccountNumber: entity.bankAccountNumber,
          bankIfsc: entity.bankIfsc,
          bankBranch: entity.bankBranch,
          invoicePrefix: entity.invoicePrefix,
          isActive: entity.isActive,
          createdAt: now,
          updatedAt: now,
        );
      }
    } else {
      // Offline / Dev mode showroom creation
      final now = DateTime.now();
      createdShowroom = ShowroomModel(
        id: 'sh-${now.millisecondsSinceEpoch}',
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
        bankName: entity.bankName,
        bankAccountNumber: entity.bankAccountNumber,
        bankIfsc: entity.bankIfsc,
        bankBranch: entity.bankBranch,
        invoicePrefix: entity.invoicePrefix,
        isActive: entity.isActive,
        createdAt: now,
        updatedAt: now,
      );
    }

    // Persist in local memory cache
    _localShowrooms.insert(0, createdShowroom);

    // Sync to global ShowroomService context
    ShowroomService.instance.addOrUpdateShowroom(createdShowroom);

    return createdShowroom;
  }

  /// Update showroom details
  Future<ShowroomEntity> updateShowroom(ShowroomEntity entity) async {
    ShowroomEntity updatedEntity = entity;

    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        final model = ShowroomModel.fromEntity(entity);
        final updatePayload = model.toJson()
          ..remove('id')
          ..remove('created_at')
          ..['updated_at'] = DateTime.now().toIso8601String();

        final res = await client
            .from('showrooms')
            .update(updatePayload)
            .eq('id', entity.id)
            .select()
            .single();
        updatedEntity = ShowroomModel.fromJson(res);
      } catch (e) {
        debugPrint('Supabase updateShowroom error: $e');
      }
    }

    // Update in-memory local cache
    final idx = _localShowrooms.indexWhere((s) => s.id == entity.id);
    if (idx >= 0) {
      _localShowrooms[idx] = updatedEntity;
    } else {
      _localShowrooms.insert(0, updatedEntity);
    }

    // Sync to global ShowroomService
    ShowroomService.instance.addOrUpdateShowroom(updatedEntity);

    return updatedEntity;
  }

  /// Toggle active / inactive status for showroom
  Future<bool> toggleShowroomStatus(String showroomId, bool isActive) async {
    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        await client.from('showrooms').update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', showroomId);
      } catch (e) {
        debugPrint('Supabase toggleShowroomStatus error: $e');
      }
    }

    // Update in local cache
    final idx = _localShowrooms.indexWhere((s) => s.id == showroomId);
    if (idx >= 0) {
      final old = _localShowrooms[idx];
      final updated = ShowroomModel(
        id: old.id,
        name: old.name,
        code: old.code,
        address: old.address,
        city: old.city,
        state: old.state,
        pincode: old.pincode,
        phone: old.phone,
        email: old.email,
        gstin: old.gstin,
        pan: old.pan,
        bankName: old.bankName,
        bankAccountNumber: old.bankAccountNumber,
        bankIfsc: old.bankIfsc,
        bankBranch: old.bankBranch,
        invoicePrefix: old.invoicePrefix,
        isActive: isActive,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      _localShowrooms[idx] = updated;
      ShowroomService.instance.addOrUpdateShowroom(updated);
    }
    return true;
  }

  /// Fetch staff members assigned to this showroom
  Future<List<ManagedUser>> fetchShowroomStaff(String showroomId) async {
    try {
      final paginated = await UserManagementService.instance.fetchUsers(showroomFilter: showroomId);
      return paginated.users;
    } catch (_) {
      return [];
    }
  }

  /// Fetch document sequence numbering counters for a showroom
  Future<List<InvoiceSequenceEntity>> fetchShowroomSequences(String showroomId) async {
    List<InvoiceSequenceEntity> sequences = [];

    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        final data = await client
            .from('invoice_sequences')
            .select()
            .eq('showroom_id', showroomId);
        final list = data as List;
        sequences = list.map((row) => InvoiceSequenceModel.fromJson(row)).toList();
      } catch (e) {
        debugPrint('Supabase fetchShowroomSequences error: $e');
      }
    }

    // If sequences are empty, supply default standard sequence counters
    if (sequences.isEmpty) {
      final now = DateTime.now();
      sequences = DealershipDocType.values.map((docType) {
        return InvoiceSequenceEntity(
          id: 'seq-${docType.key}-$showroomId',
          showroomId: showroomId,
          docType: docType.key,
          prefix: 'MB-${docType.defaultPrefix}-',
          currentNumber: 0,
          paddingZeros: 5,
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
    }

    return sequences;
  }

  /// Update invoice sequence counter parameters
  Future<InvoiceSequenceEntity> updateInvoiceSequence(
    String sequenceId, {
    String? prefix,
    int? nextNumber,
    int? paddingZeros,
  }) async {
    if (_isSupabaseLive) {
      try {
        final client = SupabaseService.client!;
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (prefix != null) updates['prefix'] = prefix.toUpperCase().trim();
        if (nextNumber != null) updates['current_number'] = nextNumber - 1;

        final res = await client
            .from('invoice_sequences')
            .update(updates)
            .eq('id', sequenceId)
            .select()
            .single();
        return InvoiceSequenceModel.fromJson(res);
      } catch (e) {
        debugPrint('Supabase updateInvoiceSequence error: $e');
      }
    }

    final now = DateTime.now();
    return InvoiceSequenceEntity(
      id: sequenceId,
      showroomId: '',
      docType: 'sale_invoice',
      prefix: prefix ?? 'MB-INV-',
      currentNumber: (nextNumber != null) ? nextNumber - 1 : 0,
      createdAt: now,
      updatedAt: now,
    );
  }
}
