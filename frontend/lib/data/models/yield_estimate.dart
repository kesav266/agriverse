class YieldEstimate {
  final double estimatedYieldQuintals;
  final double totalCostOfCultivation;
  final double expectedMarketPrice;
  final double projectedTotalRevenue;
  final double projectedNetProfit;
  final double roiPercentage;
  final String advisoryEn;
  final String advisoryTe;
  final String assumptionsBasis;

  YieldEstimate({
    required this.estimatedYieldQuintals,
    required this.totalCostOfCultivation,
    required this.expectedMarketPrice,
    required this.projectedTotalRevenue,
    required this.projectedNetProfit,
    required this.roiPercentage,
    required this.advisoryEn,
    required this.advisoryTe,
    required this.assumptionsBasis,
  });

  factory YieldEstimate.fromJson(Map<String, dynamic> json) {
    return YieldEstimate(
      estimatedYieldQuintals: _requiredNumber(json, 'estimated_yield_quintals'),
      totalCostOfCultivation: _requiredNumber(
        json,
        'total_cost_of_cultivation_inr',
      ),
      expectedMarketPrice: _requiredNumber(
        json,
        'expected_market_price_per_quintal',
      ),
      projectedTotalRevenue: _requiredNumber(
        json,
        'projected_total_revenue_inr',
      ),
      projectedNetProfit: _requiredNumber(json, 'projected_net_profit_inr'),
      roiPercentage: _requiredNumber(json, 'roi_percentage'),
      advisoryEn: _requiredString(json, 'advisory_en'),
      advisoryTe: _requiredString(json, 'advisory_te'),
      assumptionsBasis: _requiredString(json, 'assumptions_basis'),
    );
  }
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Missing required estimate field: $key');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required estimate field: $key');
}
