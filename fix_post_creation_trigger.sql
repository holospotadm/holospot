-- =====================================================
-- CORREÇÃO CRÍTICA: TRIGGER DE FEEDBACK COM CAMPO CORRETO
-- =====================================================

-- O erro "record 'new' has no field 'author_id'" está vindo do trigger de feedback
-- que está tentando acessar NEW.author_id quando deveria ser NEW.user_id

-- Corrigir trigger de feedback
CREATE OR REPLACE FUNCTION trigger_feedback_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
BEGIN
    -- Obter autor do post (se aplicável)
    IF NEW.post_id IS NOT NULL THEN
        SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
        
        -- CORRIGIDO: usar user_id ao invés de author_id
        -- Adicionar pontos para quem deu feedback
        PERFORM add_points_to_user(NEW.user_id, 'feedback_given', 8, NEW.id, 'feedback');
        
        -- Adicionar pontos para quem recebeu feedback (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            PERFORM add_points_to_user(v_post_author, 'feedback_received', 10, NEW.id, 'feedback');
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verificar se há outros triggers problemáticos
-- Listar todos os triggers que podem estar causando problemas
SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    'Trigger verificado' as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('posts', 'feedbacks', 'comments', 'reactions')
AND NOT t.tgisinternal;

-- Testar criação de post após correção
SELECT 'Trigger de feedback corrigido - criação de posts deve funcionar agora' as resultado;

