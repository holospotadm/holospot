-- =====================================================
-- FUNÇÃO: calculate_holospot_index (v2 - PERCENTIL)
-- Calcula o Índice HoloSpot usando percentil para comparação justa
-- =====================================================

-- Dropar função anterior
DROP FUNCTION IF EXISTS calculate_holospot_index(UUID);

CREATE OR REPLACE FUNCTION calculate_holospot_index(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    -- Componentes do índice
    v_positivity DECIMAL(5,2) := 0;
    v_reciprocity DECIMAL(5,2) := 0;
    v_impact DECIMAL(5,2) := 0;
    v_evolution DECIMAL(5,2) := 0;
    
    -- Dados brutos do usuário
    v_posts_received INTEGER := 0;
    v_unique_highlighters INTEGER := 0;
    v_highlight_types INTEGER := 0;
    v_total_types INTEGER := 6;
    
    v_my_mentions INTEGER := 0;
    v_mutual_mentions INTEGER := 0;
    
    v_people_highlighted INTEGER := 0;
    v_reactions_generated INTEGER := 0;
    v_chains_participated INTEGER := 0;
    
    v_streak INTEGER := 0;
    v_days_active INTEGER := 0;
    
    -- Percentis calculados
    v_pct_posts_received DECIMAL(5,2) := 0;
    v_pct_unique_highlighters DECIMAL(5,2) := 0;
    v_pct_people_highlighted DECIMAL(5,2) := 0;
    v_pct_reactions_generated DECIMAL(5,2) := 0;
    v_pct_chains_participated DECIMAL(5,2) := 0;
    v_pct_streak DECIMAL(5,2) := 0;
    v_pct_days_active DECIMAL(5,2) := 0;
    
    -- Fatores de ajuste
    v_time_factor DECIMAL(5,2) := 1.0;
    v_consistency_factor DECIMAL(5,2) := 1.0;
    
    -- Resultado final
    v_index DECIMAL(5,2) := 0;
    v_level TEXT := 'Observando';
    v_emoji TEXT := '👁️';
    
    -- Variáveis auxiliares
    v_user_created_at TIMESTAMP;
    v_post_ids UUID[];
    v_total_users INTEGER := 0;
BEGIN
    -- Contar total de usuários ativos (que têm pelo menos 1 post)
    SELECT COUNT(DISTINCT user_id) INTO v_total_users FROM posts;
    
    -- Se não há usuários suficientes, usar valores mínimos
    IF v_total_users < 2 THEN
        v_total_users := 2;
    END IF;

    -- =====================================================
    -- COLETAR DADOS BRUTOS DO USUÁRIO
    -- =====================================================
    
    -- Posts recebidos
    SELECT COUNT(*) INTO v_posts_received
    FROM posts WHERE mentioned_user_id = p_user_id;
    
    -- Pessoas únicas que destacaram
    SELECT COUNT(DISTINCT user_id) INTO v_unique_highlighters
    FROM posts WHERE mentioned_user_id = p_user_id;
    
    -- Variedade de tipos recebidos
    SELECT COUNT(DISTINCT highlight_type) INTO v_highlight_types
    FROM posts WHERE mentioned_user_id = p_user_id AND highlight_type IS NOT NULL;
    
    -- Pessoas que EU destaquei
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_my_mentions
    FROM posts WHERE user_id = p_user_id AND mentioned_user_id IS NOT NULL;
    
    -- Menções mútuas
    SELECT COUNT(DISTINCT p1.mentioned_user_id) INTO v_mutual_mentions
    FROM posts p1
    INNER JOIN posts p2 ON p1.mentioned_user_id = p2.user_id
    WHERE p1.user_id = p_user_id AND p2.mentioned_user_id = p_user_id;
    
    -- Pessoas destacadas
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_people_highlighted
    FROM posts WHERE user_id = p_user_id AND mentioned_user_id IS NOT NULL;
    
    -- IDs dos posts do usuário
    SELECT ARRAY_AGG(id) INTO v_post_ids FROM posts WHERE user_id = p_user_id;
    
    -- Reações geradas
    IF v_post_ids IS NOT NULL AND array_length(v_post_ids, 1) > 0 THEN
        SELECT COUNT(*) INTO v_reactions_generated
        FROM reactions WHERE post_id = ANY(v_post_ids);
    END IF;
    
    -- Participação em correntes
    SELECT COUNT(*) INTO v_chains_participated
    FROM chain_posts WHERE author_id = p_user_id;
    
    -- Streak
    SELECT COALESCE(current_streak, 0) INTO v_streak
    FROM user_streaks WHERE user_id = p_user_id;
    
    -- Dias ativos
    SELECT created_at INTO v_user_created_at FROM profiles WHERE id = p_user_id;
    IF v_user_created_at IS NOT NULL THEN
        v_days_active := GREATEST(1, EXTRACT(DAY FROM AGE(NOW(), v_user_created_at))::INTEGER);
    ELSE
        v_days_active := 1;
    END IF;

    -- =====================================================
    -- 1. POSITIVIDADE RECEBIDA (30%) - PERCENTIL
    -- =====================================================
    
    -- Percentil de posts recebidos
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM (SELECT mentioned_user_id, COUNT(*) as cnt FROM posts 
               WHERE mentioned_user_id IS NOT NULL GROUP BY mentioned_user_id) sub
         WHERE sub.cnt <= v_posts_received),
        0
    ) INTO v_pct_posts_received;
    
    -- Percentil de destacadores únicos
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM (SELECT mentioned_user_id, COUNT(DISTINCT user_id) as cnt FROM posts 
               WHERE mentioned_user_id IS NOT NULL GROUP BY mentioned_user_id) sub
         WHERE sub.cnt <= v_unique_highlighters),
        0
    ) INTO v_pct_unique_highlighters;
    
    -- Variedade de tipos (proporção direta, não percentil)
    v_positivity := (
        (v_pct_posts_received * 0.35) +
        (v_pct_unique_highlighters * 0.35) +
        ((v_highlight_types::DECIMAL / v_total_types) * 100 * 0.30)
    );
    v_positivity := LEAST(v_positivity, 100);

    -- =====================================================
    -- 2. RECIPROCIDADE (25%)
    -- =====================================================
    
    IF v_my_mentions > 0 THEN
        v_reciprocity := (v_mutual_mentions::DECIMAL / v_my_mentions) * 100;
    ELSE
        v_reciprocity := 0;
    END IF;
    v_reciprocity := LEAST(v_reciprocity, 100);

    -- =====================================================
    -- 3. IMPACTO GERADO (25%) - PERCENTIL
    -- =====================================================
    
    -- Percentil de pessoas destacadas
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM (SELECT user_id, COUNT(DISTINCT mentioned_user_id) as cnt FROM posts 
               WHERE mentioned_user_id IS NOT NULL GROUP BY user_id) sub
         WHERE sub.cnt <= v_people_highlighted),
        0
    ) INTO v_pct_people_highlighted;
    
    -- Percentil de reações geradas
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM (SELECT p.user_id, COUNT(r.id) as cnt 
               FROM posts p LEFT JOIN reactions r ON p.id = r.post_id 
               GROUP BY p.user_id) sub
         WHERE sub.cnt <= v_reactions_generated),
        0
    ) INTO v_pct_reactions_generated;
    
    -- Percentil de participação em correntes
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM (SELECT author_id, COUNT(*) as cnt FROM chain_posts GROUP BY author_id) sub
         WHERE sub.cnt <= v_chains_participated),
        CASE WHEN v_chains_participated > 0 THEN 50 ELSE 0 END
    ) INTO v_pct_chains_participated;
    
    v_impact := (
        (v_pct_people_highlighted * 0.40) +
        (v_pct_reactions_generated * 0.35) +
        (v_pct_chains_participated * 0.25)
    );
    v_impact := LEAST(v_impact, 100);

    -- =====================================================
    -- 4. EVOLUÇÃO (20%) - PERCENTIL
    -- =====================================================
    
    -- Percentil de streak
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM user_streaks
         WHERE current_streak <= v_streak),
        CASE WHEN v_streak > 0 THEN 50 ELSE 0 END
    ) INTO v_pct_streak;
    
    -- Percentil de dias ativos
    SELECT COALESCE(
        (SELECT COUNT(*)::DECIMAL / v_total_users * 100
         FROM profiles
         WHERE EXTRACT(DAY FROM AGE(NOW(), created_at)) <= v_days_active),
        50
    ) INTO v_pct_days_active;
    
    v_evolution := (
        (v_pct_streak * 0.60) +
        (v_pct_days_active * 0.40)
    );
    v_evolution := LEAST(v_evolution, 100);

    -- =====================================================
    -- 5. FATORES DE AJUSTE
    -- =====================================================
    
    -- Fator Consistência: premia streak (máx +10%)
    v_consistency_factor := LEAST(1.1, 1 + (v_streak::DECIMAL / 100 * 0.1));

    -- =====================================================
    -- 6. CÁLCULO FINAL DO ÍNDICE
    -- =====================================================
    
    v_index := (
        (v_positivity * 0.30) +
        (v_reciprocity * 0.25) +
        (v_impact * 0.25) +
        (v_evolution * 0.20)
    ) * v_consistency_factor;
    
    v_index := LEAST(v_index, 100);

    -- =====================================================
    -- 7. DETERMINAR NÍVEL
    -- =====================================================
    
    IF v_index >= 86 THEN
        v_level := 'Sustentando'; v_emoji := '☀️';
    ELSIF v_index >= 71 THEN
        v_level := 'Pertencendo'; v_emoji := '🏠';
    ELSIF v_index >= 51 THEN
        v_level := 'Fortalecendo'; v_emoji := '💪';
    ELSIF v_index >= 31 THEN
        v_level := 'Contribuindo'; v_emoji := '🤝';
    ELSIF v_index >= 16 THEN
        v_level := 'Participando'; v_emoji := '👋';
    ELSE
        v_level := 'Observando'; v_emoji := '👁️';
    END IF;

    -- =====================================================
    -- 8. RETORNAR RESULTADO
    -- =====================================================
    
    RETURN json_build_object(
        'index', ROUND(v_index, 1),
        'level', v_level,
        'emoji', v_emoji,
        'components', json_build_object(
            'positivity', ROUND(v_positivity, 1),
            'reciprocity', ROUND(v_reciprocity, 1),
            'impact', ROUND(v_impact, 1),
            'evolution', ROUND(v_evolution, 1)
        ),
        'raw_data', json_build_object(
            'posts_received', v_posts_received,
            'unique_highlighters', v_unique_highlighters,
            'highlight_types', v_highlight_types,
            'my_mentions', v_my_mentions,
            'mutual_mentions', v_mutual_mentions,
            'people_highlighted', v_people_highlighted,
            'reactions_generated', v_reactions_generated,
            'chains_participated', v_chains_participated,
            'streak', v_streak,
            'days_active', v_days_active,
            'total_users', v_total_users
        ),
        'percentiles', json_build_object(
            'posts_received', ROUND(v_pct_posts_received, 1),
            'unique_highlighters', ROUND(v_pct_unique_highlighters, 1),
            'people_highlighted', ROUND(v_pct_people_highlighted, 1),
            'reactions_generated', ROUND(v_pct_reactions_generated, 1),
            'chains_participated', ROUND(v_pct_chains_participated, 1),
            'streak', ROUND(v_pct_streak, 1),
            'days_active', ROUND(v_pct_days_active, 1)
        )
    );
END;
$$;

-- Conceder permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION calculate_holospot_index(UUID) TO authenticated;
