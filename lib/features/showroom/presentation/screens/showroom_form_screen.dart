import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/showroom_management_service.dart';
import '../cubit/showroom_form_cubit.dart';
import '../cubit/showroom_form_state.dart';

/// Showroom Create / Edit Form Screen
///
/// Fully responsive form for dealership branch setup, statutory tax compliance,
/// and automated invoice sequence numbering.
class ShowroomFormScreen extends StatefulWidget {
  final String? editShowroomId;

  const ShowroomFormScreen({super.key, this.editShowroomId});

  @override
  State<ShowroomFormScreen> createState() => _ShowroomFormScreenState();
}

class _ShowroomFormScreenState extends State<ShowroomFormScreen> {
  late final ShowroomFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _prefixController = TextEditingController(text: 'MB');
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankBranchController = TextEditingController();

  String? _selectedState = 'Maharashtra';
  bool _isActive = true;

  bool get isEditMode => widget.editShowroomId != null;

  @override
  void initState() {
    super.initState();
    _cubit = ShowroomFormCubit();

    _prefixController.addListener(_onPrefixChanged);

    if (isEditMode) {
      _cubit.loadShowroomForEdit(widget.editShowroomId!);
    } else {
      _cubit.initNewShowroom();
    }
  }

  void _onPrefixChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _prefixController.removeListener(_onPrefixChanged);
    _cubit.close();
    _nameController.dispose();
    _codeController.dispose();
    _prefixController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankBranchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        activeNavigationId: 'showrooms',
        currentShowroomName: 'Showroom Management',
        title: isEditMode ? 'Edit Showroom' : 'Create Showroom',
        actions: [
          AppButton.ghost(
            label: 'Cancel',
            leadingIcon: Icons.close_rounded,
            onPressed: () => context.pop(),
          ),
        ],
        body: BlocConsumer<ShowroomFormCubit, ShowroomFormState>(
          listener: (context, state) {
            if (state is ShowroomFormSuccess) {
              context.showSuccessSnackBar(state.message);
              context.pop();
            }
            if (state is ShowroomFormError) {
              context.showErrorSnackBar(state.message);
            }
            if (state is ShowroomFormReady && state.existingShowroom != null) {
              final s = state.existingShowroom!;
              if (_nameController.text.isEmpty) {
                _nameController.text = s.name;
                _codeController.text = s.code;
                _prefixController.text = s.invoicePrefix;
                _addressController.text = s.address;
                _cityController.text = s.city;
                _selectedState = s.state;
                _pincodeController.text = s.pincode;
                _phoneController.text = s.phone;
                _emailController.text = s.email ?? '';
                _gstinController.text = s.gstin ?? '';
                _panController.text = s.pan ?? '';
                _bankNameController.text = s.bankName ?? '';
                _bankAccountController.text = s.bankAccountNumber ?? '';
                _bankIfscController.text = s.bankIfsc ?? '';
                _bankBranchController.text = s.bankBranch ?? '';
                _isActive = s.isActive;
              }
            }
          },
          builder: (context, state) {
            if (state is ShowroomFormLoading) {
              return AppSkeleton.form(sections: 4, fields: 3);
            }
            if (state is ShowroomFormSaving) {
              return const AppPageLoader(message: 'Saving showroom coordinates...');
            }
            if (state is ShowroomFormError && state is! ShowroomFormReady) {
              return AppErrorState(
                title: 'Failed to Load Showroom',
                message: state.message,
                onRetry: () {
                  if (isEditMode) {
                    _cubit.loadShowroomForEdit(widget.editShowroomId!);
                  } else {
                    _cubit.initNewShowroom();
                  }
                },
              );
            }
            if (state is ShowroomFormReady) {
              return _buildForm(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ShowroomFormReady state) {
    final isDark = context.isDarkMode;
    final isMobile = context.isMobile;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: ResponsiveUtils.contentPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Card Banner ───
                _buildHeaderBanner(context, isDark),
                const SizedBox(height: AppDimensions.spacing24),

                // ─── Section 1: Branch Identification ───
                AppFormSection(
                  title: 'Branch Identification',
                  subtitle: 'Core dealership showroom code, trade name, and document sequence prefix',
                  children: [
                    ResponsiveFieldRow(
                      flexes: const [2, 1, 1],
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Showroom Name',
                          hint: 'e.g. MYBIKE Flagship Central',
                          isRequired: true,
                          prefixIcon: Icons.storefront_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Showroom name is required';
                            }
                            return null;
                          },
                        ),
                        AppTextField(
                          controller: _codeController,
                          label: 'Branch Code',
                          hint: 'e.g. IND-MUM',
                          isRequired: true,
                          enabled: !isEditMode,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          prefixIcon: Icons.qr_code_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Code is required';
                            if (val.contains(' ')) return 'No spaces allowed';
                            return null;
                          },
                        ),
                        AppTextField(
                          controller: _prefixController,
                          label: 'Invoice Prefix',
                          hint: 'e.g. MB-MUM',
                          isRequired: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          prefixIcon: Icons.tag_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Prefix is required';
                            return null;
                          },
                        ),
                      ],
                    ),

