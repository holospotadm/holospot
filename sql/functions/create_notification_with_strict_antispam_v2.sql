-- ============================================================================
-- FUNÇÃO: create_notification_with_strict_antispam_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_with_strict_antispam(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
    can_create BOOLEAN := false;
BEGIN
    -- Não criar notificação para si mesmo
    IF p_from_user_id = p_user_id THEN
        RETURN false;
    END IF;
    
    -- Obter threshold específico
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Se threshold é -1, sempre criar (badges, level up)
    IF threshold_hours = -1 THEN
        can_create := true;
    -- Se threshold é 0, sempre criar (feedbacks)
    ELSIF threshold_hours = 0 THEN
        can_create := true;
    ELSE
        -- Verificar se já existe notificação similar no período
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL;
        
        -- Só criar se não existe similar
        can_create := (existing_count = 0);
    END IF;
    
    -- Se pode criar, inserir
    IF can_create THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RETURN true;
    ELSE
        -- Log que foi bloqueada
        RAISE NOTICE 'Notificação bloqueada por anti-spam: % de % para %', 
            p_type, p_from_user_id, p_user_id;
        RETURN false;
    END IF;
END;
$function$

