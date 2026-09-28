import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_loading.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../common/widgets/responsive_field_row.dart';
import '../../../../common/widgets/app_dropdown.dart';
import '../cubit/journal_entry_form_cubit.dart';
import '../cubit/journal_entry_form_state.dart';

/// Journal Entry Form Screen (Double-Entry Voucher Builder)
class JournalEntryFormScreen extends StatelessWidget {
  const JournalEntryFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JournalEntryFormCubit()..init(),
      child: const _JournalEntryFormView(),
    );
  }
}

class _JournalEntryFormView extends StatefulWidget {
  const _JournalEntryFormView();

  @override
  State<_JournalEntryFormView> createState() => _JournalEntryFormViewState();
}

class _JournalEntryFormViewState extends State<_JournalEntryFormView> {
  late final TextEditingController _narrationController;
  late final TextEditingController _refIdController;

  @override
  void initState() {
    super.initState();
    _narrationController = TextEditingController();
    _refIdController = TextEditingController();
  }

  @override
  void dispose() {
    _narrationController.dispose();
    _refIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return BlocConsumer<JournalEntryFormCubit, JournalEntryFormState>(
      listener: (context, state) {
        if (state.savedEntry != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Journal Voucher ${state.savedEntry!.entryNumber} posted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/accounting/journals');
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return AppScaffold(
          activeNavigationId: 'accounts',
          title: 'Create Journal Voucher',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/accounting/journals'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Ledger'),
            ),
            const SizedBox(width: 16),
          ],
          body: state.isLoading
              ? AppSkeleton.form(sections: 2, fields: 4)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Voucher Header Info Card ───
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Voucher Particulars', style: AppTypography.headlineSmall),
                                const SizedBox(height: 16),
                                ResponsiveFieldRow(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: state.entryDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null && context.mounted) {
                                          context.read<JournalEntryFormCubit>().updateHeader(date: picked);
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Voucher Date *',
                                          prefixIcon: Icon(Icons.calendar_today_rounded),
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Text(dateFormat.format(state.entryDate)),
                                      ),
                                    ),
                                    AppDropdown<String>(
                                      label: 'Reference Type *',
                                      value: state.referenceType,
                                      prefixIcon: Icons.receipt_rounded,
                                      items: const [
                                        'manual',
                                        'sales_invoice',
                                        'payment_receipt',
                                        'purchase_invoice',
                                        'expense',
                                      ],
                                      itemLabel: (v) {
                                        switch (v) {
                                          case 'manual': return 'Manual General Journal';
                                          case 'sales_invoice': return 'Sales Invoice Adjustment';
                                          case 'payment_receipt': return 'Payment Receipt Settlement';
                                          case 'purchase_invoice': return 'Purchase Bill Settlement';
                                          case 'expense': return 'Expense Voucher';
                                          default: return v;
                                        }
                                      },
                                      onChanged: (v) {
                                        if (v != null) {
                                          context.read<JournalEntryFormCubit>().updateHeader(referenceType: v);
                                        }
                                      },
                                    ),
                                    TextField(
                                      controller: _refIdController,
                                      onChanged: (v) => context.read<JournalEntryFormCubit>().updateHeader(referenceId: v),
                                      decoration: const InputDecoration(
                                        labelText: 'Reference No. (Optional)',
                                        hintText: 'e.g. INV-1002 or CHQ-991',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _narrationController,
                                  onChanged: (v) => context.read<JournalEntryFormCubit>().updateHeader(narration: v),
                                  decoration: const InputDecoration(
                                    labelText: 'Narration / Description *',
                                    hintText: 'e.g. Being payment of showroom facility lease rent for current month',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ─── Double-Entry Lines Builder ───
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text('Accounting Lines (Debits & Credits)', style: AppTypography.headlineSmall),
                                    ),
                                    const SizedBox(width: AppDimensions.spacing12),
                                    OutlinedButton.icon(
                                      onPressed: () => context.read<JournalEntryFormCubit>().addLine(),
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: const Text('Add Line'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.lines.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final line = state.lines[index];
                                    return _buildLineRow(context, index, line, state, isDark);
                                  },
                                ),
                                const SizedBox(height: 20),

                                // ─── Real-Time Balancing Indicator ───
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: state.isBalanced
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                    border: Border.all(
                                      color: state.isBalanced
                                          ? AppColors.success.withValues(alpha: 0.3)
                                          : AppColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final statusLine = Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            state.isBalanced ? Icons.check_circle_rounded : Icons.warning_rounded,
                                            color: state.isBalanced ? AppColors.success : AppColors.error,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              state.isBalanced
                                                  ? 'Balanced Voucher (Debits = Credits)'
                                                  : 'Unbalanced Voucher (Difference: ${currency.format(state.balanceDifference)})',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: state.isBalanced ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                      final totalsLine = Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Total DR: ${currency.format(state.totalDebit)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 16),
                                          Text('Total CR: ${currency.format(state.totalCredit)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      );

                                      // The DR/CR totals push the status message off
                                      // a phone, so there they take their own line.
                                      if (context.isMobile) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            statusLine,
                                            const SizedBox(height: 10),
                                            totalsLine,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: statusLine),
                                          const SizedBox(width: AppDimensions.spacing12),
                                          totalsLine,
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ─── Action Buttons ───
                          Builder(
                            builder: (context) {
                              final postButton = FilledButton.icon(
                                onPressed: state.isSubmitting || !state.isValid
                                    ? null
                                    : () => context.read<JournalEntryFormCubit>().submitJournal(autoPost: true),
                                icon: state.isSubmitting
                                    ? const AppLoading(
                                        size: AppLoadingSize.small,
                                        color: Colors.white,
                                      )
                                    : const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Post Journal Voucher'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                              );
                              final cancelButton = OutlinedButton(
                                onPressed: () => context.go('/accounting/journals'),
                                child: const Text('Cancel'),
                              );

                              // The two buttons together are wider than a phone
                              // screen, so they stack full width there.
                              if (context.isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    postButton,
                                    const SizedBox(height: 12),
                                    cancelButton,
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  cancelButton,
                                  const SizedBox(width: 12),
                                  postButton,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLineRow(
    BuildContext context,
    int index,
    dynamic line,
    JournalEntryFormState state,
    bool isDark,
  ) {
    final accountField = AppDropdown<String>(
      isDense: true,
      label: 'Account *',
      hint: 'Select Ledger Account',
      value: line.accountId.isNotEmpty ? line.accountId : null,
      items: state.availableAccounts.map((a) => a.id).toList(),
      itemLabel: (id) {
        final acct = state.availableAccounts.where((a) => a.id == id).firstOrNull;
        return acct != null ? '${acct.accountCode} - ${acct.accountName}' : id;
      },
      onChanged: (val) {
        if (val != null) {
          context.read<JournalEntryFormCubit>().updateLine(index, accountId: val);
        }
      },
    );
    final debitField = TextFormField(
      initialValue: line.debitAmount > 0 ? line.debitAmount.toStringAsFixed(2) : '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Debit (DR)',
        prefixText: '₹ ',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        final d = double.tryParse(val) ?? 0.0;
        context.read<JournalEntryFormCubit>().updateLine(
              index,
              debit: d,
              credit: d > 0 ? 0.0 : line.creditAmount, // mutually exclusive
            );
      },
    );
    final creditField = TextFormField(
      initialValue: line.creditAmount > 0 ? line.creditAmount.toStringAsFixed(2) : '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Credit (CR)',
        prefixText: '₹ ',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        final c = double.tryParse(val) ?? 0.0;
        context.read<JournalEntryFormCubit>().updateLine(
              index,
              credit: c,
              debit: c > 0 ? 0.0 : line.debitAmount, // mutually exclusive
            );
      },
    );
    final removeButton = IconButton(
      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      onPressed: state.lines.length > 2
          ? () => context.read<JournalEntryFormCubit>().removeLine(index)
          : null,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      // Three side-by-side inputs leave each about 50px wide on a phone, so the
      // account takes a full-width line of its own there.
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                accountField,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: debitField),
                    const SizedBox(width: 12),
                    Expanded(child: creditField),
                    const SizedBox(width: 4),
                    removeButton,
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: accountField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: debitField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: creditField),
                const SizedBox(width: 8),
                removeButton,
              ],
            ),
    );
  }
}
