-- ============================================================
-- HoloSpot: Validação do Seed v7
-- Execute APÓS o seed principal ter sido executado com sucesso
-- ============================================================

SELECT
    tabela,
    total,
    esperado,
    CASE WHEN total = esperado THEN 'OK ✓'
         ELSE 'ERRO ✗ — esperado ' || esperado || ', encontrado ' || total
    END AS status
FROM (
    SELECT 'profiles_seed' AS tabela, COUNT(*)::int AS total, 20 AS esperado
    FROM public.profiles WHERE email LIKE '%@seed.holospot.com'
    UNION ALL
    SELECT 'comunidades', COUNT(*)::int, 3 FROM public.communities
    UNION ALL
    SELECT 'follows', COUNT(*)::int, 135 FROM public.follows
    UNION ALL
    SELECT 'posts_total', COUNT(*)::int, 82 FROM public.posts
    UNION ALL
    SELECT 'chains', COUNT(*)::int, 4 FROM public.chains
    UNION ALL
    SELECT 'reactions', COUNT(*)::int, 504 FROM public.reactions
    UNION ALL
    SELECT 'comments', COUNT(*)::int, 163 FROM public.comments
    UNION ALL
    SELECT 'feedbacks', COUNT(*)::int, 71 FROM public.feedbacks
    UNION ALL
    SELECT 'notificacoes_residuais', COUNT(*)::int, 0
    FROM public.notifications
    WHERE created_at >= '2026-03-16'
      AND user_id != (SELECT id FROM auth.users WHERE email = 'guilherme.dutra@b11c.com')
    UNION ALL
    SELECT 'posts_comunidade_ok', COUNT(*)::int, 31
    FROM public.posts WHERE community_id IS NOT NULL
) AS resultado
ORDER BY tabela;