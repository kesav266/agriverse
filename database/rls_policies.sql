-- ====================================================================
-- AgriVerse AI Migration 007: Row Level Security (RLS) & Role Protection
-- Description: Enforces multi-tenant farmer data isolation & admin safeguards
-- Repeatable and idempotent
-- ====================================================================

BEGIN;

-- Add ownership for yield records before installing policies. Existing rows are
-- linked only where their farm or crop-cycle ownership is known.
ALTER TABLE public.yield_estimates
    ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.yield_estimates ADD COLUMN IF NOT EXISTS crop_name VARCHAR(100);
UPDATE public.yield_estimates AS estimate
SET farmer_id = farm.farmer_id
FROM public.farms AS farm
WHERE estimate.farm_id = farm.id AND estimate.farmer_id IS NULL;
UPDATE public.yield_estimates AS estimate
SET crop_name = cycle.crop_name
FROM public.crop_cycles AS cycle
WHERE estimate.crop_cycle_id = cycle.id AND estimate.crop_name IS NULL;
CREATE INDEX IF NOT EXISTS idx_yield_estimates_farmer_time
    ON public.yield_estimates(farmer_id, calculated_at DESC);
ALTER TABLE public.crop_recommendations ALTER COLUMN confidence_score DROP DEFAULT;
ALTER TABLE public.crop_health_diagnoses ALTER COLUMN severity SET DEFAULT 'Uncertain';

-- --------------------------------------------------------------------
-- 1. Helper Functions for Security Context
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT coalesce(
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
        OR (auth.jwt() ->> 'role') = 'service_role',
        false
    );
$$;

-- --------------------------------------------------------------------
-- 2. Enable Row Level Security (RLS) on all tables
-- --------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farm_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_health_diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yield_estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_messages ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 3. Profiles Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
    FOR SELECT USING (
        supabase_auth_id = auth.uid() OR public.is_admin()
    );

DROP POLICY IF EXISTS "profiles_insert_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_insert_own_or_admin" ON public.profiles
    FOR INSERT WITH CHECK (
        supabase_auth_id = auth.uid() OR public.is_admin()
    );

DROP POLICY IF EXISTS "profiles_update_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_update_own_or_admin" ON public.profiles
    FOR UPDATE USING (
        supabase_auth_id = auth.uid() OR public.is_admin()
    ) WITH CHECK (
        supabase_auth_id = auth.uid() OR public.is_admin()
    );

DROP POLICY IF EXISTS "profiles_delete_admin_only" ON public.profiles;
CREATE POLICY "profiles_delete_admin_only" ON public.profiles
    FOR DELETE USING (public.is_admin());

