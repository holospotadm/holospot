-- ============================================================================
-- FUNÇÃO: should_create_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.should_create_notification(p_user_id uuid, p_from_user_id uuid, p_type text, p_hours_threshold integer DEFAULT 2)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Se threshold é -1, sempre criar (badges, level up)
    IF p_hours_threshold = -1 THEN
        RETURN true;
    END IF;
    
    -- Se threshold é 0, sempre criar (feedbacks)
    IF p_hours_threshold = 0 THEN
        RETURN true;
    END IF;
    
    -- Verificar se já existe notificação similar nas últimas X horas
    RETURN NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (p_hours_threshold || ' hours')::INTERVAL
    );
END;
$function$

