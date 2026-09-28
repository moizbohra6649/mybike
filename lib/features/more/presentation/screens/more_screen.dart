import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/common.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// Item descriptor for the Enterprise Services Hub
class _HubServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;
  final String? badge;

  const _HubServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routeName,
    this.badge,
  });
}

/// Category section for the Enterprise Services Hub
class _HubCategorySection {
  final String title;
  final String description;
  final IconData icon;
  final List<_HubServiceItem> items;

  const _HubCategorySection({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
  });
}

/// Master "More" Screen — Enterprise Services Hub & Operational Command Launcher
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const List<_HubCategorySection> _sections = [
    _HubCategorySection(
      title: 'Dealership Operations & CRM',
      description: 'Customer lifecycle, bookings pipeline, showroom master & vehicle catalog',
      icon: Icons.storefront_rounded,
      items: [
        _HubServiceItem(
          title: 'Bookings & Advances',
          subtitle: 'Active customer orders, token advances & delivery dates',
          icon: Icons.bookmark_added_rounded,
          color: AppColors.primaryYellow,
          routeName: RouteNames.bookings,
          badge: 'Live',
        ),
        _HubServiceItem(
          title: 'Customers Directory',
          subtitle: 'Customer profiles, KYC verification & contact histories',
          icon: Icons.people_alt_rounded,
          color: AppColors.info,
          routeName: RouteNames.customers,
        ),
        _HubServiceItem(
          title: 'Vehicle Catalog Master',
          subtitle: 'Two-wheeler OEM models, variants, color specs & prices',
          icon: Icons.two_wheeler_rounded,
          color: AppColors.success,
          routeName: RouteNames.vehicles,
        ),
        _HubServiceItem(
          title: 'Showrooms & Branches',
          subtitle: 'Branch locations, regional hubs, sequences & settings',
          icon: Icons.apartment_rounded,
          color: AppColors.warning,
          routeName: RouteNames.showrooms,
        ),
      ],
    ),
    _HubCategorySection(
      title: 'Procurement & Logistics',
      description: 'Factory purchase orders, OEM vendor partners & stock movements',
      icon: Icons.local_shipping_rounded,
      items: [
        _HubServiceItem(
          title: 'Purchase Orders (PO)',
          subtitle: 'OEM factory purchase orders, lines & arrival tracking',
          icon: Icons.shopping_bag_rounded,
          color: AppColors.error,
          routeName: RouteNames.purchases,
          badge: 'Active',
        ),
        _HubServiceItem(
          title: 'OEM Suppliers Master',
          subtitle: 'Honda, Ather Energy, TVS Motors & vendor database',
          icon: Icons.factory_rounded,
          color: AppColors.info,
          routeName: RouteNames.suppliers,
        ),
        _HubServiceItem(
          title: 'Stock Inwarding (GRN)',
          subtitle: 'Inward vehicle batches, serialized VINs & PDI checks',
          icon: Icons.move_to_inbox_rounded,
          color: AppColors.success,
          routeName: RouteNames.stockInward,
        ),
        _HubServiceItem(
          title: 'Inter-Branch Stock Transfers',
          subtitle: 'Vehicle transfers between Mumbai, Pune & Bengaluru',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.primaryYellow,
          routeName: RouteNames.stockTransfer,
        ),
      ],
    ),
    _HubCategorySection(
      title: 'Finance, Accounts & Tax',
      description: 'Treasury cash/bank vouchers, OPEX petty cash, GST & statements',
      icon: Icons.account_balance_wallet_rounded,
      items: [
        _HubServiceItem(
          title: 'Treasury & Vouchers',
          subtitle: 'Payment, receipt & contra vouchers with journal links',
          icon: Icons.payments_rounded,
          color: AppColors.info,
          routeName: RouteNames.finance,
          badge: 'Ledger',
        ),
        _HubServiceItem(
          title: 'Petty Cash & OPEX Expenses',
          subtitle: 'Daily dealership operating costs & expense receipts',
          icon: Icons.receipt_rounded,
          color: AppColors.warning,
          routeName: RouteNames.expenses,
        ),
        _HubServiceItem(
          title: 'Chart of Accounts & Journals',
          subtitle: 'Financial ledger, journal vouchers & trial balances',
          icon: Icons.menu_book_rounded,
          color: AppColors.primaryYellow,
          routeName: RouteNames.chartOfAccounts,
        ),
        _HubServiceItem(
          title: 'GST & Statutory Tax Portal',
          subtitle: 'Automated GSTR-1, GSTR-3B summaries & tax matrices',
          icon: Icons.account_balance_rounded,
          color: AppColors.error,
          routeName: RouteNames.gstDashboard,
        ),
        _HubServiceItem(
          title: 'Financial & MIS Reports',
          subtitle: 'P&L statements, balance sheets, aged debt & cashflows',
          icon: Icons.analytics_rounded,
          color: AppColors.success,
          routeName: RouteNames.reports,
        ),
      ],
    ),
    _HubCategorySection(
      title: 'Governance & Enterprise Control',
      description: 'Multi-level approvals, digital document archive, audit trails & staff RBAC',
      icon: Icons.admin_panel_settings_rounded,
      items: [
        _HubServiceItem(
          title: 'Approvals Hub',
          subtitle: 'Authorize purchase orders, discounts & finance vouchers',
          icon: Icons.verified_rounded,
          color: AppColors.primaryYellow,
          routeName: RouteNames.approvals,
          badge: 'Pending',
        ),
        _HubServiceItem(
          title: 'Document DMS Vault',
          subtitle: 'Digital vehicle file archives, RTO records & delivery passes',
          icon: Icons.folder_shared_rounded,
          color: AppColors.info,
          routeName: RouteNames.documents,
        ),
        _HubServiceItem(
          title: 'Audit Trail & Event Logs',
          subtitle: 'Immutable system audit logs & security access trails',
          icon: Icons.security_rounded,
          color: AppColors.error,
          routeName: RouteNames.auditLogs,
        ),
        _HubServiceItem(
          title: 'Staff & User Management',
          subtitle: 'Dealership staff directory, branch assignments & access',
          icon: Icons.manage_accounts_rounded,
          color: AppColors.success,
          routeName: RouteNames.users,
        ),
        _HubServiceItem(
          title: 'Roles & RBAC Privileges',
          subtitle: 'Granular permissions matrix for sales, finance & admins',
          icon: Icons.lock_person_rounded,
          color: AppColors.warning,
          routeName: RouteNames.roles,
        ),
        _HubServiceItem(
          title: 'System Settings',
          subtitle: 'Dealership company profile, currency & global settings',
          icon: Icons.settings_rounded,
          color: AppColors.lightSecondaryText,
          routeName: RouteNames.settings,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isDesktop = context.isDesktop;

    return AppScaffold(
      activeNavigationId: 'more',
      title: 'Enterprise Services Hub',
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppDimensions.spacing32 : AppDimensions.spacing16,
          vertical: AppDimensions.spacing20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile & Active Showroom Hero Card
            _buildProfileAndBranchCard(context, isDark, isDesktop),
            const SizedBox(height: AppDimensions.spacing20),

            // 2. Quick Operations Launchpad Bar
            _buildQuickOperationsBar(context, isDark),
            const SizedBox(height: AppDimensions.spacing24),

            // 3. Categorized Service Hub Sections
            for (final section in _sections) ...[
              _buildCategoryHeader(section, isDark),
              const SizedBox(height: AppDimensions.spacing12),
              _buildServicesGrid(context, section.items, isDesktop, isDark),
              const SizedBox(height: AppDimensions.spacing24),
            ],

            // 4. System Info & Preferences Footer Card
            _buildSystemFooterCard(context, isDark),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }

  // ─── 1. Profile & Branch Hero Card ───
  Widget _buildProfileAndBranchCard(BuildContext context, bool isDark, bool isDesktop) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String fullName = 'Dealership Administrator';
        String email = 'admin@mybike.in';
        String roleName = 'Enterprise Admin';
        String branchName = 'Multi-Branch Enterprise';
        String branchCity = 'National Network';

        if (authState is Authenticated) {
          fullName = authState.profile.fullName ?? authState.profile.email;
          email = authState.profile.email;
          roleName = authState.profile.isSuperAdmin
              ? 'Super Admin'
              : (authState.profile.isAdmin
                  ? 'Admin'
                  : (authState.profile.roles.isNotEmpty
                      ? authState.profile.roles.first.replaceAll('_', ' ').toUpperCase()
                      : 'Staff'));
          branchName = authState.activeShowroom.name;
          branchCity = '${authState.activeShowroom.city}, ${authState.activeShowroom.state}';
        } else {
          final supUser = SupabaseService.currentUser;
          if (supUser != null) {
            email = supUser.email ?? email;
            fullName = (supUser.userMetadata?['full_name'] as String?) ?? email.split('@').first;
          }
        }

        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M';

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacing20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E222B),
                      const Color(0xFF161920),
                    ]
                  : [
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF8F9FA),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with Gold Accent Ring
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryYellow, Color(0xFFFFA000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryYellow.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                border: Border.all(
                                  color: AppColors.primaryYellow.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                roleName,
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: AppDimensions.spacing12),

              // Active Showroom Branch Pill & Quick Branch Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branchName,
                            style: AppTypography.captionLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            branchCity,
                            style: AppTypography.captionSmall.copyWith(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.goNamed(RouteNames.showroomSelection),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_alt_rounded,
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Switch Branch',
                            style: AppTypography.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 2. Quick Operations Launchpad Bar ───
  Widget _buildQuickOperationsBar(BuildContext context, bool isDark) {
    final actions = [
      {
        'label': 'New Booking',
        'icon': Icons.bookmark_add_rounded,
        'color': AppColors.primaryYellow,
        'route': RouteNames.customerCreate,
      },
      {
        'label': 'New Sale Invoice',
        'icon': Icons.post_add_rounded,
        'color': AppColors.info,
        'route': RouteNames.saleCreate,
      },
      {
        'label': 'Inward Vehicle',
        'icon': Icons.add_business_rounded,
        'color': AppColors.success,
        'route': RouteNames.stockInward,
      },
      {
        'label': 'Create PO',
        'icon': Icons.add_shopping_cart_rounded,
        'color': AppColors.error,
        'route': RouteNames.purchaseCreate,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'QUICK OPERATIONS LAUNCHPAD',
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions.map((act) {
              final color = act['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => context.goNamed(act['route'] as String),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222B) : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(act['icon'] as IconData, size: 15, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          act['label'] as String,
                          style: AppTypography.captionLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── 3. Category Header ───
  Widget _buildCategoryHeader(_HubCategorySection section, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(section.icon, size: 16, color: AppColors.primaryYellow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  section.description,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Services Grid ───
  Widget _buildServicesGrid(
    BuildContext context,
    List<_HubServiceItem> items,
    bool isDesktop,
    bool isDark,
  ) {
    if (isDesktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 84,
              crossAxisSpacing: 14,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _buildServiceTile(context, items[index], isDark),
          );
        },
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildServiceTile(context, items[i], isDark),
        ],
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, _HubServiceItem item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed(item.routeName),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222B) : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(width: AppDimensions.spacing14),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Text(
                              item.badge!,
                              style: AppTypography.captionSmall.copyWith(
                                color: item.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. System Footer Card ───
  Widget _buildSystemFooterCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161920) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF242832) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Supabase Cloud Connected • Live Sync',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: AppColors.primaryYellow,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MYBIKE ERP Enterprise • v2.5.0',
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
              InkWell(
                onTap: () {
                  AppConfirmDialog.show(
                    context,
                    title: 'Sign Out?',
                    message: 'Are you sure you want to log out of your MYBIKE Dealership session?',
                    confirmText: 'Sign Out',
                    isDestructive: true,
                  ).then((confirmed) {
                    if (confirmed == true && context.mounted) {
                      context.read<AuthCubit>().logout();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Sign Out',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
