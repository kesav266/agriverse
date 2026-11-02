from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.security import get_current_farmer
from app.core.exceptions import AgriVerseException
from app.db.database import get_db
from app.models.domain import ProfileDB
from app.models.schemas import IrrigationScheduleRequest, IrrigationScheduleResponse
from app.services.agri_service import AgriService

router = APIRouter(prefix="/irrigation", tags=["Irrigation Management"])

@router.post("/schedule", response_model=IrrigationScheduleResponse)
def calculate_irrigation_schedule(
    req: IrrigationScheduleRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Calculate optimal irrigation schedule based on soil moisture and crop type."""
    if req.farm_id:
        from app.services.farm_service import FarmService
        FarmService.get_farm_by_id(db, req.farm_id, current_farmer.id)
    return AgriService.calculate_irrigation(req)
