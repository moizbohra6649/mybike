import '../../domain/entities/invoice_sequence_entity.dart';

/// Data model for InvoiceSequence with Supabase JSON mapping
class InvoiceSequenceModel extends InvoiceSequenceEntity {
  const InvoiceSequenceModel({
    required super.id,
    required super.showroomId,
    super.financialYearId,
    required super.docType,
    required super.prefix,
    super.currentNumber,
    super.paddingZeros,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InvoiceSequenceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSequenceModel(
      id: json['id']?.toString() ?? '',
      showroomId: json['showroom_id']?.toString() ?? '',
      financialYearId: json['financial_year_id']?.toString(),
      docType: (json['doc_type'] ?? json['sequence_type'])?.toString() ?? 'sales_invoice',
      prefix: json['prefix']?.toString() ?? 'MB',
      currentNumber: (json['current_number'] as num?)?.toInt() ?? 0,
      paddingZeros: (json['padding_zeros'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showroom_id': showroomId,
      'financial_year_id': financialYearId,
      'sequence_type': docType,
      'prefix': prefix,
      'current_number': currentNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceSequenceModel.fromEntity(InvoiceSequenceEntity entity) {
    return InvoiceSequenceModel(
      id: entity.id,
      showroomId: entity.showroomId,
      financialYearId: entity.financialYearId,
      docType: entity.docType,
      prefix: entity.prefix,
      currentNumber: entity.currentNumber,
      paddingZeros: entity.paddingZeros,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
