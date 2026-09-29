import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_loading.dart';
import '../cubit/booking_wizard_cubit.dart';
import '../cubit/booking_wizard_state.dart';

/// Interactive Booking & Sales Invoicing Wizard Screen
class BookingWizardScreen extends StatelessWidget {
  const BookingWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingWizardCubit(),
      child: const _BookingWizardView(),
    );
  }
}

class _BookingWizardView extends StatefulWidget {
  const _BookingWizardView();

  @override
  State<_BookingWizardView> createState() => _BookingWizardViewState();
}

class _BookingWizardViewState extends State<_BookingWizardView> {
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerMobileController;
  late final TextEditingController _customerSearchController;

  OverlayEntry? _topToastOverlay;
  Timer? _topToastTimer;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _customerMobileController = TextEditingController();
    _customerSearchController = TextEditingController();
  }

  void _dismissTopToast() {
    _topToastTimer?.cancel();
    _topToastTimer = null;
    if (_topToastOverlay != null && _topToastOverlay!.mounted) {
      _topToastOverlay!.remove();
    }
    _topToastOverlay = null;
  }

  /// Displays a floating top toast notification with a decent, subtle slate/amber palette
  void _showTopMessage(
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Color? accentColor,
  }) {
    _dismissTopToast();

    if (!mounted) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    final accent = accentColor ?? const Color(0xFFF59E0B); // Soft warm amber instead of harsh red

    _topToastOverlay = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        return Positioned(
          top: topPadding + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1.0 - value) * -14),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222A), // Decent elegant obsidian slate
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _dismissTopToast,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_topToastOverlay!);
    _topToastTimer = Timer(const Duration(seconds: 4), () {
      _dismissTopToast();
    });
  }

  @override
  void dispose() {
    _dismissTopToast();
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocConsumer<BookingWizardCubit, BookingWizardState>(
      listener: (context, state) {
        if (state.savedInvoice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tax Invoice ${state.savedInvoice!.invoiceNumber} generated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/sales/${state.savedInvoice!.id}');
        }
        if (state.error != null) {
          _showTopMessage(state.error!);
        }
      },
      builder: (context, state) {
        return AppScaffold(
          activeNavigationId: 'sales',
          title: 'Sales & Booking Wizard',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  children: [
                    // ─── Step Indicator Progress Bar ───
                    _buildStepper(context, state, isDark),
                    const SizedBox(height: 24),

                    // ─── Step Content Card ───
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: _buildCurrentStep(context, state, isDark),
                    ),
                    const SizedBox(height: 24),

                    // ─── Wizard Bottom Navigation Buttons ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (state.currentStep > 0)
                          OutlinedButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () => context.read<BookingWizardCubit>().previousStep(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Back'),
                          )
                        else
                          const SizedBox.shrink(),
                        if (state.currentStep < 4)
                          FilledButton.icon(
                            onPressed: () {
                              final cubit = context.read<BookingWizardCubit>();
                              if (state.currentStep == 0) {
                                final name = _customerNameController.text.trim();
                                final mobile = _customerMobileController.text.trim();
                                if (name.isEmpty) {
                                  _showTopMessage('Please select a customer or enter customer full name.');
                                  return;
                                }
                                if (mobile.isEmpty || mobile.length < 10) {
                                  _showTopMessage('Please enter a valid 10-digit mobile number.');
                                  return;
                                }
                                cubit.setCustomer(
                                  id: state.selectedCustomerId,
                                  name: name,
                                  mobile: mobile,
                                );
                              } else if (state.currentStep == 1) {
                                if (state.selectedVariantId == null || state.selectedVariantId!.isEmpty) {
                                  _showTopMessage('Please select a vehicle model & variant to continue.');
                                  return;
                                }
                                if (state.selectedColorId == null || state.selectedColorId!.isEmpty) {
                                  _showTopMessage('Please select a vehicle color to continue.');
                                  return;
                                }
                              }
                              cubit.nextStep();
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('Continue'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: AppColors.primaryBlack,
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () => context.read<BookingWizardCubit>().generateInvoice(),
                            icon: state.isSaving
                                ? const AppLoading(
                                    size: AppLoadingSize.small,
                                    color: Colors.white,
                                  )
                                : const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text('Generate Tax Invoice'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepper(BuildContext context, BookingWizardState state, bool isDark) {
    const steps = ['Customer', 'Vehicle', 'Pricing', 'Payment', 'Review'];
    final accentColor = isDark ? AppColors.primaryYellow : AppColors.primaryYellowDark;

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = state.currentStep > index;
        final isCurrent = state.currentStep == index;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isDone
                          ? AppColors.success
                          : (isCurrent
                              ? AppColors.primaryYellow
                              : (isDark ? AppColors.darkBackground : AppColors.lightBackground)),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: AppTypography.captionLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? AppColors.primaryBlack
                                    : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? accentColor
                            : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 24,
                  height: 2,
                  color: isDone
                      ? AppColors.success
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext context, BookingWizardState state, bool isDark) {
    switch (state.currentStep) {
      case 0:
        return _buildStep0Customer(context, state, isDark);
      case 1:
        return _buildStep1Vehicle(context, state, isDark);
      case 2:
        return _buildStep2Pricing(context, state, isDark);
      case 3:
        return _buildStep3Payment(context, state, isDark);
      case 4:
        return _buildStep4Review(context, state, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Customer Selection ───
  Widget _buildStep0Customer(BuildContext context, BookingWizardState state, bool isDark) {
    final cubit = context.read<BookingWizardCubit>();
    final isCustomerSelected = state.selectedCustomerId != null && state.selectedCustomerId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 1: Customer Details', style: AppTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Select a customer from database or enter customer details manually.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => cubit.loadCustomers(),
              tooltip: 'Refresh Database Customers',
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Database Customer Search & Select Section ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: isDark ? AppColors.primaryYellowLight : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search Customer in Database',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28282D) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '${state.availableCustomers.length} in DB',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Field
              TextField(
                controller: _customerSearchController,
                onChanged: (val) => cubit.searchCustomers(val),
                decoration: InputDecoration(
                  hintText: 'Search by customer name, mobile number, or ID...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkHintText : AppColors.lightHintText,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _customerSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          onPressed: () {
                            _customerSearchController.clear();
                            cubit.searchCustomers('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF141416) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF333339) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF333339) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primaryYellow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Customer Results State
              if (state.isLoadingCustomers) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading customers from database...',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (state.availableCustomers.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No registered customers found in database. Enter new customer details below.',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (state.filteredCustomers.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No customers match "${_customerSearchController.text}"',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            _customerSearchController.clear();
                            cubit.searchCustomers('');
                          },
                          child: const Text('Clear search filter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.filteredCustomers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final customer = state.filteredCustomers[index];
                      final isSelected = state.selectedCustomerId == customer.id;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _customerNameController.text = customer.fullName;
                            _customerMobileController.text = customer.mobilePrimary;
                            cubit.selectCustomer(customer);
                          },
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primaryYellow.withValues(alpha: 0.16)
                                      : const Color(0xFFFFFBEB))
                                  : (isDark ? const Color(0xFF24242A) : Colors.white),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? AppColors.primaryYellow : const Color(0xFFF59E0B))
                                    : (isDark ? const Color(0xFF33333A) : const Color(0xFFE5E7EB)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? AppColors.primaryYellow
                                      : (isDark ? const Color(0xFF33333A) : const Color(0xFFE5E7EB)),
                                  child: Text(
                                    customer.initials.isNotEmpty ? customer.initials : 'C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.primaryBlack
                                          : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                                    ),
                                  ),
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
                                              customer.fullName,
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? (isDark ? AppColors.primaryYellowLight : const Color(0xFFB45309))
                                                    : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              customer.customerNumber,
                                              style: AppTypography.captionSmall.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '+91 ${customer.mobilePrimary}',
                                            style: AppTypography.captionMedium.copyWith(
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                            ),
                                          ),
                                          if (customer.city != null && customer.city!.isNotEmpty) ...[
                                            Text(
                                              ' • ${customer.city}',
                                              style: AppTypography.captionMedium.copyWith(
                                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                              ),
                                            ),
                                          ],
                                          if (customer.kycStatus == 'verified') ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryYellow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: AppColors.primaryBlack,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Active Selection Banner ──
        if (isCustomerSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Linked Customer: ${state.customerName} (${state.selectedCustomer?.customerNumber ?? state.selectedCustomerId})',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _customerNameController.clear();
                    _customerMobileController.clear();
                    cubit.clearCustomerSelection();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

        // ── Customer Form Fields ──
        Text('Customer Invoicing Details', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Customer Full Name *',
            hintText: 'e.g. Ramesh Chandra',
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _customerMobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Mobile Number (10 Digits) *',
            hintText: 'e.g. 9820011223',
            prefixText: '+91 ',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  // ─── Step 1: Vehicle Selection ───
  Widget _buildStep1Vehicle(BuildContext context, BookingWizardState state, bool isDark) {
    final accentColor = isDark ? AppColors.primaryYellow : AppColors.primaryYellowDark;
    final bikes = [
      {
        'modelId': '11111111-cb35-4000-8000-000000000001',
        'modelName': 'Honda CB350 H\'ness',
        'variantId': 'ed20dcc6-3ecd-4275-9bcf-fef5170167a1',
        'variantName': 'DLX Pro Dual Tone',
        'price': 217800.0,
        'isEv': false,
        'vin': 'ME4NC5800N8000101',
        'colors': [
          {'id': 'dc7007fe-1686-4afa-a1dd-672bc73489e6', 'name': 'Precious Red Metallic', 'hex': 'B71C1C'},
          {'id': 'dc7007fe-1686-4afa-a1dd-672bc73489e7', 'name': 'Pearl Night Star Black', 'hex': '1A1A1A'},
          {'id': 'dc7007fe-1686-4afa-a1dd-672bc73489e8', 'name': 'Matte Marvel Blue', 'hex': '1E3A8A'},
        ],
      },
      {
        'modelId': '22222222-450x-4000-8000-000000000002',
        'modelName': 'Ather 450X Gen 3',
        'variantId': 'c7b5277d-e8b4-48ef-8ccf-38a6c9023d2a',
        'variantName': '3.7 kWh Pro',
        'price': 154999.0,
        'isEv': true,
        'vin': 'MALJA450XN0000103',
        'colors': [
          {'id': 'c7b5277d-e8b4-48ef-8ccf-38a6c9023c01', 'name': 'True White', 'hex': 'F8FAFC'},
          {'id': 'c7b5277d-e8b4-48ef-8ccf-38a6c9023c02', 'name': 'Space Grey', 'hex': '374151'},
          {'id': 'c7b5277d-e8b4-48ef-8ccf-38a6c9023c03', 'name': 'Mint Green', 'hex': '10B981'},
        ],
      },
      {
        'modelId': '33333333-rtr3-4000-8000-000000000003',
        'modelName': 'TVS Apache RTR 310',
        'variantId': '274bff7a-db20-4338-911a-523fdd27f7ef',
        'variantName': 'BTO Dynamic Kit',
        'price': 272000.0,
        'isEv': false,
        'vin': 'ME4NC5800N8000102',
        'colors': [
          {'id': '274bff7a-db20-4338-911a-523fdd27c001', 'name': 'Arsenal Black', 'hex': '111111'},
          {'id': '274bff7a-db20-4338-911a-523fdd27c002', 'name': 'Fury Yellow', 'hex': 'EAB308'},
          {'id': '274bff7a-db20-4338-911a-523fdd27c003', 'name': 'Sepang Blue', 'hex': '2563EB'},
        ],
      },
      {
        'modelId': '44444444-hunt-4000-8000-000000000004',
        'modelName': 'Royal Enfield Hunter 350',
        'variantId': '98453344-5566-4778-8990-112233445566',
        'variantName': 'Metro Dapper',
        'price': 169656.0,
        'isEv': false,
        'vin': 'ME4NC5800N8000105',
        'colors': [
          {'id': '98453344-5566-4778-8990-11223344c001', 'name': 'Dapper Ash', 'hex': '607D8B'},
          {'id': '98453344-5566-4778-8990-11223344c002', 'name': 'Rebel Blue', 'hex': '0284C7'},
          {'id': '98453344-5566-4778-8990-11223344c003', 'name': 'Rebel Red', 'hex': 'DC2626'},
        ],
      },
      {
        'modelId': '55555555-rizt-4000-8000-000000000005',
        'modelName': 'Ather Rizta Family Scooter',
        'variantId': 'a1234567-89ab-4cde-f012-3456789abcde',
        'variantName': 'Rizta Z 3.7',
        'price': 144999.0,
        'isEv': true,
        'vin': 'MALJA450XN0000104',
        'colors': [
          {'id': 'a1234567-89ab-4cde-f012-3456789ac001', 'name': 'Pangong Blue', 'hex': '1E88E5'},
          {'id': 'a1234567-89ab-4cde-f012-3456789ac002', 'name': 'Deccan Grey', 'hex': '4B5563'},
          {'id': 'a1234567-89ab-4cde-f012-3456789ac003', 'name': 'Siachen White', 'hex': 'F1F5F9'},
        ],
      },
    ];

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Select Vehicle & Color', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Choose the motorcycle or electric scooter variant and color for invoice generation.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bikes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bike = bikes[index];
            final isSelected = state.selectedVariantId == bike['variantId'];
            final bikeColors = bike['colors'] as List<Map<String, String>>;

            return InkWell(
              onTap: () {
                if (!isSelected) {
                  context.read<BookingWizardCubit>().setVehicle(
                        modelId: bike['modelId'] as String,
                        modelName: bike['modelName'] as String,
                        variantId: bike['variantId'] as String,
                        variantName: bike['variantName'] as String,
                        exShowroomPrice: bike['price'] as double,
                        isEv: bike['isEv'] as bool,
                        vin: bike['vin'] as String,
                      );
                }
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E222D) : const Color(0xFFFFFBEB))
                      : (isDark ? const Color(0xFF16161A) : Colors.transparent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          bike['isEv'] == true ? Icons.electric_scooter_rounded : Icons.two_wheeler_rounded,
                          size: 28,
                          color: isSelected ? accentColor : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bike['modelName'] as String,
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                bike['variantName'] as String,
                                style: AppTypography.captionMedium.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currency.format(bike['price']),
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              bike['isEv'] == true ? '5% GST (EV)' : '28% GST (ICE)',
                              style: AppTypography.captionMedium.copyWith(
                                color: bike['isEv'] == true ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Color Selection Palette for Selected Bike ──
                    if (isSelected) ...[
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Select Color *',
                            style: AppTypography.captionLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (state.selectedColorId != null && state.selectedColorId!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    state.selectedColorName ?? '',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Selection Required',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: bikeColors.map((col) {
                          final isColorSelected = state.selectedColorId == col['id'];
                          final dotColor = _parseHexColor(col['hex']!);
                          final isLightDot = dotColor.computeLuminance() > 0.7;

                          return InkWell(
                            onTap: () {
                              context.read<BookingWizardCubit>().setColor(
                                    colorId: col['id']!,
                                    colorName: col['name']!,
                                    colorHex: col['hex']!,
                                  );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isColorSelected
                                    ? (isDark ? const Color(0xFF2A2A35) : Colors.white)
                                    : (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isColorSelected
                                      ? accentColor
                                      : (isDark ? const Color(0xFF383842) : const Color(0xFFD1D5DB)),
                                  width: isColorSelected ? 1.8 : 1,
                                ),
                                boxShadow: isColorSelected
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isLightDot ? Colors.black26 : Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: isColorSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 10,
                                            color: isLightDot ? Colors.black87 : Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    col['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isColorSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isColorSelected
                                          ? (isDark ? Colors.white : Colors.black87)
                                          : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Step 2: On-Road Pricing Customizer ───
  Widget _buildStep2Pricing(BuildContext context, BookingWizardState state, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    final accentColor = isDark ? AppColors.primaryYellow : AppColors.primaryYellowDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: On-Road Price & Indian Tax Breakdown', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Fine-tune statutory charges, accessories, and promotional discounts.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          title: const Text('Ex-Showroom Price (Vehicle Base)'),
          trailing: Text(currency.format(state.exShowroomPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: Text(state.isEv ? 'CGST (2.5%) + SGST (2.5%) — EV' : 'CGST (14%) + SGST (14%) — Petrol'),
          trailing: Text(currency.format(state.totalGst), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text('RTO Road Tax & Registration'),
          subtitle: Text(state.isEv ? 'Subsidized EV Road Tax' : 'Standard 10-12% State Road Tax'),
          trailing: Text(currency.format(state.rtoCharges)),
        ),
        ListTile(
          title: const Text('Comprehensive Insurance (1+5 Yrs)'),
          trailing: Text(currency.format(state.insuranceCharges)),
        ),
        ListTile(
          title: const Text('Accessories Pack (Crash Guard, Grip, Cover)'),
          trailing: Text(currency.format(state.accessoriesTotal)),
        ),
        ListTile(
          title: const Text('Extended Warranty & 5-Yr Roadside Assistance'),
          trailing: Text(currency.format(state.extendedWarrantyAmount)),
        ),
        const Divider(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Total On-Road Price (INR):', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Text(
                currency.format(state.totalOnRoadPrice),
                textAlign: TextAlign.right,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Payment & Financing ───
  Widget _buildStep3Payment(BuildContext context, BookingWizardState state, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Payment & Settlement', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Record token booking advances, bank loan financing, and customer down payments.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: state.bookingAdvanceAdjusted > 0 ? state.bookingAdvanceAdjusted.toStringAsFixed(0) : '5000',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Booking Token Advance Adjusted (INR)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0.0;
            context.read<BookingWizardCubit>().updatePayment(bookingAdvance: val);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.financeAmount > 0 ? state.financeAmount.toStringAsFixed(0) : '150000',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Bank Loan / Finance Disbursed (INR)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0.0;
            context.read<BookingWizardCubit>().updatePayment(
                  financeAmount: val,
                  financeBank: 'HDFC Bank Auto Loan',
                );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.downPaymentPaid > 0 ? state.downPaymentPaid.toStringAsFixed(0) : '0',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Customer Down Payment Today (INR)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0.0;
            context.read<BookingWizardCubit>().updatePayment(downPayment: val);
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('Total Received: ${currency.format(state.totalPaid)}')),
              const SizedBox(width: AppDimensions.spacing12),
              Text(
                'Balance Due: ${currency.format(state.balanceAmount)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: state.isFullyPaid ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 4: Final Review ───
  Widget _buildStep4Review(BuildContext context, BookingWizardState state, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    final accentColor = isDark ? AppColors.primaryYellow : AppColors.primaryYellowDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5: Review & Confirm Invoice', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Verify customer particulars, GST rates, and vehicle allocation before issuing.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            color: AppColors.primaryYellow.withValues(alpha: 0.06),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer:', style: AppTypography.bodySmall),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Text('${state.customerName} (+91 ${state.customerMobile})',
                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle:', style: AppTypography.bodySmall),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Text('${state.selectedModelName} (${state.selectedVariantName})',
                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color / VIN:', style: AppTypography.bodySmall),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Text('${state.selectedColorName} • ${state.selectedVin ?? "Assigned on Invoicing"}',
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GST Regime:', style: AppTypography.bodySmall),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Text(state.isEv ? '5.0% EV Subsidized GST' : '28.0% Standard Motor Vehicle GST',
                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('Total On-Road Value:', style: AppTypography.headlineSmall),
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  Text(
                    currency.format(state.totalOnRoadPrice),
                    textAlign: TextAlign.right,
                    style: AppTypography.headlineSmall.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
