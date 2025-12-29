-- ============================================================================
-- FUNÇÃO: create_single_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_single_notification(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Criar notificação simples sem agrupamento
    INSERT INTO public.notifications (
        user_id,
        from_user_id,
        type,
        message,
        read,
        created_at,
        group_key,
        group_count,
        group_data
    ) VALUES (
        p_user_id,
        p_from_user_id,
        p_type,
        p_message,
        false,
        NOW(),
        NULL,  -- Sem agrupamento para notificações simples
        1,
        NULL
    );
    
    RAISE NOTICE 'NOTIFICAÇÃO CRIADA: % para %', p_type, p_user_id;
END;
$function$

