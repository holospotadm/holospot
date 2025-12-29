-- ============================================================================
-- FUNÇÃO: create_notification_with_strict_antispam
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_with_strict_antispam(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_post_id uuid DEFAULT NULL::uuid)
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
    ELSE
        -- Verificar spam baseado no threshold
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > (NOW() - INTERVAL '1 hour' * threshold_hours);
        
        -- Decidir se pode criar baseado no tipo e contagem
        can_create := CASE 
            WHEN p_type = 'reaction' AND existing_count < 2 THEN true
            WHEN p_type = 'comment' AND existing_count < 1 THEN true
            WHEN p_type = 'follow' AND existing_count < 1 THEN true
            WHEN p_type = 'feedback' AND existing_count < 1 THEN true
            ELSE false
        END;
    END IF;
    
    -- Criar se permitido COM post_id
    IF can_create THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, post_id, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message, p_post_id, false, NOW()
        );
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$function$

