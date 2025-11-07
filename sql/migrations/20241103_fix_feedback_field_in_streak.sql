-- ============================================================================
-- FIX: Corrigir campo de feedbacks na função calculate_user_streak
-- ============================================================================
-- Data: 2025-11-03
-- Problema: Função estava usando author_id mas deveria usar mentioned_user_id
-- Solução: mentioned_user_id = quem ESCREVEU o feedback
-- ============================================================================

-- Dropar função existente
DROP FUNCTION IF EXISTS public.calculate_user_streak(UUID);

-- Recriar função com correção
CREATE FUNCTION public.calculate_user_streak(p_user_id UUID)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_timezone TEXT;
    v_check_date DATE;
    v_today DATE;
    v_yesterday DATE;
    v_streak INTEGER := 0;
    v_max_streak INTEGER := 0;
    v_last_activity DATE;
    v_has_activity BOOLEAN;
    v_posts_count INTEGER;
    v_comments_count INTEGER;
    v_reactions_count INTEGER;
    v_feedbacks_count INTEGER;
BEGIN
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone 
    FROM public.profiles 
    WHERE id = p_user_id;
    
    -- Usar timezone padrão se não encontrado
    IF v_user_timezone IS NULL THEN
        v_user_timezone := 'America/Sao_Paulo';
    END IF;
    
    -- Data de hoje no timezone do usuário
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    
    -- Começar verificando de hoje para trás
    v_check_date := v_today;
    
    -- Loop para verificar atividades consecutivas
    FOR i IN 0..365 LOOP
        v_has_activity := FALSE;
        
        -- Verificar se houve atividade neste dia
        -- Contar posts
        SELECT COUNT(*) INTO v_posts_count
        FROM public.posts 
        WHERE user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
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
        
        -- Contar feedbacks (quem escreveu = mentioned_user_id)
        SELECT COUNT(*) INTO v_feedbacks_count
        FROM public.feedbacks 
        WHERE mentioned_user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        -- Log detalhado
        RAISE NOTICE '📅 Verificando atividades em % (timezone: %): Posts=%, Comments=%, Reactions=%, Feedbacks=%', 
            v_check_date, v_user_timezone, v_posts_count, v_comments_count, v_reactions_count, v_feedbacks_count;
        
        -- Verificar se teve atividade
        IF v_posts_count > 0 OR v_comments_count > 0 OR v_reactions_count > 0 OR v_feedbacks_count > 0 THEN
            v_has_activity := TRUE;
            v_last_activity := v_check_date;
        END IF;
        
        -- Se teve atividade, incrementar streak
        IF v_has_activity THEN
            v_streak := v_streak + 1;
            IF v_streak > v_max_streak THEN
                v_max_streak := v_streak;
            END IF;
        ELSE
            -- Se não teve atividade e não é hoje nem ontem, parar
            IF v_check_date < v_yesterday THEN
                EXIT;
            END IF;
            -- Se é hoje ou ontem sem atividade, zerar streak
            IF v_check_date = v_today OR v_check_date = v_yesterday THEN
                v_streak := 0;
            END IF;
        END IF;
        
        -- Ir para o dia anterior
        v_check_date := v_check_date - INTERVAL '1 day';
    END LOOP;
    
    RETURN QUERY SELECT v_streak, v_max_streak, v_last_activity;
END;
$$;

GRANT EXECUTE ON FUNCTION public.calculate_user_streak(UUID) TO authenticated;
