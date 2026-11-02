-- ====================================================================
-- AgriVerse AI - Master Relational Database Schema
-- Target Engine: PostgreSQL 15+ / Supabase
-- Description: Complete idempotent DDL script for all system entities
-- ====================================================================

-- 1. Enable Cryptographic & UUID Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Trigger Function for Updated Timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------
-- 3. Profiles Table (Farmer Accounts)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_auth_id UUID UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    village VARCHAR(100),
    district VARCHAR(100) NOT NULL DEFAULT 'Guntur',
    state VARCHAR(100) NOT NULL DEFAULT 'Andhra Pradesh',
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'en', -- 'en' or 'te'
    simple_mode_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Safely link to Supabase Auth if auth.users is present
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'auth' AND table_name = 'users'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_profiles_supabase_auth'
        ) THEN
            ALTER TABLE public.profiles
            ADD CONSTRAINT fk_profiles_supabase_auth 
            FOREIGN KEY (supabase_auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone_number);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_id ON public.profiles(supabase_auth_id);
CREATE INDEX IF NOT EXISTS idx_profiles_district ON public.profiles(district);

-- --------------------------------------------------------------------
-- 4. Farms Table (Agricultural Land Holdings)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    farm_name VARCHAR(120) NOT NULL,
    land_area_acres NUMERIC(6, 2) NOT NULL CHECK (land_area_acres > 0),
    soil_type VARCHAR(50) NOT NULL, -- 'Black Cotton', 'Red Sandy', 'Alluvial', 'Clay'
    irrigation_source VARCHAR(50) NOT NULL, -- 'Borewell', 'Canal', 'Rainfed', 'Drip'
    latitude NUMERIC(9, 6) CHECK (latitude BETWEEN -90.0 AND 90.0),
    longitude NUMERIC(9, 6) CHECK (longitude BETWEEN -180.0 AND 180.0),
    survey_number VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_farms_updated_at ON public.farms;
