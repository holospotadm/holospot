-- ============================================================================
-- NOTIFICATION FUNCTIONS - Funções de Notificação
-- ============================================================================
-- Funções responsáveis por criar notificações automáticas para usuários
-- Sistema anti-spam com agrupamento e controle de duplicatas
-- ============================================================================

-- ============================================================================
-- HOLOFOTE NOTIFICATIONS - Notificações de Menções
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_holofote_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    mentioned_user_id UUID;
    username_from TEXT;
    mentioned_username TEXT;
BEGIN
    -- Verificar se o post tem menção (holofote)
    -- Assumindo que há um campo mentioned_user_id ou similar na tabela posts
    -- OU extrair da coluna content procurando por @username
    
    -- OPÇÃO 1: Se há campo mentioned_user_id na tabela posts
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.user_id THEN
        
        -- Buscar username de quem criou o post
        SELECT COALESCE(username, 'Usuario') INTO username_from 
        FROM public.profiles 
        WHERE id = NEW.user_id;
        
        -- Verificação anti-duplicata
        IF NOT EXISTS (
            SELECT 1 FROM public.notifications 
            WHERE user_id = NEW.mentioned_user_id 
            AND from_user_id = NEW.user_id 
            AND type = 'mention'
            AND created_at > NOW() - INTERVAL '1 hour'
            LIMIT 1
        ) THEN
            -- Criar notificação de holofote
            INSERT INTO public.notifications (
                user_id, from_user_id, type, message, read, created_at
            ) VALUES (
                NEW.mentioned_user_id,  -- Quem foi mencionado recebe notificação
                NEW.user_id,            -- Quem criou o post
                'mention',
                username_from || ' destacou você em um post',  -- ✅ NOVA MENSAGEM
                false,
                NOW()
            );
        END IF;
    END IF;
    
    -- OPÇÃO 2: Se não há campo, extrair da content (implementar se necessário)
    /*
    IF NEW.content LIKE '%@%' THEN
        -- Lógica para extrair @username da content
        -- E criar notificação para cada usuário mencionado
    END IF;
    */
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMMENT NOTIFICATIONS - Notificações de Comentários
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_correto()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificar se não é auto-comentário
    IF post_author_id IS NULL OR post_author_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.user_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.user_id 
        AND type = 'comment'
        AND created_at > NOW() - INTERVAL '6 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, read, created_at
    ) VALUES (
        post_author_id,
        NEW.user_id,
        'comment',
        username_from || ' comentou no seu post',  -- ✅ SEM EXCLAMAÇÃO
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_comment_notification_only()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
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
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Criar APENAS notificação (não mexer em pontos)
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'comment', message_text, 2
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- REACTION NOTIFICATIONS - Notificações de Reações
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
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'inspired' THEN '✨'
        WHEN 'grateful' THEN '🙏'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post!';
    
    -- Criar APENAS notificação (pontos são tratados por outro trigger)
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'reaction', message_text, 1
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- FEEDBACK NOTIFICATIONS - Notificações de Feedbacks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_correto()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-feedback
    IF NEW.author_id = NEW.mentioned_user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.mentioned_user_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.author_id 
        AND from_user_id = NEW.mentioned_user_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, read, created_at
    ) VALUES (
        NEW.author_id,
        NEW.mentioned_user_id,
        'feedback',
        username_from || ' deu feedback sobre o seu post',  -- ✅ SEM EXCLAMAÇÃO
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- FOLLOW NOTIFICATIONS - Notificações de Follows
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification_correto()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-follow
    IF NEW.following_id = NEW.follower_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem seguiu
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.follower_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.following_id 
        AND from_user_id = NEW.follower_id 
        AND type = 'follow'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, read, created_at
    ) VALUES (
        NEW.following_id,
        NEW.follower_id,
        'follow',
        username_from || ' começou a te seguir',  -- ✅ SEM EXCLAMAÇÃO
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- BADGE NOTIFICATIONS - Notificações de Badges
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_badge_notification_only()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
    message_text TEXT;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Montar mensagem
    message_text := '🏆 Parabéns! Você conquistou o emblema "' || badge_info.name || '" (' || badge_info.rarity || ')';
    
    -- Criar APENAS notificação (pontos já são tratados por outros triggers)
    PERFORM create_single_notification(
        NEW.user_id, NULL, 'badge_earned', message_text, 3
    );
    
    RAISE NOTICE 'BADGE NOTIFICADO: % (%s) para %', badge_info.name, badge_info.rarity, NEW.user_id;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- STREAK NOTIFICATIONS - Notificações de Streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_streak_notification_only()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    milestone_reached INTEGER;
    bonus_points INTEGER;
BEGIN
    -- Verificar se atingiu um milestone (baseado no sistema existente)
    IF OLD.next_milestone != NEW.next_milestone THEN
        -- Milestone foi atingido (next_milestone mudou)
        milestone_reached := OLD.next_milestone;
        
        -- Buscar pontos bônus do histórico (se existir)
        SELECT COALESCE(points_earned, 0) INTO bonus_points
        FROM public.points_history 
        WHERE user_id = NEW.user_id 
        AND action_type = 'streak_bonus_' || milestone_reached || 'd'
        AND created_at >= NOW() - INTERVAL '1 hour'
        ORDER BY created_at DESC
        LIMIT 1;
        
        -- Notificar milestone usando marcos corretos (7, 30, 182, 365)
        PERFORM notify_streak_milestone_correct(
            NEW.user_id, 
            milestone_reached, 
            COALESCE(bonus_points, 0)
        );
        
        RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', milestone_reached, NEW.user_id, bonus_points;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.handle_holofote_notification() IS 
'Cria notificações quando usuários são mencionados em holofotes.
Sistema anti-duplicata com janela de 1 hora.';

COMMENT ON FUNCTION public.handle_comment_notification_correto() IS 
'Cria notificações quando posts recebem comentários.
Sistema anti-duplicata com janela de 6 horas.';

COMMENT ON FUNCTION public.handle_comment_notification_only() IS 
'Versão simplificada de notificação de comentários.
Utiliza função auxiliar create_single_notification().';

COMMENT ON FUNCTION public.handle_reaction_simple() IS 
'Cria notificações quando posts recebem reações.
Inclui emoji específico por tipo de reação.';

COMMENT ON FUNCTION public.handle_feedback_notification_correto() IS 
'Cria notificações quando posts recebem feedbacks.
Sistema anti-duplicata com janela de 24 horas.';

COMMENT ON FUNCTION public.handle_follow_notification_correto() IS 
'Cria notificações quando usuários são seguidos.
Sistema anti-duplicata com janela de 24 horas.';

COMMENT ON FUNCTION public.handle_badge_notification_only() IS 
'Cria notificações quando usuários conquistam badges.
Inclui informações de raridade do badge.';

COMMENT ON FUNCTION public.handle_streak_notification_only() IS 
'Cria notificações quando usuários atingem milestones de streak.
Inclui informações de pontos bônus conquistados.';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES DE NOTIFICAÇÃO
-- ============================================================================
-- 
-- Funções Dependentes:
-- - create_single_notification(): Função auxiliar para criar notificações
-- - notify_streak_milestone_correct(): Função específica para streaks
-- 
-- Sistema Anti-Spam:
-- - Janelas de tempo diferentes por tipo de notificação
-- - Verificação de duplicatas antes de criar
-- - Agrupamento automático por group_key
-- - Contadores de group_count
-- 
-- Tipos de Notificação:
-- - mention: Menções em holofotes (1 hora)
-- - comment: Comentários em posts (6 horas)
-- - reaction: Reações em posts (imediato)
-- - feedback: Feedbacks em posts (24 horas)
-- - follow: Novos seguidores (24 horas)
-- - badge_earned: Badges conquistados (imediato)
-- - streak: Milestones de streak (imediato)
-- 
-- Prioridades:
-- - badge_earned: 3 (alta)
-- - comment: 2 (média)
-- - reaction: 1 (baixa)
-- - follow: 2 (média)
-- - feedback: 2 (média)
-- - mention: 3 (alta)
-- - streak: 3 (alta)
-- 
-- Mensagens Padronizadas:
-- - Sem exclamações desnecessárias
-- - Linguagem natural e amigável
-- - Informações específicas quando relevante
-- - Emojis apropriados por contexto
-- 
-- ============================================================================

