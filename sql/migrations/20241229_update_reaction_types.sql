-- ============================================================================
-- MIGRAÇÃO: Atualizar tipos de reação para loved, claps, hug
-- Data: 2024-12-29
-- ============================================================================
-- Esta migração atualiza todas as funções que referenciam os tipos antigos
-- de reação (touched, grateful, inspired) para os novos tipos (loved, claps, hug)
-- ============================================================================

-- ============================================================================
-- FUNÇÃO 1: handle_reaction_simple (CORRIGIDA)
-- ============================================================================
-- Correções:
-- 1. Tipos de reação: touched → loved, grateful → claps, inspired → hug
-- 2. Emojis: ❤️ (loved), 👏 (claps), 🫂 (hug)
-- 3. Corrigido NEW.author_id para NEW.user_id (coluna correta da tabela reactions)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_simple()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji baseado no novo tipo de reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Mensagem simples
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Verificação simples de duplicata (sem lock complexo)
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação simples (COM post_id)
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, post_id,
            priority, read, created_at
        ) VALUES (
            post_owner_id, NEW.user_id, 'reaction', message_text, NEW.post_id,
            1, false, NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.handle_reaction_simple IS 
'Cria notificação simples quando alguém reage a um post. Tipos: loved (❤️), claps (👏), hug (🫂)';

-- ============================================================================
-- FUNÇÃO 2: handle_reaction_notification (CORRIGIDA)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji baseado no novo tipo de reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id,
        priority, read, created_at
    ) VALUES (
        post_owner_id, NEW.user_id, 'reaction', message_text, NEW.post_id,
        1, false, NOW()
    )
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.handle_reaction_notification IS 
'Cria notificação quando alguém reage a um post. Tipos: loved (❤️), claps (👏), hug (🫂)';

-- ============================================================================
-- ATUALIZAR COMENTÁRIO DA TABELA REACTIONS
-- ============================================================================

COMMENT ON COLUMN public.reactions.type IS 'Tipo da reação: loved (❤️ Amei), claps (👏 Palmas), hug (🫂 Abraço)';

-- ============================================================================
-- NOTAS DA MIGRAÇÃO
-- ============================================================================
-- 
-- Tipos de Reação Atualizados:
-- - ANTIGO: touched (❤️), grateful (🙏), inspired (✨)
-- - NOVO: loved (❤️), claps (👏), hug (🫂)
-- 
-- Funções Atualizadas:
-- 1. handle_reaction_simple - Notificação simples de reação
-- 2. handle_reaction_notification - Notificação de reação
-- 
-- Correções Adicionais:
-- - Corrigido NEW.author_id para NEW.user_id (tabela reactions não tem author_id)
-- 
-- Compatibilidade:
-- - Reações antigas (touched, grateful, inspired) mostrarão emoji 👍 genérico
-- - Novas reações (loved, claps, hug) mostrarão emojis corretos
-- 
-- ============================================================================
