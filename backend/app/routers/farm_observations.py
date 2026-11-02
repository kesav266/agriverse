from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import CropCycleDB, FarmDB, ObservationDB, ProfileDB
from app.models.schemas import (
    FarmObservationCreate,
    FarmObservationResponse,
    FarmObservationUpdate,
)

router = APIRouter(prefix="/farm-observations", tags=["Farm Observations"])


def _owned_cycle(db: Session, cycle_id: str, farmer_id: str) -> CropCycleDB:
    cycle = (
        db.query(CropCycleDB)
        .join(FarmDB, FarmDB.id == CropCycleDB.farm_id)
        .filter(CropCycleDB.id == cycle_id, FarmDB.farmer_id == farmer_id)
        .first()
    )
    if cycle is None:
        raise HTTPException(status_code=404, detail="Crop cycle not found")
    return cycle


def _owned_observation(db: Session, observation_id: str, farmer_id: str) -> ObservationDB:
    observation = (
        db.query(ObservationDB)
        .join(CropCycleDB, CropCycleDB.id == ObservationDB.crop_cycle_id)
        .join(FarmDB, FarmDB.id == CropCycleDB.farm_id)
        .filter(ObservationDB.id == observation_id, FarmDB.farmer_id == farmer_id)
        .first()
    )
    if observation is None:
        raise HTTPException(status_code=404, detail="Farm observation not found")
    return observation


@router.get("/crop-cycle/{cycle_id}", response_model=List[FarmObservationResponse])
def list_observations(
    cycle_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """List observations for a crop cycle owned by the authenticated farmer."""
    cycle = _owned_cycle(db, cycle_id, current_farmer.id)
    return (
        db.query(ObservationDB)
        .filter(ObservationDB.crop_cycle_id == cycle.id)
        .order_by(ObservationDB.observation_date.desc(), ObservationDB.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.post(
    "/crop-cycle/{cycle_id}",
    response_model=FarmObservationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_observation(
    cycle_id: str,
    observation_in: FarmObservationCreate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Record dated field observations against an owned crop cycle."""
    cycle = _owned_cycle(db, cycle_id, current_farmer.id)
    observation = ObservationDB(
        crop_cycle_id=cycle.id,
        **observation_in.model_dump(),
    )
    db.add(observation)
    db.commit()
    db.refresh(observation)
    return observation


@router.patch("/{observation_id}", response_model=FarmObservationResponse)
def update_observation(
    observation_id: str,
    update_in: FarmObservationUpdate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Edit a farmer-owned observation without changing its crop-cycle owner."""
    observation = _owned_observation(db, observation_id, current_farmer.id)
    for key, value in update_in.model_dump(exclude_unset=True).items():
        setattr(observation, key, value)
    db.commit()
    db.refresh(observation)
    return observation


@router.delete("/{observation_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_observation(
    observation_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Delete one observation after verifying ownership through its crop cycle."""
    observation = _owned_observation(db, observation_id, current_farmer.id)
    db.delete(observation)
    db.commit()
