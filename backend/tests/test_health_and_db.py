import pytest
from pydantic import ValidationError

from app.core.config import Settings
from app.db.database import check_db_connection


def test_database_connection_uses_isolated_sqlite_for_tests():
    result = check_db_connection()
    assert result["status"] == "connected"
    assert result["dialect"] == "sqlite"
    assert result["latency_ms"] >= 0


def test_health_reports_configuration_without_exposing_credentials(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["environment"] == "testing"
    assert data["mock_mode"] is False
    assert data["dependencies"]["weather_provider_configured"] is False
    assert "SECRET_KEY" not in response.text


def test_openapi_documentation_is_available(client):
    response = client.get("/api/v1/openapi.json")
    assert response.status_code == 200
    assert "/api/v1/yield-estimates/calculate" in response.json()["paths"]


def test_production_configuration_requires_https_origins_and_public_api_hosts():
    common_settings = {
        "ENVIRONMENT": "production",
        "SECRET_KEY": "x" * 32,
        "DATABASE_URL": "postgresql://user:password@db.example.com:5432/agriverse",
    }

    with pytest.raises(ValidationError, match="HTTPS"):
        Settings(
            **common_settings,
            CORS_ORIGINS=["http://app.example.com"],
            TRUSTED_HOSTS=["api.example.com"],
        )

    with pytest.raises(ValidationError, match="local development"):
        Settings(
            **common_settings,
            CORS_ORIGINS=["https://app.example.com"],
            TRUSTED_HOSTS=["localhost"],
        )


def test_production_configuration_accepts_exact_public_origins_and_hosts():
    settings = Settings(
        ENVIRONMENT="production",
        SECRET_KEY="x" * 32,
        DATABASE_URL="postgresql://user:password@db.example.com:5432/agriverse",
        CORS_ORIGINS=["https://app.example.com"],
        TRUSTED_HOSTS=["api.example.com"],
    )

    assert settings.CORS_ORIGINS == ["https://app.example.com"]
    assert settings.TRUSTED_HOSTS == ["api.example.com"]
import logging


def test_provider_credentials_are_redacted_from_request_logs():
    from app.core.logging import ProviderSecretRedactionFilter

    record = logging.LogRecord(
        name="httpx",
        level=logging.INFO,
        pathname="provider.py",
        lineno=1,
        msg="HTTP Request: GET https://provider.test/weather?appid=provider-secret&limit=1 401",
        args=(),
        exc_info=None,
    )

    assert ProviderSecretRedactionFilter().filter(record)
    message = record.getMessage()
    assert "provider-secret" not in message
    assert "appid=[REDACTED]" in message
