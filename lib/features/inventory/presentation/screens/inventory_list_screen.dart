import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/vehicle_inventory_item.dart';
import '../cubit/inventory_list_cubit.dart';
import '../cubit/inventory_list_state.dart';

/// Main Inventory & Stock Management Screen
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  late final InventoryListCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = InventoryListCubit()..loadInventory();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  String _formatInr(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} Lakh';
    }
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        onRefresh: _cubit.loadInventory,
        activeNavigationId: 'inventory',
        currentShowroomName: 'Inventory & Stock',
        title: 'Vehicle Inventory',
        body: BlocConsumer<InventoryListCubit, InventoryListState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.status == InventoryListStatus.failure) {
              context.showErrorSnackBar(state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.status == InventoryListStatus.loading && state.items.isEmpty) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            return SingleChildScrollView(
              padding: ResponsiveUtils.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ───
                  AppSectionHeader(
                    title: 'Vehicle Stock & Asset Tracking',
                    countBadge: state.totalUnits,
                    subtitle: 'Real-time VIN chassis tracking, multi-branch stock levels, inwarding (GRN), and transfer logistics',
                    trailing: Wrap(
                      spacing: AppDimensions.spacing8,
                      runSpacing: AppDimensions.spacing8,
                      children: [
                        AppButton.secondary(
                          label: 'Branch Transfer',
                          leadingIcon: Icons.swap_horiz_rounded,
                          onPressed: () async {
                            await context.push('/inventory/transfer');
                            _cubit.loadInventory();
                          },
                        ),
                        AppButton.primary(
                          label: 'Inward Stock (GRN)',
                          leadingIcon: Icons.add_box_rounded,
                          onPressed: () async {
                            await context.push('/inventory/inward');
                            _cubit.loadInventory();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing20),

                  // ─── KPI Metric Cards ───
                  _buildKpiMetrics(context, state),
                  const SizedBox(height: AppDimensions.spacing24),

                  // ─── Filters & Search ───
                  _buildFilterBar(context, state),
                  const SizedBox(height: AppDimensions.spacing24),

                  // ─── Inventory Grid ───
                  if (state.items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Inventory Units Found',
                      description: 'No vehicles match your active branch, status, or search filters.',
                    )
                  else
                    _buildInventoryGrid(context, state),
                  const SizedBox(height: AppDimensions.spacing40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, InventoryListState state) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    final cards = [
      AppStatCard(
        title: 'Total Units',
        value: '${state.totalUnits}',
        icon: Icons.two_wheeler_rounded,
        iconColor: AppColors.primaryYellow,
      ),
      AppStatCard(
        title: 'In-Stock (Available)',
        value: '${state.availableUnits}',
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF10B981),
      ),
      AppStatCard(
        title: 'Booked / Allocated',
        value: '${state.bookedUnits}',
        icon: Icons.bookmark_added_outlined,
        iconColor: const Color(0xFF3B82F6),
      ),
      AppStatCard(
        title: 'In-Transit',
        value: '${state.inTransitUnits}',
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFFF59E0B),
      ),
      AppStatCard(
        title: 'Total Stock Value',
        value: _formatInr(state.totalValuationInr),
        icon: Icons.currency_rupee_rounded,
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

    final crossAxisCount = isDesktop ? 5 : 3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacing16,
      crossAxisSpacing: AppDimensions.spacing16,
      childAspectRatio: isDesktop ? 2.1 : 2.0,
      children: cards,
    );
  }

  Widget _buildFilterBar(BuildContext context, InventoryListState state) {
    final isDark = context.isDarkMode;
    final isMobile = context.isMobile;

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
          if (isMobile) ...[
            AppTextField(
              controller: _searchController,
              hint: 'Search by VIN, Engine, Motor, Key...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => _cubit.search(val),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            AppDropdown<String?>(
              label: 'Showroom Branch',
              value: state.selectedShowroomId,
              items: [null, ...state.showrooms.map((s) => s.showroom.id)],
              itemLabel: (id) {
                if (id == null) return 'All Showrooms';
                final s = state.showrooms.where((sh) => sh.showroom.id == id).firstOrNull;
                return s != null ? '${s.showroom.name} (${s.showroom.code})' : 'All Showrooms';
              },
              onChanged: (id) => _cubit.filterByShowroom(id),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    hint: 'Search by VIN, Engine No, Motor No, Key Tag...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (val) => _cubit.search(val),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                // Showroom selector
                SizedBox(
                  width: 240,
                  child: AppDropdown<String?>(
                    label: 'Showroom Branch',
                    value: state.selectedShowroomId,
                    items: [null, ...state.showrooms.map((s) => s.showroom.id)],
                    itemLabel: (id) {
                      if (id == null) return 'All Showrooms';
                      final s = state.showrooms.where((sh) => sh.showroom.id == id).firstOrNull;
                      return s != null ? '${s.showroom.name} (${s.showroom.code})' : 'All Showrooms';
                    },
                    onChanged: (id) => _cubit.filterByShowroom(id),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppDimensions.spacing12),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: [
              // Powertrain Chips
              _buildFilterChip('All Types', state.selectedPowertrain == null, () => _cubit.filterByPowertrain(null)),
              _buildFilterChip('Petrol Only', state.selectedPowertrain == 'petrol', () => _cubit.filterByPowertrain('petrol'), icon: Icons.local_gas_station_rounded),
              _buildFilterChip('Electric EV', state.selectedPowertrain == 'electric', () => _cubit.filterByPowertrain('electric'), icon: Icons.electric_bolt_rounded),

              const SizedBox(width: 8),
              // Status Chips
              _buildFilterChip('All Statuses', state.selectedStatus == null, () => _cubit.filterByStatus(null)),
              _buildFilterChip('In Stock', state.selectedStatus == 'in_stock', () => _cubit.filterByStatus('in_stock')),
              _buildFilterChip('Booked', state.selectedStatus == 'booked', () => _cubit.filterByStatus('booked')),
              _buildFilterChip('In Transit', state.selectedStatus == 'in_transit', () => _cubit.filterByStatus('in_transit')),
              _buildFilterChip('Sold', state.selectedStatus == 'sold', () => _cubit.filterByStatus('sold')),

              const SizedBox(width: 8),
              // PDI Chips
              _buildFilterChip('PDI Passed', state.selectedPdiStatus == 'passed', () => _cubit.filterByPdiStatus(state.selectedPdiStatus == 'passed' ? null : 'passed')),
              _buildFilterChip('PDI Pending', state.selectedPdiStatus == 'pending', () => _cubit.filterByPdiStatus(state.selectedPdiStatus == 'pending' ? null : 'pending')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected, {IconData? icon}) {
    final isDark = context.isDarkMode;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.black : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
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
        color: isSelected ? Colors.black : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );
  }

  Widget _buildInventoryGrid(BuildContext context, InventoryListState state) {
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
          return _buildVehicleCard(context, item);
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
        childAspectRatio: isDesktop ? 1.25 : 1.15,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildVehicleCard(context, item);
      },
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleInventoryItem item) {
    final isDark = context.isDarkMode;
    final v = item.vehicle;
    final isEv = item.isElectric;

    Color swatchColor;
    try {
      final hex = item.color?.hexCode.replaceAll('#', '') ?? '888888';
      swatchColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      swatchColor = Colors.grey;
    }

    Color statusColor;
    switch (v.status) {
      case 'in_stock':
        statusColor = const Color(0xFF10B981);
        break;
      case 'booked':
      case 'allocated':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'in_transit':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'sold':
      case 'delivered':
        statusColor = const Color(0xFF6B7280);
        break;
      default:
        statusColor = AppColors.error;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: VIN Badge & Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 13, color: AppColors.primaryYellowDark),
                    const SizedBox(width: 4),
                    Text(
                      v.vin,
                      style: AppTypography.captionSmall.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: v.status.replaceAll('_', ' ').toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing10),

          // Vehicle Model & Variant
          Text(
            item.displayName,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing4),

          // Powertrain & Color info
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatchColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.color?.name ?? 'Color N/A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('•', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 10),
              Icon(
                isEv ? Icons.electric_bolt_rounded : Icons.local_gas_station_rounded,
                size: 13,
                color: isEv ? const Color(0xFF10B981) : const Color(0xFFF97316),
              ),
              const SizedBox(width: 4),
              Text(
                isEv ? 'Electric' : 'Petrol',
                style: AppTypography.captionSmall.copyWith(
                  color: isEv ? const Color(0xFF10B981) : const Color(0xFFF97316),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // Engine / Motor No & Key tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    isEv
                        ? 'Motor: ${v.motorNumber ?? "N/A"}'
                        : 'Engine: ${v.engineNumber ?? "N/A"}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Text(
                  v.keyNumber != null ? 'Key: ${v.keyNumber}' : 'No Key Tag',
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Showroom Location & PDI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: AppColors.primaryYellowDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.showroom?.name ?? 'Branch N/A',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: v.pdiStatus == 'passed' ? 'PDI PASSED' : 'PDI PENDING',
                color: v.pdiStatus == 'passed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing10),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: 'View VIN Dossier',
              leadingIcon: Icons.description_outlined,
              onPressed: () async {
                await context.push('/inventory/${v.id}');
                _cubit.loadInventory();
              },
            ),
          ),
        ],
      ),
    );
  }
}
