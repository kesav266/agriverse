-- ====================================================================
-- AgriVerse AI Migration 002: Profiles and Farms
-- Description: Core entities for farmer accounts and land parcel records
-- Repeatable and idempotent
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Profiles Table (Farmer Accounts)
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

-- Safely link to Supabase Auth if auth.users table is present
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

-- Profiles updated_at Trigger
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone_number);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_id ON public.profiles(supabase_auth_id);
CREATE INDEX IF NOT EXISTS idx_profiles_district ON public.profiles(district);

-- --------------------------------------------------------------------
-- 2. Farms Table (Agricultural Land Holdings)
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

-- Farms updated_at Trigger
DROP TRIGGER IF EXISTS set_farms_updated_at ON public.farms;
CREATE TRIGGER set_farms_updated_at
    BEFORE UPDATE ON public.farms
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Farms Indexes
CREATE INDEX IF NOT EXISTS idx_farms_farmer ON public.farms(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farms_soil_type ON public.farms(soil_type);
