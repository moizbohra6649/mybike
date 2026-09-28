import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'showroom_management_service.dart';
import 'vehicle_master_service.dart';
import '../../features/inventory/domain/entities/inventory_vehicle_entity.dart';
import '../../features/inventory/domain/entities/stock_transfer_entity.dart';
import '../../features/inventory/domain/entities/stock_movement_entity.dart';
import '../../features/inventory/domain/entities/vehicle_inventory_item.dart';
import '../../features/inventory/data/models/inventory_vehicle_model.dart';
import '../../features/inventory/data/models/stock_transfer_model.dart';
import '../../features/inventory/data/models/stock_movement_model.dart';

/// DTO for inwarding a single serialized vehicle unit
class InwardVehicleUnit {
  final String vin;
  final String? engineNumber;
  final String? motorNumber;
  final String? batterySerialNumber;
  final String? keyNumber;
  final double purchaseCost;
  final String mfgYearMonth;
  final String locationInShowroom;

  const InwardVehicleUnit({
    required this.vin,
    this.engineNumber,
    this.motorNumber,
    this.batterySerialNumber,
    this.keyNumber,
    this.purchaseCost = 0.0,
    this.mfgYearMonth = '2026-01',
    this.locationInShowroom = 'Main Display Area',
  });
}

/// Comprehensive Inventory & Stock Management Service
///
/// Handles serialized vehicle stock, GRN factory inwarding, PDI checklists,
/// and live movements directly backed by Supabase.
class InventoryManagementService {
  InventoryManagementService._();
  static final InventoryManagementService instance = InventoryManagementService._();

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ─────────────────────────────────────────────
  // 1. INVENTORY QUERIES
  // ─────────────────────────────────────────────

