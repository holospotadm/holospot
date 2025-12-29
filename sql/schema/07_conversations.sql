-- ============================================================================
-- TABELA: conversations
-- ============================================================================

CREATE TABLE public.conversations (updated_at timestamp with time zone DEFAULT now(), created_at timestamp with time zone DEFAULT now(), user2_id uuid NOT NULL, user1_id uuid NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid());
