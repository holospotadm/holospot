-- Execute SEPARADAMENTE após o seed principal ter concluído com COMMIT.

-- VALIDAÇÃO FINAL (execute separadamente após o COMMIT)
-- Todas as colunas "ok" devem retornar TRUE
-- ============================================================================
SELECT
    tabela,
    total,
    esperado,
    CASE WHEN total = esperado THEN 'OK ✓' ELSE 'ERRO ✗' END AS status
FROM (
    SELECT 'profiles_seed'     AS tabela, COUNT(*) AS total, 20  AS esperado FROM public.profiles    WHERE email LIKE '%@seed.holospot.com'
    UNION ALL
    SELECT 'comunidades',                 COUNT(*),           3              FROM public.communities  WHERE owner_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'follows',                     COUNT(*),           135 FROM public.follows      WHERE follower_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'posts_total',                 COUNT(*),           82 FROM public.posts WHERE user_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'chains',                      COUNT(*),           4  FROM public.chains       WHERE creator_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'reactions',                   COUNT(*),           100 FROM public.reactions  WHERE user_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'comments',                    COUNT(*),           23 FROM public.comments   WHERE user_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'feedbacks',                   COUNT(*),           12 FROM public.feedbacks WHERE mentioned_user_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
    UNION ALL
    SELECT 'notificacoes_seed',           COUNT(*),           0              FROM public.notifications WHERE from_user_id IN (SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com')
) t
ORDER BY tabela;
