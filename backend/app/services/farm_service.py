from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.exceptions import FarmNotFoundException, PermissionDeniedException, CropCycleNotFoundException
from app.db.repositories import FarmRepository, CropCycleRepository
from app.models.domain import FarmDB, CropCycleDB
from app.models.schemas import FarmCreate, FarmUpdate, CropCycleCreate, CropCycleUpdate

class FarmService:
    @staticmethod
    def list_farms_by_farmer(
        db: Session, farmer_id: str, skip: int = 0, limit: int = 50
    ) -> List[FarmDB]:
        """Fetch a page of farm properties owned by the given farmer."""
        return FarmRepository.list_by_farmer(db, farmer_id, skip, limit)

    @staticmethod
    def get_farm_by_id(db: Session, farm_id: str, authenticated_farmer_id: Optional[str] = None) -> FarmDB:
        """Fetch a specific farm by ID, verifying ownership if authenticated_farmer_id is provided."""
        farm = FarmRepository.get_by_id(db, farm_id)
        if not farm:
            raise FarmNotFoundException(farm_id)
        if authenticated_farmer_id and farm.farmer_id != authenticated_farmer_id:
            raise PermissionDeniedException("You are not authorized to access this farm property.")
        return farm

    @staticmethod
    def create_farm(db: Session, farm_in: FarmCreate, authenticated_farmer_id: Optional[str] = None) -> FarmDB:
        """Create a new farm under the specified farmer ID."""
        if not authenticated_farmer_id:
            raise PermissionDeniedException("Sign in before creating a farm.")
        target_farmer_id = farm_in.farmer_id or authenticated_farmer_id
        # Verify that authenticated farmer isn't creating farms on behalf of others without permission
        if authenticated_farmer_id and target_farmer_id != authenticated_farmer_id:
            raise PermissionDeniedException("Cannot create farm lands for a different farmer.")

        return FarmRepository.create(
            db,
            farmer_id=target_farmer_id,
            farm_name=farm_in.farm_name,
            land_area_acres=farm_in.land_area_acres,
            soil_type=farm_in.soil_type,
            irrigation_source=farm_in.irrigation_source,
            latitude=farm_in.latitude,
            longitude=farm_in.longitude,
            survey_number=farm_in.survey_number
        )

    @staticmethod
    def update_farm(db: Session, farm_id: str, farm_update: FarmUpdate, authenticated_farmer_id: Optional[str] = None) -> FarmDB:
        """Update farm details with authorization check."""
        farm = FarmService.get_farm_by_id(db, farm_id, authenticated_farmer_id)
        data = farm_update.model_dump(exclude_unset=True)
        updated = FarmRepository.update(db, farm_id, **data)
        return updated or farm

    @staticmethod
    def delete_farm(db: Session, farm_id: str, authenticated_farmer_id: Optional[str] = None) -> bool:
        """Delete a farm property with ownership verification."""
        FarmService.get_farm_by_id(db, farm_id, authenticated_farmer_id)
        return FarmRepository.delete(db, farm_id)

    # ----------------------------------------------------------------
    # Crop Cycle Management
    # ----------------------------------------------------------------
    @staticmethod
    def list_crop_cycles_by_farm(
        db: Session,
        farm_id: str,
        authenticated_farmer_id: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
    ) -> List[CropCycleDB]:
        """Fetch crop cycles for a farm."""
        FarmService.get_farm_by_id(db, farm_id, authenticated_farmer_id)
        return CropCycleRepository.list_by_farm(db, farm_id, skip, limit)

    @staticmethod
    def create_crop_cycle(db: Session, cycle_in: CropCycleCreate, authenticated_farmer_id: Optional[str] = None) -> CropCycleDB:
        """Create a new crop cycle under a verified farm."""
        FarmService.get_farm_by_id(db, cycle_in.farm_id, authenticated_farmer_id)
        return CropCycleRepository.create(
            db,
            farm_id=cycle_in.farm_id,
            crop_name=cycle_in.crop_name,
            variety=cycle_in.variety or "Standard",
            sowing_date=cycle_in.sowing_date,
            expected_harvest_date=cycle_in.expected_harvest_date,
            stage=cycle_in.stage,
            status="Active"
        )

    @staticmethod
    def update_crop_cycle(db: Session, cycle_id: str, update_in: CropCycleUpdate, authenticated_farmer_id: Optional[str] = None) -> CropCycleDB:
        """Update stage or harvest date of a crop cycle."""
        cycle = CropCycleRepository.get_by_id(db, cycle_id)
        if not cycle:
            raise CropCycleNotFoundException(cycle_id)
        # Verify farm ownership
        FarmService.get_farm_by_id(db, cycle.farm_id, authenticated_farmer_id)
        data = update_in.model_dump(exclude_unset=True)
        sowing_date = data.get("sowing_date", cycle.sowing_date)
        harvest_date = data.get("expected_harvest_date", cycle.expected_harvest_date)
        if harvest_date is not None and harvest_date < sowing_date:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Expected harvest date must be on or after the sowing date.",
            )
        updated = CropCycleRepository.update(db, cycle_id, **data)
        return updated or cycle

    @staticmethod
    def delete_crop_cycle(
        db: Session,
        cycle_id: str,
        authenticated_farmer_id: Optional[str] = None,
    ) -> bool:
        cycle = CropCycleRepository.get_by_id(db, cycle_id)
        if not cycle:
            raise CropCycleNotFoundException(cycle_id)
        FarmService.get_farm_by_id(db, cycle.farm_id, authenticated_farmer_id)
        return CropCycleRepository.delete(db, cycle_id)
