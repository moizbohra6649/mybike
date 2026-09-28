import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'supplier_management_service.dart';
import '../../features/purchases/domain/entities/purchase_order_entity.dart';
import '../../features/purchases/domain/entities/purchase_order_item_entity.dart';
import '../../features/purchases/data/models/purchase_order_model.dart';
import '../../features/purchases/data/models/purchase_order_item_model.dart';

/// Central Dealership Purchase & Procurement Service
///
/// Backs Purchase Orders, receiving workflows, and OEM inwarding via live Supabase CRUD.
class PurchaseManagementService {
  static final PurchaseManagementService instance =
      PurchaseManagementService._();

  PurchaseManagementService._();

  static const Map<String, String> categoryLabels = {
    'vehicles': 'Vehicles',
    'spare_parts': 'Spare Parts',
    'accessories': 'Accessories & Gear',
    'service_consumables': 'Service Consumables',
    'other': 'Other',
  };

  static List<String> get categories => categoryLabels.keys.toList();

  static String categoryLabel(String category) =>
      categoryLabels[category] ?? 'Other';

  static const Map<String, String> statusLabels = {
    'draft': 'Draft',
    'submitted': 'Submitted',
    'approved': 'Approved',
    'partially_received': 'Partially Received',
    'received': 'Received',
    'cancelled': 'Cancelled',
  };

  static int nextSerial(List<String> existingNumbers, String prefix) {
    var maxSerial = 0;
    for (final num in existingNumbers) {
      if (num.startsWith(prefix)) {
        final rest = num.substring(prefix.length);
        final serial = int.tryParse(rest) ?? 0;
        if (serial > maxSerial) maxSerial = serial;
      }
    }
    return maxSerial + 1;
  }

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
    String? showroomId,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!
          .from('purchase_orders')
          .select('*, purchase_order_items(*)');

      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        query = query.eq('supplier_id', supplierId);
      }
      if (purchaseCategory != null && purchaseCategory.isNotEmpty && purchaseCategory != 'all') {
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
      debugPrint('Supabase fetchPurchaseOrders error: $e');
      return [];
    }
  }

  Future<PurchaseOrderEntity?> fetchPurchaseOrderById(String id) async {
    if (!_isSupabaseLive) return null;

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
      return null;
    } catch (e) {
      debugPrint('Supabase fetchPurchaseOrderById error: $e');
      return null;
    }
  }

  Future<String> nextPoNumber(String showroomPrefix) async {
    final year = DateTime.now().year;
    final prefix = 'PO-$year-';

    if (_isSupabaseLive) {
      try {
        final rows = await SupabaseService.client!
            .from('purchase_orders')
            .select('po_number')
            .like('po_number', '$prefix%')
            .order('po_number', ascending: false)
            .limit(1);

        var nextSeq = 1;
        if ((rows as List).isNotEmpty) {
          final top = rows.first['po_number'] as String;
          final match = RegExp(r'(\d+)$').firstMatch(top);
          if (match != null) {
            nextSeq = (int.tryParse(match.group(1)!) ?? 0) + 1;
          }
        }
        return '$prefix${nextSeq.toString().padLeft(4, '0')}';
      } catch (e) {
        debugPrint('Supabase nextPoNumber error: $e');
      }
    }

    return '$prefix${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final order = PurchaseOrderModel.fromEntity(entity).recomputed();

    final row = await SupabaseService.client!
        .from('purchase_orders')
        .insert(PurchaseOrderModel.fromEntity(order).toInsertJson())
        .select()
        .single();

    final saved = PurchaseOrderModel.fromJson(row);
    final items = await _replaceItems(saved.id, order.items);
    return PurchaseOrderModel.fromEntity(saved).copyWith(items: items);
  }

  Future<PurchaseOrderEntity> updatePurchaseOrder(PurchaseOrderEntity entity) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final now = DateTime.now();
    final order =
        PurchaseOrderModel.fromEntity(entity).recomputed().copyWith(updatedAt: now);

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
  }

  Future<PurchaseOrderEntity> updateStatus(
    String id,
    String newStatus, {
    String? rejectionReason,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final patch = <String, dynamic>{
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (rejectionReason != null) {
      patch['rejection_reason'] = rejectionReason;
    }

    final row = await SupabaseService.client!
        .from('purchase_orders')
        .update(patch)
        .eq('id', id)
        .select('*, purchase_order_items(*)')
        .single();

    final saved = PurchaseOrderModel.fromJson(row);
    final names = await _supplierNames([saved.supplierId]);
    return PurchaseOrderModel.fromEntity(saved)
        .copyWith(supplierName: names[saved.supplierId]);
  }

  Future<void> deletePurchaseOrder(String id) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!
          .from('purchase_orders')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Supabase deletePurchaseOrder error: $e');
      rethrow;
    }
  }

  bool canDelete(PurchaseOrderEntity order) => order.status == 'draft';

  Future<String> generatePoNumber([String? showroomId]) async {
    final year = DateTime.now().year;
    final prefix = 'PO-$year-';
    final orders = await fetchPurchaseOrders();
    final serial = nextSerial(orders.map((o) => o.poNumber).toList(), prefix);
    return '$prefix${serial.toString().padLeft(4, '0')}';
  }

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
        : (anyReceived ? 'partially_received' : order.status);

    if (_isSupabaseLive) {
      for (final item in updatedItems) {
        await SupabaseService.client!
            .from('purchase_order_items')
            .update({'received_quantity': item.receivedQuantity})
            .eq('id', item.id);
      }
      return await updateStatus(id, status);
    }
    return order;
  }

  Future<List<PurchaseOrderItemEntity>> _replaceItems(
    String poId,
    List<PurchaseOrderItemEntity> items,
  ) async {
    await SupabaseService.client!
        .from('purchase_order_items')
        .delete()
        .eq('purchase_order_id', poId);

    if (items.isEmpty) return const [];

    final payloads = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final m = PurchaseOrderItemModel.fromEntity(item)
          .copyWith(purchaseOrderId: poId, lineNumber: i + 1);
      final json = PurchaseOrderItemModel.fromEntity(m).toJson()
        ..remove('id')
        ..remove('created_at');
      payloads.add(json);
    }

    final inserted = await SupabaseService.client!
        .from('purchase_order_items')
        .insert(payloads)
        .select();

    return (inserted as List)
        .map((r) => PurchaseOrderItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
