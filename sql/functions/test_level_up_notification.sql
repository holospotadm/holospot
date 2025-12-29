-- ============================================================================
-- FUNÇÃO: test_level_up_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_level_up_notification(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_points INTEGER;
    current_level INTEGER := 1;
    next_level INTEGER := 2;
    level_names TEXT[] := ARRAY['Novato', 'Iniciante', 'Ativo', 'Engajado', 'Influente', 'Líder', 'Especialista', 'Mestre', 'Lenda', 'Hall da Fama'];
    level_thresholds INTEGER[] := ARRAY[0, 100, 300, 600, 1000, 2000, 4000, 8000, 16000, 32000];
    i INTEGER;
    notification_created BOOLEAN;
BEGIN
    -- Buscar pontos atuais
    SELECT total_points INTO current_points FROM public.user_points WHERE user_id = p_user_id;
    
    IF current_points IS NULL THEN
        RETURN 'Usuário não encontrado';
    END IF;
    
    -- Calcular nível atual
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF current_points >= level_thresholds[i] THEN
            current_level := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Calcular próximo nível
    next_level := current_level + 1;
    IF next_level > array_length(level_names, 1) THEN
        next_level := array_length(level_names, 1);
    END IF;
    
    -- Criar notificação de level up de teste
    SELECT notify_level_up_definitive(
        p_user_id, 
        current_level - 1, 
        current_level, 
        level_names[current_level]
    ) INTO notification_created;
    
    IF notification_created THEN
        RETURN 'Notificação de level up criada com sucesso! Nível: ' || level_names[current_level];
    ELSE
        RETURN 'Notificação não foi criada (pode já existir)';
    END IF;
END;
$function$

