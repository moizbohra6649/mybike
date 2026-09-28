import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/analytics_dashboard_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final AnalyticsDashboardService _analyticsService;

  DashboardCubit({AnalyticsDashboardService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsDashboardService(),
        super(const DashboardState());

  Future<void> loadDashboard({String? showroomId, String? period}) async {
    final sId = showroomId ?? state.selectedShowroomId;
    final p = period ?? state.selectedPeriod;

    emit(state.copyWith(
      status: DashboardStatus.loading,
      selectedShowroomId: sId,
      clearShowroom: showroomId == null && sId == null,
      selectedPeriod: p,
    ));

    try {
      var currentShowrooms = state.showrooms;
      if (currentShowrooms.isEmpty) {
        currentShowrooms = await _analyticsService.showroomService.fetchShowrooms();
      }

      final sales = await _analyticsService.getSalesDashboard(showroomId: sId, period: p);
      final purchase = await _analyticsService.getPurchaseDashboard(showroomId: sId, period: p);
      final inventory = await _analyticsService.getInventoryDashboard(showroomId: sId, period: p);
      final finance = await _analyticsService.getFinanceDashboard(showroomId: sId, period: p);
      final profit = await _analyticsService.getProfitDashboard(showroomId: sId, period: p);

      emit(state.copyWith(
        status: DashboardStatus.success,
        showrooms: currentShowrooms,
        salesData: sales,
        purchaseData: purchase,
        inventoryData: inventory,
        financeData: finance,
        profitData: profit,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: 'Failed to load enterprise analytics: $e',
      ));
    }
  }

  void setTab(int tabIndex) {
    emit(state.copyWith(activeTab: tabIndex));
  }

  Future<void> filterByShowroom(String? showroomId) async {
    emit(state.copyWith(
      selectedShowroomId: showroomId,
      clearShowroom: showroomId == null,
    ));
    await loadDashboard(showroomId: showroomId);
  }

  Future<void> filterByPeriod(String period) async {
    emit(state.copyWith(selectedPeriod: period));
    await loadDashboard(period: period);
  }
}
