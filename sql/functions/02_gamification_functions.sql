-- ============================================================================
-- GAMIFICATION FUNCTIONS - Funções de Gamificação
-- ============================================================================
-- Funções responsáveis pelo sistema de badges e gamificação
-- Utilizadas pelos triggers de gamificação
-- ============================================================================

-- ============================================================================
-- AUTO_CHECK_BADGES_WITH_BONUS_AFTER_ACTION - Verificação Automática de Badges
-- ============================================================================
-- Função principal do sistema de gamificação
-- Verifica e concede badges automaticamente após ações do usuário
-- Inclui sistema de bonus por streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_check_badges_with_bonus_after_action()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    affected_user_id UUID;
    post_owner_id UUID;
    result_text TEXT;
BEGIN
    -- Determinar qual usuário foi afetado baseado na tabela e operação
    IF TG_TABLE_NAME = 'posts' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar usuário mencionado se houver
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'comments' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar dono do post
            SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
            IF post_owner_id IS NOT NULL AND post_owner_id != NEW.user_id THEN
                SELECT check_and_grant_badges_with_bonus(post_owner_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'feedbacks' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.author_id;
            -- Também verificar usuário mencionado
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'user_points' THEN
        IF TG_OP = 'UPDATE' THEN
            affected_user_id := NEW.user_id;
        END IF;
    END IF;
    
    -- Verificar badges para o usuário principal afetado
    IF affected_user_id IS NOT NULL THEN
        SELECT check_and_grant_badges_with_bonus(affected_user_id) INTO result_text;
        IF result_text != 'Nenhum badge novo concedido' THEN
            RAISE NOTICE 'Auto-check badges com bônus: %', result_text;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.auto_check_badges_with_bonus_after_action() IS 
'Função principal do sistema de gamificação.
Verifica automaticamente se usuários atingiram critérios para novos badges.
Inclui sistema de bonus por streaks e atividade consecutiva.
Utilizada por todos os triggers de gamificação.
Execução: AFTER INSERT/UPDATE
Segurança: SECURITY INVOKER
Volatilidade: VOLATILE';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES DE GAMIFICAÇÃO
-- ============================================================================
-- 
-- Função Dependente: check_and_grant_badges_with_bonus()
-- - Esta função chama check_and_grant_badges_with_bonus() que deve existir
-- - Responsável pela lógica específica de verificação de badges
-- - Inclui sistema de bonus por streaks
-- 
-- Lógica de Funcionamento:
-- 1. Identifica qual usuário foi afetado pela ação
-- 2. Determina o tipo de ação (post, comment, reaction, feedback, points)
-- 3. Verifica usuários adicionais (mencionados, donos de posts)
-- 4. Chama função de verificação de badges para cada usuário
-- 5. Registra logs de badges concedidos
-- 
-- Ações Monitoradas:
-- - posts: Criação de holofotes (user_id + mentioned_user_id)
-- - reactions: Criação de reações (user_id)
-- - comments: Criação de comentários (user_id + post owner)
-- - feedbacks: Criação de feedbacks (author_id + mentioned_user_id)
-- - user_points: Atualização de pontos (user_id)
-- 
-- Sistema de Bonus:
-- - Multiplicadores por tipo de ação
-- - Bonus por streaks consecutivos
-- - Bonus por milestones de atividade
-- - Aplicação automática baseada em histórico
-- 
-- Triggers que Utilizam:
-- - auto_badge_check_bonus_posts
-- - auto_badge_check_bonus_comments
-- - auto_badge_check_bonus_reactions
-- - auto_badge_check_bonus_feedbacks
-- - auto_badge_check_bonus_user_points
-- 
-- Performance:
-- - Executa apenas quando necessário
-- - Evita verificações desnecessárias
-- - Logs controlados para debugging
-- - Otimizada para múltiplos usuários por ação
-- 
-- ============================================================================