  Future<List<VehicleInventoryItem>> fetchInventory({
    String? showroomId,
    String? variantId,
    String? status,
    String? pdiStatus,
    String? search,
    String? powertrain, // 'petrol', 'electric'
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('inventory_vehicles').select();
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (variantId != null && variantId.isNotEmpty) {
        query = query.eq('variant_id', variantId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (pdiStatus != null && pdiStatus.isNotEmpty && pdiStatus != 'all') {
        query = query.eq('pdi_status', pdiStatus);
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        query = query.or('vin.ilike.%$s%,engine_number.ilike.%$s%,motor_number.ilike.%$s%,key_number.ilike.%$s%');
      }

      final data = await query.order('created_at', ascending: false);
      final rawVehicles = (data as List).map((row) => InventoryVehicleModel.fromJson(row)).toList();

      return _hydrateVehicles(rawVehicles, powertrain: powertrain);
    } catch (e) {
      debugPrint('Supabase fetchInventory error: $e');
      return [];
    }
  }

  Future<List<VehicleInventoryItem>> _hydrateVehicles(
    List<InventoryVehicleEntity> vehicles, {
    String? powertrain,
  }) async {
    final showrooms = await ShowroomManagementService.instance.fetchShowrooms();
    final showroomMap = {for (final s in showrooms) s.showroom.id: s.showroom};

    final catalog = await VehicleMasterService.instance.fetchCatalogItems();
    final modelsMap = {for (final item in catalog) item.model.id: item.model};
    final brandsMap = {for (final item in catalog) if (item.brand != null) item.brand!.id: item.brand!};

    final allVariants = catalog.expand((c) => c.variants).toList();
    final variantMap = {for (final v in allVariants) v.id: v};

    final allColors = catalog.expand((c) => c.colors).toList();
    final colorMap = {for (final col in allColors) col.id: col};

    final results = <VehicleInventoryItem>[];
    for (final v in vehicles) {
      final variant = variantMap[v.variantId];
      final model = variant != null ? modelsMap[variant.modelId] : null;
      final brand = model != null ? brandsMap[model.brandId] : null;
      final color = colorMap[v.colorId];
      final showroom = showroomMap[v.showroomId];

      // Filter by powertrain if specified
      if (powertrain != null && powertrain.isNotEmpty && powertrain != 'all') {
        if (powertrain == 'petrol' && (model?.isPetrol != true && !v.isPetrol)) continue;
        if (powertrain == 'electric' && (model?.isElectric != true && !v.isElectric)) continue;
      }

      results.add(VehicleInventoryItem(
        vehicle: v,
        model: model,
        variant: variant,
        brand: brand,
        color: color,
        showroom: showroom,
      ));
    }

    return results;
  }

  Future<VehicleInventoryItem?> fetchVehicleById(String id) async {
    final items = await fetchInventory();
    return items.where((i) => i.vehicle.id == id).firstOrNull;
  }

  Future<VehicleInventoryItem?> fetchVehicleByVin(String vin) async {
    final items = await fetchInventory();
    return items.where((i) => i.vehicle.vin.toUpperCase() == vin.toUpperCase()).firstOrNull;
  }

  // ─────────────────────────────────────────────
  // 2. INWARDING (GRN BATCH)
  // ─────────────────────────────────────────────

  Future<List<InventoryVehicleEntity>> inwardStock({
    required String showroomId,
    required String variantId,
    required String colorId,
    required List<InwardVehicleUnit> units,
    String? remarks,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final now = DateTime.now();
    final createdList = <InventoryVehicleEntity>[];

    for (final unit in units) {
      final payload = <String, dynamic>{
        'showroom_id': showroomId,
        'variant_id': variantId,
        'color_id': colorId,
        'vin': unit.vin.trim().toUpperCase(),
        'engine_number': unit.engineNumber?.trim().isNotEmpty == true ? unit.engineNumber!.trim() : null,
        'motor_number': unit.motorNumber?.trim().isNotEmpty == true ? unit.motorNumber!.trim() : null,
        'battery_serial_number': unit.batterySerialNumber?.trim().isNotEmpty == true ? unit.batterySerialNumber!.trim() : null,
        'key_number': unit.keyNumber?.trim().isNotEmpty == true ? unit.keyNumber!.trim() : null,
        'status': 'in_stock',
        'purchase_cost': unit.purchaseCost,
        'received_date': now.toIso8601String().split('T').first,
        'mfg_year_month': unit.mfgYearMonth,
        'battery_health_percentage': unit.motorNumber != null ? 100.0 : null,
        'odometer_reading_km': 0.0,
        'location_in_showroom': unit.locationInShowroom,
        'pdi_status': 'pending',
      };

      try {
        final res = await SupabaseService.client!
            .from('inventory_vehicles')
            .insert(payload)
            .select()
            .single();

        final created = InventoryVehicleModel.fromJson(res);
        createdList.add(created);

        await logStockMovement(
          vehicleId: created.id,
          movementType: 'inward_grn',
          toShowroomId: showroomId,
          remarks: remarks ?? 'Factory Inward (GRN)',
        );
      } catch (e) {
        debugPrint('Supabase inwardStock unit error: $e');
        rethrow;
      }
    }

    return createdList;
  }

  // ─────────────────────────────────────────────
  // 3. STATUS & PDI UPDATES
  // ─────────────────────────────────────────────

  Future<void> updateVehicleStatus(String vehicleId, String status, {String? remarks}) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!
          .from('inventory_vehicles')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', vehicleId);

      await logStockMovement(
        vehicleId: vehicleId,
        movementType: 'status_adjustment',
        remarks: remarks ?? 'Status changed to $status',
      );
    } catch (e) {
      debugPrint('Supabase updateVehicleStatus error: $e');
      rethrow;
    }
  }

  Future<void> updatePdiStatus(String vehicleId, String pdiStatus, {String? notes}) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!
          .from('inventory_vehicles')
          .update({
            'pdi_status': pdiStatus,
            'pdi_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vehicleId);

      await logStockMovement(
        vehicleId: vehicleId,
        movementType: 'pdi_status_update',
        remarks: 'PDI Inspection status marked: $pdiStatus. ${notes ?? ""}',
      );
    } catch (e) {
      debugPrint('Supabase updatePdiStatus error: $e');
      rethrow;
    }
  }

  Future<void> updateVehicleLocation(String vehicleId, String location, {String? remarks}) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!
          .from('inventory_vehicles')
          .update({
            'location_in_showroom': location,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vehicleId);

      await logStockMovement(
        vehicleId: vehicleId,
        movementType: 'bay_location_change',
        remarks: remarks ?? 'Relocated to $location',
      );
    } catch (e) {
      debugPrint('Supabase updateVehicleLocation error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // 4. INTER-SHOWROOM STOCK TRANSFERS
  // ─────────────────────────────────────────────

  Future<List<StockTransferEntity>> fetchStockTransfers({
    String? showroomId,
    String? status,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('stock_transfers').select('*, stock_transfer_items(*)');
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.or('source_showroom_id.eq.$showroomId,destination_showroom_id.eq.$showroomId');
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((row) => StockTransferModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchStockTransfers error: $e');
      return [];
    }
  }

  Future<StockTransferEntity> createStockTransfer({
    required String sourceShowroomId,
    required String destinationShowroomId,
    required List<String> vehicleIds,
    String? notes,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final now = DateTime.now();
    final transferNumber = 'TRF-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final res = await SupabaseService.client!
        .from('stock_transfers')
        .insert({
          'transfer_number': transferNumber,
          'source_showroom_id': sourceShowroomId,
          'destination_showroom_id': destinationShowroomId,
          'status': 'requested',
          'notes': notes,
        })
        .select()
        .single();

    final transfer = StockTransferModel.fromJson(res);

    for (final vId in vehicleIds) {
      await SupabaseService.client!.from('stock_transfer_items').insert({
        'transfer_id': transfer.id,
        'vehicle_id': vId,
        'status': 'pending',
      });
    }

    return transfer;
  }

  Future<void> dispatchStockTransfer(String transferId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!
          .from('stock_transfers')
          .update({
            'status': 'in_transit',
            'dispatched_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transferId);
    } catch (e) {
      debugPrint('Supabase dispatchStockTransfer error: $e');
    }
  }

  Future<void> receiveStockTransfer(String transferId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!
          .from('stock_transfers')
          .update({
            'status': 'received',
            'received_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transferId);
    } catch (e) {
      debugPrint('Supabase receiveStockTransfer error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // 5. MOVEMENTS & AUDIT LOG
  // ─────────────────────────────────────────────

  Future<List<StockMovementEntity>> fetchVehicleMovements(String vehicleId) async {
    if (!_isSupabaseLive) return [];

    try {
      final data = await SupabaseService.client!
          .from('stock_movements')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);
      return (data as List).map((row) => StockMovementModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchVehicleMovements error: $e');
      return [];
    }
  }

  Future<void> logStockMovement({
    required String vehicleId,
    required String movementType,
    String? fromShowroomId,
    String? toShowroomId,
    String? performedBy,
    String? remarks,
  }) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!.from('stock_movements').insert({
        'vehicle_id': vehicleId,
        'movement_type': movementType,
        'from_showroom_id': fromShowroomId,
        'to_showroom_id': toShowroomId,
        'performed_by': performedBy,
        'remarks': remarks,
      });
    } catch (e) {
      debugPrint('Supabase logStockMovement error: $e');
    }
  }
}
