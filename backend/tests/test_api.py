import asyncio
from datetime import datetime, timezone
from types import SimpleNamespace

from PIL import Image
import io

from app.core.config import settings
from app.services.weather_service import WeatherService


def test_health_and_readiness_are_separate(client):
    assert client.get("/health/live").json()["status"] == "alive"
    ready = client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json()["database"]["status"] == "connected"
    assert ready.json()["dependencies"] == {
        "weather_provider_configured": False,
        "assistant_provider_configured": False,
        "disease_model_configured": False,
    }


def test_password_auth_and_profile_access(client, register_farmer):
    profile, headers, phone, password = register_farmer()
    assert client.get("/api/v1/auth/me").status_code == 401
    assert client.get("/api/v1/auth/me", headers=headers).json()["id"] == profile["id"]
    assert client.post("/api/v1/auth/login", json={"phone_number": phone, "password": "incorrect"}).status_code == 401
    assert client.post("/api/v1/auth/login", json={"phone_number": phone, "otp": "123456"}).status_code == 422

    update = client.put("/api/v1/farm-profiles/me", headers=headers, json={
        "preferred_language": "hi", "simple_mode_enabled": True, "village": "Updated village"
    })
    assert update.status_code == 200
    assert update.json()["preferred_language"] == "hi"
    assert update.json()["village"] == "Updated village"


def test_rule_recommendations_are_transparent_and_do_not_claim_scores(client, register_farmer):
    _, headers, _, _ = register_farmer("Recommendation Farmer")
    response = client.post("/api/v1/crop-recommendations/evaluate", headers=headers, json={
        "soil_type": "Black soil", "season": "Kharif", "available_water": "high"
    })
    assert response.status_code == 200
    recommendations = response.json()
    assert any(item["crop_name"] == "Paddy (Rice)" for item in recommendations)
    assert all(item["methodology"] == "transparent_rules" for item in recommendations)
    assert all(item["confidence_score"] is None for item in recommendations)
    assert "not include soil tests" in recommendations[0]["details_en"]
    invalid = client.post("/api/v1/crop-recommendations/evaluate", headers=headers, json={
        "soil_type": "Black soil", "season": "Monsoon", "available_water": "high"
    })
    assert invalid.status_code == 422


def test_weather_provider_mapping_and_missing_key(monkeypatch):
    async def fake_get_json(cls, client, path, params):
        if path == "/geo/1.0/direct":
            return [{"name": "Guntur", "lat": 16.3, "lon": 80.4}]
        if path == "/data/2.5/weather":
            return {
                "main": {"temp": 31.25, "humidity": 61},
                "weather": [{"description": "clear sky"}],
                "dt": 1_793_520_000,
                "wind": {"speed": 2.0},
                "rain": {"1h": 0.4},
            }
        return {"list": [{
            "dt": 1_793_530_800,
            "main": {"temp": 30.0},
            "weather": [{"description": "light rain"}],
            "rain": {"3h": 1.2},
        }]}

    monkeypatch.setattr(settings, "WEATHER_API_KEY", "test-provider-key")
    monkeypatch.setattr(WeatherService, "_get_json", classmethod(fake_get_json))
    result = asyncio.run(WeatherService.get_weather_forecast("Guntur"))
    assert result.temperature_celsius == 31.25
    assert result.rainfall_mm == 0.4
    assert result.wind_speed_kmh == 7.2
    assert result.forecast[0].rainfall_mm == 1.2
    assert "OpenWeather" in result.data_source

    monkeypatch.setattr(settings, "WEATHER_API_KEY", "")
    try:
        asyncio.run(WeatherService.get_weather_forecast("Guntur"))
    except Exception as error:
        assert getattr(error, "error_code", None) == "WEATHER_NOT_CONFIGURED"
    else:
        raise AssertionError("missing weather key must not return synthetic data")


def test_weather_api_failure_is_sanitized(client):
    response = client.get("/api/v1/weather/Guntur")
    assert response.status_code == 503
    assert response.json()["error_code"] == "WEATHER_NOT_CONFIGURED"


