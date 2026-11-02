from typing import List
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.security import get_current_farmer
from app.models.domain import ProfileDB
from app.models.schemas import FarmCreate, FarmResponse, FarmUpdate
from app.services.farm_service import FarmService

router = APIRouter(prefix="/farms", tags=["Farm Lands & Properties"])

@router.get("", response_model=List[FarmResponse])
@router.get("/", response_model=List[FarmResponse])
def list_my_farms(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """List only the authenticated farmer's farm plots."""
    farms = FarmService.list_farms_by_farmer(db, current_farmer.id, skip, limit)
    return [FarmResponse.model_validate(f) for f in farms]

@router.post("", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
def create_farm(
    farm_in: FarmCreate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Register a new farm plot under the authenticated farmer."""
    created_farm = FarmService.create_farm(db, farm_in, authenticated_farmer_id=current_farmer.id)
    return FarmResponse.model_validate(created_farm)

@router.get("/farmer/{farmer_id}", response_model=List[FarmResponse])
def get_farms_by_farmer_legacy(
    farmer_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Legacy list route restricted to the authenticated farmer's own records."""
    if current_farmer.id != farmer_id:
        from app.core.exceptions import PermissionDeniedException
        raise PermissionDeniedException("You may only view your own farms.")
    farms = FarmService.list_farms_by_farmer(db, farmer_id, skip, limit)
    return [FarmResponse.model_validate(f) for f in farms]

@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm_details(
    farm_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Fetch details of an individual farm plot."""
    farm = FarmService.get_farm_by_id(db, farm_id, authenticated_farmer_id=current_farmer.id)
    return FarmResponse.model_validate(farm)

@router.put("/{farm_id}", response_model=FarmResponse)
def update_farm_details(
    farm_id: str,
    farm_update: FarmUpdate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Update details of an owned farm plot."""
    updated = FarmService.update_farm(db, farm_id, farm_update, authenticated_farmer_id=current_farmer.id)
    return FarmResponse.model_validate(updated)

@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farm_plot(
    farm_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Delete a farm plot owned by the authenticated farmer."""
    FarmService.delete_farm(db, farm_id, authenticated_farmer_id=current_farmer.id)
    return None
