-- ============================================================================
-- FUNÇÃO: handle_gamification_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_gamification_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_level INTEGER := 1;
    new_level INTEGER := 1;
    level_name TEXT;
    level_thresholds INTEGER[] := ARRAY[0, 100, 300, 600, 1000, 2000, 4000, 8000, 16000, 32000];
    level_names TEXT[] := ARRAY['Novato', 'Iniciante', 'Ativo', 'Engajado', 'Influente', 'Líder', 'Especialista', 'Mestre', 'Lenda', 'Hall da Fama'];
    i INTEGER;
BEGIN
    -- Calcular nível anterior
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF OLD.total_points >= level_thresholds[i] THEN
            old_level := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Calcular novo nível
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF NEW.total_points >= level_thresholds[i] THEN
            new_level := i;
            level_name := level_names[i];
            EXIT;
        END IF;
    END LOOP;
    
    -- Notificar level up se mudou
    IF new_level > old_level THEN
        PERFORM notify_level_up_definitive(NEW.user_id, old_level, new_level, level_name);
        RAISE NOTICE 'Level up: % subiu do nível % para % (%)', NEW.user_id, old_level, new_level, level_name;
    END IF;
    
    -- Notificar marcos de pontuação
    PERFORM notify_point_milestone_definitive(NEW.user_id, OLD.total_points, NEW.total_points);
    
    RETURN NEW;
END;
$function$

