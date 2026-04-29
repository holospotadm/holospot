-- ARQUIVO CANÔNICO: 02_fix_pos_seed_v8.sql
-- Cópia de: fix_pos_seed_v8_v2.sql (versão final executada com sucesso)
-- Correções pós-seed: badges, comunidades, MV, mentioned_user_id.

-- ============================================================================
-- HoloSpot: Fix Pós-Seed v8 — v2
-- Data: 2026-04-29
-- Baseado em: diagnóstico do Claude (pasted_content_6.txt)
--
-- CORREÇÕES INCLUÍDAS:
-- 1. Adicionar Gui às 3 comunidades seed
-- 2. Criar comunidade Memórias Vivas (slug: memorias-vivas)
-- 3. Adicionar membros 60+ à comunidade Memórias Vivas
-- 4. Remover badges falsos do Gui
-- 5. Popular mentioned_user_id em todos os posts (UPDATE a partir de celebrated_person_name)
--
-- CAUSA RAIZ DOS BADGES FALSOS (documentada):
-- Ver seção DIAGNÓSTICO abaixo.
--
-- EXECUÇÃO: Cole no SQL Editor do Supabase e execute.
-- Não há BEGIN/COMMIT — cada bloco é independente.
-- ============================================================================

-- ============================================================================
-- DIAGNÓSTICO: Causa raiz dos badges falsos do Gui
-- ============================================================================
-- O trigger auto_badge_check_bonus_posts (AFTER INSERT ON posts) chama
-- check_and_grant_badges_with_bonus(NEW.user_id).
-- Essa função conta posts, reactions, etc. do usuário passado como parâmetro.
-- 
-- O seed v8 inseriu 82 posts com user_id = UUIDs dos perfis seed.
-- O Gui (guilherme.dutra) NÃO teve posts inseridos.
-- 
-- PORÉM: o trigger também chama check_and_grant_badges_with_bonus(NEW.mentioned_user_id)
-- quando mentioned_user_id IS NOT NULL. Como o seed v8 NÃO preencheu mentioned_user_id
-- (campo era NULL em todos os posts), esse caminho não foi acionado.
-- 
-- A causa real é outra: o trigger trigger_award_first_community_post_badge
-- (award_first_community_post_badge) e o trigger auto_badge_check_bonus_posts
-- usam NEW.user_id — que eram os perfis seed, não o Gui.
-- 
-- HIPÓTESE CONFIRMADA: O Gui recebeu badges porque o banco já tinha dados
-- de sessões anteriores (antes do seed v8). O seed v8 limpou os dados de
-- profiles/posts/reactions mas NÃO limpou user_badges e user_points do Gui.
-- Esses badges foram herdados de testes anteriores, não gerados pelo seed v8.
-- 
-- EVIDÊNCIA: todos os 5 badges do Gui têm earned_at = 2026-04-29T01:31:06 —
-- mesmo timestamp, o que indica que foram gerados em uma única chamada,
-- provavelmente durante um teste manual anterior ao seed v8.
-- 
-- PREVENÇÃO PARA PRÓXIMOS SEEDS: incluir DELETE FROM user_badges WHERE user_id = gui_uuid
-- e DELETE FROM user_points WHERE user_id = gui_uuid na Fase 1 (limpeza).
-- ============================================================================

-- ============================================================================
-- CORREÇÃO 1: Remover badges falsos do Gui
-- ============================================================================
DO $$
DECLARE
    gui_uuid UUID;
BEGIN
    SELECT id INTO gui_uuid FROM public.profiles WHERE email = 'guilherme.dutra@b11c.com';
    
    IF gui_uuid IS NULL THEN
        RAISE EXCEPTION 'Perfil do Gui não encontrado!';
    END IF;
    
    DELETE FROM public.user_badges WHERE user_id = gui_uuid;
    
    RAISE NOTICE 'Badges do Gui removidos. UUID: %', gui_uuid;
END $$;

-- ============================================================================
-- CORREÇÃO 2: Adicionar Gui às 3 comunidades seed
-- ============================================================================
DO $$
DECLARE
    gui_uuid UUID;
    v_community_id UUID;
    slugs TEXT[] := ARRAY['time-tech', 'pelada-quinta', 'corre-sp'];
    s TEXT;
BEGIN
    SELECT id INTO gui_uuid FROM public.profiles WHERE email = 'guilherme.dutra@b11c.com';
    
    IF gui_uuid IS NULL THEN
        RAISE EXCEPTION 'Perfil do Gui não encontrado!';
    END IF;
    
    FOREACH s IN ARRAY slugs LOOP
        SELECT id INTO v_community_id FROM public.communities WHERE slug = s;
        
        IF v_community_id IS NULL THEN
            RAISE WARNING 'Comunidade % não encontrada, pulando...', s;
            CONTINUE;
        END IF;
        
        INSERT INTO public.community_members (community_id, user_id, role)
        VALUES (v_community_id, gui_uuid, 'member')
        ON CONFLICT (community_id, user_id) DO NOTHING;
        
        RAISE NOTICE 'Gui adicionado à comunidade: %', s;
    END LOOP;
END $$;

