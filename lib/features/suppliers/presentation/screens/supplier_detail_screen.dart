import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/indian_currency_formatter.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/supplier_management_service.dart';
import '../../domain/entities/supplier_entity.dart';

/// Supplier Detail Screen — read-only vendor master record.
class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final _service = SupplierManagementService.instance;

  SupplierEntity? _supplier;
  bool _isLoading = true;
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
      final supplier = await _service.fetchSupplierById(widget.supplierId);
      if (!mounted) return;
      setState(() {
        _supplier = supplier;
        _isLoading = false;
        _loadError = supplier == null ? 'This supplier no longer exists.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggleStatus() async {
    final supplier = _supplier;
    if (supplier == null) return;

    final newStatus = !supplier.isActive;
    try {
      await _service.toggleSupplierStatus(supplier.id, newStatus);
      if (!mounted) return;
      context.showSuccessSnackBar(
        newStatus ? 'Vendor activated' : 'Vendor deactivated',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplier = _supplier;

    return AppScaffold(
      activeNavigationId: 'suppliers',
      currentShowroomName: 'Procurement',
      title: supplier?.name ?? 'Supplier Details',
      actions: [
        if (supplier != null) ...[
          AppButton.ghost(
            label: supplier.isActive ? 'Deactivate' : 'Activate',
            leadingIcon: supplier.isActive
                ? Icons.toggle_off_outlined
                : Icons.toggle_on_rounded,
            onPressed: _toggleStatus,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          AppButton.primary(
            label: 'Edit',
            leadingIcon: Icons.edit_outlined,
            onPressed: () async {
              await context.pushNamed(
                RouteNames.supplierCreate,
                queryParameters: {'editId': supplier.id},
              );
              _load();
            },
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
        title: 'Failed to Load Supplier',
        message: _loadError!,
        onRetry: _load,
      );
    }

    final s = _supplier!;
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Identity ───
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(
                          color: AppColors.primaryYellow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s.code,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.primaryYellowLight
                              : AppColors.primaryYellowDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    AppStatusBadge.fromStatus(s.isActive ? 'active' : 'inactive'),
                    if (s.isShared) ...[
                      const SizedBox(width: AppDimensions.spacing8),
                      const AppStatusBadge(
                        label: 'All Branches',
                        color: AppColors.info,
                        icon: Icons.hub_outlined,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      SupplierManagementService.typeLabel(s.supplierType),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                Text(
                  s.name,
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Contact ───
          AppFormSection(
            title: 'Contact & Address',
            subtitle: 'Purchase contact and billing address for this vendor',
            children: [
              _DetailRow(label: 'Contact Person', value: s.contactPerson),
              _DetailRow(label: 'Primary Phone', value: s.phone),
              _DetailRow(label: 'Alternate Phone', value: s.alternatePhone),
              _DetailRow(label: 'Email', value: s.email),
              _DetailRow(label: 'Address', value: s.fullAddress),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Commercial Terms ───
          AppFormSection(
            title: 'Commercial Terms',
            subtitle: 'Credit terms applied to purchase orders raised on this vendor',
            children: [
              _DetailRow(label: 'Category', value: SupplierManagementService.typeLabel(s.supplierType)),
              _DetailRow(label: 'Payment Terms', value: 'Net ${s.paymentTermsDays} days'),
              _DetailRow(
                label: 'Credit Limit',
                value: IndianCurrencyFormatter.formatIndianCurrency(s.creditLimit),
              ),
              _DetailRow(
                label: 'Opening Balance Payable',
                value: IndianCurrencyFormatter.formatIndianCurrency(s.openingBalance),
              ),
              _DetailRow(label: 'Branch Scope', value: s.isShared ? 'All branches' : 'Single branch'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Statutory & Banking ───
          AppFormSection(
            title: 'Statutory & Banking',
            subtitle: 'Tax registration and settlement account',
            children: [
              _DetailRow(label: 'GSTIN', value: s.gstin),
              _DetailRow(label: 'PAN', value: s.pan),
              _DetailRow(label: 'Bank Name', value: s.bankName),
              _DetailRow(label: 'Account Number', value: s.bankAccountNumber),
              _DetailRow(label: 'IFSC Code', value: s.bankIfsc),
            ],
          ),

          if (s.notes != null && s.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing20),
            AppFormSection(
              title: 'Internal Notes',
              children: [Text(s.notes!, style: AppTypography.bodyMedium)],
            ),
          ],

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
}

/// A label / value pair that renders an em dash for anything unset.
class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value! : '—',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: hasValue
                    ? (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)
                    : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
