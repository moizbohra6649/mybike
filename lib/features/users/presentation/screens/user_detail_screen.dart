import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/user_management_service.dart';

/// User Detail Screen — Read-only profile view
class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  ManagedUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserManagementService.instance.fetchUserById(
        widget.userId,
      );
      if (user == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      onRefresh: _loadUser,
      activeNavigationId: 'users',
      currentShowroomName: 'User Management',
      title: 'User Profile',
      actions: [
        if (_user != null)
          AppButton.secondary(
            label: 'Edit',
            leadingIcon: Icons.edit_outlined,
            onPressed: () async {
              await context.pushNamed(
                RouteNames.userCreate,
                queryParameters: {'editId': _user!.profile.id},
              );
              _loadUser();
            },
          ),
        const SizedBox(width: 8),
        AppButton.ghost(
          label: 'Back',
          leadingIcon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
        ),
      ],
      body: _isLoading
          ? AppSkeleton.detail()
          : _error != null
          ? AppErrorState(title: 'Error', message: _error!, onRetry: _loadUser)
          : _buildProfile(context),
    );
  }

  Widget _buildProfile(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    final user = _user!;
    final isDark = context.isDarkMode;

    final initials = (user.profile.fullName ?? user.profile.email)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Profile Header Card ───
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryYellow.withValues(
                    alpha: 0.2,
                  ),
                  child: Text(
                    initials,
                    style: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryYellowDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppDimensions.spacing12,
                        runSpacing: AppDimensions.spacing4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            user.profile.fullName ?? 'Unnamed',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppStatusBadge(
                            label: user.profile.isActive
                                ? 'Active'
                                : 'Inactive',
                            color: user.profile.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing4),
                      Text(
                        user.profile.email,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                      if (user.profile.phone != null) ...[
                        const SizedBox(height: AppDimensions.spacing2),
                        Text(
                          user.profile.phone!,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkMutedText
                                : AppColors.lightMutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Roles & Showrooms Grid ───
          if (context.isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRolesCard(user),
                const SizedBox(height: AppDimensions.spacing16),
                _buildShowroomsCard(user, isDark),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRolesCard(user)),
                const SizedBox(width: AppDimensions.spacing16),
                Expanded(child: _buildShowroomsCard(user, isDark)),
              ],
            ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Account Info ───
          AppCard(
            title: 'Account Information',
            child: context.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: _formatDate(user.profile.createdAt),
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                      _InfoItem(
                        icon: Icons.update_outlined,
                        label: 'Last Updated',
                        value: _formatDate(user.profile.updatedAt),
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                      _InfoItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'User ID',
                        value: user.profile.id.length > 12
                            ? '${user.profile.id.substring(0, 12)}...'
                            : user.profile.id,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created',
                          value: _formatDate(user.profile.createdAt),
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.update_outlined,
                          label: 'Last Updated',
                          value: _formatDate(user.profile.updatedAt),
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.fingerprint_rounded,
                          label: 'User ID',
                          value: user.profile.id.length > 12
                              ? '${user.profile.id.substring(0, 12)}...'
                              : user.profile.id,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppDimensions.spacing40),
        ],
      ),
    );
  }

  Widget _buildRolesCard(ManagedUser user) {
    return AppCard(
      title: 'Assigned Roles',
      subtitle:
          '${user.roles.length} role${user.roles.length == 1 ? '' : 's'} assigned',
      child: user.roles.isEmpty
          ? Text(
              'No roles',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightMutedText,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.roles.map((role) {
                final color = _roleColor(role.name);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: color),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            role.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          if (role.isSystemRole)
                            Text(
                              'System Role',
                              style: AppTypography.captionSmall.copyWith(
                                color: color.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildShowroomsCard(ManagedUser user, bool isDark) {
    return AppCard(
      title: 'Showroom Access',
      subtitle:
          '${user.showrooms.length} showroom${user.showrooms.length == 1 ? '' : 's'} assigned',
      child: user.showrooms.isEmpty
          ? Text(
              'No showrooms',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightMutedText,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: user.showrooms.map((showroom) {
                final isDefault = showroom.id == user.defaultShowroomId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      border: Border.all(
                        color: isDefault
                            ? AppColors.primaryYellow.withValues(alpha: 0.5)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            showroom.code,
                            style: AppTypography.captionSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryYellowDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showroom.name,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${showroom.city}, ${showroom.state}',
                                style: AppTypography.captionMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.lightMutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: AppColors.primaryYellow,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Default',
                                  style: AppTypography.captionSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _roleColor(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return const Color(0xFFEF4444);
      case 'admin':
        return const Color(0xFFF59E0B);
      case 'showroom_manager':
        return const Color(0xFF3B82F6);
      case 'sales_executive':
      case 'sales_manager':
        return const Color(0xFF10B981);
      case 'accountant':
      case 'cashier':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.captionMedium.copyWith(
                color: isDark
                    ? AppColors.darkMutedText
                    : AppColors.lightMutedText,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
