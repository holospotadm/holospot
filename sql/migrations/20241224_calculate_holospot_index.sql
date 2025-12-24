-- =====================================================
-- FUNÇÃO: calculate_holospot_index
-- Calcula o Índice HoloSpot (bem-estar social) do usuário
-- =====================================================

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
    
    -- Dados para cálculos
    v_posts_received INTEGER := 0;
    v_unique_highlighters INTEGER := 0;
    v_highlight_types INTEGER := 0;
    v_total_types INTEGER := 6; -- Gratidão, Conquista, Inspiração, Apoio, Admiração, Memória
    
    v_my_mentions INTEGER := 0;
    v_mutual_mentions INTEGER := 0;
    
    v_people_highlighted INTEGER := 0;
    v_reactions_generated INTEGER := 0;
    v_chains_created INTEGER := 0;
    v_chain_participants INTEGER := 0;
    
    v_streak INTEGER := 0;
    v_months_active INTEGER := 0;
    v_days_active INTEGER := 0;
    
    -- Fatores de ajuste
    v_time_factor DECIMAL(5,2) := 1.0;
    v_consistency_factor DECIMAL(5,2) := 1.0;
    
    -- Resultado final
    v_index DECIMAL(5,2) := 0;
    v_level TEXT := 'Observando';
    v_emoji TEXT := '👁️';
    v_next_level TEXT := 'Participando';
    v_next_emoji TEXT := '👋';
    v_points_to_next INTEGER := 0;
    v_level_min INTEGER := 0;
    v_level_max INTEGER := 15;
    
    -- Variáveis auxiliares
    v_user_created_at TIMESTAMP;
    v_post_ids UUID[];