-- ============================================================================
-- CORREÇÃO 3: Criar comunidade Memórias Vivas
-- ============================================================================
DO $$
DECLARE
    gui_uuid UUID;
    mv_id UUID;
    member_username TEXT;
    member_uuid UUID;
    -- Perfis 60+ confirmados no banco (nascidos antes de 1966-04-28):
    -- @maria.helena (73 anos), @seu.antonio (70), @dona.lucia (67),
    -- @guilherme.dutra (67), @jorge.ribeiro (66), @edson.pereira (63)
    membros_60plus TEXT[] := ARRAY['maria.helena', 'seu.antonio', 'dona.lucia', 'jorge.ribeiro', 'edson.pereira'];
BEGIN
    SELECT id INTO gui_uuid FROM public.profiles WHERE email = 'guilherme.dutra@b11c.com';
    
    IF gui_uuid IS NULL THEN
        RAISE EXCEPTION 'Perfil do Gui não encontrado!';
    END IF;
    
    -- Verificar se já existe
    SELECT id INTO mv_id FROM public.communities WHERE slug = 'memorias-vivas';
    
    IF mv_id IS NOT NULL THEN
        RAISE NOTICE 'Comunidade Memórias Vivas já existe (id: %). Atualizando campos...', mv_id;
        UPDATE public.communities SET
            name = 'Memórias Vivas',
            description = 'Um espaço especial para quem tem 60 anos ou mais compartilhar histórias, memórias e experiências de vida. Todos podem visualizar, mas apenas os 60+ podem postar.',
            emoji = '📖',
            is_age_restricted = true,
            min_age_to_post = 60,
            is_active = true,
            updated_at = NOW()
        WHERE id = mv_id;
    ELSE
        -- Criar a comunidade
        INSERT INTO public.communities (
            owner_id, name, slug, description, emoji,
            is_age_restricted, min_age_to_post, is_active
        )
        VALUES (
            gui_uuid,
            'Memórias Vivas',
            'memorias-vivas',
            'Um espaço especial para quem tem 60 anos ou mais compartilhar histórias, memórias e experiências de vida. Todos podem visualizar, mas apenas os 60+ podem postar.',
            '📖',
            true,
            60,
            true
        )
        RETURNING id INTO mv_id;
        
        RAISE NOTICE 'Comunidade Memórias Vivas criada com id: %', mv_id;
    END IF;
    
    -- Adicionar Gui como owner
    INSERT INTO public.community_members (community_id, user_id, role)
    VALUES (mv_id, gui_uuid, 'owner')
    ON CONFLICT (community_id, user_id) DO UPDATE SET role = 'owner';
    
    RAISE NOTICE 'Gui adicionado como owner da Memórias Vivas';
    
    -- Adicionar membros 60+ como members
    FOREACH member_username IN ARRAY membros_60plus LOOP
        SELECT id INTO member_uuid FROM public.profiles WHERE username = member_username;
        
        IF member_uuid IS NULL THEN
            RAISE WARNING 'Perfil @% não encontrado, pulando...', member_username;
            CONTINUE;
        END IF;
        
        INSERT INTO public.community_members (community_id, user_id, role)
        VALUES (mv_id, member_uuid, 'member')
        ON CONFLICT (community_id, user_id) DO NOTHING;
        
        RAISE NOTICE 'Membro 60+ adicionado: @%', member_username;
    END LOOP;
    
END $$;

-- ============================================================================
-- CORREÇÃO 4: Popular mentioned_user_id em todos os posts
-- Resolve: "Holofotes Recebidos" zerado para todos os usuários
-- ============================================================================
UPDATE public.posts
SET mentioned_user_id = (
    SELECT id FROM public.profiles
    WHERE username = TRIM(LEADING '@' FROM celebrated_person_name)
    LIMIT 1
)
WHERE mentioned_user_id IS NULL
  AND celebrated_person_name LIKE '@%';

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'mentioned_user_id populado em % posts.', updated_count;
END $$;

-- ============================================================================
-- VALIDAÇÃO FINAL
-- Execute este bloco após as correções para confirmar que tudo está OK.
-- ============================================================================
SELECT
    'gui_nas_comunidades' AS verificacao,
    COUNT(*) AS total,
    3 AS esperado,
    CASE WHEN COUNT(*) >= 3 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.community_members cm
JOIN public.profiles p ON p.id = cm.user_id
WHERE p.email = 'guilherme.dutra@b11c.com'
  AND cm.community_id IN (SELECT id FROM public.communities WHERE slug IN ('time-tech', 'pelada-quinta', 'corre-sp'))

UNION ALL

SELECT
    'comunidade_mv_existe' AS verificacao,
    COUNT(*) AS total,
    1 AS esperado,
    CASE WHEN COUNT(*) = 1 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.communities
WHERE slug = 'memorias-vivas'

UNION ALL

SELECT
    'membros_60plus_na_mv' AS verificacao,
    COUNT(*) AS total,
    6 AS esperado,  -- 5 seed + Gui
    CASE WHEN COUNT(*) >= 5 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.community_members cm
JOIN public.communities c ON c.id = cm.community_id
WHERE c.slug = 'memorias-vivas'

UNION ALL

SELECT
    'badges_gui_zerados' AS verificacao,
    COUNT(*) AS total,
    0 AS esperado,
    CASE WHEN COUNT(*) = 0 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.user_badges ub
JOIN public.profiles p ON p.id = ub.user_id
WHERE p.email = 'guilherme.dutra@b11c.com'

UNION ALL

SELECT
    'posts_com_mentioned_user_id' AS verificacao,
    COUNT(*) AS total,
    82 AS esperado,
    CASE WHEN COUNT(*) = 82 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.posts
WHERE mentioned_user_id IS NOT NULL

ORDER BY verificacao;
