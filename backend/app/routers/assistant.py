from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import ProfileDB
from app.models.schemas import AssistantQueryRequest, AssistantQueryResponse
from app.services.assistant_service import AssistantService

router = APIRouter(prefix="/assistant", tags=["AI Farming Assistant (Legacy)"])

@router.post("/query", response_model=AssistantQueryResponse)
def query_ai_assistant(
    req: AssistantQueryRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    """Interact with AgriVerse AI multilingual farming assistant (Flutter compatibility)."""
    return AssistantService.query(db, current_farmer, req)
