import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../common/layouts/app_scaffold.dart';
import '../../../../common/loaders/app_loading.dart';
import '../../../../common/loaders/app_skeleton.dart';
import '../../../../core/services/sales_management_service.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../../domain/entities/delivery_challan_entity.dart';
import '../../domain/entities/gate_pass_entity.dart';

/// Vehicle Handover Checklist, Delivery Challan & Gate Pass Screen
class DeliveryChallanScreen extends StatefulWidget {
  final String invoiceId;
  const DeliveryChallanScreen({super.key, required this.invoiceId});

  @override
  State<DeliveryChallanScreen> createState() => _DeliveryChallanScreenState();
}

class _DeliveryChallanScreenState extends State<DeliveryChallanScreen> {
  SalesInvoiceEntity? _invoice;
  bool _isLoading = true;
  bool _isSaving = false;

  // Handover Checklist State
  bool _helmetProvided = true;
  bool _toolkitProvided = true;
  bool _firstAidKitProvided = true;
  bool _ownerManualProvided = true;
  bool _pdiFormSigned = true;
  bool _customerAcceptanceSigned = true;
  double _odometerKm = 2.5;
  String _receivedByName = '';

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final inv = await SalesManagementService.instance.fetchInvoiceById(widget.invoiceId);
    setState(() {
      _invoice = inv;
      _isLoading = false;
      if (inv != null) {
        _receivedByName = inv.customerName ?? 'Customer';
      }
    });
  }

  Future<void> _submitHandover() async {
    if (_invoice == null) return;
    setState(() => _isSaving = true);

    try {
      // 1. Create Delivery Challan
      final challan = await SalesManagementService.instance.createDeliveryChallan(
        DeliveryChallanEntity(
          id: '',
          showroomId: _invoice!.showroomId,
          invoiceId: _invoice!.id,
          challanNumber: '',
          challanDate: DateTime.now(),
          allocatedVin: _invoice!.vin,
          odometerReadingKm: _odometerKm,
          helmetProvided: _helmetProvided,
          toolkitProvided: _toolkitProvided,
          firstAidKitProvided: _firstAidKitProvided,
          ownerManualProvided: _ownerManualProvided,
          pdiFormSigned: _pdiFormSigned,
          customerAcceptanceSigned: _customerAcceptanceSigned,
          receivedByName: _receivedByName,
          createdAt: DateTime.now(),
          invoiceNumber: _invoice!.invoiceNumber,
          customerName: _invoice!.customerName,
          modelName: _invoice!.modelName,
          variantName: _invoice!.variantName,
          colorName: _invoice!.colorName,
        ),
      );

      // 2. Automatically generate Gate Pass for showroom security guard
      await SalesManagementService.instance.createGatePass(
        GatePassEntity(
          id: '',
          showroomId: _invoice!.showroomId,
          challanId: challan.id,
          invoiceId: _invoice!.id,
          gatePassNumber: '',
          issuedAt: DateTime.now(),
          vin: _invoice!.vin,
          customerName: _receivedByName,
          authorizedByName: 'Showroom Manager',
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery Challan ${challan.challanNumber} & Gate Pass generated!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/sales/${_invoice!.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppScaffold(
      onRefresh: _loadInvoice,
      activeNavigationId: 'sales',
      title: 'Vehicle Delivery Handover',
      body: _isLoading
          ? AppSkeleton.form(sections: 2, fields: 4)
          : _invoice == null
              ? const Center(child: Text('Invoice not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Vehicle Handover & Gate Pass', style: AppTypography.headlineMedium),
                                    Text(
                                      'Invoice: ${_invoice!.invoiceNumber} • VIN: ${_invoice!.vin}',
                                      style: AppTypography.captionMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 32),

                            // Vehicle & Customer Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Vehicle Delivered:', style: AppTypography.captionSmall),
                                      Text(
                                        '${_invoice!.modelName ?? ""} ${_invoice!.variantName ?? ""}',
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text('Color: ${_invoice!.colorName ?? "Standard"}', style: AppTypography.captionSmall),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Receiver:', style: AppTypography.captionSmall),
                                      Text(_receivedByName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                      Text('Mobile: ${_invoice!.customerMobile ?? ""}', style: AppTypography.captionSmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Mandated Checklist
                            Text(
                              'STATUTORY DELIVERY CHECKLIST (MOTOR VEHICLES ACT)',
                              style: AppTypography.captionSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              title: const Text('ISI Mark Helmet Handed Over (Mandatory)'),
                              subtitle: const Text('Provided to customer as per Central Motor Vehicles Rules'),
                              value: _helmetProvided,
                              onChanged: (v) => setState(() => _helmetProvided = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Original Tool Kit'),
                              subtitle: const Text('Verified inside utility/under-seat compartment'),
                              value: _toolkitProvided,
                              onChanged: (v) => setState(() => _toolkitProvided = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Statutory First Aid Kit'),
                              subtitle: const Text('Complies with Indian CMVR regulations'),
                              value: _firstAidKitProvided,
                              onChanged: (v) => setState(() => _firstAidKitProvided = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Owner Manual & Service Booklet with Warranty Card'),
                              subtitle: const Text('Service coupon stamps and schedule explained'),
                              value: _ownerManualProvided,
                              onChanged: (v) => setState(() => _ownerManualProvided = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Pre-Delivery Inspection (PDI) Passed & Verified'),
                              subtitle: const Text('Battery, electricals, torque check, fluid levels OK'),
                              value: _pdiFormSigned,
                              onChanged: (v) => setState(() => _pdiFormSigned = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Customer Acceptance & Vehicle Condition Signed'),
                              subtitle: const Text('Customer satisfied with physical condition and features walkthrough'),
                              value: _customerAcceptanceSigned,
                              onChanged: (v) => setState(() => _customerAcceptanceSigned = v ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 24),

                            // Handover Metrics
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _odometerKm.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Odometer Reading (KM)',
                                      suffixText: 'km',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => _odometerKm = double.tryParse(v) ?? 2.5,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _receivedByName,
                                    decoration: const InputDecoration(
                                      labelText: 'Received By Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _receivedByName = v,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Submit Handover Action
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _submitHandover,
                                icon: _isSaving
                                    ? const AppLoading(
                                        size: AppLoadingSize.small,
                                        color: Colors.white,
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded),
                                label: Text(
                                  'Confirm Handover, Generate Challan & Exit Gate Pass',
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
