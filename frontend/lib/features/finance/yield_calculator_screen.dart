import 'package:flutter/material.dart';
import 'yield_profit_estimator_screen.dart';

/// Legacy alias router forwarding to YieldProfitEstimatorScreen.
class YieldCalculatorScreen extends StatelessWidget {
  const YieldCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const YieldProfitEstimatorScreen();
  }
}
