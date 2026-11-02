-- ====================================================================
-- AgriVerse AI Migration 001: Extensions and Trigger Functions
-- Description: Enables UUID/cryptographic extensions and updated_at triggers
-- Repeatable and idempotent
-- ====================================================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Generic Trigger Function for Auto-Updating updated_at Columns
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
