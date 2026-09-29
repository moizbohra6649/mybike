import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../common/loaders/app_loading.dart';
import '../../../../common/widgets/responsive_field_row.dart';
import '../../../../common/widgets/app_dropdown.dart';
import '../../domain/entities/dealership_document_entity.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';

class DocumentUploadModal extends StatefulWidget {
  final String? initialEntityType;
  final String? initialEntityId;
  final String? initialCategory;
  final Function(DealershipDocumentEntity doc) onDocumentUploaded;

  const DocumentUploadModal({
    super.key,
    this.initialEntityType,
    this.initialEntityId,
    this.initialCategory,
    required this.onDocumentUploaded,
  });

  @override
  State<DocumentUploadModal> createState() => _DocumentUploadModalState();
}

class _DocumentUploadModalState extends State<DocumentUploadModal> {
  final _formKey = GlobalKey<FormState>();

  late String _entityType;
  late String _documentCategory;
  final TextEditingController _entityIdController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  DateTime? _expiryDate;
  String _fileFormat = 'application/pdf';
  int _simulatedSize = 450 * 1024; // 450 KB

  final List<Map<String, String>> _entityTypes = [
    {'value': 'customer', 'label': 'Customer'},
    {'value': 'vehicle', 'label': 'Vehicle / Inventory'},
    {'value': 'booking', 'label': 'Booking Order'},
    {'value': 'invoice', 'label': 'Sales Invoice'},
    {'value': 'purchase', 'label': 'Purchase Order'},
    {'value': 'showroom', 'label': 'Showroom Statutory'},
    {'value': 'general', 'label': 'General / Corporate'},
  ];

  final List<Map<String, String>> _documentCategories = [
    {'value': 'kyc', 'label': 'Customer KYC (Aadhaar, PAN, DL)'},
    {'value': 'rto_registration', 'label': 'RTO Registration (Form 20, 21, RC)'},
    {'value': 'insurance', 'label': 'Insurance Policy & Cover Note'},
    {'value': 'warranty', 'label': 'Warranty & RSA Certificate'},
    {'value': 'delivery', 'label': 'Gate Pass & Delivery Acknowledgement'},
    {'value': 'purchase_invoice', 'label': 'OEM Purchase Invoice & Consignment'},
    {'value': 'factory_gatepass', 'label': 'Factory Inward Gate Pass'},
    {'value': 'hypothecation', 'label': 'Hypothecation / Bank NOC (Form 34/35)'},
    {'value': 'puc', 'label': 'PUC Certificate'},
    {'value': 'other', 'label': 'Other Supporting Document'},
  ];

  @override
  void initState() {
    super.initState();
    _entityType = widget.initialEntityType ?? 'customer';
    _documentCategory = widget.initialCategory ?? 'kyc';
    if (widget.initialEntityId != null) {
      _entityIdController.text = widget.initialEntityId!;
    }
    _documentTypeController.text = 'Aadhaar Card';
    _fileNameController.text = 'aadhaar_card_scan.pdf';
  }

