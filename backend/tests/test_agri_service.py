from app.models.schemas import CropRecommendationRequest, IrrigationScheduleRequest, YieldCalculationRequest
from app.services.agri_service import AgriService


def test_yield_arithmetic_uses_only_submitted_values():
    request = YieldCalculationRequest(
        crop_name="Paddy",
        land_area_acres=2,
        expected_yield_quintals=30,
        market_price_per_quintal_inr=2100,
        cost_of_seeds_inr=1000,
        cost_of_fertilizers_inr=2000,
        cost_of_labor_inr=3000,
        cost_of_machinery_inr=500,
    )
    result = AgriService.calculate_yield(request)
    assert result.projected_total_revenue_inr == 63000
    assert result.total_cost_of_cultivation_inr == 6500
    assert result.projected_net_profit_inr == 56500
    assert result.assumed_yield_rate_per_acre == 15
    assert "No crop-yield model" in result.assumptions_basis


def test_recommendation_rules_return_reasoning_without_numeric_score():
    result = AgriService.get_crop_recommendations(CropRecommendationRequest(
        soil_type="Black soil", season="Kharif", available_water="high"
    ))
    paddy = next(item for item in result if item.crop_name == "Paddy (Rice)")
    assert paddy.confidence_score is None
    assert paddy.methodology == "transparent_rules"
    assert paddy.reasoning_factors
    assert "Confirm suitability" in paddy.details_en


def test_irrigation_rule_never_calculates_liters():
    result = AgriService.calculate_irrigation(IrrigationScheduleRequest(
        crop_name="Paddy",
        soil_moisture_percentage=42,
        last_irrigation_date="2026-10-10",
    ))
    assert result.water_amount_liters_per_acre is None
    assert "cannot determine whether or how much" in result.advisory_en
