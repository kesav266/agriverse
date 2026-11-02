from typing import List
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.security import get_current_farmer
from app.models.domain import ProfileDB
from app.models.schemas import CropCycleCreate, CropCycleResponse, CropCycleUpdate
from app.services.farm_service import FarmService

router = APIRouter(prefix="/crop-cycles", tags=["Crop Cycles"])

@router.get("/farm/{farm_id}", response_model=List[CropCycleResponse])
def get_crop_cycles_for_farm(
    farm_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Retrieve all crop cycles (sowing to harvest) for a given farm land."""
    cycles = FarmService.list_crop_cycles_by_farm(
        db,
        farm_id,
        authenticated_farmer_id=current_farmer.id,
        skip=skip,
        limit=limit,
    )
    return [CropCycleResponse.model_validate(c) for c in cycles]

@router.post("", response_model=CropCycleResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=CropCycleResponse, status_code=status.HTTP_201_CREATED)
def create_crop_cycle(
    cycle_in: CropCycleCreate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Log a newly initiated crop cycle on a farm land."""
    created = FarmService.create_crop_cycle(
        db, cycle_in, authenticated_farmer_id=current_farmer.id
    )
    return CropCycleResponse.model_validate(created)

@router.patch("/{cycle_id}", response_model=CropCycleResponse)
@router.put("/{cycle_id}", response_model=CropCycleResponse)
def update_crop_cycle_stage(
    cycle_id: str,
    update_in: CropCycleUpdate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Update current agricultural growth stage or harvest status."""
    updated = FarmService.update_crop_cycle(
        db, cycle_id, update_in, authenticated_farmer_id=current_farmer.id
    )
    return CropCycleResponse.model_validate(updated)


@router.delete("/{cycle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_crop_cycle(
    cycle_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Delete an owned crop cycle and its observations; estimate links are preserved as NULL."""
    FarmService.delete_crop_cycle(
        db, cycle_id, authenticated_farmer_id=current_farmer.id
    )