def test_yield_estimate_persists_and_history_is_private(client, register_farmer):
    profile, headers, _, _ = register_farmer("Yield Farmer")
    payload = {
        "crop_name": "Paddy",
        "land_area_acres": 2,
        "expected_yield_quintals": 30,
        "market_price_per_quintal_inr": 2100,
        "cost_of_seeds_inr": 1000,
        "cost_of_fertilizers_inr": 2000,
        "cost_of_labor_inr": 3000,
        "cost_of_machinery_inr": 500,
    }
    result = client.post("/api/v1/yield-estimates/calculate", headers=headers, json=payload)
    assert result.status_code == 200, result.text
    data = result.json()
    assert data["projected_total_revenue_inr"] == 63000
    assert data["total_cost_of_cultivation_inr"] == 6500
    assert data["projected_net_profit_inr"] == 56500
    assert "farmer-entered" in data["assumptions_basis"]
    history = client.get("/api/v1/yield-estimates/history", headers=headers)
    assert history.status_code == 200
    assert history.json()[0]["crop_name"] == "Paddy"
    other_profile, other_headers, _, _ = register_farmer("Other Farmer")
    assert other_profile["id"] != profile["id"]
    assert client.get("/api/v1/yield-estimates/history", headers=other_headers).json() == []
    assert client.post("/api/v1/yield-estimates/calculate", json=payload).status_code == 401


def test_irrigation_requires_auth_and_returns_no_exact_water_amount(client, register_farmer):
    payload = {
        "crop_name": "Paddy",
        "soil_moisture_percentage": 43,
        "last_irrigation_date": datetime.now(timezone.utc).date().isoformat(),
    }
    assert client.post("/api/v1/irrigation/schedule", json=payload).status_code == 401
    _, headers, _, _ = register_farmer("Irrigation Farmer")
    response = client.post("/api/v1/irrigation/schedule", headers=headers, json=payload)
    assert response.status_code == 200
    assert response.json()["water_amount_liters_per_acre"] is None
    assert response.json()["recommendation"] == "Field assessment required"


def test_crop_diagnosis_never_guesses_when_model_is_missing(client, register_farmer):
    _, headers, _, _ = register_farmer("Diagnosis Farmer")
    image = io.BytesIO()
    Image.new("RGB", (64, 64), color="green").save(image, format="PNG")
    response = client.post(
        "/api/v1/crop-health/diagnose-image",
        headers=headers,
        data={"crop_name": "Paddy"},
        files={"file": ("leaf.png", image.getvalue(), "image/png")},
    )
    assert response.status_code == 503
    assert response.json()["error_code"] == "DISEASE_MODEL_NOT_CONFIGURED"
    malformed = client.post(
        "/api/v1/crop-health/diagnose-image",
        headers=headers,
        data={"crop_name": "Paddy"},
        files={"file": ("leaf.png", b"not an image", "image/png")},
    )
    assert malformed.status_code == 415


def test_crop_diagnosis_uses_mocked_model_only_in_test_and_saves_result(
    client, register_farmer, monkeypatch, tmp_path
):
    from app.services import disease_service

    _, headers, _, _ = register_farmer("Mock Diagnosis Farmer")
    model_path = tmp_path / "test-model.pt"
    model_path.write_bytes(b"test fixture only")
    monkeypatch.setattr(settings, "DISEASE_MODEL_PATH", str(model_path))
    monkeypatch.setattr(settings, "DISEASE_MODEL_CONFIDENCE", 0.5)
    monkeypatch.setattr(settings, "DISEASE_ALLOWED_LABELS", ["Test class from mock model"])

    class TensorLike:
        def __init__(self, values):
            self.values = values

        def detach(self): return self
        def cpu(self): return self
        def tolist(self): return self.values

    class Boxes:
        conf = TensorLike([0.88])
        cls = TensorLike([0])

        def __len__(self): return 1

    class Prediction:
        boxes = Boxes()
        names = {0: "Test class from mock model"}

    class MockModel:
        def predict(self, **kwargs):
            assert kwargs["verbose"] is False
            return [Prediction()]

    monkeypatch.setattr(disease_service, "_load_model", lambda path: MockModel())
    image = io.BytesIO()
    Image.new("RGB", (64, 64), color="green").save(image, format="PNG")
    response = client.post(
        "/api/v1/crop-health/diagnose-image",
        headers=headers,
        data={"crop_name": "Paddy"},
        files={"file": ("leaf.png", image.getvalue(), "image/png")},
    )
    assert response.status_code == 200, response.text
    assert response.json()["detected_disease"] == "Test class from mock model"
    assert response.json()["confidence_score"] == 0.88
    history = client.get("/api/v1/crop-health/history", headers=headers)
    assert history.status_code == 200
    assert history.json()[0]["detected_disease"] == "Test class from mock model"


