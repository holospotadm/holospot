-- ============================================================================
-- FUNÇÃO: notify_point_milestone_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_point_milestone_definitive(p_user_id uuid, p_old_points integer, p_new_points integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    milestones INTEGER[] := ARRAY[100, 250, 500, 1000, 2500, 5000, 10000];
    milestone INTEGER;
    notified BOOLEAN := false;
BEGIN
    -- Verificar se atingiu algum marco
    FOREACH milestone IN ARRAY milestones LOOP
        IF p_old_points < milestone AND p_new_points >= milestone THEN
            -- Criar notificação de marco
            PERFORM create_notification_no_duplicates(
                p_user_id,
                NULL, -- Sistema
                'milestone',
                '🎉 Marco histórico: ' || milestone || ' pontos conquistados!',
                3 -- Prioridade alta
            );
            notified := true;
        END IF;
    END LOOP;
    
    RETURN notified;
END;
$function$

