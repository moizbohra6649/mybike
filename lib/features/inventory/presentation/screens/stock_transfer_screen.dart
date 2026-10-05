import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/stock_transfer_entity.dart';
import '../cubit/stock_transfer_cubit.dart';
import '../cubit/stock_transfer_state.dart';

/// Inter-Showroom Branch Stock Transfer Management Screen
class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  late final StockTransferCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = StockTransferCubit()..loadTransfers();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        onRefresh: _cubit.loadTransfers,
        activeNavigationId: 'inventory',
        currentShowroomName: 'Stock Transfers',
        title: 'Inter-Branch Transfers',
        body: BlocConsumer<StockTransferCubit, StockTransferState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              context.showErrorSnackBar(state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.status == StockTransferStatus.loading && state.transfers.isEmpty) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            final showroomMap = {for (final s in state.showrooms) s.showroom.id: s.showroom};

            return SingleChildScrollView(
              padding: ResponsiveUtils.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: 'Inter-Showroom Stock Transfers',
                    countBadge: state.transfers.length,
                    subtitle: 'Manage vehicle relocations between dealership branch locations with dispatch and receipt challans',
                    trailing: AppButton.primary(
                      label: 'Create Transfer Request',
                      leadingIcon: Icons.swap_horiz_rounded,
                      onPressed: () => _showCreateTransferModal(context),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing24),

                  if (state.transfers.isEmpty)
                    const AppEmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No Stock Transfers Found',
                      description: 'Create your first inter-showroom transfer request to move inventory between branches.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.transfers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing16),
                      itemBuilder: (context, index) {
                        final t = state.transfers[index];
                        final source = showroomMap[t.sourceShowroomId];
                        final dest = showroomMap[t.destinationShowroomId];
                        return _buildTransferCard(context, t, source?.name ?? 'Branch A', dest?.name ?? 'Branch B');
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

  Widget _buildTransferCard(BuildContext context, StockTransferEntity t, String sourceName, String destName) {
    final isDark = context.isDarkMode;

    Color statusColor;
    switch (t.status) {
      case 'requested':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'in_transit':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'received':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = Colors.grey;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    t.transferNumber,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  AppStatusBadge(
                    label: t.status.replaceAll('_', ' ').toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  '${t.items.length} Units',
                  style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Route row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source Branch', style: AppTypography.captionSmall.copyWith(color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                    const SizedBox(height: 2),
                    Text(sourceName, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryYellowDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Destination Branch', style: AppTypography.captionSmall.copyWith(color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                    const SizedBox(height: 2),
                    Text(destName, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (t.notes != null && t.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              'Notes: ${t.notes}',
              style: AppTypography.captionMedium.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            ),
          ],
          const SizedBox(height: AppDimensions.spacing16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (t.isRequested)
                AppButton.primary(
                  label: 'Dispatch Vehicles',
                  leadingIcon: Icons.local_shipping_outlined,
                  onPressed: () => _cubit.dispatchTransfer(t.id),
                ),
              if (t.isInTransit)
                AppButton.primary(
                  label: 'Acknowledge Receipt',
                  leadingIcon: Icons.check_circle_outline_rounded,
                  onPressed: () => _cubit.receiveTransfer(t.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTransferModal(BuildContext context) {
    String? sourceId;
    String? destId;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final state = _cubit.state;

          return AlertDialog(
            title: const Text('Initiate Inter-Showroom Transfer'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveFieldRow(
                      children: [
                        AppDropdown<String?>(
                          label: 'Source Branch *',
                          value: sourceId,
                          items: state.showrooms.map((s) => s.showroom.id).toList(),
                          itemLabel: (id) {
                            final s = state.showrooms.where((sh) => sh.showroom.id == id).firstOrNull;
                            return s != null ? '${s.showroom.name} (${s.showroom.code})' : 'Select Source';
                          },
                          onChanged: (id) {
                            if (id != null) {
                              setModalState(() => sourceId = id);
                              _cubit.selectSourceShowroom(id);
                            }
                          },
                        ),
                        AppDropdown<String?>(
                          label: 'Destination Branch *',
                          value: destId,
                          items: state.showrooms.map((s) => s.showroom.id).toList(),
                          itemLabel: (id) {
                            final s = state.showrooms.where((sh) => sh.showroom.id == id).firstOrNull;
                            return s != null ? '${s.showroom.name} (${s.showroom.code})' : 'Select Destination';
                          },
                          onChanged: (id) {
                            if (id != null) {
                              setModalState(() => destId = id);
                              _cubit.selectDestShowroom(id);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Transfer Purpose / Logistics Notes',
                      hint: 'e.g. Relocating for VIP customer delivery at Pune',
                      controller: notesController,
                      onChanged: (val) => _cubit.notesChanged(val),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Select Vehicles to Transfer (${state.selectedVehicleIds.length} selected)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    if (sourceId == null)
                      const Text('Select a source branch to view available vehicles.')
                    else if (state.availableVehicles.isEmpty)
                      const Text('No in-stock vehicles available at the selected branch.')
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: ListView.builder(
                          itemCount: state.availableVehicles.length,
                          itemBuilder: (c, i) {
                            final item = state.availableVehicles[i];
                            final isChecked = state.selectedVehicleIds.contains(item.vehicle.id);
                            return CheckboxListTile(
                              title: Text('${item.displayName} [${item.vehicle.vin}]', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text('Color: ${item.color?.name ?? "N/A"} • ${item.vehicle.locationInShowroom}', style: AppTypography.captionLarge),
                              value: isChecked,
                              onChanged: (_) {
                                _cubit.toggleVehicleSelection(item.vehicle.id);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              AppButton.primary(
                label: 'Create Transfer',
                onPressed: () async {
                  final navigator = Navigator.of(dialogCtx);
                  final ok = await _cubit.createTransfer();
                  if (ok) {
                    navigator.pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
