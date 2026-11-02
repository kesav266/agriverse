from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_farmer
from app.db.database import get_db
from app.models.domain import AssistantConversationDB, AssistantMessageDB, ProfileDB
from app.models.schemas import (
    AssistantConversationResponse,
    AssistantQueryRequest,
    AssistantQueryResponse,
)
from app.services.assistant_service import AssistantService

router = APIRouter(prefix="/farm-assistant", tags=["Farming Assistant"])


@router.post("", response_model=AssistantQueryResponse)
@router.post("/", response_model=AssistantQueryResponse)
@router.post("/query", response_model=AssistantQueryResponse)
def query_farm_assistant(
    request: AssistantQueryRequest,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return AssistantService.query(db, current_farmer, request)


@router.get("/conversations", response_model=List[AssistantConversationResponse])
def list_conversations(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=50),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    conversations = (
        db.query(AssistantConversationDB)
        .filter(AssistantConversationDB.farmer_id == current_farmer.id)
        .order_by(AssistantConversationDB.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [
        AssistantConversationResponse(
            id=item.id,
            title=item.title,
            created_at=item.created_at,
            messages=[],
        )
        for item in conversations
    ]


@router.get("/conversations/{conversation_id}", response_model=AssistantConversationResponse)
def get_conversation(
    conversation_id: str,
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    conversation = (
        db.query(AssistantConversationDB)
        .filter(
            AssistantConversationDB.id == conversation_id,
            AssistantConversationDB.farmer_id == current_farmer.id,
        )
        .first()
    )
    if conversation is None:
        from app.core.exceptions import AgriVerseException
        raise AgriVerseException(
            "Conversation not found.", status_code=404, error_code="CONVERSATION_NOT_FOUND"
        )
    messages = (
        db.query(AssistantMessageDB)
        .filter(AssistantMessageDB.conversation_id == conversation.id)
        .order_by(AssistantMessageDB.created_at.asc(), AssistantMessageDB.id.asc())
        .all()
    )
    return AssistantConversationResponse(
        id=conversation.id,
        title=conversation.title,
        created_at=conversation.created_at,
        messages=messages,
    )
