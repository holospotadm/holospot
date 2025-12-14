-- ============================================================================
-- FIX: Inserir posts faltantes em chain_posts
-- ============================================================================
-- PROBLEMA: Posts foram criados com chain_id mas não foram inseridos em chain_posts
-- CAUSA: Função add_post_to_chain falhou silenciosamente ou não foi chamada
-- SOLUÇÃO: Inserir posts faltantes e atualizar status das correntes
-- ============================================================================

-- PASSO 1: Inserir posts faltantes em chain_posts
INSERT INTO public.chain_posts (
    chain_id,
    post_id,
    author_id,
    parent_post_author_id
)
SELECT 
    p.chain_id,
    p.id as post_id,
    p.user_id as author_id,
    NULL as parent_post_author_id  -- NULL = primeiro post (criador)
FROM public.posts p
WHERE p.chain_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM public.chain_posts cp
      WHERE cp.post_id = p.id AND cp.chain_id = p.chain_id
  );

-- PASSO 2: Atualizar correntes para status 'active' se tiverem posts
UPDATE public.chains c
SET 
    status = 'active',
    start_date = COALESCE(start_date, NOW()),
    first_post_id = COALESCE(first_post_id, (
        SELECT post_id 
        FROM public.chain_posts 
        WHERE chain_id = c.id 
        ORDER BY created_at ASC 
        LIMIT 1
    ))
WHERE c.status = 'pending'
  AND EXISTS (
      SELECT 1 FROM public.chain_posts cp
      WHERE cp.chain_id = c.id
  );

-- PASSO 3: Verificar resultado
DO $$
DECLARE
    v_total_fixed INTEGER;
    v_total_chains_activated INTEGER;
BEGIN
    -- Contar posts que foram corrigidos
    SELECT COUNT(*)
    INTO v_total_fixed
    FROM public.posts p
    WHERE p.chain_id IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM public.chain_posts cp
          WHERE cp.post_id = p.id AND cp.chain_id = p.chain_id
      );
    
    -- Contar correntes ativadas
    SELECT COUNT(*)
    INTO v_total_chains_activated
    FROM public.chains
    WHERE status = 'active';
    
    RAISE NOTICE '✅ Total de posts em chain_posts: %', v_total_fixed;
    RAISE NOTICE '✅ Total de correntes ativas: %', v_total_chains_activated;
END $$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON TABLE public.chain_posts IS 
'Registros de posts vinculados a correntes (CORRIGIDO: posts faltantes inseridos)';

-- ✅ Posts faltantes inseridos
-- ✅ Correntes ativadas
-- ✅ Contagem agora vai funcionar corretamente
