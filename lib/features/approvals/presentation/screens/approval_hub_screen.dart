import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../common/widgets/responsive_field_row.dart';
import '../../../../common/widgets/app_dropdown.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/approval_request_entity.dart';
import '../cubit/approval_list_cubit.dart';
import '../cubit/approval_list_state.dart';
import '../cubit/approval_rules_cubit.dart';
import '../cubit/approval_rules_state.dart';
import '../widgets/approval_decision_dialog.dart';
import '../widgets/approval_detail_modal.dart';
import '../widgets/approval_request_card.dart';
import '../widgets/approval_rules_table.dart';

class ApprovalHubScreen extends StatelessWidget {
  const ApprovalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ApprovalListCubit()..loadRequests()),
        BlocProvider(create: (_) => ApprovalRulesCubit()..loadRules()),
      ],
      child: const _ApprovalHubView(),
    );
  }
}

class _ApprovalHubView extends StatefulWidget {
  const _ApprovalHubView();

  @override
  State<_ApprovalHubView> createState() => _ApprovalHubViewState();
}

class _ApprovalHubViewState extends State<_ApprovalHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _types = [
    {'value': 'all', 'label': 'All Types'},
    {'value': 'expense', 'label': 'Expense'},
    {'value': 'discount', 'label': 'Discount'},
    {'value': 'purchase', 'label': 'Purchase'},
    {'value': 'payment', 'label': 'Payment'},
    {'value': 'stock_adjustment', 'label': 'Stock Adj.'},
    {'value': 'stock_transfer', 'label': 'Stock Transfer'},
  ];

  final List<Map<String, String>> _urgencies = [
    {'value': 'all', 'label': 'All Urgencies'},
    {'value': 'critical', 'label': 'Critical'},
    {'value': 'high', 'label': 'High'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'low', 'label': 'Low'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          // Pending tab
          context.read<ApprovalListCubit>().setStatus('pending');
        } else if (_tabController.index == 1) {
          // All tab
          context.read<ApprovalListCubit>().setStatus('all');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openDetailModal(BuildContext context, ApprovalRequestEntity request) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ApprovalDetailModal(
        request: request,
        onDecision: (decision, notes, reason) {
          final cubit = context.read<ApprovalListCubit>();
          if (decision == ApprovalDecisionType.approve) {
            cubit.approveRequest(
              request.id,
              approverName: 'Manager User',
              notes: notes,
            );
          } else {
            cubit.rejectRequest(
              request.id,
              approverName: 'Manager User',
              reason: reason ?? 'Rejected by management',
            );
          }
        },
      ),
    );
  }

  void _openDecisionDialog(
    BuildContext context,
    ApprovalRequestEntity request,
    ApprovalDecisionType type,
  ) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => ApprovalDecisionDialog(
        request: request,
        initialType: type,
      ),
    );

    if (res != null && context.mounted) {
      final decision = res['decision'] as ApprovalDecisionType;
      final notes = res['notes'] as String?;
      final reason = res['reason'] as String?;
      final cubit = context.read<ApprovalListCubit>();

      if (decision == ApprovalDecisionType.approve) {
        cubit.approveRequest(
          request.id,
          approverName: 'Manager User',
          notes: notes,
        );
      } else {
        cubit.rejectRequest(
          request.id,
          approverName: 'Manager User',
          reason: reason ?? 'Rejected by manager',
        );
      }
    }
  }

  void _showNewRequestDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'Spare Parts Bulk Purchase');
    final amountCtrl = TextEditingController(text: '75000');
    final descCtrl = TextEditingController(text: 'Restock brake pads and oil filters for workshop demand.');
    String selectedType = 'purchase';
    String selectedUrgency = 'high';
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Approval Request',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  ResponsiveFieldRow(
                    spacing: AppDimensions.spacingSm,
                    children: [
                      AppDropdown<String>(
                        label: 'Type',
                        value: selectedType,
                        items: const [
                          'expense',
                          'discount',
                          'purchase',
                          'payment',
                          'stock_adjustment',
                          'stock_transfer',
                        ],
                        itemLabel: (val) {
                          switch (val) {
                            case 'expense': return 'Expense';
                            case 'discount': return 'Discount';
                            case 'purchase': return 'Purchase';
                            case 'payment': return 'Payment';
                            case 'stock_adjustment': return 'Stock Adjustment';
                            case 'stock_transfer': return 'Stock Transfer';
                            default: return val;
                          }
                        },
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedType = val);
                        },
                      ),
                      AppDropdown<String>(
                        label: 'Urgency',
                        value: selectedUrgency,
                        items: const [
                          'low',
                          'normal',
                          'high',
                          'critical',
                        ],
                        itemLabel: (val) {
                          switch (val) {
                            case 'low': return 'Low';
                            case 'normal': return 'Normal';
                            case 'high': return 'High';
                            case 'critical': return 'Critical';
                            default: return val;
                          }
                        },
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedUrgency = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Request Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Justification / Remarks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellowDark,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text.trim());
                          context.read<ApprovalListCubit>().submitRequest(
                                transactionType: selectedType,
                                recordId: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                recordReference: 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                amount: amount,
                                requesterName: 'Staff Member',
                                requesterRole: 'Store Executive',
                                showroomId: 'sh-01',
                                showroomName: 'Downtown Flagship',
                                urgency: selectedUrgency,
                                payload: {
                                  'type': selectedType,
                                  'amount': amount,
                                  'timestamp': DateTime.now().toIso8601String(),
                                },
                              );
                          Navigator.of(dialogCtx).pop();
                        },
                        child: const Text('Submit Request'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocConsumer<ApprovalListCubit, ApprovalListState>(
      listener: (context, state) {
        if (state is ApprovalListLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ApprovalListCubit>().clearSuccessMessage();
        } else if (state is ApprovalListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        int pendingCount = 0;
        int approvedCount = 0;
        int rejectedCount = 0;
        String selectedType = 'all';
        String selectedUrgency = 'all';

        if (state is ApprovalListLoaded) {
          pendingCount = state.pendingCount;
          approvedCount = state.approvedCount;
          rejectedCount = state.rejectedCount;
          selectedType = state.criteria.transactionType ?? 'all';
          selectedUrgency = state.criteria.urgency ?? 'all';
        }

        return AppScaffold(
          onRefresh: () async { await Future.wait([context.read<ApprovalListCubit>().loadRequests(), context.read<ApprovalRulesCubit>().loadRules()]); },
          title: 'Approval Workflow',
          activeNavigationId: 'approvals',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showNewRequestDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellowDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing20),

                // KPI summary cards
                _buildKpiRow(context, pendingCount, approvedCount, rejectedCount),
                const SizedBox(height: AppDimensions.spacing20),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryYellowDark,
                  unselectedLabelColor: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  indicatorColor: AppColors.primaryYellow,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.hourglass_top_rounded, size: 16),
                      text: 'Pending Approvals ($pendingCount)',
                    ),
                    const Tab(
                      icon: Icon(Icons.list_alt_rounded, size: 16),
                      text: 'All Requests',
                    ),
                    const Tab(
                      icon: Icon(Icons.policy_outlined, size: 16),
                      text: 'Policy Thresholds',
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),

                // Tab Content Area
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 0: Pending Requests
                      _buildRequestsTab(
                        context,
                        state,
                        selectedType: selectedType,
                        selectedUrgency: selectedUrgency,
                        isPendingOnly: true,
                      ),

                      // Tab 1: All Requests
                      _buildRequestsTab(
                        context,
                        state,
                        selectedType: selectedType,
                        selectedUrgency: selectedUrgency,
                        isPendingOnly: false,
                      ),

                      // Tab 2: Policy Thresholds
                      const ApprovalRulesTable(),
                    ],
                  ),
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
    final isMobile = context.isMobile;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: const Icon(Icons.verified_user_outlined, color: AppColors.primaryYellowDark, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dealership Transaction Approvals',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              Text(
                'Multi-level authorization for expenses, discounts, purchases, stock adjustments, and transfers',
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(
    BuildContext context,
    int pendingCount,
    int approvedCount,
    int rejectedCount,
  ) {
    final isMobile = context.isMobile;

    return BlocBuilder<ApprovalRulesCubit, ApprovalRulesState>(
      builder: (context, rulesState) {
        final activeRulesCount = rulesState is ApprovalRulesLoaded
            ? rulesState.rules.where((r) => r.isActive).length
            : 6;

        final cards = [
          _buildKpiCard(
            title: 'Pending Approvals',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
            subtext: 'Requires manager action',
          ),
          _buildKpiCard(
            title: 'Approved Transactions',
            value: '$approvedCount',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            subtext: 'Authorized & processed',
          ),
          _buildKpiCard(
            title: 'Rejected Transactions',
            value: '$rejectedCount',
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            subtext: 'Turned down with audit reason',
          ),
          _buildKpiCard(
            title: 'Active Approval Policies',
            value: '$activeRulesCount',
            icon: Icons.policy_outlined,
            color: AppColors.primaryYellowDark,
            subtext: 'Configured threshold triggers',
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
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(child: cards[1]),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(child: cards[2]),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(
    BuildContext context,
    ApprovalListState state, {
    required String selectedType,
    required String selectedUrgency,
    required bool isPendingOnly,
  }) {
    return Column(
      children: [
        // Filter row
        _buildFiltersBar(
          context,
          selectedType: selectedType,
          selectedUrgency: selectedUrgency,
        ),
        const SizedBox(height: AppDimensions.spacing16),

        // List
        Expanded(
          child: _buildRequestsList(context, state, isPendingOnly: isPendingOnly),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(
    BuildContext context, {
    required String selectedType,
    required String selectedUrgency,
  }) {
    final isDark = context.isDarkMode;

    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by reference, record ID, or requester...',
                hintStyle: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ApprovalListCubit>().setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              onChanged: (val) {
                context.read<ApprovalListCubit>().setSearch(val);
              },
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),

        // Type Filter Dropdown
        SizedBox(
          width: 170,
          child: AppDropdown<String>(
            isDense: true,
            value: selectedType,
            items: _types.map((t) => t['value']!).toList(),
            itemLabel: (val) => _types.firstWhere((t) => t['value'] == val)['label']!,
            onChanged: (val) {
              if (val != null) {
                context.read<ApprovalListCubit>().setTransactionType(val);
              }
            },
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),

        // Urgency Filter Dropdown
        SizedBox(
          width: 150,
          child: AppDropdown<String>(
            isDense: true,
            value: selectedUrgency,
            items: _urgencies.map((u) => u['value']!).toList(),
            itemLabel: (val) => _urgencies.firstWhere((u) => u['value'] == val)['label']!,
            onChanged: (val) {
              if (val != null) {
                context.read<ApprovalListCubit>().setUrgency(val);
              }
            },
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),

        // Reset Filters Button
        IconButton(
          tooltip: 'Reset Filters',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            _searchController.clear();
            context.read<ApprovalListCubit>().loadRequests();
          },
        ),
      ],
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    ApprovalListState state, {
    required bool isPendingOnly,
  }) {
    final isDark = context.isDarkMode;

    if (state is ApprovalListLoading) {
      return AppSkeleton.list(kpis: 4, rows: 6);
    }

    if (state is ApprovalListLoaded) {
      final requests = isPendingOnly
          ? state.requests.where((r) => r.isPending).toList()
          : state.requests;

      if (requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPendingOnly ? Icons.check_circle_outline : Icons.inbox_outlined,
                size: 56,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(height: 12),
              Text(
                isPendingOnly
                    ? 'All transactions authorized! No pending approvals.'
                    : 'No approval requests found matching current filters.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return ApprovalRequestCard(
            request: req,
            onTap: () => _openDetailModal(context, req),
            onApprove: () => _openDecisionDialog(context, req, ApprovalDecisionType.approve),
            onReject: () => _openDecisionDialog(context, req, ApprovalDecisionType.reject),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
