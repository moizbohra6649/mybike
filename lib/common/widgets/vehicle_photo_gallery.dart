import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/vehicle_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/vehicles/domain/entities/vehicle_photo_entity.dart';

/// Reusable Vehicle Photo Gallery Widget
///
/// Displays a grid of vehicle photos with upload, view full-screen, set-primary,
/// and delete capabilities. Works for both VIN-level and model-level photos.
class VehiclePhotoGallery extends StatefulWidget {
  /// For inventory (VIN-level) photos.
  final String? vehicleId;

  /// For model (catalog-level) photos.
  final String? modelId;

  /// Section title shown above the gallery.
  final String title;

  /// Allow the user to add/delete photos.
  final bool editable;

  const VehiclePhotoGallery({
    super.key,
    this.vehicleId,
    this.modelId,
    this.title = 'Photo Gallery',
    this.editable = true,
  }) : assert(
         (vehicleId != null) != (modelId != null),
         'Exactly one of vehicleId or modelId must be set',
       );

  @override
  State<VehiclePhotoGallery> createState() => _VehiclePhotoGalleryState();
}

class _VehiclePhotoGalleryState extends State<VehiclePhotoGallery> {
  final VehiclePhotoService _service = VehiclePhotoService.instance;
  List<VehiclePhotoEntity> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = widget.vehicleId != null
        ? await _service.fetchVehiclePhotos(widget.vehicleId!)
        : await _service.fetchModelPhotos(widget.modelId!);
    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    // Pick photo type
    final photoType = await _showPhotoTypePicker();
    if (photoType == null) return;

    setState(() => _isUploading = true);

