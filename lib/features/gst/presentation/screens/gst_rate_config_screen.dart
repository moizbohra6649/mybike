import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/gst_rate_entity.dart';
import '../cubit/gst_rate_config_cubit.dart';
import '../cubit/gst_rate_config_state.dart';

/// Configurable GST Tax Rates Master Screen
class GstRateConfigScreen extends StatelessWidget {
  const GstRateConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GstRateConfigCubit()..loadRates(),
      child: const _GstRateConfigView(),
    );
  }
}

class _GstRateConfigView extends StatelessWidget {
  const _GstRateConfigView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isDark = context.isDarkMode;

    return AppScaffold(
      onRefresh: () => context.read<GstRateConfigCubit>().loadRates(),
      title: 'GST Tax Rates Master',
      activeNavigationId: 'gst',
      actions: [
        IconButton(
          tooltip: 'Back to GST Hub',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        AppButton(
          label: 'Add Tax Slab',
          leadingIcon: Icons.add,
          onPressed: () => _showAddEditRateDialog(context, null),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<GstRateConfigCubit>().loadRates(),
        ),
      ],
      body: BlocConsumer<GstRateConfigCubit, GstRateConfigState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionSuccessMessage!), backgroundColor: AppColors.success),
            );
          }
        },
        builder: (context, state) {
          if (state.status == GstRateConfigStatus.loading && state.rates.isEmpty) {
            return AppSkeleton.table(kpis: 3, rows: 6, columns: 4);
          }

          if (state.status == GstRateConfigStatus.failure && state.rates.isEmpty) {
            return AppErrorState(
              title: 'Failed to Load Tax Rates',
              message: state.errorMessage ?? 'An error occurred.',
              onRetry: () => context.read<GstRateConfigCubit>().loadRates(),
            );
          }

          final rates = state.filteredRates;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppDimensions.spacing24 : AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter & Search Controls
                _buildFilterControls(context, state, isDark),
                const SizedBox(height: AppDimensions.spacing20),

                // Rates List / Table
                if (rates.isEmpty)
                  AppEmptyState(
                    title: 'No Tax Slabs Found',
                    description: 'No tax slabs match your current filter criteria.',
                    actionLabel: 'Reset Filters',
                    onActionPressed: () => context.read<GstRateConfigCubit>().filterByCategory(null),
                  )
                else
                  _buildRatesTable(context, rates, isDesktop, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Filter & Search Bar ───
  Widget _buildFilterControls(BuildContext context, GstRateConfigState state, bool isDark) {
    const categories = [
      {'id': null, 'label': 'All Slabs'},
      {'id': 'vehicle_ice', 'label': 'Petrol (ICE)'},
      {'id': 'vehicle_ev', 'label': 'EVs'},
      {'id': 'spare_parts', 'label': 'Spare Parts'},
      {'id': 'accessories', 'label': 'Accessories'},
      {'id': 'service_labor', 'label': 'Workshop Labor'},
      {'id': 'documentation', 'label': 'Documentation'},
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by HSN/SAC code, description, or commodity name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => context.read<GstRateConfigCubit>().setSearchQuery(val),
          ),
          const SizedBox(height: AppDimensions.spacing12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = state.selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacing8),
                  child: ChoiceChip(
                    label: Text(
                      cat['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryYellow,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<GstRateConfigCubit>().filterByCategory(cat['id']);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rates Table / Cards ───
  Widget _buildRatesTable(
    BuildContext context,
    List<GstRateEntity> rates,
    bool isDesktop,
    bool isDark,
  ) {
    return Column(
      children: rates.map((rate) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
          child: AppCard(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // HSN / SAC Badge
                Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        rate.hsnSacCode,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryYellow,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HSN/SAC',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),

                // Name & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              rate.taxName,
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rate.categoryLabel,
                              style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (rate.description != null)
                        Text(
                          rate.description!,
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Rates Breakdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rate.gstRate}% GST',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CGST: ${rate.cgstRate}% | SGST: ${rate.sgstRate}% | IGST: ${rate.igstRate}%',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppDimensions.spacing16),

                // Action Menu
                IconButton(
                  tooltip: 'Edit Slab',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showAddEditRateDialog(context, rate),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Add / Edit Modal ───
  void _showAddEditRateDialog(BuildContext context, GstRateEntity? existingRate) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _AddEditRateDialog(
        existingRate: existingRate,
        cubit: context.read<GstRateConfigCubit>(),
      ),
    );
  }
}

class _AddEditRateDialog extends StatefulWidget {
  final GstRateEntity? existingRate;
  final GstRateConfigCubit cubit;

  const _AddEditRateDialog({this.existingRate, required this.cubit});

  @override
  State<_AddEditRateDialog> createState() => _AddEditRateDialogState();
}

class _AddEditRateDialogState extends State<_AddEditRateDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _hsnController;
  late final TextEditingController _rateController;
  late final TextEditingController _descController;
  String _category = 'vehicle_ice';

  @override
  void initState() {
    super.initState();
    final r = widget.existingRate;
    _nameController = TextEditingController(text: r?.taxName ?? '');
    _hsnController = TextEditingController(text: r?.hsnSacCode ?? '');
    _rateController = TextEditingController(text: r != null ? r.gstRate.toString() : '28.0');
    _descController = TextEditingController(text: r?.description ?? '');
    _category = r?.category ?? 'vehicle_ice';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    _rateController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingRate != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit GST Tax Slab' : 'Add New GST Tax Slab'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _hsnController,
                decoration: const InputDecoration(labelText: 'HSN / SAC Code (e.g. 8711, 8714, 9987)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tax Commodity Name'),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Category',
                value: _category,
                prefixIcon: Icons.category_outlined,
                items: const [
                  'vehicle_ice',
                  'vehicle_ev',
                  'spare_parts',
                  'accessories',
                  'service_labor',
                  'documentation',
                  'other',
                ],
                itemLabel: (val) {
                  switch (val) {
                    case 'vehicle_ice': return 'Petrol Vehicle (ICE)';
                    case 'vehicle_ev': return 'Electric Vehicle (EV)';
                    case 'spare_parts': return 'Spare Parts';
                    case 'accessories': return 'Accessories & Riding Gear';
                    case 'service_labor': return 'Workshop Labor';
                    case 'documentation': return 'Documentation & Facilitation';
                    case 'other': return 'Other';
                    default: return val;
                  }
                },
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total GST % (CGST & SGST will be split 50:50)',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description / Notes'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(
          label: isEdit ? 'Update Slab' : 'Save Slab',
          onPressed: () {
            final rateVal = double.tryParse(_rateController.text) ?? 28.0;
            final entity = GstRateEntity.standard(
              id: widget.existingRate?.id ?? 'rate-${DateTime.now().millisecondsSinceEpoch}',
              taxName: _nameController.text.trim(),
              hsnSacCode: _hsnController.text.trim(),
              totalGstRate: rateVal,
              category: _category,
              description: _descController.text.trim(),
              effectiveFrom: widget.existingRate?.effectiveFrom ?? DateTime.now(),
            );
            widget.cubit.saveRate(entity);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
