import '../../domain/entities/purchase_order_item_entity.dart';

/// Purchase Order Line Item Model with JSON serialization for Supabase
class PurchaseOrderItemModel extends PurchaseOrderItemEntity {
  const PurchaseOrderItemModel({
    required super.id,
    required super.purchaseOrderId,
    super.lineNumber = 1,
    super.itemType = 'spare_part',
    super.variantId,
    super.colorId,
    required super.description,
    super.hsnCode,
    super.quantity = 1,
    super.receivedQuantity = 0,
    super.unitPrice = 0,
    super.taxRate = 18,
    required super.lineTotal,
    required super.createdAt,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      id: json['id'] as String,
      purchaseOrderId: json['purchase_order_id'] as String,
      lineNumber: (json['line_number'] as num?)?.toInt() ?? 1,
      itemType: json['item_type'] as String? ?? 'spare_part',
      variantId: json['variant_id'] as String?,
      colorId: json['color_id'] as String?,
      description: json['description'] as String,
      hsnCode: json['hsn_code'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      receivedQuantity: (json['received_quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'line_number': lineNumber,
      'item_type': itemType,
      'variant_id': variantId,
      'color_id': colorId,
      'description': description,
      'hsn_code': hsnCode,
      'quantity': quantity,
      'received_quantity': receivedQuantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'line_total': lineTotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Payload for an INSERT — the database assigns id and created_at.
  Map<String, dynamic> toInsertJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at');
  }

  factory PurchaseOrderItemModel.fromEntity(PurchaseOrderItemEntity entity) {
    return PurchaseOrderItemModel(
      id: entity.id,
      purchaseOrderId: entity.purchaseOrderId,
      lineNumber: entity.lineNumber,
      itemType: entity.itemType,
      variantId: entity.variantId,
      colorId: entity.colorId,
      description: entity.description,
      hsnCode: entity.hsnCode,
      quantity: entity.quantity,
      receivedQuantity: entity.receivedQuantity,
      unitPrice: entity.unitPrice,
      taxRate: entity.taxRate,
      lineTotal: entity.lineTotal,
      createdAt: entity.createdAt,
    );
  }

  PurchaseOrderItemModel copyWith({
    String? purchaseOrderId,
    int? lineNumber,
    String? itemType,
    String? variantId,
    String? colorId,
    String? description,
    String? hsnCode,
    int? quantity,
    int? receivedQuantity,
    double? unitPrice,
    double? taxRate,
    double? lineTotal,
  }) {
    return PurchaseOrderItemModel(
      id: id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      lineNumber: lineNumber ?? this.lineNumber,
      itemType: itemType ?? this.itemType,
      variantId: variantId ?? this.variantId,
      colorId: colorId ?? this.colorId,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt,
    );
  }
}
