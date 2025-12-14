-- ============================================================================
-- DEBUG: Verificar dados de correntes e posts
-- ============================================================================
-- Execute este script no Supabase SQL Editor para verificar o estado das correntes
-- ============================================================================

-- 1. Listar todas as correntes
SELECT 
    id,
    name,
    status,
    creator_id,
    first_post_id,
    created_at
FROM chains
ORDER BY created_at DESC
LIMIT 10;

-- 2. Listar posts com chain_id
SELECT 
    id,
    user_id,
    chain_id,
    type,
    highlight_type,
    created_at
FROM posts
WHERE chain_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 3. Listar registros em chain_posts
SELECT 
    cp.id,
    cp.chain_id,
    cp.post_id,
    cp.author_id,
    cp.parent_post_author_id,
    cp.created_at,
    c.name as chain_name,
    p.id as post_exists
FROM chain_posts cp
LEFT JOIN chains c ON c.id = cp.chain_id
LEFT JOIN posts p ON p.id = cp.post_id
ORDER BY cp.created_at DESC
LIMIT 10;

-- 4. Contar posts por corrente (mesma lógica de get_chain_info)
SELECT 
    c.id as chain_id,
    c.name as chain_name,
    c.status,
    COUNT(cp.id) as total_posts_in_chain_posts,
    COUNT(DISTINCT cp.author_id) as total_participants,
    (SELECT COUNT(*) FROM posts WHERE chain_id = c.id) as total_posts_with_chain_id
FROM chains c
LEFT JOIN chain_posts cp ON cp.chain_id = c.id
GROUP BY c.id, c.name, c.status
ORDER BY c.created_at DESC
LIMIT 10;

-- 5. Verificar se há posts com chain_id mas SEM registro em chain_posts (PROBLEMA!)
SELECT 
    p.id as post_id,
    p.chain_id,
    p.user_id,
    p.created_at,
    c.name as chain_name,
    CASE 
        WHEN cp.id IS NULL THEN '❌ NÃO ESTÁ EM chain_posts'
        ELSE '✅ Está em chain_posts'
    END as status
FROM posts p
LEFT JOIN chains c ON c.id = p.chain_id
LEFT JOIN chain_posts cp ON cp.post_id = p.id AND cp.chain_id = p.chain_id
WHERE p.chain_id IS NOT NULL
ORDER BY p.created_at DESC
LIMIT 20;

-- ============================================================================
-- RESULTADO ESPERADO:
-- - Todos os posts com chain_id devem ter registro em chain_posts
-- - Se algum post mostrar "❌ NÃO ESTÁ EM chain_posts", é o problema!
-- ============================================================================
