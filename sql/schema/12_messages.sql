-- ============================================================================
-- TABELA: messages
-- ============================================================================

CREATE TABLE public.messages (created_at timestamp with time zone DEFAULT now(), is_read boolean DEFAULT false, content text NOT NULL, sender_id uuid NOT NULL, conversation_id uuid NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid());
