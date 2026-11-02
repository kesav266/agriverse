-- ====================================================================
-- AgriVerse AI Migration 008: Legacy Compatibility Views
-- Description: Provides aliases for legacy queries while standardizing tables
-- Repeatable and idempotent
-- ====================================================================

-- 1. Legacy view: observations -> farm_observations
CREATE OR REPLACE VIEW public.observations WITH (security_invoker = true) AS 
SELECT * FROM public.farm_observations;

-- 2. Legacy view: recommendations -> crop_recommendations
CREATE OR REPLACE VIEW public.recommendations WITH (security_invoker = true) AS 
SELECT * FROM public.crop_recommendations;

-- 3. Legacy view: weather_records -> weather_observations
CREATE OR REPLACE VIEW public.weather_records WITH (security_invoker = true) AS 
SELECT * FROM public.weather_observations;

-- 4. Legacy view: image_diagnosis_records -> crop_health_diagnoses
CREATE OR REPLACE VIEW public.image_diagnosis_records WITH (security_invoker = true) AS 
SELECT * FROM public.crop_health_diagnoses;
