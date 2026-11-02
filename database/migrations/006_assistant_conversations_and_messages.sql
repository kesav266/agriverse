-- ====================================================================
-- AgriVerse AI Migration 006: Assistant Conversations and Messages
-- Description: Conversational history and multi-turn agricultural dialog
-- Repeatable and idempotent
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Assistant Conversations Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.assistant_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL DEFAULT 'AgriVerse Query',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Conversations updated_at Trigger
DROP TRIGGER IF EXISTS set_assistant_conversations_updated_at ON public.assistant_conversations;
CREATE TRIGGER set_assistant_conversations_updated_at
    BEFORE UPDATE ON public.assistant_conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Conversations Indexes
CREATE INDEX IF NOT EXISTS idx_assistant_conv_farmer ON public.assistant_conversations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_assistant_conv_created ON public.assistant_conversations(created_at DESC);

-- --------------------------------------------------------------------
-- 2. Assistant Messages Table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.assistant_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.assistant_conversations(id) ON DELETE CASCADE,
    sender VARCHAR(20) NOT NULL CHECK (sender IN ('user', 'assistant')),
    content TEXT NOT NULL,
    language VARCHAR(10) NOT NULL DEFAULT 'en', -- 'en' or 'te'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Messages Indexes
CREATE INDEX IF NOT EXISTS idx_assistant_msg_conv ON public.assistant_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_assistant_msg_created ON public.assistant_messages(created_at ASC);
