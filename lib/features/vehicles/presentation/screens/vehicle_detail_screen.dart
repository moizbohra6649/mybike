import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../common/widgets/vehicle_photo_gallery.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/vehicle_catalog_item.dart';
import '../../domain/entities/vehicle_color_entity.dart';
import '../../domain/entities/vehicle_variant_entity.dart';
import '../cubit/vehicle_detail_cubit.dart';
import '../cubit/vehicle_detail_state.dart';

/// Vehicle Detail Screen — Technical Specifications, Dual Powertrains, and Statutory Pricing
class VehicleDetailScreen extends StatefulWidget {
  final String modelId;

  const VehicleDetailScreen({super.key, required this.modelId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final VehicleDetailCubit _cubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = VehicleDetailCubit(modelId: widget.modelId)..loadDetails();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _cubit.close();
    _tabController.dispose();
    super.dispose();
  }

  String _formatInr(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        onRefresh: _cubit.loadDetails,
        activeNavigationId: 'vehicles',
        currentShowroomName: 'Vehicle Master',
        title: 'Vehicle Details',
        body: BlocConsumer<VehicleDetailCubit, VehicleDetailState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.status == VehicleDetailStatus.failure) {
              context.showErrorSnackBar(state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.status == VehicleDetailStatus.loading && state.item == null) {
              return AppSkeleton.detail();
            }

            if (state.status == VehicleDetailStatus.failure && state.item == null) {
              return AppErrorState(
                title: 'Failed to load vehicle details',
                message: state.errorMessage ?? 'An unexpected error occurred',
                onRetry: () => _cubit.loadDetails(),
              );
            }

            final item = state.item;
            if (item == null) return const SizedBox.shrink();

            return SingleChildScrollView(
              padding: ResponsiveUtils.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, item),
                  const SizedBox(height: AppDimensions.spacing20),

                  // Tab navigation
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryYellowDark,
                      unselectedLabelColor: context.isDarkMode
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      indicatorColor: AppColors.primaryYellow,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.layers_rounded),
                          text: 'Variants & Statutory Pricing (${item.variants.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.palette_rounded),
                          text: 'Colors & Palettes (${item.colors.length})',
                        ),
                        const Tab(
                          icon: Icon(Icons.photo_library_rounded),
                          text: 'Photos',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing24),

