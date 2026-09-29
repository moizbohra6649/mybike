import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../cubit/sales_invoice_list_cubit.dart';
import '../cubit/sales_invoice_list_state.dart';

/// Sales & Invoicing Screen
///
/// Displays GST tax invoices, financial KPIs, and vehicle delivery status.
class SalesInvoiceListScreen extends StatelessWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesInvoiceListCubit()..loadInvoices(),
      child: const _SalesInvoiceListView(),
    );
  }
}

class _SalesInvoiceListView extends StatelessWidget {
  const _SalesInvoiceListView();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isDark = context.isDarkMode;

    return AppScaffold(
      activeNavigationId: 'sales',
      title: 'Sales & Invoices',
      actions: [
        if (isMobile)
          IconButton(
            onPressed: () => context.goNamed(RouteNames.saleCreate),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'New Sale / Booking',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryBlack,
            ),
          )
        else
          FilledButton.icon(
            onPressed: () => context.goNamed(RouteNames.saleCreate),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: const Text('New Sale / Booking'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        if (!isMobile) const SizedBox(width: 16),
      ],
      body: BlocBuilder<SalesInvoiceListCubit, SalesInvoiceListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return AppSkeleton.list(kpis: 4, rows: 6);
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load sales invoices', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  Text(state.error!, style: AppTypography.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SalesInvoiceListCubit>().loadInvoices(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SalesInvoiceListCubit>().loadInvoices(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── KPI Cards Row ───
                  _buildKpiGrid(context, state, isDark),
                  const SizedBox(height: 24),

                  // ─── Search and Filter Bar ───
                  _buildFilterBar(context, state, isDark),
                  const SizedBox(height: 20),

                  // ─── Invoice List ───
                  if (state.filteredInvoices.isEmpty)
                    _buildEmptyState(context, isDark)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.filteredInvoices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildInvoiceCard(
                          context,
                          state.filteredInvoices[index],
                          isDark,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, SalesInvoiceListState state, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard(
              title: 'Total Sales Revenue',
              value: currencyFormat.format(state.totalRevenue),
              subtitle: 'Active & delivered invoices',
              icon: Icons.currency_rupee_rounded,
              color: AppColors.success,
              width: cardWidth,
              isDark: isDark,
            ),
            _buildKpiCard(
              title: 'Total GST Collected',
              value: currencyFormat.format(state.totalGstCollected),
              subtitle: 'CGST + SGST (28% & 5%)',
              icon: Icons.receipt_long_rounded,
              color: AppColors.info,
              width: cardWidth,
              isDark: isDark,
            ),
            _buildKpiCard(
              title: 'Invoices Issued',
              value: '${state.totalInvoices}',
              subtitle: 'Customer tax invoices',
              icon: Icons.description_outlined,
              color: AppColors.primaryYellow,
              width: cardWidth,
              isDark: isDark,
            ),
            _buildKpiCard(
              title: 'Pending Delivery',
              value: '${state.pendingDeliveries}',
              subtitle: 'Awaiting customer handover',
              icon: Icons.local_shipping_outlined,
              color: AppColors.warning,
              width: cardWidth,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionLarge.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.captionSmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, SalesInvoiceListState state, bool isDark) {
    final searchField = TextField(
      onChanged: (v) => context.read<SalesInvoiceListCubit>().search(v),
      decoration: InputDecoration(
        hintText: 'Search by invoice no, VIN, customer name or mobile...',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final statusChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context, 'All', null, state.selectedStatus == null, isDark),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Issued', 'issued', state.selectedStatus == 'issued', isDark),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Delivered', 'delivered', state.selectedStatus == 'delivered', isDark),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Draft', 'draft', state.selectedStatus == 'draft', isDark),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 12),
                statusChips,
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 16),
                statusChips,
              ],
            ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String? statusValue,
    bool isSelected,
    bool isDark,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => context.read<SalesInvoiceListCubit>().filterByStatus(statusValue),
      selectedColor: AppColors.primaryYellow.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryBlack,
      labelStyle: AppTypography.captionLarge.copyWith(
        color: isSelected
            ? (isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark)
            : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryYellow
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    SalesInvoiceEntity invoice,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor;
    String statusLabel;
    switch (invoice.status) {
      case 'delivered':
        statusColor = AppColors.success;
        statusLabel = 'DELIVERED';
        break;
      case 'issued':
        statusColor = AppColors.info;
        statusLabel = 'ISSUED';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'DRAFT';
    }

    return InkWell(
      onTap: () => context.go('/sales/${invoice.id}'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.primaryYellowDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headlineSmall.copyWith(
                                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Date: ${dateFormat.format(invoice.invoiceDate)} • ${invoice.showroomName ?? "Showroom"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall.copyWith(
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.captionSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (context.isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: AppTypography.captionSmall.copyWith(
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoice.customerName ?? 'Customer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (invoice.customerMobile != null)
                              Text(
                                invoice.customerMobile!,
                                style: AppTypography.captionSmall.copyWith(
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'On-Road Total',
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(invoice.totalOnRoadPrice),
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            invoice.isPaid ? 'Paid in Full' : 'Bal: ${currencyFormat.format(invoice.balanceAmount)}',
                            style: AppTypography.captionSmall.copyWith(
                              color: invoice.isPaid ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.two_wheeler_outlined, size: 16, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${invoice.modelName ?? ""} ${invoice.variantName ?? ""} • VIN: ${invoice.vin}',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer',
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.customerName ?? 'Customer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (invoice.customerMobile != null)
                          Text(
                            invoice.customerMobile!,
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle & VIN',
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${invoice.modelName ?? ""} ${invoice.variantName ?? ""}',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'VIN: ${invoice.vin}',
                          style: AppTypography.captionSmall.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'On-Road Total',
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(invoice.totalOnRoadPrice),
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          invoice.isPaid ? 'Paid in Full' : 'Bal: ${currencyFormat.format(invoice.balanceAmount)}',
                          style: AppTypography.captionSmall.copyWith(
                            color: invoice.isPaid ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
            const SizedBox(height: 16),
            Text(
              'No sales invoices found',
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new sale or booking to generate GST tax invoices.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
