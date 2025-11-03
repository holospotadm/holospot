-- Migration: Adicionar logs de debug para calculate_user_streak
-- Data: 2024-11-02
-- Descrição: Adicionar logs detalhados para investigar por que feedbacks não contam para streak

CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_streak INTEGER := 0;
    v_user_timezone TEXT;
    v_current_date DATE;
    v_check_date DATE;
    v_has_activity BOOLEAN;
BEGIN
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone
    FROM profiles 
    WHERE id = p_user_id;
    
    -- Se não encontrar timezone, usar padrão do Brasil
    IF v_user_timezone IS NULL THEN
        v_user_timezone := 'America/Sao_Paulo';
    END IF;
    
    -- Calcular data atual no timezone do usuário
    v_current_date := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_check_date := v_current_date;
    
    -- Log para debug
    RAISE NOTICE 'Calculando streak para usuário % no timezone % (data atual: %)', 
        p_user_id, v_user_timezone, v_current_date;
    
    -- Loop para contar dias consecutivos com atividade
    LOOP
        -- Verificar atividades do dia usando timezone do usuário
        -- DEBUG: Contar cada tipo de atividade separadamente
        DECLARE
            v_posts_count INTEGER;
            v_comments_count INTEGER;
            v_reactions_count INTEGER;
            v_feedbacks_count INTEGER;
        BEGIN
            -- Contar posts
            SELECT COUNT(*) INTO v_posts_count
            FROM public.posts 
            WHERE user_id = p_user_id 
            AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date
            AND (content ~ '@\w+' OR content IS NOT NULL);
            
            -- Contar comentários
            SELECT COUNT(*) INTO v_comments_count
            FROM public.comments 
            WHERE user_id = p_user_id
            AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
            
            -- Contar reações
            SELECT COUNT(*) INTO v_reactions_count
            FROM public.reactions 
            WHERE user_id = p_user_id
            AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
            
            -- Contar feedbacks
            SELECT COUNT(*) INTO v_feedbacks_count
            FROM public.feedbacks 
            WHERE author_id = p_user_id
            AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
            
            -- Log detalhado
            RAISE NOTICE '📅 Verificando atividades em % (timezone: %): Posts=%, Comments=%, Reactions=%, Feedbacks=%', 
                v_check_date, v_user_timezone, v_posts_count, v_comments_count, v_reactions_count, v_feedbacks_count;
            
            -- Verificar se houve atividade
            v_has_activity := (v_posts_count + v_comments_count + v_reactions_count + v_feedbacks_count) > 0;
        END;
        
        -- Se não houve atividade neste dia, parar o loop
        IF NOT v_has_activity THEN
            -- Se é hoje e não tem atividade, streak é 0
            IF v_check_date = v_current_date THEN
                v_streak := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Se houve atividade, incrementar streak
        v_streak := v_streak + 1;
        
        -- Ir para o dia anterior
        v_check_date := v_check_date - INTERVAL '1 day';
        
        -- Limite de segurança para evitar loop infinito (máximo 365 dias)
        IF v_streak >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Streak calculado: % dias (timezone: %)', v_streak, v_user_timezone;
    
    RETURN v_streak;
END;
$function$;
