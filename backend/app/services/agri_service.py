from datetime import date, timedelta
from typing import List
import uuid

from app.models.schemas import (
    CropRecommendationRequest,
    RecommendationItem,
    RecommendationFactor,
    IrrigationScheduleRequest,
    IrrigationScheduleResponse,
    YieldCalculationRequest,
    YieldCalculationResponse,
)


class AgriService:
    """Transparent rules and arithmetic that do not depend on fabricated data."""

    @staticmethod
    def get_crop_recommendations(req: CropRecommendationRequest) -> List[RecommendationItem]:
        soil = req.soil_type.strip().lower()
        season = req.season.strip().lower()
        water = req.available_water.strip().lower()
        result: List[RecommendationItem] = []

        def add(crop: str, title: str, reason: str, factors: list[RecommendationFactor]) -> None:
            result.append(RecommendationItem(
                id=str(uuid.uuid4()),
                farm_id=req.farm_id,
                crop_name=crop,
                category="Crop Selection",
                recommendation_title=title,
                details_en=(
                    f"Rule match: {reason} This screening does not include soil tests, local rainfall, "
                    "pest pressure, variety, or market conditions. Confirm suitability with a local "
                    "agricultural extension officer before planting."
                ),
                details_te=(
                    f"నియమాల ఆధారంగా: {reason} ఈ ప్రాథమిక పరిశీలనలో నేల పరీక్షలు, స్థానిక వర్షపాతం, "
                    "తెగుళ్ల ఒత్తిడి, వంగడం లేదా మార్కెట్ పరిస్థితులు లేవు. విత్తే ముందు స్థానిక వ్యవసాయ "
                    "విస్తరణ అధికారిని సంప్రదించండి."
                ),
                confidence_score=None,
                methodology="transparent_rules",
                reasoning_factors=factors,
            ))

        common = [
            RecommendationFactor(
                factor_name="Soil type",
                observation=req.soil_type,
                suitability="Used as a broad screening condition; not a laboratory soil test.",
            ),
            RecommendationFactor(
                factor_name="Season",
                observation=req.season,
                suitability="Used as a broad calendar filter; local sowing windows vary.",
            ),
            RecommendationFactor(
                factor_name="Water availability",
                observation=req.available_water,
                suitability="Used as farmer-reported context; no irrigation quantity is inferred.",
            ),
        ]

        if "black" in soil and season == "kharif" and water in {"high", "medium"}:
            add("Paddy (Rice)", "Paddy is a possible Kharif option", "reported black soil, Kharif season, and medium or high water availability match the screening rules.", common)
        if ("black" in soil or "clay" in soil) and season in {"kharif", "rabi"}:
            add("Cotton", "Cotton is a possible option", "reported black or clay soil and the selected season match the screening rules.", common)
        if ("red" in soil or "sandy" in soil) and season in {"kharif", "rabi"}:
            add("Groundnut", "Groundnut is a possible option", "reported red or sandy soil and the selected season match the screening rules.", common)
        if not result:
            add("Pulses", "Check short-duration pulse options locally", "the supplied combination has no specific crop rule in this limited rule set.", common)
        return result

    @staticmethod
    def calculate_irrigation(req: IrrigationScheduleRequest) -> IrrigationScheduleResponse:
        # Percent readings are not portable across sensor types, soil textures,
        # root depths, and crop stages. Do not convert them into liters or dates.
        return IrrigationScheduleResponse(
            recommendation="Field assessment required",
            next_assessment_date=date.today() + timedelta(days=1),
            water_amount_liters_per_acre=None,
            advisory_en=(
                f"The submitted soil-moisture reading is {req.soil_moisture_percentage:.1f}%. "
                f"The last irrigation date entered was {req.last_irrigation_date.isoformat()}. "
                "A percentage and date alone cannot determine whether or how much to irrigate. Check moisture "
                "at the active root depth, inspect the crop, and account for the next local rainfall forecast "
                "before deciding."
            ),
            advisory_te=(
                f"మీరు నమోదు చేసిన నేల తేమ {req.soil_moisture_percentage:.1f}%. ఈ శాతం ఒక్కటితో నీరు "
                "అవసరమా లేదా ఎంత ఇవ్వాలో నిర్ణయించలేం. వేర్ల లోతులో తేమను, పంట స్థితిని పరిశీలించి, "
                "స్థానిక వర్ష సూచనను పరిగణనలోకి తీసుకోండి."
            ),
            missing_information=[
                "soil texture and sensor calibration",
                "crop growth stage and root depth",
                "local rainfall forecast",
                "irrigation system and recent effective rainfall",
            ],
        )

    @staticmethod
    def calculate_yield(req: YieldCalculationRequest) -> YieldCalculationResponse:
        total_cost = round(
            req.cost_of_seeds_inr
            + req.cost_of_fertilizers_inr
            + req.cost_of_labor_inr
            + req.cost_of_machinery_inr,
            2,
        )
        expected_yield = round(req.expected_yield_quintals, 2)
        price = round(req.market_price_per_quintal_inr, 2)
        revenue = round(expected_yield * price, 2)
        net_profit = round(revenue - total_cost, 2)
        roi = round((net_profit / total_cost) * 100, 2) if total_cost else 0.0
        rate_per_acre = round(expected_yield / req.land_area_acres, 2)
        basis = (
            "Arithmetic estimate using farmer-entered total yield, selling price, and listed costs. "
            "No crop-yield model or live market-price feed is configured."
        )
        return YieldCalculationResponse(
            crop_name=req.crop_name.strip(),
            land_area_acres=req.land_area_acres,
            estimated_yield_quintals=expected_yield,
            assumed_yield_rate_per_acre=rate_per_acre,
            total_cost_of_cultivation_inr=total_cost,
            expected_market_price_per_quintal=price,
            projected_total_revenue_inr=revenue,
            projected_net_profit_inr=net_profit,
            roi_percentage=roi,
            assumptions_basis=basis,
            advisory_en="Estimate only. Actual yield, sale grade, price, and total costs may differ.",
            advisory_te="ఇది అంచనా మాత్రమే. వాస్తవ దిగుబడి, నాణ్యత, ధర మరియు మొత్తం ఖర్చులు మారవచ్చు.",
        )
