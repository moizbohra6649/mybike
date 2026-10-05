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
import '../cubit/voucher_list_cubit.dart';
import '../cubit/voucher_list_state.dart';
import '../../domain/entities/finance_voucher_entity.dart';

/// Financial Voucher Register Screen
class VoucherListScreen extends StatelessWidget {
  final String? initialType;

  const VoucherListScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = VoucherListCubit()..loadVouchers();
        if (initialType != null && initialType!.isNotEmpty) {
          cubit.filterByType(initialType!);
        }
        return cubit;
      },
      child: const _VoucherListView(),
    );
  }
}

class _VoucherListView extends StatefulWidget {
  const _VoucherListView();

  @override
  State<_VoucherListView> createState() => _VoucherListViewState();
}

class _VoucherListViewState extends State<_VoucherListView> {
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
      onRefresh: () => context.read<VoucherListCubit>().loadVouchers(),
      title: 'Financial Voucher Register',
      activeNavigationId: 'finance',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<VoucherListCubit>().loadVouchers(),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.primaryBlack,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Voucher', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => context.goNamed(RouteNames.voucherCreate),
      ),
      body: BlocBuilder<VoucherListCubit, VoucherListState>(
        builder: (context, state) {
          if (state.isLoading && state.vouchers.isEmpty) {
            return AppSkeleton.list(kpis: 4, rows: 6);
          }

          if (state.error != null && state.vouchers.isEmpty) {
            return AppErrorState(
              title: 'Error Loading Vouchers',
              message: state.error!,
              onRetry: () => context.read<VoucherListCubit>().loadVouchers(),
            );
          }

          return Column(
            children: [
              // Filter Bar & KPIs
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing16 : AppDimensions.spacing12),
                child: Column(
                  children: [
                    // Search & Quick Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search by voucher #, party name, or UTR/cheque reference...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        context.read<VoucherListCubit>().searchVouchers('');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) => context.read<VoucherListCubit>().searchVouchers(val),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'New Payment',
                            leadingIcon: Icons.upload_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.goNamed(
                              RouteNames.voucherCreate,
                              queryParameters: {'type': 'payment'},
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppButton(
                            label: 'New Receipt',
                            leadingIcon: Icons.download_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.goNamed(
                              RouteNames.voucherCreate,
                              queryParameters: {'type': 'receipt'},
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip(context, 'all', 'All Vouchers (${state.vouchers.length})', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'payment', 'Payments', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'receipt', 'Receipts', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'contra', 'Contra', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'expense', 'Petty Cash', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'credit_note', 'Credit Notes', state.selectedType),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, 'debit_note', 'Debit Notes', state.selectedType),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics Strip
                    Row(
                      children: [
                        _buildMetricPill(
                          label: 'Disbursed (Payments & Expenses)',
                          amount: currencyFormat.format(state.totalDisbursed),
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricPill(
                          label: 'Collected (Receipts)',
                          amount: currencyFormat.format(state.totalReceived),
                          color: AppColors.success,
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          _buildMetricPill(
                            label: 'Contra Transfers',
                            amount: currencyFormat.format(state.totalContra),
                            color: AppColors.primaryYellow,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Vouchers List
              Expanded(
                child: state.filteredVouchers.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Matching Vouchers',
                        description: 'Try adjusting your search or filters.',
                        actionLabel: 'Reset Filters',
                        onActionPressed: () {
                          _searchCtrl.clear();
                          context.read<VoucherListCubit>().clearFilters();
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        itemCount: state.filteredVouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = state.filteredVouchers[index];
                          return _buildVoucherCard(context, voucher, currencyFormat, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type, String label, String activeType) {
    final isSelected = activeType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppColors.primaryYellow.withValues(alpha: 0.3),
      onSelected: (_) => context.read<VoucherListCubit>().filterByType(type),
    );
  }

  Widget _buildMetricPill({required String label, required String amount, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.captionMedium.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(amount, style: AppTypography.labelLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(
    BuildContext context,
    FinanceVoucherEntity v,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    Color typeColor;
    IconData typeIcon;
    switch (v.voucherType) {
      case 'payment':
        typeColor = AppColors.error;
        typeIcon = Icons.upload_rounded;
        break;
      case 'receipt':
        typeColor = AppColors.success;
        typeIcon = Icons.download_rounded;
        break;
      case 'contra':
        typeColor = AppColors.primaryYellow;
        typeIcon = Icons.swap_horiz_rounded;
        break;
      case 'expense':
        typeColor = Colors.orange;
        typeIcon = Icons.payments_outlined;
        break;
      case 'credit_note':
        typeColor = Colors.purple;
        typeIcon = Icons.assignment_return_rounded;
        break;
      case 'debit_note':
        typeColor = Colors.teal;
        typeIcon = Icons.note_alt_rounded;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.receipt_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(typeIcon, color: typeColor, size: 22),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                v.voucherNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                v.typeLabel,
                style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w700, color: typeColor),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${v.partyName} • ${dateFormat.format(v.voucherDate)} • ${v.paymentModeLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall,
        ),
        trailing: Text(
          currencyFormat.format(v.netAmount),
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: (v.isPayment || v.isExpense) ? AppColors.error : AppColors.success,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (context.isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General Ledger Mapping', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Source Account: ${v.sourceAccountName ?? v.sourceAccountId ?? "N/A"}', style: AppTypography.bodySmall),
                Text('Destination Account: ${v.destinationAccountName ?? v.destinationAccountId ?? "N/A"}', style: AppTypography.bodySmall),
                if (v.journalEntryId != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '✓ Synchronized with General Ledger: JRN-${v.voucherNumber}',
                      style: AppTypography.captionMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instrumentation & Narration', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (v.referenceNumber != null)
                  Text('Reference / Cheque: ${v.referenceNumber}', style: AppTypography.bodySmall),
                if (v.bankName != null)
                  Text('Bank: ${v.bankName}', style: AppTypography.bodySmall),
                Text('Narration: ${v.narration}', style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('General Ledger Mapping', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Source Account: ${v.sourceAccountName ?? v.sourceAccountId ?? "N/A"}', style: AppTypography.bodySmall),
                      Text('Destination Account: ${v.destinationAccountName ?? v.destinationAccountId ?? "N/A"}', style: AppTypography.bodySmall),
                      if (v.journalEntryId != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓ Synchronized with General Ledger: JRN-${v.voucherNumber}',
                            style: AppTypography.captionMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instrumentation & Narration', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      if (v.referenceNumber != null)
                        Text('Reference / Cheque: ${v.referenceNumber}', style: AppTypography.bodySmall),
                      if (v.bankName != null)
                        Text('Bank: ${v.bankName}', style: AppTypography.bodySmall),
                      Text('Narration: ${v.narration}', style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
