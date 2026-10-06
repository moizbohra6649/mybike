import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/showroom_management_service.dart';
import '../../../../core/services/showroom_service.dart';
import '../cubit/showroom_list_cubit.dart';
import '../cubit/showroom_list_state.dart';

/// Showroom List Screen — Multi-branch dealership overview, KPIs, and branch actions
class ShowroomListScreen extends StatefulWidget {
  const ShowroomListScreen({super.key});

  @override
  State<ShowroomListScreen> createState() => _ShowroomListScreenState();
}

class _ShowroomListScreenState extends State<ShowroomListScreen> {
  late final ShowroomListCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ShowroomListCubit()..loadShowrooms();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        onRefresh: () => _cubit.loadShowrooms(refresh: true),
        activeNavigationId: 'showrooms',
        currentShowroomName: 'Showrooms Directory',
        title: 'Showroom Management',
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add Showroom',
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.primaryBlack,
          onPressed: () async {
            await context.pushNamed(RouteNames.showroomCreate);
            _cubit.loadShowrooms(refresh: true);
          },
          child: const Icon(Icons.add_business_rounded),
        ),
        body: BlocConsumer<ShowroomListCubit, ShowroomListState>(
          listener: (context, state) {
            if (state is ShowroomListError) {
              context.showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is ShowroomListLoading) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            if (state is ShowroomListError) {
              return AppErrorState(
                title: 'Failed to Load Showrooms',
                message: state.message,
                onRetry: () => _cubit.loadShowrooms(refresh: true),
              );
            }

            if (state is ShowroomListLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, ShowroomListLoaded state) {
    final activeContext = ShowroomService.instance.activeShowroom;

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Stat KPI Cards ───
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        title: 'Total Showrooms',
                        value: state.totalCount.toString(),
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.primaryYellow,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                    Expanded(
                      child: AppStatCard(
                        title: 'Active Branches',
                        value: state.activeCount.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                    Expanded(
                      child: AppStatCard(
                        title: 'Staff Mapped',
                        value: state.totalStaffMapped.toString(),
                        icon: Icons.people_alt_outlined,
                        iconColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                    Expanded(
                      child: AppStatCard(
                        title: 'Operating Cities',
                        value: state.totalOperatingCities.toString(),
                        icon: Icons.location_city_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                );
              }

              if (isTablet) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppStatCard(
                            title: 'Total Showrooms',
                            value: state.totalCount.toString(),
                            icon: Icons.storefront_rounded,
                            iconColor: AppColors.primaryYellow,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: AppStatCard(
                            title: 'Active Branches',
                            value: state.activeCount.toString(),
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: AppStatCard(
                            title: 'Staff Mapped',
                            value: state.totalStaffMapped.toString(),
                            icon: Icons.people_alt_outlined,
                            iconColor: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: AppStatCard(
                            title: 'Operating Cities',
                            value: state.totalOperatingCities.toString(),
                            icon: Icons.location_city_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Mobile
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppStatCard(
                        title: 'Total Showrooms',
                        value: state.totalCount.toString(),
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.primaryYellow,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    SizedBox(
                      width: 170,
                      child: AppStatCard(
                        title: 'Active Branches',
                        value: state.activeCount.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    SizedBox(
                      width: 170,
                      child: AppStatCard(
                        title: 'Staff Mapped',
                        value: state.totalStaffMapped.toString(),
                        icon: Icons.people_alt_outlined,
                        iconColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    SizedBox(
                      width: 170,
                      child: AppStatCard(
                        title: 'Cities',
                        value: state.totalOperatingCities.toString(),
                        icon: Icons.location_city_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Toolbar: Search (full width) ───
          SizedBox(
            width: double.infinity,
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search showroom by name, code, city...',
              onChanged: (val) => _cubit.searchShowrooms(val),
              onClear: () {
                _searchController.clear();
                _cubit.searchShowrooms('');
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // ─── Filters ───
          Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filter Chips
              FilterChip(
                label: const Text('All Branches'),
                selected: state.activeFilter == null,
                onSelected: (_) => _cubit.filterByActive(null),
              ),
              FilterChip(
                label: const Text('Active Only'),
                selected: state.activeFilter == true,
                onSelected: (_) => _cubit.filterByActive(true),
              ),
              FilterChip(
                label: const Text('Inactive Only'),
                selected: state.activeFilter == false,
                onSelected: (_) => _cubit.filterByActive(false),
              ),

              if (state.searchQuery != null || state.activeFilter != null)
                ActionChip(
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  onPressed: () {
                    _searchController.clear();
                    _cubit.clearFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Showroom Grid ───
          if (state.showrooms.isEmpty)
            const AppEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No Showrooms Found',
              description: 'No showrooms match the current search or filter criteria.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveUtils.gridCrossAxisCount(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );

                const spacing = AppDimensions.spacing16;
                final itemWidth = (constraints.maxWidth -
                        spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

                // Wrap (instead of a fixed-extent grid) lets each card size
                // to its content, avoiding empty gaps inside the card.
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(state.showrooms.length, (index) {
                    final item = state.showrooms[index];
                    final isCurrentOperating = activeContext?.id == item.showroom.id;

                    return SizedBox(
                      width: itemWidth,
                      child: _ShowroomCard(
                      item: item,
                      isCurrentOperating: isCurrentOperating,
                      onViewDetails: () async {
                        await context.pushNamed(
                          RouteNames.showroomDetail,
                          pathParameters: {'showroomId': item.showroom.id},
                        );
                        _cubit.loadShowrooms(refresh: true);
                      },
                      onEdit: () async {
                        await context.pushNamed(
                          RouteNames.showroomCreate,
                          queryParameters: {'editId': item.showroom.id},
                        );
                        _cubit.loadShowrooms(refresh: true);
                      },
                      onSwitchContext: () async {
                        await ShowroomService.instance.switchShowroom(item.showroom);
                        if (context.mounted) {
                          context.showSuccessSnackBar(
                            'Switched operating branch to: ${item.showroom.name}',
                          );
                          setState(() {});
                        }
                      },
                      ),
                    );
                  }),
                );
              },
            ),

          // Bottom space so the FAB doesn't overlap the last card
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Rich Showroom Card Presentation Component
class _ShowroomCard extends StatelessWidget {
  final ShowroomWithStats item;
  final bool isCurrentOperating;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onSwitchContext;

  const _ShowroomCard({
    required this.item,
    required this.isCurrentOperating,
    required this.onViewDetails,
    required this.onEdit,
    required this.onSwitchContext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final showroom = item.showroom;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      border: isCurrentOperating
          ? const BorderSide(color: AppColors.primaryYellow, width: 2)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Code Badge, Status, Current Context Indicator ───
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  showroom.code,
                  style: AppTypography.captionLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrentOperating)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'CURRENT',
                        style: AppTypography.captionSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              AppStatusBadge.fromStatus(
                showroom.isActive ? 'active' : 'inactive',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // ─── Showroom Name ───
          Text(
            showroom.name,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // ─── Address & City ───
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${showroom.city}, ${showroom.state}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ─── Contact Phone ───
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(width: 4),
              Text(
                showroom.phone,
                style: AppTypography.captionLarge.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // ─── Metadata Badges ───
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (showroom.gstin != null && showroom.gstin!.isNotEmpty)
                _ChipTag(
                  icon: Icons.receipt_long_outlined,
                  text: 'GST: ${showroom.gstin!.length >= 5 ? showroom.gstin!.substring(0, 5) : showroom.gstin!}...',
                ),
              _ChipTag(
                icon: Icons.tag_rounded,
                text: 'Prefix: ${showroom.invoicePrefix}',
              ),
              _ChipTag(
                icon: Icons.people_outline_rounded,
                text: '${item.staffCount} Staff',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.spacing8),

          // ─── Action Buttons ───
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Details',
                  leadingIcon: Icons.visibility_outlined,
                  size: AppButtonSize.small,
                  onPressed: onViewDetails,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Showroom',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                onPressed: onEdit,
              ),
              if (!isCurrentOperating && showroom.isActive) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.primaryYellowDark),
                  tooltip: 'Switch to this branch',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  onPressed: onSwitchContext,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChipTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
          const SizedBox(width: 3),
          Text(
            text,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
        ],
      ),
    );
  }
}
