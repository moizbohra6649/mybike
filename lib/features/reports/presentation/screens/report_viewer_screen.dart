import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../common/common.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/report_viewer_cubit.dart';
import '../cubit/report_viewer_state.dart';

import '../../../../core/services/document_export_service.dart';
import '../widgets/export_action_modal.dart';
import 'document_preview_screen.dart';

/// Detailed Statement & Register Viewer Screen
class ReportViewerScreen extends StatelessWidget {
  final String reportType;

  const ReportViewerScreen({
    super.key,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportViewerCubit(reportType: reportType)..loadReport(),
      child: const _ReportViewerContent(),
    );
  }
}

class _ReportViewerContent extends StatelessWidget {
  const _ReportViewerContent();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<ReportViewerCubit, ReportViewerState>(
      builder: (context, state) {
        final cubit = context.read<ReportViewerCubit>();

        return AppScaffold(
          title: state.title.isNotEmpty ? state.title : 'Report Viewer',
          activeNavigationId: 'reports',
          actions: [
            // Export Shortcut
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export Statement (PDF, Excel, CSV, Print)',
              onPressed: state.rows.isEmpty
                  ? null
                  : () => _showExportModal(context, state),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload Report',
              onPressed: () => cubit.loadReport(),
            ),
          ],
          body: Column(
            children: [
              // ─── Filter & Parameters Bar ───
              _buildFilterBar(context, state, cubit, isDark),

              // ─── Main Content Area ───
              Expanded(
                child: state.status == ReportViewerStatus.loading
                    ? AppSkeleton.table(rows: 8, columns: 5)
                    : state.status == ReportViewerStatus.failure
                        ? _buildErrorView(state, cubit, isDark)
                        : _buildReportBody(context, state, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ReportViewerState state,
    ReportViewerCubit cubit,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing20,
        vertical: AppDimensions.spacing12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Back Button to Reports Hub
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Reports Hub',
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: AppDimensions.spacing8),

            // Showroom Branch Filter Dropdown
            SizedBox(
              width: 220,
              child: AppDropdown<String?>(
                isDense: true,
                hint: 'Showroom Branch',
                value: state.criteria.showroomId,
                items: const [
                  null,
                  'showroom-mumbai-main',
                  'showroom-pune-west',
                  'showroom-bangalore-metro',
                ],
                itemLabel: (id) {
                  switch (id) {
                    case 'showroom-mumbai-main':
                      return 'Mumbai Flagship';
                    case 'showroom-pune-west':
                      return 'Pune West Hub';
                    case 'showroom-bangalore-metro':
                      return 'Bangalore Metro';
                    default:
                      return 'All Showrooms';
                  }
                },
                onChanged: (newShowroomId) {
                  final showroomName = newShowroomId == 'showroom-mumbai-main'
                      ? 'Mumbai Flagship'
                      : (newShowroomId == 'showroom-pune-west'
                          ? 'Pune West Hub'
                          : (newShowroomId == 'showroom-bangalore-metro' ? 'Bangalore Metro' : 'All Showrooms'));
                  cubit.updateCriteria(state.criteria.copyWith(
                    showroomId: newShowroomId,
                    clearShowroom: newShowroomId == null,
                    showroomName: showroomName,
                  ));
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spacing16),

            // Period Filter Pills
            Row(
              children: [
                _buildPeriodChip(context, 'This Month', 'month', state, cubit),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'This Quarter', 'quarter', state, cubit),
                const SizedBox(width: 8),
                _buildPeriodChip(context, 'FY 2025-26', 'year', state, cubit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    String label,
    String periodValue,
    ReportViewerState state,
    ReportViewerCubit cubit,
  ) {
    final isSelected = state.criteria.period == periodValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final now = DateTime.now();
          DateTime start = state.criteria.startDate;
          DateTime end = state.criteria.endDate;

          if (periodValue == 'month') {
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          } else if (periodValue == 'quarter') {
            final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
            start = DateTime(now.year, qMonth, 1);
            end = DateTime(now.year, qMonth + 3, 0, 23, 59, 59);
          } else if (periodValue == 'year') {
            final startYear = now.month >= 4 ? now.year : now.year - 1;
            start = DateTime(startYear, 4, 1);
            end = DateTime(startYear + 1, 3, 31, 23, 59, 59);
          }

          cubit.updateCriteria(state.criteria.copyWith(
            period: periodValue,
            startDate: start,
            endDate: end,
          ));
        }
      },
    );
  }

  Widget _buildErrorView(ReportViewerState state, ReportViewerCubit cubit, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(state.errorMessage ?? 'An error occurred loading statement.', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry Report',
            leadingIcon: Icons.refresh,
            onPressed: () => cubit.loadReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBody(BuildContext context, ReportViewerState state, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Letterhead Header ───
          _buildLetterhead(state, isDark),
          const SizedBox(height: AppDimensions.spacing20),

          // ─── Summary Metric Cards ───
          if (state.summaryCards.isNotEmpty) ...[
            _buildSummaryRow(state, isDark),
            const SizedBox(height: AppDimensions.spacing24),
          ],

          // ─── Tabular Data Table ───
          _buildDataTableCard(context, state, isDark),
        ],
      ),
    );
  }

  Widget _buildLetterhead(ReportViewerState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      'MYBIKE ERP',
                      style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.title,
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GSTIN: 27AABCM9821Q1Z4',
                style: AppTypography.captionSmall.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Generated: ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())}',
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ReportViewerState state, bool isDark) {
    return Row(
      children: state.summaryCards.map((card) {
        final title = card['title'] as String;
        final value = card['value'] as String? ?? (card['value:'] as String? ?? '');
        final color = (card['color'] as Color?) ?? AppColors.primaryYellow;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataTableCard(BuildContext context, ReportViewerState state, bool isDark) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 900),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.darkCard : AppColors.lightBackground,
              ),
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columns: state.columns.map((col) {
                return DataColumn(
                  label: Text(
                    col.title,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  numeric: col.align == TextAlign.right,
                );
              }).toList(),
              rows: state.rows.map((row) {
                final isTotal = row.isTotalRow;
                final isSubtotal = row.isSubtotalRow;
                final isHeader = row.isHeader;

                final rowColor = isTotal
                    ? (isDark ? AppColors.primaryYellow.withAlpha(30) : AppColors.primaryYellow.withAlpha(40))
                    : (isSubtotal
                        ? (isDark ? AppColors.darkCard : AppColors.lightBackground)
                        : null);

                return DataRow(
                  color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
                  cells: row.cells.map((cell) {
                    return DataCell(
                      Text(
                        cell.text,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: (isTotal || isHeader || cell.isBold) ? FontWeight.bold : FontWeight.normal,
                          color: cell.textColor ??
                              (isTotal
                                  ? AppColors.primaryYellow
                                  : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)),
                        ),
                        textAlign: cell.align,
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportModal(BuildContext context, ReportViewerState state) {
    const exportService = DocumentExportService();

    ExportActionModal.show(
      context,
      title: 'Export ${state.title}',
      subtitle: '${state.rows.length} rows • Filtered by active criteria',
      onGeneratePdf: () => exportService.generateReportPdf(
        title: state.title,
        subtitle: 'MYBIKE ERP • Official Statement',
        columns: state.columns,
        rows: state.rows,
      ),
      onPreviewPdf: (bytes) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentPreviewScreen(
              title: state.title,
              pdfBytes: bytes,
            ),
          ),
        );
      },
      onExportExcel: () async {
        exportService.generateReportExcelXml(
          sheetName: state.title,
          title: state.title,
          columns: state.columns,
          rows: state.rows,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel spreadsheet generated for ${state.title} (${state.rows.length} rows)'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onExportCsv: () async {
        exportService.generateReportCsvString(
          columns: state.columns,
          rows: state.rows,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV data generated for ${state.title} (${state.rows.length} rows)'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onPrint: () async {
        final pdfBytes = await exportService.generateReportPdf(
          title: state.title,
          subtitle: 'MYBIKE ERP • Official Statement',
          columns: state.columns,
          rows: state.rows,
        );
        await exportService.printDocument(
          bytes: pdfBytes,
          name: state.title,
        );
      },
    );
  }
}

