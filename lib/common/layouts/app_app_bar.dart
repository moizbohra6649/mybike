import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/extensions/context_extensions.dart';
import '../components/search_filters/global_search_modal.dart';

/// MYBIKE Top Header Bar
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showShowroomSelector;
  final String currentShowroomName;
  final VoidCallback? onShowroomSwitchTap;
  final VoidCallback? onNotificationTap;
  final int unreadNotificationsCount;
  final VoidCallback? onMenuTap;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showShowroomSelector = true,
    this.currentShowroomName = 'Central Showroom',
    this.onShowroomSwitchTap,
    this.onNotificationTap,
    this.unreadNotificationsCount = 2,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  /// Actions compact enough to keep in the bar itself on a narrow screen.
  List<Widget> get _inlineActions => (actions ?? const <Widget>[])
      .where((action) => action is IconButton || action is PopupMenuButton)
      .toList();

  /// Actions that have to move into the overflow sheet on a narrow screen.
  /// `SizedBox` spacers between actions are dropped — it spaces its own
  /// children.
  List<Widget> get _overflowActions {
    final inline = _inlineActions;
    return (actions ?? const <Widget>[])
        .where((action) => !inline.contains(action) && action is! SizedBox)
        .toList();
  }

  /// Opens the page actions that did not fit in the bar, laid out at full
  /// width so their labels stay readable.
  void _showActionsSheet(BuildContext context) {
    final isDark = context.isDarkMode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing20,
            AppDimensions.spacing12,
            AppDimensions.spacing20,
            AppDimensions.spacing24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing20),
              for (final action in _overflowActions) ...[
                // Close the sheet on the way into the action. These navigate
                // through the router underneath, which would otherwise leave the
                // sheet sitting on top of the screen it just opened.
                Listener(
                  onPointerUp: (_) => Navigator.of(sheetContext).pop(),
                  child: action,
                ),
                const SizedBox(height: AppDimensions.spacing12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: AppDimensions.borderWidth,
            ),
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          left: true,
          right: true,
          child: SizedBox(
            height: AppDimensions.appBarHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppDimensions.spacing12 : AppDimensions.spacing24,
              ),
              child: Row(
                children: [
          if (onMenuTap != null) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              onPressed: onMenuTap,
              tooltip: 'Navigation Menu',
              visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
            ),
            SizedBox(width: isMobile ? AppDimensions.spacing4 : AppDimensions.spacing8),
          ],
          if (titleWidget != null)
            Expanded(child: titleWidget!)
          else if (title != null)
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 18 : 20,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            )
          else
            const Spacer(),
          // Showroom Selector (Desktop / Tablet only, in Drawer or Profile menu on mobile)
          if (showShowroomSelector && !isMobile) ...[
            InkWell(
              onTap: onShowroomSwitchTap ??
                  () {
                    context.showSnackBar('Showroom switcher active: $currentShowroomName');
                  },
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                  vertical: AppDimensions.spacing6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: AppDimensions.iconSm,
                      color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        currentShowroomName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
          ],
          // Global Search Trigger
          if (context.isDesktop)
            InkWell(
              onTap: () => GlobalSearchModal.show(context),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing10,
                  vertical: AppDimensions.spacing6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      size: AppDimensions.iconSm,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Text(
                      'Search ERP...',
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        'Ctrl+K',
                        style: AppTypography.captionSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!isMobile)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              iconSize: AppDimensions.iconMd,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              tooltip: 'Search ERP (Ctrl+K)',
              onPressed: () => GlobalSearchModal.show(context),
            ),
          if (!isMobile) const SizedBox(width: AppDimensions.spacing8),
          // Theme Toggle (Desktop only; on mobile accessible via User Profile menu)
          if (!isMobile)
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                final isThemeDark = state.themeMode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(
                    isThemeDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: AppDimensions.iconMd,
                  ),
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  tooltip: isThemeDark ? 'Switch to light mode' : 'Switch to dark mode',
                  onPressed: () {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
          // Notifications
          StreamBuilder<int>(
            stream: NotificationService.instance.unreadCountStream,
            initialData: NotificationService.instance.unreadCount,
            builder: (context, snapshot) {
              final count = snapshot.data ?? unreadNotificationsCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    iconSize: AppDimensions.iconMd,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    tooltip: 'Notifications',
                    visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                    onPressed: onNotificationTap ?? () => context.push('/notifications'),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: AppDimensions.spacing8),
          // User Avatar & Menu
          PopupMenuButton<String>(
            tooltip: 'User profile',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin User',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    Text(
                      'admin@mybike.com',
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (isMobile && showShowroomSelector) ...[
                PopupMenuItem<String>(
                  value: 'showroom',
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primaryYellowDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentShowroomName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              if (isMobile) ...[
                PopupMenuItem<String>(
                  value: 'search',
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Search ERP'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
                      const SizedBox(width: 12),
                      Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                // Sign out before navigating: leaving the session, permissions
                // and showroom access in place meant the next login inherited
                // the previous user's scope.
                await AuthService.instance.signOut();
                if (!context.mounted) return;
                context.goNamed(RouteNames.login);
              } else if (val == 'settings') {
                context.goNamed(RouteNames.settings);
              } else if (val == 'theme') {
                context.read<ThemeCubit>().toggleTheme();
              } else if (val == 'search') {
                GlobalSearchModal.show(context);
              } else if (val == 'showroom') {
                if (onShowroomSwitchTap != null) {
                  onShowroomSwitchTap!();
                } else {
                  context.showSnackBar('Showroom: $currentShowroomName');
                }
              }
            },
            child: CircleAvatar(
              radius: isMobile ? 15 : 18,
              backgroundColor: AppColors.primaryYellow,
              child: Text(
                'MB',
                style: TextStyle(
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            SizedBox(width: isMobile ? AppDimensions.spacing4 : AppDimensions.spacing8),
            if (isDesktop)
              ...actions!
            else ...[
              // Text buttons ("Trial Balance", "New Voucher") are far too wide
              // to sit beside the title on a phone — three of them overflow the
              // bar by ~150px. Below desktop they collapse into an overflow menu
              // that opens the full-size actions in a bottom sheet; icon-only
              // actions stay inline, where they still fit.
              ..._inlineActions,
              if (_overflowActions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  iconSize: AppDimensions.iconMd,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  tooltip: 'More actions',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showActionsSheet(context),
                ),
            ],
          ],
        ],
      ),
    ),
  ),
),
),
);
}
}
