-- ============================================================================
-- FUNÇÃO ATUALIZADA: calculate_user_streak_with_timezone
-- ============================================================================
-- Versão corrigida que usa o timezone do usuário para cálculo correto de streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_streak_with_timezone(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $$
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
        SELECT EXISTS (
            SELECT 1 FROM (
                -- Posts criados
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND (content ~ '@\w+' OR content IS NOT NULL)
                
                UNION ALL
                
                -- Comentários em qualquer post
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.comments 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Reações em qualquer post
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.reactions 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Feedbacks escritos
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.feedbacks 
                WHERE author_id = p_user_id
            ) activities
            WHERE activity_date = v_check_date
        ) INTO v_has_activity;
        
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
$$;

-- ============================================================================
-- ATUALIZAR FUNÇÃO PRINCIPAL PARA USAR TIMEZONE
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $$
BEGIN
    -- Usar a nova função com timezone
    RETURN calculate_user_streak_with_timezone(p_user_id);
END;
$$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.calculate_user_streak_with_timezone(UUID) IS 
'Calcula streak do usuário considerando seu fuso horário.
Corrige problema de cálculo incorreto quando servidor e usuário estão em timezones diferentes.
Usa timezone da tabela profiles ou America/Sao_Paulo como padrão.';

COMMENT ON FUNCTION public.calculate_user_streak(UUID) IS 
'Função principal para calcular streak. Atualizada para usar timezone do usuário.
Mantém compatibilidade com código existente.';

-- ============================================================================
-- EXEMPLO DE USO
-- ============================================================================
-- SELECT calculate_user_streak('user-uuid-here');
-- SELECT calculate_user_streak_with_timezone('user-uuid-here');
