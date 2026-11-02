import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/yield_estimate.dart';
import '../../widgets/app_card.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/tts_button.dart';

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
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
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
        border: const OutlineInputBorder(),
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
    final result = _result;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
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
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter your crop and current estimates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _field('Crop name', _crop, text: true),
                  _field('Farm area (acres)', _area, positive: true),
                  _field(
                    'Expected total yield (quintals)',
                    _yield,
                    positive: true,
                  ),
                  _field('Your expected price per quintal (₹)', _price),
                  const Divider(height: 24),
                  Text(
                    'Costs (₹)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  _field('Seed cost', _seeds),
                  _field('Fertilizer cost', _fertilizers),
                  _field('Labor cost', _labor),
                  _field('Machinery cost', _machinery),
                  FilledButton.icon(
                    onPressed: _busy ? null : _calculate,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calculate_outlined),
                    label: Text(
                      _busy ? 'Calculating…' : 'Calculate and save estimate',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.tr('estimated_net_profit'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '₹${result.projectedNetProfit.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.tr('revenue')}: ₹${(result.projectedNetProfit + result.totalCostOfCultivation).toStringAsFixed(2)}',
                  ),
                  Text(
                    '${state.tr('entered_yield')}: ${result.estimatedYieldQuintals.toStringAsFixed(2)} ${state.tr('quintals')}',
                  ),
                  Text(
                    '${state.tr('entered_price')}: ₹${result.expectedMarketPrice.toStringAsFixed(2)} ${state.tr('per_quintal')}',
                  ),
                  Text(
                    '${state.tr('entered_costs')}: ₹${result.totalCostOfCultivation.toStringAsFixed(2)}',
                  ),
                  Text(
                    '${state.tr('roi_prefix')}: ${result.roiPercentage.toStringAsFixed(1)}%',
                  ),
                  const Divider(height: 22),
                  Text(result.assumptionsBasis),
                  const SizedBox(height: 8),
                  Text(
                    state.currentLanguage == 'te'
                        ? result.advisoryTe
                        : result.advisoryEn,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
