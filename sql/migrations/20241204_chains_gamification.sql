-- ============================================================================
-- MIGRATION: Chains Gamification (Badges e Pontuação)
-- ============================================================================
-- DESCRIÇÃO:
-- - Adiciona 8 novos badges relacionados a correntes
-- - Adiciona 2 novos action_types para pontuação
-- - Cria 4 funções de suporte para verificação de badges
-- - Atualiza função auto_badge_check_bonus para incluir badges de correntes
-- - Cria 2 triggers para verificação automática de badges
-- ============================================================================

-- ============================================================================
-- 1. INSERIR NOVOS BADGES
-- ============================================================================

-- Badges de Criação de Correntes
INSERT INTO badges (name, description, rarity, icon, points_required, condition_type, condition_value, category, is_active)
VALUES
    ('Iniciador', 'Crie sua primeira corrente', 'comum', '🔗', 50, 'chains_created', 1, 'correntes', true),
    ('Conector', 'Crie 5 correntes', 'raro', '⛓️', 150, 'chains_created', 5, 'correntes', true),
    ('Engrenagem', 'Crie 20 correntes', 'épico', '⚙️', 500, 'chains_created', 20, 'correntes', true),
    ('Corrente Viral', 'Crie uma corrente com 50 participantes', 'lendário', '🔥', 1000, 'chain_participants', 50, 'correntes', true)
ON CONFLICT (name) DO NOTHING;

-- Badges de Participação em Correntes
INSERT INTO badges (name, description, rarity, icon, points_required, condition_type, condition_value, category, is_active)
VALUES
    ('Elo', 'Participe da sua primeira corrente', 'comum', '🔗', 50, 'chains_participated', 1, 'correntes', true),
    ('Corrente Forte', 'Participe de 10 correntes', 'raro', '💪', 150, 'chains_participated', 10, 'correntes', true),
    ('Multiplicador', 'Participe de 50 correntes', 'épico', '📈', 500, 'chains_participated', 50, 'correntes', true),
    ('Elo Profundo', 'Participe de uma corrente em profundidade 10', 'lendário', '🌊', 1000, 'chain_depth', 10, 'correntes', true)
ON CONFLICT (name) DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ 8 badges de correntes inseridos';
END $$;

-- ============================================================================
-- 2. FUNÇÕES DE SUPORTE PARA BADGES
-- ============================================================================

-- 2.1. Contar correntes criadas por um usuário
CREATE OR REPLACE FUNCTION public.count_user_created_chains(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM chains
        WHERE creator_id = p_user_id
    );
END;
$function$;

COMMENT ON FUNCTION public.count_user_created_chains IS 'Conta quantas correntes um usuário criou';

-- 2.2. Contar participações em correntes de um usuário
CREATE OR REPLACE FUNCTION public.count_user_participated_chains(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT chain_id)
        FROM chain_posts
        WHERE user_id = p_user_id
    );
END;
$function$;

COMMENT ON FUNCTION public.count_user_participated_chains IS 'Conta em quantas correntes diferentes um usuário participou';

-- 2.3. Obter número de participantes de uma corrente
CREATE OR REPLACE FUNCTION public.get_chain_participants_count(p_chain_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT user_id)
        FROM chain_posts
        WHERE chain_id = p_chain_id
    );
END;
$function$;

COMMENT ON FUNCTION public.get_chain_participants_count IS 'Conta quantos participantes únicos uma corrente tem';

