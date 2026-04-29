-- ============================================================================
-- HoloSpot: Fix Pós-Seed v8
-- Problemas 1, 3 e 6 do relatório pós-seed
-- Executar no Supabase SQL Editor
-- ============================================================================

BEGIN;

-- ============================================================================
-- PROBLEMA 6: Adicionar Gui às 3 comunidades do seed
-- O Gui não foi incluído no seed porque não é um perfil seed, mas deve
-- poder participar das comunidades como membro.
-- ============================================================================

DO $$
DECLARE
    gui_uuid UUID;
    comm_id UUID;
BEGIN
    -- Buscar UUID do Gui
    SELECT id INTO gui_uuid FROM public.profiles WHERE username = 'guilherme.dutra';
    
    IF gui_uuid IS NULL THEN
        RAISE EXCEPTION 'Perfil guilherme.dutra não encontrado';
    END IF;
    
    RAISE NOTICE 'Adicionando Gui (%) às comunidades...', gui_uuid;
    
    -- Adicionar às 3 comunidades como membro
    FOR comm_id IN SELECT id FROM public.communities WHERE slug IN ('time-tech', 'pelada-quinta', 'corre-sp')
    LOOP
        INSERT INTO public.community_members (community_id, user_id, role, joined_at)
        VALUES (comm_id, gui_uuid, 'member', now())
        ON CONFLICT (community_id, user_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Gui adicionado às 3 comunidades com sucesso';
END;
$$;

-- ============================================================================
-- PROBLEMA 3: Criar comunidade Memórias Vivas
-- O feed MV busca por slug 'memorias-vivas' na tabela communities.
-- Essa comunidade não foi criada no seed — só as chains MV foram criadas.
-- is_age_restricted = true e min_age_to_post = 60 (só 60+ podem postar)
-- Todos podem visualizar.
-- ============================================================================

DO $$
DECLARE
    gui_uuid UUID;
    mv_id UUID;
BEGIN
    SELECT id INTO gui_uuid FROM public.profiles WHERE username = 'guilherme.dutra';
    
    -- Verificar se já existe
    SELECT id INTO mv_id FROM public.communities WHERE slug = 'memorias-vivas';
    
    IF mv_id IS NOT NULL THEN
        RAISE NOTICE 'Comunidade Memórias Vivas já existe (id: %)', mv_id;
    ELSE
        INSERT INTO public.communities (
            name, slug, description, emoji, owner_id,
            is_active, is_age_restricted, min_age_to_post,
            allow_multiple_feedbacks, created_at
        )
        VALUES (
            'Memórias Vivas',
            'memorias-vivas',
            'Um espaço exclusivo para quem tem 60 anos ou mais compartilhar histórias, memórias e experiências de vida',
            '📖',
            gui_uuid,
            true,
            true,
            60,
            true,
            now()
        )
        RETURNING id INTO mv_id;
        
        RAISE NOTICE 'Comunidade Memórias Vivas criada (id: %)', mv_id;
    END IF;
    
    -- Adicionar o Gui como membro também
    INSERT INTO public.community_members (community_id, user_id, role, joined_at)
    VALUES (mv_id, gui_uuid, 'owner', now())
    ON CONFLICT (community_id, user_id) DO NOTHING;
    
    -- Adicionar os perfis seed com 60+ anos como membros
    -- (dona.lucia = 1948, helena.santos = 1950, roberto.carvalho = 1952)
    INSERT INTO public.community_members (community_id, user_id, role, joined_at)
    SELECT mv_id, id, 'member', now()
    FROM public.profiles
    WHERE username IN ('dona.lucia', 'helena.santos', 'roberto.carvalho')
    ON CONFLICT (community_id, user_id) DO NOTHING;
    
    RAISE NOTICE 'Membros do Memórias Vivas configurados';
END;
$$;

-- ============================================================================
-- PROBLEMA 1: Remover badges indevidos do Gui
-- Os badges foram concedidos durante o seed porque os triggers de gamificação
-- ficaram ativos. O Gui não realizou nenhuma ação real — os badges vieram
-- de atividade dos perfis seed que o mencionaram ou interagiram com seus posts.
-- Solução: limpar user_badges do Gui e deixar o sistema recalcular
-- naturalmente quando ele usar a plataforma de verdade.
-- ============================================================================

DO $$
DECLARE
    gui_uuid UUID;
    badges_removed INTEGER;
BEGIN
    SELECT id INTO gui_uuid FROM public.profiles WHERE username = 'guilherme.dutra';
    
    DELETE FROM public.user_badges WHERE user_id = gui_uuid;
    GET DIAGNOSTICS badges_removed = ROW_COUNT;
    
    RAISE NOTICE 'Removidos % badges indevidos do Gui', badges_removed;
END;
$$;

COMMIT;

-- ============================================================================
-- VALIDAÇÃO
-- ============================================================================

SELECT 'gui_nas_comunidades' AS item,
       COUNT(*) AS total,
       3 AS esperado,
       CASE WHEN COUNT(*) >= 3 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.community_members cm
JOIN public.profiles p ON p.id = cm.user_id
WHERE p.username = 'guilherme.dutra'

UNION ALL

SELECT 'memorias_vivas_existe' AS item,
       COUNT(*) AS total,
       1 AS esperado,
       CASE WHEN COUNT(*) = 1 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.communities
WHERE slug = 'memorias-vivas'

UNION ALL

SELECT 'badges_gui_zerados' AS item,
       COUNT(*) AS total,
       0 AS esperado,
       CASE WHEN COUNT(*) = 0 THEN 'OK ✓' ELSE 'FALHOU ✗' END AS status
FROM public.user_badges ub
JOIN public.profiles p ON p.id = ub.user_id
WHERE p.username = 'guilherme.dutra';