    final result = await _service.pickAndUploadPhoto(
      vehicleId: widget.vehicleId,
      modelId: widget.modelId,
      photoType: photoType,
      source: source,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (result != null) {
        await _loadPhotos();
        if (mounted) context.showSuccessSnackBar('Photo uploaded successfully');
      }
    }
  }

  Future<String?> _showPhotoTypePicker() async {
    final types = widget.vehicleId != null
        ? [
            ('general', 'General', Icons.photo_camera_outlined),
            ('front', 'Front View', Icons.arrow_upward_rounded),
            ('rear', 'Rear View', Icons.arrow_downward_rounded),
            ('left', 'Left Side', Icons.arrow_back_rounded),
            ('right', 'Right Side', Icons.arrow_forward_rounded),
            ('dashboard', 'Dashboard', Icons.speed_outlined),
            ('engine', 'Engine Bay', Icons.settings_outlined),
            ('chassis', 'Chassis / Frame', Icons.build_outlined),
            ('pdi', 'PDI Inspection', Icons.fact_check_outlined),
            ('damage', 'Damage Report', Icons.warning_amber_rounded),
            ('delivery', 'Delivery Handover', Icons.handshake_outlined),
          ]
        : [
            ('general', 'General', Icons.photo_camera_outlined),
            ('front', 'Front View', Icons.arrow_upward_rounded),
            ('rear', 'Rear View', Icons.arrow_downward_rounded),
            ('left', 'Left Side', Icons.arrow_back_rounded),
            ('right', 'Right Side', Icons.arrow_forward_rounded),
            ('marketing', 'Marketing / Promo', Icons.campaign_outlined),
            ('brochure', 'Brochure Image', Icons.menu_book_outlined),
          ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.isDarkMode ? const Color(0xFF1A1D24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20),
              child: Row(
                children: [
                  const Icon(Icons.label_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('Select Photo Type', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            ...types.map((t) => ListTile(
              leading: Icon(t.$3, color: AppColors.primaryYellow),
              title: Text(t.$2, style: AppTypography.bodyMedium),
              dense: true,
              onTap: () => Navigator.pop(ctx, t.$1),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(VehiclePhotoEntity photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Text('Are you sure you want to delete "${photo.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _service.deletePhoto(photo);
      if (mounted) {
        if (success) {
          await _loadPhotos();
          if (mounted) context.showSuccessSnackBar('Photo deleted');
        } else {
          context.showErrorSnackBar('Failed to delete photo');
        }
      }
    }
  }

  Future<void> _setPrimary(VehiclePhotoEntity photo) async {
    final success = await _service.setPrimaryPhoto(photo);
    if (mounted && success) {
      await _loadPhotos();
      if (mounted) context.showSuccessSnackBar('Primary photo updated');
    }
  }

  void _showFullScreen(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenGallery(
              photos: _photos,
              initialIndex: index,
              onDelete: widget.editable ? _deletePhoto : null,
              onSetPrimary: widget.editable ? _setPrimary : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.photo_library_outlined, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '${_photos.length}',
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.primaryYellowDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.editable && !_isLoading)
                PopupMenuButton<ImageSource>(
                  tooltip: 'Add Photo',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
                  ),
                  onSelected: _isUploading ? null : _pickAndUpload,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: ImageSource.gallery,
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Choose from Gallery'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: ImageSource.camera,
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Take Photo'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_photos.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildPhotoGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Photos Yet',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.editable
                ? 'Tap the + button above to add photos'
                : 'No photos have been uploaded for this vehicle',
            style: AppTypography.captionMedium.copyWith(
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 5
            : constraints.maxWidth > 500 ? 4
            : constraints.maxWidth > 350 ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimensions.spacing10,
            mainAxisSpacing: AppDimensions.spacing10,
            childAspectRatio: 1.0,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, index) => _buildPhotoTile(index, isDark),
        );
      },
    );
  }

  Widget _buildPhotoTile(int index, bool isDark) {
    final photo = _photos[index];

    return GestureDetector(
      onTap: () => _showFullScreen(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: photo.isPrimary
                ? AppColors.primaryYellow
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
            width: photo.isPrimary ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              photo.publicUrl != null && photo.publicUrl!.isNotEmpty
                  ? Image.network(
                      photo.publicUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _photoPlaceholder(isDark),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : _photoPlaceholder(isDark),

              // Primary badge
              if (photo.isPrimary)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                    ),
                    child: Text(
                      'PRIMARY',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),

              // Photo type badge
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    photo.photoTypeLabel,
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Hover / long-press overlay for actions
              if (widget.editable)
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 14),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case 'primary':
                          _setPrimary(photo);
                          break;
                        case 'delete':
                          _deletePhoto(photo);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (!photo.isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Row(
                            children: [
                              Icon(Icons.star_outline, size: 16),
                              SizedBox(width: 8),
                              Text('Set as Primary'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: isDark ? Colors.white24 : Colors.grey.shade300,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// FULL-SCREEN GALLERY VIEWER
// ═════════════════════════════════════════════════════════════════════════

class _FullScreenGallery extends StatefulWidget {
  final List<VehiclePhotoEntity> photos;
  final int initialIndex;
  final Future<void> Function(VehiclePhotoEntity)? onDelete;
  final Future<void> Function(VehiclePhotoEntity)? onSetPrimary;

  const _FullScreenGallery({
    required this.photos,
    required this.initialIndex,
    this.onDelete,
    this.onSetPrimary,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photo.photoTypeLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_currentIndex + 1} of ${widget.photos.length} · ${photo.fileSizeFormatted}',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          if (widget.onSetPrimary != null && !photo.isPrimary)
            IconButton(
              icon: const Icon(Icons.star_outline),
              tooltip: 'Set as Primary',
              onPressed: () {
                widget.onSetPrimary!(photo);
                Navigator.pop(context);
              },
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete',
              onPressed: () {
                widget.onDelete!(photo);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final p = widget.photos[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: p.publicUrl != null && p.publicUrl!.isNotEmpty
                      ? Image.network(
                          p.publicUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: Colors.white38,
                        ),
                ),
              );
            },
          ),

          // Page indicator dots
          if (widget.photos.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (i) => Container(
                    width: i == _currentIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? AppColors.primaryYellow : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
