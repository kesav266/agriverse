import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Central Asset Registry & Fallback Provider for AgriVerse AI.
/// Provides documented conventions for realistic farm imagery, crop photography,
/// disease samples, and graceful offline fallback widgets.
class AppAssets {
  static const String basePath = 'assets/images';

  // Crop Canopies
  static const String paddyField = '$basePath/crops/paddy_rice.jpg';
  static const String chilliField = '$basePath/crops/red_chilli.jpg';
  static const String cottonField = '$basePath/crops/cotton_field.jpg';
  static const String maizeField = '$basePath/crops/maize_corn.jpg';

  // Foliage Pathology
  static const String leafBlast = '$basePath/diseases/leaf_blast_paddy.jpg';
  static const String bacterialBlight =
      '$basePath/diseases/bacterial_blight.jpg';

  // Branding
  static const String appEmblem = '$basePath/branding/agriverse_logo.png';
  static const String farmerAvatar = '$basePath/branding/farmer_avatar.png';

  /// Graceful Photographic Image Loader with offline fallback
  static Widget cropImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    IconData fallbackIcon = Icons.spa_rounded,
  }) {
    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.mistMint,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Icon(
              fallbackIcon,
              size: (height != null && height < 50) ? 20 : 36,
              color: AppColors.forestPine,
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }
    return imageWidget;
  }
}