                  // Tab Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return _buildVariantsSection(context, item);
                      } else if (_tabController.index == 1) {
                        return _buildColorsSection(context, item);
                      } else {
                        return VehiclePhotoGallery(
                          modelId: item.model.id,
                          title: 'Model Photos',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacing40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VehicleCatalogItem item) {
    final isDark = context.isDarkMode;
    final isEv = item.model.isElectric;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isEv ? const Color(0xFF10B981) : const Color(0xFFF97316))
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Center(
                  child: Icon(
                    isEv ? Icons.electric_bolt_rounded : Icons.two_wheeler_rounded,
                    size: 32,
                    color: isEv ? const Color(0xFF10B981) : const Color(0xFFF97316),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            item.brand?.name ?? 'Unknown Brand',
                            style: AppTypography.captionSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppStatusBadge(
                          label: isEv ? 'ELECTRIC EV' : 'PETROL',
                          color: isEv ? const Color(0xFF10B981) : const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 8),
                        AppStatusBadge(
                          label: item.model.bodyType.toUpperCase(),
                          color: AppColors.primaryYellowDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.model.name,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    if (item.model.description != null && item.model.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.model.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Header actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton.secondary(
                    label: 'Edit Model',
                    leadingIcon: Icons.edit_outlined,
                    onPressed: () async {
                      await context.push('/vehicles/${item.model.id}/edit');
                      _cubit.loadDetails();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    tooltip: 'Delete Model',
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Vehicle Model'),
                          content: Text('Are you sure you want to delete ${item.model.name}? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final ok = await _cubit.deleteModel();
                        if (ok && mounted) {
                          router.pop();
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VARIANTS SECTION
  // ─────────────────────────────────────────────

  Widget _buildVariantsSection(BuildContext context, VehicleCatalogItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Model Variants & Pricing Breakdown',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            AppButton.primary(
              label: 'Add Variant',
              leadingIcon: Icons.add_rounded,
              onPressed: () => _showVariantModal(context, item: item),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),

        if (item.variants.isEmpty)
          const AppEmptyState(
            icon: Icons.layers_outlined,
            title: 'No Variants Defined',
            description: 'Add your first variant for this model to configure specifications and statutory pricing.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: item.variants.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing16),
            itemBuilder: (context, index) {
              final variant = item.variants[index];
              return _buildVariantCard(context, item, variant);
            },
          ),
      ],
    );
  }

  Widget _buildVariantCard(BuildContext context, VehicleCatalogItem item, VehicleVariantEntity variant) {
    final isDark = context.isDarkMode;
    final isEv = item.model.isElectric;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    variant.name,
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      variant.code,
                      style: AppTypography.captionSmall.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Variant',
                    onPressed: () => _showVariantModal(context, item: item, existing: variant),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                    tooltip: 'Delete Variant',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Variant'),
                          content: Text('Are you sure you want to delete variant "${variant.name}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _cubit.deleteVariant(variant.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Specs Badges Row
          Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing8,
            children: isEv
                ? [
                    if (variant.batteryCapacityKwh != null)
                      _buildSpecBadge(Icons.battery_charging_full_rounded, '${variant.batteryCapacityKwh} kWh Battery'),
                    if (variant.motorPowerKw != null)
                      _buildSpecBadge(Icons.speed_rounded, '${variant.motorPowerKw} kW Motor'),
                    if (variant.rangeKm != null)
                      _buildSpecBadge(Icons.route_rounded, '${variant.rangeKm} km Certified Range'),
                    if (variant.trueRangeKm != null)
                      _buildSpecBadge(Icons.verified_rounded, '${variant.trueRangeKm} km True Range'),
                    if (variant.chargingTimeHours != null)
                      _buildSpecBadge(Icons.access_time_rounded, '${variant.chargingTimeHours}h Charging'),
                    if (variant.fastCharging)
                      _buildSpecBadge(Icons.bolt_rounded, 'Fast Charging Supported', isHighlight: true),
                    if (variant.batteryWarrantyYears != null)
                      _buildSpecBadge(Icons.security_rounded, '${variant.batteryWarrantyYears} Yrs Warranty'),
                  ]
                : [
                    if (variant.engineCc != null)
                      _buildSpecBadge(Icons.engineering_rounded, '${variant.engineCc} cc Engine'),
                    if (variant.maxPower != null)
                      _buildSpecBadge(Icons.flash_on_rounded, variant.maxPower!),
                    if (variant.maxTorque != null)
                      _buildSpecBadge(Icons.rotate_right_rounded, variant.maxTorque!),
                    if (variant.mileageKmpl != null)
                      _buildSpecBadge(Icons.local_gas_station_rounded, '${variant.mileageKmpl} kmpl ARAI'),
                    if (variant.fuelCapacityLiters != null)
                      _buildSpecBadge(Icons.opacity_rounded, '${variant.fuelCapacityLiters}L Tank'),
                    if (variant.transmission != null)
                      _buildSpecBadge(Icons.settings_rounded, variant.transmission!),
                    if (variant.emissionNorm != null)
                      _buildSpecBadge(Icons.eco_rounded, variant.emissionNorm!),
                  ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Pricing Breakdown Table / Banner
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                    Text(
                      'Statutory Cost Breakdown (India INR)',
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        'On-Road: ${_formatInr(variant.estimatedOnRoadPrice)}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing12),
                context.isMobile
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildPriceItem('Ex-Showroom Price', _formatInr(variant.exShowroomPrice))),
                              Expanded(child: _buildPriceItem('GST Rate', '${variant.gstRate}%')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (variant.cessRate > 0)
                                Expanded(child: _buildPriceItem('CESS Rate', '${variant.cessRate}%')),
                              Expanded(child: _buildPriceItem('RTO Charges', _formatInr(variant.rtoCharges))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildPriceItem('Insurance (1+5 Yr)', _formatInr(variant.insuranceCharges))),
                              if (variant.otherCharges > 0)
                                Expanded(child: _buildPriceItem('Other / Handling', _formatInr(variant.otherCharges))),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildPriceItem('Ex-Showroom Price', _formatInr(variant.exShowroomPrice))),
                          Expanded(child: _buildPriceItem('GST Rate', '${variant.gstRate}%')),
                          if (variant.cessRate > 0)
                            Expanded(child: _buildPriceItem('CESS Rate', '${variant.cessRate}%')),
                          Expanded(child: _buildPriceItem('RTO Charges', _formatInr(variant.rtoCharges))),
                          Expanded(child: _buildPriceItem('Insurance (1+5 Yr)', _formatInr(variant.insuranceCharges))),
                          if (variant.otherCharges > 0)
                            Expanded(child: _buildPriceItem('Other / Handling', _formatInr(variant.otherCharges))),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label, {bool isHighlight = false}) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF10B981)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlight
                ? const Color(0xFF10B981)
                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                  : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String value) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // COLORS SECTION
  // ─────────────────────────────────────────────

  Widget _buildColorsSection(BuildContext context, VehicleCatalogItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Available Colors & Paint Options',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            AppButton.primary(
              label: 'Add Color',
              leadingIcon: Icons.add_rounded,
              onPressed: () => _showColorModal(context, item: item),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),

        if (item.colors.isEmpty)
          const AppEmptyState(
            icon: Icons.palette_outlined,
            title: 'No Colors Configured',
            description: 'Add paint options and color codes for this model.',
          )
        else if (context.isMobile)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: item.colors.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing12),
            itemBuilder: (context, index) {
              final color = item.colors[index];
              return _buildColorCard(context, item, color);
            },
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.gridCrossAxisCount(context, mobile: 1, tablet: 2, desktop: 3),
              mainAxisSpacing: AppDimensions.spacing16,
              crossAxisSpacing: AppDimensions.spacing16,
              childAspectRatio: 2.8,
            ),
            itemCount: item.colors.length,
            itemBuilder: (context, index) {
              final color = item.colors[index];
              return _buildColorCard(context, item, color);
            },
          ),
      ],
    );
  }

  Widget _buildColorCard(BuildContext context, VehicleCatalogItem item, VehicleColorEntity color) {
    final isDark = context.isDarkMode;
    Color parsedColor;
    try {
      final hex = color.hexCode.replaceAll('#', '');
      parsedColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      parsedColor = Colors.grey;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Color swatch circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: parsedColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: parsedColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  color.name,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${color.code} • ${color.additionalPrice > 0 ? "+ ${_formatInr(color.additionalPrice)}" : "Standard"}',
                  style: AppTypography.captionSmall.copyWith(
                    color: color.additionalPrice > 0 ? AppColors.primaryYellowDark : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                    fontWeight: color.additionalPrice > 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            tooltip: 'Delete Color',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Color'),
                  content: Text('Are you sure you want to delete color "${color.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                _cubit.deleteColor(color.id);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MODALS (VARIANT & COLOR)
  // ─────────────────────────────────────────────

  void _showVariantModal(BuildContext context, {required VehicleCatalogItem item, VehicleVariantEntity? existing}) {
    final isEv = item.model.isElectric;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final priceCtrl = TextEditingController(text: existing?.exShowroomPrice.toStringAsFixed(0) ?? '');
    final rtoCtrl = TextEditingController(text: existing?.rtoCharges.toStringAsFixed(0) ?? (isEv ? '2500' : '20000'));
    final insCtrl = TextEditingController(text: existing?.insuranceCharges.toStringAsFixed(0) ?? (isEv ? '6500' : '11000'));
    final otherCtrl = TextEditingController(text: existing?.otherCharges.toStringAsFixed(0) ?? '2500');

    // Petrol controllers
    final ccCtrl = TextEditingController(text: existing?.engineCc?.toString() ?? '');
    final powerCtrl = TextEditingController(text: existing?.maxPower ?? '');
    final torqueCtrl = TextEditingController(text: existing?.maxTorque ?? '');
    final mileageCtrl = TextEditingController(text: existing?.mileageKmpl?.toString() ?? '');
    final fuelTankCtrl = TextEditingController(text: existing?.fuelCapacityLiters?.toString() ?? '');
    final transCtrl = TextEditingController(text: existing?.transmission ?? '5-Speed Manual');

    // EV controllers
    final batteryCtrl = TextEditingController(text: existing?.batteryCapacityKwh?.toString() ?? '');
    final motorCtrl = TextEditingController(text: existing?.motorPowerKw?.toString() ?? '');
    final rangeCtrl = TextEditingController(text: existing?.rangeKm?.toString() ?? '');
    final trueRangeCtrl = TextEditingController(text: existing?.trueRangeKm?.toString() ?? '');
    final chargeTimeCtrl = TextEditingController(text: existing?.chargingTimeHours?.toString() ?? '');
    bool fastCharging = existing?.fastCharging ?? true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: Text(existing != null ? 'Edit Variant: ${existing.name}' : 'Add New Variant'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identification
                    ResponsiveFieldRow(
                      spacing: AppDimensions.spacing12,
                      children: [
                        AppTextField(
                          label: 'Variant Name *',
                          hint: isEv ? 'e.g. 3.7 kWh Pro' : 'e.g. DLX Pro Dual Tone',
                          controller: nameCtrl,
                        ),
                        AppTextField(
                          label: 'Variant Code *',
                          hint: 'e.g. VAR-01',
                          controller: codeCtrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Technical Specifications Section
                    Text(
                      isEv ? 'Electric Powertrain Specifications' : 'Internal Combustion Specifications',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    if (isEv) ...[
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Battery Capacity (kWh)',
                            hint: 'e.g. 3.7',
                            controller: batteryCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          AppTextField(
                            label: 'Motor Power (kW)',
                            hint: 'e.g. 6.4',
                            controller: motorCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Certified Range (km)',
                            hint: 'e.g. 150',
                            controller: rangeCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          AppTextField(
                            label: 'True / Real Range (km)',
                            hint: 'e.g. 110',
                            controller: trueRangeCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Charging Time (Hours)',
                            hint: 'e.g. 4.5',
                            controller: chargeTimeCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          CheckboxListTile(
                            title: const Text('Fast Charging'),
                            value: fastCharging,
                            onChanged: (val) => setModalState(() => fastCharging = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ] else ...[
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Engine Displacement (cc)',
                            hint: 'e.g. 348.36',
                            controller: ccCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          AppTextField(
                            label: 'Max Power',
                            hint: 'e.g. 20.8 bhp @ 5500 rpm',
                            controller: powerCtrl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Max Torque',
                            hint: 'e.g. 30 Nm @ 3000 rpm',
                            controller: torqueCtrl,
                          ),
                          AppTextField(
                            label: 'ARAI Mileage (kmpl)',
                            hint: 'e.g. 38.5',
                            controller: mileageCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ResponsiveFieldRow(
                        spacing: AppDimensions.spacing12,
                        children: [
                          AppTextField(
                            label: 'Fuel Tank Capacity (L)',
                            hint: 'e.g. 15.0',
                            controller: fuelTankCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          AppTextField(
                            label: 'Transmission',
                            hint: 'e.g. 5-Speed Manual',
                            controller: transCtrl,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Statutory Pricing Breakdown (INR)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    ResponsiveFieldRow(
                      spacing: AppDimensions.spacing12,
                      children: [
                        AppTextField(
                          label: 'Ex-Showroom Price (INR) *',
                          hint: 'e.g. 145000',
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        AppTextField(
                          label: 'RTO / Registration (INR)',
                          hint: 'e.g. 18000',
                          controller: rtoCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldRow(
                      spacing: AppDimensions.spacing12,
                      children: [
                        AppTextField(
                          label: 'Comprehensive Insurance (INR)',
                          hint: 'e.g. 10500',
                          controller: insCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        AppTextField(
                          label: 'Other / Handling (INR)',
                          hint: 'e.g. 2500',
                          controller: otherCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton.primary(
                label: existing != null ? 'Update Variant' : 'Create Variant',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;

                  if (name.isEmpty || code.isEmpty || price <= 0) {
                    context.showErrorSnackBar('Please provide variant name, code, and ex-showroom price');
                    return;
                  }

                  final rto = double.tryParse(rtoCtrl.text) ?? 0.0;
                  final ins = double.tryParse(insCtrl.text) ?? 0.0;
                  final other = double.tryParse(otherCtrl.text) ?? 0.0;

                  final variantEntity = VehicleVariantEntity(
                    id: existing?.id ?? '',
                    modelId: item.model.id,
                    name: name,
                    code: code,
                    engineCc: double.tryParse(ccCtrl.text),
                    maxPower: powerCtrl.text.isNotEmpty ? powerCtrl.text : null,
                    maxTorque: torqueCtrl.text.isNotEmpty ? torqueCtrl.text : null,
                    mileageKmpl: double.tryParse(mileageCtrl.text),
                    fuelCapacityLiters: double.tryParse(fuelTankCtrl.text),
                    transmission: transCtrl.text.isNotEmpty ? transCtrl.text : null,
                    emissionNorm: 'BS6 Phase 2',
                    batteryCapacityKwh: double.tryParse(batteryCtrl.text),
                    motorPowerKw: double.tryParse(motorCtrl.text),
                    rangeKm: int.tryParse(rangeCtrl.text),
                    trueRangeKm: int.tryParse(trueRangeCtrl.text),
                    chargingTimeHours: double.tryParse(chargeTimeCtrl.text),
                    fastCharging: fastCharging,
                    batteryWarrantyYears: isEv ? 3 : null,
                    exShowroomPrice: price,
                    gstRate: isEv ? 5.0 : 28.0,
                    cessRate: (!isEv && (double.tryParse(ccCtrl.text) ?? 0) > 350) ? 3.0 : 0.0,
                    rtoCharges: rto,
                    insuranceCharges: ins,
                    otherCharges: other,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  Navigator.pop(dialogCtx);
                  await _cubit.saveVariant(variantEntity);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorModal(BuildContext context, {required VehicleCatalogItem item}) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    String selectedHex = '#9B111E';

    final presetColors = [
      {'name': 'Crimson Red', 'hex': '#9B111E'},
      {'name': 'Pearl Black', 'hex': '#111111'},
      {'name': 'Pure White', 'hex': '#F8F9FA'},
      {'name': 'Space Grey', 'hex': '#4A4E51'},
      {'name': 'Matte Blue', 'hex': '#0047AB'},
      {'name': 'Electric Green', 'hex': '#10B981'},
      {'name': 'Fury Yellow', 'hex': '#F5C518'},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Add Paint / Color Option'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Color Name *',
                    hint: 'e.g. Precious Red Metallic',
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Color Code *',
                    hint: 'e.g. RED-MET-01',
                    controller: codeCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Additional Paint Price (INR)',
                    hint: '0 for standard paint',
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Color Swatch',
                    style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: presetColors.map((preset) {
                      final hex = preset['hex']!;
                      final isSelected = selectedHex == hex;
                      Color c;
                      try {
                        c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                      } catch (_) {
                        c = Colors.grey;
                      }

                      return InkWell(
                        onTap: () => setModalState(() => selectedHex = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryYellow : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              AppButton.primary(
                label: 'Save Color',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final extraPrice = double.tryParse(priceCtrl.text) ?? 0.0;

                  if (name.isEmpty || code.isEmpty) {
                    context.showErrorSnackBar('Color name and code are required');
                    return;
                  }

                  final color = VehicleColorEntity(
                    id: '',
                    modelId: item.model.id,
                    name: name,
                    code: code,
                    hexCode: selectedHex,
                    additionalPrice: extraPrice,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  Navigator.pop(dialogCtx);
                  await _cubit.saveColor(color);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