-- 2.4. Calcular profundidade máxima de participação de um usuário
CREATE OR REPLACE FUNCTION public.get_user_participation_depth(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_max_depth INTEGER := 0;
    v_chain_record RECORD;
    v_depth INTEGER;
BEGIN
    -- Para cada corrente que o usuário participou
    FOR v_chain_record IN 
        SELECT DISTINCT chain_id 
        FROM chain_posts 
        WHERE user_id = p_user_id
    LOOP
        -- Calcular profundidade nesta corrente
        WITH RECURSIVE chain_tree AS (
            -- Primeiro post (criador)
            SELECT 
                cp.post_id,
                cp.user_id,
                cp.parent_post_author_id,
                0 AS depth
            FROM chain_posts cp
            WHERE cp.chain_id = v_chain_record.chain_id
            AND cp.parent_post_author_id IS NULL
            
            UNION ALL
            
            -- Posts subsequentes
            SELECT 
                cp.post_id,
                cp.user_id,
                cp.parent_post_author_id,
                ct.depth + 1
            FROM chain_posts cp
            INNER JOIN chain_tree ct ON cp.parent_post_author_id = ct.user_id
            WHERE cp.chain_id = v_chain_record.chain_id
        )
        SELECT MAX(depth) INTO v_depth
        FROM chain_tree
        WHERE user_id = p_user_id;
        
        -- Atualizar profundidade máxima
        IF v_depth > v_max_depth THEN
            v_max_depth := v_depth;
        END IF;
    END LOOP;
    
    RETURN v_max_depth;
END;
$function$;

COMMENT ON FUNCTION public.get_user_participation_depth IS 'Calcula a profundidade máxima de participação de um usuário em correntes';

DO $$
BEGIN
    RAISE NOTICE '✅ 4 funções de suporte criadas';
END $$;

-- ============================================================================
-- 3. ATUALIZAR FUNÇÃO auto_badge_check_bonus
-- ============================================================================

-- Recriar função para incluir verificação de badges de correntes
CREATE OR REPLACE FUNCTION public.auto_badge_check_bonus(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_badge RECORD;
    v_user_value INTEGER;
    v_already_earned BOOLEAN;
BEGIN
    -- Iterar sobre todos os badges
    FOR v_badge IN 
        SELECT id, name, condition_type, condition_value, points_required 
        FROM badges 
        WHERE is_active = true
        ORDER BY condition_value ASC
    LOOP
        -- Verificar se usuário já ganhou este badge
        SELECT EXISTS(
            SELECT 1 FROM user_badges 
            WHERE user_id = p_user_id AND badge_id = v_badge.id
        ) INTO v_already_earned;
        
        -- Se já ganhou, pular
        IF v_already_earned THEN
            CONTINUE;
        END IF;
        
        -- Obter valor do usuário baseado no tipo de condição
        CASE v_badge.condition_type
            WHEN 'posts_count' THEN
                SELECT COUNT(*) INTO v_user_value FROM posts WHERE user_id = p_user_id;
            WHEN 'reactions_given' THEN
                SELECT COUNT(*) INTO v_user_value FROM reactions WHERE user_id = p_user_id;
            WHEN 'comments_given' THEN
                SELECT COUNT(*) INTO v_user_value FROM comments WHERE user_id = p_user_id;
            WHEN 'feedbacks_given' THEN
                SELECT COUNT(*) INTO v_user_value FROM feedbacks WHERE mentioned_user_id = p_user_id;
            WHEN 'holofotes_given' THEN
                SELECT COUNT(*) INTO v_user_value FROM posts WHERE user_id = p_user_id;
            WHEN 'streak_days' THEN
                SELECT COALESCE(current_streak, 0) INTO v_user_value FROM user_streaks WHERE user_id = p_user_id;
            WHEN 'chains_created' THEN
                v_user_value := count_user_created_chains(p_user_id);
            WHEN 'chains_participated' THEN
                v_user_value := count_user_participated_chains(p_user_id);
            WHEN 'chain_participants' THEN
                -- Para este badge, verificar se ALGUMA corrente do usuário tem X participantes
                SELECT MAX(participant_count) INTO v_user_value
                FROM (
                    SELECT get_chain_participants_count(id) AS participant_count
                    FROM chains
                    WHERE creator_id = p_user_id
                ) AS chain_counts;
                
                IF v_user_value IS NULL THEN
                    v_user_value := 0;
                END IF;
            WHEN 'chain_depth' THEN
                v_user_value := get_user_participation_depth(p_user_id);
            ELSE
                v_user_value := 0;
        END CASE;
        
        -- Verificar se usuário atingiu a condição
        IF v_user_value >= v_badge.condition_value THEN
            -- Conceder badge
            INSERT INTO user_badges (user_id, badge_id)
            VALUES (p_user_id, v_badge.id)
            ON CONFLICT DO NOTHING;
            
            -- Adicionar pontos bônus
            IF v_badge.points_required > 0 THEN
                INSERT INTO points_history (user_id, action_type, points_earned, reference_type, reference_id)
                VALUES (p_user_id, 'badge_earned', v_badge.points_required, 'badge', v_badge.id);
                
                -- Atualizar total de pontos
                PERFORM recalculate_user_points_secure(p_user_id);
            END IF;
            
            -- Criar notificação
            INSERT INTO notifications (user_id, type, title, message, reference_type, reference_id)
            VALUES (
                p_user_id,
                'badge_earned',
                'Novo Badge Conquistado! ' || v_badge.name,
                'Você ganhou o badge "' || v_badge.name || '" e ' || v_badge.points_required || ' pontos bônus!',
                'badge',
                v_badge.id
            );
            
            RAISE NOTICE '🏆 Badge concedido: % para usuário %', v_badge.name, p_user_id;
        END IF;
    END LOOP;
END;
$function$;

COMMENT ON FUNCTION public.auto_badge_check_bonus IS 'Verifica e concede badges automaticamente, incluindo badges de correntes';

DO $$
BEGIN
    RAISE NOTICE '✅ Função auto_badge_check_bonus atualizada';
END $$;

-- ============================================================================
-- 4. TRIGGERS PARA VERIFICAÇÃO AUTOMÁTICA DE BADGES
-- ============================================================================

-- 4.1. Trigger ao criar corrente
CREATE OR REPLACE FUNCTION public.check_chain_creation_badges()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Adicionar pontos por criar corrente
    INSERT INTO points_history (user_id, action_type, points_earned, reference_type, reference_id)
    VALUES (NEW.creator_id, 'chain_created', 25, 'chain', NEW.id);
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.creator_id);
    
    -- Verificar badges
    PERFORM auto_badge_check_bonus(NEW.creator_id);
    
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trigger_check_chain_creation_badges ON chains;
CREATE TRIGGER trigger_check_chain_creation_badges
    AFTER INSERT ON chains
    FOR EACH ROW
    EXECUTE FUNCTION check_chain_creation_badges();

COMMENT ON TRIGGER trigger_check_chain_creation_badges ON chains IS 'Adiciona pontos e verifica badges ao criar corrente';

-- 4.2. Trigger ao participar de corrente
CREATE OR REPLACE FUNCTION public.check_chain_participation_badges()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Adicionar pontos por participar de corrente
    INSERT INTO points_history (user_id, action_type, points_earned, reference_type, reference_id)
    VALUES (NEW.user_id, 'chain_participated', 15, 'chain_post', NEW.post_id);
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    
    -- Verificar badges
    PERFORM auto_badge_check_bonus(NEW.user_id);
    
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trigger_check_chain_participation_badges ON chain_posts;
CREATE TRIGGER trigger_check_chain_participation_badges
    AFTER INSERT ON chain_posts
    FOR EACH ROW
    EXECUTE FUNCTION check_chain_participation_badges();

COMMENT ON TRIGGER trigger_check_chain_participation_badges ON chain_posts IS 'Adiciona pontos e verifica badges ao participar de corrente';

DO $$
BEGIN
    RAISE NOTICE '✅ 2 triggers criados';
END $$;

-- ============================================================================
-- 5. PERMISSÕES
-- ============================================================================

-- Permitir usuários autenticados chamarem as funções
GRANT EXECUTE ON FUNCTION public.count_user_created_chains TO authenticated;
GRANT EXECUTE ON FUNCTION public.count_user_participated_chains TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_chain_participants_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_participation_depth TO authenticated;

DO $$
BEGIN
    RAISE NOTICE '✅ Permissões configuradas';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 FASE 6 CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '📊 8 badges de correntes adicionados';
    RAISE NOTICE '💰 2 action_types de pontuação: chain_created (25 pts), chain_participated (15 pts)';
    RAISE NOTICE '🔧 4 funções de suporte criadas';
    RAISE NOTICE '⚡ 2 triggers automáticos configurados';
    RAISE NOTICE '🏆 Sistema de gamificação de correntes 100% funcional!';
END $$;