  @override
  void dispose() {
    _entityIdController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _notesController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _documentCategory = category;
      switch (category) {
        case 'kyc':
          _documentTypeController.text = 'Aadhaar Card';
          _fileNameController.text = 'aadhaar_front_back.pdf';
          break;
        case 'rto_registration':
          _documentTypeController.text = 'Form 20 Sales Certificate';
          _fileNameController.text = 'form_20_sales_cert.pdf';
          break;
        case 'insurance':
          _documentTypeController.text = 'Comprehensive 5-Year Policy';
          _fileNameController.text = 'icici_lombard_policy.pdf';
          break;
        case 'warranty':
          _documentTypeController.text = 'Extended Warranty Certificate';
          _fileNameController.text = 'extended_warranty_cert.pdf';
          break;
        case 'delivery':
          _documentTypeController.text = 'Customer Delivery Gate Pass';
          _fileNameController.text = 'delivery_acknowledgement.pdf';
          break;
        case 'purchase_invoice':
          _documentTypeController.text = 'OEM Factory Tax Invoice';
          _fileNameController.text = 'tvs_factory_invoice.pdf';
          break;
        case 'factory_gatepass':
          _documentTypeController.text = 'Inward Consignment Note';
          _fileNameController.text = 'consignment_gate_pass.pdf';
          break;
        case 'hypothecation':
          _documentTypeController.text = 'Form 34 Bank Hypothecation';
          _fileNameController.text = 'form_34_hypothecation.pdf';
          break;
        case 'puc':
          _documentTypeController.text = 'Pollution Under Control (PUC)';
          _fileNameController.text = 'puc_certificate.pdf';
          break;
        default:
          _documentTypeController.text = 'Supporting Document';
          _fileNameController.text = 'document_scan.pdf';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocProvider(
      create: (_) => DocumentUploadCubit(),
      child: BlocConsumer<DocumentUploadCubit, DocumentUploadState>(
        listener: (context, state) {
          if (state is DocumentUploadSuccess) {
            widget.onDocumentUploaded(state.document);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document "${state.document.fileName}" registered successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is DocumentUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is DocumentUploadSubmitting;

          return Dialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryYellowDark, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload New Dealership Document',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Attach customer KYC, RTO certificate, insurance policy, or gate pass',
                                  style: AppTypography.captionMedium.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Entity Type & Entity ID Row
                      ResponsiveFieldRow(
                        children: [
                          AppDropdown<String>(
                            label: 'Linked Entity',
                            isRequired: true,
                            value: _entityType,
                            prefixIcon: Icons.link,
                            items: _entityTypes.map((type) => type['value']!).toList(),
                            itemLabel: (val) {
                              final match = _entityTypes.where((t) => t['value'] == val);
                              if (match.isNotEmpty) return match.first['label']!;
                              return val;
                            },
                            onChanged: (val) {
                              if (val != null) setState(() => _entityType = val);
                            },
                          ),
                          TextFormField(
                            controller: _entityIdController,
                            decoration: const InputDecoration(
                              labelText: 'Entity ID / Code *',
                              hintText: 'e.g. cust-01, veh-02',
                              prefixIcon: Icon(Icons.tag, size: 18),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Entity ID is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Document Category
                      AppDropdown<String>(
                        label: 'Document Category',
                        isRequired: true,
                        value: _documentCategory,
                        prefixIcon: Icons.category_outlined,
                        items: _documentCategories.map((cat) => cat['value']!).toList(),
                        itemLabel: (val) {
                          final match = _documentCategories.where((c) => c['value'] == val);
                          if (match.isNotEmpty) return match.first['label']!;
                          return val;
                        },
                        onChanged: _onCategoryChanged,
                      ),
                      const SizedBox(height: 16),

                      // Document Type & Document Number
                      ResponsiveFieldRow(
                        flexes: const [3, 2],
                        children: [
                          TextFormField(
                            controller: _documentTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Document Name / Type *',
                              hintText: 'e.g. Aadhaar Card, Form 20',
                              prefixIcon: Icon(Icons.badge_outlined, size: 18),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Document name is required';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _documentNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Doc Number / Ref',
                              hintText: 'e.g. DL-1420110012345',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Simulated File Dropzone Container
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: AppColors.primaryYellow.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_file, color: AppColors.primaryYellowDark, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Attached File Details',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                                  ),
                                ),
                                const Spacer(),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'application/pdf', label: Text('PDF')),
                                    ButtonSegment(value: 'image/jpeg', label: Text('Image')),
                                  ],
                                  selected: {_fileFormat},
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _fileFormat = selection.first;
                                      if (_fileFormat.contains('pdf')) {
                                        if (!_fileNameController.text.endsWith('.pdf')) {
                                          _fileNameController.text = '${_fileNameController.text.split('.').first}.pdf';
                                        }
                                        _simulatedSize = 480 * 1024;
                                      } else {
                                        if (!_fileNameController.text.endsWith('.jpg')) {
                                          _fileNameController.text = '${_fileNameController.text.split('.').first}.jpg';
                                        }
                                        _simulatedSize = 820 * 1024;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _fileNameController,
                              decoration: const InputDecoration(
                                labelText: 'File Name *',
                                hintText: 'filename.pdf',
                                prefixIcon: Icon(Icons.insert_drive_file_outlined, size: 18),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'File name is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Expiry Date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined, color: AppColors.primaryYellowDark),
                        title: Text(
                          _expiryDate == null
                              ? 'Document Expiry Date (Optional)'
                              : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) {
                              setState(() => _expiryDate = picked);
                            }
                          },
                          child: Text(_expiryDate == null ? 'Set Date' : 'Change'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Notes input
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes / Remarks',
                          hintText: 'e.g. Original physically inspected at Rajkot branch',
                          prefixIcon: Icon(Icons.notes_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    if (!_formKey.currentState!.validate()) return;
                                    context.read<DocumentUploadCubit>().uploadDocument(
                                          entityType: _entityType,
                                          entityId: _entityIdController.text.trim(),
                                          documentCategory: _documentCategory,
                                          documentType: _documentTypeController.text.trim(),
                                          documentNumber: _documentNumberController.text.trim().isEmpty
                                              ? null
                                              : _documentNumberController.text.trim(),
                                          fileName: _fileNameController.text.trim(),
                                          fileSize: _simulatedSize,
                                          mimeType: _fileFormat,
                                          expiryDate: _expiryDate,
                                          uploadedBy: 'Store Executive',
                                          notes: _notesController.text.trim().isEmpty
                                              ? null
                                              : _notesController.text.trim(),
                                        );
                                  },
                            icon: isSubmitting
                                // The themed spinner colour is the same yellow
                                // as this button, so it has to be told to use
                                // the button's own foreground instead.
                                ? const AppLoading(
                                    size: AppLoadingSize.small,
                                    color: AppColors.primaryBlack,
                                  )
                                : const Icon(Icons.cloud_upload, size: 18),
                            label: Text(isSubmitting ? 'Uploading...' : 'Upload & Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
