import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/supplier_management_service.dart';
import 'supplier_list_state.dart';

/// Cubit managing the vendor directory: search, type filter and active status.
class SupplierListCubit extends Cubit<SupplierListState> {
  final SupplierManagementService _service;

  SupplierListCubit({SupplierManagementService? service})
      : _service = service ?? SupplierManagementService.instance,
        super(const SupplierListInitial());

  /// Load vendors, preserving the active filters unless [refresh] is set.
  Future<void> loadSuppliers({bool refresh = false}) async {
    String? currentSearch;
    String? currentType;
    bool? currentActive;

    if (state is SupplierListLoaded && !refresh) {
      final loaded = state as SupplierListLoaded;
      currentSearch = loaded.searchQuery;
      currentType = loaded.typeFilter;
      currentActive = loaded.activeFilter;
    }

    emit(const SupplierListLoading());
    await _fetch(
      search: currentSearch,
      type: currentType,
      isActive: currentActive,
    );
  }

  Future<void> searchSuppliers(String query) async {
    final trimmed = query.trim();
    await _fetch(
      search: trimmed.isEmpty ? null : trimmed,
      type: _currentType,
      isActive: _currentActive,
    );
  }

  Future<void> filterByType(String? type) async {
    await _fetch(
      search: _currentSearch,
      type: type,
      isActive: _currentActive,
    );
  }

  Future<void> filterByActive(bool? isActive) async {
    await _fetch(
      search: _currentSearch,
      type: _currentType,
      isActive: isActive,
    );
  }

  Future<void> clearFilters() async {
    emit(const SupplierListLoading());
    await _fetch();
  }

  /// Toggle a vendor between active and inactive.
  Future<void> toggleSupplierStatus(String supplierId, bool newStatus) async {
    try {
      await _service.toggleSupplierStatus(supplierId, newStatus);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Re-fetch and emit, without flipping back to the loading state — so filter
  /// and search changes update the list in place instead of flashing it.
  Future<void> _fetch({
    String? search,
    String? type,
    bool? isActive,
  }) async {
    try {
      final suppliers = await _service.fetchSuppliers(
        search: search,
        supplierType: type,
        isActive: isActive,
      );

      emit(SupplierListLoaded(
        suppliers: suppliers,
        searchQuery: search,
        typeFilter: type,
        activeFilter: isActive,
      ));
    } catch (e) {
      emit(SupplierListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  String? get _currentSearch =>
      state is SupplierListLoaded ? (state as SupplierListLoaded).searchQuery : null;

  String? get _currentType =>
      state is SupplierListLoaded ? (state as SupplierListLoaded).typeFilter : null;

  bool? get _currentActive =>
      state is SupplierListLoaded ? (state as SupplierListLoaded).activeFilter : null;
}
