from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import ProfileDB
from app.models.schemas import YieldCalculationRequest, YieldCalculationResponse
from app.routers.yield_estimates import calculate_and_save

router = APIRouter(prefix="/finance", tags=["Yield & Profit Calculations (Legacy)"])

@router.post("/calculate-yield", response_model=YieldCalculationResponse)
def calculate_farm_yield(
    req: YieldCalculationRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Estimate crop yield, cultivation cost, revenue, and net profit (Flutter compatibility)."""
    return calculate_and_save(req, current_farmer, db)
