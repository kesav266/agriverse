import secrets
from typing import List, Optional

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "AgriVerse AI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"

    # A local development key is generated for this process when none is set.
    # Production requires a stable, operator-supplied key.
    SECRET_KEY: str = Field(default="", repr=False)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60, ge=5, le=1440)

    DATABASE_URL: Optional[str] = None
    SUPABASE_URL: Optional[str] = None
    SUPABASE_KEY: Optional[str] = Field(default=None, repr=False)
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = Field(default=None, repr=False)

    # Provider credentials stay on the backend. Empty values disable the provider.
    USE_MOCK_PROVIDERS: bool = False  # Retained for .env compatibility; never enables fake responses.
    WEATHER_API_KEY: Optional[str] = Field(default=None, repr=False)
    WEATHER_REQUEST_TIMEOUT_SECONDS: float = Field(default=8.0, ge=1.0, le=30.0)
    GEMINI_AI_API_KEY: Optional[str] = Field(default=None, repr=False)
    GEMINI_MODEL: str = "gemini-3.8-flash"
    GEMINI_REQUEST_TIMEOUT_SECONDS: float = Field(default=20.0, ge=2.0, le=60.0)

    DISEASE_MODEL_PATH: Optional[str] = None
    DISEASE_MODEL_CONFIDENCE: float = Field(default=0.45, ge=0.0, le=1.0)
    DISEASE_ALLOWED_LABELS: List[str] = Field(default_factory=list)
    MAX_UPLOAD_BYTES: int = Field(default=8 * 1024 * 1024, ge=1024, le=25 * 1024 * 1024)
    MAX_REQUEST_BYTES: int = Field(default=10 * 1024 * 1024, ge=1024, le=30 * 1024 * 1024)

    CORS_ORIGINS: List[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]
    TRUSTED_HOSTS: List[str] = ["localhost", "127.0.0.1", "testserver"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    @field_validator("DEBUG", mode="before")
    @classmethod
    def parse_debug(cls, value):
        # Some launch environments use DEBUG=release/debug as a build-mode label.
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized in {"release", "production", "prod", "false", "0", "no", "off", ""}:
                return False
            if normalized in {"debug", "development", "true", "1", "yes", "on"}:
                return True
        return value

    @model_validator(mode="after")
    def validate_runtime_security(self):
        environment = self.ENVIRONMENT.strip().lower()
        production = environment in {"prod", "production", "staging"}
        if not self.SECRET_KEY:
            if production:
                raise ValueError("SECRET_KEY must be configured for production")
            self.SECRET_KEY = secrets.token_urlsafe(48)

        if production:
            if len(self.SECRET_KEY.encode("utf-8")) < 32:
                raise ValueError("Production SECRET_KEY must contain at least 32 bytes")
            if "replace-with" in self.SECRET_KEY.lower() or "change-me" in self.SECRET_KEY.lower():
                raise ValueError("Production SECRET_KEY must not be a placeholder")
            if self.DEBUG:
                raise ValueError("DEBUG must be false in production")
            if not self.CORS_ORIGINS or "*" in self.CORS_ORIGINS:
                raise ValueError("Production CORS_ORIGINS must contain exact HTTPS frontend origins")
            if any(not origin.startswith("https://") for origin in self.CORS_ORIGINS):
                raise ValueError("Production CORS_ORIGINS must use HTTPS origins only")
            if not self.TRUSTED_HOSTS or "*" in self.TRUSTED_HOSTS:
                raise ValueError("Production TRUSTED_HOSTS must contain exact API hostnames")
            if any(host in {"localhost", "127.0.0.1"} for host in self.TRUSTED_HOSTS):
                raise ValueError("Production TRUSTED_HOSTS must not contain local development hosts")
            if not self.DATABASE_URL or not self.DATABASE_URL.strip().startswith(("postgres://", "postgresql://", "postgresql+psycopg://", "postgresql+psycopg2://")):
                raise ValueError("Production DATABASE_URL must point to PostgreSQL")
        return self

    @property
    def effective_database_url(self) -> str:
        """Configured PostgreSQL/Supabase URL or a local SQLite development database."""
        if self.DATABASE_URL and self.DATABASE_URL.strip():
            url = self.DATABASE_URL.strip()
            if url.startswith("postgres://"):
                return url.replace("postgres://", "postgresql+psycopg://", 1)
            if url.startswith("postgresql://"):
                return url.replace("postgresql://", "postgresql+psycopg://", 1)
            return url
        return "sqlite:///./agriverse.db"


settings = Settings()
