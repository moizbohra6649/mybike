import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/extensions/context_extensions.dart';

/// Selection result wrapper for bottom sheet modal
class _DropdownResult<T> {
  final T? value;
  final bool isCleared;

  const _DropdownResult.select(this.value) : isCleared = false;
  const _DropdownResult.clear() : value = null, isCleared = true;
}

/// Ultra-Premium Styled BottomSheet Dropdown for MYBIKE ERP
///
/// Converts standard dropdown selectors into an intuitive, touch-friendly
/// Modal BottomSheet with:
/// - Smooth slide-up bottom sheet presentation
/// - Integrated search filter for quick item discovery
/// - Item selection indicator with gold brand accent and checkmark badge
/// - Support for custom item builders and custom item labels
/// - Quick clear affordance
/// - Form validation and error messaging
class AppDropdown<T> extends StatefulWidget {
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
  final String? sheetTitle;
  final bool? enableSearch;

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
    this.sheetTitle,
    this.enableSearch,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final GlobalKey<FormFieldState<T?>> _fieldKey = GlobalKey<FormFieldState<T?>>();

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fieldKey.currentState?.didChange(widget.value);
        }
      });
    }
  }

  String _getItemLabel(T? item) {
    if (item == null) return '';
    if (widget.itemLabel != null) {
      return widget.itemLabel!(item);
    }
    return item.toString();
  }

  Future<void> _openBottomSheet(BuildContext context, FormFieldState<T?> formState) async {
    if (!widget.enabled || widget.onChanged == null) return;
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<_DropdownResult<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AppDropdownBottomSheet<T>(
        title: widget.sheetTitle ?? widget.label ?? widget.hint ?? 'Select Option',
        items: widget.items,
        selectedValue: widget.value,
        itemLabel: widget.itemLabel,
        itemBuilder: widget.itemBuilder,
        isClearable: widget.isClearable,
        enableSearch: widget.enableSearch ?? (widget.items.length > 5),
        maxHeight: widget.menuMaxHeight,
      ),
    );

    if (result != null) {
      if (result.isCleared) {
        formState.didChange(null);
        widget.onChanged?.call(null);
      } else {
        formState.didChange(result.value);
        widget.onChanged?.call(result.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final showClear = widget.isClearable && widget.value != null && widget.enabled && widget.onChanged != null;

    final fieldBg = isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFAFAFA);
    final borderColor = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final hintTextColor = isDark ? AppColors.darkHintText : AppColors.lightHintText;

    return FormField<T?>(
      key: _fieldKey,
      initialValue: widget.value,
      validator: widget.validator != null ? (val) => widget.validator!(val as T) : null,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (FormFieldState<T?> formState) {
        final hasError = formState.hasError || widget.errorText != null;
        final currentError = formState.errorText ?? widget.errorText;

        final suffixAffordance = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClear) ...[
              InkWell(
                onTap: () {
                  formState.didChange(null);
                  widget.onChanged?.call(null);
                },
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
                color: widget.enabled ? secondaryTextColor : hintTextColor,
                size: AppDimensions.iconSm + 2,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
          ],
        );

        final prefixWidget = widget.prefixIcon != null
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
                    widget.prefixIcon,
                    color: isDark ? AppColors.primaryYellow : AppColors.primaryBlack,
                    size: AppDimensions.iconSm,
                  ),
                ),
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Row(
                children: [
                  Text(
                    widget.label!,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      color: primaryTextColor,
                    ),
                  ),
                  if (widget.isRequired) ...[
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled && widget.onChanged != null
                    ? () => _openBottomSheet(context, formState)
                    : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.enabled
                        ? fieldBg
                        : (isDark ? const Color(0xFF141416) : const Color(0xFFF3F4F6)),
                    hintText: widget.hint ?? 'Select option',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: hintTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    helperText: widget.helperText,
                    helperStyle: AppTypography.captionMedium.copyWith(color: secondaryTextColor),
                    errorText: currentError,
                    errorMaxLines: 2,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                      vertical: widget.isDense ? AppDimensions.spacing8 : AppDimensions.spacing12,
                    ),
                    prefixIcon: prefixWidget,
                    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 40),
                    suffixIcon: suffixAffordance,
                    suffixIconConstraints: const BoxConstraints(minHeight: 40),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide(
                        color: hasError ? AppColors.error : borderColor,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide(
                        color: hasError ? AppColors.error : AppColors.primaryYellowDark,
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
                  isEmpty: widget.value == null,
                  child: widget.value != null
                      ? (widget.itemBuilder != null
                          ? widget.itemBuilder!(context, widget.value as T)
                          : Text(
                              _getItemLabel(widget.value as T),
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ))
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Modal BottomSheet Content Widget
class _AppDropdownBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final bool isClearable;
  final bool enableSearch;
  final double? maxHeight;

  const _AppDropdownBottomSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    this.itemLabel,
    this.itemBuilder,
    required this.isClearable,
    required this.enableSearch,
    this.maxHeight,
  });

  @override
  State<_AppDropdownBottomSheet<T>> createState() => _AppDropdownBottomSheetState<T>();
}

