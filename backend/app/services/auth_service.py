from typing import Optional, Tuple
from sqlalchemy.orm import Session
from app.core.exceptions import InvalidCredentialsException, DuplicateResourceException, ProfileNotFoundException
from app.core.security import get_password_hash, verify_password, create_access_token
from app.db.repositories import ProfileRepository
from app.models.domain import ProfileDB
from app.models.schemas import ProfileCreate, ProfileResponse, ProfileUpdate

class AuthService:
    @staticmethod
    def register_farmer(db: Session, profile_in: ProfileCreate) -> ProfileDB:
        """Register a new farmer account and securely store credentials."""
        existing = ProfileRepository.get_by_phone(db, profile_in.phone_number)
        if existing:
            raise DuplicateResourceException(
                f"A farmer profile with phone number '{profile_in.phone_number}' is already registered."
            )

        hashed = get_password_hash(profile_in.password)
        profile = ProfileRepository.create(
            db,
            full_name=profile_in.full_name,
            phone_number=profile_in.phone_number,
            hashed_password=hashed,
            village=profile_in.village,
            district=profile_in.district,
            state=profile_in.state,
            preferred_language=profile_in.preferred_language,
            simple_mode_enabled=profile_in.simple_mode_enabled,
        )
        return profile

    @staticmethod
    def login_farmer(
        db: Session,
        phone_number: str,
        password: str,
    ) -> Tuple[str, ProfileDB]:
        """Authenticate a farmer with their password and issue a JWT access token."""
        profile = ProfileRepository.get_by_phone(db, phone_number)
        
        if not profile:
            raise InvalidCredentialsException("No farmer account registered with this phone number.")

        if not verify_password(password, profile.hashed_password):
            raise InvalidCredentialsException("Incorrect password.")

        token = create_access_token({
            "sub": profile.id,
            "phone": profile.phone_number,
            "name": profile.full_name,
            "district": profile.district,
        })
        return token, profile

    @staticmethod
    def get_profile_by_id(db: Session, profile_id: str) -> ProfileDB:
        """Fetch profile by ID or raise 404."""
        profile = ProfileRepository.get_by_id(db, profile_id)
        if not profile:
            raise ProfileNotFoundException(profile_id)
        return profile

    @staticmethod
    def get_profile_by_phone(db: Session, phone_number: str) -> ProfileDB:
        """Fetch profile by phone number or raise 404."""
        profile = ProfileRepository.get_by_phone(db, phone_number)
        if not profile:
            raise ProfileNotFoundException(phone_number)
        return profile

    @staticmethod
    def update_profile(db: Session, profile_id: str, update_in: ProfileUpdate) -> ProfileDB:
        """Update farmer profile details."""
        data = update_in.model_dump(exclude_unset=True)
        updated = ProfileRepository.update(db, profile_id, **data)
        if not updated:
            raise ProfileNotFoundException(profile_id)
        return updated
