import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/extensions/context_extensions.dart';

/// Ultra-Premium Styled Dropdown for MYBIKE ERP
///
/// Features:
/// - Sleek card-like field styling with smooth focus/hover glow
/// - Custom rounded badge prefix icon container
/// - Modern circular chevron badge with optional instant clear action
/// - Rich elevated popup menu with active item highlight and checkmark badge
/// - Clean collapsed state rendering via [selectedItemBuilder]
/// - Full support for form validation, helper text, and compact/dense mode
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool isRequired;
  final bool enabled;
  final bool isClearable;
  final bool isDense;
  final IconData? prefixIcon;
  final double? menuMaxHeight;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
    this.itemBuilder,
    this.validator,
    this.autovalidateMode,
    this.isRequired = false,
    this.enabled = true,
    this.isClearable = false,
    this.isDense = false,
    this.prefixIcon,
    this.menuMaxHeight,
  });

  String _getItemLabel(T item) {
    if (itemLabel != null) {
      return itemLabel!(item);
    }
    return item?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final showClear = isClearable && value != null && enabled && onChanged != null;

    // Palette tokens
    final fieldBg = isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFAFAFA);
    final borderColor = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final hintTextColor = isDark ? AppColors.darkHintText : AppColors.lightHintText;

    // Trailing chevron / clear widget
    final suffixAffordance = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showClear) ...[
          InkWell(
            onTap: () => onChanged!(null),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacing4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: AppDimensions.iconXs,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing6),
        ],
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF28282D) : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? secondaryTextColor : hintTextColor,
            size: AppDimensions.iconSm + 2,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  color: primaryTextColor,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: AppDimensions.spacing4),
                Text(
                  '*',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
        ],

        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: suffixAffordance,
          dropdownColor: isDark ? const Color(0xFF202024) : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          elevation: 8,
          menuMaxHeight: menuMaxHeight ?? 380,
          autovalidateMode: autovalidateMode,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? fieldBg : (isDark ? const Color(0xFF141416) : const Color(0xFFF3F4F6)),
            hintText: hint ?? 'Select option',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: hintTextColor,
              fontWeight: FontWeight.w400,
            ),
            helperText: helperText,
            helperStyle: AppTypography.captionMedium.copyWith(color: secondaryTextColor),
            errorText: errorText,
            errorMaxLines: 2,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: isDense ? AppDimensions.spacing8 : AppDimensions.spacing12,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacing12,
                      right: AppDimensions.spacing8,
                    ),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28282D) : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(
                        prefixIcon,
                        color: isDark ? AppColors.primaryYellow : AppColors.primaryBlack,
                        size: AppDimensions.iconSm,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 40),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: borderColor,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primaryYellowDark,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.errorDark,
                width: 1.8,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF242426) : const Color(0xFFEEEEEE),
                width: 1.0,
              ),
            ),
          ),

          // Render clean collapsed text inside the closed field
          selectedItemBuilder: (BuildContext context) {
            return items.map((T item) {
              if (itemBuilder != null) {
                return itemBuilder!(context, item);
              }
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _getItemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },

          // Render rich elevated items inside the opened popup menu
          items: items.map((T item) {
            final isSelected = item == value;
            final labelText = _getItemLabel(item);

            return DropdownMenuItem<T>(
              value: item,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing10,
                  vertical: AppDimensions.spacing8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primaryYellow.withValues(alpha: 0.16)
                          : const Color(0xFFFFFBEB))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm + 2),
                  border: isSelected
                      ? Border.all(
                          color: isDark
                              ? AppColors.primaryYellow.withValues(alpha: 0.45)
                              : const Color(0xFFFDE68A),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: itemBuilder != null
                          ? itemBuilder!(context, item)
                          : Text(
                              labelText,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.primaryYellowLight
                                        : const Color(0xFFB45309))
                                    : primaryTextColor,
                              ),
                            ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(left: AppDimensions.spacing8),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primaryYellow : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
