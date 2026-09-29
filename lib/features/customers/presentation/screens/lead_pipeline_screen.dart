import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../domain/entities/lead_entity.dart';
import '../cubit/lead_pipeline_cubit.dart';
import '../cubit/lead_pipeline_state.dart';

/// Lead Pipeline Screen
///
/// Displays the sales lead pipeline with priority indicators,
/// conversion funnel stats, and filter support.
class LeadPipelineScreen extends StatelessWidget {
  const LeadPipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeadPipelineCubit()..loadLeads(),
      child: const _LeadPipelineView(),
    );
  }
}

class _LeadPipelineView extends StatelessWidget {
  const _LeadPipelineView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppScaffold(
      title: 'Lead Pipeline',
      activeNavigationId: 'customers',
      body: BlocBuilder<LeadPipelineCubit, LeadPipelineState>(
        builder: (context, state) {
          if (state.isLoading) {
            return AppSkeleton.list(rows: 6);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<LeadPipelineCubit>().loadLeads(),
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
                    '${state.filteredLeads.length} lead${state.filteredLeads.length != 1 ? 's' : ''}',
                    style: AppTypography.captionLarge.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ),

                // ─── Lead Cards ───
                ...state.filteredLeads.map((lead) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                      child: _LeadCard(lead: lead),
                    )),

                if (state.filteredLeads.isEmpty && !state.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacing40),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up_rounded, size: 48,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(height: AppDimensions.spacing12),
                          Text('No leads found',
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
  final LeadPipelineState state;
  const _KpiCardsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isDesktop = context.isDesktop;

    final cards = [
      _KpiData('Active Leads', '${state.totalActiveLeads}', Icons.trending_up_rounded, AppColors.info),
      _KpiData('Hot 🔥', '${state.hotLeads}', Icons.local_fire_department_rounded, AppColors.error),
      _KpiData('Conversion Rate', '${state.conversionRate.toStringAsFixed(1)}%', Icons.check_circle_outline_rounded, AppColors.success),
      _KpiData('Avg Days to Close', '${state.avgDaysToClose}d', Icons.timer_outlined, AppColors.warning),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop
            ? (constraints.maxWidth - (cards.length - 1) * 12) / cards.length
            : (constraints.maxWidth - AppDimensions.spacing12) / 2;

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
  final LeadPipelineState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cubit = context.read<LeadPipelineCubit>();

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
              hintText: 'Search by name or lead number...',
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

          // Priority chips
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: [
              _FilterChip(label: 'All Priority', isSelected: state.selectedPriority == null || state.selectedPriority!.isEmpty,
                  onTap: () => cubit.applyFilters(priority: '')),
              _FilterChip(label: '🔥 Hot', isSelected: state.selectedPriority == 'hot',
                  onTap: () => cubit.applyFilters(priority: 'hot'), color: AppColors.error),
              _FilterChip(label: '☀️ Warm', isSelected: state.selectedPriority == 'warm',
                  onTap: () => cubit.applyFilters(priority: 'warm'), color: AppColors.warning),
              _FilterChip(label: '❄️ Cold', isSelected: state.selectedPriority == 'cold',
                  onTap: () => cubit.applyFilters(priority: 'cold'), color: AppColors.info),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // Status chips
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: [
              _FilterChip(label: 'All Status', isSelected: state.selectedStatus == null || state.selectedStatus!.isEmpty,
                  onTap: () => cubit.applyFilters(status: '')),
              _FilterChip(label: 'New', isSelected: state.selectedStatus == 'new',
                  onTap: () => cubit.applyFilters(status: 'new')),
              _FilterChip(label: 'Interested', isSelected: state.selectedStatus == 'interested',
                  onTap: () => cubit.applyFilters(status: 'interested')),
              _FilterChip(label: 'Negotiation', isSelected: state.selectedStatus == 'negotiation',
                  onTap: () => cubit.applyFilters(status: 'negotiation')),
              _FilterChip(label: 'Converted', isSelected: state.selectedStatus == 'converted',
                  onTap: () => cubit.applyFilters(status: 'converted'), color: AppColors.success),
              _FilterChip(label: 'Lost', isSelected: state.selectedStatus == 'lost',
                  onTap: () => cubit.applyFilters(status: 'lost'), color: AppColors.error),
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

// ─── Lead Card ───
class _LeadCard extends StatelessWidget {
  final LeadEntity lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: lead.isHot
              ? AppColors.error.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(lead.priorityEmoji, style: AppTypography.headlineMedium),
              const SizedBox(width: AppDimensions.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                    Text(lead.leadNumber,
                        style: AppTypography.overline.copyWith(
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText, letterSpacing: 0.8)),
                  ],
                ),
              ),
              _StatusPill(label: lead.statusLabel, color: _statusColor(lead.status)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          // Vehicle interest + source
          Row(
            children: [
              Icon(Icons.two_wheeler_outlined, size: 14,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${lead.interestedModelName ?? "N/A"}${lead.interestedVariantName != null ? " • ${lead.interestedVariantName}" : ""}',
                  style: AppTypography.captionLarge.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(lead.sourceLabel, style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          // Assigned to + follow up info
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (lead.assignedToName != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                    const SizedBox(width: 4),
                    Text(lead.assignedToName!,
                        style: AppTypography.captionLarge.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                  ],
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 14,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                  const SizedBox(width: 4),
                  Text('${lead.daysOpen}d open',
                      style: AppTypography.captionLarge.copyWith(
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                ],
              ),
              if (lead.nextFollowUpAt != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lead.isFollowUpOverdue
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    'Follow-up: ${DateFormat('dd MMM').format(lead.nextFollowUpAt!)}',
                    style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600,
                        color: lead.isFollowUpOverdue ? AppColors.error : AppColors.info),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new': return AppColors.info;
      case 'contacted': return AppColors.pending;
      case 'interested': return AppColors.warning;
      case 'test_ride_scheduled': case 'test_ride_done': return AppColors.inProgress;
      case 'negotiation': return AppColors.warning;
      case 'booking_initiated': return AppColors.info;
      case 'converted': return AppColors.success;
      case 'lost': return AppColors.error;
      case 'follow_up': return AppColors.pending;
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