CREATE TRIGGER set_farms_updated_at
    BEFORE UPDATE ON public.farms
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_farms_farmer ON public.farms(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farms_soil_type ON public.farms(soil_type);

-- --------------------------------------------------------------------
-- 5. Crop Cycles Table (Sowing to Harvest Lifecycles)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    variety VARCHAR(100) NOT NULL DEFAULT 'Standard',
    sowing_date DATE NOT NULL,
    expected_harvest_date DATE,
    stage VARCHAR(50) NOT NULL DEFAULT 'Sowing', -- 'Sowing', 'Vegetative', 'Flowering', 'Harvesting', 'Completed'
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Completed', 'Abandoned'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_crop_cycles_updated_at ON public.crop_cycles;
CREATE TRIGGER set_crop_cycles_updated_at
    BEFORE UPDATE ON public.crop_cycles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_crop_cycles_farm ON public.crop_cycles(farm_id);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_status ON public.crop_cycles(status);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_stage ON public.crop_cycles(stage);

-- --------------------------------------------------------------------
-- 6. Farm Observations Table (Field Moisture and Pest Notes)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.farm_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crop_cycle_id UUID NOT NULL REFERENCES public.crop_cycles(id) ON DELETE CASCADE,
    observation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    soil_moisture_percentage NUMERIC(5, 2) CHECK (soil_moisture_percentage BETWEEN 0.0 AND 100.0),
    pest_symptoms TEXT,
    notes TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_farm_observations_updated_at ON public.farm_observations;
CREATE TRIGGER set_farm_observations_updated_at
    BEFORE UPDATE ON public.farm_observations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_farm_obs_cycle ON public.farm_observations(crop_cycle_id);
CREATE INDEX IF NOT EXISTS idx_farm_obs_date ON public.farm_observations(observation_date);

-- --------------------------------------------------------------------
-- 7. Crop Recommendations Table (Rule-Based & Intelligent Advisories)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Fertilizer', 'Pest Management', 'Irrigation', 'Crop Selection'
    recommendation_title VARCHAR(200) NOT NULL,
    details_en TEXT NOT NULL,
    details_te TEXT NOT NULL,
    confidence_score NUMERIC(3, 2) CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    is_actioned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_recommendations_farm ON public.crop_recommendations(farm_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_crop ON public.crop_recommendations(crop_name);
CREATE INDEX IF NOT EXISTS idx_recommendations_category ON public.crop_recommendations(category);

-- --------------------------------------------------------------------
-- 8. Weather Observations Table (Agro-Climatic Observations)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.weather_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district VARCHAR(100) NOT NULL,
    temperature_celsius NUMERIC(4, 1) NOT NULL,
    humidity_percentage NUMERIC(5, 2) NOT NULL CHECK (humidity_percentage BETWEEN 0.0 AND 100.0),
    rainfall_mm NUMERIC(6, 2) NOT NULL DEFAULT 0.0 CHECK (rainfall_mm >= 0.0),
    wind_speed_kmh NUMERIC(5, 2) CHECK (wind_speed_kmh >= 0.0),
    forecast_condition VARCHAR(100) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_weather_district ON public.weather_observations(district);
CREATE INDEX IF NOT EXISTS idx_weather_recorded ON public.weather_observations(recorded_at DESC);

-- --------------------------------------------------------------------
-- 9. Crop Health Diagnoses Table (Pathology Inference Records)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_health_diagnoses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    image_url TEXT,
    detected_disease VARCHAR(150) NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'Uncertain',
    recommended_treatment_en TEXT NOT NULL,
    recommended_treatment_te TEXT NOT NULL,
    diagnosed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_diagnoses_farmer ON public.crop_health_diagnoses(farmer_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_crop ON public.crop_health_diagnoses(crop_name);

-- --------------------------------------------------------------------
-- 10. Yield Estimates Table (Cultivation Economics and Profit Projections)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.yield_estimates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    crop_name VARCHAR(100),
    crop_cycle_id UUID REFERENCES public.crop_cycles(id) ON DELETE SET NULL,
    farm_id UUID REFERENCES public.farms(id) ON DELETE SET NULL,
    estimated_yield_quintals NUMERIC(8, 2) NOT NULL CHECK (estimated_yield_quintals >= 0.0),
    cost_of_cultivation_inr NUMERIC(10, 2) NOT NULL CHECK (cost_of_cultivation_inr >= 0.0),
    expected_market_price_per_quintal NUMERIC(8, 2) NOT NULL CHECK (expected_market_price_per_quintal >= 0.0),
    projected_revenue_inr NUMERIC(10, 2) NOT NULL,
    projected_net_profit_inr NUMERIC(10, 2) NOT NULL,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_yield_estimates_farm ON public.yield_estimates(farm_id);
CREATE INDEX IF NOT EXISTS idx_yield_estimates_cycle ON public.yield_estimates(crop_cycle_id);
CREATE INDEX IF NOT EXISTS idx_yield_estimates_farmer_time ON public.yield_estimates(farmer_id, calculated_at DESC);

-- --------------------------------------------------------------------
-- 11. Assistant Conversations Table (Bilingual Agricultural Sessions)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.assistant_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL DEFAULT 'AgriVerse Query',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_assistant_conversations_updated_at ON public.assistant_conversations;
CREATE TRIGGER set_assistant_conversations_updated_at
    BEFORE UPDATE ON public.assistant_conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_assistant_conv_farmer ON public.assistant_conversations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_assistant_conv_created ON public.assistant_conversations(created_at DESC);

-- --------------------------------------------------------------------
-- 12. Assistant Messages Table (Dialogue Messages)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.assistant_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.assistant_conversations(id) ON DELETE CASCADE,
    sender VARCHAR(20) NOT NULL CHECK (sender IN ('user', 'assistant')),
    content TEXT NOT NULL,
    language VARCHAR(10) NOT NULL DEFAULT 'en', -- 'en' or 'te'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_assistant_msg_conv ON public.assistant_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_assistant_msg_created ON public.assistant_messages(created_at ASC);

-- --------------------------------------------------------------------
-- 13. Backward-Compatibility Views
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW public.observations WITH (security_invoker = true) AS SELECT * FROM public.farm_observations;
CREATE OR REPLACE VIEW public.recommendations WITH (security_invoker = true) AS SELECT * FROM public.crop_recommendations;
CREATE OR REPLACE VIEW public.weather_records WITH (security_invoker = true) AS SELECT * FROM public.weather_observations;
CREATE OR REPLACE VIEW public.image_diagnosis_records WITH (security_invoker = true) AS SELECT * FROM public.crop_health_diagnoses;