-- --------------------------------------------------------------------
-- 4. Farms Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "farms_access_own_or_admin" ON public.farms;
CREATE POLICY "farms_access_own_or_admin" ON public.farms
    FOR ALL USING (
        farmer_id IN (
            SELECT id FROM public.profiles 
            WHERE supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

-- --------------------------------------------------------------------
-- 5. Crop Cycles Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "crop_cycles_access_own_or_admin" ON public.crop_cycles;
CREATE POLICY "crop_cycles_access_own_or_admin" ON public.crop_cycles
    FOR ALL USING (
        farm_id IN (
            SELECT f.id FROM public.farms f
            JOIN public.profiles p ON f.farmer_id = p.id
            WHERE p.supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

-- --------------------------------------------------------------------
-- 6. Farm Observations Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "farm_observations_access_own_or_admin" ON public.farm_observations;
CREATE POLICY "farm_observations_access_own_or_admin" ON public.farm_observations
    FOR ALL USING (
        crop_cycle_id IN (
            SELECT cc.id FROM public.crop_cycles cc
            JOIN public.farms f ON cc.farm_id = f.id
            JOIN public.profiles p ON f.farmer_id = p.id
            WHERE p.supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

-- --------------------------------------------------------------------
-- 7. Crop Recommendations Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "crop_recommendations_select_own_or_admin" ON public.crop_recommendations;
CREATE POLICY "crop_recommendations_select_own_or_admin" ON public.crop_recommendations
    FOR SELECT USING (
        farm_id IN (
            SELECT f.id FROM public.farms f
            JOIN public.profiles p ON f.farmer_id = p.id
            WHERE p.supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "crop_recommendations_modify_admin_only" ON public.crop_recommendations;
CREATE POLICY "crop_recommendations_modify_admin_only" ON public.crop_recommendations
    FOR ALL USING (public.is_admin());

-- --------------------------------------------------------------------
-- 8. Weather Observations Policies (Public Read Access)
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "weather_observations_public_read" ON public.weather_observations;
CREATE POLICY "weather_observations_public_read" ON public.weather_observations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "weather_observations_modify_admin_only" ON public.weather_observations;
CREATE POLICY "weather_observations_modify_admin_only" ON public.weather_observations
    FOR ALL USING (public.is_admin());

-- --------------------------------------------------------------------
-- 9. Crop Health Diagnoses Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "crop_health_diagnoses_access_own_or_admin" ON public.crop_health_diagnoses;
CREATE POLICY "crop_health_diagnoses_access_own_or_admin" ON public.crop_health_diagnoses
    FOR ALL USING (
        farmer_id IN (
            SELECT id FROM public.profiles 
            WHERE supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

-- --------------------------------------------------------------------
-- 10. Yield Estimates Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "yield_estimates_access_own_or_admin" ON public.yield_estimates;
CREATE POLICY "yield_estimates_access_own_or_admin" ON public.yield_estimates
    FOR ALL USING (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    );

-- --------------------------------------------------------------------
-- 11. Assistant Conversations & Messages Policies
-- --------------------------------------------------------------------
DROP POLICY IF EXISTS "assistant_conversations_access_own_or_admin" ON public.assistant_conversations;
CREATE POLICY "assistant_conversations_access_own_or_admin" ON public.assistant_conversations
    FOR ALL USING (
        farmer_id IN (
            SELECT id FROM public.profiles 
            WHERE supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "assistant_messages_access_own_or_admin" ON public.assistant_messages;
CREATE POLICY "assistant_messages_access_own_or_admin" ON public.assistant_messages
    FOR ALL USING (
        conversation_id IN (
            SELECT c.id FROM public.assistant_conversations c
            JOIN public.profiles p ON c.farmer_id = p.id
            WHERE p.supabase_auth_id = auth.uid()
        )
        OR public.is_admin()
    );

COMMIT;
-- AgriVerse AI Migration 009
-- Additive data ownership fields and strict Supabase API isolation.
-- Review the RLS effects and take a database backup before applying to a live project.

BEGIN;

ALTER TABLE public.yield_estimates
    ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.yield_estimates
    ADD COLUMN IF NOT EXISTS crop_name VARCHAR(100);

-- Preserve historical rows and attach ownership where the existing farm/cycle relation proves it.
UPDATE public.yield_estimates AS estimate
SET farmer_id = farm.farmer_id
FROM public.farms AS farm
WHERE estimate.farm_id = farm.id
  AND estimate.farmer_id IS NULL;

UPDATE public.yield_estimates AS estimate
SET crop_name = cycle.crop_name
FROM public.crop_cycles AS cycle
WHERE estimate.crop_cycle_id = cycle.id
  AND estimate.crop_name IS NULL;

CREATE INDEX IF NOT EXISTS idx_yield_estimates_farmer_time
    ON public.yield_estimates(farmer_id, calculated_at DESC);

ALTER TABLE public.crop_recommendations
    ALTER COLUMN confidence_score DROP DEFAULT;
ALTER TABLE public.crop_health_diagnoses
    ALTER COLUMN severity SET DEFAULT 'Uncertain';

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT coalesce(
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
        OR (auth.jwt() ->> 'role') = 'service_role',
        false
    );
$$;

-- Custom backend accounts have no Supabase auth UUID. They use the private backend DB
-- connection; the anon/authenticated Supabase data APIs must never treat NULL auth IDs as owners.
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
    FOR SELECT USING (supabase_auth_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS "profiles_insert_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_insert_own_or_admin" ON public.profiles
    FOR INSERT WITH CHECK (supabase_auth_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS "profiles_update_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_update_own_or_admin" ON public.profiles
    FOR UPDATE USING (supabase_auth_id = auth.uid() OR public.is_admin())
    WITH CHECK (supabase_auth_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "farms_access_own_or_admin" ON public.farms;
CREATE POLICY "farms_access_own_or_admin" ON public.farms
    FOR ALL
    USING (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    )
    WITH CHECK (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "crop_cycles_access_own_or_admin" ON public.crop_cycles;
CREATE POLICY "crop_cycles_access_own_or_admin" ON public.crop_cycles
    FOR ALL
    USING (
        farm_id IN (
            SELECT farm.id FROM public.farms AS farm
            JOIN public.profiles AS profile ON profile.id = farm.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    )
    WITH CHECK (
        farm_id IN (
            SELECT farm.id FROM public.farms AS farm
            JOIN public.profiles AS profile ON profile.id = farm.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    );

DROP POLICY IF EXISTS "farm_observations_access_own_or_admin" ON public.farm_observations;
CREATE POLICY "farm_observations_access_own_or_admin" ON public.farm_observations
    FOR ALL
    USING (
        crop_cycle_id IN (
            SELECT cycle.id FROM public.crop_cycles AS cycle
            JOIN public.farms AS farm ON farm.id = cycle.farm_id
            JOIN public.profiles AS profile ON profile.id = farm.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    )
    WITH CHECK (
        crop_cycle_id IN (
            SELECT cycle.id FROM public.crop_cycles AS cycle
            JOIN public.farms AS farm ON farm.id = cycle.farm_id
            JOIN public.profiles AS profile ON profile.id = farm.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    );

DROP POLICY IF EXISTS "crop_recommendations_select_own_or_admin" ON public.crop_recommendations;
CREATE POLICY "crop_recommendations_select_own_or_admin" ON public.crop_recommendations
    FOR SELECT USING (
        farm_id IN (
            SELECT farm.id FROM public.farms AS farm
            JOIN public.profiles AS profile ON profile.id = farm.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    );
DROP POLICY IF EXISTS "crop_recommendations_modify_admin_only" ON public.crop_recommendations;
CREATE POLICY "crop_recommendations_modify_admin_only" ON public.crop_recommendations
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "crop_health_diagnoses_access_own_or_admin" ON public.crop_health_diagnoses;
CREATE POLICY "crop_health_diagnoses_access_own_or_admin" ON public.crop_health_diagnoses
    FOR ALL
    USING (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    )
    WITH CHECK (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "yield_estimates_access_own_or_admin" ON public.yield_estimates;
CREATE POLICY "yield_estimates_access_own_or_admin" ON public.yield_estimates
    FOR ALL
    USING (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    )
    WITH CHECK (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "assistant_conversations_access_own_or_admin" ON public.assistant_conversations;
CREATE POLICY "assistant_conversations_access_own_or_admin" ON public.assistant_conversations
    FOR ALL
    USING (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    )
    WITH CHECK (
        farmer_id IN (SELECT id FROM public.profiles WHERE supabase_auth_id = auth.uid())
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "assistant_messages_access_own_or_admin" ON public.assistant_messages;
CREATE POLICY "assistant_messages_access_own_or_admin" ON public.assistant_messages
    FOR ALL
    USING (
        conversation_id IN (
            SELECT conversation.id FROM public.assistant_conversations AS conversation
            JOIN public.profiles AS profile ON profile.id = conversation.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    )
    WITH CHECK (
        conversation_id IN (
            SELECT conversation.id FROM public.assistant_conversations AS conversation
            JOIN public.profiles AS profile ON profile.id = conversation.farmer_id
            WHERE profile.supabase_auth_id = auth.uid()
        ) OR public.is_admin()
    );

-- PostgreSQL 15+ invoker views keep the underlying table RLS policies in force.
CREATE OR REPLACE VIEW public.observations WITH (security_invoker = true)
    AS SELECT * FROM public.farm_observations;
CREATE OR REPLACE VIEW public.recommendations WITH (security_invoker = true)
    AS SELECT * FROM public.crop_recommendations;
CREATE OR REPLACE VIEW public.weather_records WITH (security_invoker = true)
    AS SELECT * FROM public.weather_observations;
CREATE OR REPLACE VIEW public.image_diagnosis_records WITH (security_invoker = true)
    AS SELECT * FROM public.crop_health_diagnoses;

COMMIT;
