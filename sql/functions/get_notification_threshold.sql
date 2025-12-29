-- ============================================================================
-- FUNÇÃO: get_notification_threshold
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_notification_threshold(p_type text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN CASE p_type
        WHEN 'reaction' THEN 2        -- 2 horas para reações
        WHEN 'comment' THEN 6         -- 6 horas para comentários  
        WHEN 'feedback' THEN 0        -- Sem limite para feedbacks
        WHEN 'follow' THEN 24         -- 24 horas para follows
        WHEN 'badge_earned' THEN -1   -- Nunca bloquear badges
        WHEN 'level_up' THEN -1       -- Nunca bloquear level up
        WHEN 'milestone' THEN -1      -- Nunca bloquear marcos
        WHEN 'reaction_grouped' THEN -1 -- Nunca bloquear agrupadas
        ELSE 1                        -- Default: 1 hora
    END;
END;
$function$

