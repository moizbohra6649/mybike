import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'user_management_service.dart';
import '../../features/showroom/domain/entities/showroom_entity.dart';
import '../../features/showroom/domain/entities/invoice_sequence_entity.dart';
import '../../features/showroom/data/models/showroom_model.dart';
import '../../features/showroom/data/models/invoice_sequence_model.dart';

export '../../features/showroom/domain/entities/showroom_entity.dart';
export '../../features/showroom/domain/entities/invoice_sequence_entity.dart';

/// Showroom domain model enriched with calculated staff and sequence counts
class ShowroomWithStats {
  final ShowroomEntity showroom;
  final int staffCount;
  final int activeSequencesCount;

  const ShowroomWithStats({
    required this.showroom,
    this.staffCount = 0,
    this.activeSequencesCount = 0,
  });
}

/// Showroom Management Service
///
/// Handles CRUD operations for Dealership Showrooms / Branches,
/// User Assignments, and Statutory Document Sequences directly backed by Supabase.
class ShowroomManagementService {
  ShowroomManagementService._();
  static final ShowroomManagementService instance = ShowroomManagementService._();

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

  void resetDevData() {}

  // ─────────────────────────────────────────────
  // Fetch
  // ─────────────────────────────────────────────

  /// Fetch all showrooms with optional filters directly from Supabase
  Future<List<ShowroomWithStats>> fetchShowrooms({
    String? search,
    bool? isActive,
    String? city,
    String? state,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      final client = SupabaseService.client!;
      var query = client.from('showrooms').select();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        query = query.or('name.ilike.%$s%,code.ilike.%$s%,city.ilike.%$s%');
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (state != null && state.isNotEmpty) {
        query = query.eq('state', state);
      }

      final data = await query.order('created_at', ascending: true);
      final rawList = data as List;

      // Fetch user showroom counts to compute staff counts
      Map<String, int> staffCounts = {};
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

      return rawList.map((row) {
        final sModel = ShowroomModel.fromJson(row as Map<String, dynamic>);
        return ShowroomWithStats(
          showroom: sModel,
          staffCount: staffCounts[sModel.id] ?? 0,
          activeSequencesCount: 5,
        );
      }).toList();
    } catch (e) {
      debugPrint('Supabase fetchShowrooms error: $e');
      return [];
    }
  }

  /// Fetch single showroom by ID
  Future<ShowroomEntity?> fetchShowroomById(String showroomId) async {
    if (!_isSupabaseLive) return null;

    try {
      final client = SupabaseService.client!;
      final data = await client.from('showrooms').select().eq('id', showroomId).maybeSingle();
      if (data != null) return ShowroomModel.fromJson(data);
      return null;
    } catch (e) {
      debugPrint('Supabase fetchShowroomById error: $e');
      return null;
    }
  }

  /// Create a new showroom
  Future<ShowroomEntity> createShowroom(
    ShowroomEntity entity, {
    List<InvoiceSequenceEntity>? initialSequences,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final client = SupabaseService.client!;
    final model = ShowroomModel.fromEntity(entity);
    final payload = model.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final res = await client.from('showrooms').insert(payload).select().single();
    final createdShowroom = ShowroomModel.fromJson(res);

    // Auto-create document sequences if sequence table exists
    try {
      final sequencesToInsert = <Map<String, dynamic>>[];
      final prefix = createdShowroom.invoicePrefix;
      final now = DateTime.now();

      for (final docType in DealershipDocType.values) {
        sequencesToInsert.add({
          'showroom_id': createdShowroom.id,
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

    return createdShowroom;
  }

  /// Update showroom details
  Future<ShowroomEntity> updateShowroom(ShowroomEntity entity) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

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
    return ShowroomModel.fromJson(res);
  }

  /// Toggle active / inactive status for showroom
  Future<bool> toggleShowroomStatus(String showroomId, bool isActive) async {
    if (!_isSupabaseLive) return false;

    try {
      final client = SupabaseService.client!;
      await client.from('showrooms').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', showroomId);
      return true;
    } catch (e) {
      debugPrint('Supabase toggleShowroomStatus error: $e');
      rethrow;
    }
  }

  /// Fetch staff members assigned to this showroom
  Future<List<ManagedUser>> fetchShowroomStaff(String showroomId) async {
    final paginated = await UserManagementService.instance.fetchUsers(showroomFilter: showroomId);
    return paginated.users;
  }

  /// Fetch document sequence numbering counters for a showroom
  Future<List<InvoiceSequenceEntity>> fetchShowroomSequences(String showroomId) async {
    if (!_isSupabaseLive) return [];

    try {
      final client = SupabaseService.client!;
      final data = await client
          .from('invoice_sequences')
          .select()
          .eq('showroom_id', showroomId);
      return (data as List).map((row) => InvoiceSequenceModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchShowroomSequences error: $e');
      return [];
    }
  }

  /// Update invoice sequence counter parameters
  Future<InvoiceSequenceEntity> updateInvoiceSequence(
    String sequenceId, {
    String? prefix,
    int? nextNumber,
    int? paddingZeros,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

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
  }
}
