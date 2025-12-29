-- ============================================================================
-- FUNÇÃO: notify_badge_earned
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_earned(p_user_id uuid, p_badge_id uuid, p_badge_name text, p_badge_rarity text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se já não existe notificação deste badge
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = 'badge_earned'
        AND message LIKE '%' || p_badge_name || '%'
    ) THEN
        RETURN create_notification_smart(
            p_user_id,
            NULL, -- Sem from_user (sistema)
            'badge_earned',
            '🏆 Parabéns! Você conquistou o emblema "' || p_badge_name || '" (' || p_badge_rarity || ')',
            3 -- Prioridade alta
        );
    END IF;
    
    RETURN false;
END;
$function$

