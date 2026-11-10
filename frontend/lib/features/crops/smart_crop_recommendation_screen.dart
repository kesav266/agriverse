import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/recommendation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';

/// Screen 9: Premium Modern Rule-Based Crop Recommendation Screen.
class SmartCropRecommendationScreen extends StatefulWidget {
  const SmartCropRecommendationScreen({super.key});

  @override
  State<SmartCropRecommendationScreen> createState() =>
      _SmartCropRecommendationScreenState();
}

class _SmartCropRecommendationScreenState
    extends State<SmartCropRecommendationScreen> {
  String? _season;
  String? _soil;
  String? _water;
  List<Recommendation> _results = [];
  String? _error;
  bool _loading = false;

  Future<void> _evaluate() async {
    if (_loading) return;
    if (_season == null || _soil == null || _water == null) {
      setState(
        () => _error = context.read<AppStateProvider>().tr(
          'select_crop_conditions',
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    final state = context.read<AppStateProvider>();
    try {
      final results = await state.evaluateRecommendations(
        soilType: _soil!,
        season: _season!,
        availableWater: _water!,
      );
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(title: Text(state.tr('smart_recommendation'))),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter Criteria Card
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mistMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.forestPine,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.tr('rule_based_screening'),
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.tr('screening_disclaimer'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Season Selector
                DropdownButtonFormField<String>(
                  initialValue: _season,
                  decoration: InputDecoration(
                    labelText: state.tr('season'),
                    prefixIcon: const Icon(Icons.wb_sunny_rounded, color: AppColors.forestPine),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Kharif',
                      child: Text(state.tr('kharif')),
                    ),
                    DropdownMenuItem(
                      value: 'Rabi',
                      child: Text(state.tr('rabi')),
                    ),
                    DropdownMenuItem(
                      value: 'Zaid',
                      child: Text(state.tr('zaid')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _season = value),
                ),
                const SizedBox(height: 14),

                // Soil Type Selector
                DropdownButtonFormField<String>(
                  initialValue: _soil,
                  decoration: InputDecoration(
                    labelText: state.tr('soil_type'),
                    prefixIcon: const Icon(Icons.layers_rounded, color: AppColors.forestPine),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Black soil',
                      child: Text(state.tr('black_soil')),
                    ),
                    DropdownMenuItem(
                      value: 'Red sandy soil',
                      child: Text(state.tr('red_sandy_soil')),
                    ),
                    DropdownMenuItem(
                      value: 'Alluvial soil',
                      child: Text(state.tr('alluvial_soil')),
                    ),
                    DropdownMenuItem(
                      value: 'Clay soil',
                      child: Text(state.tr('clay_soil')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _soil = value),
                ),
                const SizedBox(height: 14),

                // Water Availability Selector
                DropdownButtonFormField<String>(
                  initialValue: _water,
                  decoration: InputDecoration(
                    labelText: state.tr('water_availability'),
                    prefixIcon: const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7)),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'high',
                      child: Text(state.tr('high')),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text(state.tr('medium')),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text(state.tr('low')),
                    ),
                    DropdownMenuItem(
                      value: 'rainfed',
                      child: Text(state.tr('rainfed')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _water = value),
                ),
                const SizedBox(height: 20),

                // Evaluate Action Button
                AppButton(
                  text: state.tr(_loading ? 'evaluating' : 'get_crop_screening'),
                  icon: Icons.search_rounded,
                  isLoading: _loading,
                  isPill: true,
                  height: 52,
                  onPressed: _loading ? null : _evaluate,
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB4AB)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          if (_results.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionHeader(
              title: state.tr('possible_local_options'),
              subtitle: 'Crops matching your selected seasonal agro-conditions',
            ),
            const SizedBox(height: 6),
            ..._results.map(
              (item) => AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.mistMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.forestPine,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.cropName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FarmStatusBadge(
                          label: 'Recommended',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.forestPine,
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    Text(
                      state.currentLanguage == 'te'
                          ? item.detailsTe
                          : item.detailsEn,
                      style: const TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF3F7F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.tr('method_prefix')}: ${item.methodology.replaceAll('_', ' ')} · ${state.tr('no_confidence_score')}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
