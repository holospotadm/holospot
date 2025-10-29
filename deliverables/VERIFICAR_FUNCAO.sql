-- ============================================
-- SCRIPT DE VERIFICAÇÃO
-- Verifica se a função get_community_feed foi atualizada
-- ============================================

-- 1. Ver código atual da função
SELECT pg_get_functiondef('public.get_community_feed(uuid,uuid,integer,integer)'::regprocedure);

-- 2. Procurar por "FROM likes l" (versão correta)
-- Se retornar linhas, a função foi atualizada
SELECT 
    CASE 
        WHEN pg_get_functiondef('public.get_community_feed(uuid,uuid,integer,integer)'::regprocedure) LIKE '%FROM likes l%' 
        THEN '✅ Função ATUALIZADA (tem alias "l")'
        ELSE '❌ Função NÃO atualizada (sem alias "l")'
    END as status;

-- 3. Se não foi atualizada, forçar atualização
-- Copie e cole a função abaixo:

DROP FUNCTION IF EXISTS public.get_community_feed(uuid,uuid,integer,integer);

CREATE OR REPLACE FUNCTION public.get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    mentioned_user_id UUID,
    person_name TEXT,
    content TEXT,
    image_url TEXT,
    created_at TIMESTAMP,
    likes_count INTEGER,
    comments_count INTEGER,
    user_has_liked BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é membro
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    -- Retornar posts da comunidade
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.celebrated_person_name,
        p.mentioned_user_id,
        p.person_name,
        p.content,
        p.image_url,
        p.created_at,
        p.likes_count,
        p.comments_count,
        EXISTS(SELECT 1 FROM likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as user_has_liked
    FROM posts p
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$;

-- 4. Verificar novamente
SELECT 
    CASE 
        WHEN pg_get_functiondef('public.get_community_feed(uuid,uuid,integer,integer)'::regprocedure) LIKE '%FROM likes l%' 
        THEN '✅ Função ATUALIZADA com sucesso!'
        ELSE '❌ Ainda com problema'
    END as status_final;

