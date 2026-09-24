import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/indian_currency_formatter.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/supplier_management_service.dart';
import '../../domain/entities/supplier_entity.dart';
import '../cubit/supplier_list_cubit.dart';
import '../cubit/supplier_list_state.dart';

/// Supplier List Screen — vendor master for OEMs, spare-part distributors and
/// service vendors, with KPIs, search and category filters.
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late final SupplierListCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = SupplierListCubit()..loadSuppliers();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        activeNavigationId: 'suppliers',
        currentShowroomName: 'Procurement',
        title: 'Supplier Management',
        body: BlocConsumer<SupplierListCubit, SupplierListState>(
          listener: (context, state) {
            if (state is SupplierListError) {
              context.showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is SupplierListLoading) {
              return AppSkeleton.list(kpis: 4, rows: 6);
            }

            if (state is SupplierListError) {
              return AppErrorState(
                title: 'Failed to Load Suppliers',
                message: state.message,
                onRetry: () => _cubit.loadSuppliers(refresh: true),
              );
            }

            if (state is SupplierListLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, SupplierListLoaded state) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          AppSectionHeader(
            title: 'Vendors & Suppliers',
            countBadge: state.totalCount,
            subtitle:
                'OEMs, spare-part distributors and service vendors, with credit limits and payment terms',
            trailing: AppButton.primary(
              label: 'Add Supplier',
              leadingIcon: Icons.add_business_rounded,
              onPressed: () async {
                await context.pushNamed(RouteNames.supplierCreate);
                _cubit.loadSuppliers(refresh: true);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Stat KPI Cards ───
          AppResponsiveGrid(
            minItemWidth: 200,
            children: [
              AppStatCard(
                title: 'Total Vendors',
                value: state.totalCount.toString(),
                icon: Icons.local_shipping_outlined,
                iconColor: AppColors.primaryYellow,
              ),
              AppStatCard(
                title: 'Active',
                value: state.activeCount.toString(),
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
              ),
              AppStatCard(
                title: 'OEM Partners',
                value: state.oemCount.toString(),
                icon: Icons.factory_outlined,
                iconColor: AppColors.info,
              ),
              AppStatCard(
                title: 'Opening Payable',
                value: IndianCurrencyFormatter.formatIndianCurrency(
                  state.totalPayable,
                  showSymbol: true,
                ).trim(),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Toolbar: Search & Filters ───
          Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search by name, code, GSTIN, phone...',
                  onChanged: (val) => _cubit.searchSuppliers(val),
                  onClear: () {
                    _searchController.clear();
                    _cubit.searchSuppliers('');
                  },
                ),
              ),

              SizedBox(
                width: 240,
                child: AppDropdown<String>(
                  hint: 'All Categories',
                  value: state.typeFilter,
                  items: SupplierManagementService.supplierTypes,
                  itemLabel: SupplierManagementService.typeLabel,
                  prefixIcon: Icons.category_outlined,
                  onChanged: (val) => _cubit.filterByType(val),
                ),
              ),

              FilterChip(
                label: const Text('All Vendors'),
                selected: state.activeFilter == null,
                onSelected: (_) => _cubit.filterByActive(null),
              ),
              FilterChip(
                label: const Text('Active Only'),
                selected: state.activeFilter == true,
                onSelected: (_) => _cubit.filterByActive(true),
              ),
              FilterChip(
                label: const Text('Inactive Only'),
                selected: state.activeFilter == false,
                onSelected: (_) => _cubit.filterByActive(false),
              ),

              if (state.searchQuery != null ||
                  state.activeFilter != null ||
                  state.typeFilter != null)
                ActionChip(
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  onPressed: () {
                    _searchController.clear();
                    _cubit.clearFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Vendor Grid ───
          if (state.suppliers.isEmpty)
            const AppEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No Suppliers Found',
              description: 'No vendors match the current search or filter criteria.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveUtils.gridCrossAxisCount(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.suppliers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppDimensions.spacing16,
                    mainAxisSpacing: AppDimensions.spacing16,
                    mainAxisExtent: 268,
                  ),
                  itemBuilder: (context, index) {
                    final supplier = state.suppliers[index];

                    return _SupplierCard(
                      supplier: supplier,
                      onViewDetails: () async {
                        await context.pushNamed(
                          RouteNames.supplierDetail,
                          pathParameters: {'supplierId': supplier.id},
                        );
                        _cubit.loadSuppliers(refresh: true);
                      },
                      onEdit: () async {
                        await context.pushNamed(
                          RouteNames.supplierCreate,
                          queryParameters: {'editId': supplier.id},
                        );
                        _cubit.loadSuppliers(refresh: true);
                      },
                      onToggleStatus: () => _cubit.toggleSupplierStatus(
                        supplier.id,
                        !supplier.isActive,
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Vendor card — identity, category, contact and commercial terms at a glance.
class _SupplierCard extends StatelessWidget {
  final SupplierEntity supplier;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _SupplierCard({
    required this.supplier,
    required this.onViewDetails,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mutedColor = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Code, Category, Status ───
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  supplier.code,
                  style: AppTypography.captionLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.primaryYellowLight : AppColors.primaryYellowDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              AppStatusBadge.fromStatus(supplier.isActive ? 'active' : 'inactive'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // ─── Name & Category ───
          Text(
            supplier.name,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            SupplierManagementService.typeLabel(supplier.supplierType),
            style: AppTypography.bodySmall.copyWith(color: mutedColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // ─── Contact ───
          if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
            _IconLine(
              icon: Icons.person_outline_rounded,
              text: supplier.contactPerson!,
              color: mutedColor,
            ),
          _IconLine(
            icon: Icons.phone_outlined,
            text: supplier.phone,
            color: mutedColor,
          ),
          if (supplier.location.isNotEmpty)
            _IconLine(
              icon: Icons.location_on_outlined,
              text: supplier.location,
              color: mutedColor,
            ),

          const Spacer(),

          // ─── Commercial Terms ───
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (supplier.gstin != null && supplier.gstin!.isNotEmpty)
                _ChipTag(icon: Icons.receipt_long_outlined, text: 'GSTIN set'),
              _ChipTag(
                icon: Icons.schedule_rounded,
                text: 'Net ${supplier.paymentTermsDays}d',
              ),
              if (supplier.creditLimit > 0)
                _ChipTag(
                  icon: Icons.account_balance_wallet_outlined,
                  text: IndianCurrencyFormatter.formatIndianCurrency(
                    supplier.creditLimit,
                    showSymbol: true,
                  ).trim(),
                ),
              if (supplier.isShared)
                const _ChipTag(icon: Icons.hub_outlined, text: 'All Branches'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.spacing8),

          // ─── Actions ───
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Details',
                  leadingIcon: Icons.visibility_outlined,
                  size: AppButtonSize.small,
                  onPressed: onViewDetails,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Supplier',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                onPressed: onEdit,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  supplier.isActive
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_outlined,
                  size: 22,
                  color: supplier.isActive ? AppColors.success : AppColors.error,
                ),
                tooltip: supplier.isActive ? 'Deactivate Vendor' : 'Activate Vendor',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                onPressed: onToggleStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _IconLine({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.captionLarge.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChipTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
        ],
      ),
    );
  }
}
