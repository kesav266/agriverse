import 'package:flutter/material.dart';

/// AgriVerse AI Master Design System Color Tokens.
/// Follows the "Agronomic Editorial & Ambient Precision" design direction:
/// Deep Forest Pine, Warm Alabaster canvas, Earthy Clay neutrals, Harvest Gold AI accents.
class AppColors {
  // Brand Core Colors
  static const Color forestPine = Color(0xFF0F3826);
  static const Color forestDeep = Color(0xFF0D3D22);
  static const Color forestPrimary = Color(0xFF114B2D);
  static const Color mistMint = Color(0xFFE8F2EC);
  static const Color softSage = Color(0xFFE2F0E7);
  static const Color deepWoodland = Color(0xFF143828);
  static const Color luminousSage = Color(0xFF2EA06F);
  static const Color vibrantEmerald = Color(0xFF16A34A);

  // High-Impact Accents (60-30-10 distribution)
  static const Color harvestGold = Color(0xFFE09F3E);
  static const Color warmHoney = Color(0xFFF4B961);
  static const Color amberSun = Color(0xFFF59E0B);
  static const Color terracotta = Color(0xFFC85A32);
  static const Color sunlitClay = Color(0xFFE87D56);
  static const Color monsoonAzure = Color(0xFF1E6B8A);
  static const Color clearStream = Color(0xFF4FA3C7);
  static const Color skyBlue = Color(0xFF0284C7);

  // Backgrounds & Surfaces (Light Theme)
  static const Color warmAlabaster = Color(0xFFF9F8F3);
  static const Color canvasBg = Color(0xFFF6F8F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color warmOat = Color(0xFFF3EFE6);
  static const Color pillInactive = Color(0xFFEDF2EE);

  // Backgrounds & Surfaces (Dark Theme)
  static const Color nightCanopy = Color(0xFF111613);
  static const Color charcoalSurface = Color(0xFF19201C);
  static const Color cardElevatedDark = Color(0xFF232C27);

  // Neutral & Typography Colors (Light Theme)
  static const Color textPrimary = Color(0xFF1A241E);
  static const Color textHeadline = Color(0xFF111C15);
  static const Color textSecondary = Color(0xFF5A6B61);
  static const Color textMuted = Color(0xFF8C9B92);
  static const Color textOnDark = Color(0xFFF3F7F4);
  static const Color textOnDarkSecondary = Color(0xFFA2B5AA);

  // Neutral & Typography Colors (Dark Theme)
  static const Color textDarkPrimary = Color(0xFFF3F7F4);
  static const Color textDarkSecondary = Color(0xFFA2B5AA);
  static const Color textDarkMuted = Color(0xFF6F8277);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE6E2D8);
  static const Color borderSubtle = Color(0xFFE5ECE7);
  static const Color borderMedium = Color(0xFFCED6CF);
  static const Color borderFocused = Color(0xFF0F3826);
  static const Color borderDark = Color(0xFF2A352F);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF2D6A4F);
  static const Color successLight = Color(0xFFE8F5EE);
  static const Color successBorder = Color(0xFFA3D9BC);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFEDEA);
  static const Color errorBorder = Color(0xFFFFB4AB);

  static const Color info = Color(0xFF1E6B8A);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Curated Editorial Gradients
  static const LinearGradient heroEditorialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2E20), Color(0xFF185338)],
  );

  static const LinearGradient subtleCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF9F5)],
  );

  static const LinearGradient weatherSkyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E3854), Color(0xFF1E6B8A), Color(0xFF3B8EA5)],
  );

  static const LinearGradient diagnosticHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2822), Color(0xFF2D6A4F)],
  );

  // ---------------------------------------------------------------------------
  // Backward-compatibility Aliases for Existing Screen Code
  // ---------------------------------------------------------------------------
  static const Color forestGreen = forestPine;
  static const Color emerald = forestPine;
  static const Color limeAccent = harvestGold;
  static const Color darkLime = Color(0xFFC78328);
  static const Color warmIvory = warmAlabaster;
  static const Color surfaceCard = surfaceWhite;
  static const Color surfaceElevated = warmOat;
  static const Color surfaceDark = deepWoodland;
  static const LinearGradient forestHeroGradient = heroEditorialGradient;
}
