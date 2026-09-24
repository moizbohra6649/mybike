import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/supplier_management_service.dart';
import '../../../../core/services/showroom_management_service.dart';
import '../../domain/entities/supplier_entity.dart';

/// Supplier Create / Edit Form Screen
///
/// Holds its own state rather than a cubit: one record, one save, no list and
/// no filters — the same call the Settings screen makes.
class SupplierFormScreen extends StatefulWidget {
  final String? editSupplierId;

  const SupplierFormScreen({super.key, this.editSupplierId});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _service = SupplierManagementService.instance;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _paymentTermsController = TextEditingController(text: '30');
  final _creditLimitController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  String _supplierType = 'spare_parts';
  String? _selectedState = 'Maharashtra';
  bool _isActive = true;

  /// The record being edited, kept so a save does not re-fetch it.
  SupplierEntity? _existing;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  bool get isEditMode => widget.editSupplierId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) _loadSupplier();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _paymentTermsController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplier() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final supplier = await _service.fetchSupplierById(widget.editSupplierId!);
      if (!mounted) return;

      if (supplier == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'This supplier no longer exists.';
        });
        return;
      }

      _applySupplier(supplier);
      setState(() {
        _existing = supplier;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applySupplier(SupplierEntity s) {
    _nameController.text = s.name;
    _codeController.text = s.code;
    _contactPersonController.text = s.contactPerson ?? '';
    _phoneController.text = s.phone;
    _alternatePhoneController.text = s.alternatePhone ?? '';
    _emailController.text = s.email ?? '';
    _addressController.text = s.address ?? '';
    _cityController.text = s.city ?? '';
    _pincodeController.text = s.pincode ?? '';
    _gstinController.text = s.gstin ?? '';
    _panController.text = s.pan ?? '';
    _bankNameController.text = s.bankName ?? '';
    _bankAccountController.text = s.bankAccountNumber ?? '';
    _bankIfscController.text = s.bankIfsc ?? '';
    _paymentTermsController.text = s.paymentTermsDays.toString();
    _creditLimitController.text = _plainAmount(s.creditLimit);
    _openingBalanceController.text = _plainAmount(s.openingBalance);
    _notesController.text = s.notes ?? '';
    _supplierType = s.supplierType;
    _selectedState = s.state ?? _selectedState;
    _isActive = s.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      activeNavigationId: 'suppliers',
      currentShowroomName: 'Procurement',
      title: isEditMode ? 'Edit Supplier' : 'Add Supplier',
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
    if (_isLoading) return AppSkeleton.form(sections: 4, fields: 3);

    if (_loadError != null) {
      return AppErrorState(
        title: 'Failed to Load Supplier',
        message: _loadError!,
        onRetry: _loadSupplier,
      );
    }

    if (_isSaving) {
      return const AppPageLoader(message: 'Saving supplier record...');
    }

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1: Vendor Identity ───
            AppFormSection(
              title: 'Vendor Identification',
              subtitle: 'Supplier code, trade name and procurement category',
              children: [
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Supplier Name',
                      hint: 'e.g. Honda Motorcycle & Scooter India',
                      isRequired: true,
                      prefixIcon: Icons.business_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Supplier name is required';
                        }
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _codeController,
                      label: 'Supplier Code',
                      hint: 'e.g. SUP-HONDA',
                      isRequired: true,
                      enabled: !isEditMode,
                      prefixIcon: Icons.qr_code_rounded,
                      validator: (val) {
                        final clean = val?.trim();
                        if (clean == null || clean.isEmpty) return 'Code is required';
                        if (clean.contains(' ')) return 'No spaces allowed';
                        return null;
                      },
                    ),
                    AppDropdown<String>(
                      label: 'Category',
                      value: _supplierType,
                      isRequired: true,
                      items: SupplierManagementService.supplierTypes,
                      itemLabel: SupplierManagementService.typeLabel,
                      prefixIcon: Icons.category_outlined,
                      onChanged: (val) =>
                          setState(() => _supplierType = val ?? 'spare_parts'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing12),
                Row(
                  children: [
                    Checkbox(
                      value: _isActive,
                      activeColor: AppColors.primaryYellow,
                      onChanged: (val) => setState(() => _isActive = val ?? true),
                    ),
                    const Expanded(
                      child: Text(
                        'Vendor is active and open for purchase orders',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Section 2: Contact & Address ───
            AppFormSection(
              title: 'Contact & Address',
              subtitle: 'Purchase contact and billing address for this vendor',
              children: [
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _contactPersonController,
                      label: 'Contact Person',
                      hint: 'e.g. Rajesh Kulkarni',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Primary Phone',
                      hint: '+91 22 2650 1100',
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Phone is required';
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _alternatePhoneController,
                      label: 'Alternate Phone',
                      hint: 'Optional',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_iphone_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'orders@vendor.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppDimensions.spacing16),
                AppTextField(
                  controller: _addressController,
                  label: 'Street Address',
                  hint: 'Plot / street, area, landmark',
                  maxLines: 2,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppDimensions.spacing16),
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'e.g. Mumbai',
                      prefixIcon: Icons.location_city_rounded,
                    ),
                    AppDropdown<String>(
                      label: 'State / Union Territory',
                      value: _selectedState,
                      items: ShowroomManagementService.indianStatesAndUTs,
                      onChanged: (val) => setState(() => _selectedState = val),
                    ),
                    AppTextField(
                      controller: _pincodeController,
                      label: 'PIN Code',
                      hint: '6-digit PIN',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.markunread_mailbox_outlined,
                      validator: (val) {
                        final clean = val?.trim() ?? '';
                        if (clean.isEmpty) return null;
                        if (!SupplierManagementService.pincodeRegex.hasMatch(clean)) {
                          return 'Enter 6-digit Indian PIN';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Section 3: Statutory Compliance ───
            AppFormSection(
              title: 'Statutory & GST Compliance',
              subtitle: 'Tax registration details printed on purchase orders',
              children: [
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _gstinController,
                      label: 'GSTIN',
                      hint: 'e.g. 27AABCU9603R1ZM',
                      prefixIcon: Icons.receipt_long_outlined,
                      validator: (val) {
                        final clean = val?.trim().toUpperCase() ?? '';
                        if (clean.isEmpty) return null;
                        if (!SupplierManagementService.gstinRegex.hasMatch(clean)) {
                          return 'Invalid 15-character GSTIN format';
                        }
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _panController,
                      label: 'PAN',
                      hint: 'e.g. AABCU9603R',
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) {
                        final clean = val?.trim().toUpperCase() ?? '';
                        if (clean.isEmpty) return null;
                        if (!SupplierManagementService.panRegex.hasMatch(clean)) {
                          return 'Invalid 10-character PAN format';
                        }
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _bankIfscController,
                      label: 'IFSC Code',
                      hint: 'e.g. HDFC0000042',
                      prefixIcon: Icons.pin_outlined,
                      validator: (val) {
                        final clean = val?.trim().toUpperCase() ?? '';
                        if (clean.isEmpty) return null;
                        if (!SupplierManagementService.ifscRegex.hasMatch(clean)) {
                          return 'Invalid 11-character IFSC format';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Section 4: Commercial & Banking ───
            AppFormSection(
              title: 'Commercial Terms & Banking',
              subtitle: 'Credit terms applied to purchase orders, and settlement account',
              children: [
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _paymentTermsController,
                      label: 'Payment Terms (days)',
                      hint: 'e.g. 30',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.schedule_rounded,
                      validator: _nonNegativeIntValidator,
                    ),
                    AppTextField(
                      controller: _creditLimitController,
                      label: 'Credit Limit',
                      hint: 'e.g. 500000',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      validator: _amountValidator,
                    ),
                    AppTextField(
                      controller: _openingBalanceController,
                      label: 'Opening Balance Payable',
                      hint: 'e.g. 0',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.receipt_outlined,
                      validator: _amountValidator,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                ResponsiveFieldRow(
                  children: [
                    AppTextField(
                      controller: _bankNameController,
                      label: 'Bank Name',
                      hint: 'e.g. HDFC Bank',
                      prefixIcon: Icons.account_balance_outlined,
                    ),
                    AppTextField(
                      controller: _bankAccountController,
                      label: 'Account Number',
                      hint: 'e.g. 50200011223344',
                      prefixIcon: Icons.numbers_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing16),
                AppTextField(
                  controller: _notesController,
                  label: 'Internal Notes',
                  hint: 'Delivery lead time, settlement quirks, margin notes...',
                  maxLines: 3,
                  prefixIcon: Icons.sticky_note_2_outlined,
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
                  label: isEditMode ? 'Update Supplier' : 'Create Supplier',
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

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final existing = _existing;

    final entity = SupplierEntity(
      id: existing?.id ?? 'sup-${now.microsecondsSinceEpoch}',
      showroomId: existing?.showroomId,
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      supplierType: _supplierType,
      contactPerson: _optional(_contactPersonController),
      phone: _phoneController.text.trim(),
      alternatePhone: _optional(_alternatePhoneController),
      email: _optional(_emailController),
      address: _optional(_addressController),
      city: _optional(_cityController),
      state: _selectedState,
      pincode: _optional(_pincodeController),
      gstin: _optionalUpper(_gstinController),
      pan: _optionalUpper(_panController),
      bankName: _optional(_bankNameController),
      bankAccountNumber: _optional(_bankAccountController),
      bankIfsc: _optionalUpper(_bankIfscController),
      paymentTermsDays: int.tryParse(_paymentTermsController.text.trim()) ?? 30,
      creditLimit: _parseAmount(_creditLimitController.text),
      openingBalance: _parseAmount(_openingBalanceController.text),
      isActive: _isActive,
      notes: _optional(_notesController),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (isEditMode) {
        await _service.updateSupplier(entity);
      } else {
        await _service.createSupplier(entity);
      }
      if (!mounted) return;
      context.showSuccessSnackBar(
        isEditMode ? 'Supplier updated successfully' : 'Supplier created successfully',
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  static String? _optionalUpper(TextEditingController c) {
    final text = c.text.trim().toUpperCase();
    return text.isEmpty ? null : text;
  }

  static double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  /// Trims the trailing `.0` so the edit form shows `500000`, not `500000.0`.
  static String _plainAmount(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  static String? _nonNegativeIntValidator(String? val) {
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) return null;
    final parsed = int.tryParse(clean);
    if (parsed == null) return 'Enter a whole number of days';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  static String? _amountValidator(String? val) {
    final clean = val?.replaceAll(',', '').trim() ?? '';
    if (clean.isEmpty) return null;
    final parsed = double.tryParse(clean);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }
}
