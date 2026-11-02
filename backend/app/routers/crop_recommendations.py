from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.schemas import CropRecommendationRequest, RecommendationItem
from app.core.security import get_current_farmer
from app.models.domain import ProfileDB
from app.services.agri_service import AgriService
from app.services.farm_service import FarmService

router = APIRouter(prefix="/crop-recommendations", tags=["Crop Recommendations"])

@router.post("/evaluate", response_model=List[RecommendationItem])
def evaluate_crop_suitability(
    req: CropRecommendationRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """
    Transparent rule-based recommendation engine evaluating soil type,
    season, water availability, and agro-climatic conditions.
    """
    if req.farm_id:
        farm = FarmService.get_farm_by_id(db, req.farm_id, current_farmer.id)
        req = req.model_copy(update={"soil_type": farm.soil_type})
    return AgriService.get_crop_recommendations(req)

@router.get("/{farm_id}", response_model=List[RecommendationItem])
def get_recommendations_for_farm(
    farm_id: str,
    season: str = Query(..., pattern="^(?i:kharif|rabi|zaid)$"),
    available_water: str = Query(..., pattern="^(?i:high|medium|low|rainfed)$"),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Retrieve tailored crop recommendations for a farm based on its registered soil type."""
    farm = FarmService.get_farm_by_id(db, farm_id, current_farmer.id)
    req = CropRecommendationRequest(
        farm_id=farm.id,
        soil_type=farm.soil_type,
        season=season,
        available_water=available_water,
    )
    return AgriService.get_crop_recommendations(req)
