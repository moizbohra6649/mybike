import 'package:equatable/equatable.dart';
import '../../domain/entities/supplier_entity.dart';

sealed class SupplierListState extends Equatable {
  const SupplierListState();

  @override
  List<Object?> get props => [];
}

class SupplierListInitial extends SupplierListState {
  const SupplierListInitial();
}

class SupplierListLoading extends SupplierListState {
  const SupplierListLoading();
}

class SupplierListLoaded extends SupplierListState {
  final List<SupplierEntity> suppliers;
  final String? searchQuery;
  final bool? activeFilter;
  final String? typeFilter;

  const SupplierListLoaded({
    required this.suppliers,
    this.searchQuery,
    this.activeFilter,
    this.typeFilter,
  });

  int get totalCount => suppliers.length;
  int get activeCount => suppliers.where((s) => s.isActive).length;
  int get inactiveCount => totalCount - activeCount;
  int get oemCount => suppliers.where((s) => s.supplierType == 'oem').length;

  /// Opening balance still owed across every listed vendor.
  double get totalPayable =>
      suppliers.fold<double>(0, (sum, s) => sum + s.openingBalance);

  SupplierListLoaded copyWith({
    List<SupplierEntity>? suppliers,
    String? searchQuery,
    bool? activeFilter,
    String? typeFilter,
    bool clearSearch = false,
    bool clearActiveFilter = false,
    bool clearTypeFilter = false,
  }) {
    return SupplierListLoaded(
      suppliers: suppliers ?? this.suppliers,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      activeFilter: clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }

  @override
  List<Object?> get props => [suppliers, searchQuery, activeFilter, typeFilter];
}

class SupplierListError extends SupplierListState {
  final String message;

  const SupplierListError(this.message);

  @override
  List<Object?> get props => [message];
}
