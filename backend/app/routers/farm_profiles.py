from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.security import get_current_farmer
from app.core.exceptions import PermissionDeniedException
from app.models.domain import ProfileDB
from app.models.schemas import ProfileResponse, ProfileUpdate
from app.services.auth_service import AuthService

router = APIRouter(prefix="/farm-profiles", tags=["Farmer Profiles"])

@router.get("/me", response_model=ProfileResponse)
def get_my_profile(current_farmer: ProfileDB = Depends(get_current_farmer)):
    """Retrieve the authenticated farmer's profile and configuration."""
    return ProfileResponse.model_validate(current_farmer)

@router.put("/me", response_model=ProfileResponse)
def update_my_profile(
    update_in: ProfileUpdate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Update personal preferences, preferred language (English/Telugu), or simple mode."""
    updated = AuthService.update_profile(db, current_farmer.id, update_in)
    return ProfileResponse.model_validate(updated)

@router.get("/{farmer_id}", response_model=ProfileResponse)
def get_farmer_profile_by_id(
    farmer_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Retrieve profile by farmer ID, ensuring privacy authorization."""
    if current_farmer.id != farmer_id:
        raise PermissionDeniedException("You are not authorized to view another farmer's private profile.")
    profile = AuthService.get_profile_by_id(db, farmer_id)
    return ProfileResponse.model_validate(profile)

@router.put("/{farmer_id}", response_model=ProfileResponse)
def update_farmer_profile_by_id(
    farmer_id: str,
    update_in: ProfileUpdate,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """Update profile by farmer ID with ownership verification."""
    if current_farmer.id != farmer_id:
        raise PermissionDeniedException("You are not authorized to modify another farmer's profile.")
    updated = AuthService.update_profile(db, farmer_id, update_in)
    return ProfileResponse.model_validate(updated)
