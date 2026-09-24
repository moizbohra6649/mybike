import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/indian_currency_formatter.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/purchase_management_service.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../cubit/purchase_order_list_cubit.dart';
import '../cubit/purchase_order_list_state.dart';

/// Purchase Order List Screen — procurement register with KPIs and filters.
class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  late final PurchaseOrderListCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = PurchaseOrderListCubit()..loadOrders();
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
        activeNavigationId: 'purchases',
        currentShowroomName: 'Procurement',
        title: 'Purchase Orders',
        body: BlocConsumer<PurchaseOrderListCubit, PurchaseOrderListState>(
          listener: (context, state) {
            if (state is PurchaseOrderListError) {
              context.showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is PurchaseOrderListLoading) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            if (state is PurchaseOrderListError) {
              return AppErrorState(
                title: 'Failed to Load Purchase Orders',
                message: state.message,
                onRetry: () => _cubit.loadOrders(refresh: true),
              );
            }

            if (state is PurchaseOrderListLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, PurchaseOrderListLoaded state) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          AppSectionHeader(
            title: 'Purchase Orders',
            countBadge: state.totalCount,
            subtitle:
                'Procurement raised on OEMs and vendors, from draft through goods receipt',
            trailing: AppButton.primary(
              label: 'Create Purchase Order',
              leadingIcon: Icons.add_rounded,
              onPressed: () async {
                await context.pushNamed(RouteNames.purchaseCreate);
                _cubit.loadOrders(refresh: true);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Stat KPI Cards ───
          AppResponsiveGrid(
            minItemWidth: 200,
            children: [
              AppStatCard(
                title: 'Total Orders',
                value: state.totalCount.toString(),
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.primaryYellow,
              ),
              AppStatCard(
                title: 'Open Orders',
                value: state.openCount.toString(),
                icon: Icons.hourglass_empty_rounded,
                iconColor: AppColors.warning,
              ),
              AppStatCard(
                title: 'Awaiting Receipt',
                value: state.receivableCount.toString(),
                icon: Icons.local_shipping_outlined,
                iconColor: AppColors.info,
              ),
              AppStatCard(
                title: 'Order Value',
                value: IndianCurrencyFormatter.formatIndianCurrency(
                  state.totalValue,
                  showSymbol: true,
                ).trim(),
                icon: Icons.currency_rupee_rounded,
                iconColor: AppColors.success,
              ),
              AppStatCard(
                title: 'Payable Balance',
                value: IndianCurrencyFormatter.formatIndianCurrency(
                  state.outstandingPayable,
                  showSymbol: true,
                ).trim(),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Toolbar: Search & Filters ───
          Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search by PO number or vendor...',
                  onChanged: (val) => _cubit.searchOrders(val),
                  onClear: () {
                    _searchController.clear();
                    _cubit.searchOrders('');
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: AppDropdown<String>(
                  hint: 'All Statuses',
                  value: state.statusFilter,
                  items: PurchaseManagementService.statusLabels.keys.toList(),
                  itemLabel: (key) =>
                      PurchaseManagementService.statusLabels[key] ?? key,
                  prefixIcon: Icons.flag_outlined,
                  onChanged: (val) => _cubit.filterByStatus(val),
                ),
              ),
              SizedBox(
                width: 200,
                child: AppDropdown<String>(
                  hint: 'All Categories',
                  value: state.categoryFilter,
                  items: PurchaseManagementService.categories,
                  itemLabel: PurchaseManagementService.categoryLabel,
                  prefixIcon: Icons.category_outlined,
                  onChanged: (val) => _cubit.filterByCategory(val),
                ),
              ),
              if (state.searchQuery != null ||
                  state.statusFilter != null ||
                  state.categoryFilter != null)
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

          // ─── Orders Table ───
          if (state.orders.isEmpty)
            const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Purchase Orders Found',
              description: 'No purchase orders match the current search or filter criteria.',
            )
          else
            AppDataTable<PurchaseOrderEntity>(
              minWidth: 900,
              columns: [
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'PO Number',
                  flex: 3,
                  cellBuilder: (context, order) => _PoNumberCell(order: order),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Vendor',
                  flex: 4,
                  cellBuilder: (context, order) => Text(
                    order.supplierName ?? 'Unknown vendor',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Order Date',
                  flex: 2,
                  cellBuilder: (context, order) =>
                      Text(_formatDate(order.orderDate), style: AppTypography.bodySmall),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Received',
                  flex: 2,
                  isNumeric: true,
                  cellBuilder: (context, order) => Text(
                    '${order.receivedQuantity} / ${order.totalQuantity}',
                    style: AppTypography.bodySmall.copyWith(
                      color: order.isReceivable
                          ? AppColors.warning
                          : (context.isDarkMode
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Total',
                  flex: 3,
                  isNumeric: true,
                  cellBuilder: (context, order) => AppCurrencyText(
                    amount: order.totalAmount,
                    size: AppCurrencySize.small,
                  ),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Status',
                  flex: 2,
                  cellBuilder: (context, order) => AppStatusBadge(
                    label: PurchaseManagementService.statusLabels[order.status] ??
                        order.status,
                    color: _statusColor(order.status),
                  ),
                ),
                AppDataColumn<PurchaseOrderEntity>(
                  title: 'Actions',
                  flex: 2,
                  cellBuilder: (context, order) => _OrderActions(
                    order: order,
                    onView: () async {
                      await context.pushNamed(
                        RouteNames.purchaseDetail,
                        pathParameters: {'purchaseId': order.id},
                      );
                      _cubit.loadOrders(refresh: true);
                    },
                    onEdit: () async {
                      await context.pushNamed(
                        RouteNames.purchaseCreate,
                        queryParameters: {'editId': order.id},
                      );
                      _cubit.loadOrders(refresh: true);
                    },
                    onDelete: () => _confirmDelete(context, order),
                  ),
                ),
              ],
              items: state.orders,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PurchaseOrderEntity order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Purchase Order?',
      message:
          '${order.poNumber} will be removed along with all of its line items. This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await PurchaseManagementService.instance.deletePurchaseOrder(order.id);
        if (!context.mounted) return;
        context.showSuccessSnackBar('${order.poNumber} deleted');
        _cubit.loadOrders(refresh: true);
      } catch (e) {
        if (!context.mounted) return;
        context.showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'received':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'sent':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return const Color(0xFF6B7280);
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _PoNumberCell extends StatelessWidget {
  final PurchaseOrderEntity order;

  const _PoNumberCell({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          order.poNumber,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          PurchaseManagementService.categoryLabel(order.purchaseCategory),
          style: AppTypography.captionSmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
      ],
    );
  }
}

class _OrderActions extends StatelessWidget {
  final PurchaseOrderEntity order;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OrderActions({
    required this.order,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Only an untouched draft can still be edited or deleted.
    final isEditable =
        order.isEditable && PurchaseManagementService.instance.canDelete(order);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'View Purchase Order',
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(6),
            minimumSize: const Size(32, 32),
          ),
          onPressed: onView,
        ),
        if (isEditable) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit Purchase Order',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            tooltip: 'Delete Purchase Order',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}
