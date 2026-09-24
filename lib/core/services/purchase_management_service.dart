import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'supplier_management_service.dart';
import '../../features/purchases/domain/entities/purchase_order_entity.dart';
import '../../features/purchases/domain/entities/purchase_order_item_entity.dart';
import '../../features/purchases/data/models/purchase_order_model.dart';
import '../../features/purchases/data/models/purchase_order_item_model.dart';

/// Purchase Order Management Service
///
/// Raises and tracks procurement documents against suppliers. Vehicle lines are
/// inwarded into stock from the Inventory module (Stock Inward), where the VIN,
/// engine and battery serial numbers are captured — a purchase order records
/// how much arrived, not the individual unit identities.
class PurchaseManagementService {
  static final PurchaseManagementService instance = PurchaseManagementService._();

  PurchaseManagementService._();

  /// Procurement categories. Keys are the stored `purchase_category` values.
  static const Map<String, String> categoryLabels = {
    'new_vehicle': 'New Vehicles',
    'spare_part': 'Spare Parts',
    'accessory': 'Accessories',
    'riding_gear': 'Riding Gear',
    'service': 'Service / Job Work',
  };

  static List<String> get categories => categoryLabels.keys.toList();

  static String categoryLabel(String category) =>
      categoryLabels[category] ?? category;

  /// Statuses a purchase order can be moved to from the detail screen.
  static const Map<String, String> statusLabels = {
    'draft': 'Draft',
    'sent': 'Sent to Vendor',
    'partial': 'Partially Received',
    'received': 'Received',
    'cancelled': 'Cancelled',
  };

  List<PurchaseOrderModel>? _devOrders;

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ─────────────────────────────────────────────
  // Fetch
  // ─────────────────────────────────────────────

