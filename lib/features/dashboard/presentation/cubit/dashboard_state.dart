import 'package:equatable/equatable.dart';
import '../../../../core/services/showroom_management_service.dart';
import '../../domain/entities/finance_dashboard_data.dart';
import '../../domain/entities/inventory_dashboard_data.dart';
import '../../domain/entities/profit_dashboard_data.dart';
import '../../domain/entities/purchase_dashboard_data.dart';
import '../../domain/entities/sales_dashboard_data.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final int activeTab; // 0: Overview, 1: Sales, 2: Purchases, 3: Inventory, 4: Finance, 5: Profit
  final String? selectedShowroomId; // null for All Showrooms
  final String selectedPeriod; // 'month', 'quarter', 'year'
  final List<ShowroomWithStats> showrooms;
  final SalesDashboardData? salesData;
  final PurchaseDashboardData? purchaseData;
  final InventoryDashboardData? inventoryData;
  final FinanceDashboardData? financeData;
  final ProfitDashboardData? profitData;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.activeTab = 0,
    this.selectedShowroomId,
    this.selectedPeriod = 'month',
    this.showrooms = const [],
    this.salesData,
    this.purchaseData,
    this.inventoryData,
    this.financeData,
    this.profitData,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    int? activeTab,
    String? selectedShowroomId,
    bool clearShowroom = false,
    String? selectedPeriod,
    List<ShowroomWithStats>? showrooms,
    SalesDashboardData? salesData,
    PurchaseDashboardData? purchaseData,
    InventoryDashboardData? inventoryData,
    FinanceDashboardData? financeData,
    ProfitDashboardData? profitData,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      activeTab: activeTab ?? this.activeTab,
      selectedShowroomId: clearShowroom ? null : (selectedShowroomId ?? this.selectedShowroomId),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      showrooms: showrooms ?? this.showrooms,
      salesData: salesData ?? this.salesData,
      purchaseData: purchaseData ?? this.purchaseData,
      inventoryData: inventoryData ?? this.inventoryData,
      financeData: financeData ?? this.financeData,
      profitData: profitData ?? this.profitData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeTab,
        selectedShowroomId,
        selectedPeriod,
        showrooms,
        salesData,
        purchaseData,
        inventoryData,
        financeData,
        profitData,
        errorMessage,
      ];
}