def test_assistant_requires_provider_and_conversation_owner(client, register_farmer):
    _, headers, _, _ = register_farmer("Assistant Farmer")
    query = {"query": "How can I check soil moisture?", "language": "en"}
    response = client.post("/api/v1/farm-assistant/query", headers=headers, json=query)
    assert response.status_code == 503
    assert response.json()["error_code"] == "ASSISTANT_NOT_CONFIGURED"
    assert client.get("/api/v1/farm-assistant/conversations").status_code == 401


def test_assistant_persists_provider_reply_and_checks_conversation_owner(
    client, register_farmer, monkeypatch
):
    from app.services import assistant_service

    profile, headers, _, _ = register_farmer("Persisted Assistant Farmer")
    other, other_headers, _, _ = register_farmer("Other Assistant Farmer")
    monkeypatch.setattr(settings, "GEMINI_AI_API_KEY", "test-provider-key")
    monkeypatch.setattr(settings, "GEMINI_MODEL", "test-model")

    class MockResponse:
        status_code = 200

        @staticmethod
        def json():
            return {
                "status": "completed",
                "steps": [{"type": "model_output", "content": [{"type": "text", "text": "Check moisture at the active root depth."}]}],
            }

    def fake_post(url, **kwargs):
        assert url.endswith("/v1/interactions")
        assert kwargs["headers"]["x-goog-api-key"] == "test-provider-key"
        assert kwargs["json"]["store"] is False
        assert "temperature" not in kwargs["json"]["generation_config"]
        return MockResponse()

    monkeypatch.setattr(assistant_service.httpx, "post", fake_post)
    response = client.post("/api/v1/farm-assistant/query", headers=headers, json={
        "query": "How should I check field moisture?", "language": "en"
    })
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["reply"] == "Check moisture at the active root depth."
    conversation_id = body["conversation_id"]

    detail = client.get(f"/api/v1/farm-assistant/conversations/{conversation_id}", headers=headers)
    assert detail.status_code == 200
    assert [message["sender"] for message in detail.json()["messages"]] == ["user", "assistant"]
    assert client.get(f"/api/v1/farm-assistant/conversations/{conversation_id}", headers=other_headers).status_code == 404
    assert profile["id"] != other["id"]


def test_assistant_provider_errors_have_safe_diagnostics(client, register_farmer, monkeypatch):
    from app.services import assistant_service

    _, headers, _, _ = register_farmer("Assistant Diagnostics Farmer")
    monkeypatch.setattr(settings, "GEMINI_AI_API_KEY", "test-provider-key")
    cases = [
        (400, {"error": {"message": "API key not valid."}}, "ASSISTANT_PROVIDER_AUTH_FAILED"),
        (404, {"error": {"message": "The requested model was not found."}}, "ASSISTANT_MODEL_UNAVAILABLE"),
        (429, {"error": {"message": "Rate limit exceeded."}}, "ASSISTANT_RATE_LIMITED"),
    ]

    for status_code, payload, error_code in cases:
        class MockResponse:
            def __init__(self, code, body):
                self.status_code = code
                self._body = body

            def json(self):
                return self._body

        monkeypatch.setattr(
            assistant_service.httpx,
            "post",
            lambda *_args, _code=status_code, _body=payload, **_kwargs: MockResponse(_code, _body),
        )
        response = client.post(
            "/api/v1/farm-assistant/query",
            headers=headers,
            json={"query": "How should I check the crop?", "language": "en"},
        )
        assert response.status_code == 503
        assert response.json()["error_code"] == error_code
        assert "API key not valid" not in response.text