class _AppDropdownBottomSheetState<T> extends State<_AppDropdownBottomSheet<T>> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getItemLabel(T item) {
    if (widget.itemLabel != null) {
      return widget.itemLabel!(item);
    }
    return item?.toString() ?? '';
  }

  List<T> get _filteredItems {
    if (_searchQuery.trim().isEmpty) {
      return widget.items;
    }
    final q = _searchQuery.trim().toLowerCase();
    return widget.items.where((item) {
      final label = _getItemLabel(item).toLowerCase();
      return label.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final hintTextColor = isDark ? AppColors.darkHintText : AppColors.lightHintText;
    final sheetBg = isDark ? const Color(0xFF1B1B1E) : Colors.white;
    final searchBg = isDark ? const Color(0xFF26262B) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF2F2F36) : const Color(0xFFE5E7EB);

    final screenHeight = MediaQuery.of(context).size.height;
    final maxAllowedHeight = widget.maxHeight != null
        ? widget.maxHeight!.clamp(240.0, screenHeight * 0.85)
        : screenHeight * 0.72;

    final filtered = _filteredItems;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radius2xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxAllowedHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppDimensions.spacing12),
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF383840) : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                ),

                // Header Row (Title, Count Badge, Close Button)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spacing20,
                    AppDimensions.spacing12,
                    AppDimensions.spacing12,
                    AppDimensions.spacing8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing8,
                          vertical: AppDimensions.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryYellow.withValues(alpha: 0.12)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          '${widget.items.length}',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.primaryYellowLight : const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: secondaryTextColor,
                        splashRadius: 20,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Optional Search Box
                if (widget.enableSearch)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                      vertical: AppDimensions.spacing8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: AppTypography.bodyMedium.copyWith(color: primaryTextColor),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: searchBg,
                        hintText: 'Search in ${widget.title.toLowerCase()}...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: hintTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: secondaryTextColor,
                          size: AppDimensions.iconSm + 2,
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 16),
                                color: secondaryTextColor,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing12,
                          vertical: AppDimensions.spacing10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                // Quick Clear Selection bar if option is clearable
                if (widget.isClearable && widget.selectedValue != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                      vertical: AppDimensions.spacing4,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(const _DropdownResult.clear()),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing12,
                          vertical: AppDimensions.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.clear_all_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppDimensions.spacing8),
                            Text(
                              'Clear Selection',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Divider(height: 1),

                // Scrollable Item List
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: secondaryTextColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppDimensions.spacing8),
                              Text(
                                'No results match "$_searchQuery"',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: AppDimensions.spacing8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Text('Clear Search Filter'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.spacing16,
                            AppDimensions.spacing12,
                            AppDimensions.spacing16,
                            AppDimensions.spacing16,
                          ),
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.spacing6),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected = item == widget.selectedValue;
                            final labelText = _getItemLabel(item);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop(_DropdownResult<T>.select(item));
                                },
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacing14,
                                    vertical: AppDimensions.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.primaryYellow.withValues(alpha: 0.16)
                                            : const Color(0xFFFFFBEB))
                                        : (isDark
                                            ? const Color(0xFF222226)
                                            : const Color(0xFFF9FAFB)),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.primaryYellow.withValues(alpha: 0.6)
                                              : const Color(0xFFF59E0B))
                                          : borderColor,
                                      width: isSelected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: widget.itemBuilder != null
                                            ? widget.itemBuilder!(context, item)
                                            : Text(
                                                labelText,
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: isSelected
                                                      ? (isDark
                                                          ? AppColors.primaryYellowLight
                                                          : const Color(0xFFB45309))
                                                      : primaryTextColor,
                                                  fontWeight:
                                                      isSelected ? FontWeight.w600 : FontWeight.w400,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: AppDimensions.spacing10),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.primaryYellow
                                                : const Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF3F3F46)
                                                  : const Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
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
            ),
          ),
        ),
      ),
    );
  }
}
