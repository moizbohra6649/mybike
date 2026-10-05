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
import '../../domain/entities/vehicle_catalog_item.dart';
import '../cubit/vehicle_catalog_cubit.dart';
import '../cubit/vehicle_catalog_state.dart';

/// Vehicle List / Catalog Screen
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  late final VehicleCatalogCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = VehicleCatalogCubit()..loadCatalog();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  String _formatInr(double amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '₹${lakhs.toStringAsFixed(2)} Lakh';
    }
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        onRefresh: _cubit.loadCatalog,
        activeNavigationId: 'vehicles',
        currentShowroomName: 'Vehicle Master',
        title: 'Vehicle Master',
        body: BlocConsumer<VehicleCatalogCubit, VehicleCatalogState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.status == VehicleCatalogStatus.failure) {
              context.showErrorSnackBar(state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.status == VehicleCatalogStatus.loading && state.items.isEmpty) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            return SingleChildScrollView(
              padding: ResponsiveUtils.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ───
                  AppSectionHeader(
                    title: 'Vehicle Master Catalog',
                    countBadge: state.totalModels,
                    subtitle: 'Multi-brand motorcycle & electric scooter catalog, technical specifications, and statutory pricing',
                    trailing: AppButton.primary(
                      label: 'Add Vehicle Model',
                      leadingIcon: Icons.add_rounded,
                      onPressed: () async {
                        await context.pushNamed(RouteNames.vehicleCreate);
                        _cubit.loadCatalog();
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing20),

                  // ─── KPI Metric Cards ───
                  _buildKpiMetrics(context, state),
                  const SizedBox(height: AppDimensions.spacing24),

                  // ─── Search & Filters Bar ───
                  _buildFilterBar(context, state),
                  const SizedBox(height: AppDimensions.spacing24),

                  // ─── Catalog Grid ───
                  if (state.items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.two_wheeler_rounded,
                      title: 'No Vehicles Found',
                      description: 'No models match your current filters. Try changing your search query or powertrain filter.',
                    )
                  else
                    _buildCatalogGrid(context, state),
                  const SizedBox(height: AppDimensions.spacing40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, VehicleCatalogState state) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    final cards = [
      AppStatCard(
        title: 'Total Models',
        value: '${state.totalModels}',
        icon: Icons.two_wheeler_rounded,
        iconColor: AppColors.primaryYellow,
      ),
      AppStatCard(
        title: 'Petrol Bikes',
        value: '${state.petrolCount}',
        icon: Icons.local_gas_station_rounded,
        iconColor: const Color(0xFFF97316),
      ),
      AppStatCard(
        title: 'Electric EV',
        value: '${state.electricCount}',
        icon: Icons.electric_bolt_rounded,
        iconColor: const Color(0xFF10B981),
      ),
      AppStatCard(
        title: 'Total Variants',
        value: '${state.totalVariants}',
        icon: Icons.layers_rounded,
        iconColor: const Color(0xFF8B5CF6),
      ),
    ];

    if (!isDesktop && !isTablet) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cards.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                right: entry.key == cards.length - 1 ? 0 : AppDimensions.spacing12,
              ),
              child: SizedBox(
                width: 170,
                child: entry.value,
              ),
            );
          }).toList(),
        ),
      );
    }

    final crossAxisCount = isDesktop ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacing16,
      crossAxisSpacing: AppDimensions.spacing16,
      childAspectRatio: isDesktop ? 2.3 : 2.0,
      children: cards,
    );
  }

  Widget _buildFilterBar(BuildContext context, VehicleCatalogState state) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ResponsiveUtils.isMobile(context)) ...[
            AppTextField(
              controller: _searchController,
              hint: 'Search models by name...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => _cubit.search(val),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            AppDropdown<String?>(
              label: 'Brand',
              value: state.selectedBrandId,
              items: [null, ...state.brands.map((b) => b.id)],
              itemLabel: (id) {
                if (id == null) return 'All Brands';
                final brand = state.brands.where((b) => b.id == id).firstOrNull;
                return brand?.name ?? 'All Brands';
              },
              onChanged: (id) => _cubit.filterByBrand(id),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    hint: 'Search models by name...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (val) => _cubit.search(val),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                // Brand Dropdown filter
                SizedBox(
                  width: 200,
                  child: AppDropdown<String?>(
                    label: 'Brand',
                    value: state.selectedBrandId,
                    items: [null, ...state.brands.map((b) => b.id)],
                    itemLabel: (id) {
                      if (id == null) return 'All Brands';
                      final brand = state.brands.where((b) => b.id == id).firstOrNull;
                      return brand?.name ?? 'All Brands';
                    },
                    onChanged: (id) => _cubit.filterByBrand(id),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacing12),
          Wrap(
            spacing: AppDimensions.spacing8,
            children: [
              _buildTypeFilterChip(
                label: 'All Powertrains',
                isSelected: state.selectedType == null,
                onSelected: () => _cubit.filterByType(null),
              ),
              _buildTypeFilterChip(
                label: 'Petrol',
                icon: Icons.local_gas_station_rounded,
                isSelected: state.selectedType == 'petrol',
                onSelected: () => _cubit.filterByType('petrol'),
              ),
              _buildTypeFilterChip(
                label: 'Electric (EV)',
                icon: Icons.electric_bolt_rounded,
                isSelected: state.selectedType == 'electric',
                onSelected: () => _cubit.filterByType('electric'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final isDark = context.isDarkMode;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.black
                  : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryYellow,
      checkmarkColor: Colors.black,
      labelStyle: AppTypography.captionMedium.copyWith(
        color: isSelected
            ? Colors.black
            : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );
  }

  Widget _buildCatalogGrid(BuildContext context, VehicleCatalogState state) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    if (!isDesktop && !isTablet) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing16),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _buildModelCard(context, item);
        },
      );
    }

    final crossAxisCount = isDesktop ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spacing16,
        crossAxisSpacing: AppDimensions.spacing16,
        childAspectRatio: isDesktop ? 1.05 : 1.0,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildModelCard(context, item);
      },
    );
  }

  Widget _buildModelCard(BuildContext context, VehicleCatalogItem item) {
    final isDark = context.isDarkMode;
    final isEv = item.model.isElectric;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Brand chip & Powertrain badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    item.brand?.name ?? 'Unknown Brand',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              AppStatusBadge(
                label: isEv ? 'ELECTRIC' : 'PETROL',
                color: isEv ? const Color(0xFF10B981) : const Color(0xFFF97316),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Model Name
          Text(
            item.model.name,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing4),

          // Body Type badge
          Text(
            item.model.bodyType.toUpperCase(),
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.primaryYellowDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // Description
          Text(
            item.model.description ?? 'No description provided.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Price Range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ex-Showroom:',
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Text(
                    item.variants.isEmpty
                        ? 'Pricing TBA'
                        : item.minPrice == item.maxPrice
                            ? _formatInr(item.minPrice)
                            : '${_formatInr(item.minPrice)} - ${_formatInr(item.maxPrice)}',
                    textAlign: TextAlign.right,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Meta indicators (variants & colors count)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                  const SizedBox(width: 4),
                  Text(
                    '${item.variantCount} Variants',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_outlined, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                  const SizedBox(width: 4),
                  Text(
                    '${item.colorCount} Colors',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Actions
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'View Details',
                  leadingIcon: Icons.visibility_outlined,
                  onPressed: () async {
                    await context.push('/vehicles/${item.model.id}');
                    _cubit.loadCatalog();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Delete Model',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Vehicle Model'),
                      content: Text('Are you sure you want to delete ${item.model.name}? This will also delete all associated variants and colors.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _cubit.deleteModel(item.model.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
