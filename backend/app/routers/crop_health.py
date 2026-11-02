from typing import List

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.core.config import settings
from app.core.exceptions import AgriVerseException
from app.core.logging import logger
from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import ImageDiagnosisDB, ProfileDB
from app.models.schemas import DiagnosisResponse
from app.services.disease_service import diagnose_image as run_model

router = APIRouter(prefix="/crop-health", tags=["Crop Health & Disease AI"])


async def process_diagnosis(
    file: UploadFile,
    crop_name: str,
    current_farmer: ProfileDB,
    db: Session,
) -> DiagnosisResponse:
    if not crop_name.strip() or len(crop_name.strip()) > 100:
        raise AgriVerseException("Crop name must contain 1 to 100 characters.", 422, "INVALID_CROP_NAME")
    data = await file.read(settings.MAX_UPLOAD_BYTES + 1)
    result = await run_in_threadpool(
        run_model, data, file.content_type, crop_name.strip(), current_farmer.id
    )
    diagnosis = ImageDiagnosisDB(
        id=result.id,
        farmer_id=current_farmer.id,
        crop_name=result.crop_name,
        image_url=None,  # Image bytes are processed in memory and are not retained.
        detected_disease=result.detected_disease,
        severity=result.severity,
        recommended_treatment_en=result.recommended_treatment_en,
        recommended_treatment_te=result.recommended_treatment_te,
    )
    try:
        db.add(diagnosis)
        db.commit()
    except Exception as exc:
        db.rollback()
        logger.error("Failed to save crop diagnosis record; exception_type=%s", type(exc).__name__)
        raise AgriVerseException(
            "The diagnosis record could not be saved.",
            status_code=503,
            error_code="DIAGNOSIS_PERSISTENCE_FAILED",
        )
    return result


@router.post("/diagnose-image", response_model=DiagnosisResponse)
@router.post("/diagnose", response_model=DiagnosisResponse, deprecated=True)
async def diagnose_crop_health(
    file: UploadFile = File(...),
    crop_name: str = Form(..., min_length=1, max_length=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return await process_diagnosis(file, crop_name, current_farmer, db)


@router.get("/history", response_model=List[DiagnosisResponse])
def get_diagnosis_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    records = (
        db.query(ImageDiagnosisDB)
        .filter(ImageDiagnosisDB.farmer_id == current_farmer.id)
        .order_by(ImageDiagnosisDB.diagnosed_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [
        DiagnosisResponse(
            id=item.id,
            farmer_id=item.farmer_id,
            crop_name=item.crop_name,
            detected_disease=item.detected_disease,
            severity=item.severity,
            confidence_score=None,
            recommended_treatment_en=item.recommended_treatment_en,
            recommended_treatment_te=item.recommended_treatment_te,
            inference_engine="YOLO",
            diagnosed_at=item.diagnosed_at,
            needs_expert_review=True,
        )
        for item in records
    ]
