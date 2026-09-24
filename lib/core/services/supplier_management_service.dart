import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/suppliers/domain/entities/supplier_entity.dart';
import '../../features/suppliers/data/models/supplier_model.dart';

/// Central Dealership Supplier / Vendor Master Service
///
/// Backs the Suppliers section: OEMs, spare-part distributors, accessory and
/// riding-gear dealers, and service vendors. Falls back to seeded in-memory
/// vendors while running on demo data.
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

  List<SupplierModel>? _devSuppliers;

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
    if (_isSupabaseLive) {
      try {
        // Filters first: order() returns a transform builder that no longer
        // accepts eq().
        var query = SupabaseService.client!.from('suppliers').select();

        if (supplierType != null && supplierType.isNotEmpty) {
          query = query.eq('supplier_type', supplierType);
        }
        if (isActive != null) {
          query = query.eq('is_active', isActive);
        }

        final rows = await query.order('name', ascending: true);
        var list = (rows as List)
            .map((row) => SupplierModel.fromJson(row as Map<String, dynamic>))
            .toList();

        // Branch scoping is enforced by RLS: the select policy admits shared
        // rows (showroom_id IS NULL) plus the caller's own branches.
        if (search != null && search.trim().isNotEmpty) {
          list = _applySearch(list, search);
        }
        return list;
      } catch (e) {
        debugPrint('Supabase fetchSuppliers error: $e, falling back to dev mode');
      }
    }

    // ─── Dev Mode Fallback ───
    await SupabaseService.devLatency();
    _initDevData();
    var list = List<SupplierModel>.from(_devSuppliers!);

    if (supplierType != null && supplierType.isNotEmpty) {
      list = list.where((s) => s.supplierType == supplierType).toList();
    }
    if (isActive != null) {
      list = list.where((s) => s.isActive == isActive).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      list = _applySearch(list, search);
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<SupplierEntity?> fetchSupplierById(String id) async {
    if (_isSupabaseLive) {
      try {
        final row = await SupabaseService.client!
            .from('suppliers')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (row != null) return SupplierModel.fromJson(row);
      } catch (e) {
        debugPrint('Supabase fetchSupplierById error: $e, falling back to dev mode');
      }
    }

    await SupabaseService.devLatency();
    _initDevData();
    final matches = _devSuppliers!.where((s) => s.id == id);
    return matches.isNotEmpty ? matches.first : null;
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
  // Create / Update
  // ─────────────────────────────────────────────

  Future<SupplierEntity> createSupplier(SupplierEntity entity) async {
    final model = SupplierModel.fromEntity(entity);

    if (_isSupabaseLive) {
      try {
        final row = await SupabaseService.client!
            .from('suppliers')
            .insert(model.toInsertJson())
            .select()
            .single();
        return SupplierModel.fromJson(row);
      } catch (e) {
        debugPrint('Supabase createSupplier error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    _devSuppliers!.insert(0, model);
    return model;
  }

  Future<SupplierEntity> updateSupplier(SupplierEntity entity) async {
    final now = DateTime.now();
    final model = SupplierModel.fromEntity(entity).copyWith(updatedAt: now);

    if (_isSupabaseLive) {
      try {
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
      } catch (e) {
        debugPrint('Supabase updateSupplier error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final index = _devSuppliers!.indexWhere((s) => s.id == model.id);
    if (index != -1) {
      _devSuppliers![index] = model;
    }
    return model;
  }

  Future<void> toggleSupplierStatus(String id, bool isActive) async {
    if (_isSupabaseLive) {
      try {
        await SupabaseService.client!
            .from('suppliers')
            .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return;
      } catch (e) {
        debugPrint('Supabase toggleSupplierStatus error: $e, falling back to dev mode');
      }
    }

    _initDevData();
    final index = _devSuppliers!.indexWhere((s) => s.id == id);
    if (index != -1) {
      _devSuppliers![index] =
          _devSuppliers![index].copyWith(isActive: isActive, updatedAt: DateTime.now());
    }
  }

  // ─────────────────────────────────────────────
  // Seeded Demo Vendors
  // ─────────────────────────────────────────────

  void _initDevData() {
    if (_devSuppliers != null) return;

    final now = DateTime.now();

    _devSuppliers = [
      SupplierModel(
        id: 'sup-001',
        showroomId: null,
        code: 'SUP-HONDA',
        name: 'Honda Motorcycle & Scooter India',
        supplierType: 'oem',
        contactPerson: 'Rajesh Kulkarni',
        phone: '+91 22 2650 1100',
        email: 'oem.sales@honda.example',
        address: 'Plot 12, MIDC Industrial Area',
        city: 'Gurugram',
        state: 'Haryana',
        pincode: '122001',
        gstin: '06AABCH1234M1Z5',
        pan: 'AABCH1234M',
        bankName: 'HDFC Bank',
        bankAccountNumber: '50200011223344',
        bankIfsc: 'HDFC0000042',
        paymentTermsDays: 45,
        creditLimit: 5000000,
        openingBalance: 0,
        isActive: true,
        notes: 'Primary two-wheeler OEM. Dispatch in 7-10 working days against PO.',
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        id: 'sup-002',
        showroomId: null,
        code: 'SUP-ATHER',
        name: 'Ather Energy Ltd',
        supplierType: 'oem',
        contactPerson: 'Sneha Iyer',
        phone: '+91 80 4712 9000',
        email: 'dealers@atherenergy.example',
        address: 'IBC Knowledge Park, Bannerghatta Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560029',
        gstin: '29AABCA5678L1Z2',
        pan: 'AABCA5678L',
        bankName: 'ICICI Bank',
        bankAccountNumber: '00400122334455',
        bankIfsc: 'ICIC0000044',
        paymentTermsDays: 30,
        creditLimit: 2500000,
        openingBalance: 125000,
        isActive: true,
        notes: 'EV OEM. Battery warranty claims settled quarterly.',
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        id: 'sup-003',
        showroomId: null,
        code: 'SUP-TVS',
        name: 'TVS Motor Company Ltd',
        supplierType: 'oem',
        contactPerson: 'Mohan Deshpande',
        phone: '+91 44 2827 2233',
        email: 'channel.sales@tvs.example',
        address: 'Jayalakshmi Estates, 29 Haddows Road',
        city: 'Chennai',
        state: 'Tamil Nadu',
        pincode: '600006',
        gstin: '33AABCT9012P1Z8',
        pan: 'AABCT9012P',
        bankName: 'State Bank of India',
        bankAccountNumber: '30045678901',
        bankIfsc: 'SBIN0001234',
        paymentTermsDays: 45,
        creditLimit: 4000000,
        openingBalance: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        id: 'sup-004',
        showroomId: 'sh-001',
        code: 'SUP-AUTOPARTS',
        name: 'Bharat Auto Parts & Accessories',
        supplierType: 'spare_parts',
        contactPerson: 'Imran Shaikh',
        phone: '+91 98200 44556',
        email: 'orders@bharatautoparts.example',
        address: '14 Opera House, Charni Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400004',
        gstin: '27AABCB3456N1Z4',
        pan: 'AABCB3456N',
        bankName: 'Axis Bank',
        bankAccountNumber: '918020098765',
        bankIfsc: 'UTIB0000123',
        paymentTermsDays: 15,
        creditLimit: 500000,
        openingBalance: 48750,
        isActive: true,
        notes: 'Fast-moving filters, chain kits, brake pads. Same-day delivery in Mumbai.',
        createdAt: now,
        updatedAt: now,
      ),
      SupplierModel(
        id: 'sup-005',
        showroomId: 'sh-001',
        code: 'SUP-RIDEGEAR',
        name: 'TrailBlazer Riding Gear',
        supplierType: 'accessories',
        contactPerson: 'Priya Nair',
        phone: '+91 98111 77889',
        email: 'sales@trailblazer.example',
        address: 'Unit 7, Lamington Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400007',
        gstin: '27AABCT7788Q1Z9',
        pan: 'AABCT7788Q',
        paymentTermsDays: 21,
        creditLimit: 250000,
        openingBalance: 0,
        isActive: true,
        notes: 'Helmets, riding jackets and gloves. Margin 28-32%.',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
