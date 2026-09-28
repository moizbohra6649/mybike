import 'package:equatable/equatable.dart';

/// Domain entity representing a vehicle photo (either VIN-level or model-level).
class VehiclePhotoEntity extends Equatable {
  final String id;

  /// Set for inventory (physical unit) photos, null for model-level photos.
  final String? vehicleId;

  /// Set for catalog model-level photos, null for VIN-level photos.
  final String? modelId;

  final String fileName;
  final String storagePath;
  final String? publicUrl;
  final int fileSizeBytes;
  final String mimeType;

  /// Type / angle of the photo.
  final String photoType; // 'general', 'front', 'rear', 'left', 'right',
                           // 'dashboard', 'engine', 'chassis', 'pdi',
                           // 'damage', 'delivery', 'marketing', 'brochure'
  final String? caption;
  final int sortOrder;
  final bool isPrimary;
  final String? uploadedBy;
  final DateTime createdAt;

  const VehiclePhotoEntity({
    required this.id,
    this.vehicleId,
    this.modelId,
    required this.fileName,
    required this.storagePath,
    this.publicUrl,
    this.fileSizeBytes = 0,
    this.mimeType = 'image/jpeg',
    this.photoType = 'general',
    this.caption,
    this.sortOrder = 0,
    this.isPrimary = false,
    this.uploadedBy,
    required this.createdAt,
  });

  bool get isInventoryPhoto => vehicleId != null;
  bool get isModelPhoto => modelId != null;

  String get photoTypeLabel {
    switch (photoType) {
      case 'front':       return 'Front View';
      case 'rear':        return 'Rear View';
      case 'left':        return 'Left Side';
      case 'right':       return 'Right Side';
      case 'dashboard':   return 'Dashboard / Cluster';
      case 'engine':      return 'Engine Bay';
      case 'chassis':     return 'Chassis / Frame';
      case 'pdi':         return 'PDI Inspection';
      case 'damage':      return 'Damage Report';
      case 'delivery':    return 'Delivery Handover';
      case 'marketing':   return 'Marketing / Promo';
      case 'brochure':    return 'Brochure / Catalog';
      case 'general':
      default:            return 'General';
    }
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  VehiclePhotoEntity copyWith({
    String? id,
    String? vehicleId,
    String? modelId,
    String? fileName,
    String? storagePath,
    String? publicUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? photoType,
    String? caption,
    int? sortOrder,
    bool? isPrimary,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return VehiclePhotoEntity(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      modelId: modelId ?? this.modelId,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      photoType: photoType ?? this.photoType,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      isPrimary: isPrimary ?? this.isPrimary,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, vehicleId, modelId, fileName, storagePath, publicUrl,
        fileSizeBytes, mimeType, photoType, caption, sortOrder,
        isPrimary, uploadedBy, createdAt,
      ];
}
