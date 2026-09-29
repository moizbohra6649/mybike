import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../domain/entities/customer_entity.dart';
import '../cubit/customer_list_cubit.dart';
import '../cubit/customer_list_state.dart';

/// Customer List Screen
///
/// Displays all customers with KPI cards, search, and multi-filter support.
class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerListCubit()..loadCustomers(),
      child: const _CustomerListView(),
    );
  }
}

class _CustomerListView extends StatelessWidget {
  const _CustomerListView();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return AppScaffold(
      title: 'Customers',
      activeNavigationId: 'customers',
      actions: [
        if (isMobile)
          IconButton(
            onPressed: () => context.goNamed(RouteNames.customerCreate),
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Customer',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryBlack,
            ),
          )
        else
          FilledButton.icon(
            onPressed: () => context.goNamed(RouteNames.customerCreate),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add Customer'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryBlack,
            ),
          ),
        if (!isMobile) const SizedBox(width: AppDimensions.spacing12),
      ],
      body: BlocBuilder<CustomerListCubit, CustomerListState>(
        builder: (context, state) {
          final isDark = context.isDarkMode;
          if (state.isLoading) {
            return AppSkeleton.list(kpis: 4, rows: 6);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<CustomerListCubit>().loadCustomers(),
            color: AppColors.primaryYellow,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spacing20),
              children: [
                // ─── KPI Cards ───
                _KpiCardsRow(state: state),
                const SizedBox(height: AppDimensions.spacing20),

                // ─── Filter Bar ───
                _FilterBar(state: state),
                const SizedBox(height: AppDimensions.spacing16),

                // ─── Results Count ───
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                  child: Text(
                    '${state.filteredCustomers.length} customer${state.filteredCustomers.length != 1 ? 's' : ''}',
                    style: AppTypography.captionLarge.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ),

                // ─── Customer Cards ───
                ...state.filteredCustomers.map((customer) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                      child: _CustomerCard(customer: customer),
                    )),

                if (state.filteredCustomers.isEmpty && !state.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacing40),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 48,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(height: AppDimensions.spacing12),
                          Text('No customers found',
                              style: AppTypography.bodyLarge.copyWith(
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── KPI Cards Row ───
class _KpiCardsRow extends StatelessWidget {
  final CustomerListState state;
  const _KpiCardsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isDesktop = context.isDesktop;

    final cards = [
      _KpiData('Total Customers', '${state.totalCustomers}', Icons.people_rounded, AppColors.info),
      _KpiData('KYC Verified', '${state.kycVerified}', Icons.verified_user_rounded, AppColors.success),
      _KpiData('KYC Pending', '${state.kycPending}', Icons.pending_outlined, AppColors.warning),
      _KpiData('New This Month', '${state.newThisMonth}', Icons.fiber_new_rounded, AppColors.delivered),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((kpi) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing6),
                child: _KpiCard(data: kpi, isDark: isDark),
              ),
            )).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppDimensions.spacing12) / 2;
        return Wrap(
          spacing: AppDimensions.spacing12,
          runSpacing: AppDimensions.spacing12,
          children: cards.map((kpi) => SizedBox(
                width: cardWidth,
                child: _KpiCard(data: kpi, isDark: isDark),
              )).toList(),
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.title, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool isDark;
  const _KpiCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                Text(
                  data.title,
                  style: AppTypography.captionMedium.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───
class _FilterBar extends StatelessWidget {
  final CustomerListState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cubit = context.read<CustomerListCubit>();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, mobile, or customer number...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            onChanged: (value) => cubit.search(value),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // KYC Status chips
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: [
              _FilterChip(
                label: 'All KYC',
                isSelected: state.selectedKycStatus == null || state.selectedKycStatus!.isEmpty,
                onTap: () => cubit.applyFilters(kycStatus: ''),
              ),
              _FilterChip(
                label: '✓ Verified',
                isSelected: state.selectedKycStatus == 'verified',
                onTap: () => cubit.applyFilters(kycStatus: 'verified'),
                color: AppColors.success,
              ),
              _FilterChip(
                label: '◎ Pending',
                isSelected: state.selectedKycStatus == 'pending',
                onTap: () => cubit.applyFilters(kycStatus: 'pending'),
                color: AppColors.warning,
              ),
              _FilterChip(
                label: '½ Partial',
                isSelected: state.selectedKycStatus == 'partial',
                onTap: () => cubit.applyFilters(kycStatus: 'partial'),
                color: AppColors.info,
              ),
              _FilterChip(
                label: '✗ Rejected',
                isSelected: state.selectedKycStatus == 'rejected',
                onTap: () => cubit.applyFilters(kycStatus: 'rejected'),
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // Customer Type chips
          Wrap(
            spacing: AppDimensions.spacing8,
            children: [
              _FilterChip(
                label: 'All Types',
                isSelected: state.selectedCustomerType == null || state.selectedCustomerType!.isEmpty,
                onTap: () => cubit.applyFilters(customerType: ''),
              ),
              _FilterChip(
                label: 'Individual',
                isSelected: state.selectedCustomerType == 'individual',
                onTap: () => cubit.applyFilters(customerType: 'individual'),
              ),
              _FilterChip(
                label: 'Corporate',
                isSelected: state.selectedCustomerType == 'corporate',
                onTap: () => cubit.applyFilters(customerType: 'corporate'),
              ),
              _FilterChip(
                label: 'Fleet',
                isSelected: state.selectedCustomerType == 'fleet',
                onTap: () => cubit.applyFilters(customerType: 'fleet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primaryYellow).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primaryYellow)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionLarge.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (color ?? (isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark))
                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
          ),
        ),
      ),
    );
  }
}

// ─── Customer Card ───
class _CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () => context.go('/customers/${customer.id}'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _avatarColor(customer.customerType).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Center(
                child: Text(
                  customer.initials,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _avatarColor(customer.customerType),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(customer.fullName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                      _KycBadge(status: customer.kycStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer.mobilePrimary,
                          style: AppTypography.captionLarge.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(
                            customer.customerTypeLabel,
                            style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.customerNumber,
                    style: AppTypography.overline.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String type) {
    switch (type) {
      case 'corporate':
        return AppColors.info;
      case 'fleet':
        return AppColors.inProgress;
      default:
        return AppColors.primaryYellow;
    }
  }
}

class _KycBadge extends StatelessWidget {
  final String status;
  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'verified':
        color = AppColors.success;
        label = '✓ Verified';
        break;
      case 'partial':
        color = AppColors.info;
        label = '½ Partial';
        break;
      case 'rejected':
        color = AppColors.error;
        label = '✗ Rejected';
        break;
      case 'pending':
      default:
        color = AppColors.warning;
        label = '◎ Pending';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
