import uuid
from datetime import datetime, date, timezone
from sqlalchemy import Column, String, Float, Boolean, DateTime, Date, ForeignKey, Text, Numeric, CHAR
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID
from sqlalchemy.types import TypeDecorator
from sqlalchemy.orm import relationship
from app.db.database import Base


class GUID(TypeDecorator):
    """Use native PostgreSQL UUIDs while preserving existing dashed SQLite IDs."""
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PostgreSQLUUID(as_uuid=False))
        return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return str(value)

def generate_uuid() -> str:
    return str(uuid.uuid4())

class ProfileDB(Base):
    __tablename__ = "profiles"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    supabase_auth_id = Column(GUID(), unique=True, nullable=True)
    full_name = Column(String(120), nullable=False)
    phone_number = Column(String(15), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    village = Column(String(100), nullable=True)
    district = Column(String(100), nullable=False, default="Guntur")
    state = Column(String(100), nullable=False, default="Andhra Pradesh")
    preferred_language = Column(String(10), nullable=False, default="en")  # 'en' or 'te'
    simple_mode_enabled = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    farms = relationship("FarmDB", back_populates="farmer", cascade="all, delete-orphan")
    image_diagnoses = relationship("ImageDiagnosisDB", back_populates="farmer", cascade="all, delete-orphan")
    conversations = relationship("AssistantConversationDB", back_populates="farmer", cascade="all, delete-orphan")

class FarmDB(Base):
    __tablename__ = "farms"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farmer_id = Column(GUID(), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    farm_name = Column(String(120), nullable=False)
    land_area_acres = Column(Float, nullable=False)
    soil_type = Column(String(50), nullable=False)
    irrigation_source = Column(String(50), nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    survey_number = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    farmer = relationship("ProfileDB", back_populates="farms")
    crop_cycles = relationship("CropCycleDB", back_populates="farm", cascade="all, delete-orphan")
    recommendations = relationship("RecommendationDB", back_populates="farm", cascade="all, delete-orphan")
    yield_estimates = relationship("YieldEstimateDB", back_populates="farm", cascade="all, delete-orphan")

class CropCycleDB(Base):
    __tablename__ = "crop_cycles"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farm_id = Column(GUID(), ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    crop_name = Column(String(100), nullable=False)
    variety = Column(String(100), nullable=True, default="Standard")
    sowing_date = Column(Date, nullable=False)
    expected_harvest_date = Column(Date, nullable=True)
    stage = Column(String(50), nullable=False, default="Sowing")
    status = Column(String(20), nullable=False, default="Active")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    farm = relationship("FarmDB", back_populates="crop_cycles")
    observations = relationship("ObservationDB", back_populates="crop_cycle", cascade="all, delete-orphan")
    yield_estimates = relationship("YieldEstimateDB", back_populates="crop_cycle", cascade="all, delete-orphan")

class ObservationDB(Base):
    __tablename__ = "farm_observations"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    crop_cycle_id = Column(GUID(), ForeignKey("crop_cycles.id", ondelete="CASCADE"), nullable=False, index=True)
    observation_date = Column(Date, nullable=False, default=date.today)
    soil_moisture_percentage = Column(Float, nullable=True)
    pest_symptoms = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    crop_cycle = relationship("CropCycleDB", back_populates="observations")

class RecommendationDB(Base):
    __tablename__ = "crop_recommendations"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farm_id = Column(GUID(), ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    crop_name = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    recommendation_title = Column(String(200), nullable=False)
    details_en = Column(Text, nullable=False)
    details_te = Column(Text, nullable=False)
    confidence_score = Column(Float, nullable=True)
    is_actioned = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    farm = relationship("FarmDB", back_populates="recommendations")

class WeatherRecordDB(Base):
    __tablename__ = "weather_observations"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    district = Column(String(100), nullable=False, index=True)
    temperature_celsius = Column(Float, nullable=False)
    humidity_percentage = Column(Float, nullable=False)
    rainfall_mm = Column(Float, default=0.0)
    wind_speed_kmh = Column(Float, nullable=True)
    forecast_condition = Column(String(100), nullable=False)
    recorded_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

class ImageDiagnosisDB(Base):
    __tablename__ = "crop_health_diagnoses"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farmer_id = Column(GUID(), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    crop_name = Column(String(100), nullable=False)
    image_url = Column(Text, nullable=True)
    detected_disease = Column(String(150), nullable=False)
    severity = Column(String(50), nullable=False, default="Uncertain")
    recommended_treatment_en = Column(Text, nullable=False)
    recommended_treatment_te = Column(Text, nullable=False)
    diagnosed_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    farmer = relationship("ProfileDB", back_populates="image_diagnoses")

class YieldEstimateDB(Base):
    __tablename__ = "yield_estimates"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farmer_id = Column(GUID(), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True, index=True)
    crop_name = Column(String(100), nullable=True)
    crop_cycle_id = Column(GUID(), ForeignKey("crop_cycles.id", ondelete="SET NULL"), nullable=True, index=True)
    farm_id = Column(GUID(), ForeignKey("farms.id", ondelete="SET NULL"), nullable=True, index=True)
    estimated_yield_quintals = Column(Float, nullable=False)
    cost_of_cultivation_inr = Column(Float, nullable=False)
    expected_market_price_per_quintal = Column(Float, nullable=False)
    projected_revenue_inr = Column(Float, nullable=False)
    projected_net_profit_inr = Column(Float, nullable=False)
    calculated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    crop_cycle = relationship("CropCycleDB", back_populates="yield_estimates")
    farm = relationship("FarmDB", back_populates="yield_estimates")
    farmer = relationship("ProfileDB")

class AssistantConversationDB(Base):
    __tablename__ = "assistant_conversations"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    farmer_id = Column(GUID(), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(150), nullable=False, default="AgriVerse Query")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    farmer = relationship("ProfileDB", back_populates="conversations")
    messages = relationship("AssistantMessageDB", back_populates="conversation", cascade="all, delete-orphan")

class AssistantMessageDB(Base):
    __tablename__ = "assistant_messages"

    id = Column(GUID(), primary_key=True, default=generate_uuid)
    conversation_id = Column(GUID(), ForeignKey("assistant_conversations.id", ondelete="CASCADE"), nullable=False, index=True)
    sender = Column(String(20), nullable=False)
    content = Column(Text, nullable=False)
    language = Column(String(10), nullable=False, default="en")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    conversation = relationship("AssistantConversationDB", back_populates="messages")
