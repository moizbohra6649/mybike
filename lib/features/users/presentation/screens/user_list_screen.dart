import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/user_management_service.dart';
import '../cubit/user_management_cubit.dart';
import '../cubit/user_management_state.dart';

/// User List Screen — Admin CRUD for all dealership users
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late final UserManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = UserManagementCubit()..loadUsers();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        activeNavigationId: 'users',
        currentShowroomName: 'All Showrooms',
        title: 'User Management',
        body: BlocConsumer<UserManagementCubit, UserManagementState>(
          listener: (context, state) {
            if (state is UserManagementError) {
              context.showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is UserManagementLoading) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            if (state is UserManagementError) {
              return AppErrorState(
                title: 'Failed to Load Users',
                message: state.message,
                onRetry: () => _cubit.loadUsers(),
              );
            }

            if (state is UserManagementLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, UserManagementLoaded state) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          AppSectionHeader(
            title: 'Users',
            countBadge: state.totalCount,
            subtitle: 'Manage dealership staff accounts, roles, and showroom access',
            trailing: AppButton.primary(
              label: 'Add User',
              leadingIcon: Icons.person_add_outlined,
              onPressed: () async {
                await context.pushNamed(RouteNames.userCreate);
                _cubit.loadUsers();
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // ─── Filters Toolbar ───
          AppDashboardCard(
            title: 'Staff Directory',
            subtitle: 'Search and filter across all showroom staff',
            headerAction: AppSearchField(
              hint: 'Search name or email...',
              width: context.isMobile ? 180 : 280,
              onChanged: (val) => _cubit.searchUsers(val),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters Row
                Wrap(
                  spacing: AppDimensions.spacing12,
                  runSpacing: AppDimensions.spacing12,
                  children: [
                    // Role filter
                    _FilterChip(
                      label: state.roleFilter != null
                          ? _displayRoleName(state.roleFilter!)
                          : 'All Roles',
                      icon: Icons.admin_panel_settings_outlined,
                      isActive: state.roleFilter != null,
                      onTap: () => _showRoleFilterMenu(context, state.roleFilter),
                    ),
                    // Active filter
                    _FilterChip(
                      label: state.activeFilter == null
                          ? 'All Status'
                          : (state.activeFilter! ? 'Active' : 'Inactive'),
                      icon: Icons.toggle_on_outlined,
                      isActive: state.activeFilter != null,
                      onTap: () => _showActiveFilterMenu(context, state.activeFilter),
                    ),
                    // Clear filters
                    if (state.searchQuery != null || state.roleFilter != null || state.activeFilter != null)
                      ActionChip(
                        label: Text(
                          'Clear Filters',
                          style: AppTypography.captionLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        onPressed: () => _cubit.clearFilters(),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing20),

                // ─── Users Table ───
                if (state.users.isEmpty)
                  const AppEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Users Found',
                    description: 'No users match the current filters. Try adjusting your search.',
                  )
                else
                  AppDataTable<ManagedUser>(
                    minWidth: 800,
                    columns: [
                      AppDataColumn<ManagedUser>(
                        title: 'User',
                        flex: 3,
                        cellBuilder: (context, user) => _UserCell(user: user),
                      ),
                      AppDataColumn<ManagedUser>(
                        title: 'Role',
                        flex: 2,
                        cellBuilder: (context, user) => _RoleBadges(user: user),
                      ),
                      AppDataColumn<ManagedUser>(
                        title: 'Showrooms',
                        flex: 2,
                        cellBuilder: (context, user) => _ShowroomBadges(user: user),
                      ),
                      AppDataColumn<ManagedUser>(
                        title: 'Status',
                        flex: 1,
                        cellBuilder: (context, user) => AppStatusBadge(
                          label: user.profile.isActive ? 'Active' : 'Inactive',
                          color: user.profile.isActive ? AppColors.success : AppColors.error,
                        ),
                      ),
                      AppDataColumn<ManagedUser>(
                        title: 'Actions',
                        flex: 1,
                        cellBuilder: (context, user) => _ActionButtons(
                          user: user,
                          onView: () async {
                            await context.pushNamed(
                              RouteNames.userDetail,
                              pathParameters: {'userId': user.profile.id},
                            );
                            _cubit.loadUsers();
                          },
                          onEdit: () async {
                            await context.pushNamed(
                              RouteNames.userCreate,
                              queryParameters: {'editId': user.profile.id},
                            );
                            _cubit.loadUsers();
                          },
                          onToggleActive: () async {
                            final currentUser = user;
                            final confirmed = await AppConfirmDialog.show(
                              context,
                              title: currentUser.profile.isActive ? 'Deactivate User?' : 'Activate User?',
                              message: currentUser.profile.isActive
                                  ? 'This will prevent ${currentUser.profile.fullName ?? currentUser.profile.email} from logging in.'
                                  : 'This will restore login access for ${currentUser.profile.fullName ?? currentUser.profile.email}.',
                              confirmText: currentUser.profile.isActive ? 'Deactivate' : 'Activate',
                              isDestructive: currentUser.profile.isActive,
                            );
                            if (confirmed == true) {
                              _cubit.toggleUserActive(currentUser.profile.id, !currentUser.profile.isActive);
                            }
                          },
                        ),
                      ),
                    ],
                    items: state.users,
                  ),

                const SizedBox(height: AppDimensions.spacing16),

                // ─── Pagination ───
                if (state.users.isNotEmpty)
                  AppPagination(
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    totalRecords: state.totalCount,
                    pageSize: state.pageSize,
                    onPageChanged: (p) => _cubit.changePage(p),
                    onPageSizeChanged: (s) => _cubit.changePageSize(s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing40),
        ],
      ),
    );
  }

  String _displayRoleName(String roleName) {
    return roleName.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  void _showRoleFilterMenu(BuildContext context, String? currentFilter) {
    final roles = [
      null,
      'super_admin',
      'admin',
      'showroom_manager',
      'sales_manager',
      'sales_executive',
      'purchase_manager',
      'inventory_manager',
      'accountant',
      'cashier',
      'service_manager',
      'viewer',
    ];

    showMenu<String?>(
      context: context,
      position: RelativeRect.fromLTRB(200, 200, 300, 300),
      items: roles.map((role) {
        final label = role == null ? 'All Roles' : _displayRoleName(role);
        return PopupMenuItem<String?>(
          value: role,
          child: Row(
            children: [
              if (role == currentFilter)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryYellow)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != currentFilter) {
        _cubit.filterByRole(value);
      }
    });
  }

  void _showActiveFilterMenu(BuildContext context, bool? currentFilter) {
    showMenu<bool?>(
      context: context,
      position: RelativeRect.fromLTRB(350, 200, 450, 300),
      items: [
        PopupMenuItem<bool?>(
          value: null,
          child: Row(
            children: [
              if (currentFilter == null)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryYellow)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('All Status'),
            ],
          ),
        ),
        PopupMenuItem<bool?>(
          value: true,
          child: Row(
            children: [
              if (currentFilter == true)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryYellow)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('Active Only'),
            ],
          ),
        ),
        PopupMenuItem<bool?>(
          value: false,
          child: Row(
            children: [
              if (currentFilter == false)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryYellow)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('Inactive Only'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != currentFilter) {
        _cubit.toggleActiveFilter(value);
      }
    });
  }
}

// ─── Helper Widgets ───

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: isActive
          ? AppColors.primaryYellow.withValues(alpha: isDark ? 0.2 : 0.15)
          : (isDark ? AppColors.darkCard : AppColors.lightCard),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryYellow.withValues(alpha: 0.6)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? AppColors.primaryYellow : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.captionLarge.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark)
                      : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCell extends StatelessWidget {
  final ManagedUser user;
  const _UserCell({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final initials = (user.profile.fullName ?? user.profile.email)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryYellowDark,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.profile.fullName ?? 'Unnamed',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.profile.email,
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBadges extends StatelessWidget {
  final ManagedUser user;
  const _RoleBadges({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.roles.isEmpty) {
      return Text(
        'No role',
        style: AppTypography.captionMedium.copyWith(color: AppColors.lightMutedText),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: user.roles.take(2).map((role) {
        final color = _roleColor(role.name);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            role.displayName,
            style: AppTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
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
      case 'inventory_manager':
      case 'purchase_manager':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _ShowroomBadges extends StatelessWidget {
  final ManagedUser user;
  const _ShowroomBadges({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    if (user.showrooms.isEmpty) {
      return Text(
        'None',
        style: AppTypography.captionMedium.copyWith(color: AppColors.lightMutedText),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...user.showrooms.take(2).map((s) {
          final isDefault = s.id == user.defaultShowroomId;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: isDefault ? AppColors.primaryYellow.withValues(alpha: 0.5) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDefault) ...[
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.primaryYellow),
                  const SizedBox(width: 3),
                ],
                Text(
                  s.code,
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          );
        }),
        if (user.showrooms.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '+${user.showrooms.length - 2}',
              style: AppTypography.captionSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryYellowDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ManagedUser user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _ActionButtons({
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'View Details',
          onPressed: onView,
          splashRadius: 18,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          tooltip: 'More Actions',
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
            PopupMenuItem(
              value: 'toggle',
              child: Row(children: [
                Icon(user.profile.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                const SizedBox(width: 8),
                Text(user.profile.isActive ? 'Deactivate' : 'Activate'),
              ]),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'toggle') onToggleActive();
          },
        ),
      ],
    );
  }
}
