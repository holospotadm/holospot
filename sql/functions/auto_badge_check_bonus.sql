-- ============================================================================
-- FUNÇÃO: auto_badge_check_bonus
-- ============================================================================

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
        BEGIN  -- Bloco de exceção para cada badge
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
            v_user_value := 0;  -- Valor padrão
            
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
                    SELECT COALESCE(MAX(participant_count), 0) INTO v_user_value
                    FROM (
                        SELECT get_chain_participants_count(id) AS participant_count
                        FROM chains
                        WHERE creator_id = p_user_id
                    ) AS chain_counts;
                WHEN 'chain_depth' THEN
                    v_user_value := COALESCE(get_user_participation_depth(p_user_id), 0);
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
                
                -- Criar notificação (CORRIGIDO: apenas colunas que existem)
                INSERT INTO notifications (user_id, type, message)
                VALUES (
                    p_user_id,
                    'badge_earned',
                    '🏆 Novo Badge Conquistado! ' || v_badge.name || ' - Você ganhou ' || v_badge.points_required || ' pontos bônus!'
                );
                
                RAISE NOTICE '🏆 Badge concedido: % para usuário %', v_badge.name, p_user_id;
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Log do erro mas continua processando outros badges
                RAISE NOTICE '⚠️ Erro ao verificar badge %: %', v_badge.name, SQLERRM;
                CONTINUE;
        END;
    END LOOP;
END;
$function$

