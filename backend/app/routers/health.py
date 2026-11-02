from fastapi import APIRouter
from app.core.config import settings
from app.db.database import check_db_connection
from app.models.schemas import HealthCheckResponse
from app.services.disease_service import disease_model_configured

router = APIRouter(prefix="/health", tags=["Health & Diagnostics"])

@router.get("", response_model=HealthCheckResponse)
@router.get("/", response_model=HealthCheckResponse)
def get_system_health():
    """System health check endpoint verifying database connectivity and service state."""
    db_status = check_db_connection()
    status_str = "healthy" if db_status.get("status") == "connected" else "degraded"
    
    return HealthCheckResponse(
        status=status_str,
        app_name=settings.APP_NAME,
        environment=settings.ENVIRONMENT,
        version="1.0.0",
        database=db_status,
        mock_mode=False,
        dependencies={
            "weather_provider_configured": bool(settings.WEATHER_API_KEY),
            "assistant_provider_configured": bool(settings.GEMINI_AI_API_KEY),
            "disease_model_configured": disease_model_configured(),
        },
    )
