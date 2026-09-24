import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/charts/bar_chart_card.dart';
import '../widgets/charts/donut_chart_card.dart';
import '../widgets/charts/line_trend_chart_card.dart';
import '../widgets/charts/progress_breakdown_card.dart';

/// Master Executive Analytics & Command Center Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return AppScaffold(
      title: 'Enterprise Analytics Command Center',
      activeNavigationId: 'dashboard',
      actions: [
        IconButton(
          tooltip: 'Refresh Analytics',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<DashboardCubit>().loadDashboard(),
        ),
      ],
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading && state.salesData == null) {
            return AppSkeleton.dashboard();
          }

          if (state.status == DashboardStatus.failure && state.salesData == null) {
            return AppErrorState(
              title: 'Failed to Load Analytics',
              message: state.errorMessage ?? 'An error occurred while compiling dashboard metrics.',
              onRetry: () => context.read<DashboardCubit>().loadDashboard(),
            );
          }

          return Column(
            children: [
              // Global Filter Bar (Showroom Scope + Date Range)
              _buildGlobalFilterBar(context, state, isDesktop, isDark),

              // Tab Selector (Overview, Sales, Purchases, Inventory, Finance, Profit)
              _buildTabSelector(context, state, isDark),

              // Main Active Dashboard View
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing24 : AppDimensions.spacing16),
                  child: _buildActiveDashboard(context, state, currency, isDesktop, isDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── 1. Global Filter Bar ───
  Widget _buildGlobalFilterBar(
    BuildContext context,
    DashboardState state,
    bool isDesktop,
    bool isDark,
  ) {
    final periods = [
      {'id': 'month', 'label': 'This Month (Sep)'},
      {'id': 'quarter', 'label': 'This Quarter (Q2)'},
      {'id': 'year', 'label': 'FY 2026-27'},
    ];

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: state.selectedShowroomId,
        icon: const Icon(Icons.arrow_drop_down),
        isExpanded: !isDesktop,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        dropdownColor: isDark ? const Color(0xFF242832) : Colors.white,
        items: const [
          DropdownMenuItem(value: null, child: Text('All Showrooms (Enterprise)')),
          DropdownMenuItem(value: 'showroom-mumbai-main', child: Text('Mumbai Flagship — Central')),
          DropdownMenuItem(value: 'showroom-pune-west', child: Text('Pune West Hub — Deccan')),
          DropdownMenuItem(value: 'showroom-bangalore-metro', child: Text('Bangalore Metro — Indiranagar')),
        ],
        onChanged: (val) => context.read<DashboardCubit>().filterByShowroom(val),
      ),
    );

    final showroomSelector = Row(
      mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
      children: [
        const Icon(Icons.storefront_outlined, size: 20, color: AppColors.primaryYellow),
        const SizedBox(width: 8),
        if (isDesktop)
          dropdown
        else
          Expanded(child: dropdown),
      ],
    );

    final periodPills = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = state.selectedPeriod == p['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                p['label'] as String,
                style: AppTypography.captionLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryYellow,
              onSelected: (selected) {
                if (selected) context.read<DashboardCubit>().filterByPeriod(p['id'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                showroomSelector,
                periodPills,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                showroomSelector,
                const SizedBox(height: 8),
                periodPills,
              ],
            ),
    );
  }

  // ─── 2. Tab Navigation Bar ───
  Widget _buildTabSelector(BuildContext context, DashboardState state, bool isDark) {
    final tabs = [
      {'title': 'Executive Overview', 'icon': Icons.space_dashboard_outlined},
      {'title': 'Sales Dashboard', 'icon': Icons.receipt_long_outlined},
      {'title': 'Purchase Dashboard', 'icon': Icons.shopping_bag_outlined},
      {'title': 'Inventory Dashboard', 'icon': Icons.inventory_2_outlined},
      {'title': 'Finance Dashboard', 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'Profit & Margins', 'icon': Icons.trending_up_rounded},
    ];

    return Container(
      color: isDark ? const Color(0xFF14171E) : Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final tab = entry.value;
            final isSelected = state.activeTab == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => context.read<DashboardCubit>().setTab(idx),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryYellow : (isDark ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab['title'] as String,
                        style: AppTypography.captionLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── 3. Active Dashboard Router ───
  Widget _buildActiveDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    switch (state.activeTab) {
      case 0:
        return _buildExecutiveOverview(context, state, currency, isDesktop, isDark);
      case 1:
        return _buildSalesDashboard(context, state, currency, isDesktop, isDark);
      case 2:
        return _buildPurchaseDashboard(context, state, currency, isDesktop, isDark);
      case 3:
        return _buildInventoryDashboard(context, state, currency, isDesktop, isDark);
      case 4:
        return _buildFinanceDashboard(context, state, currency, isDesktop, isDark);
      case 5:
        return _buildProfitDashboard(context, state, currency, isDesktop, isDark);
      default:
        return _buildExecutiveOverview(context, state, currency, isDesktop, isDark);
    }
  }

  // ─── TAB 0: EXECUTIVE OVERVIEW ───
  Widget _buildExecutiveOverview(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final sales = state.salesData;
    final inventory = state.inventoryData;
    final finance = state.financeData;
    final profit = state.profitData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enterprise Scorecard Grid
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Gross Revenue', currency.format(sales?.totalRevenue ?? 4250000), '94.2% of target', Icons.trending_up, AppColors.primaryYellow, width),
              _buildMetricCard('Stock Valuation', currency.format(inventory?.totalStockValuationInr ?? 5510000), '${inventory?.totalUnitsOnHand ?? 38} units on hand', Icons.inventory_2_outlined, AppColors.info, width),
              _buildMetricCard('Liquid Treasury', currency.format(finance?.totalLiquidFunds ?? 2560000), 'Cash + Bank accounts', Icons.account_balance_outlined, AppColors.success, width),
              _buildMetricCard('EBITDA (Net Profit)', currency.format(profit?.ebitda ?? 480000), '${(profit?.ebitdaMarginPercent ?? 11.3).toStringAsFixed(1)}% net margin', Icons.attach_money_rounded, AppColors.warning, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Quick Operations Action Bar
        Text('Quick Operations Launchpad', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButton(
              label: 'New Customer Booking',
              leadingIcon: Icons.add,
              // Was RouteNames.bookingCreate — a constant with no registered
              // route, so goNamed threw and the button did nothing. The booking
              // wizard is mounted at /sales/create (RouteNames.saleCreate).
              onPressed: () => context.goNamed(RouteNames.saleCreate),
            ),
            AppButton(
              label: 'Vehicle Inwarding',
              leadingIcon: Icons.local_shipping_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.goNamed(RouteNames.stockInward),
            ),
            AppButton(
              label: 'Record Financial Voucher',
              leadingIcon: Icons.payments_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.goNamed(RouteNames.voucherCreate),
            ),
            AppButton(
              label: 'GST Statutory Hub',
              leadingIcon: Icons.calculate_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.goNamed(RouteNames.gstDashboard),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing24),

        // High Level Visuals
        if (sales != null && profit != null) ...[
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: LineTrendChartCard(
                    title: 'Monthly Revenue Run Rate',
                    subtitle: 'Current vs Target Plan (₹ Lakhs)',
                    data: sales.monthlyRevenueTrend,
                    primarySeriesLabel: 'Actual',
                    secondarySeriesLabel: 'Target',
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing20),
                Expanded(
                  child: DonutChartCard(
                    title: 'Revenue by Powertrain',
                    subtitle: 'Petrol vs Green EV Sales Volume',
                    data: sales.powertrainShare,
                    centerTitle: '${sales.deliveredBikesCount}',
                    centerSubtitle: 'Delivered',
                  ),
                ),
              ],
            )
          else ...[
            LineTrendChartCard(
              title: 'Monthly Revenue Run Rate',
              subtitle: 'Current vs Target Plan',
              data: sales.monthlyRevenueTrend,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            DonutChartCard(
              title: 'Revenue by Powertrain',
              data: sales.powertrainShare,
              centerTitle: '${sales.deliveredBikesCount}',
            ),
          ],
        ],
      ],
    );
  }

  // ─── TAB 1: SALES DASHBOARD ───
  Widget _buildSalesDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final s = state.salesData;
    if (s == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Gross Sales Revenue', currency.format(s.totalRevenue), 'Total Invoiced Value', Icons.receipt_long_outlined, AppColors.primaryYellow, width),
              _buildMetricCard('Bikes Delivered', '${s.deliveredBikesCount}', 'Completed handovers', Icons.two_wheeler_outlined, AppColors.success, width),
              _buildMetricCard('Pending Bookings', '${s.pendingBookingsCount}', 'Awaiting vehicle dispatch', Icons.bookmark_border_rounded, AppColors.warning, width),
              _buildMetricCard('Average Ticket Size', currency.format(s.averageTicketSize), 'Per vehicle on-road price', Icons.analytics_outlined, AppColors.info, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Visuals
        if (isDesktop)
          Row(
            children: [
              Expanded(
                flex: 6,
                child: LineTrendChartCard(
                  title: 'Sales Revenue Trajectory (FY 2026)',
                  subtitle: 'Actual Sales vs Target Quota',
                  data: s.monthlyRevenueTrend,
                  primarySeriesLabel: 'Actual Sales',
                  secondarySeriesLabel: 'Target Quota',
                ),
              ),
              const SizedBox(width: AppDimensions.spacing20),
              Expanded(
                flex: 4,
                child: DonutChartCard(
                  title: 'Powertrain Share',
                  subtitle: 'Petrol Motorcycles vs Electric Scooters',
                  data: s.powertrainShare,
                  centerTitle: '${s.deliveredBikesCount}',
                  centerSubtitle: 'Units Delivered',
                ),
              ),
            ],
          )
        else ...[
          LineTrendChartCard(title: 'Sales Revenue Trajectory', data: s.monthlyRevenueTrend),
          const SizedBox(height: AppDimensions.spacing16),
          DonutChartCard(title: 'Powertrain Share', data: s.powertrainShare, centerTitle: '${s.deliveredBikesCount}'),
        ],
        const SizedBox(height: AppDimensions.spacing24),

        // Model Leaderboard Bar Chart
        BarChartCard(
          title: 'Top Selling Two-Wheelers Leaderboard',
          subtitle: 'Unit sales volume by model',
          data: s.topModels,
        ),
      ],
    );
  }

  // ─── TAB 2: PURCHASE DASHBOARD ───
  Widget _buildPurchaseDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final p = state.purchaseData;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Procurement Spend', currency.format(p.totalProcurementSpend), 'Direct OEM purchases', Icons.shopping_bag_outlined, AppColors.info, width),
              _buildMetricCard('Inward Units', '${p.inwardUnitsCount}', 'Received into inventory', Icons.local_shipping_outlined, AppColors.success, width),
              _buildMetricCard('Pending Orders', '${p.pendingOrdersCount}', 'In factory transit', Icons.schedule, AppColors.warning, width),
              _buildMetricCard('OEM Payables', currency.format(p.supplierPayablesTotal), 'Outstanding due to OEMs', Icons.payments_outlined, AppColors.error, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Visuals
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: DonutChartCard(
                  title: 'OEM Procurement Allocation',
                  subtitle: 'Spend share across vehicle manufacturers',
                  data: p.oemSpendDistribution,
                  centerTitle: '100%',
                  centerSubtitle: 'OEM Share',
                ),
              ),
              const SizedBox(width: AppDimensions.spacing20),
              Expanded(
                child: BarChartCard(
                  title: 'Monthly Procurement Volume',
                  subtitle: 'Inward purchase spend trend (₹ Lakhs)',
                  data: p.monthlyPurchaseTrend,
                  barColor: AppColors.info,
                ),
              ),
            ],
          )
        else ...[
          DonutChartCard(title: 'OEM Procurement Allocation', data: p.oemSpendDistribution, centerTitle: '100%'),
          const SizedBox(height: AppDimensions.spacing16),
          BarChartCard(title: 'Monthly Procurement Volume', data: p.monthlyPurchaseTrend),
        ],
        const SizedBox(height: AppDimensions.spacing24),

        ProgressBreakdownCard(
          title: 'Commodity Spend Breakdown',
          subtitle: 'New Two-Wheelers vs Spare Parts vs Riding Gear',
          data: p.categorySpendBreakdown,
        ),
      ],
    );
  }

  // ─── TAB 3: INVENTORY DASHBOARD ───
  Widget _buildInventoryDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final inv = state.inventoryData;
    if (inv == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Stock on Hand', '${inv.totalUnitsOnHand}', 'Physical bikes in showrooms', Icons.inventory_2_outlined, AppColors.primaryYellow, width),
              _buildMetricCard('Stock Valuation', currency.format(inv.totalStockValuationInr), 'Asset value at cost', Icons.account_balance_wallet_outlined, AppColors.info, width),
              _buildMetricCard('Holding Period', '${inv.averageHoldingDays} days', 'Average days sales inventory', Icons.hourglass_bottom_rounded, AppColors.success, width),
              _buildMetricCard('Aging Stock Alerts', '${inv.agingStockCount}', 'Units held > 60 days', Icons.warning_amber_rounded, AppColors.error, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Charts
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: DonutChartCard(
                  title: 'Inventory by Category',
                  subtitle: 'Motorcycles vs Electric vs Scooters',
                  data: inv.categoryDistribution,
                  centerTitle: '${inv.totalUnitsOnHand}',
                  centerSubtitle: 'Total Bikes',
                ),
              ),
              const SizedBox(width: AppDimensions.spacing20),
              Expanded(
                child: BarChartCard(
                  title: 'Showroom Stock Balance',
                  subtitle: 'Vehicles parked across branches',
                  data: inv.showroomStockBalance,
                  barColor: AppColors.success,
                ),
              ),
            ],
          )
        else ...[
          DonutChartCard(title: 'Inventory by Category', data: inv.categoryDistribution, centerTitle: '${inv.totalUnitsOnHand}'),
          const SizedBox(height: AppDimensions.spacing16),
          BarChartCard(title: 'Showroom Stock Balance', data: inv.showroomStockBalance),
        ],
        const SizedBox(height: AppDimensions.spacing24),

        ProgressBreakdownCard(
          title: 'Stock Allocation Status',
          subtitle: 'Available vs Reserved Bookings vs In Transit',
          data: inv.stockStatusSplit,
        ),
      ],
    );
  }

  // ─── TAB 4: FINANCE DASHBOARD ───
  Widget _buildFinanceDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final f = state.financeData;
    if (f == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Total Liquid Treasury', currency.format(f.totalLiquidFunds), 'Cash + Bank balances', Icons.account_balance_outlined, AppColors.success, width),
              _buildMetricCard('Sundry Debtors', currency.format(f.totalReceivables), 'Customer receivables', Icons.arrow_downward_rounded, AppColors.info, width),
              _buildMetricCard('Sundry Creditors', currency.format(f.totalPayables), 'OEM & supplier payables', Icons.arrow_upward_rounded, AppColors.error, width),
              _buildMetricCard('Net Working Capital', currency.format(f.netWorkingCapital), 'Current assets - liabilities', Icons.balance_outlined, AppColors.primaryYellow, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Visuals
        if (isDesktop)
          Row(
            children: [
              Expanded(
                flex: 6,
                child: LineTrendChartCard(
                  title: 'Cashflow Inflow vs Outflow',
                  subtitle: 'Monthly treasury collections vs vendor disbursements',
                  data: f.monthlyCashflowTrend,
                  primarySeriesLabel: 'Collections (Inflow)',
                  secondarySeriesLabel: 'Disbursements (Outflow)',
                  primaryColor: AppColors.success,
                  secondaryColor: AppColors.error,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing20),
              Expanded(
                flex: 4,
                child: DonutChartCard(
                  title: 'Treasury Split',
                  subtitle: 'Bank Current A/c vs Cash Drawer',
                  data: f.cashVsBankSplit,
                  centerTitle: currency.format(f.totalLiquidFunds),
                  centerSubtitle: 'Liquid Funds',
                ),
              ),
            ],
          )
        else ...[
          LineTrendChartCard(title: 'Cashflow Inflow vs Outflow', data: f.monthlyCashflowTrend),
          const SizedBox(height: AppDimensions.spacing16),
          DonutChartCard(title: 'Treasury Split', data: f.cashVsBankSplit, centerTitle: currency.format(f.totalLiquidFunds)),
        ],
        const SizedBox(height: AppDimensions.spacing24),

        ProgressBreakdownCard(
          title: 'Customer Payment Modes Mix',
          subtitle: 'Bank Transfer / RTGS vs UPI vs Cash vs Cheque',
          data: f.paymentModeMix,
        ),
      ],
    );
  }

  // ─── TAB 5: PROFIT DASHBOARD ───
  Widget _buildProfitDashboard(
    BuildContext context,
    DashboardState state,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    final p = state.profitData;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 4)) / 5
              : (constraints.maxWidth - AppDimensions.spacing16) / 2;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildMetricCard('Gross Revenue', currency.format(p.grossRevenue), 'Sales turnover', Icons.receipt_long_outlined, AppColors.primaryYellow, width),
              _buildMetricCard('Cost of Goods (COGS)', currency.format(p.costOfGoodsSold), 'Vehicle procurement cost', Icons.shopping_cart_outlined, AppColors.error, width),
              _buildMetricCard('Gross Profit', currency.format(p.grossProfit), '${p.grossMarginPercent.toStringAsFixed(1)}% Gross Margin', Icons.trending_up_rounded, AppColors.success, width),
              _buildMetricCard('Operating Opex', currency.format(p.operatingExpenses), 'Lease, salaries, utilities', Icons.corporate_fare_outlined, AppColors.warning, width),
              _buildMetricCard('EBITDA (Net Profit)', currency.format(p.ebitda), '${p.ebitdaMarginPercent.toStringAsFixed(1)}% Net Margin', Icons.verified_outlined, AppColors.info, width),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.spacing24),

        // Visuals
        if (isDesktop)
          Row(
            children: [
              Expanded(
                flex: 6,
                child: LineTrendChartCard(
                  title: 'Revenue vs COGS Unit Economics',
                  subtitle: 'Tracking gross margin progression over fiscal year',
                  data: p.revenueVsCogsTrend,
                  primarySeriesLabel: 'Turnover',
                  secondarySeriesLabel: 'COGS',
                  primaryColor: AppColors.primaryYellow,
                  secondaryColor: AppColors.error,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing20),
              Expanded(
                flex: 4,
                child: DonutChartCard(
                  title: 'Profit by Profit Centre',
                  subtitle: 'Bikes vs Accessories vs Financing vs Workshop',
                  data: p.profitContributionBySegment,
                  centerTitle: currency.format(p.grossProfit),
                  centerSubtitle: 'Gross Margin',
                ),
              ),
            ],
          )
        else ...[
          LineTrendChartCard(title: 'Revenue vs COGS Unit Economics', data: p.revenueVsCogsTrend),
          const SizedBox(height: AppDimensions.spacing16),
          DonutChartCard(title: 'Profit by Profit Centre', data: p.profitContributionBySegment, centerTitle: currency.format(p.grossProfit)),
        ],
        const SizedBox(height: AppDimensions.spacing24),

        BarChartCard(
          title: 'Showroom Profitability Ranking',
          subtitle: 'Net margin contribution by branch',
          data: p.showroomProfitabilityRanking,
          barColor: AppColors.primaryYellow,
        ),
      ],
    );
  }

  // ─── Reusable Metric Card ───
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    double width,
  ) {
    return AppCard(
      width: width,
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              fontSize: width < 170 ? 15 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(color: AppColors.lightSecondaryText),
          ),
        ],
      ),
    );
  }
}
