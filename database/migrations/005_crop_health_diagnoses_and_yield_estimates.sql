-- ====================================================================
-- AgriVerse AI Migration 005: Crop Health Diagnoses and Yield Estimates
-- Description: Pathology diagnosis history and economic yield forecasts
-- Repeatable and idempotent
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Crop Health Diagnoses Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_health_diagnoses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    image_url TEXT,
    detected_disease VARCHAR(150) NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'Moderate', -- 'Low', 'Moderate', 'High'
    recommended_treatment_en TEXT NOT NULL,
    recommended_treatment_te TEXT NOT NULL,
    diagnosed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Crop Health Diagnoses Indexes
CREATE INDEX IF NOT EXISTS idx_diagnoses_farmer ON public.crop_health_diagnoses(farmer_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_crop ON public.crop_health_diagnoses(crop_name);

-- --------------------------------------------------------------------
-- 2. Yield Estimates Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.yield_estimates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crop_cycle_id UUID REFERENCES public.crop_cycles(id) ON DELETE SET NULL,
    farm_id UUID REFERENCES public.farms(id) ON DELETE SET NULL,
    estimated_yield_quintals NUMERIC(8, 2) NOT NULL CHECK (estimated_yield_quintals >= 0.0),
    cost_of_cultivation_inr NUMERIC(10, 2) NOT NULL CHECK (cost_of_cultivation_inr >= 0.0),
    expected_market_price_per_quintal NUMERIC(8, 2) NOT NULL CHECK (expected_market_price_per_quintal >= 0.0),
    projected_revenue_inr NUMERIC(10, 2) NOT NULL,
    projected_net_profit_inr NUMERIC(10, 2) NOT NULL,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Yield Estimates Indexes
CREATE INDEX IF NOT EXISTS idx_yield_estimates_farm ON public.yield_estimates(farm_id);
CREATE INDEX IF NOT EXISTS idx_yield_estimates_cycle ON public.yield_estimates(crop_cycle_id);
