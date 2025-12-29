-- ============================================================================
-- FUNÇÃO: check_notification_spam
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_notification_spam(p_user_id uuid, p_from_user_id uuid, p_type text, p_reference_id text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
BEGIN
    -- Obter threshold para este tipo
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Se threshold é -1, sempre permitir
    IF threshold_hours = -1 THEN
        RETURN true;
    END IF;
    
    -- Se threshold é 0, sempre permitir
    IF threshold_hours = 0 THEN
        RETURN true;
    END IF;
    
    -- Contar notificações similares no período
    SELECT COUNT(*) INTO existing_count
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL
    AND (p_reference_id IS NULL OR message LIKE '%' || p_reference_id || '%');
    
    -- Retornar se pode criar (0 = pode criar)
    RETURN existing_count = 0;
END;
$function$

