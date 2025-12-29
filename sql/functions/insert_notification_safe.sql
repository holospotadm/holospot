-- ============================================================================
-- FUNÇÃO: insert_notification_safe
-- ============================================================================

CREATE OR REPLACE FUNCTION public.insert_notification_safe(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_reference_id text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se deve criar
    IF check_notification_spam(p_user_id, p_from_user_id, p_type, p_reference_id) THEN
        -- Inserir notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RETURN true;
    ELSE
        -- Bloqueada por spam
        RETURN false;
    END IF;
END;
$function$

