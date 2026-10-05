import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/audit_filter_criteria.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../cubit/audit_log_cubit.dart';
import '../cubit/audit_log_state.dart';
import '../widgets/audit_diff_modal.dart';
import '../widgets/audit_log_row.dart';

class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditLogCubit()..loadLogs(),
      child: const _AuditTrailView(),
    );
  }
}

class _AuditTrailView extends StatefulWidget {
  const _AuditTrailView();

  @override
  State<_AuditTrailView> createState() => _AuditTrailViewState();
}

class _AuditTrailViewState extends State<_AuditTrailView> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _modules = [
    {'value': 'all', 'label': 'All Modules'},
    {'value': 'sales', 'label': 'Sales & Invoices'},
    {'value': 'inventory', 'label': 'Inventory & Stock'},
    {'value': 'finance', 'label': 'Finance & Vouchers'},
    {'value': 'accounting', 'label': 'Accounting & Ledger'},
    {'value': 'customers', 'label': 'Customers & Leads'},
    {'value': 'documents', 'label': 'Document DMS'},
    {'value': 'vehicles', 'label': 'Vehicle Master'},
    {'value': 'showrooms', 'label': 'Showrooms'},
    {'value': 'users', 'label': 'Users & Roles'},
    {'value': 'auth', 'label': 'Authentication'},
  ];

  final List<Map<String, String>> _actions = [
    {'value': 'all', 'label': 'All Actions'},
    {'value': 'CREATE', 'label': 'Create'},
    {'value': 'UPDATE', 'label': 'Update'},
    {'value': 'DELETE', 'label': 'Delete'},
    {'value': 'VERIFY', 'label': 'Verify'},
    {'value': 'REJECT', 'label': 'Reject'},
    {'value': 'STATUS_CHANGE', 'label': 'Status Change'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDiffModal(BuildContext context, AuditLogEntity log) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AuditDiffModal(log: log),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final csv = await context.read<AuditLogCubit>().exportCsv();
    if (csv.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audit log CSV exported successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuditLogCubit, AuditLogState>(
      listener: (context, state) {
        if (state is AuditLogError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        Map<String, dynamic> metrics = {
          'total': 0,
          'today': 0,
          'critical': 0,
          'uniqueUsers': 0,
        };
        String selectedModule = 'all';
        String selectedAction = 'all';
        String selectedSeverity = 'all';

        if (state is AuditLogLoaded) {
          metrics = state.metrics;
          selectedModule = state.criteria.module ?? 'all';
          selectedAction = state.criteria.action ?? 'all';
          selectedSeverity = state.criteria.severity ?? 'all';
        }

        return AppScaffold(
          onRefresh: () => context.read<AuditLogCubit>().loadLogs(),
          title: 'Audit Trail & Compliance',
          activeNavigationId: 'audit-logs',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _handleExport(context),
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing20),

                // Metrics KPI Row
                _buildKpiRow(context, metrics),
                const SizedBox(height: AppDimensions.spacing20),

                // Filters & Search Bar
                _buildControlsBar(
                  context,
                  selectedModule: selectedModule,
                  selectedAction: selectedAction,
                  selectedSeverity: selectedSeverity,
                ),
                const SizedBox(height: AppDimensions.spacing16),

                // Main Audit Log List
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: const Icon(Icons.history_rounded, color: AppColors.primaryYellowDark, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enterprise Audit Trail & Compliance Log',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 18 : null,
                ),
              ),
              Text(
                'Immutable ledger of user actions, module operations, before/after record diffs, and security events',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(BuildContext context, Map<String, dynamic> metrics) {
    final isMobile = context.isMobile;

    final cards = [
      _buildMetricCard(
        context,
        title: 'Total Logged Events',
        value: '${metrics['total'] ?? 0}',
        icon: Icons.receipt_long_rounded,
        color: AppColors.primaryYellowDark,
      ),
      _buildMetricCard(
        context,
        title: 'Actions Today',
        value: '${metrics['today'] ?? 0}',
        icon: Icons.today_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _buildMetricCard(
        context,
        title: 'Critical Operations',
        value: '${metrics['critical'] ?? 0}',
        icon: Icons.warning_amber_rounded,
        color: AppColors.error,
        isHighlight: (metrics['critical'] ?? 0) > 0,
      ),
      _buildMetricCard(
        context,
        title: 'Active Operators',
        value: '${metrics['uniqueUsers'] ?? 0}',
        icon: Icons.people_outline_rounded,
        color: AppColors.success,
      ),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - AppDimensions.spacing12) / 2;
          return Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing12,
            children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[1]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[2]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMedium.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(
    BuildContext context, {
    required String selectedModule,
    required String selectedAction,
    required String selectedSeverity,
  }) {
    final isDark = context.isDarkMode;
    final isMobile = context.isMobile;

    final searchField = TextField(
      controller: _searchController,
      style: TextStyle(
        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      ),
      decoration: InputDecoration(
        hintText: 'Search audit logs by operator, record ID, action, or module...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<AuditLogCubit>().setSearch('');
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (val) {
        context.read<AuditLogCubit>().setSearch(val);
      },
    );

    final moduleDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedModule,
          isExpanded: isMobile,
          icon: const Icon(Icons.folder_open_outlined, size: 16),
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          items: _modules.map((m) {
            return DropdownMenuItem(value: m['value'], child: Text(m['label']!));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              context.read<AuditLogCubit>().setModule(val);
            }
          },
        ),
      ),
    );

    final severityFilter = FilterChip(
      label: const Text('Critical Only'),
      selected: selectedSeverity == 'critical',
      selectedColor: AppColors.error.withValues(alpha: 0.2),
      labelStyle: AppTypography.captionMedium.copyWith(
        fontWeight: selectedSeverity == 'critical' ? FontWeight.bold : FontWeight.normal,
        color: selectedSeverity == 'critical' ? AppColors.error : null,
      ),
      onSelected: (selected) {
        context.read<AuditLogCubit>().setSeverity(selected ? 'critical' : 'all');
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          searchField,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: moduleDropdown),
              const SizedBox(width: 10),
              severityFilter,
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: searchField,
              ),
              const SizedBox(width: 12),
              moduleDropdown,
              const SizedBox(width: 12),
              severityFilter,
            ],
          ),
        ],
        const SizedBox(height: 12),

        // Action Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _actions.map((act) {
              final isSelected = selectedAction == act['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(act['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primaryYellow,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: AppTypography.captionMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.black87
                        : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<AuditLogCubit>().setAction(act['value']!);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AuditLogState state) {
    final isDark = context.isDarkMode;

    if (state is AuditLogLoading) {
      return AppSkeleton.table(kpis: 4, rows: 8, columns: 5);
    }

    if (state is AuditLogError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(state.message, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AuditLogCubit>().loadLogs(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is AuditLogLoaded) {
      if (state.logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_toggle_off_rounded,
                  size: 48,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Audit Logs Found',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No audit events match your selected filters and query.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context.read<AuditLogCubit>().loadLogs(
                        criteria: const AuditFilterCriteria(),
                      );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Filters'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: state.logs.length,
        itemBuilder: (context, index) {
          final log = state.logs[index];
          return AuditLogRow(
            log: log,
            onViewDiff: () => _openDiffModal(context, log),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
