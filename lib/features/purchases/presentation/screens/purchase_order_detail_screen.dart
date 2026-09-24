import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/purchase_management_service.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/entities/purchase_order_item_entity.dart';

/// Purchase Order Detail Screen — the order as issued to the vendor, its line
/// items, goods receipt and status transitions.
///
/// Receiving records how much of each line arrived. Vehicle lines are inwarded
/// into stock from Inventory → Stock Inward, where the VIN, engine and battery
/// serial numbers are captured per unit.
class PurchaseOrderDetailScreen extends StatefulWidget {
  final String purchaseId;

  const PurchaseOrderDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  final _service = PurchaseManagementService.instance;

  PurchaseOrderEntity? _order;
  bool _isLoading = true;
  bool _isWorking = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final order = await _service.fetchPurchaseOrderById(widget.purchaseId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
        _loadError = order == null ? 'This purchase order no longer exists.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendToVendor() async {
    final order = _order!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Send to Vendor?',
      message:
          '${order.poNumber} will be marked as sent and become receivable against delivery.',
      confirmText: 'Send',
    );
    if (confirmed != true) return;

    await _run(() => _service.updateStatus(order.id, 'sent'),
        success: '${order.poNumber} sent to vendor');
  }

  Future<void> _cancelOrder() async {
    final order = _order!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cancel Purchase Order?',
      message:
          '${order.poNumber} will be cancelled. Lines already received stay in the record.',
      confirmText: 'Cancel Order',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await _run(() => _service.updateStatus(order.id, 'cancelled'),
        success: '${order.poNumber} cancelled');
  }

  Future<void> _receiveGoods() async {
    final order = _order!;
    final received = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _ReceiveDialog(order: order),
    );
    if (received == null || received.isEmpty) return;

    await _run(
      () => _service.receivePurchaseOrder(order.id, received),
      success: 'Goods receipt recorded against ${order.poNumber}',
    );
  }

  Future<void> _run(Future<void> Function() action, {required String success}) async {
    setState(() => _isWorking = true);
    try {
      await action();
      if (!mounted) return;
      setState(() => _isWorking = false);
      context.showSuccessSnackBar(success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      context.showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return AppScaffold(
      activeNavigationId: 'purchases',
      currentShowroomName: 'Procurement',
      title: order?.poNumber ?? 'Purchase Order',
      actions: [
        if (order != null && !_isWorking) ...[
          if (order.isEditable) ...[
            AppButton.ghost(
              label: 'Edit',
              leadingIcon: Icons.edit_outlined,
              onPressed: () async {
                await context.pushNamed(
                  RouteNames.purchaseCreate,
                  queryParameters: {'editId': order.id},
                );
                _load();
              },
            ),
            const SizedBox(width: AppDimensions.spacing8),
            AppButton.secondary(
              label: 'Send to Vendor',
              leadingIcon: Icons.send_rounded,
              onPressed: _sendToVendor,
            ),
            const SizedBox(width: AppDimensions.spacing8),
          ],
          if (order.isReceivable) ...[
            AppButton.primary(
              label: 'Receive Goods',
              leadingIcon: Icons.inventory_rounded,
              onPressed: _receiveGoods,
            ),
            const SizedBox(width: AppDimensions.spacing8),
          ],
          if (order.status != 'cancelled' && order.status != 'received')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              tooltip: 'Cancel Purchase Order',
              onPressed: _cancelOrder,
            ),
        ],
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return AppSkeleton.form(sections: 3, fields: 2);

    if (_loadError != null) {
      return AppErrorState(
        title: 'Failed to Load Purchase Order',
        message: _loadError!,
        onRetry: _load,
      );
    }

    if (_isWorking) {
      return const AppPageLoader(message: 'Updating purchase order...');
    }

    final order = _order!;
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Order Summary ───
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.poNumber,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.primaryYellowLight
                            : AppColors.primaryYellowDark,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    AppStatusBadge(
                      label: PurchaseManagementService.statusLabels[order.status] ??
                          order.status,
                      color: _statusColor(order.status),
                    ),
                    const Spacer(),
                    AppStatusBadge(
                      label: PurchaseManagementService.categoryLabel(
                        order.purchaseCategory,
                      ),
                      color: AppColors.info,
                      icon: Icons.category_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                Text(
                  order.supplierName ?? 'Unknown vendor',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                Wrap(
                  spacing: AppDimensions.spacing24,
                  runSpacing: AppDimensions.spacing12,
                  children: [
                    _MetaItem(
                      icon: Icons.event_outlined,
                      label: 'Order Date',
                      value: _formatDate(order.orderDate),
                    ),
                    _MetaItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Expected Delivery',
                      value: order.expectedDeliveryDate == null
                          ? 'Not set'
                          : _formatDate(order.expectedDeliveryDate!),
                    ),
                    _MetaItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Received',
                      value: '${order.receivedQuantity} of ${order.totalQuantity} units',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Line Items ───
          AppSectionHeader(
            title: 'Line Items',
            countBadge: order.itemCount,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          if (order.items.isEmpty)
            const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Line Items',
              description: 'This purchase order has no line items recorded.',
            )
          else
            AppDataTable<PurchaseOrderItemEntity>(
              minWidth: 760,
              columns: [
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: '#',
                  width: 40,
                  cellBuilder: (context, item) =>
                      Text(item.lineNumber.toString(), style: AppTypography.bodySmall),
                ),
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: 'Description',
                  flex: 5,
                  cellBuilder: (context, item) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.description,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        PurchaseManagementService.categoryLabel(item.itemType),
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.darkMutedText
                              : AppColors.lightMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: 'Qty',
                  flex: 1,
                  isNumeric: true,
                  cellBuilder: (context, item) => Text(
                    '${item.receivedQuantity}/${item.quantity}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.isFullyReceived
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: 'Unit Price',
                  flex: 2,
                  isNumeric: true,
                  cellBuilder: (context, item) => AppCurrencyText(
                    amount: item.unitPrice,
                    size: AppCurrencySize.small,
                  ),
                ),
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: 'GST',
                  flex: 1,
                  isNumeric: true,
                  cellBuilder: (context, item) =>
                      Text('${item.taxRate}%', style: AppTypography.bodySmall),
                ),
                AppDataColumn<PurchaseOrderItemEntity>(
                  title: 'Total',
                  flex: 3,
                  isNumeric: true,
                  cellBuilder: (context, item) => AppCurrencyText(
                    amount: item.totalAmount,
                    size: AppCurrencySize.small,
                  ),
                ),
              ],
              items: order.items,
            ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Totals ───
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            child: Column(
              children: [
                _totalLine(context, 'Taxable Value', order.subtotal),
                _totalLine(context, 'GST', order.taxAmount),
                _totalLine(context, 'Other Charges', order.otherCharges),
                const Divider(height: AppDimensions.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order Total',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    AppCurrencyText(
                      amount: order.totalAmount,
                      size: AppCurrencySize.large,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing8),
                _totalLine(context, 'Paid', order.paidAmount),
                _totalLine(
                  context,
                  'Balance Payable',
                  order.balanceAmount,
                  emphasise: true,
                ),
              ],
            ),
          ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing20),
            AppFormSection(
              title: 'Internal Notes',
              children: [Text(order.notes!, style: AppTypography.bodyMedium)],
            ),
          ],

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _totalLine(
    BuildContext context,
    String label,
    double amount, {
    bool emphasise = false,
  }) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: emphasise ? FontWeight.w700 : FontWeight.w400,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ),
          AppCurrencyText(amount: amount, size: AppCurrencySize.small),
        ],
      ),
    );
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Collects the quantity received per outstanding line.
class _ReceiveDialog extends StatefulWidget {
  final PurchaseOrderEntity order;

