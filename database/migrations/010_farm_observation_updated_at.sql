-- AgriVerse AI Migration 010
-- Track modifications to farmer-editable field observations.
-- Additive only; existing rows receive the migration time as their initial updated_at.

BEGIN;

ALTER TABLE public.farm_observations
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL
    DEFAULT timezone('utc'::text, now());

DROP TRIGGER IF EXISTS set_farm_observations_updated_at ON public.farm_observations;
CREATE TRIGGER set_farm_observations_updated_at
    BEFORE UPDATE ON public.farm_observations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

COMMIT;
