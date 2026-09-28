import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/vehicles/domain/entities/vehicle_photo_entity.dart';

/// Manages vehicle photo uploads, fetching, and deletion via Supabase Storage + DB.
///
/// Supports both:
/// - **Inventory (VIN-level)** photos: PDI, damage, delivery, general physical unit photos
/// - **Model (catalog-level)** photos: marketing, brochure, display images
class VehiclePhotoService {
  VehiclePhotoService._();
  static final VehiclePhotoService instance = VehiclePhotoService._();

  static const String _bucketName = 'vehicle-photos';
  static const String _tableName = 'vehicle_photos';

  bool get _isLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  final ImagePicker _picker = ImagePicker();

  // ═══════════════════════════════════════════════════════════
  // FETCH PHOTOS
  // ═══════════════════════════════════════════════════════════

  /// Fetch photos for a specific inventory vehicle (by VIN id).
  Future<List<VehiclePhotoEntity>> fetchVehiclePhotos(String vehicleId) async {
    return _fetchPhotos(column: 'vehicle_id', id: vehicleId);
  }

  /// Fetch photos for a vehicle model (catalog).
  Future<List<VehiclePhotoEntity>> fetchModelPhotos(String modelId) async {
    return _fetchPhotos(column: 'model_id', id: modelId);
  }

  Future<List<VehiclePhotoEntity>> _fetchPhotos({
    required String column,
    required String id,
  }) async {
    if (!_isLive) return [];

    try {
      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq(column, id)
          .order('sort_order')
          .order('created_at', ascending: false);

      return (response as List).map((e) => _parsePhoto(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('VehiclePhotoService.fetchPhotos error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PICK & UPLOAD
  // ═══════════════════════════════════════════════════════════

  /// Pick a photo from gallery or camera, upload it, and store metadata.
  ///
  /// Returns the created [VehiclePhotoEntity], or null if cancelled/failed.
  Future<VehiclePhotoEntity?> pickAndUploadPhoto({
    String? vehicleId,
    String? modelId,
    String photoType = 'general',
    String? caption,
    ImageSource source = ImageSource.gallery,
  }) async {
    assert(
      (vehicleId != null) != (modelId != null),
      'Exactly one of vehicleId or modelId must be set',
    );

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final fileName = picked.name;
      final mimeType = _getMimeType(fileName);

      return await uploadPhoto(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        vehicleId: vehicleId,
        modelId: modelId,
        photoType: photoType,
        caption: caption,
      );
    } catch (e) {
      debugPrint('VehiclePhotoService.pickAndUploadPhoto error: $e');
      return null;
    }
  }

  /// Upload raw bytes to storage and store metadata in DB.
  Future<VehiclePhotoEntity?> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
    String? vehicleId,
    String? modelId,
    String photoType = 'general',
    String? caption,
  }) async {
    if (!_isLive) return null;

    try {
      // Build storage path: vehicle-photos/vehicles/{id}/{timestamp}_{filename}
      // or vehicle-photos/models/{id}/{timestamp}_{filename}
      final folder = vehicleId != null
          ? 'vehicles/$vehicleId'
          : 'models/$modelId';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.]'), '_');
      final storagePath = '$folder/${timestamp}_$safeName';

      // Upload to Supabase Storage
      await SupabaseService.client!.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      // Get public URL
      final publicUrl = SupabaseService.client!.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      // Get existing count for sort_order
      final column = vehicleId != null ? 'vehicle_id' : 'model_id';
      final ownerId = vehicleId ?? modelId!;
      final existingCount = await SupabaseService.client!
          .from(_tableName)
          .select('id')
          .eq(column, ownerId);
      final sortOrder = (existingCount as List).length;

      // Insert metadata row
      final payload = {
        'vehicle_id': vehicleId,
        'model_id': modelId,
        'file_name': fileName,
        'storage_path': storagePath,
        'public_url': publicUrl,
        'file_size_bytes': bytes.length,
        'mime_type': mimeType,
        'photo_type': photoType,
        'caption': caption,
        'sort_order': sortOrder,
        'is_primary': sortOrder == 0,
        'uploaded_by': SupabaseService.currentUserId,
      };

      final res = await SupabaseService.client!
          .from(_tableName)
          .insert(payload)
          .select()
          .single();

      return _parsePhoto(res);
    } catch (e) {
      debugPrint('VehiclePhotoService.uploadPhoto error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════

  /// Delete a photo from storage and remove its DB metadata.
  Future<bool> deletePhoto(VehiclePhotoEntity photo) async {
    if (!_isLive) return false;

    try {
      // Delete from storage
      await SupabaseService.client!.storage
          .from(_bucketName)
          .remove([photo.storagePath]);

      // Delete metadata row
      await SupabaseService.client!
          .from(_tableName)
          .delete()
          .eq('id', photo.id);

      return true;
    } catch (e) {
      debugPrint('VehiclePhotoService.deletePhoto error: $e');
      return false;
    }
  }

  /// Set a photo as the primary photo for its vehicle/model.
  Future<bool> setPrimaryPhoto(VehiclePhotoEntity photo) async {
    if (!_isLive) return false;

    try {
      final column = photo.vehicleId != null ? 'vehicle_id' : 'model_id';
      final ownerId = photo.vehicleId ?? photo.modelId!;

      // Reset all is_primary for this owner
      await SupabaseService.client!
          .from(_tableName)
          .update({'is_primary': false})
          .eq(column, ownerId);

      // Set this one as primary
      await SupabaseService.client!
          .from(_tableName)
          .update({'is_primary': true})
          .eq('id', photo.id);

      return true;
    } catch (e) {
      debugPrint('VehiclePhotoService.setPrimaryPhoto error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  VehiclePhotoEntity _parsePhoto(Map<String, dynamic> row) {
    return VehiclePhotoEntity(
      id: row['id'] as String,
      vehicleId: row['vehicle_id'] as String?,
      modelId: row['model_id'] as String?,
      fileName: row['file_name'] as String? ?? '',
      storagePath: row['storage_path'] as String? ?? '',
      publicUrl: row['public_url'] as String?,
      fileSizeBytes: (row['file_size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: row['mime_type'] as String? ?? 'image/jpeg',
      photoType: row['photo_type'] as String? ?? 'general',
      caption: row['caption'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isPrimary: row['is_primary'] as bool? ?? false,
      uploadedBy: row['uploaded_by'] as String?,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
