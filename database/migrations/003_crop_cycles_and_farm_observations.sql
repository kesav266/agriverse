-- ====================================================================
-- AgriVerse AI Migration 003: Crop Cycles and Farm Observations
-- Description: Crop lifecycle tracking and field soil/pest observations
-- Repeatable and idempotent
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Crop Cycles Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL, -- e.g. 'Paddy (Rice)', 'Red Chilli', 'Cotton'
    variety VARCHAR(100) NOT NULL DEFAULT 'Standard',
    sowing_date DATE NOT NULL,
    expected_harvest_date DATE,
    stage VARCHAR(50) NOT NULL DEFAULT 'Sowing', -- 'Sowing', 'Vegetative', 'Flowering', 'Harvesting', 'Completed'
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Completed', 'Abandoned'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Crop Cycles updated_at Trigger
DROP TRIGGER IF EXISTS set_crop_cycles_updated_at ON public.crop_cycles;
CREATE TRIGGER set_crop_cycles_updated_at
    BEFORE UPDATE ON public.crop_cycles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Crop Cycles Indexes
CREATE INDEX IF NOT EXISTS idx_crop_cycles_farm ON public.crop_cycles(farm_id);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_status ON public.crop_cycles(status);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_stage ON public.crop_cycles(stage);

-- --------------------------------------------------------------------
-- 2. Farm Observations Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.farm_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crop_cycle_id UUID NOT NULL REFERENCES public.crop_cycles(id) ON DELETE CASCADE,
    observation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    soil_moisture_percentage NUMERIC(5, 2) CHECK (soil_moisture_percentage BETWEEN 0.0 AND 100.0),
    pest_symptoms TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Farm Observations Indexes
CREATE INDEX IF NOT EXISTS idx_farm_obs_cycle ON public.farm_observations(crop_cycle_id);
CREATE INDEX IF NOT EXISTS idx_farm_obs_date ON public.farm_observations(observation_date);
