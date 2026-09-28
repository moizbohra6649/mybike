import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_loading.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../common/widgets/app_dropdown.dart';
import '../cubit/customer_form_cubit.dart';
import '../cubit/customer_form_state.dart';

/// Customer Create / Edit Form Screen
class CustomerFormScreen extends StatelessWidget {
  final String? editCustomerId;
  const CustomerFormScreen({super.key, this.editCustomerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = CustomerFormCubit();
        if (editCustomerId != null) {
          cubit.loadForEdit(editCustomerId!);
        }
        return cubit;
      },
      child: _CustomerFormView(isEdit: editCustomerId != null),
    );
  }
}

class _CustomerFormView extends StatelessWidget {
  final bool isEdit;
  const _CustomerFormView({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocConsumer<CustomerFormCubit, CustomerFormState>(
      listener: (context, state) {
        if (state.isSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Customer updated successfully' : 'Customer created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<CustomerFormCubit>();

        return AppScaffold(
          title: isEdit ? 'Edit Customer' : 'New Customer',
          activeNavigationId: 'customers',
          body: state.isLoading
              ? AppSkeleton.form(sections: 2, fields: 4)
              : ListView(
                  padding: const EdgeInsets.all(AppDimensions.spacing20),
                  children: [
                    // ─── Personal Details Section ───
                    _SectionCard(
                      isDark: isDark,
                      title: 'Personal Details',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _FormField(
                            label: 'First Name *',
                            initialValue: state.firstName,
                            onChanged: cubit.updateFirstName,
                            isDark: isDark,
                          ),
                          second: _FormField(
                            label: 'Last Name *',
                            initialValue: state.lastName,
                            onChanged: cubit.updateLastName,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _DropdownField(
                            label: 'Gender',
                            value: state.gender,
                            items: const {'male': 'Male', 'female': 'Female', 'other': 'Other'},
                            onChanged: cubit.updateGender,
                            isDark: isDark,
                          ),
                          second: _DropdownField(
                            label: 'Customer Type',
                            value: state.customerType,
                            items: const {'individual': 'Individual', 'corporate': 'Corporate', 'fleet': 'Fleet'},
                            onChanged: cubit.updateCustomerType,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Contact Section ───
                    _SectionCard(
                      isDark: isDark,
                      title: 'Contact Information',
                      icon: Icons.phone_outlined,
                      children: [
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _FormField(
                            label: 'Mobile Primary * (10 digits)',
                            initialValue: state.mobilePrimary,
                            onChanged: cubit.updateMobilePrimary,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            isDark: isDark,
                          ),
                          second: _FormField(
                            label: 'Mobile Secondary',
                            initialValue: state.mobileSecondary ?? '',
                            onChanged: cubit.updateMobileSecondary,
                            keyboardType: TextInputType.phone,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _FormField(
                            label: 'Email',
                            initialValue: state.email ?? '',
                            onChanged: cubit.updateEmail,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                          ),
                          second: _DropdownField(
                            label: 'Preferred Contact',
                            value: state.preferredContactMethod,
                            items: const {'phone': 'Phone', 'whatsapp': 'WhatsApp', 'email': 'Email', 'sms': 'SMS'},
                            onChanged: cubit.updatePreferredContact,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Address Section ───
                    _SectionCard(
                      isDark: isDark,
                      title: 'Address',
                      icon: Icons.location_on_outlined,
                      children: [
                        _FormField(
                          label: 'Address Line 1',
                          initialValue: state.addressLine1 ?? '',
                          onChanged: cubit.updateAddressLine1,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormField(
                          label: 'Address Line 2',
                          initialValue: state.addressLine2 ?? '',
                          onChanged: cubit.updateAddressLine2,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _FormField(
                            label: 'City',
                            initialValue: state.city ?? '',
                            onChanged: cubit.updateCity,
                            isDark: isDark,
                          ),
                          second: _FormField(
                            label: 'State',
                            initialValue: state.state ?? '',
                            onChanged: cubit.updateState,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormRow(
                          isMobile: context.isMobile,
                          first: _FormField(
                            label: 'PIN Code (6 digits)',
                            initialValue: state.pinCode ?? '',
                            onChanged: cubit.updatePinCode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            isDark: isDark,
                          ),
                          second: _FormField(
                            label: 'Landmark',
                            initialValue: state.landmark ?? '',
                            onChanged: cubit.updateLandmark,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Classification Section ───
                    _SectionCard(
                      isDark: isDark,
                      title: 'Classification',
                      icon: Icons.category_outlined,
                      children: [
                        _DropdownField(
                          label: 'Source',
                          value: state.source,
                          items: const {
                            'walk_in': 'Walk-in',
                            'phone_call': 'Phone Call',
                            'website': 'Website',
                            'social_media': 'Social Media',
                            'oem_referral': 'OEM Referral',
                            'exchange_inquiry': 'Exchange Inquiry',
                            'corporate_tieup': 'Corporate Tie-up',
                            'auto_expo': 'Auto Expo',
                            'existing_customer': 'Existing Customer',
                            'other': 'Other',
                          },
                          onChanged: cubit.updateSource,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        _FormField(
                          label: 'Notes',
                          initialValue: state.notes ?? '',
                          onChanged: cubit.updateNotes,
                          maxLines: 3,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── Save Button ───
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: state.isSaving ? null : () => cubit.saveCustomer(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.primaryBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                        ),
                        child: state.isSaving
                            ? const AppLoading(
                                size: AppLoadingSize.small,
                                color: AppColors.primaryBlack,
                              )
                            : Text(isEdit ? 'Update Customer' : 'Create Customer',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing40),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Section Card ───
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.isDark, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryYellow),
              const SizedBox(width: AppDimensions.spacing8),
              Text(title, style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          ...children,
        ],
      ),
    );
  }
}

// ─── Form Field ───
class _FormField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final bool isDark;

  const _FormField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.captionLarge.copyWith(
          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
        ),
        counterText: '',
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Dropdown Field ───
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _DropdownField({
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown<String>(
      label: label,
      value: value,
      items: items.keys.toList(),
      itemLabel: (k) => items[k] ?? k,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _FormRow extends StatelessWidget {
  final bool isMobile;
  final Widget first;
  final Widget second;

  const _FormRow({
    required this.isMobile,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: AppDimensions.spacing12),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: second),
      ],
    );
  }
}
