import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/extensions/context_extensions.dart';

/// Generic Styled Dropdown for MYBIKE ERP
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final bool isRequired;
  final bool enabled;
  final bool isClearable;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
    this.itemBuilder,
    this.isRequired = false,
    this.enabled = true,
    this.isClearable = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    // Mirrors AppDatePicker: the clear affordance only exists when there is
    // something to clear, so an empty or disabled field keeps its plain caret.
    final showClear = isClearable && value != null && enabled && onChanged != null;

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
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
          icon: showClear
              ? const SizedBox.shrink()
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  size: AppDimensions.iconMd,
                ),
          dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Select option',
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    size: AppDimensions.iconSm,
                  )
                : null,
            // The clear button takes over the dropdown's own caret slot, so
            // the caret is re-drawn beside it to keep the affordance visible.
            suffixIcon: showClear
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: AppDimensions.iconSm),
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        onPressed: () => onChanged!(null),
                        tooltip: 'Clear selection',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.spacing12),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          size: AppDimensions.iconMd,
                        ),
                      ),
                    ],
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing12,
            ),
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemBuilder != null
                  ? itemBuilder!(context, item)
                  : Text(
                      itemLabel != null ? itemLabel!(item) : item.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
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
