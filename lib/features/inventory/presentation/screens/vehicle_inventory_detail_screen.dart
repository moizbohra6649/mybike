import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../common/widgets/vehicle_photo_gallery.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/entities/vehicle_inventory_item.dart';
import '../cubit/vehicle_inventory_detail_cubit.dart';
import '../cubit/vehicle_inventory_detail_state.dart';

/// Detailed Vehicle Unit (VIN) Dossier Screen
/// High-fidelity dealer asset dossier with serialization, inspection, bay location, and lifecycle audit log.
class VehicleInventoryDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleInventoryDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleInventoryDetailScreen> createState() => _VehicleInventoryDetailScreenState();
}

class _VehicleInventoryDetailScreenState extends State<VehicleInventoryDetailScreen> {
  late final VehicleInventoryDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = VehicleInventoryDetailCubit(vehicleId: widget.vehicleId)..loadDetails();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatInr(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_stock':
        return AppColors.success;
      case 'booked':
      case 'allocated':
        return AppColors.info;
      case 'in_transit':
        return AppColors.warning;
      case 'sold':
      case 'delivered':
        return const Color(0xFF6366F1); // Indigo
      case 'damaged':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<VehicleInventoryDetailCubit, VehicleInventoryDetailState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
          }
        },
        builder: (context, state) {
          final item = state.item;

          return AppScaffold(
            onRefresh: _cubit.loadDetails,
            activeNavigationId: 'inventory',
            currentShowroomName: item?.showroom?.name ?? 'VIN Dossier',
            title: item != null ? 'VIN Dossier: ${item.vehicle.vin}' : 'Vehicle Unit Dossier',
            actions: [
              if (item != null) ...[
                if (!isMobile) ...[
                  AppButton.secondary(
                    label: 'Status',
                    leadingIcon: Icons.swap_horiz_rounded,
                    onPressed: () => _showStatusModal(context, item.vehicle.status),
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  AppButton.secondary(
                    label: 'PDI Check',
                    leadingIcon: Icons.fact_check_outlined,
                    onPressed: () => _showPdiModal(context, item.vehicle.pdiStatus, item.vehicle.pdiNotes),
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  AppButton.secondary(
                    label: 'Relocate',
                    leadingIcon: Icons.edit_location_alt_outlined,
                    onPressed: () => _showRelocateModal(context, item.vehicle.locationInShowroom),
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                ],
              ],
              AppButton.ghost(
                label: 'Back',
                leadingIcon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
            ],
            body: state.status == VehicleInventoryDetailStatus.loading && item == null
                ? AppSkeleton.detail()
                : state.status == VehicleInventoryDetailStatus.failure && item == null
                    ? AppErrorState(
                        title: 'Vehicle Not Found',
                        message: state.errorMessage ?? 'Unable to find vehicle unit in inventory',
                        onRetry: () => _cubit.loadDetails(),
                      )
                    : item == null
                        ? const SizedBox.shrink()
                        : _buildContent(context, item, state),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, VehicleInventoryItem item, VehicleInventoryDetailState state) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Hero Header & Key KPI Strip ───
          _buildHeroHeader(context, item),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Responsive Grid ───
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Serialized Coordinates & PDI
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildIdentifiersCard(context, item),
                      const SizedBox(height: AppDimensions.spacing20),
                      _buildPdiCard(context, item),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing20),

                // Right Column: Bay Storage & Lifecycle Audit Log
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildLocationCard(context, item),
                      const SizedBox(height: AppDimensions.spacing20),
                      _buildTimelineCard(context, state.movements),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Mobile & Tablet: Stacked Single Column
            _buildIdentifiersCard(context, item),
            const SizedBox(height: AppDimensions.spacing16),
            _buildPdiCard(context, item),
            const SizedBox(height: AppDimensions.spacing16),
            _buildLocationCard(context, item),
            const SizedBox(height: AppDimensions.spacing16),
            _buildTimelineCard(context, state.movements),
          ],

          // ─── Vehicle Photo Gallery ───
          const SizedBox(height: AppDimensions.spacing20),
          VehiclePhotoGallery(
            vehicleId: item.vehicle.id,
            title: 'Vehicle Photos',
          ),
          const SizedBox(height: AppDimensions.spacing40),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. HERO DOSSIER HEADER
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHeroHeader(BuildContext context, VehicleInventoryItem item) {
    final isDark = context.isDarkMode;
    final v = item.vehicle;
    final isEv = item.isElectric;
    final statusColor = _getStatusColor(v.status);
    final isMobile = ResponsiveUtils.isMobile(context);

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            // Mobile Hero Header: Stacked row with avatar & title, then full-width badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEv
                          ? [const Color(0xFF10B981).withValues(alpha: 0.25), const Color(0xFF059669).withValues(alpha: 0.1)]
                          : [AppColors.primaryYellow.withValues(alpha: 0.3), AppColors.primaryYellowDark.withValues(alpha: 0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isEv
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : AppColors.primaryYellowDark.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isEv ? Icons.electric_bolt_rounded : Icons.two_wheeler_rounded,
                      size: 26,
                      color: isEv ? const Color(0xFF10B981) : AppColors.primaryYellowDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.color?.name ?? "Color N/A"} • ${item.showroom?.name ?? "Branch N/A"}',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'status') _showStatusModal(context, v.status);
                    if (val == 'pdi') _showPdiModal(context, v.pdiStatus, v.pdiNotes);
                    if (val == 'relocate') _showRelocateModal(context, v.locationInShowroom);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'status', child: Text('Update Status')),
                    const PopupMenuItem(value: 'pdi', child: Text('Update PDI Check')),
                    const PopupMenuItem(value: 'relocate', child: Text('Relocate Bay')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full-width badges wrap
            Wrap(
              spacing: AppDimensions.spacing8,
              runSpacing: AppDimensions.spacing6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v.vin,
                        style: AppTypography.labelLarge.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: v.vin));
                          context.showSuccessSnackBar('VIN copied to clipboard');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: v.status.replaceAll('_', ' ').toUpperCase(),
                  color: statusColor,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isEv ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEv ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                        size: 13,
                        color: isEv ? const Color(0xFF10B981) : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEv ? 'ELECTRIC EV' : 'PETROL ICE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isEv ? const Color(0xFF10B981) : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Inward: ${DateFormat('dd MMM yyyy').format(v.receivedDate)}',
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Desktop Hero Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Type Glow Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEv
                          ? [const Color(0xFF10B981).withValues(alpha: 0.25), const Color(0xFF059669).withValues(alpha: 0.1)]
                          : [AppColors.primaryYellow.withValues(alpha: 0.3), AppColors.primaryYellowDark.withValues(alpha: 0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: isEv
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : AppColors.primaryYellowDark.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isEv ? Icons.electric_bolt_rounded : Icons.two_wheeler_rounded,
                      size: 34,
                      color: isEv ? const Color(0xFF10B981) : AppColors.primaryYellowDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),

                // Title, VIN, & Status Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppDimensions.spacing8,
                        runSpacing: AppDimensions.spacing6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Monospaced VIN Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  v.vin,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: v.vin));
                                    context.showSuccessSnackBar('VIN copied to clipboard');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Unit Status Badge
                          AppStatusBadge(
                            label: v.status.replaceAll('_', ' ').toUpperCase(),
                            color: statusColor,
                          ),

                          // EV or Petrol Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isEv ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isEv ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                                  size: 13,
                                  color: isEv ? const Color(0xFF10B981) : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isEv ? 'ELECTRIC EV' : 'PETROL ICE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isEv ? const Color(0xFF10B981) : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing8),

                      // Display Name (Brand + Model + Variant)
                      Text(
                        item.displayName,
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing4),

                      // Meta: Color, Showroom, Inward Date
                      Wrap(
                        spacing: AppDimensions.spacing12,
                        runSpacing: AppDimensions.spacing4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Color Tag
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _parseColor(item.color?.hexCode),
                                  border: Border.all(color: Colors.grey.shade400, width: 0.8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.color?.name ?? 'Color N/A',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          Text('•', style: TextStyle(color: Colors.grey.shade500)),

                          // Showroom Branch
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                item.showroom?.name ?? 'Branch N/A',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),

                          Text('•', style: TextStyle(color: Colors.grey.shade500)),

                          // Inward Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Inward: ${DateFormat('dd MMM yyyy').format(v.receivedDate)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Key KPI Highlights Bar ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildKpiChip(
                  icon: Icons.key_rounded,
                  label: 'Physical Key Tag',
                  value: v.keyNumber ?? 'Not Assigned',
                  isDark: isDark,
                  accentColor: AppColors.primaryYellowDark,
                ),
                _buildKpiChip(
                  icon: Icons.speed_rounded,
                  label: 'Odometer Reading',
                  value: '${v.odometerReadingKm.toStringAsFixed(0)} km',
                  isDark: isDark,
                  accentColor: const Color(0xFF3B82F6),
                ),
                _buildKpiChip(
                  icon: Icons.place_rounded,
                  label: 'Storage Bay',
                  value: v.locationInShowroom.isNotEmpty ? v.locationInShowroom : 'Main Display',
                  isDark: isDark,
                  accentColor: const Color(0xFF8B5CF6),
                ),
                if (isEv)
                  _buildKpiChip(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Battery Health',
                    value: '${v.batteryHealthPercentage?.toStringAsFixed(1) ?? "100.0"}% Health',
                    isDark: isDark,
                    accentColor: const Color(0xFF10B981),
                  )
                else
                  _buildKpiChip(
                    icon: Icons.payments_outlined,
                    label: 'Purchase Cost',
                    value: _formatInr(v.purchaseCost),
                    isDark: isDark,
                    accentColor: AppColors.success,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color accentColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. SERIALIZED ASSET IDENTIFICATION CARD
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildIdentifiersCard(BuildContext context, VehicleInventoryItem item) {
    final v = item.vehicle;
    final isEv = item.isElectric;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 22, color: AppColors.primaryYellowDark),
                  const SizedBox(width: 8),
                  Text(
                    'Serialized Asset Identification',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Asset ID: ${v.id.length > 8 ? '${v.id.substring(0, 8)}...' : v.id}',
                  style: AppTypography.captionSmall.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Primary Grid of Coordinates
          Wrap(
            spacing: AppDimensions.spacing16,
            runSpacing: AppDimensions.spacing12,
            children: [
              _buildSpecTile(
                context,
                title: 'Chassis / VIN Number',
                value: v.vin,
                icon: Icons.confirmation_number_outlined,
                isMonospace: true,
                canCopy: true,
              ),
              _buildSpecTile(
                context,
                title: 'Physical Key Tag',
                value: v.keyNumber ?? 'Not Assigned',
                icon: Icons.vpn_key_outlined,
                canCopy: v.keyNumber != null,
              ),
              if (isEv) ...[
                _buildSpecTile(
                  context,
                  title: 'Electric Motor Serial',
                  value: v.motorNumber ?? 'N/A',
                  icon: Icons.electric_meter_outlined,
                  isMonospace: true,
                  canCopy: v.motorNumber != null,
                ),
                _buildSpecTile(
                  context,
                  title: 'Battery Serial Number',
                  value: v.batterySerialNumber ?? 'N/A',
                  icon: Icons.battery_saver_outlined,
                  isMonospace: true,
                  canCopy: v.batterySerialNumber != null,
                ),
                _buildBatteryHealthTile(context, v.batteryHealthPercentage),
              ] else ...[
                _buildSpecTile(
                  context,
                  title: 'Engine Serial Number',
                  value: v.engineNumber ?? 'N/A',
                  icon: Icons.precision_manufacturing_outlined,
                  isMonospace: true,
                  canCopy: v.engineNumber != null,
                ),
              ],
              _buildSpecTile(
                context,
                title: 'Odometer Reading',
                value: '${v.odometerReadingKm.toStringAsFixed(1)} km',
                icon: Icons.shutter_speed_outlined,
              ),
              _buildSpecTile(
                context,
                title: 'Dealer Purchase Cost',
                value: _formatInr(v.purchaseCost),
                icon: Icons.currency_rupee_rounded,
                isHighlight: true,
              ),
              _buildSpecTile(
                context,
                title: 'Mfg Year & Month',
                value: v.mfgYearMonth,
                icon: Icons.event_note_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool isMonospace = false,
    bool canCopy = false,
    bool isHighlight = false,
  }) {
    final isDark = context.isDarkMode;
    final width = ResponsiveUtils.isMobile(context) ? double.infinity : 240.0;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isHighlight
              ? AppColors.primaryYellowDark.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlight ? AppColors.primaryYellowDark : Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.labelLarge.copyWith(
                    fontFamily: isMonospace ? 'monospace' : null,
                    fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: isMonospace ? 0.6 : null,
                    color: isHighlight
                        ? (isDark ? AppColors.primaryYellow : AppColors.primaryYellowDark)
                        : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy)
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                context.showSuccessSnackBar('$title copied');
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryHealthTile(BuildContext context, double? health) {
    final isDark = context.isDarkMode;
    final width = ResponsiveUtils.isMobile(context) ? double.infinity : 240.0;
    final pct = (health ?? 100.0).clamp(0.0, 100.0);
    final color = pct > 80
        ? const Color(0xFF10B981)
        : (pct > 50 ? const Color(0xFFF59E0B) : AppColors.error);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.battery_std_rounded, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Battery Health Status',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. PRE-DELIVERY INSPECTION (PDI) CARD
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildPdiCard(BuildContext context, VehicleInventoryItem item) {
    final isDark = context.isDarkMode;
    final v = item.vehicle;
    final isPassed = v.pdiStatus == 'passed';
    final isFailed = v.pdiStatus == 'failed';
    final statusColor = isPassed
        ? const Color(0xFF10B981)
        : (isFailed ? AppColors.error : const Color(0xFFF59E0B));

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Badge & Action
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPassed ? Icons.verified_user_rounded : Icons.fact_check_outlined,
                    size: 22,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pre-Delivery Inspection (PDI)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              AppStatusBadge(
                label: isPassed ? 'PDI PASSED' : (isFailed ? 'PDI FAILED' : 'PDI PENDING'),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // PDI Checklist Items Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildPdiCheckItem('Electrical, Lighting & Diagnostics', isPassed, isDark),
                const SizedBox(height: 6),
                _buildPdiCheckItem('Braking System, Tyres & Suspension', isPassed, isDark),
                const SizedBox(height: 6),
                _buildPdiCheckItem('Bodywork, Paint, Mirrors & Accessories', isPassed, isDark),
                const SizedBox(height: 6),
                _buildPdiCheckItem('Fluid Levels & Final Quality Assurance', isPassed, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Technician Notes
          Text(
            'TECHNICIAN INSPECTION NOTES',
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              (v.pdiNotes != null && v.pdiNotes!.isNotEmpty)
                  ? v.pdiNotes!
                  : 'No technician notes recorded for this unit yet.',
              style: AppTypography.bodySmall.copyWith(
                fontStyle: (v.pdiNotes == null || v.pdiNotes!.isEmpty) ? FontStyle.italic : FontStyle.normal,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.secondary(
              label: 'Update PDI Inspection',
              leadingIcon: Icons.edit_note_rounded,
              onPressed: () => _showPdiModal(context, v.pdiStatus, v.pdiNotes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdiCheckItem(String label, bool isPassed, bool isDark) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle_rounded : Icons.pending_outlined,
          size: 16,
          color: isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isPassed ? FontWeight.w600 : FontWeight.normal,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
        ),
        Text(
          isPassed ? 'VERIFIED' : 'PENDING CHECK',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. SHOWROOM & STORAGE BAY CARD
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildLocationCard(BuildContext context, VehicleInventoryItem item) {
    final v = item.vehicle;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 22, color: AppColors.primaryYellowDark),
                  const SizedBox(width: 8),
                  Text(
                    'Showroom & Storage Bay',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
                tooltip: 'Relocate Bay',
                onPressed: () => _showRelocateModal(context, v.locationInShowroom),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Showroom Branch Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 28, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Showroom Branch',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.showroom?.name ?? 'Central Showroom Branch',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Physical Storage Bay
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              ),
            ),
            child: ResponsiveUtils.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shelves, size: 20, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PHYSICAL BAY POSITION',
                                  style: AppTypography.captionSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  v.locationInShowroom.isNotEmpty ? v.locationInShowroom : 'Main Display Area',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.secondary(
                          label: 'Relocate Bay Position',
                          leadingIcon: Icons.swap_vert_rounded,
                          onPressed: () => _showRelocateModal(context, v.locationInShowroom),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shelves, size: 20, color: Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PHYSICAL BAY POSITION',
                              style: AppTypography.captionSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.locationInShowroom.isNotEmpty ? v.locationInShowroom : 'Main Display Area',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton.secondary(
                        label: 'Relocate',
                        leadingIcon: Icons.swap_vert_rounded,
                        onPressed: () => _showRelocateModal(context, v.locationInShowroom),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. LIFECYCLE MOVEMENT & AUDIT TIMELINE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineCard(BuildContext context, List<StockMovementEntity> movements) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 22, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Lifecycle & Movement Audit Log',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          if (movements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.timeline_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No stock movement events recorded yet.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final m = movements[index];
                final isLast = index == movements.length - 1;
                return _buildTimelineNode(context, m, isLast, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context,
    StockMovementEntity m,
    bool isLast,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    IconData icon;
    Color nodeColor;

    switch (m.movementType) {
      case 'inward_grn':
        icon = Icons.input_rounded;
        nodeColor = const Color(0xFF10B981);
        break;
      case 'transfer_dispatch':
      case 'transfer_receive':
        icon = Icons.local_shipping_outlined;
        nodeColor = const Color(0xFF3B82F6);
        break;
      case 'booking_allocation':
      case 'sale_delivery':
        icon = Icons.handshake_outlined;
        nodeColor = const Color(0xFF6366F1);
        break;
      case 'pdi_status_update':
        icon = Icons.fact_check_outlined;
        nodeColor = const Color(0xFF14B8A6);
        break;
      case 'bay_location_change':
        icon = Icons.edit_location_alt_outlined;
        nodeColor = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.radio_button_checked_rounded;
        nodeColor = AppColors.primaryYellowDark;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line & Dot
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeColor.withValues(alpha: 0.15),
                  border: Border.all(color: nodeColor, width: 1.5),
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: nodeColor),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.displayTitle,
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        dateFormat.format(m.createdAt),
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                    ],
                  ),
                  if (m.remarks != null && m.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      m.remarks!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                  if (m.performedBy != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Staff: ${m.performedBy}',
                      style: AppTypography.captionSmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 6. MODAL DIALOGS (PDI, RELOCATE, STATUS)
  // ═════════════════════════════════════════════════════════════════════════

  void _showPdiModal(BuildContext context, String currentStatus, String? currentNotes) {
    String selectedStatus = currentStatus;
    final notesController = TextEditingController(text: currentNotes ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.fact_check_outlined, color: AppColors.primaryYellowDark),
                SizedBox(width: 8),
                Text('Update Pre-Delivery Inspection (PDI)'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown<String>(
                    label: 'PDI Inspection Status',
                    value: selectedStatus,
                    items: const ['passed', 'pending', 'failed'],
                    itemLabel: (s) {
                      switch (s) {
                        case 'passed':
                          return 'PASSED (Inspection Cleared)';
                        case 'failed':
                          return 'FAILED (Issues Detected)';
                        default:
                          return 'PENDING (Awaiting Check)';
                      }
                    },
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Technician Inspection Notes',
                    hint: 'Details of battery charge, brake checks, fluids, tyre pressure, paint condition...',
                    controller: notesController,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton.primary(
                label: 'Save Inspection',
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final success = await _cubit.updatePdi(
                    selectedStatus,
                    notes: notesController.text.trim(),
                  );
                  if (success && context.mounted) {
                    context.showSuccessSnackBar('PDI status updated successfully');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRelocateModal(BuildContext context, String currentLocation) {
    final locationController = TextEditingController(text: currentLocation);
    final suggestions = ['Display Floor A1', 'Display Floor Bay B2', 'Warehouse Bay 1', 'Storage Yard A', 'PDI Service Bay'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_location_alt_outlined, color: AppColors.primaryYellowDark),
                SizedBox(width: 8),
                Text('Relocate Showroom Bay'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'New Bay Location',
                    hint: 'e.g. Display Floor Bay A1, Stockyard Bay 4',
                    controller: locationController,
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Suggestions:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestions.map((s) {
                      return ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            locationController.text = s;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton.primary(
                label: 'Save Bay Location',
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final success = await _cubit.updateLocation(locationController.text.trim());
                  if (success && context.mounted) {
                    context.showSuccessSnackBar('Vehicle bay location updated');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusModal(BuildContext context, String currentStatus) {
    String selectedStatus = currentStatus;
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: AppColors.primaryYellowDark),
                SizedBox(width: 8),
                Text('Update Unit Inventory Status'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown<String>(
                    label: 'Inventory Status',
                    value: selectedStatus,
                    items: const ['in_stock', 'booked', 'allocated', 'in_transit', 'damaged'],
                    itemLabel: (s) => s.replaceAll('_', ' ').toUpperCase(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Adjustment Remarks / Reason',
                    hint: 'e.g. Returned to stock after booking cancellation, transit arrival...',
                    controller: remarksController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              AppButton.primary(
                label: 'Update Status',
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final success = await _cubit.updateStatus(
                    selectedStatus,
                    remarks: remarksController.text.trim(),
                  );
                  if (success && context.mounted) {
                    context.showSuccessSnackBar('Vehicle unit status updated');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return Colors.grey;
  }
}
