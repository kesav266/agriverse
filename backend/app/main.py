from collections import defaultdict, deque
from contextlib import asynccontextmanager
import time
from threading import Lock

from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, UploadFile, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from starlette.middleware.trustedhost import TrustedHostMiddleware

from app.core.config import settings
from app.core.exceptions import AgriVerseException
from app.core.logging import logger
from app.services.disease_service import disease_model_configured, preload_disease_model
from app.core.security import get_current_farmer
from app.db.database import check_db_connection, engine, get_db, init_db
from app.models.domain import ProfileDB
from app.models.schemas import DiagnosisResponse, HealthCheckResponse
from app.routers import (
    assistant,
    auth,
    crop_cycles,
    farm_observations,
    crop_health,
    crop_recommendations,
    crops,
    farms,
    farm_assistant,
    farm_profiles,
    finance,
    health,
    irrigation,
    weather,
    yield_estimates,
)
from sqlalchemy.orm import Session


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    disease_model_loaded = preload_disease_model()
    logger.info("AgriVerse API started; database dialect=%s", engine.dialect.name)
    logger.info("Crop-disease model preloaded=%s", disease_model_loaded)
    yield
    logger.info("AgriVerse API stopped")


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="Community-oriented agricultural support APIs for farmers.",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$" if settings.ENVIRONMENT == "development" else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.TRUSTED_HOSTS)


@app.middleware("http")
async def request_limits_and_access_log(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > settings.MAX_REQUEST_BYTES:
                return JSONResponse(
                    status_code=413,
                    content={"error_code": "REQUEST_TOO_LARGE", "detail": "Request body exceeds the configured limit."},
                )
        except ValueError:
            return JSONResponse(
                status_code=400,
                content={"error_code": "INVALID_CONTENT_LENGTH", "detail": "Invalid request size."},
            )

    path = request.url.path
    budget = None
    if path.endswith("/farm-assistant/query") or path.endswith("/assistant/query"):
        budget = ("assistant", 10, 60)
    elif path.endswith("/crop-health/diagnose-image") or path.endswith("/crop-health/diagnose") or path.endswith("/health/diagnose"):
        budget = ("diagnosis", 20, 60)
    elif "/weather/" in path:
        budget = ("weather", 60, 60)
    if budget:
        client_ip = request.client.host if request.client else "unknown"
        category, maximum, period = budget
        key = (client_ip, category)
        now = time.monotonic()
        with _rate_lock:
            if len(_rate_windows) > 10_000:
                _rate_windows.clear()
            recent = _rate_windows[key]
            while recent and now - recent[0] >= period:
                recent.popleft()
            if len(recent) >= maximum:
                return JSONResponse(
                    status_code=429,
                    headers={"Retry-After": str(period)},
                    content={"error_code": "RATE_LIMITED", "detail": "Too many requests. Try again later."},
                )
            recent.append(now)

    started = time.monotonic()
    response = await call_next(request)
    logger.info(
        "http_request method=%s path=%s status=%s duration_ms=%.1f",
        request.method,
        path,
        response.status_code,
        (time.monotonic() - started) * 1000,
    )
    return response


_rate_windows = defaultdict(deque)
_rate_lock = Lock()


@app.exception_handler(AgriVerseException)
async def agriverse_exception_handler(request: Request, exc: AgriVerseException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error_code": exc.error_code,
            "detail": exc.detail,
            "details": exc.details,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = [
        {
            "field": " -> ".join(str(part) for part in error.get("loc", [])),
            "message": error.get("msg", "Invalid value"),
        }
        for error in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content={
            "error_code": "VALIDATION_ERROR",
            "detail": "Invalid request payload or parameters",
            "validation_errors": errors,
        },
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error_code": "HTTP_ERROR", "detail": exc.detail},
        headers=exc.headers,
    )


@app.exception_handler(SQLAlchemyError)
async def database_exception_handler(request: Request, exc: SQLAlchemyError):
    """Return a safe database error without exposing SQL or bound farmer data."""
    original = getattr(exc, "orig", None)
    sqlstate = getattr(original, "sqlstate", None)
    schema_missing = sqlstate == "42P01"
    logger.error(
        "Database API error method=%s path=%s exception_type=%s sqlstate=%s",
        request.method,
        request.url.path,
        type(exc).__name__,
        sqlstate,
    )
    return JSONResponse(
        status_code=503,
        content={
            "error_code": (
                "DATABASE_SCHEMA_NOT_INITIALIZED"
                if schema_missing
                else "DATABASE_UNAVAILABLE"
            ),
            "detail": (
                "The backend database schema is not initialized."
                if schema_missing
                else "The backend database is unavailable."
            ),
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(
        "Unhandled API error method=%s path=%s exception_type=%s",
        request.method,
        request.url.path,
        type(exc).__name__,
    )
    return JSONResponse(
        status_code=500,
        content={
            "error_code": "INTERNAL_SERVER_ERROR",
            "detail": "An internal server error occurred.",
        },
    )


def _health_payload(db_status: dict) -> HealthCheckResponse:
    return HealthCheckResponse(
        status="healthy" if db_status.get("status") == "connected" else "degraded",
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


@app.get("/", tags=["Health"])
@app.get("/health/live", tags=["Health"])
def liveness():
    return {"status": "alive", "app_name": settings.APP_NAME}


@app.get("/health", tags=["Health"], response_model=HealthCheckResponse)
def health_check():
    return _health_payload(check_db_connection())


@app.get("/health/ready", tags=["Health"], response_model=HealthCheckResponse)
def readiness():
    result = _health_payload(check_db_connection())
    if result.database.get("status") != "connected":
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database is not ready")
    return result


@app.post(
    f"{settings.API_V1_STR}/health/diagnose",
    tags=["Crop Health & Disease AI"],
    response_model=DiagnosisResponse,
    deprecated=True,
)
async def legacy_health_diagnose(
    file: UploadFile = File(...),
    crop_name: str = Form(..., min_length=1, max_length=100),
    current_farmer: ProfileDB = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return await crop_health.process_diagnosis(file, crop_name, current_farmer, db)


app.include_router(health.router, prefix=settings.API_V1_STR)
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(farm_profiles.router, prefix=settings.API_V1_STR)
app.include_router(farms.router, prefix=settings.API_V1_STR)
app.include_router(crop_cycles.router, prefix=settings.API_V1_STR)
app.include_router(farm_observations.router, prefix=settings.API_V1_STR)
app.include_router(crop_recommendations.router, prefix=settings.API_V1_STR)
app.include_router(weather.router, prefix=settings.API_V1_STR)
app.include_router(irrigation.router, prefix=settings.API_V1_STR)
app.include_router(crop_health.router, prefix=settings.API_V1_STR)
app.include_router(yield_estimates.router, prefix=settings.API_V1_STR)
app.include_router(farm_assistant.router, prefix=settings.API_V1_STR)

# Existing compatibility paths remain protected and use the real service.
app.include_router(crops.router, prefix=settings.API_V1_STR)
app.include_router(finance.router, prefix=settings.API_V1_STR)
app.include_router(assistant.router, prefix=settings.API_V1_STR)
