-- ============================================================================
-- FUNÇÃO: create_notification_no_duplicates_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_no_duplicates(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_post_id uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_notification_id UUID;
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
    AND message = p_message  -- Verificação exata da mensagem
    AND created_at > NOW() - INTERVAL '1 hour'  -- Janela menor para duplicatas exatas
    LIMIT 1;
    
    -- Se encontrou duplicata exata, não criar
    IF existing_notification_id IS NOT NULL THEN
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

