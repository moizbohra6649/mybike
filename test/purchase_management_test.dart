import 'package:flutter_test/flutter_test.dart';
import 'package:mybike/core/services/purchase_management_service.dart';
import 'package:mybike/features/purchases/data/models/purchase_order_item_model.dart';

void main() {
  test('nextSerial skips past gaps left by deleted drafts', () {
    const prefix = 'PO-2026-';
    expect(PurchaseManagementService.nextSerial([], prefix), 1);
    // PO-2026-0002 was deleted: a count would return 3 and collide with 0003.
    expect(
      PurchaseManagementService.nextSerial(
        ['PO-2026-0001', 'PO-2026-0003', 'PO-2025-0099'],
        prefix,
      ),
      4,
    );
  });

  test('vehicle lines use the same key the form and database store', () {
    final line = PurchaseOrderItemModel(
      id: 'poi-1',
      purchaseOrderId: 'po-1',
      itemType: PurchaseManagementService.categories.first,
      description: 'Activa 6G',
      lineTotal: 0,
      createdAt: DateTime(2026),
    );
    expect(line.itemType, 'new_vehicle');
    expect(line.isVehicleLine, isTrue);
  });
}
