import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/gstr3b_report_entity.dart';
import '../cubit/gstr3b_report_cubit.dart';
import '../cubit/gstr3b_report_state.dart';

/// Statutory GSTR-3B Monthly Return Screen
class Gstr3bReportScreen extends StatelessWidget {
  const Gstr3bReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Gstr3bReportCubit()..loadReport(),
      child: const _Gstr3bReportView(),
    );
  }
}

class _Gstr3bReportView extends StatelessWidget {
  const _Gstr3bReportView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return AppScaffold(
      onRefresh: () => context.read<Gstr3bReportCubit>().loadReport(),
      title: 'GSTR-3B Monthly Summary Return',
      activeNavigationId: 'gst',
      actions: [
        IconButton(
          tooltip: 'Back to GST Hub',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        IconButton(
          tooltip: 'Copy Form 3B Summary',
          icon: const Icon(Icons.copy_rounded),
          onPressed: () => _copyForm3bSummary(context),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<Gstr3bReportCubit>().loadReport(),
        ),
      ],
      body: BlocBuilder<Gstr3bReportCubit, Gstr3bReportState>(
        builder: (context, state) {
          if (state.status == Gstr3bReportStatus.loading && state.report == null) {
            return AppSkeleton.table(kpis: 3, rows: 8, columns: 5);
          }

          if (state.status == Gstr3bReportStatus.failure && state.report == null) {
            return AppErrorState(
              title: 'Failed to Compile GSTR-3B',
              message: state.errorMessage ?? 'An error occurred while compiling return tables.',
              onRetry: () => context.read<Gstr3bReportCubit>().loadReport(),
            );
          }

          final report = state.report;
          if (report == null) {
            return const Center(child: Text('No data available'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing24 : AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeader(context, state, report, isDark),
                const SizedBox(height: AppDimensions.spacing20),

                // Table 3.1 Outward Supplies
                _buildTable31OutwardSupplies(report, currencyFormat, isDesktop, isDark),
                const SizedBox(height: AppDimensions.spacing24),

                // Table 4 Eligible ITC
                _buildTable4EligibleItc(report, currencyFormat, isDesktop, isDark),
                const SizedBox(height: AppDimensions.spacing24),

                // Table 6.1 Payment of Tax
                _buildTable61TaxPayment(report, currencyFormat, isDesktop, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Header Banner ───
  Widget _buildHeader(
    BuildContext context,
    Gstr3bReportState state,
    Gstr3bReportEntity report,
    bool isDark,
  ) {
    const periods = ['2026-09', '2026-08', '2026-07'];
    final isMobile = context.isMobile;

    final headerInfo = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(Icons.assignment_outlined, color: AppColors.primaryYellow, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FORM GSTR-3B [See rule 61(5)]',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'GSTIN: ${report.gstin} • Legal Name: MYBIKE DEALERSHIPS PVT LTD',
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final periodSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Return Period: ', style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: periods.map((p) {
              final isSelected = state.selectedPeriod == p;
              return ChoiceChip(
                label: Text(
                  p,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.primaryBlack : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryYellow,
                onSelected: (selected) {
                  if (selected) context.read<Gstr3bReportCubit>().changePeriod(p);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerInfo,
                const SizedBox(height: AppDimensions.spacing12),
                periodSelector,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headerInfo),
                const SizedBox(width: AppDimensions.spacing16),
                Flexible(child: periodSelector),
              ],
            ),
    );
  }

  /// Report tables carry many numeric columns. On narrow screens they are given
  /// a fixed minimum width and scroll horizontally instead of crushing every
  /// column into an unreadable sliver.
  static const double _reportTableMinWidth = 760;

  Widget _scrollableTable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < _reportTableMinWidth
                ? _reportTableMinWidth
                : constraints.maxWidth,
            child: child,
          ),
        );
      },
    );
  }

  // ─── Table 3.1: Outward Supplies ───
  Widget _buildTable31OutwardSupplies(
    Gstr3bReportEntity report,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3.1 Details of Outward Supplies and inward supplies liable to reverse charge',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: _scrollableTable(
            Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? AppColors.darkDivider : AppColors.lightBackground,
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text('Nature of Supplies', style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Total Taxable Value', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Integrated Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Central Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('State/UT Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...report.outwardSupplies.map((row) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(row.natureOfSupplies, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.totalTaxableValue), textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text(currency.format(row.integratedTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.centralTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.stateTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Table 4: Eligible ITC ───
  Widget _buildTable4EligibleItc(
    Gstr3bReportEntity report,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. Eligible Input Tax Credit (ITC)',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: _scrollableTable(
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? AppColors.darkDivider : AppColors.lightBackground,
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text('Details of ITC', style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Integrated Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Central Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('State/UT Tax', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Total ITC', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...report.eligibleItc.map((row) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(row.details, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.integratedTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.centralTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.stateTax), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.totalItc), textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.success))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Table 6.1: Payment of Tax ───
  Widget _buildTable61TaxPayment(
    Gstr3bReportEntity report,
    NumberFormat currency,
    bool isDesktop,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '6.1 Payment of Tax (Net Cash Challan vs ITC Utilization)',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: Text(
                'Net Cash Payable: ${currency.format(report.netCashPayable)}',
                style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryYellowDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: _scrollableTable(
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? AppColors.darkDivider : AppColors.lightBackground,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Tax Description', style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Tax Payable', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Paid Through ITC', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Tax Paid in Cash', textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...report.taxPayments.map((row) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(row.description, style: AppTypography.captionLarge.copyWith(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text(currency.format(row.taxPayable), textAlign: TextAlign.right, style: AppTypography.captionLarge)),
                        Expanded(flex: 2, child: Text(currency.format(row.paidThroughItc), textAlign: TextAlign.right, style: AppTypography.captionLarge.copyWith(color: AppColors.success))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            currency.format(row.taxPaidCash),
                            textAlign: TextAlign.right,
                            style: AppTypography.captionLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: row.taxPaidCash > 0 ? AppColors.primaryYellowDark : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _copyForm3bSummary(BuildContext context) {
    final report = context.read<Gstr3bReportCubit>().state.report;
    if (report == null) return;

    final text = 'FORM GSTR-3B Summary\n'
        'Filing Period: ${report.filingPeriod}\n'
        'GSTIN: ${report.gstin}\n'
        'Total Outward Tax: ₹${report.totalOutwardTax}\n'
        'Total Eligible ITC: ₹${report.totalEligibleItc}\n'
        'Net Cash Payable: ₹${report.netCashPayable}\n';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form GSTR-3B summary copied to clipboard!'), backgroundColor: AppColors.success),
    );
  }
}