                    // Live Document Sequence Numbering Preview
                    _buildSequencePreview(context, isDark),
                    const SizedBox(height: AppDimensions.spacing8),

                    // Active Status Switch Card
                    _buildStatusSwitchCard(context, isDark),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),

                // ─── Section 2: Location & Contact Details ───
                AppFormSection(
                  title: 'Location & Contact Details',
                  subtitle: 'Operating address printed on customer invoices and delivery challans',
                  children: [
                    AppTextField(
                      controller: _addressController,
                      label: 'Street Address',
                      hint: 'Plot / Survey number, street, landmark, area',
                      isRequired: true,
                      maxLines: 2,
                      prefixIcon: Icons.location_on_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Street address is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    ResponsiveFieldRow(
                      flexes: const [1, 1, 1],
                      children: [
                        AppTextField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'e.g. Mumbai',
                          isRequired: true,
                          prefixIcon: Icons.location_city_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'City is required';
                            return null;
                          },
                        ),
                        AppDropdown<String>(
                          label: 'State / Union Territory',
                          value: _selectedState,
                          items: ShowroomManagementService.indianStatesAndUTs,
                          prefixIcon: Icons.map_outlined,
                          onChanged: (val) => setState(() => _selectedState = val),
                        ),
                        AppTextField(
                          controller: _pincodeController,
                          label: 'PIN Code',
                          hint: '6-digit PIN',
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          prefixIcon: Icons.markunread_mailbox_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'PIN code is required';
                            if (!ShowroomFormCubit.pincodeRegex.hasMatch(val.trim())) {
                              return 'Enter 6-digit Indian PIN';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    ResponsiveFieldRow(
                      children: [
                        AppTextField(
                          controller: _phoneController,
                          label: 'Primary Phone',
                          hint: '+91 98200 12345',
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Phone is required';
                            return null;
                          },
                        ),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'showroom@mybike.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),

                // ─── Section 3: Statutory & GST Compliance ───
                AppFormSection(
                  title: 'Statutory & GST Compliance',
                  subtitle: 'Goods & Services Tax registration and PAN for branch compliance',
                  children: [
                    ResponsiveFieldRow(
                      children: [
                        AppTextField(
                          controller: _gstinController,
                          label: 'GSTIN (GST Number)',
                          hint: 'e.g. 27AABCU9603R1ZM',
                          helperText: '15-character statutory GST identification number',
                          maxLength: 15,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          prefixIcon: Icons.receipt_long_outlined,
                          validator: (val) {
                            final clean = val?.trim().toUpperCase();
                            if (clean != null &&
                                clean.isNotEmpty &&
                                !ShowroomFormCubit.gstinRegex.hasMatch(clean)) {
                              return 'Invalid 15-character GSTIN format';
                            }
                            return null;
                          },
                        ),
                        AppTextField(
                          controller: _panController,
                          label: 'PAN (Permanent Account Number)',
                          hint: 'e.g. AABCU9603R',
                          helperText: '10-character Permanent Account Number',
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          prefixIcon: Icons.badge_outlined,
                          validator: (val) {
                            final clean = val?.trim().toUpperCase();
                            if (clean != null &&
                                clean.isNotEmpty &&
                                !ShowroomFormCubit.panRegex.hasMatch(clean)) {
                              return 'Invalid 10-character PAN format';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),

                // ─── Section 4: Banking Information ───
                AppFormSection(
                  title: 'Banking Coordinates',
                  subtitle: 'Bank account printed on customer invoices for NEFT/RTGS/IMPS payments',
                  children: [
                    ResponsiveFieldRow(
                      children: [
                        AppTextField(
                          controller: _bankNameController,
                          label: 'Bank Name',
                          hint: 'e.g. HDFC Bank Ltd',
                          prefixIcon: Icons.account_balance_outlined,
                        ),
                        AppTextField(
                          controller: _bankAccountController,
                          label: 'Account Number',
                          hint: 'e.g. 50200012345678',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.numbers_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    ResponsiveFieldRow(
                      children: [
                        AppTextField(
                          controller: _bankIfscController,
                          label: 'IFSC Code',
                          hint: 'e.g. HDFC0000042',
                          helperText: '11-character Indian Financial System Code',
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          prefixIcon: Icons.pin_outlined,
                          validator: (val) {
                            final clean = val?.trim().toUpperCase();
                            if (clean != null &&
                                clean.isNotEmpty &&
                                !ShowroomFormCubit.ifscRegex.hasMatch(clean)) {
                              return 'Invalid 11-character IFSC format';
                            }
                            return null;
                          },
                        ),
                        AppTextField(
                          controller: _bankBranchController,
                          label: 'Bank Branch Name',
                          hint: 'e.g. Bandra Kurla Complex',
                          prefixIcon: Icons.business_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing32),

                // ─── Responsive Action Buttons ───
                _buildActionButtons(context, isMobile),
                const SizedBox(height: AppDimensions.spacing40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Center(
              child: Icon(
                Icons.storefront_rounded,
                color: AppColors.primaryYellowDark,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isEditMode ? 'Edit Branch Showroom' : 'Add New Branch Showroom',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Text(
                        isEditMode ? 'EDIT' : 'NEW',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Configure branch identity, operational state, tax GSTIN, and statutory numbering sequence.',
                  style: AppTypography.captionMedium.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequencePreview(BuildContext context, bool isDark) {
    final prefix = _prefixController.text.trim().toUpperCase();
    if (prefix.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacing12, bottom: AppDimensions.spacing4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacing12),
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.primaryYellow.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Automated Sequence Numbering Preview',
                    style: AppTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPreviewBadge(context, 'Tax Invoice', '$prefix-INV-00001', isDark),
                _buildPreviewBadge(context, 'Booking', '$prefix-BKG-00001', isDark),
                _buildPreviewBadge(context, 'Challan', '$prefix-DC-00001', isDark),
                _buildPreviewBadge(context, 'Receipt', '$prefix-RCP-00001', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBadge(BuildContext context, String label, String code, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.captionSmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
          Text(
            code,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryYellowLight : AppColors.primaryBlack,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSwitchCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: _isActive
              ? AppColors.primaryYellow.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Switch.adaptive(
            value: _isActive,
            activeThumbColor: AppColors.primaryYellow,
            activeTrackColor: AppColors.primaryYellow.withValues(alpha: 0.4),
            onChanged: (val) => setState(() => _isActive = val),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isActive ? 'Active Operating Showroom' : 'Inactive Showroom',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _isActive
                              ? (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)
                              : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.darkMutedText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Text(
                        _isActive ? 'ONLINE' : 'OFFLINE',
                        style: AppTypography.captionSmall.copyWith(
                          color: _isActive ? AppColors.success : AppColors.darkMutedText,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'When active, this showroom is open for vehicle stock mapping, customer invoicing, and dealership operations.',
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(
            label: isEditMode ? 'Update Showroom' : 'Create Showroom',
            leadingIcon: Icons.save_rounded,
            size: AppButtonSize.large,
            isFullWidth: true,
            onPressed: _submitForm,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          AppButton.ghost(
            label: 'Cancel',
            size: AppButtonSize.medium,
            isFullWidth: true,
            onPressed: () => context.pop(),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton.ghost(
          label: 'Cancel',
          size: AppButtonSize.medium,
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        AppButton.primary(
          label: isEditMode ? 'Update Showroom' : 'Create Showroom',
          leadingIcon: Icons.save_rounded,
          size: AppButtonSize.medium,
          onPressed: _submitForm,
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _cubit.saveShowroom(
        name: _nameController.text,
        code: _codeController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _selectedState ?? 'Maharashtra',
        pincode: _pincodeController.text,
        phone: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        gstin: _gstinController.text.isEmpty ? null : _gstinController.text,
        pan: _panController.text.isEmpty ? null : _panController.text,
        bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
        bankAccountNumber: _bankAccountController.text.isEmpty ? null : _bankAccountController.text,
        bankIfsc: _bankIfscController.text.isEmpty ? null : _bankIfscController.text,
        bankBranch: _bankBranchController.text.isEmpty ? null : _bankBranchController.text,
        invoicePrefix: _prefixController.text,
        isActive: _isActive,
      );
    }
  }
}
