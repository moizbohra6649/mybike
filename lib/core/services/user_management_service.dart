import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/roles/domain/entities/role_entity.dart';
import '../../features/showroom/domain/entities/showroom_entity.dart';
import '../../features/auth/data/models/user_profile_model.dart';
import '../../features/roles/data/models/role_model.dart';
import '../../features/showroom/data/models/showroom_model.dart';

export '../../features/auth/domain/entities/user_profile.dart';

/// Managed user with hydrated roles and showroom assignments
class ManagedUser {
  final UserProfile profile;
  final List<RoleEntity> roles;
  final List<ShowroomEntity> showrooms;
  final String? defaultShowroomId;

  const ManagedUser({
    required this.profile,
    this.roles = const [],
    this.showrooms = const [],
    this.defaultShowroomId,
  });
}

/// Paginated user list result
class PaginatedUsers {
  final List<ManagedUser> users;
  final int totalCount;

  const PaginatedUsers({required this.users, required this.totalCount});
}

/// User Management Service
///
/// Handles CRUD operations for system users, role assignments,
/// and showroom access controls backed by Supabase profiles and auth.
class UserManagementService {
  UserManagementService._();
  static final UserManagementService instance = UserManagementService._();

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ─────────────────────────────────────────────
  // User Queries
  // ─────────────────────────────────────────────