  const _ReceiveDialog({required this.order});

  @override
  State<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<_ReceiveDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      if (item.isFullyReceived) continue;
      _controllers[item.id] =
          TextEditingController(text: item.pendingQuantity.toString());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingItems =
        widget.order.items.where((i) => !i.isFullyReceived).toList();

    return AlertDialog(
      title: Text('Receive Goods — ${widget.order.poNumber}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the quantity that arrived against each line.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppDimensions.spacing16),
              for (final item in pendingItems) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.description,
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.pendingQuantity} pending',
                            style: AppTypography.captionSmall.copyWith(
                              color: context.isDarkMode
                                  ? AppColors.darkMutedText
                                  : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                    SizedBox(
                      width: 100,
                      child: AppTextField(
                        controller: _controllers[item.id],
                        keyboardType: TextInputType.number,
                        hint: '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing12),
              ],
              if (widget.order.items.any((i) => i.isVehicleLine))
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: AppDimensions.spacing8),
                      Expanded(
                        child: Text(
                          'Vehicle lines are inwarded into stock from Inventory → Stock Inward, where each unit\'s VIN is captured.',
                          style: AppTypography.captionSmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Record Receipt',
          leadingIcon: Icons.check_rounded,
          onPressed: () {
            final received = <String, int>{};
            for (final entry in _controllers.entries) {
              final qty = int.tryParse(entry.value.text.trim()) ?? 0;
              if (qty > 0) received[entry.key] = qty;
            }
            Navigator.of(context).pop(received);
          },
        ),
      ],
    );
  }
}
