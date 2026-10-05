import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/finance_dashboard_cubit.dart';
import '../cubit/finance_dashboard_state.dart';
import '../../domain/entities/finance_voucher_entity.dart';

/// Finance & Cash/Bank Hub Dashboard
class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FinanceDashboardCubit()..loadDashboard(),
      child: const _FinanceDashboardView(),
    );
  }
}

class _FinanceDashboardView extends StatelessWidget {
  const _FinanceDashboardView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return AppScaffold(
      onRefresh: () => context.read<FinanceDashboardCubit>().loadDashboard(),
      title: 'Finance & Cash/Bank Hub',
      activeNavigationId: 'finance',
      actions: [
        IconButton(
          tooltip: 'Refresh Hub',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<FinanceDashboardCubit>().loadDashboard(),
        ),
      ],
      body: BlocBuilder<FinanceDashboardCubit, FinanceDashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.cashAccounts.isEmpty) {
            return AppSkeleton.dashboard();
          }

          if (state.error != null && state.cashAccounts.isEmpty) {
            return AppErrorState(
              title: 'Failed to Load Finance Hub',
              message: state.error!,
              onRetry: () => context.read<FinanceDashboardCubit>().loadDashboard(),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing24 : AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Action Bar
                _buildQuickActionBar(context, isDark),
                const SizedBox(height: 20),

                // Top Liquid & Working Capital KPIs
                _buildKPIRow(context, state, currencyFormat, isDesktop, isDark),
                const SizedBox(height: 24),

                // Accounts & Aging 2-Column Section
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildCashAndBankAccountsCard(context, state, currencyFormat, isDark),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        child: _buildOutstandingsSummaryCard(context, state, currencyFormat, isDark),
                      ),
                    ],
                  )
                else ...[
                  _buildCashAndBankAccountsCard(context, state, currencyFormat, isDark),
                  const SizedBox(height: 20),
                  _buildOutstandingsSummaryCard(context, state, currencyFormat, isDark),
                ],
                const SizedBox(height: 24),

                // Recent Vouchers Table
                _buildRecentVouchersSection(context, state, currencyFormat, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryBlack, size: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cash & Bank Operations', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text('Multi-account liquid positions & financial vouchers', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Record Payment',
                leadingIcon: Icons.upload_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.goNamed(
                  RouteNames.voucherCreate,
                  queryParameters: {'type': 'payment'},
                ),
              ),
              AppButton(
                label: 'Record Receipt',
                leadingIcon: Icons.download_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.goNamed(
                  RouteNames.voucherCreate,
                  queryParameters: {'type': 'receipt'},
                ),
              ),
              AppButton(
                label: 'Contra Transfer',
                leadingIcon: Icons.swap_horiz_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.goNamed(
                  RouteNames.voucherCreate,
                  queryParameters: {'type': 'contra'},
                ),
              ),
              AppButton(
                label: 'All Vouchers',
                leadingIcon: Icons.receipt_long_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () => context.goNamed(RouteNames.vouchers),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIRow(
    BuildContext context,
    FinanceDashboardState state,
    NumberFormat currencyFormat,
    bool isDesktop,
    bool isDark,
  ) {
    final kpis = [
      _buildKPICard('Total Liquid Funds', currencyFormat.format(state.totalLiquid), Icons.account_balance_wallet_rounded, AppColors.info, isDark),
      _buildKPICard('Cash in Drawers', currencyFormat.format(state.totalCash), Icons.payments_rounded, AppColors.success, isDark),
      _buildKPICard('Bank Accounts', currencyFormat.format(state.totalBank), Icons.account_balance_rounded, AppColors.primaryYellow, isDark),
      _buildKPICard(
        'Net Working Position',
        currencyFormat.format(state.netWorkingBalance),
        Icons.pie_chart_rounded,
        state.netWorkingBalance >= 0 ? AppColors.success : AppColors.error,
        isDark,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis.map((k) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: k))).toList(),
      );
    } else {
      return Column(
        children: kpis.map((k) => Padding(padding: const EdgeInsets.only(bottom: 12), child: k)).toList(),
      );
    }
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashAndBankAccountsCard(
    BuildContext context,
    FinanceDashboardState state,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Operational Accounts Position', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              TextButton.icon(
                icon: const Icon(Icons.account_balance_outlined, size: 16),
                label: const Text('Chart of Accounts'),
                onPressed: () => context.goNamed(RouteNames.chartOfAccounts),
              ),
            ],
          ),
          const Divider(height: 20),
          ...state.cashAccounts.map((acct) => _buildAccountItemTile(
                icon: Icons.payments_outlined,
                iconColor: AppColors.success,
                code: acct.accountCode,
                name: acct.accountName,
                type: 'Cash Drawer',
                balance: acct.currentBalance,
                currencyFormat: currencyFormat,
              )),
          const Divider(height: 20),
          ...state.bankAccounts.map((acct) => _buildAccountItemTile(
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.info,
                code: acct.accountCode,
                name: acct.accountName,
                type: 'Current Account',
                balance: acct.currentBalance,
                currencyFormat: currencyFormat,
              )),
        ],
      ),
    );
  }

  Widget _buildAccountItemTile({
    required IconData icon,
    required Color iconColor,
    required String code,
    required String name,
    required String type,
    required double balance,
    required NumberFormat currencyFormat,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('$code • $type', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text(
            currencyFormat.format(balance),
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: balance >= 0 ? null : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingsSummaryCard(
    BuildContext context,
    FinanceDashboardState state,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Receivables & Payables', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Aging Ledger'),
                onPressed: () => context.goNamed(RouteNames.outstandings),
              ),
            ],
          ),
          const Divider(height: 20),

          // Receivables Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.call_received_rounded, color: AppColors.info, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Receivables', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        'Overdue (>30d): ${currencyFormat.format(state.overdueReceivables)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(state.totalReceivables),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.info),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Payables Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.call_made_rounded, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Supplier & OEM Payables', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        'Overdue (>30d): ${currencyFormat.format(state.overduePayables)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(state.totalPayables),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppButton(
            label: 'Inspect Aging Ledger',
            leadingIcon: Icons.analytics_outlined,
            isFullWidth: true,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.goNamed(RouteNames.outstandings),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVouchersSection(
    BuildContext context,
    FinanceDashboardState state,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Recent Financial Vouchers', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              TextButton.icon(
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('View All'),
                onPressed: () => context.goNamed(RouteNames.vouchers),
              ),
            ],
          ),
          const Divider(height: 20),
          if (state.recentVouchers.isEmpty)
            const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Vouchers Recorded',
              description: 'Record your first payment, customer collection, or contra deposit.',
            )
          else
            ...state.recentVouchers.map((v) => _buildVoucherListTile(context, v, currencyFormat)),
        ],
      ),
    );
  }

  Widget _buildVoucherListTile(
    BuildContext context,
    FinanceVoucherEntity v,
    NumberFormat currencyFormat,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    Color badgeColor;
    IconData icon;
    switch (v.voucherType) {
      case 'payment':
        badgeColor = AppColors.error;
        icon = Icons.upload_rounded;
        break;
      case 'receipt':
        badgeColor = AppColors.success;
        icon = Icons.download_rounded;
        break;
      case 'contra':
        badgeColor = AppColors.primaryYellow;
        icon = Icons.swap_horiz_rounded;
        break;
      case 'expense':
        badgeColor = Colors.orange;
        icon = Icons.payments_outlined;
        break;
      case 'credit_note':
        badgeColor = Colors.purple;
        icon = Icons.assignment_return_rounded;
        break;
      case 'debit_note':
        badgeColor = Colors.teal;
        icon = Icons.note_alt_rounded;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.receipt_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(v.voucherNumber, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        v.typeLabel,
                        style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w700, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${v.partyName} • ${dateFormat.format(v.voucherDate)} via ${v.paymentModeLabel}',
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(v.netAmount),
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: (v.isPayment || v.isExpense) ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
