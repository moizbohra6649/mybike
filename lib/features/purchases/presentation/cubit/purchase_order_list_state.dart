import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase_order_entity.dart';

sealed class PurchaseOrderListState extends Equatable {
  const PurchaseOrderListState();

  @override
  List<Object?> get props => [];
}

class PurchaseOrderListInitial extends PurchaseOrderListState {
  const PurchaseOrderListInitial();
}

class PurchaseOrderListLoading extends PurchaseOrderListState {
  const PurchaseOrderListLoading();
}

class PurchaseOrderListLoaded extends PurchaseOrderListState {
  final List<PurchaseOrderEntity> orders;
  final String? searchQuery;
  final String? statusFilter;
  final String? categoryFilter;

  const PurchaseOrderListLoaded({
    required this.orders,
    this.searchQuery,
    this.statusFilter,
    this.categoryFilter,
  });

  int get totalCount => orders.length;

  /// Orders still waiting on the vendor: raised but not fully received.
  int get openCount => orders
      .where((o) => o.status == 'draft' || o.status == 'sent' || o.status == 'partial')
      .length;

  int get receivableCount => orders.where((o) => o.isReceivable).length;

  double get totalValue => orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

  double get outstandingPayable =>
      orders.fold<double>(0, (sum, o) => sum + o.balanceAmount);

  PurchaseOrderListLoaded copyWith({
    List<PurchaseOrderEntity>? orders,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    bool clearSearch = false,
    bool clearStatusFilter = false,
    bool clearCategoryFilter = false,
  }) {
    return PurchaseOrderListLoaded(
      orders: orders ?? this.orders,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
    );
  }

  @override
  List<Object?> get props => [orders, searchQuery, statusFilter, categoryFilter];
}

class PurchaseOrderListError extends PurchaseOrderListState {
  final String message;

  const PurchaseOrderListError(this.message);

  @override
  List<Object?> get props => [message];
}
