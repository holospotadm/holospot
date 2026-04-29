-- ARQUIVO CANÔNICO: 03_fix_memorias_vivas_feed.sql
-- Cópia de: fix_feed_memorias_vivas_v1.sql
-- Fix: popular community_id nos posts da chain Memórias Vivas.

-- ============================================================================
-- FIX: Feed Memórias Vivas vazio
-- Versão: v1
-- Data: 2026-04-28
-- Autor: Manus (executor) / Gui Dutra (PO)
-- Commit: (a ser gerado)
-- ============================================================================
-- 
-- DIAGNÓSTICO:
-- A função get_community_feed busca posts por WHERE p.community_id = p_community_id.
-- Os 3 posts da chain "O conselho que eu carrego até hoje" (is_memorias_vivas = true)
-- foram inseridos pelo seed v8 com community_id = NULL, pois a comunidade memorias-vivas
-- ainda não existia naquele momento (foi criada pelo fix_pos_seed_v8_v2.sql).
--
-- SOLUÇÃO (Opção A): Atualizar community_id dos 3 posts para o ID da comunidade MV.
-- Isso faz com que os posts apareçam no feed da comunidade E continuem na corrente.
-- Não há duplicação — o mesmo post tem chain_id E community_id preenchidos.
--
-- EXECUÇÃO: Já executado via exec_sql (SECURITY DEFINER, bypass RLS).
-- Este script é a documentação do fix para versionamento no GitHub.
-- ============================================================================

-- Atualizar community_id dos posts da chain Memórias Vivas
UPDATE public.posts
SET community_id = (
    SELECT id FROM public.communities WHERE slug = 'memorias-vivas' LIMIT 1
)
WHERE chain_id IN (
    SELECT id FROM public.chains WHERE is_memorias_vivas = true
)
AND community_id IS NULL;

-- Validação
DO $$
DECLARE
    v_mv_id UUID;
    v_count INTEGER;
BEGIN
    SELECT id INTO v_mv_id FROM public.communities WHERE slug = 'memorias-vivas';
    
    SELECT COUNT(*) INTO v_count
    FROM public.posts
    WHERE chain_id IN (SELECT id FROM public.chains WHERE is_memorias_vivas = true)
    AND community_id = v_mv_id;
    
    IF v_count = 3 THEN
        RAISE NOTICE '✅ Fix OK — 3 posts da chain MV agora têm community_id = %', v_mv_id;
    ELSE
        RAISE EXCEPTION '❌ Fix FALHOU — esperado 3 posts, encontrado %', v_count;
    END IF;
END $$;
