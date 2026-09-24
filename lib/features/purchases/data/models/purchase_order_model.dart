import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/entities/purchase_order_item_entity.dart';
import 'purchase_order_item_model.dart';

/// Purchase Order Model with JSON serialization for Supabase
class PurchaseOrderModel extends PurchaseOrderEntity {
  const PurchaseOrderModel({
    required super.id,
    required super.showroomId,
    required super.supplierId,
    super.supplierName,
    required super.poNumber,
    required super.orderDate,
    super.expectedDeliveryDate,
    super.purchaseCategory = 'spare_part',
    super.subtotal = 0,
    super.taxAmount = 0,
    super.otherCharges = 0,
    super.totalAmount = 0,
    super.paidAmount = 0,
    super.paymentStatus = 'unpaid',
    super.status = 'draft',
    super.approvedBy,
    super.notes,
    super.items = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    // Line items arrive embedded when the query asked for
    // `*, purchase_order_items(*)`; a header-only select has no such key.
    final rawItems = json['purchase_order_items'] as List?;

    return PurchaseOrderModel(
      id: json['id'] as String,
      showroomId: json['showroom_id'] as String,
      supplierId: json['supplier_id'] as String,
      poNumber: json['po_number'] as String,
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'] as String)
          : DateTime.now(),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      purchaseCategory: json['purchase_category'] as String? ?? 'spare_part',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      otherCharges: (json['other_charges'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      status: json['status'] as String? ?? 'draft',
      approvedBy: json['approved_by'] as String?,
      notes: json['notes'] as String?,
      items: rawItems == null
          ? const []
          : rawItems
              .map((row) =>
                  PurchaseOrderItemModel.fromJson(row as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.lineNumber.compareTo(b.lineNumber)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Header payload. Line items live in their own table and are written
  /// separately.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showroom_id': showroomId,
      'supplier_id': supplierId,
      'po_number': poNumber,
      'order_date': _dateOnly(orderDate),
      'expected_delivery_date':
          expectedDeliveryDate == null ? null : _dateOnly(expectedDeliveryDate!),
      'purchase_category': purchaseCategory,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'other_charges': otherCharges,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': paymentStatus,
      'status': status,
      'approved_by': approvedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Payload for an INSERT — the database assigns id and timestamps.
  Map<String, dynamic> toInsertJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The entity's total recomputation, kept as a model so callers can keep
  /// chaining model-only helpers such as [copyWith].
  PurchaseOrderModel recomputed() =>
      PurchaseOrderModel.fromEntity(withRecomputedTotals());

  factory PurchaseOrderModel.fromEntity(PurchaseOrderEntity entity) {
    return PurchaseOrderModel(
      id: entity.id,
      showroomId: entity.showroomId,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      poNumber: entity.poNumber,
      orderDate: entity.orderDate,
      expectedDeliveryDate: entity.expectedDeliveryDate,
      purchaseCategory: entity.purchaseCategory,
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      otherCharges: entity.otherCharges,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      paymentStatus: entity.paymentStatus,
      status: entity.status,
      approvedBy: entity.approvedBy,
      notes: entity.notes,
      items: entity.items,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PurchaseOrderModel copyWith({
    String? supplierId,
    String? supplierName,
    String? poNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? purchaseCategory,
    double? subtotal,
    double? taxAmount,
    double? otherCharges,
    double? totalAmount,
    double? paidAmount,
    String? paymentStatus,
    String? status,
    String? approvedBy,
    String? notes,
    List<PurchaseOrderItemEntity>? items,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderModel(
      id: id,
      showroomId: showroomId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      poNumber: poNumber ?? this.poNumber,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      purchaseCategory: purchaseCategory ?? this.purchaseCategory,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      otherCharges: otherCharges ?? this.otherCharges,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
