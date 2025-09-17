-- ============================================================================
-- SECURITY FUNCTIONS - Funções de Segurança e Integridade
-- ============================================================================
-- Funções responsáveis por operações seguras, validações e gerenciamento de pontos
-- Sistema integrado de pontuação com prevenção de fraudes
-- ============================================================================

-- ============================================================================
-- POST SECURITY - Inserção Segura de Posts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_post_insert_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    mentioned_user_id UUID;
BEGIN
    -- Adicionar pontos para quem criou o post (10 pontos)
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.user_id, 'post_created', 10,
        'post', NEW.id, NOW()
    );
    
    -- Se há usuário mencionado, adicionar pontos para ele também (5 pontos)
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            NEW.mentioned_user_id, 'mentioned_in_post', 5,
            'post', NEW.id, NOW()
        );
        
        -- Atualizar total do usuário mencionado
        PERFORM update_user_total_points(NEW.mentioned_user_id);
    END IF;
    
    -- Atualizar total do autor
    PERFORM update_user_total_points(NEW.user_id);
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMMENT SECURITY - Operações Seguras de Comentários
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_insert_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem comentou (5 pontos)
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.user_id, 'comment_created', 5,
        'comment', NEW.id, NOW()
    );
    
    -- Adicionar pontos para autor do post (3 pontos) se não for ele mesmo
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            post_author_id, 'comment_received', 3,
            'comment', NEW.id, NOW()
        );
        
        -- Atualizar total do autor do post
        PERFORM update_user_total_points(post_author_id);
    END IF;
    
    -- Atualizar total de quem comentou
    PERFORM update_user_total_points(NEW.user_id);
    
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_comment_delete_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO comentário: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Usar função SECURITY DEFINER para deletar pontos
    PERFORM delete_comment_points_secure(OLD.id);
    
    -- Recalcular pontos para quem comentou
    PERFORM recalculate_user_points_secure(OLD.user_id);
    
    -- Recalcular pontos para o dono do post (se diferente)
    IF post_owner_id IS NOT NULL AND post_owner_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_owner_id);
    END IF;
    
    RAISE NOTICE 'DELEÇÃO CONCLUÍDA com sucesso';
    RETURN OLD;
END;
$function$;

-- ============================================================================
-- REACTION SECURITY - Operações Seguras de Reações
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_insert_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Quem reagiu ganha 3 pontos
    PERFORM add_points_secure(
        NEW.user_id, 3, 'reaction_given', NEW.id, 'reaction', NEW.post_id, NEW.type
    );
    
    -- Dono do post ganha 2 pontos (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_secure(
            post_author_id, 2, 'reaction_received', NEW.id, 'reaction', NEW.post_id, NEW.type
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_reaction_delete_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO reação: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Usar função SECURITY DEFINER para deletar pontos
    PERFORM delete_reaction_points_secure(OLD.id);
    
    -- Recalcular pontos para quem reagiu
    PERFORM recalculate_user_points_secure(OLD.user_id);
    
    -- Recalcular pontos para o dono do post (se diferente)
    IF post_owner_id IS NOT NULL AND post_owner_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_owner_id);
    END IF;
    
    RAISE NOTICE 'DELEÇÃO CONCLUÍDA com sucesso';
    RETURN OLD;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_reaction_points_simple()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem reagiu (3 pontos) - CAST CORRETO
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.user_id, 'reaction_given', 3,
        'reaction', NEW.id::text::uuid, NOW()
    );
    
    -- Adicionar pontos para autor do post (2 pontos) se não for ele mesmo - CAST CORRETO
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            post_author_id, 'reaction_received', 2,
            'reaction', NEW.id::text::uuid, NOW()
        );
    END IF;
    
    -- Atualizar totais
    PERFORM update_user_total_points(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM update_user_total_points(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- FEEDBACK SECURITY - Inserção Segura de Feedbacks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_insert_secure()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    -- Adicionar pontos para quem deu feedback (8 pontos)
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.author_id, 'feedback_given', 8,
        'feedback', NEW.id, NOW()
    );
    
    -- Adicionar pontos para quem recebeu feedback (5 pontos) se não for ele mesmo
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.author_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            NEW.mentioned_user_id, 'feedback_received', 5,
            'feedback', NEW.id, NOW()
        );
        
        -- Atualizar total de quem recebeu
        PERFORM update_user_total_points(NEW.mentioned_user_id);
    END IF;
    
    -- Atualizar total de quem deu feedback
    PERFORM update_user_total_points(NEW.author_id);
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.handle_post_insert_secure() IS 
'Gerencia pontos de forma segura na criação de posts.
Autor: +10 pontos, Mencionado: +5 pontos.';

COMMENT ON FUNCTION public.handle_comment_insert_secure() IS 
'Gerencia pontos de forma segura na criação de comentários.
Autor comentário: +5 pontos, Autor post: +3 pontos.';

COMMENT ON FUNCTION public.handle_comment_delete_secure() IS 
'Remove pontos de forma segura na deleção de comentários.
Utiliza funções SECURITY DEFINER para operações críticas.';

COMMENT ON FUNCTION public.handle_reaction_insert_secure() IS 
'Gerencia pontos de forma segura na criação de reações.
Quem reage: +3 pontos, Autor post: +2 pontos.';

COMMENT ON FUNCTION public.handle_reaction_delete_secure() IS 
'Remove pontos de forma segura na deleção de reações.
Utiliza funções SECURITY DEFINER para operações críticas.';

COMMENT ON FUNCTION public.handle_reaction_points_simple() IS 
'Versão simplificada de gerenciamento de pontos para reações.
Inclui cast correto para UUID.';

COMMENT ON FUNCTION public.handle_feedback_insert_secure() IS 
'Gerencia pontos de forma segura na criação de feedbacks.
Quem dá: +8 pontos, Quem recebe: +5 pontos.';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES DE SEGURANÇA
-- ============================================================================
-- 
-- Funções Dependentes (SECURITY DEFINER):
-- - add_points_secure(): Adiciona pontos com validações
-- - delete_comment_points_secure(): Remove pontos de comentários
-- - delete_reaction_points_secure(): Remove pontos de reações
-- - recalculate_user_points_secure(): Recalcula totais de usuários
-- - update_user_total_points(): Atualiza totais na tabela user_points
-- 
-- Sistema de Pontuação:
-- - post_created: +10 pontos (autor)
-- - mentioned_in_post: +5 pontos (mencionado)
-- - comment_created: +5 pontos (autor comentário)
-- - comment_received: +3 pontos (autor post)
-- - reaction_given: +3 pontos (quem reage)
-- - reaction_received: +2 pontos (autor post)
-- - feedback_given: +8 pontos (quem dá feedback)
-- - feedback_received: +5 pontos (quem recebe feedback)
-- 
-- Validações de Segurança:
-- - Prevenção de auto-pontuação em alguns casos
-- - Verificação de existência de usuários
-- - Validação de referências (posts, comments, etc.)
-- - Cast correto de tipos (UUID)
-- - Logs detalhados para debugging
-- 
-- Integridade de Dados:
-- - Transações atômicas
-- - Rollback automático em caso de erro
-- - Recálculo de totais após operações
-- - Manutenção de histórico completo
-- 
-- Performance:
-- - Operações otimizadas
-- - Índices apropriados nas consultas
-- - Evita operações desnecessárias
-- - Logs controlados
-- 
-- Auditoria:
-- - Registro completo em points_history
-- - Rastreabilidade de todas as operações
-- - Timestamps precisos
-- - Referências cruzadas mantidas
-- 
-- ============================================================================

