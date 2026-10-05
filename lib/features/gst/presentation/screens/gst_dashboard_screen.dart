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
import '../../../../core/services/gst_management_service.dart';
import '../cubit/gst_dashboard_cubit.dart';
import '../cubit/gst_dashboard_state.dart';

/// GST & Statutory Tax Hub Dashboard
class GstDashboardScreen extends StatelessWidget {
  const GstDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GstDashboardCubit()..loadDashboard(),
      child: const _GstDashboardView(),
    );
  }
}

class _GstDashboardView extends StatelessWidget {
  const _GstDashboardView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return AppScaffold(
      onRefresh: () => context.read<GstDashboardCubit>().loadDashboard(),
      title: 'GST & Statutory Tax Hub',
      activeNavigationId: 'gst',
      actions: [
        IconButton(
          tooltip: 'Interactive Tax Calculator',
          icon: const Icon(Icons.calculate_outlined),
          onPressed: () => _showTaxCalculatorModal(context),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<GstDashboardCubit>().loadDashboard(),
        ),
      ],
      body: BlocBuilder<GstDashboardCubit, GstDashboardState>(
        builder: (context, state) {
          if (state.status == GstDashboardStatus.loading && state.summary == null) {
            return AppSkeleton.dashboard();
          }

          if (state.status == GstDashboardStatus.failure && state.summary == null) {
            return AppErrorState(
              title: 'Failed to Load GST Hub',
              message: state.errorMessage ?? 'An error occurred while compiling tax records.',
              onRetry: () => context.read<GstDashboardCubit>().loadDashboard(),
            );
          }

          final summary = state.summary;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing24 : AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Period Selector & Showroom Tenancy Header
                _buildHeaderBar(context, state, isDark),
                const SizedBox(height: AppDimensions.spacing20),

                // 2. Core Statutory KPI Cards
                if (summary != null) ...[
                  _buildStatutoryKpiGrid(context, summary, currencyFormat, isDesktop),
                  const SizedBox(height: AppDimensions.spacing24),

                  // 3. Tax Breakdown & GL Ledger Reconciliation
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildTaxSplitCard(context, summary, currencyFormat, isDark),
                        ),
                        const SizedBox(width: AppDimensions.spacing20),
                        Expanded(
                          flex: 5,
                          child: _buildGlReconciliationCard(context, summary, currencyFormat, isDark),
                        ),
                      ],
                    )
                  else ...[
                    _buildTaxSplitCard(context, summary, currencyFormat, isDark),
                    const SizedBox(height: AppDimensions.spacing16),
                    _buildGlReconciliationCard(context, summary, currencyFormat, isDark),
                  ],

                  const SizedBox(height: AppDimensions.spacing24),

                  // 4. Quick Action Filing Modules
                  _buildFilingActionCards(context, isDesktop, isDark),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 1. Header Bar & Filing Period Selector ───
  Widget _buildHeaderBar(BuildContext context, GstDashboardState state, bool isDark) {
    const periods = ['2026-09', '2026-08', '2026-07'];

    final isMobile = context.isMobile;

    final gstinInfo = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing10),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryYellow, size: 24),
        ),
        const SizedBox(width: AppDimensions.spacing16),
        Expanded(
          flex: isMobile ? 1 : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GSTIN: 27AABCU9603R1ZM',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Regular Dealership Taxpayer • Maharashtra (27)',
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final periodSelector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Filing Period: ',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          ...periods.map((p) {
            final isSelected = state.selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  _formatPeriodName(p),
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryYellow,
                onSelected: (selected) {
                  if (selected) {
                    context.read<GstDashboardCubit>().changePeriod(p);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppDimensions.spacing16 : AppDimensions.spacing20,
        vertical: AppDimensions.spacing16,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gstinInfo,
                const SizedBox(height: 12),
                periodSelector,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                gstinInfo,
                periodSelector,
              ],
            ),
    );
  }

  String _formatPeriodName(String p) {
    switch (p) {
      case '2026-09':
        return 'Sep 2026 (Active)';
      case '2026-08':
        return 'Aug 2026';
      case '2026-07':
        return 'Jul 2026';
      default:
        return p;
    }
  }

  // ─── 2. Statutory KPI Cards ───
  Widget _buildStatutoryKpiGrid(
    BuildContext context,
    dynamic summary,
    NumberFormat currencyFormat,
    bool isDesktop,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = isDesktop
          ? (constraints.maxWidth - (AppDimensions.spacing16 * 3)) / 4
          : (constraints.maxWidth - AppDimensions.spacing16) / 2;

      return Wrap(
        spacing: AppDimensions.spacing16,
        runSpacing: AppDimensions.spacing16,
        children: [
          _buildKpiCard(
            title: 'Outward Supplies',
            subtitle: 'Gross Taxable Sales',
            value: currencyFormat.format(summary.totalOutwardTaxable),
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.info,
            cardWidth: cardWidth,
          ),
          _buildKpiCard(
            title: 'Output GST Liability',
            subtitle: 'CGST + SGST + IGST',
            value: currencyFormat.format(summary.totalOutputTax),
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            cardWidth: cardWidth,
          ),
          _buildKpiCard(
            title: 'Eligible ITC (Asset)',
            subtitle: 'Input Tax Credit',
            value: currencyFormat.format(summary.totalEligibleItc),
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.success,
            cardWidth: cardWidth,
          ),
          _buildKpiCard(
            title: 'Net GST Payable',
            subtitle: summary.totalNetTaxPayable > 0 ? 'Cash Challan Needed' : 'Credit Carry Forward',
            value: currencyFormat.format(summary.totalNetTaxPayable),
            icon: Icons.payments_outlined,
            iconColor: AppColors.primaryYellow,
            cardWidth: cardWidth,
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double cardWidth,
  }) {
    return AppCard(
      width: cardWidth,
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 18),
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
              fontSize: cardWidth < 170 ? 15 : null,
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

  // ─── 3. Tax Breakdown Visualizer ───
  Widget _buildTaxSplitCard(
    BuildContext context,
    dynamic summary,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statutory Tax Head Breakdown',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Output vs Input (ITC)',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTaxRow(
            label: 'Central GST (CGST)',
            output: summary.outputCgst,
            input: summary.itcCgst,
            net: summary.netCgstPayable,
            currencyFormat: currencyFormat,
          ),
          const Divider(height: 24),
          _buildTaxRow(
            label: 'State GST (SGST)',
            output: summary.outputSgst,
            input: summary.itcSgst,
            net: summary.netSgstPayable,
            currencyFormat: currencyFormat,
          ),
          const Divider(height: 24),
          _buildTaxRow(
            label: 'Integrated GST (IGST)',
            output: summary.outputIgst,
            input: summary.itcIgst,
            net: summary.netIgstPayable,
            currencyFormat: currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow({
    required String label,
    required double output,
    required double input,
    required double net,
    required NumberFormat currencyFormat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Net Payable: ${currencyFormat.format(net)}',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: net > 0 ? AppColors.primaryYellow : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Output Liability: ${currencyFormat.format(output)}',
              style: AppTypography.captionSmall.copyWith(color: AppColors.error),
            ),
            Text(
              'ITC Utilized: ${currencyFormat.format(input)}',
              style: AppTypography.captionSmall.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 4. GL Ledger Reconciliation Card ───
  Widget _buildGlReconciliationCard(
    BuildContext context,
    dynamic summary,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final isReconciled = summary.isGlReconciled;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'General Ledger Cross-Check',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isReconciled ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReconciled ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      size: 14,
                      color: isReconciled ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReconciled ? '100% RECONCILED' : 'DISCREPANCY DETECTED',
                      style: AppTypography.captionSmall.copyWith(
                        color: isReconciled ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildGlRow('Output CGST/SGST (Accounts 2020, 2021)', summary.glOutputTaxBalance, currencyFormat),
          const SizedBox(height: AppDimensions.spacing12),
          _buildGlRow('Input Tax Credit Asset (Accounts 1060, 1061)', summary.glInputTaxBalance, currencyFormat),
          const SizedBox(height: AppDimensions.spacing16),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              'Every sales invoice and vendor voucher automatically posts balanced entries to ledger accounts, guaranteeing audit compliance.',
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlRow(String title, double amount, NumberFormat currencyFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: AppTypography.bodySmall),
        ),
        Text(
          currencyFormat.format(amount),
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ─── 5. Quick Action Filing Modules ───
  Widget _buildFilingActionCards(BuildContext context, bool isDesktop, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statutory Returns & Configuration',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop
              ? (constraints.maxWidth - (AppDimensions.spacing16 * 2)) / 3
              : constraints.maxWidth;

          return Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing16,
            children: [
              _buildActionModule(
                title: 'GSTR-1 Outward Supplies',
                description: 'B2B, B2C Large, B2C Small, HSN Table 12, Document serial summary.',
                buttonText: 'View GSTR-1 Return',
                icon: Icons.table_chart_outlined,
                onPressed: () => context.pushNamed(RouteNames.gstr1Report),
                width: width,
              ),
              _buildActionModule(
                title: 'GSTR-3B Monthly Return',
                description: 'Table 3.1 Outward supplies, Table 4 Eligible ITC, Table 6.1 Tax Payment.',
                buttonText: 'View GSTR-3B Return',
                icon: Icons.assignment_outlined,
                onPressed: () => context.pushNamed(RouteNames.gstr3bReport),
                width: width,
              ),
              _buildActionModule(
                title: 'GST Tax Rates Master',
                description: 'Configurable HSN/SAC codes (8711 Petrol 28%, 8711 EV 5%, 8714 Spares 18%).',
                buttonText: 'Configure Rates',
                icon: Icons.tune_rounded,
                onPressed: () => context.pushNamed(RouteNames.gstRates),
                width: width,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildActionModule({
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required VoidCallback onPressed,
    required double width,
  }) {
    return AppCard(
      width: width,
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: AppColors.primaryYellow, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            description,
            style: AppTypography.captionSmall.copyWith(color: AppColors.lightSecondaryText),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          AppButton(
            label: buttonText,
            variant: AppButtonVariant.secondary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  // ─── 6. Interactive Tax Calculator Modal ───
  void _showTaxCalculatorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const _TaxCalculatorDialog(),
    );
  }
}

/// Interactive Dealership Tax Calculator Dialog
class _TaxCalculatorDialog extends StatefulWidget {
  const _TaxCalculatorDialog();

  @override
  State<_TaxCalculatorDialog> createState() => _TaxCalculatorDialogState();
}

class _TaxCalculatorDialogState extends State<_TaxCalculatorDialog> {
  final _amountController = TextEditingController(text: '100000');
  final _discountController = TextEditingController(text: '0');
  String _hsnCode = '8711';
  bool _isInterstate = false;
  bool _applyTcs = false;

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = GstManagementService();
    final base = double.tryParse(_amountController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    final result = service.calculateTax(
      baseAmount: base,
      discountAmount: discount,
      hsnSacCode: _hsnCode,
      isInterstate: _isInterstate,
      tcsRate: _applyTcs ? 0.1 : 0.0,
    );

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppColors.primaryYellow),
          SizedBox(width: 8),
          Text('GST Tax Simulator'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount (₹)', prefixIcon: Icon(Icons.discount_outlined)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'HSN / SAC Code & Item Type',
                value: _hsnCode,
                prefixIcon: Icons.receipt_long_outlined,
                items: const [
                  '8711',
                  '8711-EV',
                  '8714',
                  '8714-ACC',
                  '9987',
                ],
                itemLabel: (val) {
                  switch (val) {
                    case '8711': return '8711 — Petrol Vehicle (28% GST)';
                    case '8711-EV': return '8711-EV — Electric Vehicle (5% GST)';
                    case '8714': return '8714 — Spare Parts (18% GST)';
                    case '8714-ACC': return '8714-ACC — Accessories (28% GST)';
                    case '9987': return '9987 — Workshop Labor (18% GST)';
                    default: return val;
                  }
                },
                onChanged: (val) {
                  if (val != null) setState(() => _hsnCode = val);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Inter-State Supply (IGST)'),
                value: _isInterstate,
                onChanged: (val) => setState(() => _isInterstate = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apply Section 206C TCS (0.1%)'),
                value: _applyTcs,
                onChanged: (val) => setState(() => _applyTcs = val),
              ),
              const Divider(height: 24),
              Text('Tax Calculation Output', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _simRow('Taxable Base', currency.format(result.taxableAmount)),
              if (!_isInterstate) ...[
                _simRow('CGST (${result.cgstRate}%)', currency.format(result.cgstAmount)),
                _simRow('SGST (${result.sgstRate}%)', currency.format(result.sgstAmount)),
              ] else
                _simRow('IGST (${result.igstRate}%)', currency.format(result.igstAmount)),
              if (result.tcsAmount > 0)
                _simRow('TCS Sec 206C (${result.tcsRate}%)', currency.format(result.tcsAmount)),
              _simRow('Round-Off', currency.format(result.roundOff)),
              const Divider(height: 16),
              _simRow('Grand Total', currency.format(result.finalTotal), isBold: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _simRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold) : AppTypography.captionMedium),
          Text(value, style: isBold ? AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryYellow) : AppTypography.captionMedium),
        ],
      ),
    );
  }
}
