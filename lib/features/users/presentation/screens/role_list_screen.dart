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
import '../../../../core/services/role_management_service.dart';
import '../cubit/role_management_cubit.dart';
import '../cubit/role_management_state.dart';

/// Role List Screen — Manage roles and permissions
class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  late final RoleManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = RoleManagementCubit()..loadRoles();
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
        onRefresh: _cubit.loadRoles,
        activeNavigationId: 'users',
        currentShowroomName: 'Administration',
        title: 'Roles & Permissions',
        body: BlocConsumer<RoleManagementCubit, RoleManagementState>(
          listener: (context, state) {
            if (state is RoleManagementError) {
              context.showErrorSnackBar(state.message);
            }
            if (state is RoleManagementDeleteSuccess) {
              context.showSuccessSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is RoleManagementLoading) {
              return AppSkeleton.list(rows: 7);
            }

            if (state is RoleManagementError) {
              return AppErrorState(
                title: 'Failed to Load Roles',
                message: state.message,
                onRetry: () => _cubit.loadRoles(),
              );
            }

            if (state is RoleManagementLoaded) {
              return _buildContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RoleManagementLoaded state) {
    final systemRoles = state.roles.where((r) => r.role.isSystemRole).toList();
    final customRoles = state.roles.where((r) => !r.role.isSystemRole).toList();

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          AppSectionHeader(
            title: 'Roles & Permissions',
            countBadge: state.roles.length,
            subtitle:
                'Configure role-based access control for dealership staff',
            trailing: AppButton.primary(
              label: 'New Custom Role',
              leadingIcon: Icons.add_rounded,
              onPressed: () async {
                await context.pushNamed(
                  RouteNames.roles,
                  queryParameters: {'action': 'create'},
                );
                _cubit.loadRoles();
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // ─── System Roles Section ───
          AppFormSection(
            title: 'System Roles',
            subtitle:
                '${systemRoles.length} built-in roles — cannot be renamed or deleted',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outlined, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text(
                    'PROTECTED',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            children: systemRoles.map((managedRole) {
              return _RoleCard(
                managedRole: managedRole,
                onViewPermissions: () async {
                  await context.pushNamed(
                    RouteNames.roles,
                    queryParameters: {
                      'action': 'edit',
                      'roleId': managedRole.role.id,
                    },
                  );
                  _cubit.loadRoles();
                },
                onDelete: null, // System roles can't be deleted
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Custom Roles Section ───
          AppFormSection(
            title: 'Custom Roles',
            subtitle: customRoles.isEmpty
                ? 'No custom roles defined. Create one to tailor access.'
                : '${customRoles.length} custom role${customRoles.length == 1 ? '' : 's'}',
            children: [
              if (customRoles.isEmpty)
                const AppEmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'No Custom Roles',
                  description:
                      'Create custom roles to define specific access patterns for your team.',
                )
              else
                ...customRoles.map((managedRole) {
                  return _RoleCard(
                    managedRole: managedRole,
                    onViewPermissions: () async {
                      await context.pushNamed(
                        RouteNames.roles,
                        queryParameters: {
                          'action': 'edit',
                          'roleId': managedRole.role.id,
                        },
                      );
                      _cubit.loadRoles();
                    },
                    onDelete: () async {
                      final confirmed = await AppConfirmDialog.show(
                        context,
                        title: 'Delete Role?',
                        message:
                            'Are you sure you want to delete "${managedRole.role.displayName}"? This cannot be undone and will unassign all users with this role.',
                        confirmText: 'Delete Role',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        _cubit.deleteRole(managedRole.role.id);
                      }
                    },
                  );
                }),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing40),
        ],
      ),
    );
  }
}

/// Individual Role Card
class _RoleCard extends StatelessWidget {
  final ManagedRole managedRole;
  final VoidCallback onViewPermissions;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.managedRole,
    required this.onViewPermissions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final role = managedRole.role;
    final permCount = role.permissions.length;
    final color = _roleColor(role.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing10),
      child: Material(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: onViewPermissions,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: context.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Role icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 22,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacing16),

                          // Role info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      role.displayName,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (role.isSystemRole)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'SYSTEM',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (role.description != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    role.description!,
                                    style: AppTypography.captionMedium.copyWith(
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
                      const SizedBox(height: AppDimensions.spacing16),
                      Row(
                        children: [
                          // Permission count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              '$permCount perm${permCount == 1 ? '' : 's'}',
                              style: AppTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacing12),

                          // User count
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${managedRole.userCount}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Actions
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 20),
                            tooltip: 'Manage Permissions',
                            onPressed: onViewPermissions,
                          ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.error,
                              ),
                              tooltip: 'Delete Role',
                              onPressed: onDelete,
                            ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Role icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 22,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing16),

                      // Role info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  role.displayName,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (role.isSystemRole) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SYSTEM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (role.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                role.description!,
                                style: AppTypography.captionMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.lightMutedText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Permission count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          '$permCount perm${permCount == 1 ? '' : 's'}',
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing12),

                      // User count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkMutedText
                                : AppColors.lightMutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${managedRole.userCount}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimensions.spacing12),

                      // Actions
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        tooltip: 'Manage Permissions',
                        onPressed: onViewPermissions,
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.error,
                          ),
                          tooltip: 'Delete Role',
                          onPressed: onDelete,
                        ),
                    ],
                  ),
          ),
        ),
      ),
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
      case 'service_manager':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
