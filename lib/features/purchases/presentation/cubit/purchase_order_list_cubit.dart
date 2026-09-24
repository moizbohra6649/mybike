import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/purchase_management_service.dart';
import 'purchase_order_list_state.dart';

/// Cubit managing the purchase order register: search, status and category
/// filters.
class PurchaseOrderListCubit extends Cubit<PurchaseOrderListState> {
  final PurchaseManagementService _service;

  PurchaseOrderListCubit({PurchaseManagementService? service})
      : _service = service ?? PurchaseManagementService.instance,
        super(const PurchaseOrderListInitial());

  /// Load orders, preserving the active filters unless [refresh] is set.
  Future<void> loadOrders({bool refresh = false}) async {
    String? search;
    String? status;
    String? category;

    if (state is PurchaseOrderListLoaded && !refresh) {
      final loaded = state as PurchaseOrderListLoaded;
      search = loaded.searchQuery;
      status = loaded.statusFilter;
      category = loaded.categoryFilter;
    }

    emit(const PurchaseOrderListLoading());
    await _fetch(search: search, status: status, category: category);
  }

  Future<void> searchOrders(String query) async {
    final trimmed = query.trim();
    await _fetch(
      search: trimmed.isEmpty ? null : trimmed,
      status: _currentStatus,
      category: _currentCategory,
    );
  }

  Future<void> filterByStatus(String? status) async {
    await _fetch(
      search: _currentSearch,
      status: status,
      category: _currentCategory,
    );
  }

  Future<void> filterByCategory(String? category) async {
    await _fetch(
      search: _currentSearch,
      status: _currentStatus,
      category: category,
    );
  }

  Future<void> clearFilters() async {
    emit(const PurchaseOrderListLoading());
    await _fetch();
  }

  /// Re-fetch and emit, without returning to the loading state — filter and
  /// search changes then update the list in place instead of flashing it.
  Future<void> _fetch({String? search, String? status, String? category}) async {
    try {
      final orders = await _service.fetchPurchaseOrders(
        search: search,
        status: status,
        purchaseCategory: category,
      );

      emit(PurchaseOrderListLoaded(
        orders: orders,
        searchQuery: search,
        statusFilter: status,
        categoryFilter: category,
      ));
    } catch (e) {
      emit(PurchaseOrderListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  String? get _currentSearch => state is PurchaseOrderListLoaded
      ? (state as PurchaseOrderListLoaded).searchQuery
      : null;

  String? get _currentStatus => state is PurchaseOrderListLoaded
      ? (state as PurchaseOrderListLoaded).statusFilter
      : null;

  String? get _currentCategory => state is PurchaseOrderListLoaded
      ? (state as PurchaseOrderListLoaded).categoryFilter
      : null;
}
