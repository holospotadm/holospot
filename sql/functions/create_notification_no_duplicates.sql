-- ============================================================================
-- FUNÇÃO: create_notification_no_duplicates
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_no_duplicates(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_notification_id UUID;
    can_create BOOLEAN := false;
BEGIN
    -- Não criar para si mesmo (exceto gamificação)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter threshold
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificar se já existe notificação EXATA
    SELECT id INTO existing_notification_id
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND (
        -- Para badges/level up: verificar se já existe (nunca duplicar)
        (threshold_hours = -1 AND message = p_message) OR
        -- Para feedbacks: verificar últimas 24h
        (threshold_hours = 0 AND created_at > NOW() - INTERVAL '24 hours') OR
        -- Para outros: verificar período específico
        (threshold_hours > 0 AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL)
    )
    LIMIT 1;
    
    -- Se não existe, pode criar
    IF existing_notification_id IS NULL THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RAISE NOTICE 'Notificação criada: % de % para %', p_type, p_from_user_id, p_user_id;
        RETURN true;
    ELSE
        RAISE NOTICE 'Notificação BLOQUEADA (duplicada): % de % para %', p_type, p_from_user_id, p_user_id;
        RETURN false;
    END IF;
END;
$function$

