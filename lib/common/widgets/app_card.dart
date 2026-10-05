import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/extensions/context_extensions.dart';

/// MYBIKE Base Surface Card
class AppCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableHover;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
    this.margin,
    this.onTap,
    this.enableHover = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.border,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final hasHeader = widget.title != null || widget.trailing != null;

    // When there is no header, pass the child through directly so it receives
    // the parent's (possibly bounded) constraints. Wrapping it in a
    // min-sized Column would give it unbounded height and break any
    // Spacer/Expanded used inside fixed-height cards (e.g. grid tiles).
    Widget cardBody = !hasHeader ? widget.child : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppDimensions.spacing2),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.captionMedium.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        widget.child,
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.fromBorderSide(
          widget.border ??
              BorderSide(
                color: _isHovered && widget.enableHover
                    ? (isDark ? AppColors.primaryYellow.withValues(alpha: 0.5) : AppColors.primaryYellowDark)
                    : defaultBorder,
                width: AppDimensions.borderWidth,
              ),
        ),
        boxShadow: _isHovered && widget.enableHover
            ? (isDark ? AppShadows.cardDark : AppShadows.dropdownLight)
            : (isDark ? AppShadows.cardDark : AppShadows.cardLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: widget.onTap,
          onHover: widget.enableHover ? (hovering) => setState(() => _isHovered = hovering) : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: widget.padding,
            child: cardBody,
          ),
        ),
      ),
    );
  }
}
