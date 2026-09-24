import 'package:equatable/equatable.dart';
import 'purchase_order_item_entity.dart';

/// Purchase Order Domain Entity
///
/// A procurement document raised on a supplier: new vehicles from an OEM, or
/// spare parts, accessories and riding gear from a distributor.
class PurchaseOrderEntity extends Equatable {
  final String id;
  final String showroomId;
  final String supplierId;

  /// Vendor name as resolved for display. Not stored on the order.
  final String? supplierName;

  final String poNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;

  /// 'new_vehicle', 'spare_part', 'accessory', 'riding_gear' or 'service'.
  final String purchaseCategory;

  final double subtotal;
  final double taxAmount;
  final double otherCharges;
  final double totalAmount;
  final double paidAmount;

  /// 'unpaid', 'partial' or 'paid'.
  final String paymentStatus;

  /// 'draft', 'sent', 'partial', 'received' or 'cancelled'.
  final String status;

  final String? approvedBy;
  final String? notes;
  final List<PurchaseOrderItemEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseOrderEntity({
    required this.id,
    required this.showroomId,
    required this.supplierId,
    this.supplierName,
    required this.poNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.purchaseCategory = 'spare_part',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.otherCharges = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.paymentStatus = 'unpaid',
    this.status = 'draft',
    this.approvedBy,
    this.notes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get itemCount => items.length;

  int get totalQuantity => items.fold<int>(0, (sum, i) => sum + i.quantity);

  int get receivedQuantity => items.fold<int>(0, (sum, i) => sum + i.receivedQuantity);

  double get balanceAmount => totalAmount - paidAmount;

  /// Only a draft can still be edited or deleted.
  bool get isEditable => status == 'draft';

  bool get isCancelled => status == 'cancelled';

  /// A PO is receivable while it is issued and has lines still outstanding.
  bool get isReceivable =>
      (status == 'sent' || status == 'partial') &&
      items.any((i) => !i.isFullyReceived);

  /// Recomputes the header totals from the current line items.
  PurchaseOrderEntity withRecomputedTotals() {
    final sub = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final tax = items.fold<double>(0, (sum, i) => sum + i.taxAmount);

    return PurchaseOrderEntity(
      id: id,
      showroomId: showroomId,
      supplierId: supplierId,
      supplierName: supplierName,
      poNumber: poNumber,
      orderDate: orderDate,
      expectedDeliveryDate: expectedDeliveryDate,
      purchaseCategory: purchaseCategory,
      subtotal: sub,
      taxAmount: tax,
      otherCharges: otherCharges,
      totalAmount: sub + tax + otherCharges,
      paidAmount: paidAmount,
      paymentStatus: paymentStatus,
      status: status,
      approvedBy: approvedBy,
      notes: notes,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        showroomId,
        supplierId,
        supplierName,
        poNumber,
        orderDate,
        expectedDeliveryDate,
        purchaseCategory,
        subtotal,
        taxAmount,
        otherCharges,
        totalAmount,
        paidAmount,
        paymentStatus,
        status,
        approvedBy,
        notes,
        items,
        createdAt,
        updatedAt,
      ];
}
