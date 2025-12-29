-- ============================================================================
-- FUNÇÃO: create_notification_ultra_safe
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_ultra_safe(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
    exact_match_count INTEGER;
BEGIN
    -- Não criar para si mesmo (exceto gamificação)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter threshold
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificação 1: Mensagem exata já existe?
    SELECT COUNT(*) INTO exact_match_count
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND message = p_message
    AND created_at > NOW() - INTERVAL '24 hours'; -- Sempre verificar 24h para mensagens exatas
    
    -- Se já existe mensagem exata, não criar
    IF exact_match_count > 0 THEN
        RAISE NOTICE 'BLOQUEADO: Mensagem exata já existe - %', p_message;
        RETURN false;
    END IF;
    
    -- Verificação 2: Threshold por tipo
    IF threshold_hours = -1 THEN
        -- Badges/level up: verificar se já existe
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = p_type
        AND message = p_message;
        
        IF existing_count > 0 THEN
            RAISE NOTICE 'BLOQUEADO: Badge/Level já notificado - %', p_type;
            RETURN false;
        END IF;
    ELSIF threshold_hours = 0 THEN
        -- Feedbacks: permitir sempre (já verificou mensagem exata acima)
        NULL;
    ELSE
        -- Outros tipos: verificar período
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL;
        
        IF existing_count > 0 THEN
            RAISE NOTICE 'BLOQUEADO: Dentro do período de % horas - %', threshold_hours, p_type;
            RETURN false;
        END IF;
    END IF;
    
    -- Se passou em todas as verificações, criar
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, 
        priority, read, created_at
    ) VALUES (
        p_user_id, p_from_user_id, p_type, p_message,
        p_priority, false, NOW()
    );
    
    RAISE NOTICE 'CRIADA: Notificação % de % para %', p_type, p_from_user_id, p_user_id;
    RETURN true;
END;
$function$

