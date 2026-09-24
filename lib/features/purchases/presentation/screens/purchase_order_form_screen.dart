import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/purchase_management_service.dart';
import '../../../../core/services/supplier_management_service.dart';
import '../../../../core/services/showroom_service.dart';
import '../../../suppliers/domain/entities/supplier_entity.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/entities/purchase_order_item_entity.dart';

/// Purchase Order Create / Edit Form Screen
///
/// Header fields plus a line-item editor. Saves go through
/// [PurchaseManagementService], which recomputes the header totals from the
/// lines, so the form never sends stale amounts.
///
/// Line items carry a free-text description and an item type. The
/// `variant_id` / `color_id` columns on `purchase_order_items` stay null until
/// vehicle lines are linked to the vehicle master catalogue.
class PurchaseOrderFormScreen extends StatefulWidget {
  final String? editPurchaseId;

  const PurchaseOrderFormScreen({super.key, this.editPurchaseId});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _service = PurchaseManagementService.instance;
  final _formKey = GlobalKey<FormState>();

  final _poNumberController = TextEditingController();
  final _otherChargesController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<SupplierEntity> _suppliers = [];
  String? _supplierId;
  String _category = 'spare_part';
  DateTime _orderDate = DateTime.now();
  DateTime? _expectedDate;
  final List<_ItemDraft> _items = [];

  PurchaseOrderEntity? _existing;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  bool get isEditMode => widget.editPurchaseId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poNumberController.dispose();
    _otherChargesController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Inactive vendors are included on purpose: an order raised on a vendor
      // that has since been deactivated must still resolve its supplier when
      // the order is reopened for edit.
      final suppliers = await SupplierManagementService.instance.fetchSuppliers();
      if (!mounted) return;

      if (suppliers.isEmpty) {
        setState(() {
          _isLoading = false;
          _loadError = 'Add at least one supplier before raising a purchase order.';
        });
        return;
      }

      _suppliers = suppliers;

