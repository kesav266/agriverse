-- ====================================================================
-- AgriVerse AI Migration 004: Crop Recommendations and Weather Observations
-- Description: Expert rule/AI recommendations and agro-climatic observations
-- Repeatable and idempotent
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Crop Recommendations Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Fertilizer', 'Pest Management', 'Irrigation', 'Crop Selection'
    recommendation_title VARCHAR(200) NOT NULL,
    details_en TEXT NOT NULL,
    details_te TEXT NOT NULL,
    confidence_score NUMERIC(3, 2) DEFAULT 0.95 CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    is_actioned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Crop Recommendations Indexes
CREATE INDEX IF NOT EXISTS idx_recommendations_farm ON public.crop_recommendations(farm_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_crop ON public.crop_recommendations(crop_name);
CREATE INDEX IF NOT EXISTS idx_recommendations_category ON public.crop_recommendations(category);

-- --------------------------------------------------------------------
-- 2. Weather Observations Table
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

-- Weather Observations Indexes
CREATE INDEX IF NOT EXISTS idx_weather_district ON public.weather_observations(district);
CREATE INDEX IF NOT EXISTS idx_weather_recorded ON public.weather_observations(recorded_at DESC);