  Future<List<PurchaseOrderEntity>> fetchPurchaseOrders({
    String? search,
    String? status,
    String? supplierId,
    String? purchaseCategory,
  }) async {
    if (_isSupabaseLive) {
      try {
        var query = SupabaseService.client!
            .from('purchase_orders')
            .select('*, purchase_order_items(*)');

        if (status != null && status.isNotEmpty) {
          query = query.eq('status', status);
        }
        if (supplierId != null && supplierId.isNotEmpty) {
          query = query.eq('supplier_id', supplierId);
        }
        if (purchaseCategory != null && purchaseCategory.isNotEmpty) {
          query = query.eq('purchase_category', purchaseCategory);
        }

        final rows = await query.order('order_date', ascending: false);
        var list = (rows as List)
            .map((row) => PurchaseOrderModel.fromJson(row as Map<String, dynamic>))
            .toList();

        await _attachSupplierNames(list);

        if (search != null && search.trim().isNotEmpty) {
          list = _applySearch(list, search);
        }
        return list;
      } catch (e) {
        debugPrint('Supabase fetchPurchaseOrders error: $e, falling back to dev mode');
      }
    }

    // ─── Dev Mode Fallback ───
    await SupabaseService.devLatency();
    _initDevData();
    var list = List<PurchaseOrderModel>.from(_devOrders!);

    if (status != null && status.isNotEmpty) {
      list = list.where((o) => o.status == status).toList();
    }
    if (supplierId != null && supplierId.isNotEmpty) {
      list = list.where((o) => o.supplierId == supplierId).toList();
    }
    if (purchaseCategory != null && purchaseCategory.isNotEmpty) {
      list = list.where((o) => o.purchaseCategory == purchaseCategory).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      list = _applySearch(list, search);
    }

    list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  Future<PurchaseOrderEntity?> fetchPurchaseOrderById(String id) async {
    if (_isSupabaseLive) {
      try {
        final row = await SupabaseService.client!
            .from('purchase_orders')
            .select('*, purchase_order_items(*)')
            .eq('id', id)
            .maybeSingle();

        if (row != null) {
          final order = PurchaseOrderModel.fromJson(row);
          final names = await _supplierNames([order.supplierId]);
          return PurchaseOrderModel.fromEntity(order)
              .copyWith(supplierName: names[order.supplierId]);
        }
      } catch (e) {
        debugPrint('Supabase fetchPurchaseOrderById error: $e, falling back to dev mode');
      }
    }

    await SupabaseService.devLatency();
    _initDevData();
    final matches = _devOrders!.where((o) => o.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Next PO number for this year, e.g. `PO-2026-0005`.
  ///
  /// Highest number rather than a count, so deleting a draft cannot hand out a
  /// number that is still in use.
  ///
  /// ponytail: max + 1 rather than a locked sequence — two simultaneous
  /// creates can collide, which the unique index on (showroom_id, po_number)
  /// rejects. Move to a Postgres sequence if that ever happens in practice.
  Future<String> generatePoNumber() async {
    final prefix = 'PO-${DateTime.now().year}-';
    Iterable<String>? existing;

    if (_isSupabaseLive) {
      try {
        final rows = await SupabaseService.client!
            .from('purchase_orders')
            .select('po_number')
            .like('po_number', '$prefix%');
        existing = (rows as List).map((r) => r['po_number'] as String);
      } catch (e) {
        debugPrint('Supabase generatePoNumber error: $e, falling back to dev mode');
      }
    }

    if (existing == null) {
      _initDevData();
      existing = _devOrders!.map((o) => o.poNumber);
    }

    return '$prefix${nextSerial(existing, prefix).toString().padLeft(4, '0')}';
  }

  /// One past the highest serial among [numbers] that start with [prefix].
  static int nextSerial(Iterable<String> numbers, String prefix) {
    var max = 0;
    for (final n in numbers) {
      if (!n.startsWith(prefix)) continue;
      final serial = int.tryParse(n.substring(prefix.length)) ?? 0;
      if (serial > max) max = serial;
    }
    return max + 1;
  }

  static List<PurchaseOrderModel> _applySearch(
    List<PurchaseOrderModel> list,
    String search,
  ) {
    final q = search.trim().toLowerCase();
    return list
        .where((o) =>
            o.poNumber.toLowerCase().contains(q) ||
            (o.supplierName?.toLowerCase().contains(q) ?? false) ||
            categoryLabel(o.purchaseCategory).toLowerCase().contains(q))
        .toList();
  }

  /// Fills in `supplierName` for display, in one query for the whole page.
  Future<void> _attachSupplierNames(List<PurchaseOrderModel> orders) async {
    if (orders.isEmpty) return;

    final names = await _supplierNames(orders.map((o) => o.supplierId).toSet());
    for (var i = 0; i < orders.length; i++) {
      orders[i] = orders[i].copyWith(supplierName: names[orders[i].supplierId]);
    }
  }

  Future<Map<String, String>> _supplierNames(Iterable<String> ids) async {
    if (!_isSupabaseLive) return const {};

    try {
      final suppliers = await SupplierManagementService.instance.fetchSuppliers();
      return {
        for (final s in suppliers)
          if (ids.contains(s.id)) s.id: s.name,
      };
    } catch (e) {
      debugPrint('Supabase supplier name lookup error: $e');
      return const {};
    }
  }

  // ─────────────────────────────────────────────
  // Create / Update
  // ─────────────────────────────────────────────

  Future<PurchaseOrderEntity> createPurchaseOrder(PurchaseOrderEntity entity) async {
    final order = PurchaseOrderModel.fromEntity(entity).recomputed();

    if (_isSupabaseLive) {
      try {
        final row = await SupabaseService.client!
            .from('purchase_orders')
            .insert(PurchaseOrderModel.fromEntity(order).toInsertJson())
            .select()
            .single();

        final saved = PurchaseOrderModel.fromJson(row);
        final items = await _replaceItems(saved.id, order.items);
        return PurchaseOrderModel.fromEntity(saved).copyWith(items: items);
      } catch (e) {
        debugPrint('Supabase createPurchaseOrder error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final items = _renumber(order.items, order.id);
    final stored = PurchaseOrderModel.fromEntity(order).copyWith(items: items);
    _devOrders!.insert(0, stored);
    return stored;
  }

  Future<PurchaseOrderEntity> updatePurchaseOrder(PurchaseOrderEntity entity) async {
    final now = DateTime.now();
    final order =
        PurchaseOrderModel.fromEntity(entity).recomputed().copyWith(updatedAt: now);

    if (_isSupabaseLive) {
      try {
        final payload = PurchaseOrderModel.fromEntity(order).toJson()
          ..remove('id')
          ..remove('created_at');

        final row = await SupabaseService.client!
            .from('purchase_orders')
            .update(payload)
            .eq('id', order.id)
            .select()
            .single();

        final saved = PurchaseOrderModel.fromJson(row);
        final items = await _replaceItems(saved.id, order.items);
        return PurchaseOrderModel.fromEntity(saved).copyWith(items: items);
      } catch (e) {
        debugPrint('Supabase updatePurchaseOrder error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final items = _renumber(order.items, order.id);
    final stored = PurchaseOrderModel.fromEntity(order).copyWith(items: items);

    final index = _devOrders!.indexWhere((o) => o.id == order.id);
    if (index != -1) _devOrders![index] = stored;
    return stored;
  }

  /// Whether a purchase order can be deleted — only an untouched draft.
  bool canDelete(PurchaseOrderEntity order) =>
      order.isEditable && order.receivedQuantity == 0;

  Future<void> deletePurchaseOrder(String id) async {
    if (_isSupabaseLive) {
      try {
        // Items cascade from the header.
        await SupabaseService.client!.from('purchase_orders').delete().eq('id', id);
        return;
      } catch (e) {
        debugPrint('Supabase deletePurchaseOrder error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    _devOrders!.removeWhere((o) => o.id == id);
  }

  /// Moves a purchase order to a new status.
  Future<void> updateStatus(String id, String status) async {
    if (_isSupabaseLive) {
      try {
        await SupabaseService.client!
            .from('purchase_orders')
            .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return;
      } catch (e) {
        debugPrint('Supabase updateStatus error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final index = _devOrders!.indexWhere((o) => o.id == id);
    if (index != -1) {
      _devOrders![index] =
          _devOrders![index].copyWith(status: status, updatedAt: DateTime.now());
    }
  }

  /// Records a goods receipt against a purchase order.
  ///
  /// [receivedQuantities] maps line item id to the quantity that arrived in
  /// this receipt. Lines left out are treated as not received. The order moves
  /// to `received` once every line is complete, otherwise `partial`.
  Future<PurchaseOrderEntity> receivePurchaseOrder(
    String id,
    Map<String, int> receivedQuantities,
  ) async {
    final order = await fetchPurchaseOrderById(id);
    if (order == null) {
      throw Exception('Purchase order not found');
    }

    final updatedItems = <PurchaseOrderItemEntity>[];
    for (final item in order.items) {
      final arrived = receivedQuantities[item.id] ?? 0;
      final newReceived =
          (item.receivedQuantity + arrived).clamp(0, item.quantity).toInt();

      updatedItems.add(PurchaseOrderItemModel.fromEntity(item).copyWith(
        receivedQuantity: newReceived,
      ));
    }

    final allReceived = updatedItems.every((i) => i.isFullyReceived);
    final anyReceived = updatedItems.any((i) => i.receivedQuantity > 0);
    final status = allReceived
        ? 'received'
        : (anyReceived ? 'partial' : order.status);

    if (_isSupabaseLive) {
      try {
        for (final item in updatedItems) {
          await SupabaseService.client!
              .from('purchase_order_items')
              .update({'received_quantity': item.receivedQuantity})
              .eq('id', item.id);
        }
        await updateStatus(id, status);
        return (await fetchPurchaseOrderById(id))!;
      } catch (e) {
        debugPrint('Supabase receivePurchaseOrder error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final updated = PurchaseOrderModel.fromEntity(order).copyWith(
      items: updatedItems,
      status: status,
      updatedAt: DateTime.now(),
    );

    final index = _devOrders!.indexWhere((o) => o.id == id);
    if (index != -1) _devOrders![index] = updated;
    return updated;
  }

  /// Replaces the line items of an order with [items].
  Future<List<PurchaseOrderItemEntity>> _replaceItems(
    String orderId,
    List<PurchaseOrderItemEntity> items,
  ) async {
    await SupabaseService.client!
        .from('purchase_order_items')
        .delete()
        .eq('purchase_order_id', orderId);

    if (items.isEmpty) return const [];

    final rows = await SupabaseService.client!
        .from('purchase_order_items')
        .insert(_renumber(items, orderId)
            .map((i) => PurchaseOrderItemModel.fromEntity(i).toInsertJson())
            .toList())
        .select();

    return (rows as List)
        .map((row) => PurchaseOrderItemModel.fromJson(row as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
  }

  /// Stamps the owning order and 1-based line numbers onto [items].
  static List<PurchaseOrderItemEntity> _renumber(
    List<PurchaseOrderItemEntity> items,
    String orderId,
  ) {
    final result = <PurchaseOrderItemEntity>[];
    for (var i = 0; i < items.length; i++) {
      result.add(PurchaseOrderItemModel.fromEntity(items[i]).copyWith(
        purchaseOrderId: orderId,
        lineNumber: i + 1,
      ));
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // Seeded Demo Purchase Orders
  // ─────────────────────────────────────────────

  void _initDevData() {
    if (_devOrders != null) return;

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    PurchaseOrderItemModel item({
      required String id,
      required String description,
      required int quantity,
      required double unitPrice,
      int received = 0,
      String itemType = 'spare_part',
      double taxRate = 18,
    }) {
      return PurchaseOrderItemModel(
        id: id,
        purchaseOrderId: '',
        description: description,
        itemType: itemType,
        quantity: quantity,
        receivedQuantity: received,
        unitPrice: unitPrice,
        taxRate: taxRate,
        lineTotal: quantity * unitPrice,
        createdAt: now,
      );
    }

    _devOrders = [
      PurchaseOrderModel(
        id: 'po-001',
        showroomId: 'sh-001',
        supplierId: 'sup-001',
        supplierName: 'Honda Motorcycle & Scooter India',
        poNumber: 'PO-${now.year}-0001',
        orderDate: thisMonth.subtract(const Duration(days: 12)),
        expectedDeliveryDate: thisMonth.add(const Duration(days: 8)),
        purchaseCategory: 'new_vehicle',
        status: 'partial',
        paymentStatus: 'partial',
        paidAmount: 500000,
        notes: 'Monthly allocation. Balance against delivery.',
        createdAt: thisMonth.subtract(const Duration(days: 12)),
        updatedAt: now,
        items: [
          item(
            id: 'poi-001',
            description: 'Honda Activa 6G STD — Pearl Precious White',
            itemType: 'new_vehicle',
            quantity: 12,
            unitPrice: 62000,
            received: 8,
            taxRate: 28,
          ),
          item(
            id: 'poi-002',
            description: 'Honda Shine 125 Disc — Matte Axis Grey',
            itemType: 'new_vehicle',
            quantity: 8,
            unitPrice: 71500,
            received: 8,
            taxRate: 28,
          ),
        ],
      ).recomputed(),
      PurchaseOrderModel(
        id: 'po-002',
        showroomId: 'sh-001',
        supplierId: 'sup-004',
        supplierName: 'Bharat Auto Parts & Accessories',
        poNumber: 'PO-${now.year}-0002',
        orderDate: thisMonth.subtract(const Duration(days: 6)),
        expectedDeliveryDate: thisMonth.add(const Duration(days: 2)),
        purchaseCategory: 'spare_part',
        status: 'sent',
        notes: 'Fast-moving service consumables.',
        createdAt: thisMonth.subtract(const Duration(days: 6)),
        updatedAt: now,
        items: [
          item(id: 'poi-003', description: 'Air Filter — Activa 6G', quantity: 60, unitPrice: 210),
          item(id: 'poi-004', description: 'Chain Sprocket Kit — Shine 125', quantity: 25, unitPrice: 1150),
          item(id: 'poi-005', description: 'Brake Pad Set — Front', quantity: 40, unitPrice: 320),
        ],
      ).recomputed(),
      PurchaseOrderModel(
        id: 'po-003',
        showroomId: 'sh-001',
        supplierId: 'sup-005',
        supplierName: 'TrailBlazer Riding Gear',
        poNumber: 'PO-${now.year}-0003',
        orderDate: thisMonth.subtract(const Duration(days: 3)),
        purchaseCategory: 'riding_gear',
        status: 'draft',
        notes: 'Awaiting margin approval before dispatch.',
        createdAt: thisMonth.subtract(const Duration(days: 3)),
        updatedAt: now,
        items: [
          item(id: 'poi-006', description: 'Full-Face Helmet — Large', quantity: 15, unitPrice: 2750),
          item(id: 'poi-007', description: 'Riding Jacket — Mesh, XL', quantity: 10, unitPrice: 3400),
        ],
      ).recomputed(),
      PurchaseOrderModel(
        id: 'po-004',
        showroomId: 'sh-001',
        supplierId: 'sup-002',
        supplierName: 'Ather Energy Ltd',
        poNumber: 'PO-${now.year}-0004',
        orderDate: thisMonth.subtract(const Duration(days: 24)),
        purchaseCategory: 'new_vehicle',
        status: 'received',
        paymentStatus: 'paid',
        paidAmount: 1116000,
        createdAt: thisMonth.subtract(const Duration(days: 24)),
        updatedAt: now,
        items: [
          item(
            id: 'poi-008',
            description: 'Ather 450X Gen 3 — Space Grey',
            itemType: 'new_vehicle',
            quantity: 6,
            unitPrice: 155000,
            received: 6,
            taxRate: 5,
          ),
        ],
      ).recomputed(),
    ];
  }
}
