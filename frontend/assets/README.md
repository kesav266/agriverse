# AgriVerse AI Asset Repository & Image Strategy

This directory contains curated static assets for the AgriVerse AI application, ensuring 100% offline functionality and realistic agronomic presentation.

## Directory Structure
```
assets/
├── images/
│   ├── crops/
│   │   ├── paddy_rice.jpg         # Macro photography of paddy crop in flowering/grain stage
│   │   ├── red_chilli.jpg         # High-resolution Andhra Guntur red chilli plants
│   │   ├── cotton_field.jpg       # Cotton bolls in vegetative/boll formation stage
│   │   └── maize_corn.jpg         # Vibrant maize crop canopy
│   ├── diseases/
│   │   ├── leaf_blast_paddy.jpg   # Magnaporthe oryzae spindle-shaped lesions
│   │   └── bacterial_blight.jpg   # Xanthomonas oryzae water-soaked leaf streaks
│   └── branding/
│       ├── agriverse_logo.png     # High-contrast botanical emblem
│       └── farmer_avatar.png      # Regional Indian farmer portrait
└── icons/
    └── README.md                  # Vector icon definitions
```

## Fallback & Offline Conventions
1. All crop and disease images must be accessed via `AppAssets.cropImage(assetPath: ...)` defined in `lib/core/assets/app_assets.dart`.
2. If an image asset is unavailable or fails to load, `AppAssets.cropImage` automatically renders an accessible botanical container with `AppColors.mistMint` background and `AppColors.forestPine` icon, preventing render exceptions or broken image placeholders.
3. No remote image URLs (Unsplash, external CDNs) are required for core operations.
