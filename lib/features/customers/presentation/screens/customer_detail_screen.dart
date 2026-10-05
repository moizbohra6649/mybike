import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../domain/entities/customer_document_entity.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../cubit/customer_detail_cubit.dart';
import '../cubit/customer_detail_state.dart';

/// Customer Detail / Profile Screen
///
/// Shows the full customer profile with KYC documents, leads, and bookings tabs.
class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerDetailCubit()..loadCustomer(customerId),
      child: const _CustomerDetailView(),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  const _CustomerDetailView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppScaffold(
            title: 'Customer Profile',
            activeNavigationId: 'customers',
            body: AppSkeleton.detail(rows: 5, columns: 3),
          );
        }

        final customer = state.customer;
        if (customer == null) {
          return AppScaffold(
            title: 'Customer Profile',
            activeNavigationId: 'customers',
            body: Center(
              child: Text('Customer not found',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  )),
            ),
          );
        }

        return AppScaffold(
          onRefresh: () => context.read<CustomerDetailCubit>().loadCustomer(customer.id),
          title: customer.fullName,
          activeNavigationId: 'customers',
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            children: [
              // ─── Profile Header ───
              _ProfileHeader(customer: customer, isDark: isDark),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── Contact Card ───
              _InfoCard(
                isDark: isDark,
                title: 'Contact Information',
                icon: Icons.phone_outlined,
                children: [
                  _InfoRow(icon: Icons.phone_outlined, label: 'Primary Mobile', value: customer.mobilePrimary, isDark: isDark),
                  if (customer.mobileSecondary != null)
                    _InfoRow(icon: Icons.phone_outlined, label: 'Secondary', value: customer.mobileSecondary!, isDark: isDark),
                  if (customer.email != null)
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: customer.email!, isDark: isDark),
                  _InfoRow(icon: Icons.chat_outlined, label: 'Preferred', value: customer.preferredContactMethod ?? 'Phone', isDark: isDark),
                  if (customer.fullAddress.isNotEmpty)
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: customer.fullAddress, isDark: isDark),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── KYC Documents ───
              _DocumentsSection(documents: state.documents, isDark: isDark),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── Leads ───
              _LeadsSection(leads: state.leads, isDark: isDark),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── Bookings ───
              _BookingsSection(bookings: state.bookings, isDark: isDark),
              const SizedBox(height: AppDimensions.spacing40),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Header ───
class _ProfileHeader extends StatelessWidget {
  final dynamic customer;
  final bool isDark;
  const _ProfileHeader({required this.customer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Center(
              child: Text(customer.initials,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryYellow,
                  )),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    )),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppDimensions.spacing8,
                  runSpacing: 4,
                  children: [
                    Text(customer.customerNumber,
                        style: AppTypography.captionLarge.copyWith(
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          letterSpacing: 0.8,
                        )),
                    _StatusBadge(label: customer.kycStatusLabel, color: _kycColor(customer.kycStatus)),
                    _StatusBadge(label: customer.customerTypeLabel, color: AppColors.info),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Member since ${DateFormat('MMM yyyy').format(customer.createdAt)}',
                    style: AppTypography.captionLarge.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _kycColor(String status) {
    switch (status) {
      case 'verified': return AppColors.success;
      case 'partial': return AppColors.info;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(label, style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── Info Card ───
class _InfoCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({required this.isDark, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primaryYellow),
            const SizedBox(width: AppDimensions.spacing8),
            Text(title, style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
          ]),
          const SizedBox(height: AppDimensions.spacing12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
          const SizedBox(width: AppDimensions.spacing8),
          SizedBox(width: 80, child: Text(label, style: AppTypography.captionLarge.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText))),
          Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText))),
        ],
      ),
    );
  }
}

// ─── Documents Section ───
class _DocumentsSection extends StatelessWidget {
  final List<CustomerDocumentEntity> documents;
  final bool isDark;
  const _DocumentsSection({required this.documents, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.folder_outlined, size: 18, color: AppColors.primaryYellow),
            const SizedBox(width: AppDimensions.spacing8),
            Text('KYC Documents', style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
            const Spacer(),
            Text('${documents.length} doc${documents.length != 1 ? 's' : ''}',
                style: AppTypography.captionLarge.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ]),
          const SizedBox(height: AppDimensions.spacing12),
          if (documents.isEmpty)
            Text('No documents uploaded',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ...documents.map((doc) => _DocumentTile(doc: doc, isDark: isDark)),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final CustomerDocumentEntity doc;
  final bool isDark;
  const _DocumentTile({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Row(
          children: [
            Icon(_docIcon(doc.documentType), size: 20,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.documentTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                  Text('${doc.maskedNumber}  •  ${doc.fileSizeFormatted}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionLarge.copyWith(
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                ],
              ),
            ),
            _StatusBadge(
              label: doc.statusLabel,
              color: doc.isVerified ? AppColors.success : (doc.isRejected ? AppColors.error : AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'aadhaar': return Icons.credit_card_rounded;
      case 'pan': return Icons.badge_outlined;
      case 'driving_license': return Icons.drive_eta_outlined;
      case 'voter_id': return Icons.how_to_vote_outlined;
      case 'passport': return Icons.flight_outlined;
      case 'photo': return Icons.photo_camera_outlined;
      default: return Icons.description_outlined;
    }
  }
}

// ─── Leads Section ───
class _LeadsSection extends StatelessWidget {
  final List<LeadEntity> leads;
  final bool isDark;
  const _LeadsSection({required this.leads, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.trending_up_rounded, size: 18, color: AppColors.primaryYellow),
            const SizedBox(width: AppDimensions.spacing8),
            Text('Leads', style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
            const Spacer(),
            Text('${leads.length}', style: AppTypography.captionLarge.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ]),
          const SizedBox(height: AppDimensions.spacing12),
          if (leads.isEmpty)
            Text('No leads associated',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ...leads.map((lead) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  ),
                  child: Row(
                    children: [
                      Text(lead.priorityEmoji, style: AppTypography.titleLarge),
                      const SizedBox(width: AppDimensions.spacing8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lead.leadNumber, style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                            Text('${lead.interestedModelName ?? 'N/A'}  •  ${lead.sourceLabel}',
                                style: AppTypography.captionLarge.copyWith(
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                          ],
                        ),
                      ),
                      _StatusBadge(label: lead.statusLabel,
                          color: lead.isConverted ? AppColors.success : (lead.isLost ? AppColors.error : AppColors.info)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Bookings Section ───
class _BookingsSection extends StatelessWidget {
  final List<BookingEntity> bookings;
  final bool isDark;
  const _BookingsSection({required this.bookings, required this.isDark});

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF888888);
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return const Color(0xFF888888);
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bookmark_rounded, size: 18, color: AppColors.primaryYellow),
            const SizedBox(width: AppDimensions.spacing8),
            Text('Bookings', style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
            const Spacer(),
            Text('${bookings.length}', style: AppTypography.captionLarge.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ]),
          const SizedBox(height: AppDimensions.spacing12),
          if (bookings.isEmpty)
            Text('No bookings',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          ...bookings.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  ),
                  child: Row(
                    children: [
                      if (b.colorHex != null) ...[
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: _parseHex(b.colorHex),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.bookingNumber, style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                            Text('${b.modelName ?? ''} ${b.variantName ?? ''}  •  ${BookingEntity.formatInr(b.onRoadPrice)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionLarge.copyWith(
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: b.statusLabel,
                        color: b.isDelivered ? AppColors.success
                            : (b.isCancelled ? AppColors.error
                            : (b.isAllocated ? AppColors.info : AppColors.warning)),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
