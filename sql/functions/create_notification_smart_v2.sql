-- ============================================================================
-- FUNÇÃO: create_notification_smart_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_smart(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_post_id uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    should_create BOOLEAN;
BEGIN
    -- Não criar notificação para si mesmo (exceto badges/level up)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter limite específico para este tipo
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificar se deve criar
    SELECT should_create_notification(
        p_user_id, p_from_user_id, p_type, threshold_hours
    ) INTO should_create;
    
    -- Se deve criar, inserir COM post_id
    IF should_create THEN
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

