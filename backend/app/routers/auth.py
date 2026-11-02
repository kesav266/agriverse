from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.security import get_current_farmer
from app.core.exceptions import PermissionDeniedException
from app.models.domain import ProfileDB
from app.models.schemas import ProfileCreate, ProfileResponse, LoginRequest, AuthTokenResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication & Farmer Access"])

@router.post("/register", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
def register_farmer(profile_in: ProfileCreate, db: Session = Depends(get_db)):
    """Register a new farmer account with hashed credentials and language preference."""
    profile = AuthService.register_farmer(db, profile_in)
    return ProfileResponse.model_validate(profile)

@router.post("/login", response_model=AuthTokenResponse)
def login_farmer(login_req: LoginRequest, db: Session = Depends(get_db)):
    """Authenticate farmer with a password and issue a signed JWT access token."""
    token, profile = AuthService.login_farmer(
        db,
        phone_number=login_req.phone_number,
        password=login_req.password
    )
    return AuthTokenResponse(
        access_token=token,
        token_type="bearer",
        profile=ProfileResponse.model_validate(profile)
    )

@router.get("/me", response_model=ProfileResponse)
def get_current_farmer_profile(current_farmer: ProfileDB = Depends(get_current_farmer)):
    """Retrieve the currently authenticated farmer's private profile."""
    return ProfileResponse.model_validate(current_farmer)

@router.get("/profile/{phone_number}", response_model=ProfileResponse)
def get_profile_by_phone(
    phone_number: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Legacy profile lookup restricted to the authenticated farmer."""
    if current_farmer.phone_number != phone_number:
        raise PermissionDeniedException("You may only view your own profile.")
    profile = AuthService.get_profile_by_phone(db, phone_number)
    return ProfileResponse.model_validate(profile)
