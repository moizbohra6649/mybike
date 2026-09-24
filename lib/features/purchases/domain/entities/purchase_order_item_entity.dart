import 'package:equatable/equatable.dart';

/// Purchase Order Line Item Entity
///
/// [unitPrice] and [lineTotal] are exclusive of tax — [taxAmount] is derived
/// from [taxRate], so the order can show a taxable value, a tax value and the
/// gross total separately, the way a GST purchase bill reads.
class PurchaseOrderItemEntity extends Equatable {
  final String id;
  final String purchaseOrderId;
  final int lineNumber;

  /// One of the `purchase_category` values on the parent order:
  /// 'new_vehicle', 'spare_part', 'accessory', 'riding_gear' or 'service'.
  final String itemType;

  /// Set only for vehicle lines — the variant and colour that get inwarded
  /// into stock when this line is received.
  final String? variantId;
  final String? colorId;

  final String description;
  final String? hsnCode;
  final int quantity;
  final int receivedQuantity;
  final double unitPrice;
  final double taxRate;

  /// Taxable line value: quantity × unit price, before tax.
  final double lineTotal;
  final DateTime createdAt;

  const PurchaseOrderItemEntity({
    required this.id,
    required this.purchaseOrderId,
    this.lineNumber = 1,
    this.itemType = 'spare_part',
    this.variantId,
    this.colorId,
    required this.description,
    this.hsnCode,
    this.quantity = 1,
    this.receivedQuantity = 0,
    this.unitPrice = 0,
    this.taxRate = 18,
    required this.lineTotal,
    required this.createdAt,
  });

  /// True for lines procured as new vehicles, as opposed to parts and gear.
  bool get isVehicleLine => itemType == 'new_vehicle';

  int get pendingQuantity => quantity - receivedQuantity;

  bool get isFullyReceived => receivedQuantity >= quantity;

  double get taxAmount => lineTotal * taxRate / 100;

  double get totalAmount => lineTotal + taxAmount;

  @override
  List<Object?> get props => [
        id,
        purchaseOrderId,
        lineNumber,
        itemType,
        variantId,
        colorId,
        description,
        hsnCode,
        quantity,
        receivedQuantity,
        unitPrice,
        taxRate,
        lineTotal,
        createdAt,
      ];
}
