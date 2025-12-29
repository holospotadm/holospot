-- ============================================================================
-- FUNÇÃO: create_notification_ultra_safe_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_ultra_safe(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_post_id uuid DEFAULT NULL::uuid)
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
    AND created_at > NOW() - INTERVAL '30 minutes';
    
    IF exact_match_count > 0 THEN
        RETURN false;
    END IF;
    
    -- Verificação 2: Muitas notificações do mesmo tipo?
    SELECT COUNT(*) INTO existing_count
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND created_at > (NOW() - INTERVAL '1 hour' * threshold_hours);
    
    -- Limites por tipo
    IF (p_type = 'reaction' AND existing_count >= 3) OR
       (p_type = 'comment' AND existing_count >= 2) OR
       (p_type = 'follow' AND existing_count >= 1) OR
       (p_type = 'feedback' AND existing_count >= 1) THEN
        RETURN false;
    END IF;
    
    -- Criar notificação COM post_id
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id, read, created_at
    ) VALUES (
        p_user_id, p_from_user_id, p_type, p_message, p_post_id, false, NOW()
    );
    
    RETURN true;
END;
$function$

