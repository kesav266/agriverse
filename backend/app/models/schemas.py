from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict, ValidationInfo, field_validator, model_validator
from datetime import date, datetime, timezone
import re

# --------------------------------------------------------------------
# 0. Health Check Schemas
# --------------------------------------------------------------------
class HealthCheckResponse(BaseModel):
    status: str
    app_name: str
    environment: str
    version: str
    database: Dict[str, Any]
    mock_mode: bool
    dependencies: Dict[str, bool] = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

# --------------------------------------------------------------------
# 1. Auth & Farmer Profile Schemas
# --------------------------------------------------------------------
class ProfileCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=120)
    phone_number: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=12, max_length=72)
    village: Optional[str] = Field(None, max_length=100)
    district: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    preferred_language: str = Field("en", max_length=10) # 'en' or 'te'
    simple_mode_enabled: bool = False

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        clean = v.strip().replace(" ", "").replace("-", "")
        if not re.match(r"^\+?[0-9]{10,15}$", clean):
            raise ValueError("Phone number must contain between 10 and 15 numeric digits, optionally prefixed by +")
        return clean

    @field_validator("preferred_language")
    @classmethod
    def validate_language(cls, value: str) -> str:
        normalized = value.lower().strip()
        if normalized not in {"en", "te", "hi"}:
            raise ValueError("Language must be one of en, te, or hi")
        return normalized

    @field_validator("password")
    @classmethod
    def password_byte_limit(cls, value: str) -> str:
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Password must be at most 72 UTF-8 bytes")
        return value

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=120)
    village: Optional[str] = Field(None, max_length=100)
    district: Optional[str] = Field(None, min_length=2, max_length=100)
    state: Optional[str] = Field(None, min_length=2, max_length=100)
    preferred_language: Optional[str] = Field(None, max_length=10)
    simple_mode_enabled: Optional[bool] = None

    @field_validator("preferred_language")
    @classmethod
    def validate_preferred_language(cls, value: Optional[str]) -> Optional[str]:
        if value is not None and value.lower() not in {"en", "te", "hi"}:
            raise ValueError("Language must be one of en, te, or hi")
        return value.lower() if value is not None else None

class ProfileResponse(BaseModel):
    id: str
    full_name: str
    phone_number: str
    village: Optional[str] = None
    district: str
    state: str
    preferred_language: str
    simple_mode_enabled: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class LoginRequest(BaseModel):
    phone_number: str
    password: str = Field(..., min_length=1, max_length=72)

    @field_validator("phone_number")
    @classmethod
    def normalize_phone(cls, value: str) -> str:
        clean = value.strip().replace(" ", "").replace("-", "")
        if not re.match(r"^\+?[0-9]{10,15}$", clean):
            raise ValueError("Phone number must contain between 10 and 15 numeric digits")
        return clean

class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    profile: ProfileResponse

# --------------------------------------------------------------------
# 2. Farm Land Schemas
# --------------------------------------------------------------------
class FarmCreate(BaseModel):
    farmer_id: Optional[str] = None # Inferred from JWT if omitted
    farm_name: str = Field(..., min_length=2, max_length=120)
    land_area_acres: float = Field(..., gt=0.0)
    soil_type: str = Field(..., min_length=2, max_length=50) # Black Cotton, Red Sandy, Alluvial, Clay
    irrigation_source: str = Field(..., min_length=2, max_length=50) # Borewell, Canal, Rainfed, Drip
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    survey_number: Optional[str] = Field(None, max_length=50)

class FarmUpdate(BaseModel):
    farm_name: Optional[str] = Field(None, min_length=2, max_length=120)
    land_area_acres: Optional[float] = Field(None, gt=0.0)
    soil_type: Optional[str] = None
    irrigation_source: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    survey_number: Optional[str] = None

class FarmResponse(BaseModel):
    id: str
    farmer_id: str
    farm_name: str
    land_area_acres: float
    soil_type: str
    irrigation_source: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    survey_number: Optional[str] = None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------------------
