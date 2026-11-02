from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import ProfileDB
from app.models.schemas import RecommendationItem, CropRecommendationRequest
from app.services.agri_service import AgriService
from app.services.farm_service import FarmService

router = APIRouter(prefix="/crops", tags=["Crop Recommendations (Legacy)"])

@router.get("/recommendations/{farm_id}", response_model=List[RecommendationItem])
def get_crop_recommendations(
    farm_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Legacy recommendations route using the authenticated farm's actual soil data."""
    farm = FarmService.get_farm_by_id(db, farm_id, current_farmer.id)
    req = CropRecommendationRequest(
        farm_id=farm_id,
        soil_type=farm.soil_type,
        season="Kharif",
        available_water="High" if farm.irrigation_source.lower() in {"canal", "borewell", "drip"} else "Low",
    )
    return AgriService.get_crop_recommendations(req)
