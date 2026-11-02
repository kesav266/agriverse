import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_farmer_registration_and_login_flow():
    """Test full cycle: registration, authentication, token issuance, and authenticated profile retrieval."""
    unique_phone = f"+9198{uuid.uuid4().int % 100000000:08d}"
    reg_payload = {
        "full_name": "Kishore Reddy (కిషోర్ రెడ్డి)",
        "phone_number": unique_phone,
        "password": "FarmPassword#2026",
        "village": "Mangalagiri",
        "district": "Guntur",
        "state": "Andhra Pradesh",
        "preferred_language": "te",
        "simple_mode_enabled": True
    }
    # 1. Register farmer
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    profile = reg_res.json()
    assert profile["full_name"] == "Kishore Reddy (కిషోర్ రెడ్డి)"
    assert profile["phone_number"] == unique_phone
    assert profile["preferred_language"] == "te"
    assert profile["simple_mode_enabled"] is True
    assert "id" in profile

    # 2. Duplicate registration should return 409 Conflict
    dup_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert dup_res.status_code == 409
    assert dup_res.json()["error_code"] == "DUPLICATE_RESOURCE"

    # 3. Login with wrong password should fail with 401
    wrong_login = client.post("/api/v1/auth/login", json={
        "phone_number": unique_phone,
        "password": "WrongPassword123"
    })
    assert wrong_login.status_code == 401

    # 4. Login with correct password should return valid JWT
    login_res = client.post("/api/v1/auth/login", json={
        "phone_number": unique_phone,
        "password": "FarmPassword#2026"
    })
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert "access_token" in login_data
    assert login_data["token_type"] == "bearer"
    token = login_data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 5. Access /auth/me without token should be rejected (401)
    unauth_me = client.get("/api/v1/auth/me")
    assert unauth_me.status_code == 401

    # 6. Access /auth/me with token should succeed
    auth_me = client.get("/api/v1/auth/me", headers=headers)
    assert auth_me.status_code == 200
    assert auth_me.json()["id"] == profile["id"]

    # 7. Access /farm-profiles/me and update language preferences
    prof_me = client.get("/api/v1/farm-profiles/me", headers=headers)
    assert prof_me.status_code == 200
    assert prof_me.json()["preferred_language"] == "te"

    update_res = client.put("/api/v1/farm-profiles/me", headers=headers, json={
        "preferred_language": "en",
        "simple_mode_enabled": False,
        "village": "Amaravati"
    })
    assert update_res.status_code == 200
    updated_data = update_res.json()
    assert updated_data["preferred_language"] == "en"
    assert updated_data["simple_mode_enabled"] is False
    assert updated_data["village"] == "Amaravati"

    # 8. Attempting to access another farmer's profile with our token should return 403 Forbidden
    other_id = str(uuid.uuid4())
    cross_access = client.get(f"/api/v1/farm-profiles/{other_id}", headers=headers)
    assert cross_access.status_code == 403

def test_invalid_phone_number_validation():
    """Verify that malformed phone numbers fail Pydantic validation."""
    bad_payload = {
        "full_name": "Test Farmer",
        "phone_number": "not-a-number",
        "password": "validpassword123"
    }
    response = client.post("/api/v1/auth/register", json=bad_payload)
    assert response.status_code == 422
    assert response.json()["error_code"] == "VALIDATION_ERROR"
