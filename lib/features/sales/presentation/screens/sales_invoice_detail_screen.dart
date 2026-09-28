import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../core/services/document_export_service.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../../../reports/presentation/screens/document_preview_screen.dart';
import '../../../reports/presentation/widgets/export_action_modal.dart';
import '../cubit/sales_invoice_detail_cubit.dart';
import '../cubit/sales_invoice_detail_state.dart';

/// Sales Invoice Detail Screen (GST Tax Invoice Dossier)
class SalesInvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const SalesInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesInvoiceDetailCubit()..loadInvoice(invoiceId),
      child: const _SalesInvoiceDetailView(),
    );
  }
}

class _SalesInvoiceDetailView extends StatelessWidget {
  const _SalesInvoiceDetailView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMMM yyyy');
    final accentColor = isDark
        ? AppColors.primaryYellow
        : AppColors.primaryYellowDark;

    return BlocBuilder<SalesInvoiceDetailCubit, SalesInvoiceDetailState>(
      builder: (context, state) {
        final invoice = state.invoice;
        final isMobile = context.isMobile;

        return AppScaffold(
          activeNavigationId: 'sales',
          title: invoice != null
              ? 'Tax Invoice: ${invoice.invoiceNumber}'
              : 'Tax Invoice',
          actions: [
            if (invoice != null) ...[
              if (isMobile) ...[
                IconButton(
                  onPressed: () => _showPrintOptions(context, invoice),
                  icon: const Icon(Icons.print_rounded),
                  tooltip: 'Print / PDF Invoice',
                ),
                if (invoice.status == 'issued')
                  IconButton(
                    onPressed: () =>
                        context.go('/sales/${invoice.id}/delivery'),
                    icon: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.success,
                    ),
                    tooltip: 'Delivery Challan',
                  ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () => _showPrintOptions(context, invoice),
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Print / PDF Invoice'),
                ),
                const SizedBox(width: 8),
                if (invoice.status == 'issued')
                  FilledButton.icon(
                    onPressed: () =>
                        context.go('/sales/${invoice.id}/delivery'),
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text('Generate Delivery Challan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ],
            const SizedBox(width: 8),
          ],
          floatingActionButton:
              (isMobile && invoice != null && invoice.status == 'issued')
              ? FloatingActionButton.extended(
                  onPressed: () => context.go('/sales/${invoice.id}/delivery'),
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Delivery Challan'),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                )
              : null,
          body: state.isLoading
              ? AppSkeleton.detail(rows: 5, columns: 4)
              : invoice == null
              ? const Center(child: Text('Invoice not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24,
                    vertical: isMobile ? 12 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 950),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Tax Invoice Header (Responsive) ───
                            if (isMobile) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.two_wheeler_rounded,
                                      color: accentColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'MYBIKE DEALERSHIP',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                                color: accentColor,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.6,
                                              ),
                                        ),
                                        Text(
                                          'Authorized Dealer • GSTIN: 27AAACM9988C1Z4',
                                          style: AppTypography.captionSmall
                                              .copyWith(
                                                color: isDark
                                                    ? AppColors.darkMutedText
                                                    : AppColors.lightMutedText,
                                              ),
                                        ),
                                        Text(
                                          'Branch: ${invoice.showroomName ?? "Main Showroom"}',
                                          style: AppTypography.captionSmall
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TAX INVOICE',
                                            style: AppTypography.captionSmall
                                                .copyWith(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                          ),
                                          Text(
                                            invoice.invoiceNumber,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: invoice.isPaid
                                                ? AppColors.success.withValues(
                                                    alpha: 0.15,
                                                  )
                                                : AppColors.warning.withValues(
                                                    alpha: 0.15,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            invoice.isPaid ? 'PAID' : 'PENDING',
                                            style: AppTypography.captionSmall
                                                .copyWith(
                                                  color: invoice.isPaid
                                                      ? AppColors.success
                                                      : AppColors.warning,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateFormat.format(
                                            invoice.invoiceDate,
                                          ),
                                          style: AppTypography.captionSmall
                                              .copyWith(
                                                color: isDark
                                                    ? AppColors.darkMutedText
                                                    : AppColors.lightMutedText,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: accentColor.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.two_wheeler_rounded,
                                            color: accentColor,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'MYBIKE DEALERSHIP NETWORK',
                                                style: AppTypography
                                                    .headlineMedium
                                                    .copyWith(
                                                      color: accentColor,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 1.1,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Authorized Dealer • GSTIN: 27AAACM9988C1Z4',
                                                style: AppTypography
                                                    .captionLarge
                                                    .copyWith(
                                                      color: isDark
                                                          ? AppColors
                                                                .darkMutedText
                                                          : AppColors
                                                                .lightMutedText,
                                                    ),
                                              ),
                                              Text(
                                                'Branch: ${invoice.showroomName ?? "Main Showroom"}',
                                                style: AppTypography
                                                    .captionMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'TAX INVOICE',
                                          style: AppTypography.headlineSmall
                                              .copyWith(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                        ),
                                        Text(
                                          invoice.invoiceNumber,
                                          style: AppTypography.captionLarge
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'Date: ${dateFormat.format(invoice.invoiceDate)}',
                                          style: AppTypography.captionSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 32),

                            // ─── Customer & Vehicle Section (Responsive) ───
                            if (isMobile) ...[
                              _buildCustomerCard(invoice, isDark),
                              const SizedBox(height: 12),
                              _buildVehicleCard(invoice, isDark, accentColor),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildCustomerCard(invoice, isDark),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildVehicleCard(
                                      invoice,
                                      isDark,
                                      accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),

                            // ─── Tax & Pricing Breakdown Table ───
                            Container(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.lightBackground.withValues(
                                        alpha: 0.6,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TAX & PRICING COMPUTATION (HSN 8711)',
                                        style: AppTypography.captionSmall
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              color: isDark
                                                  ? AppColors.darkMutedText
                                                  : AppColors.lightMutedText,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPriceRow(
                                    'Ex-Showroom Price (Vehicle Base)',
                                    currencyFormat.format(
                                      invoice.exShowroomPrice,
                                    ),
                                    isDark,
                                    accentColor,
                                  ),
                                  if (invoice.discountAmount > 0)
                                    _buildPriceRow(
                                      'Special Dealer Discount',
                                      '- ${currencyFormat.format(invoice.discountAmount)}',
                                      isDark,
                                      accentColor,
                                      isHighlight: true,
                                    ),
                                  _buildPriceRow(
                                    'Taxable Value',
                                    currencyFormat.format(
                                      invoice.taxableAmount,
                                    ),
                                    isDark,
                                    accentColor,
                                  ),
                                  _buildPriceRow(
                                    'CGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)',
                                    currencyFormat.format(invoice.cgstAmount),
                                    isDark,
                                    accentColor,
                                  ),
                                  _buildPriceRow(
                                    'SGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)',
                                    currencyFormat.format(invoice.sgstAmount),
                                    isDark,
                                    accentColor,
                                  ),
                                  _buildPriceRow(
                                    'RTO Registration & Road Tax',
                                    currencyFormat.format(invoice.rtoCharges),
                                    isDark,
                                    accentColor,
                                  ),
                                  _buildPriceRow(
                                    'Comprehensive Insurance (1+5 Yrs)',
                                    currencyFormat.format(
                                      invoice.insuranceCharges,
                                    ),
                                    isDark,
                                    accentColor,
                                  ),
                                  if (invoice.accessoriesTotal > 0)
                                    _buildPriceRow(
                                      'Mandatory & Lifestyle Accessories Pack',
                                      currencyFormat.format(
                                        invoice.accessoriesTotal,
                                      ),
                                      isDark,
                                      accentColor,
                                    ),
                                  if (invoice.extendedWarrantyAmount > 0)
                                    _buildPriceRow(
                                      'Extended Warranty (5 Yrs RSA Package)',
                                      currencyFormat.format(
                                        invoice.extendedWarrantyAmount,
                                      ),
                                      isDark,
                                      accentColor,
                                    ),
                                  if (invoice.fastagCharges > 0)
                                    _buildPriceRow(
                                      'Fastag / RFID Tag Fees',
                                      currencyFormat.format(
                                        invoice.fastagCharges,
                                      ),
                                      isDark,
                                      accentColor,
                                    ),
                                  if (invoice.hypothecationCharges > 0)
                                    _buildPriceRow(
                                      'Hypothecation Endorsement Fees',
                                      currencyFormat.format(
                                        invoice.hypothecationCharges,
                                      ),
                                      isDark,
                                      accentColor,
                                    ),
                                  const Divider(thickness: 1.5, height: 24),
                                  _buildPriceRow(
                                    'TOTAL ON-ROAD PRICE (INR)',
                                    currencyFormat.format(
                                      invoice.totalOnRoadPrice,
                                    ),
                                    isDark,
                                    accentColor,
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── Settlement / Payment Summary ───
                            Container(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'PAYMENT & SETTLEMENT SUMMARY',
                                        style: AppTypography.captionSmall
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (invoice.balanceAmount <= 0)
                                              ? AppColors.success.withValues(
                                                  alpha: 0.15,
                                                )
                                              : AppColors.warning.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          invoice.balanceAmount <= 0
                                              ? 'SETTLED'
                                              : 'PARTIALLY PAID',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: invoice.balanceAmount <= 0
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    'Booking Advance Adjusted',
                                    currencyFormat.format(
                                      invoice.bookingAdvanceAdjusted,
                                    ),
                                    'Amount Paid Directly',
                                    currencyFormat.format(invoice.amountPaid),
                                    isMobile,
                                  ),
                                  if (invoice.financeAmount > 0 ||
                                      invoice.balanceAmount > 0) ...[
                                    const SizedBox(height: 8),
                                    _buildSummaryRow(
                                      'Finance (${invoice.financeBank ?? "Financier"})',
                                      currencyFormat.format(
                                        invoice.financeAmount,
                                      ),
                                      'Balance Due',
                                      currencyFormat.format(
                                        invoice.balanceAmount,
                                      ),
                                      isMobile,
                                      isSecondHighlighted:
                                          invoice.balanceAmount > 0,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── Delivery Status ───
                            if (state.challan != null)
                              Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vehicle Delivered under Challan ${state.challan!.challanNumber}',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            'Handed over to ${state.challan!.receivedByName} on ${dateFormat.format(state.challan!.challanDate)}',
                                            style: AppTypography.captionSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCustomerCard(SalesInvoiceEntity invoice, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.5)
            : AppColors.lightBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkMutedText
                    : AppColors.lightMutedText,
              ),
              const SizedBox(width: 6),
              Text(
                'BUYER / BILLED TO',
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkMutedText
                      : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            invoice.customerName ?? 'Customer',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (invoice.customerMobile != null) ...[
            const SizedBox(height: 2),
            Text(
              'Mobile: +91 ${invoice.customerMobile}',
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            'State: Maharashtra • POS: 27 (GST State Code)',
            style: AppTypography.captionSmall.copyWith(
              color: isDark
                  ? AppColors.darkMutedText
                  : AppColors.lightMutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
    SalesInvoiceEntity invoice,
    bool isDark,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.5)
            : AppColors.lightBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.two_wheeler_outlined,
                size: 16,
                color: isDark
                    ? AppColors.darkMutedText
                    : AppColors.lightMutedText,
              ),
              const SizedBox(width: 6),
              Text(
                'VEHICLE PARTICULARS',
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkMutedText
                      : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${invoice.modelName ?? ""} ${invoice.variantName ?? ""}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Color: ${invoice.colorName ?? "Standard"}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'VIN: ',
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  invoice.vin,
                  style: AppTypography.captionMedium.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (invoice.engineNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              'Engine No: ${invoice.engineNumber}',
              style: AppTypography.captionSmall.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (invoice.motorNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              'Motor No: ${invoice.motorNumber}',
              style: AppTypography.captionSmall.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label1,
    String value1,
    String label2,
    String value2,
    bool isMobile, {
    bool isSecondHighlighted = false,
  }) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label1, style: AppTypography.captionSmall)),
              Text(
                value1,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label2, style: AppTypography.captionSmall)),
              Text(
                value2,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSecondHighlighted ? AppColors.warning : null,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Text('$label1: ', style: AppTypography.bodySmall),
              Text(
                value1,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacing16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$label2: ', style: AppTypography.bodySmall),
              Text(
                value2,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSecondHighlighted ? AppColors.warning : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isDark,
    Color accentColor, {
    bool isTotal = false,
    bool isHighlight = false,
  }) {
    if (isTotal) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isHighlight
                    ? AppColors.error
                    : (isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlight ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context, SalesInvoiceEntity invoice) {
    const exportService = DocumentExportService();
    ExportActionModal.show(
      context,
      title: 'Tax Invoice: ${invoice.invoiceNumber}',
      subtitle:
          '${invoice.modelName ?? "Vehicle"} • ₹ ${invoice.totalOnRoadPrice.toStringAsFixed(2)}',
      onGeneratePdf: () => exportService.generateInvoicePdf(invoice: invoice),
      onPreviewPdf: (bytes) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentPreviewScreen(
              title: 'Invoice ${invoice.invoiceNumber}',
              pdfBytes: bytes,
            ),
          ),
        );
      },
      onPrint: () async {
        final bytes = await exportService.generateInvoicePdf(invoice: invoice);
        await exportService.printDocument(
          bytes: bytes,
          name: 'Invoice-${invoice.invoiceNumber}',
        );
      },
    );
  }
}