BEGIN
    -- =====================================================
    -- 1. POSITIVIDADE RECEBIDA (30%)
    -- =====================================================
    
    -- Posts recebidos (onde o usuário foi mencionado)
    SELECT COUNT(*) INTO v_posts_received
    FROM posts
    WHERE mentioned_user_id = p_user_id;
    
    -- Pessoas únicas que destacaram o usuário
    SELECT COUNT(DISTINCT user_id) INTO v_unique_highlighters
    FROM posts
    WHERE mentioned_user_id = p_user_id;
    
    -- Variedade de tipos de destaque recebidos
    SELECT COUNT(DISTINCT highlight_type) INTO v_highlight_types
    FROM posts
    WHERE mentioned_user_id = p_user_id
    AND highlight_type IS NOT NULL;
    
    -- Calcular positividade (normalizado 0-100)
    -- Posts recebidos: até 50 posts = 100%
    -- Diversidade: proporção de destacadores únicos
    -- Variedade: proporção de tipos recebidos
    v_positivity := (
        (LEAST(v_posts_received, 50)::DECIMAL / 50 * 100 * 0.25) +
        (CASE WHEN v_posts_received > 0 
            THEN (v_unique_highlighters::DECIMAL / v_posts_received) * 100 * 0.30
            ELSE 0 END) +
        (LEAST(v_posts_received, 30)::DECIMAL / 30 * 100 * 0.25) + -- Consistência temporal simplificada
        (v_highlight_types::DECIMAL / v_total_types * 100 * 0.20)
    );
    v_positivity := LEAST(v_positivity, 100);
    
    -- =====================================================
    -- 2. RECIPROCIDADE (25%)
    -- =====================================================
    
    -- Pessoas que EU destaquei
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_my_mentions
    FROM posts
    WHERE user_id = p_user_id
    AND mentioned_user_id IS NOT NULL;
    
    -- Relacionamentos bidirecionais (eu destaquei E fui destacado pela mesma pessoa)
    SELECT COUNT(DISTINCT p1.mentioned_user_id) INTO v_mutual_mentions
    FROM posts p1
    INNER JOIN posts p2 ON p1.mentioned_user_id = p2.user_id
    WHERE p1.user_id = p_user_id
    AND p2.mentioned_user_id = p_user_id;
    
    -- Calcular reciprocidade (normalizado 0-100)
    IF v_my_mentions > 0 THEN
        v_reciprocity := (v_mutual_mentions::DECIMAL / v_my_mentions) * 100;
    ELSE
        v_reciprocity := 0;
    END IF;
    v_reciprocity := LEAST(v_reciprocity, 100);
    
    -- =====================================================
    -- 3. IMPACTO GERADO (25%)
    -- =====================================================
    
    -- Pessoas únicas destacadas
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_people_highlighted
    FROM posts
    WHERE user_id = p_user_id
    AND mentioned_user_id IS NOT NULL;
    
    -- IDs dos posts do usuário
    SELECT ARRAY_AGG(id) INTO v_post_ids
    FROM posts
    WHERE user_id = p_user_id;
    
    -- Reações geradas nos posts do usuário
    IF v_post_ids IS NOT NULL AND array_length(v_post_ids, 1) > 0 THEN
        SELECT COUNT(*) INTO v_reactions_generated
        FROM reactions
        WHERE post_id = ANY(v_post_ids);
    END IF;
    
    -- Correntes criadas
    SELECT COUNT(*) INTO v_chains_created
    FROM chains
    WHERE creator_id = p_user_id;
    
    -- Participantes nas correntes do usuário
    IF v_chains_created > 0 THEN
        SELECT COUNT(DISTINCT cp.user_id) INTO v_chain_participants
        FROM chain_posts cp
        INNER JOIN chains c ON cp.chain_id = c.id
        WHERE c.creator_id = p_user_id
        AND cp.user_id != p_user_id;
    END IF;
    
    -- Calcular impacto (normalizado 0-100)
    v_impact := (
        (LEAST(v_people_highlighted, 20)::DECIMAL / 20 * 100 * 0.30) +
        (LEAST(v_reactions_generated, 100)::DECIMAL / 100 * 100 * 0.25) +
        (LEAST(v_chains_created, 10)::DECIMAL / 10 * 100 * 0.20) +
        (LEAST(v_chain_participants, 20)::DECIMAL / 20 * 100 * 0.25)
    );
    v_impact := LEAST(v_impact, 100);
    
    -- =====================================================
    -- 4. EVOLUÇÃO DO ENGAJAMENTO (20%)
    -- =====================================================
    
    -- Streak atual
    SELECT COALESCE(current_streak, 0) INTO v_streak
    FROM user_streaks
    WHERE user_id = p_user_id;
    
    -- Meses ativos na plataforma
    SELECT created_at INTO v_user_created_at
    FROM profiles
    WHERE id = p_user_id;
    
    IF v_user_created_at IS NOT NULL THEN
        v_months_active := EXTRACT(MONTH FROM AGE(NOW(), v_user_created_at))::INTEGER +
                          (EXTRACT(YEAR FROM AGE(NOW(), v_user_created_at))::INTEGER * 12);
        v_days_active := EXTRACT(DAY FROM AGE(NOW(), v_user_created_at))::INTEGER +
                        (v_months_active * 30);
    END IF;
    
    -- Calcular evolução (normalizado 0-100)
    v_evolution := (
        (LEAST(v_streak, 30)::DECIMAL / 30 * 100 * 0.50) + -- Streak até 30 dias
        (LEAST(v_months_active, 12)::DECIMAL / 12 * 100 * 0.50) -- Tempo na plataforma até 12 meses
    );
    v_evolution := LEAST(v_evolution, 100);
    
    -- =====================================================
    -- 5. FATORES DE AJUSTE
    -- =====================================================
    
    -- Fator Tempo: valoriza usuários ativos há mais tempo (máx +20%)
    v_time_factor := LEAST(1.2, 1 + (v_months_active::DECIMAL / 100));
    
    -- Fator Consistência: premia streak (máx +10%)
    v_consistency_factor := LEAST(1.1, 1 + (v_streak::DECIMAL / 365 * 0.1));
    
    -- =====================================================
    -- 6. CÁLCULO FINAL DO ÍNDICE
    -- =====================================================
    
    v_index := (
        (v_positivity * 0.30) +
        (v_reciprocity * 0.25) +
        (v_impact * 0.25) +
        (v_evolution * 0.20)
    ) * v_time_factor * v_consistency_factor;
    
    -- Limitar a 100
    v_index := LEAST(v_index, 100);
    
    -- =====================================================
    -- 7. DETERMINAR NÍVEL
    -- =====================================================
    
    IF v_index >= 86 THEN
        v_level := 'Sustentando';
        v_emoji := '☀️';
        v_next_level := NULL;
        v_next_emoji := NULL;
        v_points_to_next := 0;
        v_level_min := 86;
        v_level_max := 100;
    ELSIF v_index >= 71 THEN
        v_level := 'Pertencendo';
        v_emoji := '🏠';
        v_next_level := 'Sustentando';
        v_next_emoji := '☀️';
        v_points_to_next := 86 - v_index::INTEGER;
        v_level_min := 71;
        v_level_max := 85;
    ELSIF v_index >= 51 THEN
        v_level := 'Fortalecendo';
        v_emoji := '💪';
        v_next_level := 'Pertencendo';
        v_next_emoji := '🏠';
        v_points_to_next := 71 - v_index::INTEGER;
        v_level_min := 51;
        v_level_max := 70;
    ELSIF v_index >= 31 THEN
        v_level := 'Contribuindo';
        v_emoji := '🤝';
        v_next_level := 'Fortalecendo';
        v_next_emoji := '💪';
        v_points_to_next := 51 - v_index::INTEGER;
        v_level_min := 31;
        v_level_max := 50;
    ELSIF v_index >= 16 THEN
        v_level := 'Participando';
        v_emoji := '👋';
        v_next_level := 'Contribuindo';
        v_next_emoji := '🤝';
        v_points_to_next := 31 - v_index::INTEGER;
        v_level_min := 16;
        v_level_max := 30;
    ELSE
        v_level := 'Observando';
        v_emoji := '👁️';
        v_next_level := 'Participando';
        v_next_emoji := '👋';
        v_points_to_next := 16 - v_index::INTEGER;
        v_level_min := 0;
        v_level_max := 15;
    END IF;
    
    -- =====================================================
    -- 8. RETORNAR RESULTADO
    -- =====================================================
    
    RETURN json_build_object(
        'index', ROUND(v_index, 1),
        'level', v_level,
        'emoji', v_emoji,
        'next_level', v_next_level,
        'next_emoji', v_next_emoji,
        'points_to_next', GREATEST(v_points_to_next, 0),
        'level_min', v_level_min,
        'level_max', v_level_max,
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
            'chains_created', v_chains_created,
            'chain_participants', v_chain_participants,
            'streak', v_streak,
            'months_active', v_months_active,
            'time_factor', ROUND(v_time_factor, 2),
            'consistency_factor', ROUND(v_consistency_factor, 2)
        )
    );
END;
$$;

-- Conceder permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION calculate_holospot_index(UUID) TO authenticated;
