-- ============================================================================
-- MIGRATION 008: CORREÇÃO DO BUG NO TRIGGER DE STREAK
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Corrigir erro "mentioned_user_id" em tabelas que não têm essa coluna
-- Bug: Função tentava acessar mentioned_user_id em reactions, posts, comments
-- ============================================================================

-- CORREÇÃO: Atualizar função de trigger para verificar se coluna existe
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Atualizar streak do usuário que fez a atividade
    PERFORM update_user_streak(NEW.user_id);
    
    -- Para feedbacks, também atualizar streak do usuário mencionado
    -- CORREÇÃO: Só tentar acessar mentioned_user_id se for tabela feedbacks
    IF TG_TABLE_NAME = 'feedbacks' THEN
        -- Verificar se mentioned_user_id existe e não é nulo
        IF NEW.mentioned_user_id IS NOT NULL THEN
            PERFORM update_user_streak(NEW.mentioned_user_id);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- ============================================================================
-- LOG E VALIDAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 008 CONCLUÍDA: Bug do trigger de streak corrigido';
    RAISE NOTICE '🔧 Função update_user_streak_trigger() atualizada';
    RAISE NOTICE '📋 Agora só acessa mentioned_user_id na tabela feedbacks';
    RAISE NOTICE '🚀 Reações devem funcionar normalmente agora!';
END $$;

