import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../constants/storage_constants.dart';
import 'permission_service.dart';
import 'showroom_service.dart';
import 'supabase_service.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/data/models/user_profile_model.dart';
import '../../features/roles/domain/entities/role_entity.dart';
import '../../features/roles/data/models/role_model.dart';
import '../../features/showroom/domain/entities/showroom_entity.dart';
import '../../features/showroom/data/models/showroom_model.dart';

/// Authentication Result payload
class AuthSessionData {
  final UserProfile profile;
  final List<RoleEntity> roles;
  final List<ShowroomEntity> showrooms;

  const AuthSessionData({
    required this.profile,
    required this.roles,
    required this.showrooms,
  });
}

/// Supabase Authentication & Session Management Service
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Demo Showrooms for Dev Mode
  static final List<ShowroomEntity> devShowrooms = [
    ShowroomEntity(
      id: 'sh-001',
      name: 'MYBIKE Flagship Central',
      code: 'IND-MAIN',
      address: 'Plot 42, Automobile Hub, Linking Road',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400050',
      phone: '+91 98200 12345',
      email: 'mumbai.central@mybike.com',
      gstin: '27AABCM1234F1Z5',
      invoicePrefix: 'MBMUM',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    ShowroomEntity(
      id: 'sh-002',
      name: 'MYBIKE West Hub',
      code: 'IND-WEST',
      address: 'Near Tech Park, Hinjewadi Phase 1',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411057',
      phone: '+91 98200 67890',
      email: 'pune.west@mybike.com',
      gstin: '27AABCM1234F1Z5',
      invoicePrefix: 'MBPUN',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    ShowroomEntity(
      id: 'sh-003',
      name: 'MYBIKE North Branch',
      code: 'IND-NORTH',
      address: 'Ring Road, Sector 18',
      city: 'Nashik',
      state: 'Maharashtra',
      pincode: '422001',
      phone: '+91 98200 54321',
      email: 'nashik.north@mybike.com',
      gstin: '27AABCM1234F1Z5',
      invoicePrefix: 'MBNAS',
      isActive: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  ];

  /// Sign In with Email & Password
  Future<AuthSessionData> signIn({
    required String email,
    required String password,
  }) async {
    // 1. Live Supabase Authentication
    if (SupabaseConfig.isConfigured && SupabaseService.client != null) {
      try {
        final res = await SupabaseService.client!.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        final user = res.user;
        if (user == null) {
          throw Exception('Authentication failed: No user returned');
        }
        return await loadUserData(user.id, user.email ?? email);
      } catch (e) {
        debugPrint('Supabase Auth error: $e');
        rethrow;
      }
    }

    // 2. Development / Offline Mode
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network

    final normalizedEmail = email.trim().toLowerCase();
    List<String> roles = ['sales_executive'];
    List<ShowroomEntity> userShowrooms = [devShowrooms.first];
    String roleName = 'Sales Executive';

    if (normalizedEmail.contains('admin')) {
      roles = ['super_admin'];
      roleName = 'Super Admin';
      userShowrooms = devShowrooms; // All showrooms
    } else if (normalizedEmail.contains('manager')) {
      roles = ['showroom_manager'];
      roleName = 'Showroom Manager';
      userShowrooms = [devShowrooms[0], devShowrooms[1]];
    } else if (normalizedEmail.contains('account')) {
      roles = ['accountant'];
      roleName = 'Accountant';
      userShowrooms = [devShowrooms[0]];
    }

    final profile = UserProfile(
      id: 'dev-${normalizedEmail.hashCode.abs()}',
      email: normalizedEmail,
      fullName: '$roleName User',
      roles: roles,
      assignedShowroomIds: userShowrooms.map((s) => s.id).toList(),
      defaultShowroomId: userShowrooms.first.id,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime.now(),
    );

    final roleEntities = roles.map((r) {
      return RoleEntity(
        id: 'role-$r',
        name: r,
        displayName: roleName,
        isSystemRole: true,
      );
    }).toList();

    // Persist dev session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.userId, profile.id);
    await prefs.setString(StorageConstants.userEmail, profile.email);

    return AuthSessionData(
      profile: profile,
      roles: roleEntities,
      showrooms: userShowrooms,
    );
  }

  /// Recover existing session from cache or Supabase
  Future<AuthSessionData?> checkSession() async {
    // 1. Live Supabase Session
    if (SupabaseConfig.isConfigured && SupabaseService.client != null) {
      final session = SupabaseService.client!.auth.currentSession;
      if (session != null && !session.isExpired) {
        try {
          return await loadUserData(session.user.id, session.user.email ?? '');
        } catch (e) {
          debugPrint('Session recovery error: $e');
          return null;
        }
      }
      return null;
    }

    // 2. Dev Mode Session Recovery
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(StorageConstants.userEmail);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      return signIn(email: savedEmail, password: 'dev');
    }

    return null;
  }

  /// Sign Out
  ///
  /// Also clears the two singletons that hold state derived from the session.
  /// Without this, signing out left `PermissionService` and `ShowroomService`
  /// populated with the previous user's permissions and showroom access, so the
  /// next login inherited them — and every caller of signOut() had to remember
  /// to clear them itself.
  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.auth.signOut();
      } catch (e) {
        debugPrint('Supabase sign out error: $e');
      }
    }

    PermissionService.instance.clear();
    await ShowroomService.instance.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageConstants.userId);
    await prefs.remove(StorageConstants.userEmail);
    await prefs.remove(StorageConstants.accessToken);
    await prefs.remove(StorageConstants.selectedShowroomId);
  }

  /// Load complete user data (profile, roles, permissions, showrooms) from Supabase
  Future<AuthSessionData> loadUserData(String userId, String email) async {
    final client = SupabaseService.client!;

    // 1. Fetch Profile
    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    UserProfileModel profile;
    if (profileRes != null) {
      profile = UserProfileModel.fromJson(profileRes);
    } else {
      profile = UserProfileModel(
        id: userId,
        email: email,
        fullName: email.split('@').first,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // 2. Fetch User Roles
    final userRolesRes = await client
        .from('user_roles')
        .select('role_id, roles (id, name, display_name, description)')
        .eq('user_id', userId)
        .eq('is_active', true);

    List<RoleEntity> roles = [];
    List<String> roleNames = [];
    for (final row in userRolesRes) {
      if (row['roles'] != null) {
        final r = RoleModel.fromJson(row['roles'] as Map<String, dynamic>);
        roles.add(r);
        roleNames.add(r.name);
      }
    }

    // 3. Fetch Showrooms
    List<ShowroomEntity> showrooms = [];
    if (roleNames.contains('super_admin') || roleNames.contains('admin')) {
      // Admins see all showrooms
      final allShowroomsRes = await client.from('showrooms').select().eq('is_active', true);
      showrooms = allShowroomsRes
          .map((s) => ShowroomModel.fromJson(s))
          .toList();
    } else {
      final userShowroomsRes = await client
          .from('user_showrooms')
          .select('showroom_id, is_default, showrooms (*)')
          .eq('user_id', userId)
          .eq('is_active', true);

      for (final row in userShowroomsRes) {
        if (row['showrooms'] != null) {
          final s = ShowroomModel.fromJson(row['showrooms'] as Map<String, dynamic>);
          showrooms.add(s);
        }
      }
    }

    // Update profile with hydrated roles & showrooms
    final updatedProfile = profile.copyWith(
      roles: roleNames,
      assignedShowroomIds: showrooms.map((s) => s.id).toList(),
      defaultShowroomId: showrooms.isNotEmpty ? showrooms.first.id : null,
    );

    return AuthSessionData(
      profile: updatedProfile,
      roles: roles,
      showrooms: showrooms,
    );
  }
}
