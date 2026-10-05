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
import '../../../../core/services/showroom_service.dart';
import '../../domain/entities/invoice_sequence_entity.dart';
import '../../../../core/services/user_management_service.dart';
import '../cubit/showroom_detail_cubit.dart';
import '../cubit/showroom_detail_state.dart';

/// Showroom Detail Screen — Comprehensive branch profile, mapped staff, and sequential document counters
class ShowroomDetailScreen extends StatefulWidget {
  final String showroomId;

  const ShowroomDetailScreen({super.key, required this.showroomId});

  @override
  State<ShowroomDetailScreen> createState() => _ShowroomDetailScreenState();
}

class _ShowroomDetailScreenState extends State<ShowroomDetailScreen> {
  late final ShowroomDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ShowroomDetailCubit()..loadShowroomDetail(widget.showroomId);
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
        onRefresh: () => _cubit.loadShowroomDetail(widget.showroomId),
        activeNavigationId: 'showrooms',
        currentShowroomName: 'Showroom Detail',
        title: 'Branch Profile',
        actions: [
          AppButton.ghost(
            label: 'Back',
            leadingIcon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
        ],
        body: BlocConsumer<ShowroomDetailCubit, ShowroomDetailState>(
          listener: (context, state) {
            if (state is ShowroomDetailError) {
              context.showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is ShowroomDetailLoading) {
              return AppSkeleton.detail(rows: 4, columns: 3);
            }

            if (state is ShowroomDetailError) {
              return AppErrorState(
                title: 'Failed to Load Showroom',
                message: state.message,
                onRetry: () => _cubit.loadShowroomDetail(widget.showroomId),
              );
            }

            if (state is ShowroomDetailLoaded) {
              return _buildProfile(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }  Widget _buildProfile(BuildContext context, ShowroomDetailLoaded state) {
    final showroom = state.showroom;
    final isCurrentOperating =
        ShowroomService.instance.activeShowroom?.id == showroom.id;
    final isMobile = context.isMobile;

    final branchIcon = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 32,
          color: AppColors.primaryYellowDark,
        ),
      ),
    );

    final branchInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              showroom.name,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 18 : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                showroom.code,
                style: AppTypography.captionLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryYellowDark,
                ),
              ),
            ),
            AppStatusBadge.fromStatus(
              showroom.isActive ? 'active' : 'inactive',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          showroom.fullAddress,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Phone: ${showroom.phone} • Email: ${showroom.email ?? 'Not provided'}',
          style: AppTypography.captionLarge,
        ),
      ],
    );

    final quickActions = [
      if (!isCurrentOperating && showroom.isActive)
        AppButton.secondary(
          label: 'Set as Active Branch',
          leadingIcon: Icons.swap_horiz_rounded,
          onPressed: () async {
            await _cubit.switchOperatingShowroom(showroom.id);
            if (context.mounted) {
              context.showSuccessSnackBar('Switched active branch to ${showroom.name}');
              setState(() {});
            }
          },
        ),
      AppButton.primary(
        label: 'Edit Showroom',
        leadingIcon: Icons.edit_outlined,
        onPressed: () async {
          await context.pushNamed(
            RouteNames.showroomCreate,
            queryParameters: {'editId': showroom.id},
          );
          _cubit.loadShowroomDetail(widget.showroomId);
        },
      ),
    ];

    final taxCard = AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primaryYellowDark),
              const SizedBox(width: 8),
              Text(
                'Tax & Compliance',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _DetailRow(label: 'GSTIN', value: showroom.gstin ?? 'Not provided'),
          _DetailRow(label: 'PAN', value: showroom.pan ?? 'Not provided'),
          _DetailRow(label: 'Invoice Prefix', value: showroom.invoicePrefix),
          _DetailRow(label: 'State Jurisdiction', value: showroom.state),
        ],
      ),
    );

    final bankCard = AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                'Bank Account Coordinates',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _DetailRow(label: 'Bank Name', value: showroom.bankName ?? 'Not provided'),
          _DetailRow(label: 'Account Number', value: showroom.bankAccountNumber ?? 'Not provided'),
          _DetailRow(label: 'IFSC Code', value: showroom.bankIfsc ?? 'Not provided'),
          _DetailRow(label: 'Branch Name', value: showroom.bankBranch ?? 'Not provided'),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top Branch Header Card ───
          AppCard(
            padding: EdgeInsets.all(isMobile ? AppDimensions.spacing16 : AppDimensions.spacing24),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          branchIcon,
                          const SizedBox(width: AppDimensions.spacing16),
                          Expanded(child: branchInfo),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickActions,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      branchIcon,
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(child: branchInfo),
                      Row(
                        children: [
                          if (quickActions.length > 1) ...[
                            quickActions[0],
                            const SizedBox(width: AppDimensions.spacing8),
                            quickActions[1],
                          ] else
                            quickActions.first,
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Section 1: Statutory & Banking Details ───
          AppFormSection(
            title: 'Statutory, Tax & Banking Coordinates',
            subtitle: 'Legally registered coordinates used on invoices, receipts, and challans',
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 650) {
                    return Column(
                      children: [
                        taxCard,
                        const SizedBox(height: AppDimensions.spacing16),
                        bankCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: taxCard),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(child: bankCard),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Section 2: Document Numbering Sequences ───
          AppFormSection(
            title: 'Document Numbering Sequences',
            subtitle: 'Autonomous sequential number series generated for invoices, bookings, receipts, and challans',
            children: [
              if (state.sequences.isEmpty)
                const AppEmptyState(
                  icon: Icons.tag_rounded,
                  title: 'No Sequences Configured',
                  description: 'Document sequences will be automatically generated upon creating transactions.',
                )
              else
                AppDataTable<InvoiceSequenceEntity>(
                  minWidth: 700,
                  columns: [
                    AppDataColumn<InvoiceSequenceEntity>(
                      title: 'Document Type',
                      flex: 2,
                      cellBuilder: (context, seq) => Row(
                        children: [
                          Icon(_getDocTypeIcon(seq.docType), size: 18, color: AppColors.primaryYellowDark),
                          const SizedBox(width: 8),
                          Text(seq.docTypeLabel, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    AppDataColumn<InvoiceSequenceEntity>(
                      title: 'Prefix',
                      flex: 2,
                      cellBuilder: (context, seq) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seq.prefix,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    AppDataColumn<InvoiceSequenceEntity>(
                      title: 'Current Counter',
                      flex: 1,
                      cellBuilder: (context, seq) => Text(
                        seq.currentNumber.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    AppDataColumn<InvoiceSequenceEntity>(
                      title: 'Next Serial Preview',
                      flex: 2,
                      cellBuilder: (context, seq) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: Text(
                          seq.previewNextNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    AppDataColumn<InvoiceSequenceEntity>(
                      title: 'Actions',
                      flex: 1,
                      cellBuilder: (context, seq) => IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Configure sequence counter',
                        onPressed: () => _showEditSequenceDialog(context, seq),
                      ),
                    ),
                  ],
                  items: state.sequences,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ─── Section 3: Mapped Staff Team ───
          AppFormSection(
            title: 'Assigned Staff Members (${state.staff.length})',
            subtitle: 'Personnel authorized to access inventory, sales, and accounts for this branch',
            children: [
              if (state.staff.isEmpty)
                const AppEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No Staff Assigned',
                  description: 'Assign dealership staff to this branch via User Management.',
                )
              else
                AppDataTable<ManagedUser>(
                  minWidth: 700,
                  columns: [
                    AppDataColumn<ManagedUser>(
                      title: 'Staff Member',
                      flex: 3,
                      cellBuilder: (context, user) => Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.2),
                            child: Text(
                              user.profile.fullName?.isNotEmpty == true
                                  ? user.profile.fullName![0].toUpperCase()
                                  : user.profile.email[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryYellowDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.profile.fullName ?? 'Unnamed Staff',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(user.profile.email, style: AppTypography.captionLarge),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppDataColumn<ManagedUser>(
                      title: 'Roles',
                      flex: 2,
                      cellBuilder: (context, user) => Wrap(
                        spacing: 4,
                        children: user.roles.map((r) {
                          return AppStatusBadge(label: r.displayName, color: AppColors.info);
                        }).toList(),
                      ),
                    ),
                    AppDataColumn<ManagedUser>(
                      title: 'Default Branch',
                      flex: 1,
                      cellBuilder: (context, user) {
                        final isDefault = user.defaultShowroomId == showroom.id;
                        return isDefault
                            ? const AppStatusBadge(label: 'Primary', color: AppColors.success)
                            : const Text('Secondary', style: AppTypography.captionLarge);
                      },
                    ),
                    AppDataColumn<ManagedUser>(
                      title: 'Status',
                      flex: 1,
                      cellBuilder: (context, user) => AppStatusBadge.fromStatus(
                        user.profile.isActive ? 'active' : 'inactive',
                      ),
                    ),
                  ],
                  items: state.staff,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  IconData _getDocTypeIcon(String docType) {
    switch (docType) {
      case 'sale_invoice':
        return Icons.receipt_long_rounded;
      case 'booking':
        return Icons.bookmark_border_rounded;
      case 'payment_receipt':
        return Icons.payments_outlined;
      case 'gate_pass':
        return Icons.vpn_key_outlined;
      case 'delivery_challan':
        return Icons.local_shipping_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  void _showEditSequenceDialog(BuildContext context, InvoiceSequenceEntity seq) {
    final prefixCtrl = TextEditingController(text: seq.prefix);
    final nextNumCtrl = TextEditingController(text: seq.nextNumber.toString());
    final paddingCtrl = TextEditingController(text: seq.paddingZeros.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Configure ${seq.docTypeLabel} Sequence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: prefixCtrl,
                label: 'Sequence Prefix',
                hint: 'e.g. MB-MUM-INV-',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: nextNumCtrl,
                label: 'Next Serial Number',
                hint: 'e.g. 1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: paddingCtrl,
                label: 'Zero Padding Digits',
                hint: 'e.g. 5',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final nextNum = int.tryParse(nextNumCtrl.text.trim());
                final padding = int.tryParse(paddingCtrl.text.trim());

                _cubit.updateSequence(
                  seq.id,
                  prefix: prefixCtrl.text.trim(),
                  nextNumber: nextNum,
                  paddingZeros: padding,
                );
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.captionLarge.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
