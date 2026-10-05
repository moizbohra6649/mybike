import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_management_service.dart';
import '../../../../core/services/role_management_service.dart';
import '../../../../core/services/showroom_management_service.dart';
import 'user_form_state.dart';

/// User Form (Create/Edit) Cubit
class UserFormCubit extends Cubit<UserFormState> {
  final UserManagementService _userService;
  final RoleManagementService _roleService;

  UserFormCubit({
    UserManagementService? userService,
    RoleManagementService? roleService,
  })  : _userService = userService ?? UserManagementService.instance,
        _roleService = roleService ?? RoleManagementService.instance,
        super(const UserFormInitial());

  /// Initialize form for creating a new user
  Future<void> initNewUser() async {
    emit(const UserFormLoading());
    try {
      final roles = await _roleService.fetchRoles();
      final showroomStats = await ShowroomManagementService.instance.fetchShowrooms(isActive: true);
      final showrooms = showroomStats.map((s) => s.showroom).toList();

      emit(UserFormReady(
        existingUser: null,
        availableRoles: roles.map((r) => r.role).toList(),
        availableShowrooms: showrooms,
        selectedRoleIds: [],
        selectedShowroomIds: [],
      ));
    } catch (e) {
      emit(UserFormError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Load existing user for editing
  Future<void> loadUserForEdit(String userId) async {
    emit(const UserFormLoading());
    try {
      final user = await _userService.fetchUserById(userId);
      if (user == null) {
        emit(const UserFormError('User not found'));
        return;
      }

      final roles = await _roleService.fetchRoles();
      final showroomStats = await ShowroomManagementService.instance.fetchShowrooms(isActive: true);
      final showrooms = showroomStats.map((s) => s.showroom).toList();

      emit(UserFormReady(
        existingUser: user,
        availableRoles: roles.map((r) => r.role).toList(),
        availableShowrooms: showrooms,
        selectedRoleIds: user.roles.map((r) => r.id).toList(),
        selectedShowroomIds: user.showrooms.map((s) => s.id).toList(),
        defaultShowroomId: user.defaultShowroomId,
      ));
    } catch (e) {
      emit(UserFormError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Update role selection
  void updateRoleSelection(List<String> roleIds) {
    if (state is UserFormReady) {
      emit((state as UserFormReady).copyWith(selectedRoleIds: roleIds));
    }
  }

  /// Update showroom selection
  void updateShowroomSelection(List<String> showroomIds) {
    if (state is UserFormReady) {
      final current = state as UserFormReady;
      // If default showroom is removed, clear it
      final defaultId = showroomIds.contains(current.defaultShowroomId)
          ? current.defaultShowroomId
          : (showroomIds.isNotEmpty ? showroomIds.first : null);

      emit(current.copyWith(
        selectedShowroomIds: showroomIds,
        defaultShowroomId: defaultId,
        clearDefault: defaultId == null,
      ));
    }
  }

  /// Set default showroom
  void setDefaultShowroom(String showroomId) {
    if (state is UserFormReady) {
      emit((state as UserFormReady).copyWith(defaultShowroomId: showroomId));
    }
  }

  /// Save user (create or update)
  Future<void> saveUser({
    required String email,
    String? password,
    required String fullName,
    String? phone,
  }) async {
    if (state is! UserFormReady) return;

    final formState = state as UserFormReady;
    emit(const UserFormSaving());

    try {
      if (formState.isEditMode) {
        final userId = formState.existingUser!.profile.id;

        // Update profile
        await _userService.updateUserProfile(
          userId,
          fullName: fullName,
          phone: phone,
        );

        // Update role assignments
        await _userService.assignRoles(userId, formState.selectedRoleIds);

        // Update showroom assignments
        await _userService.assignShowrooms(
          userId,
          formState.selectedShowroomIds,
          defaultShowroomId: formState.defaultShowroomId,
        );

        emit(const UserFormSuccess('User updated successfully'));
      } else {
        // Create new user
        if (password == null || password.isEmpty) {
          emit(const UserFormError('Password is required for new users'));
          return;
        }

        await _userService.createUser(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          roleIds: formState.selectedRoleIds,
          showroomIds: formState.selectedShowroomIds,
          defaultShowroomId: formState.defaultShowroomId,
        );

        emit(const UserFormSuccess('User created successfully'));
      }
    } catch (e) {
      emit(UserFormError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
