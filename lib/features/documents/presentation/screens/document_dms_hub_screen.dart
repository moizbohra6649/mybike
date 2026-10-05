import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/dealership_document_entity.dart';
import '../../domain/entities/document_filter_criteria.dart';
import '../cubit/document_list_cubit.dart';
import '../cubit/document_list_state.dart';
import '../widgets/document_card.dart';
import '../widgets/document_reject_dialog.dart';
import '../widgets/document_upload_modal.dart';
import '../widgets/document_viewer_modal.dart';

class DocumentDmsHubScreen extends StatelessWidget {
  const DocumentDmsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocumentListCubit()..loadDocuments(),
      child: const _DocumentDmsHubView(),
    );
  }
}

class _DocumentDmsHubView extends StatefulWidget {
  const _DocumentDmsHubView();

  @override
  State<_DocumentDmsHubView> createState() => _DocumentDmsHubViewState();
}

class _DocumentDmsHubViewState extends State<_DocumentDmsHubView> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All Documents'},
    {'key': 'kyc', 'label': 'Customer KYC'},
    {'key': 'rto_registration', 'label': 'RTO Statutory'},
    {'key': 'insurance', 'label': 'Insurance'},
    {'key': 'warranty', 'label': 'Warranty & RSA'},
    {'key': 'delivery', 'label': 'Delivery Gate Pass'},
    {'key': 'purchase_invoice', 'label': 'OEM Invoices'},
    {'key': 'factory_gatepass', 'label': 'Consignment Notes'},
    {'key': 'hypothecation', 'label': 'Bank NOC'},
    {'key': 'puc', 'label': 'PUC'},
  ];

  final List<Map<String, String>> _statuses = [
    {'key': 'all', 'label': 'All Statuses'},
    {'key': 'pending', 'label': 'Pending Verification'},
    {'key': 'verified', 'label': 'Verified'},
    {'key': 'rejected', 'label': 'Rejected'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUploadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => DocumentUploadModal(
        onDocumentUploaded: (newDoc) {
          context.read<DocumentListCubit>().loadDocuments();
        },
      ),
    );
  }

  void _openViewerModal(BuildContext context, DealershipDocumentEntity doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => DocumentViewerModal(
        document: doc,
        onVerify: doc.isPending
            ? () {
                context.read<DocumentListCubit>().verifyDocument(
                      doc.id,
                      verifiedBy: 'Compliance Manager',
                    );
              }
            : null,
        onReject: doc.isPending
            ? () {
                _openRejectDialog(context, doc);
              }
            : null,
      ),
    );
  }

  void _openRejectDialog(BuildContext context, DealershipDocumentEntity doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => DocumentRejectDialog(
        document: doc,
        onConfirm: (reason) {
          context.read<DocumentListCubit>().rejectDocument(
                doc.id,
                rejectedBy: 'Compliance Officer',
                reason: reason,
              );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DealershipDocumentEntity doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.fileName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<DocumentListCubit>().deleteDocument(doc.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentListCubit, DocumentListState>(
      listener: (context, state) {
        if (state is DocumentListLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DocumentListCubit>().clearSuccessMessage();
        } else if (state is DocumentListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        Map<String, int> counts = {'total': 0, 'pending': 0, 'verified': 0, 'rejected': 0};
        String selectedCategory = 'all';
        String selectedStatus = 'all';
        String selectedEntityType = 'all';

        if (state is DocumentListLoaded) {
          counts = state.counts;
          selectedCategory = state.criteria.documentCategory ?? 'all';
          selectedStatus = state.criteria.verificationStatus ?? 'all';
          selectedEntityType = state.criteria.entityType ?? 'all';
        }

        return AppScaffold(
          onRefresh: () => context.read<DocumentListCubit>().loadDocuments(),
          title: 'Document Hub (DMS)',
          activeNavigationId: 'documents',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _openUploadModal(context),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing20),

                // Metrics KPI Row
                _buildKpiMetricsRow(context, counts),
                const SizedBox(height: AppDimensions.spacing20),

                // Filter & Search Controls Bar
                _buildControlsBar(
                  context,
                  selectedCategory: selectedCategory,
                  selectedStatus: selectedStatus,
                  selectedEntityType: selectedEntityType,
                ),
                const SizedBox(height: AppDimensions.spacing16),

                // Main Content List
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(Icons.folder_shared_outlined, color: AppColors.primaryYellowDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Document Management Hub (DMS)',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: context.isMobile ? 18 : null,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Central statutory archive for Customer KYC, RTO Form 20/21, Insurance, Warranty, Gate Passes, and OEM Invoices',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiMetricsRow(BuildContext context, Map<String, int> counts) {
    final isMobile = context.isMobile;

    final cards = [
      _buildMetricCard(
        context,
        title: 'Total Documents',
        count: counts['total'] ?? 0,
        icon: Icons.archive_outlined,
        iconColor: AppColors.primaryYellowDark,
      ),
      _buildMetricCard(
        context,
        title: 'Pending Verification',
        count: counts['pending'] ?? 0,
        icon: Icons.pending_actions_outlined,
        iconColor: AppColors.warning,
        isHighlight: (counts['pending'] ?? 0) > 0,
      ),
      _buildMetricCard(
        context,
        title: 'Verified & Approved',
        count: counts['verified'] ?? 0,
        icon: Icons.verified_user_outlined,
        iconColor: AppColors.success,
      ),
      _buildMetricCard(
        context,
        title: 'Rejected / Action Req.',
        count: counts['rejected'] ?? 0,
        icon: Icons.highlight_off_outlined,
        iconColor: AppColors.error,
      ),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - AppDimensions.spacing12) / 2;
          return Wrap(
            spacing: AppDimensions.spacing12,
            runSpacing: AppDimensions.spacing12,
            children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[1]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[2]),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    bool isHighlight = false,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isHighlight ? iconColor.withValues(alpha: 0.6) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMedium.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(
    BuildContext context, {
    required String selectedCategory,
    required String selectedStatus,
    required String selectedEntityType,
  }) {
    final isDark = context.isDarkMode;
    final isMobile = context.isMobile;

    final searchField = TextField(
      controller: _searchController,
      style: TextStyle(
        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      ),
      decoration: InputDecoration(
        hintText: 'Search by file name, doc type, customer, VIN, or record number...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<DocumentListCubit>().setSearch('');
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (val) {
        context.read<DocumentListCubit>().setSearch(val);
      },
    );

    final entityDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedEntityType,
          isExpanded: isMobile,
          icon: const Icon(Icons.filter_alt_outlined, size: 16),
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Entity Types')),
            DropdownMenuItem(value: 'customer', child: Text('Customers')),
            DropdownMenuItem(value: 'vehicle', child: Text('Vehicles')),
            DropdownMenuItem(value: 'booking', child: Text('Bookings')),
            DropdownMenuItem(value: 'invoice', child: Text('Invoices')),
            DropdownMenuItem(value: 'purchase', child: Text('Purchases')),
          ],
          onChanged: (val) {
            if (val != null) {
              context.read<DocumentListCubit>().setEntityType(val);
            }
          },
        ),
      ),
    );

    final statusChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((status) {
          final isSelected = selectedStatus == status['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(status['label']!),
              selected: isSelected,
              selectedColor: AppColors.primaryYellow.withValues(alpha: 0.25),
              labelStyle: AppTypography.captionMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppColors.primaryYellowDark : AppColors.warning)
                    : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
              ),
              onSelected: (_) {
                context.read<DocumentListCubit>().setStatus(status['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          searchField,
          const SizedBox(height: 10),
          entityDropdown,
          const SizedBox(height: 10),
          statusChips,
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: searchField,
              ),
              const SizedBox(width: 12),
              entityDropdown,
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: statusChips,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        // Horizontal Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = selectedCategory == cat['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primaryYellow,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: AppTypography.captionLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.black87
                        : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<DocumentListCubit>().setCategory(cat['key']!);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DocumentListState state) {
    final isDark = context.isDarkMode;

    if (state is DocumentListLoading) {
      return AppSkeleton.list(kpis: 4, rows: 6);
    }

    if (state is DocumentListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DocumentListCubit>().loadDocuments(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DocumentListLoaded) {
      if (state.documents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 48,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Documents Found',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No statutory records match your current search and filter criteria.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context.read<DocumentListCubit>().loadDocuments(
                        criteria: const DocumentFilterCriteria(),
                      );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Filters'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: state.documents.length,
        itemBuilder: (context, index) {
          final doc = state.documents[index];
          return DocumentCard(
            document: doc,
            onView: () => _openViewerModal(context, doc),
            onVerify: doc.isPending
                ? () {
                    context.read<DocumentListCubit>().verifyDocument(
                          doc.id,
                          verifiedBy: 'Compliance Officer',
                        );
                  }
                : null,
            onReject: doc.isPending
                ? () {
                    _openRejectDialog(context, doc);
                  }
                : null,
            onDelete: () => _confirmDelete(context, doc),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
