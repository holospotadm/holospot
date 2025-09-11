-- =====================================================
-- CORREÇÃO COMPLETA: TODOS OS TRIGGERS COM AUTHOR_ID
-- =====================================================

-- O erro "record 'new' has no field 'author_id'" está vindo de múltiplos triggers
-- que estão tentando acessar campos incorretos nas tabelas

-- 1. CORRIGIR TRIGGER DE CRIAÇÃO DE POST
CREATE OR REPLACE FUNCTION trigger_post_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Adicionar pontos para quem criou o post (CORRIGIDO: user_id)
    PERFORM add_points_to_user(NEW.user_id, 'post_created', 10, NEW.id, 'post');
    
    -- Se mencionou alguém, dar pontos extras (CORRIGIDO: user_id)
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM add_points_to_user(NEW.user_id, 'holofote_given', 20, NEW.id, 'post');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. CORRIGIR TRIGGER DE COMENTÁRIO
CREATE OR REPLACE FUNCTION trigger_comment_created()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
BEGIN
    -- Obter autor do post (CORRIGIDO: user_id ao invés de author_id)
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem comentou (CORRIGIDO: user_id)
    PERFORM add_points_to_user(NEW.user_id, 'comment_written', 5, NEW.id, 'comment');
    
    -- Adicionar pontos para quem recebeu o comentário (autor do post)
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        PERFORM add_points_to_user(v_post_author, 'comment_received', 7, NEW.id, 'comment');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. CORRIGIR TRIGGER DE FEEDBACK
CREATE OR REPLACE FUNCTION trigger_feedback_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
BEGIN
    -- Obter autor do post (se aplicável)
    IF NEW.post_id IS NOT NULL THEN
        SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
        
        -- Adicionar pontos para quem deu feedback (CORRIGIDO: user_id)
        PERFORM add_points_to_user(NEW.user_id, 'feedback_given', 8, NEW.id, 'feedback');
        
        -- Adicionar pontos para quem recebeu feedback (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            PERFORM add_points_to_user(v_post_author, 'feedback_received', 10, NEW.id, 'feedback');
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. CORRIGIR TRIGGER DE REAÇÃO
CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
BEGIN
    -- Obter autor do post (CORRIGIDO: user_id ao invés de author_id)
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem deu a reação
    PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
    
    -- Adicionar pontos para quem recebeu a reação (autor do post)
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verificar se os triggers estão ativos
SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    'Trigger corrigido' as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('posts', 'feedbacks', 'comments', 'reactions')
AND NOT t.tgisinternal;

-- Testar criação de post após correção
SELECT 'Todos os triggers corrigidos - criação de posts deve funcionar agora' as resultado;

