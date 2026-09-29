import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../domain/entities/booking_entity.dart';
import '../cubit/booking_management_cubit.dart';
import '../cubit/booking_management_state.dart';

/// Booking List Screen
///
/// Displays all vehicle bookings with financial KPIs,
/// delivery tracking, and status filter support.
class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingManagementCubit()..loadBookings(),
      child: const _BookingListView(),
    );
  }
}

class _BookingListView extends StatelessWidget {
  const _BookingListView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppScaffold(
      title: 'Bookings',
      activeNavigationId: 'bookings',
      body: BlocBuilder<BookingManagementCubit, BookingManagementState>(
        builder: (context, state) {
          if (state.isLoading) {
            return AppSkeleton.list(kpis: 5, rows: 5);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<BookingManagementCubit>().loadBookings(),
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
                    '${state.filteredBookings.length} booking${state.filteredBookings.length != 1 ? 's' : ''}',
                    style: AppTypography.captionLarge.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ),

                // ─── Booking Cards ───
                ...state.filteredBookings.map((booking) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                      child: _BookingCard(booking: booking),
                    )),

                if (state.filteredBookings.isEmpty && !state.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacing40),
                      child: Column(
                        children: [
                          Icon(Icons.bookmark_outline_rounded, size: 48,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(height: AppDimensions.spacing12),
                          Text('No bookings found',
                              style: AppTypography.bodyLarge.copyWith(
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
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

// ─── KPI Cards ───
class _KpiCardsRow extends StatelessWidget {
  final BookingManagementState state;
  const _KpiCardsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isDesktop = context.isDesktop;

    final cards = [
      _KpiData('Active Bookings', '${state.activeBookings}', Icons.bookmark_rounded, AppColors.info),
      _KpiData('Pending Delivery', '${state.pendingDelivery}', Icons.local_shipping_outlined, AppColors.warning),
      _KpiData('Total Value', BookingEntity.formatInr(state.totalBookingValue), Icons.currency_rupee_rounded, AppColors.success),
      _KpiData('Delivered This Month', '${state.deliveredThisMonth}', Icons.check_circle_rounded, AppColors.delivered),
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
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.value, style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                Text(data.title, style: AppTypography.captionLarge.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                  overflow: TextOverflow.ellipsis),
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
  final BookingManagementState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cubit = context.read<BookingManagementCubit>();

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
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by booking number or customer...',
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
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: [
              _FilterChip(label: 'All', isSelected: state.selectedStatus == null || state.selectedStatus!.isEmpty,
                  onTap: () => cubit.applyFilters(status: '')),
              _FilterChip(label: 'Pending', isSelected: state.selectedStatus == 'pending',
                  onTap: () => cubit.applyFilters(status: 'pending'), color: AppColors.warning),
              _FilterChip(label: 'Confirmed', isSelected: state.selectedStatus == 'confirmed',
                  onTap: () => cubit.applyFilters(status: 'confirmed'), color: AppColors.info),
              _FilterChip(label: 'Allocated', isSelected: state.selectedStatus == 'allocated',
                  onTap: () => cubit.applyFilters(status: 'allocated'), color: AppColors.inProgress),
              _FilterChip(label: 'Delivered', isSelected: state.selectedStatus == 'delivered',
                  onTap: () => cubit.applyFilters(status: 'delivered'), color: AppColors.success),
              _FilterChip(label: 'Cancelled', isSelected: state.selectedStatus == 'cancelled',
                  onTap: () => cubit.applyFilters(status: 'cancelled'), color: AppColors.error),
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
          color: isSelected ? (color ?? AppColors.primaryYellow).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: isSelected ? (color ?? AppColors.primaryYellow)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Text(label, style: AppTypography.captionLarge.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? (color ?? (isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark))
                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText))),
      ),
    );
  }
}

// ─── Booking Card ───
class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  const _BookingCard({required this.booking});

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF888888);
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return const Color(0xFF888888);
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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
          // Header: Booking number + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(booking.bookingNumber,
                    style: AppTypography.captionLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                      letterSpacing: 0.6,
                    )),
              ),
              const Spacer(),
              _StatusPill(label: booking.statusLabel, color: _statusColor(booking.status)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Customer + Vehicle
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(booking.customerName ?? 'Unknown',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (booking.colorHex != null) ...[
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: _parseHex(booking.colorHex),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.two_wheeler_outlined, size: 14,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${booking.modelName ?? ''} ${booking.variantName ?? ''} ${booking.colorName != null ? '• ${booking.colorName}' : ''}',
                    style: AppTypography.captionLarge.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Financials
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing6,
            children: [
              // Token amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee_rounded, size: 12, color: AppColors.success),
                    Text('Token: ${BookingEntity.formatInr(booking.bookingAmount)}',
                        style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ),
              if (booking.paymentMode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(booking.paymentModeLabel,
                      style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600)),
                ),
              Text('On-road: ${BookingEntity.formatInr(booking.onRoadPrice)}',
                  style: AppTypography.captionLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // Delivery + Allocation info
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.spacing12,
            runSpacing: 4,
            children: [
              if (booking.allocatedVin != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(booking.allocatedVin!,
                        style: AppTypography.overline.copyWith(
                          color: AppColors.info, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  ],
                ),
              if (booking.expectedDeliveryDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined, size: 13,
                      color: booking.isDeliveryOverdue ? AppColors.error
                          : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery: ${DateFormat('dd MMM yyyy').format(booking.expectedDeliveryDate!)}',
                      style: AppTypography.captionLarge.copyWith(
                        color: booking.isDeliveryOverdue ? AppColors.error
                            : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                        fontWeight: booking.isDeliveryOverdue ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              if (booking.financeRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.inProgress.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text('Finance: ${booking.financeProvider ?? 'Pending'}',
                      style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.inProgress)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'allocated': return AppColors.inProgress;
      case 'ready_for_delivery': return AppColors.delivered;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'refunded': return AppColors.error;
      default: return AppColors.info;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, color: color)),
    );
  }
}
