import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';
import '../../features/showroom/domain/entities/showroom_entity.dart';
import 'permission_service.dart';

/// Showroom Context Manager
///
/// Ensures all business queries, stock operations, and transactions
/// are properly scoped to the active showroom.
class ShowroomService {
  ShowroomService._();
  static final ShowroomService instance = ShowroomService._();

  ShowroomEntity? _activeShowroom;
  List<ShowroomEntity> _authorizedShowrooms = [];

  final ValueNotifier<ShowroomEntity?> activeShowroomNotifier =
      ValueNotifier<ShowroomEntity?>(null);

  /// Active showroom in current session
  ShowroomEntity? get activeShowroom => _activeShowroom;

  /// All showrooms the current user is authorized to view
  List<ShowroomEntity> get authorizedShowrooms => _authorizedShowrooms;

  /// Check if user has multiple authorized showrooms
  bool get hasMultipleShowrooms => _authorizedShowrooms.length > 1;

  /// Dynamically add or update a showroom in authorized list
  void addOrUpdateShowroom(ShowroomEntity showroom, {bool setActiveIfEmpty = true}) {
    final idx = _authorizedShowrooms.indexWhere((s) => s.id == showroom.id);
    if (idx >= 0) {
      _authorizedShowrooms[idx] = showroom;
      if (_activeShowroom?.id == showroom.id) {
        _activeShowroom = showroom;
        activeShowroomNotifier.value = showroom;
      }
    } else {
      _authorizedShowrooms.add(showroom);
      if (_activeShowroom == null && setActiveIfEmpty) {
        _activeShowroom = showroom;
        activeShowroomNotifier.value = showroom;
      }
    }
  }

  /// Update the full list of authorized showrooms
  void updateAuthorizedShowrooms(List<ShowroomEntity> showrooms) {
    if (showrooms.isEmpty) return;
    _authorizedShowrooms = List.from(showrooms);
    if (_activeShowroom == null) {
      _activeShowroom = _authorizedShowrooms.first;
      activeShowroomNotifier.value = _activeShowroom;
    } else {
      final match = _authorizedShowrooms.where((s) => s.id == _activeShowroom!.id);
      if (match.isNotEmpty) {
        _activeShowroom = match.first;
        activeShowroomNotifier.value = _activeShowroom;
      }
    }
  }

  /// Initialize authorized showrooms and load active selection
  Future<void> initialize({
    required List<ShowroomEntity> authorizedShowrooms,
    String? defaultShowroomId,
  }) async {
    _authorizedShowrooms = authorizedShowrooms;

    if (_authorizedShowrooms.isEmpty) {
      _activeShowroom = null;
      activeShowroomNotifier.value = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(StorageConstants.selectedShowroomId);

    ShowroomEntity? targetShowroom;

    // 1. Try restoring saved showroom if valid
    if (savedId != null) {
      try {
        targetShowroom = _authorizedShowrooms.firstWhere((s) => s.id == savedId);
      } catch (_) {
        targetShowroom = null;
      }
    }

    // 2. Try user default showroom
    if (targetShowroom == null && defaultShowroomId != null) {
      try {
        targetShowroom = _authorizedShowrooms.firstWhere((s) => s.id == defaultShowroomId);
      } catch (_) {
        targetShowroom = null;
      }
    }

    // 3. Fallback to first available showroom
    targetShowroom ??= _authorizedShowrooms.first;

    await switchShowroom(targetShowroom);
  }

  /// Switch the active showroom context
  Future<void> switchShowroom(ShowroomEntity showroom) async {
    if (!canAccess(showroom.id)) {
      debugPrint('⛔ Access denied to showroom: ${showroom.name} (${showroom.id})');
      return;
    }

    _activeShowroom = showroom;
    activeShowroomNotifier.value = showroom;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.selectedShowroomId, showroom.id);
    debugPrint('🏢 Showroom context switched to: ${showroom.name} [${showroom.code}]');
  }

  /// Check if active user has permission to access this showroom
  bool canAccess(String showroomId) {
    if (PermissionService.instance.isSuperAdmin || PermissionService.instance.isAdmin) {
      return true;
    }
    return _authorizedShowrooms.any((s) => s.id == showroomId);
  }

  /// Clear context on user logout
  Future<void> clear() async {
    _activeShowroom = null;
    _authorizedShowrooms = [];
    activeShowroomNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageConstants.selectedShowroomId);
  }
}