# 3. Crop Cycle Schemas
# --------------------------------------------------------------------
class CropCycleCreate(BaseModel):
    farm_id: str
    crop_name: str = Field(..., min_length=2, max_length=100)
    variety: Optional[str] = "Standard"
    sowing_date: date
    expected_harvest_date: Optional[date] = None
    stage: str = Field("Sowing", max_length=50) # Sowing, Vegetative, Flowering, Harvesting, Completed

    @field_validator("crop_name", "stage")
    @classmethod
    def validate_crop_cycle_text(cls, value: str) -> str:
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise ValueError("Crop name and stage must contain at least two characters")
        return cleaned

    @model_validator(mode="after")
    def validate_harvest_date(self):
        if self.expected_harvest_date and self.expected_harvest_date < self.sowing_date:
            raise ValueError("Expected harvest date must be on or after the sowing date")
        return self

class CropCycleUpdate(BaseModel):
    crop_name: Optional[str] = Field(None, min_length=2, max_length=100)
    variety: Optional[str] = Field(None, max_length=100)
    sowing_date: Optional[date] = None
    stage: Optional[str] = Field(None, min_length=2, max_length=50)
    status: Optional[str] = Field(None, min_length=2, max_length=20)
    expected_harvest_date: Optional[date] = None

    @field_validator("crop_name", "variety", "stage", "status")
    @classmethod
    def validate_cycle_update_text(
        cls, value: Optional[str], info: ValidationInfo
    ) -> Optional[str]:
        if value is None:
            return None
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Crop-cycle text fields cannot be blank")
        if info.field_name in {"crop_name", "stage", "status"} and len(cleaned) < 2:
            raise ValueError("Crop-cycle text fields must contain at least two characters")
        return cleaned

class CropCycleResponse(BaseModel):
    id: str
    farm_id: str
    crop_name: str
    variety: Optional[str] = "Standard"
    sowing_date: date
    expected_harvest_date: Optional[date] = None
    stage: str
    status: str = "Active"
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class FarmObservationCreate(BaseModel):
    observation_date: date = Field(default_factory=date.today)
    soil_moisture_percentage: Optional[float] = Field(None, ge=0, le=100)
    pest_symptoms: Optional[str] = Field(None, max_length=2000)
    notes: Optional[str] = Field(None, max_length=4000)

class FarmObservationUpdate(BaseModel):
    observation_date: Optional[date] = None
    soil_moisture_percentage: Optional[float] = Field(None, ge=0, le=100)
    pest_symptoms: Optional[str] = Field(None, max_length=2000)
    notes: Optional[str] = Field(None, max_length=4000)

class FarmObservationResponse(BaseModel):
    id: str
    crop_cycle_id: str
    observation_date: date
    soil_moisture_percentage: Optional[float] = None
    pest_symptoms: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------------------
# 4. Crop Recommendation Schemas
# --------------------------------------------------------------------
class CropRecommendationRequest(BaseModel):
    farm_id: Optional[str] = None
    soil_type: str = Field(..., min_length=2, max_length=50)
    season: str = Field(..., pattern="^(?i:kharif|rabi|zaid)$")
    available_water: str = Field(..., pattern="^(?i:high|medium|low|rainfed)$")
    district: Optional[str] = Field(None, max_length=100)

class RecommendationFactor(BaseModel):
    factor_name: str
    observation: str
    suitability: str

class RecommendationItem(BaseModel):
    id: str
    farm_id: Optional[str] = None
    crop_name: str
    category: str # Crop Selection, Fertilizer, Pest Management, Irrigation
    recommendation_title: str
    details_en: str
    details_te: str
    confidence_score: Optional[float] = None
    methodology: str = "transparent_rules"
    reasoning_factors: Optional[List[RecommendationFactor]] = None
    is_actioned: bool = False

# --------------------------------------------------------------------
# 5. Weather & Irrigation Schemas
# --------------------------------------------------------------------
class WeatherResponse(BaseModel):
    district: str
    temperature_celsius: float
    humidity_percentage: Optional[float] = None
    rainfall_mm: Optional[float] = None
    wind_speed_kmh: Optional[float] = None
    forecast_condition: str
    advisory_en: str
    advisory_te: str
    data_source: str = "weather_provider"
    recorded_at: datetime
    forecast: List["WeatherForecastPoint"] = Field(default_factory=list)

