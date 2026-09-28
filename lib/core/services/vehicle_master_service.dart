import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/vehicles/domain/entities/brand_entity.dart';
import '../../features/vehicles/domain/entities/vehicle_model_entity.dart';
import '../../features/vehicles/domain/entities/vehicle_variant_entity.dart';
import '../../features/vehicles/domain/entities/vehicle_color_entity.dart';
import '../../features/vehicles/domain/entities/vehicle_catalog_item.dart';
import '../../features/vehicles/data/models/brand_model.dart';
import '../../features/vehicles/data/models/vehicle_model_model.dart';
import '../../features/vehicles/data/models/vehicle_variant_model.dart';
import '../../features/vehicles/data/models/vehicle_color_model.dart';

/// Vehicle Master Service
///
/// Central authority for OEM Brands, Vehicle Models, Specifications,
/// Variants, and Color Options directly from Supabase.
class VehicleMasterService {
  VehicleMasterService._();
  static final VehicleMasterService instance = VehicleMasterService._();

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ─────────────────────────────────────────────
  // 1. BRANDS
  // ─────────────────────────────────────────────

  Future<List<BrandEntity>> fetchBrands({bool? isActive}) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('brands').select();
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      final data = await query.order('name', ascending: true);
      return (data as List).map((row) => BrandModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchBrands error: $e');
      return [];
    }
  }

  Future<BrandEntity> createBrand(BrandEntity brand) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final model = BrandModel.fromEntity(brand);
    final payload = model.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await SupabaseService.client!
        .from('brands')
        .insert(payload)
        .select()
        .single();
    return BrandModel.fromJson(response);
  }

  Future<BrandEntity> updateBrand(BrandEntity brand) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final model = BrandModel.fromEntity(brand);
    final payload = model.toJson();
    payload.remove('created_at');
    payload['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client!
        .from('brands')
        .update(payload)
        .eq('id', brand.id)
        .select()
        .single();
    return BrandModel.fromJson(response);
  }

  Future<void> deleteBrand(String brandId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('brands').delete().eq('id', brandId);
    } catch (e) {
      debugPrint('Supabase deleteBrand error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 2. VEHICLE MODELS
  // ─────────────────────────────────────────────

  Future<List<VehicleModelEntity>> fetchModels({
    String? brandId,
    String? type,
    String? bodyType,
    bool? isActive,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('vehicle_models').select();
      if (brandId != null && brandId.isNotEmpty) query = query.eq('brand_id', brandId);
      if (type != null && type.isNotEmpty) query = query.eq('type', type);
      if (bodyType != null && bodyType.isNotEmpty) query = query.eq('body_type', bodyType);
      if (isActive != null) query = query.eq('is_active', isActive);
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim()}%');
      }

      final data = await query.order('name', ascending: true);
      return (data as List).map((row) => VehicleModelModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchModels error: $e');
      return [];
    }
  }

  Future<VehicleModelEntity?> fetchModelById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final data = await SupabaseService.client!
          .from('vehicle_models')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data != null) return VehicleModelModel.fromJson(data);
      return null;
    } catch (e) {
      debugPrint('Supabase fetchModelById error: $e');
      return null;
    }
  }

  Future<VehicleModelEntity> createModel(VehicleModelEntity model) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final m = VehicleModelModel.fromEntity(model);
    final payload = m.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await SupabaseService.client!
        .from('vehicle_models')
        .insert(payload)
        .select()
        .single();
    return VehicleModelModel.fromJson(response);
  }

  Future<VehicleModelEntity> updateModel(VehicleModelEntity model) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final m = VehicleModelModel.fromEntity(model);
    final payload = m.toJson();
    payload.remove('created_at');
    payload['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client!
        .from('vehicle_models')
        .update(payload)
        .eq('id', model.id)
        .select()
        .single();
    return VehicleModelModel.fromJson(response);
  }

  Future<void> deleteModel(String modelId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('vehicle_models').delete().eq('id', modelId);
    } catch (e) {
      debugPrint('Supabase deleteModel error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 3. VEHICLE VARIANTS
  // ─────────────────────────────────────────────

  Future<List<VehicleVariantEntity>> fetchVariants({
    String? modelId,
    bool? isActive,
    String? fuelType,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('vehicle_variants').select();
      if (modelId != null && modelId.isNotEmpty) query = query.eq('model_id', modelId);
      if (isActive != null) query = query.eq('is_active', isActive);
      if (fuelType != null && fuelType.isNotEmpty) query = query.eq('fuel_type', fuelType);

      final data = await query.order('ex_showroom_price', ascending: true);
      return (data as List).map((row) => VehicleVariantModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchVariants error: $e');
      return [];
    }
  }

  Future<VehicleVariantEntity?> fetchVariantById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final data = await SupabaseService.client!
          .from('vehicle_variants')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data != null) return VehicleVariantModel.fromJson(data);
      return null;
    } catch (e) {
      debugPrint('Supabase fetchVariantById error: $e');
      return null;
    }
  }

  Future<VehicleVariantEntity> createVariant(VehicleVariantEntity variant) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final v = VehicleVariantModel.fromEntity(variant);
    final payload = v.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await SupabaseService.client!
        .from('vehicle_variants')
        .insert(payload)
        .select()
        .single();
    return VehicleVariantModel.fromJson(response);
  }

  Future<VehicleVariantEntity> updateVariant(VehicleVariantEntity variant) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final v = VehicleVariantModel.fromEntity(variant);
    final payload = v.toJson();
    payload.remove('created_at');
    payload['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client!
        .from('vehicle_variants')
        .update(payload)
        .eq('id', variant.id)
        .select()
        .single();
    return VehicleVariantModel.fromJson(response);
  }

  Future<void> deleteVariant(String variantId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('vehicle_variants').delete().eq('id', variantId);
    } catch (e) {
      debugPrint('Supabase deleteVariant error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 4. VEHICLE COLORS
  // ─────────────────────────────────────────────

  Future<List<VehicleColorEntity>> fetchColors({
    String? modelId,
    String? variantId,
    bool? isActive,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('vehicle_colors').select();
      if (modelId != null && modelId.isNotEmpty) {
        query = query.eq('model_id', modelId);
      }
      if (variantId != null && variantId.isNotEmpty) {
        query = query.eq('variant_id', variantId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final data = await query.order('name', ascending: true);
      return (data as List).map((row) => VehicleColorModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchColors error: $e');
      return [];
    }
  }

  Future<VehicleColorEntity?> fetchColorById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final data = await SupabaseService.client!
          .from('vehicle_colors')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data != null) return VehicleColorModel.fromJson(data);
      return null;
    } catch (e) {
      debugPrint('Supabase fetchColorById error: $e');
      return null;
    }
  }

  Future<VehicleColorEntity> createColor(VehicleColorEntity color) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final c = VehicleColorModel.fromEntity(color);
    final payload = c.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await SupabaseService.client!
        .from('vehicle_colors')
        .insert(payload)
        .select()
        .single();
    return VehicleColorModel.fromJson(response);
  }

  Future<VehicleColorEntity> updateColor(VehicleColorEntity color) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final c = VehicleColorModel.fromEntity(color);
    final payload = c.toJson();
    payload.remove('created_at');
    payload['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client!
        .from('vehicle_colors')
        .update(payload)
        .eq('id', color.id)
        .select()
        .single();
    return VehicleColorModel.fromJson(response);
  }

  Future<void> deleteColor(String colorId) async {
    if (!_isSupabaseLive) return;
    try {
      await SupabaseService.client!.from('vehicle_colors').delete().eq('id', colorId);
    } catch (e) {
      debugPrint('Supabase deleteColor error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 5. AGGREGATED CATALOG
  // ─────────────────────────────────────────────

  Future<List<VehicleCatalogItem>> fetchCatalogItems({
    String? brandId,
    String? type,
    String? bodyType,
    String? search,
    bool? isActive,
  }) async {
    final models = await fetchModels(
      brandId: brandId,
      type: type,
      bodyType: bodyType,
      search: search,
      isActive: isActive,
    );

    final brands = await fetchBrands();
    final brandsMap = {for (final b in brands) b.id: b};

    final allVariants = await fetchVariants(isActive: isActive);
    final allColors = await fetchColors(isActive: isActive);

    final items = <VehicleCatalogItem>[];
    for (final model in models) {
      final brand = brandsMap[model.brandId];
      final variants = allVariants.where((v) => v.modelId == model.id).toList();
      // Match colors by modelId or via variant associations
      final variantIds = variants.map((v) => v.id).toSet();
      final colors = allColors.where((c) => c.modelId == model.id || variantIds.contains(c.modelId)).toList();

      items.add(VehicleCatalogItem(
        model: model,
        brand: brand,
        variants: variants,
        colors: colors,
      ));
    }

    return items;
  }

  Future<VehicleCatalogItem?> fetchCatalogItemById(String modelId) async {
    final model = await fetchModelById(modelId);
    if (model == null) return null;

    final brands = await fetchBrands();
    final brand = brands.where((b) => b.id == model.brandId).firstOrNull;
    final variants = await fetchVariants(modelId: modelId);
    final colors = await fetchColors(modelId: modelId);

    return VehicleCatalogItem(
      model: model,
      brand: brand,
      variants: variants,
      colors: colors,
    );
  }
}
