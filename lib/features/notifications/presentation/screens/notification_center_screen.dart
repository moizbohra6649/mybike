import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../widgets/notification_item_card.dart';
import '../widgets/notification_preferences_modal.dart';

/// Enterprise Notification Center Screen
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationCubit()..loadNotifications(),
      child: const _NotificationCenterContent(),
    );
  }
}

class _NotificationCenterContent extends StatelessWidget {
  const _NotificationCenterContent();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final cubit = context.read<NotificationCubit>();
        final filteredList = state.filteredNotifications;

        return AppScaffold(
          onRefresh: () => cubit.loadNotifications(),
          title: 'Notification Center',
          activeNavigationId: 'dashboard',
          actions: [
            if (state.unreadCount > 0)
              TextButton.icon(
                onPressed: () => cubit.markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Mark all read'),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Alert Preferences',
              onPressed: () {
                NotificationPreferencesModal.show(
                  context,
                  initialPreferences: state.preferences ??
                      const NotificationPreferenceEntity(id: 'default', userId: 'default'),
                  onSave: (prefs) => cubit.updatePreferences(prefs),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () => cubit.loadNotifications(),
            ),
            const SizedBox(width: 8),
          ],
          body: Column(
            children: [
              // ─── Filter Pills Bar ───
              _buildCategoryFilterBar(context, state, cubit, isDark),

              // ─── Unread Count Banner ───
              if (state.unreadCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryYellowDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You have ${state.unreadCount} unread notification${state.unreadCount > 1 ? 's' : ''} across your assigned showrooms.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => cubit.markAllAsRead(),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Dismiss all'),
                      ),
                    ],
                  ),
                ),

              // ─── Notifications List ───
              Expanded(
                child: state.status == NotificationStatus.loading
                    ? AppSkeleton.list(rows: 6)
                    : filteredList.isEmpty
                        ? _buildEmptyState(context, isDark, state.activeCategory)
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppDimensions.spacing16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final notification = filteredList[index];
                              return NotificationItemCard(
                                notification: notification,
                                onMarkRead: () => cubit.markAsRead(notification.id),
                                onDelete: () => cubit.deleteNotification(notification.id),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterBar(
    BuildContext context,
    NotificationState state,
    NotificationCubit cubit,
    bool isDark,
  ) {
    final categories = [
      {'id': 'all', 'label': 'All Alerts'},
      {'id': 'unread', 'label': 'Unread (${state.unreadCount})'},
      {'id': 'urgent', 'label': 'Urgent / Priority'},
      {'id': 'inventory', 'label': 'Inventory'},
      {'id': 'booking', 'label': 'Bookings'},
      {'id': 'sales', 'label': 'Sales'},
      {'id': 'finance', 'label': 'Finance'},
      {'id': 'gst', 'label': 'GST'},
      {'id': 'transfer', 'label': 'Transfers'},
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.activeCategory == cat['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat['label']!),
              selected: isSelected,
              onSelected: (_) => cubit.setCategoryFilter(cat['id']!),
              labelStyle: AppTypography.captionLarge.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.black
                    : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
              ),
              selectedColor: AppColors.primaryYellow,
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryYellow
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String activeCategory) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeCategory == 'all'
                  ? 'You are all caught up! There are no active alerts.'
                  : 'No notifications found for category "$activeCategory".',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
