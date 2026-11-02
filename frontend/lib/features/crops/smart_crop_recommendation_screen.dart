import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/recommendation.dart';
import '../../widgets/app_card.dart';
import '../../widgets/main_drawer.dart';

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
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(state.tr('smart_recommendation'))),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  state.tr('rule_based_screening'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(state.tr('screening_disclaimer')),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _season,
                  decoration: InputDecoration(
                    labelText: state.tr('season'),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _soil,
                  decoration: InputDecoration(
                    labelText: state.tr('soil_type'),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _water,
                  decoration: InputDecoration(
                    labelText: state.tr('water_availability'),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _loading ? null : _evaluate,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    state.tr(_loading ? 'evaluating' : 'get_crop_screening'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              state.tr('possible_local_options'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._results.map(
              (item) => AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cropName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentLanguage == 'te'
                          ? item.detailsTe
                          : item.detailsEn,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.tr('method_prefix')}: ${item.methodology.replaceAll('_', ' ')} · ${state.tr('no_confidence_score')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
