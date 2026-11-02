from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.exceptions import AgriVerseException
from app.core.logging import logger
from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import CropCycleDB, FarmDB, ProfileDB, YieldEstimateDB
from app.models.schemas import (
    YieldCalculationRequest,
    YieldCalculationResponse,
    YieldEstimateHistoryItem,
)
from app.services.agri_service import AgriService
from app.services.farm_service import FarmService

router = APIRouter(prefix="/yield-estimates", tags=["Yield & Profit Calculations"])


def calculate_and_save(
    request: YieldCalculationRequest,
    current_farmer: ProfileDB,
    db: Session,
) -> YieldCalculationResponse:
    farm_id = request.farm_id
    if request.crop_cycle_id:
        cycle = (
            db.query(CropCycleDB)
            .join(FarmDB, CropCycleDB.farm_id == FarmDB.id)
            .filter(CropCycleDB.id == request.crop_cycle_id, FarmDB.farmer_id == current_farmer.id)
            .first()
        )
        if cycle is None:
            raise AgriVerseException("Crop cycle not found.", 404, "CROP_CYCLE_NOT_FOUND")
        if farm_id and farm_id != cycle.farm_id:
            raise AgriVerseException("Crop cycle does not belong to this farm.", 422, "INVALID_FARM_CYCLE")
        farm_id = cycle.farm_id
    elif farm_id:
        FarmService.get_farm_by_id(db, farm_id, current_farmer.id)

    result = AgriService.calculate_yield(request)
    estimate = YieldEstimateDB(
        farmer_id=current_farmer.id,
        crop_name=result.crop_name,
        farm_id=farm_id,
        crop_cycle_id=request.crop_cycle_id,
        estimated_yield_quintals=result.estimated_yield_quintals,
        cost_of_cultivation_inr=result.total_cost_of_cultivation_inr,
        expected_market_price_per_quintal=result.expected_market_price_per_quintal,
        projected_revenue_inr=result.projected_total_revenue_inr,
        projected_net_profit_inr=result.projected_net_profit_inr,
    )
    try:
        db.add(estimate)
        db.commit()
    except Exception as exc:
        db.rollback()
        logger.error("Failed to save yield estimate; exception_type=%s", type(exc).__name__)
        raise AgriVerseException(
            "The estimate could not be saved.", status_code=503, error_code="YIELD_PERSISTENCE_FAILED"
        )
    return result


@router.post("", response_model=YieldCalculationResponse)
@router.post("/", response_model=YieldCalculationResponse)
@router.post("/calculate", response_model=YieldCalculationResponse)
def calculate_yield_and_profit(
    request: YieldCalculationRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return calculate_and_save(request, current_farmer, db)


@router.get("/history", response_model=List[YieldEstimateHistoryItem])
def get_yield_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(YieldEstimateDB)
        .filter(YieldEstimateDB.farmer_id == current_farmer.id)
        .order_by(YieldEstimateDB.calculated_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [
        YieldEstimateHistoryItem(
            id=row.id,
            farm_id=row.farm_id,
            crop_cycle_id=row.crop_cycle_id,
            crop_name=row.crop_name or (row.crop_cycle.crop_name if row.crop_cycle else None),
            estimated_yield_quintals=row.estimated_yield_quintals,
            cost_of_cultivation_inr=row.cost_of_cultivation_inr,
            expected_market_price_per_quintal=row.expected_market_price_per_quintal,
            projected_revenue_inr=row.projected_revenue_inr,
            projected_net_profit_inr=row.projected_net_profit_inr,
            calculated_at=row.calculated_at,
        )
        for row in rows
    ]