      if (isEditMode) {
        final order = await _service.fetchPurchaseOrderById(widget.editPurchaseId!);
        if (!mounted) return;

        if (order == null) {
          setState(() {
            _isLoading = false;
            _loadError = 'This purchase order no longer exists.';
          });
          return;
        }

        _existing = order;
        _applyOrder(order);
      } else {
        _supplierId = _suppliers.first.id;
        _poNumberController.text = await _service.generatePoNumber();
        _items.add(_ItemDraft());
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyOrder(PurchaseOrderEntity order) {
    _poNumberController.text = order.poNumber;
    _supplierId = order.supplierId;
    _category = order.purchaseCategory;
    _orderDate = order.orderDate;
    _expectedDate = order.expectedDeliveryDate;
    _otherChargesController.text = _plainAmount(order.otherCharges);
    _notesController.text = order.notes ?? '';

    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(order.items.map(_ItemDraft.fromEntity));

    if (_items.isEmpty) _items.add(_ItemDraft());
  }

  double get _subtotal =>
      _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get _taxTotal =>
      _items.fold<double>(0, (sum, item) => sum + item.taxAmount);

  double get _otherCharges =>
      double.tryParse(_otherChargesController.text.replaceAll(',', '').trim()) ?? 0;

  double get _grandTotal => _subtotal + _taxTotal + _otherCharges;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      activeNavigationId: 'purchases',
      currentShowroomName: 'Procurement',
      title: isEditMode ? 'Edit Purchase Order' : 'Create Purchase Order',
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          leadingIcon: Icons.close_rounded,
          onPressed: () => context.pop(),
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return AppSkeleton.form(sections: 3, fields: 3);

    if (_loadError != null) {
      return AppErrorState(
        title: 'Cannot Open Purchase Order',
        message: _loadError!,
        onRetry: _load,
      );
    }

    if (_isSaving) {
      return const AppPageLoader(message: 'Saving purchase order...');
    }

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1: Order Header ───
            AppFormSection(
              title: 'Order Details',
              subtitle: 'Vendor, procurement category and expected delivery',
              children: [
                ResponsiveFieldRow(
                  children: [
                    AppDropdown<SupplierEntity>(
                      label: 'Supplier',
                      value: _supplierById(_supplierId),
                      isRequired: true,
                      items: _suppliers,
                      itemLabel: (s) => s.isActive ? s.name : '${s.name} (inactive)',
                      prefixIcon: Icons.local_shipping_outlined,
                      onChanged: (val) => setState(() => _supplierId = val?.id),
                    ),
                    AppTextField(
                      controller: _poNumberController,
                      label: 'PO Number',
                      hint: 'Auto-generated',
                      isRequired: true,
                      // Read-only, not disabled: the number is generated, but
                      // it is real data on a required field, so it must stay
                      // legible and copyable rather than render greyed out.
                      readOnly: true,
                      prefixIcon: Icons.tag_rounded,
                    ),
                    AppDropdown<String>(
                      label: 'Category',
                      value: _category,
                      isRequired: true,
                      items: PurchaseManagementService.categories,
                      itemLabel: PurchaseManagementService.categoryLabel,
                      prefixIcon: Icons.category_outlined,
                      onChanged: (val) =>
                          setState(() => _category = val ?? 'spare_part'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                ResponsiveFieldRow(
                  children: [
                    AppDatePicker(
                      label: 'Order Date',
                      value: _orderDate,
                      isRequired: true,
                      isClearable: false,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _orderDate = val;
                          // A delivery expected before the order was raised
                          // makes no sense, and AppDatePicker passes this
                          // value as firstDate — an earlier expected date
                          // would trip showDatePicker's range assertion when
                          // the field is next opened. Drop it instead.
                          if (_expectedDate != null &&
                              _expectedDate!.isBefore(val)) {
                            _expectedDate = null;
                          }
                        });
                      },
                    ),
                    AppDatePicker(
                      label: 'Expected Delivery',
                      hint: 'Optional',
                      value: _expectedDate,
                      firstDate: _orderDate,
                      onChanged: (val) => setState(() => _expectedDate = val),
                    ),
                    AppTextField(
                      controller: _otherChargesController,
                      label: 'Other Charges',
                      hint: 'Freight, octroi, etc.',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.local_shipping_outlined,
                      onChanged: (_) => setState(() {}),
                      validator: _amountValidator,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Section 2: Line Items ───
            AppFormSection(
              title: 'Line Items',
              subtitle: 'What is being procured — parts, accessories or vehicles',
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDimensions.spacing16),
                  _buildItemRow(i),
                ],
                const SizedBox(height: AppDimensions.spacing16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppOutlinedButton(
                    label: 'Add Line Item',
                    leadingIcon: Icons.add_rounded,
                    onPressed: () => setState(() => _items.add(_ItemDraft())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Section 3: Notes & Totals ───
            AppFormSection(
              title: 'Notes & Order Value',
              subtitle: 'Totals are computed from the line items on save',
              children: [
                AppTextField(
                  controller: _notesController,
                  label: 'Internal Notes',
                  hint: 'Delivery instructions, approval remarks...',
                  maxLines: 3,
                  prefixIcon: Icons.sticky_note_2_outlined,
                ),
                const SizedBox(height: AppDimensions.spacing16),
                _TotalsCard(
                  subtotal: _subtotal,
                  taxTotal: _taxTotal,
                  otherCharges: _otherCharges,
                  grandTotal: _grandTotal,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing32),

            // ─── Actions ───
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(label: 'Cancel', onPressed: () => context.pop()),
                const SizedBox(width: AppDimensions.spacing12),
                AppButton.primary(
                  label: isEditMode ? 'Update Purchase Order' : 'Create Purchase Order',
                  leadingIcon: Icons.save_rounded,
                  onPressed: _submitForm,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Line ${index + 1}',
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (item.receivedQuantity > 0)
                AppStatusBadge(
                  label: '${item.receivedQuantity} received',
                  color: AppColors.success,
                ),
              const SizedBox(width: AppDimensions.spacing8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Remove Line',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
                onPressed: _items.length == 1
                    ? null
                    : () => setState(() {
                          _items.removeAt(index).dispose();
                        }),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          AppTextField(
            controller: item.description,
            label: 'Description',
            hint: 'e.g. Air Filter — Activa 6G',
            isRequired: true,
            prefixIcon: Icons.inventory_2_outlined,
            onChanged: (_) => setState(() {}),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spacing12),
          ResponsiveFieldRow(
            children: [
              AppDropdown<String>(
                label: 'Item Type',
                value: item.itemType,
                items: PurchaseManagementService.categories,
                itemLabel: PurchaseManagementService.categoryLabel,
                onChanged: (val) => setState(() {
                  item.itemType = val ?? 'spare_part';
                  // Vehicle lines carry GST at 28%, parts and accessories at
                  // 18%. EVs are taxed at 5%, but the item type alone cannot
                  // tell an EV from an ICE vehicle — that distinction lives on
                  // the vehicle master, so the rate stays user-editable.
                  item.taxRate.text =
                      item.itemType == 'new_vehicle' ? '28' : '18';
                }),
              ),
              AppTextField(
                controller: item.quantity,
                label: 'Quantity',
                hint: 'e.g. 10',
                isRequired: true,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
                onChanged: (_) => setState(() {}),
                validator: _quantityValidator,
              ),
              AppTextField(
                controller: item.unitPrice,
                label: 'Unit Price',
                hint: 'Exclusive of tax',
                isRequired: true,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee_rounded,
                onChanged: (_) => setState(() {}),
                validator: (val) => _amountValidator(val, isRequired: true),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          ResponsiveFieldRow(
            children: [
              AppTextField(
                controller: item.taxRate,
                label: 'GST Rate (%)',
                hint: 'e.g. 18',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.percent_rounded,
                onChanged: (_) => setState(() {}),
                validator: _amountValidator,
              ),
              AppTextField(
                controller: item.hsnCode,
                label: 'HSN / SAC Code',
                hint: 'Optional',
                prefixIcon: Icons.confirmation_number_outlined,
              ),
              // A computed read-out, not an input — so it is not a field.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Taxable Value',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.isDarkMode
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: AppCurrencyText(
                      amount: item.lineTotal,
                      size: AppCurrencySize.small,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  SupplierEntity? _supplierById(String? id) {
    if (id == null) return null;
    for (final supplier in _suppliers) {
      if (supplier.id == id) return supplier;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final supplierId = _supplierId;
    if (supplierId == null) {
      context.showErrorSnackBar('Select a supplier before saving');
      return;
    }

    // purchase_orders.showroom_id is NOT NULL, so a draft with no branch
    // context would fail the insert. Block it here with a readable message.
    final showroomId = _existing?.showroomId ??
        ShowroomService.instance.activeShowroom?.id;
    if (showroomId == null || showroomId.isEmpty) {
      context.showErrorSnackBar('Select a showroom before raising a purchase order');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final orderId = _existing?.id ?? 'po-${now.microsecondsSinceEpoch}';

    final items = <PurchaseOrderItemEntity>[];
    for (var i = 0; i < _items.length; i++) {
      final draft = _items[i];
      final existingItem = draft.id;

      items.add(PurchaseOrderItemEntity(
        id: existingItem ?? 'poi-$orderId-$i',
        purchaseOrderId: orderId,
        lineNumber: i + 1,
        itemType: draft.itemType,
        variantId: draft.variantId,
        colorId: draft.colorId,
        description: draft.description.text.trim(),
        hsnCode: draft.hsnCode.text.trim().isEmpty
            ? null
            : draft.hsnCode.text.trim(),
        quantity: draft.quantityValue,
        receivedQuantity: draft.receivedQuantity,
        unitPrice: draft.unitPriceValue,
        taxRate: draft.taxRateValue,
        lineTotal: draft.lineTotal,
        createdAt: draft.createdAt ?? now,
      ));
    }

    final entity = PurchaseOrderEntity(
      id: orderId,
      showroomId: showroomId,
      supplierId: supplierId,
      supplierName: _supplierById(supplierId)?.name,
      poNumber: _poNumberController.text.trim(),
      orderDate: _orderDate,
      expectedDeliveryDate: _expectedDate,
      purchaseCategory: _category,
      otherCharges: _otherCharges,
      paidAmount: _existing?.paidAmount ?? 0,
      paymentStatus: _existing?.paymentStatus ?? 'unpaid',
      status: _existing?.status ?? 'draft',
      approvedBy: _existing?.approvedBy,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      items: items,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (isEditMode) {
        await _service.updatePurchaseOrder(entity);
      } else {
        await _service.createPurchaseOrder(entity);
      }
      if (!mounted) return;
      context.showSuccessSnackBar(
        isEditMode
            ? 'Purchase order updated successfully'
            : 'Purchase order created successfully',
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static String _plainAmount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  /// Amounts are optional by default — a blank tax rate or freight charge is
  /// a real 0. Pass [isRequired] for fields that are marked required in the
  /// UI, so the asterisk and the validation agree.
  static String? _amountValidator(String? val, {bool isRequired = false}) {
    final clean = val?.replaceAll(',', '').trim() ?? '';
    if (clean.isEmpty) return isRequired ? 'This field is required' : null;
    final parsed = double.tryParse(clean);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  static String? _quantityValidator(String? val) {
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) return 'Quantity is required';
    final parsed = int.tryParse(clean);
    if (parsed == null) return 'Whole number only';
    if (parsed <= 0) return 'Must be at least 1';
    return null;
  }
}

/// Editable line item, keeping its own controllers alive across rebuilds.
class _ItemDraft {
  final String? id;
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController taxRate;
  final TextEditingController hsnCode;
  String itemType;
  String? variantId;
  String? colorId;
  int receivedQuantity;
  DateTime? createdAt;

  _ItemDraft({
    this.id,
    String description = '',
    String quantity = '1',
    String unitPrice = '0',
    String taxRate = '18',
    String hsnCode = '',
    this.itemType = 'spare_part',
    this.variantId,
    this.colorId,
    this.receivedQuantity = 0,
    this.createdAt,
  })  : description = TextEditingController(text: description),
        quantity = TextEditingController(text: quantity),
        unitPrice = TextEditingController(text: unitPrice),
        taxRate = TextEditingController(text: taxRate),
        hsnCode = TextEditingController(text: hsnCode);

  factory _ItemDraft.fromEntity(PurchaseOrderItemEntity entity) {
    return _ItemDraft(
      id: entity.id,
      description: entity.description,
      quantity: entity.quantity.toString(),
      unitPrice: _trim(entity.unitPrice),
      taxRate: _trim(entity.taxRate),
      hsnCode: entity.hsnCode ?? '',
      itemType: entity.itemType,
      variantId: entity.variantId,
      colorId: entity.colorId,
      receivedQuantity: entity.receivedQuantity,
      createdAt: entity.createdAt,
    );
  }

  int get quantityValue => int.tryParse(quantity.text.trim()) ?? 0;

  double get unitPriceValue =>
      double.tryParse(unitPrice.text.replaceAll(',', '').trim()) ?? 0;

  double get taxRateValue =>
      double.tryParse(taxRate.text.replaceAll(',', '').trim()) ?? 0;

  double get lineTotal => quantityValue * unitPriceValue;

  double get taxAmount => lineTotal * taxRateValue / 100;

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
    taxRate.dispose();
    hsnCode.dispose();
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

/// Subtotal / tax / charges / payable roll-up for the order being edited.
class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double taxTotal;
  final double otherCharges;
  final double grandTotal;

  const _TotalsCard({
    required this.subtotal,
    required this.taxTotal,
    required this.otherCharges,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        children: [
          _line(context, 'Taxable Value', subtotal, isDark),
          _line(context, 'GST', taxTotal, isDark),
          _line(context, 'Other Charges', otherCharges, isDark),
          const Divider(height: AppDimensions.spacing24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Total',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              AppCurrencyText(amount: grandTotal, size: AppCurrencySize.medium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, double amount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          AppCurrencyText(amount: amount, size: AppCurrencySize.small),
        ],
      ),
    );
  }
}
