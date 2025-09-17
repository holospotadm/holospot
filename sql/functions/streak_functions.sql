-- ============================================================================
-- FUNÇÕES DE STREAK - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de funções: 4
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- FUNÇÃO: apply_streak_bonus_retroactive
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_milestone INTEGER;
BEGIN
    -- Buscar streak atual do usuário
    SELECT current_streak INTO v_current_streak
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não tem streak, não aplicar bônus
    IF v_current_streak IS NULL OR v_current_streak < 7 THEN
        RETURN;
    END IF;
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE RETURN; -- Não atingiu milestone
    END CASE;
    
    -- Calcular bônus usando função corrigida (agora recebe user_id)
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RETURN;
    END IF;
    
    -- Verificar se já foi aplicado este bônus
    IF NOT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
    ) THEN
        -- Aplicar bônus retroativo
        INSERT INTO points_history (
            user_id, 
            points_earned, 
            action_type, 
            reference_id, 
            reference_type,
            created_at
        ) VALUES (
            p_user_id,
            v_bonus_points,
            'streak_bonus_retroactive',
            p_user_id,
            'milestone_' || v_milestone::text,
            NOW()
        );
        
        -- Atualizar total de pontos
        PERFORM update_user_total_points(p_user_id);
        
        RAISE NOTICE 'Bônus retroativo aplicado: User % - Streak % dias - Milestone % - Bônus % pontos', 
            p_user_id, v_current_streak, v_milestone, v_bonus_points;
    END IF;
END;
$function$
;

-- FUNÇÃO: calculate_streak_bonus
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_points integer, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
BEGIN
    CASE p_milestone
        WHEN 7 THEN v_multiplier := 1.2;   -- +20%
        WHEN 30 THEN v_multiplier := 1.5;  -- +50%
        WHEN 180 THEN v_multiplier := 1.8; -- +80%
        WHEN 365 THEN v_multiplier := 2.0; -- +100%
        ELSE v_multiplier := 1.0;
    END CASE;
    
    -- Bonus = Pontos × (Multiplicador - 1)
    RETURN ROUND(p_points * (v_multiplier - 1));
END;
$function$
;

-- FUNÇÃO: calculate_streak_bonus
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_user_id uuid, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
    v_days_back INTEGER;
    v_points_period INTEGER;
    v_bonus INTEGER;
BEGIN
    -- Determinar multiplicador e período baseado no milestone
    CASE p_milestone
        WHEN 7 THEN 
            v_multiplier := 1.2;   -- +20%
            v_days_back := 7;
        WHEN 30 THEN 
            v_multiplier := 1.5;   -- +50%
            v_days_back := 30;
        WHEN 182 THEN 
            v_multiplier := 1.8;   -- +80%
            v_days_back := 182;
        WHEN 365 THEN 
            v_multiplier := 2.0;   -- +100%
            v_days_back := 365;
        ELSE 
            v_multiplier := 1.0;
            v_days_back := 0;
    END CASE;
    
    -- Se não é um milestone válido, retornar 0
    IF v_days_back = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular pontos dos últimos X dias
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type != 'streak_bonus_retroactive'; -- Excluir bônus anteriores
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE 'Cálculo de bônus: User % - Milestone % dias - Pontos período: % - Bônus: %', 
        p_user_id, p_milestone, v_points_period, v_bonus;
    
    RETURN v_bonus;
END;
$function$
;

-- FUNÇÃO: calculate_user_streak
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_check_date DATE;
    v_has_activity BOOLEAN;
BEGIN
    v_check_date := v_current_date;
    
    -- Loop para contar dias consecutivos com atividade
    LOOP
        -- Verificar atividades do dia (LÓGICA CORRIGIDA CONFORME ESPECIFICAÇÃO)
        SELECT EXISTS (
            SELECT 1 FROM (
                -- Posts criados mencionando outros (@username)
                SELECT DATE(created_at) as activity_date 
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND (content ~ '@\w+' OR content IS NOT NULL)  -- Posts com menções ou qualquer post
                
                UNION ALL
                
                -- Comentários em qualquer post (incluindo próprios)
                SELECT DATE(created_at) as activity_date 
                FROM public.comments 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Reações em qualquer post
                SELECT DATE(created_at) as activity_date 
                FROM public.reactions 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Feedbacks ESCRITOS (giving feedback on any post)
                SELECT DATE(created_at) as activity_date 
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
    
    RETURN v_streak;
END;
$function$
;

