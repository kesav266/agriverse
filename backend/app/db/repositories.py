from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from app.models.domain import ProfileDB, FarmDB, CropCycleDB, ObservationDB, RecommendationDB, WeatherRecordDB, ImageDiagnosisDB, YieldEstimateDB
from app.core.logging import logger

class ProfileRepository:
    @staticmethod
    def get_by_id(db: Session, profile_id: str) -> Optional[ProfileDB]:
        return db.query(ProfileDB).filter(ProfileDB.id == profile_id).first()

    @staticmethod
    def get_by_phone(db: Session, phone_number: str) -> Optional[ProfileDB]:
        return db.query(ProfileDB).filter(ProfileDB.phone_number == phone_number).first()

    @staticmethod
    def create(db: Session, **kwargs) -> ProfileDB:
        profile = ProfileDB(**kwargs)
        db.add(profile)
        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def update(db: Session, profile_id: str, **kwargs) -> Optional[ProfileDB]:
        profile = ProfileRepository.get_by_id(db, profile_id)
        if not profile:
            return None
        for key, value in kwargs.items():
            if value is not None and hasattr(profile, key):
                setattr(profile, key, value)
        db.commit()
        db.refresh(profile)
        return profile

class FarmRepository:
    @staticmethod
    def get_by_id(db: Session, farm_id: str) -> Optional[FarmDB]:
        return db.query(FarmDB).filter(FarmDB.id == farm_id).first()

    @staticmethod
    def list_by_farmer(
        db: Session, farmer_id: str, skip: int = 0, limit: int = 50
    ) -> List[FarmDB]:
        return (
            db.query(FarmDB)
            .filter(FarmDB.farmer_id == farmer_id)
            .order_by(FarmDB.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    @staticmethod
    def create(db: Session, **kwargs) -> FarmDB:
        farm = FarmDB(**kwargs)
        db.add(farm)
        db.commit()
        db.refresh(farm)
        return farm

    @staticmethod
    def update(db: Session, farm_id: str, **kwargs) -> Optional[FarmDB]:
        farm = FarmRepository.get_by_id(db, farm_id)
        if not farm:
            return None
        for key, value in kwargs.items():
            if hasattr(farm, key):
                setattr(farm, key, value)
        db.commit()
        db.refresh(farm)
        return farm

    @staticmethod
    def delete(db: Session, farm_id: str) -> bool:
        farm = FarmRepository.get_by_id(db, farm_id)
        if not farm:
            return False
        db.delete(farm)
        db.commit()
        return True

class CropCycleRepository:
    @staticmethod
    def get_by_id(db: Session, cycle_id: str) -> Optional[CropCycleDB]:
        return db.query(CropCycleDB).filter(CropCycleDB.id == cycle_id).first()

    @staticmethod
    def list_by_farm(
        db: Session, farm_id: str, skip: int = 0, limit: int = 50
    ) -> List[CropCycleDB]:
        return (
            db.query(CropCycleDB)
            .filter(CropCycleDB.farm_id == farm_id)
            .order_by(CropCycleDB.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    @staticmethod
    def list_by_farmer(db: Session, farmer_id: str) -> List[CropCycleDB]:
        return db.query(CropCycleDB).join(FarmDB).filter(FarmDB.farmer_id == farmer_id).all()

    @staticmethod
    def create(db: Session, **kwargs) -> CropCycleDB:
        cycle = CropCycleDB(**kwargs)
        db.add(cycle)
        db.commit()
        db.refresh(cycle)
        return cycle

    @staticmethod
    def update(db: Session, cycle_id: str, **kwargs) -> Optional[CropCycleDB]:
        cycle = CropCycleRepository.get_by_id(db, cycle_id)
        if not cycle:
            return None
        for key, value in kwargs.items():
            if hasattr(cycle, key):
                setattr(cycle, key, value)
        db.commit()
        db.refresh(cycle)
        return cycle

    @staticmethod
    def delete(db: Session, cycle_id: str) -> bool:
        cycle = CropCycleRepository.get_by_id(db, cycle_id)
        if cycle is None:
            return False
        db.delete(cycle)
        db.commit()
        return True
