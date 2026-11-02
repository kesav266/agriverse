"""Test configuration uses an isolated in-memory database and fake provider credentials."""
import os
import uuid

os.environ["ENVIRONMENT"] = "testing"
os.environ["DEBUG"] = "false"
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["SECRET_KEY"] = "test-only-secret-key-not-for-deployment-123456789"
os.environ["WEATHER_API_KEY"] = ""
os.environ["GEMINI_AI_API_KEY"] = ""
os.environ["DISEASE_MODEL_PATH"] = ""

import pytest
from fastapi.testclient import TestClient


@pytest.fixture(autouse=True)
def initialize_isolated_database():
    from app.db.database import init_db

    init_db()


@pytest.fixture
def client():
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def register_farmer(client):
    def create_farmer(name: str = "Test Farmer"):
        phone = f"+919{uuid.uuid4().int % 1_000_000_000:09d}"
        password = "FarmPassword#2026"
        response = client.post(
            "/api/v1/auth/register",
            json={
                "full_name": name,
                "phone_number": phone,
                "password": password,
                "village": "Test village",
                "district": "Guntur",
                "state": "Andhra Pradesh",
                "preferred_language": "en",
            },
        )
        assert response.status_code == 201, response.text
        profile = response.json()
        login = client.post(
            "/api/v1/auth/login",
            json={"phone_number": phone, "password": password},
        )
        assert login.status_code == 200, login.text
        return profile, {"Authorization": f"Bearer {login.json()['access_token']}"}, phone, password

    return create_farmer
