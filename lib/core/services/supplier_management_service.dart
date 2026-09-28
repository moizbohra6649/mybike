import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/suppliers/domain/entities/supplier_entity.dart';
import '../../features/suppliers/data/models/supplier_model.dart';

/// Central Dealership Supplier / Vendor Master Service
///
/// Backs the Suppliers section: OEMs, spare-part distributors, accessory and
/// riding-gear dealers, and service vendors via live Supabase CRUD.
class SupplierManagementService {
  static final SupplierManagementService instance = SupplierManagementService._();

  SupplierManagementService._();

  /// Vendor categories. Keys are the stored `supplier_type` values.
  static const Map<String, String> supplierTypeLabels = {
    'oem': 'Vehicle OEM',
    'spare_parts': 'Spare Parts Distributor',
    'accessories': 'Accessories & Riding Gear',
    'service': 'Service Vendor',
    'other': 'Other',
  };

  static List<String> get supplierTypes => supplierTypeLabels.keys.toList();

  static String typeLabel(String type) => supplierTypeLabels[type] ?? 'Other';

  // Statutory format checks, shared by the form and the service.
  static final RegExp gstinRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  static final RegExp ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ─────────────────────────────────────────────
  // Fetch
  // ─────────────────────────────────────────────

  Future<List<SupplierEntity>> fetchSuppliers({
    String? search,
    String? supplierType,
    bool? isActive,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('suppliers').select();

      if (supplierType != null && supplierType.isNotEmpty && supplierType != 'all') {
        query = query.eq('supplier_type', supplierType);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final rows = await query.order('name', ascending: true);
      var list = (rows as List)
          .map((row) => SupplierModel.fromJson(row as Map<String, dynamic>))
          .toList();

      if (search != null && search.trim().isNotEmpty) {
        list = _applySearch(list, search);
      }
      return list;
    } catch (e) {
      debugPrint('Supabase fetchSuppliers error: $e');
      return [];
    }
  }

  Future<SupplierEntity?> fetchSupplierById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final row = await SupabaseService.client!
          .from('suppliers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row != null) return SupplierModel.fromJson(row);
      return null;
    } catch (e) {
      debugPrint('Supabase fetchSupplierById error: $e');
      return null;
    }
  }

  static List<SupplierModel> _applySearch(List<SupplierModel> list, String search) {
    final q = search.trim().toLowerCase();
    return list
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q) ||
            (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
            (s.phone.contains(q)) ||
            (s.gstin?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ─────────────────────────────────────────────
  // Create / Update / Toggle
  // ─────────────────────────────────────────────

  Future<SupplierEntity> createSupplier(SupplierEntity entity) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final model = SupplierModel.fromEntity(entity);
    final row = await SupabaseService.client!
        .from('suppliers')
        .insert(model.toInsertJson())
        .select()
        .single();
    return SupplierModel.fromJson(row);
  }

  Future<SupplierEntity> updateSupplier(SupplierEntity entity) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final now = DateTime.now();
    final model = SupplierModel.fromEntity(entity).copyWith(updatedAt: now);

    final payload = model.toJson()
      ..remove('id')
      ..remove('created_at');
    final row = await SupabaseService.client!
        .from('suppliers')
        .update(payload)
        .eq('id', model.id)
        .select()
        .single();
    return SupplierModel.fromJson(row);
  }

  Future<void> toggleSupplierStatus(String id, bool isActive) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!
          .from('suppliers')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      debugPrint('Supabase toggleSupplierStatus error: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    if (!_isSupabaseLive) return;

    try {
      await SupabaseService.client!.from('suppliers').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteSupplier error: $e');
      rethrow;
    }
  }
}
