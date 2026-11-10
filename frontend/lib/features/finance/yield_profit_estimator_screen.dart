import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/yield_estimate.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/tts_button.dart';

/// Screen 10: Premium Modern Yield & Financial Profit Analysis Screen.
class YieldProfitEstimatorScreen extends StatefulWidget {
  const YieldProfitEstimatorScreen({super.key});

  @override
  State<YieldProfitEstimatorScreen> createState() =>
      _YieldProfitEstimatorScreenState();
}

class _YieldProfitEstimatorScreenState
    extends State<YieldProfitEstimatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crop = TextEditingController();
  final _area = TextEditingController();
  final _yield = TextEditingController();
  final _price = TextEditingController();
  final _seeds = TextEditingController(text: '0');
  final _fertilizers = TextEditingController(text: '0');
  final _labor = TextEditingController(text: '0');
  final _machinery = TextEditingController(text: '0');
  YieldEstimate? _result;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _crop,
      _area,
      _yield,
      _price,
      _seeds,
      _fertilizers,
      _labor,
      _machinery,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _numberValidator(String? value, {required bool positive}) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null ||
        !parsed.isFinite ||
        (positive ? parsed <= 0 : parsed < 0)) {
      return positive
          ? 'Enter a number greater than zero'
          : 'Enter zero or a positive number';
    }
    return null;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool positive = false,
    bool text = false,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: text
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      textCapitalization: text
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.forestPine, size: 20) : null,
      ),
      validator: text
          ? (value) =>
                value == null || value.trim().isEmpty ? 'Enter $label' : null
          : (value) => _numberValidator(value, positive: positive),
    ),
  );

  Future<void> _calculate() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    final state = context.read<AppStateProvider>();
    final firstFarm = state.farms.isEmpty ? null : state.farms.first;
    try {
      final result = await state.calculateYield({
        'crop_name': _crop.text.trim(),
        'land_area_acres': double.parse(_area.text),
        'expected_yield_quintals': double.parse(_yield.text),
        'market_price_per_quintal_inr': double.parse(_price.text),
        'cost_of_seeds_inr': double.parse(_seeds.text),
        'cost_of_fertilizers_inr': double.parse(_fertilizers.text),
        'cost_of_labor_inr': double.parse(_labor.text),
        'cost_of_machinery_inr': double.parse(_machinery.text),
        if (firstFarm != null) 'farm_id': firstFarm.id,
      });
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _result;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(state.tr('yield_estimator')),
        actions: [
          if (result != null)
            TtsButton(
              textToSpeak:
                  'Estimated net profit ${result.projectedNetProfit.toStringAsFixed(0)} rupees. This is an estimate based on your entered values.',
            ),
        ],
      ),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input Form Card
          AppCard(
            padding: const EdgeInsets.all(22),
            borderRadius: 24,
            child: Form(
              key: _formKey,
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
                          Icons.calculate_rounded,
                          color: AppColors.forestPine,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crop Production & Economics',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enter your field parameters and seasonal inputs',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _field('Crop name', _crop, text: true, icon: Icons.grass_rounded),
                  _field('Farm area (acres)', _area, positive: true, icon: Icons.landscape_rounded),
                  _field('Expected total yield (quintals)', _yield, positive: true, icon: Icons.scale_rounded),
                  _field('Expected market price per quintal (₹)', _price, icon: Icons.currency_rupee_rounded),
                  const Divider(height: 28),
                  const Text(
                    'Cultivation Expenses (₹)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestPine,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _field('Seed cost', _seeds, icon: Icons.spa_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Fertilizers', _fertilizers, icon: Icons.science_rounded)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('Labor cost', _labor, icon: Icons.people_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Machinery', _machinery, icon: Icons.agriculture_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: _busy ? 'Calculating…' : 'Calculate & Save Estimate',
                    icon: Icons.analytics_rounded,
                    isLoading: _busy,
                    isPill: true,
                    height: 52,
                    onPressed: _busy ? null : _calculate,
                  ),
                ],
              ),
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

          if (result != null) ...[
            const SizedBox(height: 18),
            // Financial Hero Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F3B25), Color(0xFF14532D), Color(0xFF1B6A3B)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220A2E1B),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.tr('estimated_net_profit'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ROI ${result.roiPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.forestPine,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${result.projectedNetProfit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricColumn(
                          state.tr('revenue'),
                          '₹${(result.projectedNetProfit + result.totalCostOfCultivation).toStringAsFixed(0)}',
                        ),
                        Container(width: 1, height: 24, color: Colors.white24),
                        _metricColumn(
                          state.tr('entered_costs'),
                          '₹${result.totalCostOfCultivation.toStringAsFixed(0)}',
                        ),
                        Container(width: 1, height: 24, color: Colors.white24),
                        _metricColumn(
                          'Yield',
                          '${result.estimatedYieldQuintals.toStringAsFixed(1)} q',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Assumptions & Advisory Card
            AppCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.forestPine, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        result.assumptionsBasis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    state.currentLanguage == 'te'
                        ? result.advisoryTe
                        : result.advisoryEn,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