class WeatherForecastPoint(BaseModel):
    timestamp: datetime
    temperature_celsius: float
    rainfall_mm: Optional[float] = None
    forecast_condition: str

class IrrigationScheduleRequest(BaseModel):
    farm_id: Optional[str] = None
    crop_name: str
    soil_moisture_percentage: float = Field(..., ge=0.0, le=100.0)
    last_irrigation_date: date

    @field_validator("last_irrigation_date")
    @classmethod
    def validate_last_irrigation_date(cls, value: date) -> date:
        if value > date.today():
            raise ValueError("Last irrigation date cannot be in the future")
        return value

class IrrigationScheduleResponse(BaseModel):
    recommendation: str
    next_assessment_date: date
    water_amount_liters_per_acre: Optional[float] = None
    advisory_en: str
    advisory_te: str
    missing_information: List[str] = Field(default_factory=list)

# --------------------------------------------------------------------
# 6. Crop Health & Diagnosis Schemas
# --------------------------------------------------------------------
class DiagnosisRequest(BaseModel):
    crop_name: str

class DiagnosisResponse(BaseModel):
    id: str
    farmer_id: Optional[str] = None
    crop_name: str
    detected_disease: str
    severity: str # Low, Moderate, High
    confidence_score: Optional[float] = None
    recommended_treatment_en: str
    recommended_treatment_te: str
    inference_engine: str = "configured_yolo_model"
    diagnosed_at: datetime
    needs_expert_review: bool = True

# --------------------------------------------------------------------
# 7. Finance & Yield Calculator Schemas
# --------------------------------------------------------------------
class YieldCalculationRequest(BaseModel):
    crop_name: str
    land_area_acres: float = Field(..., gt=0.0)
    expected_yield_quintals: float = Field(..., gt=0.0)
    market_price_per_quintal_inr: float = Field(..., ge=0.0)
    farm_id: Optional[str] = None
    crop_cycle_id: Optional[str] = None
    cost_of_seeds_inr: float = Field(0.0, ge=0.0)
    cost_of_fertilizers_inr: float = Field(0.0, ge=0.0)
    cost_of_labor_inr: float = Field(0.0, ge=0.0)
    cost_of_machinery_inr: float = Field(0.0, ge=0.0)

class YieldCalculationResponse(BaseModel):
    crop_name: str
    land_area_acres: float
    estimated_yield_quintals: float
    assumed_yield_rate_per_acre: float
    total_cost_of_cultivation_inr: float
    expected_market_price_per_quintal: float
    projected_total_revenue_inr: float
    projected_net_profit_inr: float
    roi_percentage: float
    assumptions_basis: str
    advisory_en: str
    advisory_te: str

# --------------------------------------------------------------------
# 8. AI Assistant Schemas
# --------------------------------------------------------------------
class AssistantQueryRequest(BaseModel):
    conversation_id: Optional[str] = None
    query: str = Field(..., min_length=1, max_length=2000)
    language: str = Field("en", pattern="^(en|te|hi)$")
    simple_mode: bool = False

class AssistantQueryResponse(BaseModel):
    conversation_id: str
    reply: str
    language: str
    reply_en: Optional[str] = None
    reply_te: Optional[str] = None
    suggested_actions: List[str] = Field(default_factory=list)
    retrieved_knowledge_sources: List[str] = Field(default_factory=list)
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class AssistantMessageResponse(BaseModel):
    id: str
    sender: str
    content: str
    language: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class AssistantConversationResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    messages: List[AssistantMessageResponse] = Field(default_factory=list)
    model_config = ConfigDict(from_attributes=True)

class YieldEstimateHistoryItem(BaseModel):
    id: str
    farm_id: Optional[str] = None
    crop_cycle_id: Optional[str] = None
    crop_name: Optional[str] = None
    estimated_yield_quintals: float
    cost_of_cultivation_inr: float
    expected_market_price_per_quintal: float
    projected_revenue_inr: float
    projected_net_profit_inr: float
    calculated_at: datetime
