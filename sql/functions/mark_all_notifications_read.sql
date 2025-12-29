-- ============================================================================
-- FUNÇÃO: mark_all_notifications_read
-- ============================================================================

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_updated_count INTEGER;
    v_result JSON;
BEGIN
    -- Marcar todas as notificações não lidas como lidas
    -- CORREÇÃO: Removido 'read_at = NOW()' pois o campo não existe na tabela
    UPDATE public.notifications 
    SET read = true
    WHERE user_id = p_user_id 
      AND read = false;
    
    -- Obter número de notificações atualizadas
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', CASE 
            WHEN v_updated_count = 0 THEN 'Nenhuma notificação não lida encontrada'
            WHEN v_updated_count = 1 THEN '1 notificação marcada como lida'
            ELSE v_updated_count || ' notificações marcadas como lidas'
        END
    );
    
    RAISE NOTICE 'NOTIFICAÇÕES MARCADAS COMO LIDAS: % para usuário %', v_updated_count, p_user_id;
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERRO ao marcar notificações como lidas: %', SQLERRM;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'updated_count', 0
    );
END;
$function$

