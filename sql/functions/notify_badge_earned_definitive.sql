-- ============================================================================
-- FUNÇÃO: notify_badge_earned_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_earned_definitive(p_user_id uuid, p_badge_id uuid, p_badge_name text, p_badge_rarity text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Usar função anti-duplicação para badges
    RETURN create_notification_no_duplicates(
        p_user_id,
        NULL, -- Sistema (sem from_user)
        'badge_earned',
        '🏆 Parabéns! Você conquistou o emblema "' || p_badge_name || '" (' || p_badge_rarity || ')',
        3 -- Prioridade alta
    );
END;
$function$