  /// Fetch paginated users with optional filters from Supabase
  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? roleFilter,
    String? showroomFilter,
    bool? isActive,
  }) async {
    if (!_isSupabaseLive) {
      return const PaginatedUsers(users: [], totalCount: 0);
    }

    try {
      final client = SupabaseService.client!;
      var query = client.from('profiles').select(
        '*, user_roles(role_id, is_active, roles(id, name, display_name, description, is_system_role)), user_showrooms(showroom_id, is_default, is_active, showrooms(*))',
      );

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        query = query.or('full_name.ilike.%$s%,email.ilike.%$s%');
      }

      final data = await query.order('created_at', ascending: false);
      final rawList = data as List;

      final users = rawList.map((row) {
        final profile = UserProfileModel.fromJson(row);

        List<RoleEntity> roles = [];
        if (row['user_roles'] != null) {
          for (final ur in row['user_roles']) {
            if (ur['roles'] != null && ur['is_active'] == true) {
              roles.add(RoleModel.fromJson(ur['roles']));
            }
          }
        }

        List<ShowroomEntity> showrooms = [];
        String? defaultShowroomId;
        if (row['user_showrooms'] != null) {
          for (final us in row['user_showrooms']) {
            if (us['showrooms'] != null && us['is_active'] == true) {
              showrooms.add(ShowroomModel.fromJson(us['showrooms']));
              if (us['is_default'] == true) {
                defaultShowroomId = us['showroom_id'];
              }
            }
          }
        }

        return ManagedUser(
          profile: profile,
          roles: roles,
          showrooms: showrooms,
          defaultShowroomId: defaultShowroomId,
        );
      }).toList();

      var filtered = users;
      if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
        filtered = filtered.where((u) => u.roles.any((r) => r.name == roleFilter)).toList();
      }
      if (showroomFilter != null && showroomFilter.isNotEmpty && showroomFilter != 'all') {
        filtered = filtered.where((u) => u.showrooms.any((s) => s.id == showroomFilter)).toList();
      }

      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
      final paginated = startIndex < filtered.length ? filtered.sublist(startIndex, endIndex) : <ManagedUser>[];

      return PaginatedUsers(users: paginated, totalCount: filtered.length);
    } catch (e) {
      debugPrint('UserManagementService.fetchUsers error: $e');
      return const PaginatedUsers(users: [], totalCount: 0);
    }
  }

  /// Fetch single user by ID with full details
  Future<ManagedUser?> fetchUserById(String userId) async {
    if (!_isSupabaseLive) return null;

    try {
      final client = SupabaseService.client!;
      final data = await client
          .from('profiles')
          .select('*, user_roles(role_id, is_active, roles(id, name, display_name, description, is_system_role)), user_showrooms(showroom_id, is_default, is_active, showrooms(*))')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      final profile = UserProfileModel.fromJson(data);
      List<RoleEntity> roles = [];
      if (data['user_roles'] != null) {
        for (final ur in data['user_roles']) {
          if (ur['roles'] != null && ur['is_active'] == true) {
            roles.add(RoleModel.fromJson(ur['roles']));
          }
        }
      }

      List<ShowroomEntity> showrooms = [];
      String? defaultShowroomId;
      if (data['user_showrooms'] != null) {
        for (final us in data['user_showrooms']) {
          if (us['showrooms'] != null && us['is_active'] == true) {
            showrooms.add(ShowroomModel.fromJson(us['showrooms']));
            if (us['is_default'] == true) {
              defaultShowroomId = us['showroom_id'];
            }
          }
        }
      }

      return ManagedUser(
        profile: profile,
        roles: roles,
        showrooms: showrooms,
        defaultShowroomId: defaultShowroomId,
      );
    } catch (e) {
      debugPrint('UserManagementService.fetchUserById error: $e');
      return null;
    }
  }

  /// Create a new user profile in Supabase
  Future<ManagedUser> createUser({
    required String email,
    String? password,
    required String fullName,
    String? phone,
    required List<String> roleIds,
    required List<String> showroomIds,
    String? defaultShowroomId,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final client = SupabaseService.client!;

    // Insert into profiles
    final profileRes = await client
        .from('profiles')
        .insert({
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'is_active': true,
        })
        .select()
        .single();

    final userId = profileRes['id'] as String;

    // Assign roles
    if (roleIds.isNotEmpty) {
      final roleInserts = roleIds.map((rid) => {
            'user_id': userId,
            'role_id': rid,
            'is_active': true,
          }).toList();
      await client.from('user_roles').insert(roleInserts);
    }

    // Assign showrooms
    if (showroomIds.isNotEmpty) {
      final showroomInserts = showroomIds.map((sid) => {
            'user_id': userId,
            'showroom_id': sid,
            'is_default': sid == defaultShowroomId,
            'is_active': true,
          }).toList();
      await client.from('user_showrooms').insert(showroomInserts);
    }

    final user = await fetchUserById(userId);
    if (user == null) throw Exception('Failed to fetch created user');
    return user;
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId, {
    String? fullName,
    String? phone,
    bool? isActive,
  }) async {
    if (!_isSupabaseLive) return;

    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (isActive != null) updates['is_active'] = isActive;

    await SupabaseService.client!
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  /// Assign roles to a user (replaces existing assignments)
  Future<void> assignRoles(String userId, List<String> roleIds) async {
    if (!_isSupabaseLive) return;

    final client = SupabaseService.client!;

    await client
        .from('user_roles')
        .update({'is_active': false})
        .eq('user_id', userId);

    if (roleIds.isNotEmpty) {
      final inserts = roleIds.map((rid) => {
            'user_id': userId,
            'role_id': rid,
            'is_active': true,
          }).toList();

      await client
          .from('user_roles')
          .upsert(inserts, onConflict: 'user_id,role_id');
    }
  }

  /// Assign showrooms to a user (replaces existing assignments)
  Future<void> assignShowrooms(
    String userId,
    List<String> showroomIds, {
    String? defaultShowroomId,
  }) async {
    if (!_isSupabaseLive) return;

    final client = SupabaseService.client!;

    await client
        .from('user_showrooms')
        .update({'is_active': false})
        .eq('user_id', userId);

    if (showroomIds.isNotEmpty) {
      final inserts = showroomIds.map((sid) => {
            'user_id': userId,
            'showroom_id': sid,
            'is_default': sid == defaultShowroomId,
            'is_active': true,
          }).toList();

      await client
          .from('user_showrooms')
          .upsert(inserts, onConflict: 'user_id,showroom_id');
    }
  }

  /// Toggle user active status
  Future<void> toggleUserActive(String userId, bool isActive) async {
    await updateUserProfile(userId, isActive: isActive);
  }

  void clear() {}
}
