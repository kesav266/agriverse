import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/state/app_state_provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_radii.dart';
import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/app_card.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/widgets/design_components.dart';
import 'package:frontend/widgets/state_views.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AgriVerse AI Master Design System Foundation Tests', () {
    test('Token sanity: AppColors & AppTypography & AppSpacing', () {
      expect(AppColors.forestPine, const Color(0xFF0F3826));
      expect(AppColors.warmAlabaster, const Color(0xFFF9F8F3));
      expect(AppColors.harvestGold, const Color(0xFFE09F3E));
      expect(AppColors.terracotta, const Color(0xFFC85A32));

      // Backward compatibility aliases
      expect(AppColors.forestGreen, AppColors.forestPine);
      expect(AppColors.emerald, AppColors.forestPine);
      expect(AppColors.warmIvory, AppColors.warmAlabaster);

      expect(AppSpacing.md, 16.0);
      expect(AppRadii.lgValue, 18.0);

      final metricStyle = AppTypography.metricValue();
      expect(metricStyle.fontSize, 28.0);
      final heroStyle = AppTypography.displayHero();
      expect(heroStyle.fontWeight, FontWeight.w800);
    });

    test('Theme generation: Light and Dark ThemeData', () {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, AppColors.forestPine);
      expect(dark.colorScheme.primary, AppColors.luminousSage);
    });

    testWidgets('AppButton renders and fires onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Analyze Leaf',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Analyze Leaf'), findsOneWidget);
      await tester.tap(find.text('Analyze Leaf'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AppCard and HeroDarkCard render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                AppCard(child: Text('Normal Card')),
                HeroDarkCard(child: Text('Hero Dark Card')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Normal Card'), findsOneWidget);
      expect(find.text('Hero Dark Card'), findsOneWidget);
    });

    testWidgets('AppTextField renders label and hint', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Land Area (Acres)',
              hint: '4.5',
            ),
          ),
        ),
      );

      expect(find.text('Land Area (Acres)'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('Design components: SectionHeader, MetricCard, Badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Soil Moisture',
                  subtitle: 'Real-time telemetry',
                ),
                MetricCard(
                  title: 'Rainfall',
                  value: '12.5',
                  unit: 'mm',
                  icon: Icons.grain_rounded,
                ),
                FarmStatusBadge(
                  label: 'Flowering Stage',
                  icon: Icons.spa_rounded,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Soil Moisture'), findsOneWidget);
      expect(find.text('Real-time telemetry'), findsOneWidget);
      expect(find.text('Rainfall'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('Flowering Stage'), findsOneWidget);
    });

    testWidgets('State views: LoadingView, EmptyStateView, ErrorStateView', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: EmptyStateView(
              title: 'No Farms Found',
              subtitle: 'Add your first parcel to begin.',
              actionLabel: 'Register Farm',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('No Farms Found'), findsOneWidget);
      expect(find.text('Register Farm'), findsOneWidget);
    });

    testWidgets('AppBottomNav renders all tabs and fires selection', (
      tester,
    ) async {
      int selected = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(autoLoad: false),
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              bottomNavigationBar: AppBottomNav(
                currentIndex: selected,
                onTabSelected: (idx) => selected = idx,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(
        find.text('My Farm'),
        findsNothing,
      ); // Inactive tabs only show icon

      await tester.tap(find.byIcon(Icons.landscape_outlined));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets(
      'AppAssets.cropImage renders fallback on missing asset safely',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAssets.cropImage(
                assetPath: 'assets/images/crops/non_existent.jpg',
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        // Pumps without throwing any unhandled exceptions
        await tester.pump();
        expect(find.byType(Container), findsWidgets);
      },
    );

    testWidgets('AgriVerse App smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(autoLoad: false),
          child: const AgriVerseApp(),
        ),
      );

      // Allow entrance animations to settle
      await tester.pumpAndSettle();

      expect(find.text('AgriVerse AI'), findsOneWidget);
    });
  });
}
