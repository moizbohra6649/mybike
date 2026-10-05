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
import '../cubit/outstanding_cubit.dart';
import '../cubit/outstanding_state.dart';
import '../../domain/entities/party_outstanding_entity.dart';

/// Outstanding Receivables & Payables Aging Ledger Screen
class OutstandingLedgerScreen extends StatelessWidget {
  const OutstandingLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutstandingCubit()..loadOutstandings(),
      child: const _OutstandingLedgerView(),
    );
  }
}

class _OutstandingLedgerView extends StatefulWidget {
  const _OutstandingLedgerView();

  @override
  State<_OutstandingLedgerView> createState() => _OutstandingLedgerViewState();
}

class _OutstandingLedgerViewState extends State<_OutstandingLedgerView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return AppScaffold(
      onRefresh: () => context.read<OutstandingCubit>().loadOutstandings(),
      title: 'Outstanding Ledger & Aging',
      activeNavigationId: 'finance',
      actions: [
        IconButton(
          tooltip: 'Refresh Outstandings',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<OutstandingCubit>().loadOutstandings(),
        ),
      ],
      body: BlocBuilder<OutstandingCubit, OutstandingState>(
        builder: (context, state) {
          if (state.isLoading && state.customerReceivables.isEmpty) {
            return AppSkeleton.table(kpis: 4, rows: 8, columns: 5);
          }

          if (state.error != null && state.customerReceivables.isEmpty) {
            return AppErrorState(
              title: 'Error Loading Outstandings',
              message: state.error!,
              onRetry: () => context.read<OutstandingCubit>().loadOutstandings(),
            );
          }

          final activeList = state.isReceivablesTab
              ? state.filteredReceivables
              : state.filteredPayables;

          return Column(
            children: [
              // Header Controls & Tab Bar
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing16 : AppDimensions.spacing12),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: state.isReceivablesTab
                            ? 'Search customer name or phone...'
                            : 'Search supplier or OEM name...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context.read<OutstandingCubit>().searchParties('');
                                },
                              )
                            : null,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) => context.read<OutstandingCubit>().searchParties(val),
                    ),
                    const SizedBox(height: 12),

                    // Tab Selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.read<OutstandingCubit>().switchTab('receivables'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: state.isReceivablesTab ? AppColors.primaryYellow : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Customer Receivables (${state.customerReceivables.length})',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: state.isReceivablesTab ? FontWeight.w700 : FontWeight.w500,
                                      color: state.isReceivablesTab ? AppColors.info : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(state.totalReceivables),
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.read<OutstandingCubit>().switchTab('payables'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: !state.isReceivablesTab ? AppColors.primaryYellow : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Supplier Payables (${state.supplierPayables.length})',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: !state.isReceivablesTab ? FontWeight.w700 : FontWeight.w500,
                                      color: !state.isReceivablesTab ? AppColors.error : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(state.totalPayables),
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Aging Bucket Legend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                child: Row(
                  children: [
                    Text('Aging Intervals: ', style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    _buildLegendBadge('0-30d: Current', AppColors.success),
                    const SizedBox(width: 8),
                    _buildLegendBadge('31-60d: Overdue', Colors.orange),
                    const SizedBox(width: 8),
                    _buildLegendBadge('61-90d: High', Colors.deepOrange),
                    const SizedBox(width: 8),
                    _buildLegendBadge('>90d: Critical', AppColors.error),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Party Ledger List
              Expanded(
                child: activeList.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No Outstanding Balances Found',
                        description: 'All balances are currently settled or query returned no matches.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final party = activeList[index];
                          return _buildPartyOutstandingCard(context, party, state.isReceivablesTab, currencyFormat, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildPartyOutstandingCard(
    BuildContext context,
    PartyOutstandingEntity p,
    bool isReceivable,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isReceivable
                      ? AppColors.info.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  isReceivable ? Icons.person_rounded : Icons.business_rounded,
                  color: isReceivable ? AppColors.info : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.partyName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${p.phone ?? "No Phone"} • Total Billed: ${currencyFormat.format(p.totalInvoiced)} • Settled: ${currencyFormat.format(p.totalSettled)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Outstanding', style: AppTypography.captionSmall),
                  Text(
                    currencyFormat.format(p.outstandingBalance),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isReceivable ? AppColors.info : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Aging Breakdown Row
          Row(
            children: [
              _buildAgingPill('0-30 Days', p.bucket0To30, AppColors.success, currencyFormat),
              const SizedBox(width: 8),
              _buildAgingPill('31-60 Days', p.bucket31To60, Colors.orange, currencyFormat),
              const SizedBox(width: 8),
              _buildAgingPill('61-90 Days', p.bucket61To90, Colors.deepOrange, currencyFormat),
              const SizedBox(width: 8),
              _buildAgingPill('>90 Days', p.bucket90Plus, AppColors.error, currencyFormat),
              const Spacer(),
              AppButton(
                label: isReceivable ? 'Receive Payment' : 'Make Payment',
                leadingIcon: isReceivable ? Icons.download_rounded : Icons.upload_rounded,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.small,
                onPressed: () => context.goNamed(
                  RouteNames.voucherCreate,
                  queryParameters: {
                    'type': isReceivable ? 'receipt' : 'payment',
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingPill(String label, double amount, Color color, NumberFormat currencyFormat) {
    final hasAmount = amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasAmount ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasAmount ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.captionSmall.copyWith(color: hasAmount ? color : Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            currencyFormat.format(amount),
            style: AppTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: hasAmount ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
