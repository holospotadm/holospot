-- ============================================================================
-- HOLOSPOT SEED DATA v4.0
-- Gerado em: 2026-04-28
-- Timeline simulada: 2026-03-16 a 2026-04-05 (3 semanas)
--
-- INSTRUÇÕES:
--   1. Execute o bloco principal (BEGIN ... COMMIT) no Supabase SQL Editor
--   2. Aguarde a conclusão (pode levar 30-60 segundos)
--   3. Execute o bloco de VALIDAÇÃO no final para confirmar os resultados
--
-- SEGURANÇA:
--   - Perfis reais (não @seed.holospot.com) são preservados
--   - Triggers de notificação são desabilitados durante o seed
--   - Triggers de gamificação permanecem ativos (pontos/badges/streaks)
-- ============================================================================

BEGIN;

-- ============================================================================
-- FASE 0: VERIFICAÇÃO DO PERFIL DO GUI
-- Exibe quantos perfis reais existem antes de qualquer limpeza
-- ============================================================================
DO $$
DECLARE
    gui_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO gui_count
    FROM public.profiles
    WHERE email NOT LIKE '%@seed.holospot.com';
    RAISE NOTICE '>>> Perfis reais encontrados (serão preservados): %', gui_count;
END $$;

-- ============================================================================
-- FASE 1: LIMPEZA DA BASE
-- Remove apenas dados com email @seed.holospot.com. Perfis reais intocados.
-- ============================================================================
CREATE TEMP TABLE IF NOT EXISTS _seed_cleanup_ids AS
SELECT id FROM public.profiles WHERE email LIKE '%@seed.holospot.com';

DELETE FROM public.notifications
WHERE from_user_id IN (SELECT id FROM _seed_cleanup_ids)
   OR user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.feedbacks
WHERE author_id IN (SELECT id FROM _seed_cleanup_ids)
   OR mentioned_user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.comments
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.reactions
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.chain_posts
WHERE author_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.posts
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.chains
WHERE creator_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.community_members
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.communities
WHERE owner_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.follows
WHERE follower_id IN (SELECT id FROM _seed_cleanup_ids)
   OR following_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.user_points
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.user_badges
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.user_streaks
WHERE user_id IN (SELECT id FROM _seed_cleanup_ids);

DELETE FROM public.profiles WHERE email LIKE '%@seed.holospot.com';
DELETE FROM auth.users WHERE email LIKE '%@seed.holospot.com';

DROP TABLE IF EXISTS _seed_cleanup_ids;

DO $$ BEGIN RAISE NOTICE '>>> Fase 1 OK: base limpa, perfis reais preservados.'; END $$;

-- ============================================================================
-- FASE 2: MIGRATION — Adicionar coluna bio em profiles (se não existir)
-- ============================================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio text;

DO $$ BEGIN RAISE NOTICE '>>> Fase 2 OK: coluna bio garantida.'; END $$;

-- ============================================================================
-- FASE 3: INSERÇÃO DE USUÁRIOS (20 perfis seed)
-- Estratégia: INSERT direto em auth.users + public.profiles
-- O trigger handle_new_user é no-op por decisão de produto — não é modificado.
-- ============================================================================
CREATE TEMP TABLE _seed_users (
    username text PRIMARY KEY,
    user_id  uuid DEFAULT gen_random_uuid()
);

INSERT INTO _seed_users (username) VALUES
    ('rafael.mendes'),
    ('ju.rocha'),
    ('diego.design'),
    ('ricardo.alves'),
    ('dona.lucia'),
    ('seu.antonio'),
    ('vanessa.martins'),
    ('carlos.henrique'),
    ('ana.beatriz'),
    ('marcos.vinicius'),
    ('patricia.nunes'),
    ('thiago.costa'),
    ('fernanda.lima'),
    ('jorge.ribeiro'),
    ('camila.santos'),
    ('pedro.augusto'),
    ('maria.helena'),
    ('lucas.ferreira'),
    ('renata.campos'),
    ('edson.pereira');

INSERT INTO auth.users (
    id, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud
)
SELECT
    su.user_id,
    p.email,
    crypt('HoloSpot2026!', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    jsonb_build_object('username', p.username),
    false, 'authenticated', 'authenticated'
FROM _seed_users su
JOIN (VALUES
    ('rafael.mendes', 'rafael.mendes@seed.holospot.com'),
    ('ju.rocha', 'ju.rocha@seed.holospot.com'),
    ('diego.design', 'diego.oliveira@seed.holospot.com'),
    ('ricardo.alves', 'ricardo.alves@seed.holospot.com'),
    ('dona.lucia', 'lucia.santos@seed.holospot.com'),
    ('seu.antonio', 'antonio.ferreira@seed.holospot.com'),
    ('vanessa.martins', 'vanessa.martins@seed.holospot.com'),
    ('carlos.henrique', 'carlos.lima@seed.holospot.com'),
    ('ana.beatriz', 'ana.costa@seed.holospot.com'),
    ('marcos.vinicius', 'marcos.souza@seed.holospot.com'),
    ('patricia.nunes', 'patricia.nunes@seed.holospot.com'),
    ('thiago.costa', 'thiago.costa@seed.holospot.com'),
    ('fernanda.lima', 'fernanda.oliveira@seed.holospot.com'),
    ('jorge.ribeiro', 'jorge.ribeiro@seed.holospot.com'),
    ('camila.santos', 'camila.pereira@seed.holospot.com'),
    ('pedro.augusto', 'pedro.silva@seed.holospot.com'),
    ('maria.helena', 'maria.duarte@seed.holospot.com'),
    ('lucas.ferreira', 'lucas.ferreira@seed.holospot.com'),
    ('renata.campos', 'renata.campos@seed.holospot.com'),
    ('edson.pereira', 'edson.pereira@seed.holospot.com')
) AS p(username, email) ON su.username = p.username;

INSERT INTO public.profiles (
    id, username, name, email, bio, birth_date, timezone,
    has_completed_onboarding, community_owner, created_at, updated_at
)
SELECT
    su.user_id,
    p.username, p.name, p.email, p.bio,
    p.birth_date::date, p.timezone,
    true, p.community_owner,
    NOW(), NOW()
FROM _seed_users su
JOIN (VALUES
    ('rafael.mendes', 'Rafael Mendes', 'rafael.mendes@seed.holospot.com', 'Dev frontend, pai do Theo, corredor de fim de semana', '1991-07-14', 'America/Sao_Paulo', false),
    ('ju.rocha', 'Juliana Rocha', 'ju.rocha@seed.holospot.com', 'UX designer, mãe da Liz, tentando sobreviver ao home office', '1988-03-22', 'America/Sao_Paulo', false),
    ('diego.design', 'Diego Oliveira', 'diego.oliveira@seed.holospot.com', 'Designer visual, fotógrafo nas horas vagas', '1995-11-03', 'America/Sao_Paulo', false),
    ('ricardo.alves', 'Ricardo Alves', 'ricardo.alves@seed.holospot.com', 'Tech lead, corintiano sofredor, churrasqueiro oficial', '1985-09-08', 'America/Sao_Paulo', true),
    ('dona.lucia', 'Lúcia Maria Santos', 'lucia.santos@seed.holospot.com', 'Aposentada, avó de 4, adora cozinhar e contar histórias', '1958-05-30', 'America/Sao_Paulo', false),
    ('seu.antonio', 'Antônio Carlos Ferreira', 'antonio.ferreira@seed.holospot.com', 'Carpinteiro aposentado, palmeirense raiz, avô coruja', '1955-12-17', 'America/Sao_Paulo', false),
    ('vanessa.martins', 'Vanessa Martins', 'vanessa.martins@seed.holospot.com', 'Product manager, corredora, viciada em café especial', '1993-01-25', 'America/Sao_Paulo', false),
    ('carlos.henrique', 'Carlos Henrique Lima', 'carlos.lima@seed.holospot.com', 'Backend dev, pai de gêmeos, sobrevivente de deploy sexta à noite', '1990-04-11', 'America/Sao_Paulo', true),
    ('ana.beatriz', 'Ana Beatriz Costa', 'ana.costa@seed.holospot.com', 'Scrum master, mãe solo do Miguel, aprendendo a correr', '1987-08-19', 'America/Sao_Paulo', false),
    ('marcos.vinicius', 'Marcos Vinícius Souza', 'marcos.souza@seed.holospot.com', 'Gerente de projetos, triatleta, faz pão aos domingos', '1982-06-05', 'America/Sao_Paulo', true),
    ('patricia.nunes', 'Patrícia Nunes', 'patricia.nunes@seed.holospot.com', 'Professora de história, mãe da Clara e do Pedro, leitora compulsiva', '1979-02-14', 'America/Sao_Paulo', false),
    ('thiago.costa', 'Thiago Costa', 'thiago.costa@seed.holospot.com', 'Estagiário dev, estudante de CC, flamenguista convicto', '1997-10-28', 'America/Sao_Paulo', false),
    ('fernanda.lima', 'Fernanda Lima Oliveira', 'fernanda.oliveira@seed.holospot.com', 'Data analyst, cozinheira experimental, mãe de gato', '1992-12-01', 'America/Sao_Paulo', false),
    ('jorge.ribeiro', 'Jorge Ribeiro', 'jorge.ribeiro@seed.holospot.com', 'Engenheiro aposentado, avô do Bento, caminhante de parque', '1960-03-09', 'America/Sao_Paulo', false),
    ('camila.santos', 'Camila Santos Pereira', 'camila.pereira@seed.holospot.com', 'QA engineer, violonista amadora, corredora de 5k', '1994-07-22', 'America/Sao_Paulo', false),
    ('pedro.augusto', 'Pedro Augusto Silva', 'pedro.silva@seed.holospot.com', 'DevOps, pai da Sofia, vascaíno em terapia', '1986-11-15', 'America/Sao_Paulo', false),
    ('maria.helena', 'Maria Helena Duarte', 'maria.duarte@seed.holospot.com', 'Professora aposentada, poeta de gaveta, bisavó do Mateus', '1952-08-03', 'America/Sao_Paulo', false),
    ('lucas.ferreira', 'Lucas Ferreira Neto', 'lucas.ferreira@seed.holospot.com', 'Dev júnior, gamer nas horas vagas, aprendendo a cozinhar', '1998-05-20', 'America/Sao_Paulo', false),
    ('renata.campos', 'Renata Campos', 'renata.campos@seed.holospot.com', 'Engineering manager, maratonista, mãe do Davi', '1983-09-12', 'America/Sao_Paulo', false),
    ('edson.pereira', 'Edson Pereira', 'edson.pereira@seed.holospot.com', 'Motorista de ônibus aposentado, são-paulino, avô do Nicolas', '1963-04-18', 'America/Sao_Paulo', false)
) AS p(username, name, email, bio, birth_date, timezone, community_owner)
ON su.username = p.username;

DO $$ BEGIN RAISE NOTICE '>>> Fase 3 OK: 20 usuários inseridos.'; END $$;

-- ============================================================================
-- FASE 4: COMUNIDADES E MEMBROS (3 comunidades)
-- ============================================================================
CREATE TEMP TABLE _seed_communities (
    slug         text PRIMARY KEY,
    community_id uuid DEFAULT gen_random_uuid()
);

INSERT INTO _seed_communities (slug) VALUES
    ('time-tech'),
    ('pelada-quinta'),
    ('corre-sp');

INSERT INTO public.communities (id, name, slug, description, emoji, owner_id, is_active, created_at, updated_at)
SELECT
    sc.community_id, c.name, c.slug, c.description, c.emoji,
    (SELECT user_id FROM _seed_users WHERE username = c.owner),
    true, NOW(), NOW()
FROM _seed_communities sc
JOIN (VALUES
    ('time-tech', 'Time Tech', 'Nosso espaço pra reconhecer quem faz a diferença no dia a dia do trabalho', '💻', 'ricardo.alves'),
    ('pelada-quinta', 'Pelada de Quinta', 'Quem joga junto, reconhece junto', '⚽', 'carlos.henrique'),
    ('corre-sp', 'Corre SP', 'Corredores de São Paulo e região — cada km conta', '🏃', 'marcos.vinicius')
) AS c(slug, name, description, emoji, owner)
ON sc.slug = c.slug;

INSERT INTO public.community_members (user_id, community_id, role, is_active, joined_at)
SELECT
    (SELECT user_id FROM _seed_users WHERE username = m.username),
    (SELECT community_id FROM _seed_communities WHERE slug = m.slug),
    m.role, true, NOW()
FROM (VALUES
    ('rafael.mendes', 'time-tech', 'member'),
    ('ju.rocha', 'time-tech', 'member'),
    ('diego.design', 'time-tech', 'member'),
    ('ricardo.alves', 'time-tech', 'owner'),
    ('vanessa.martins', 'time-tech', 'member'),
    ('carlos.henrique', 'time-tech', 'member'),
    ('ana.beatriz', 'time-tech', 'member'),
    ('marcos.vinicius', 'time-tech', 'member'),
    ('fernanda.lima', 'time-tech', 'member'),
    ('thiago.costa', 'time-tech', 'member'),
    ('camila.santos', 'time-tech', 'member'),
    ('pedro.augusto', 'time-tech', 'member'),
    ('lucas.ferreira', 'time-tech', 'member'),
    ('renata.campos', 'time-tech', 'member'),
    ('carlos.henrique', 'pelada-quinta', 'owner'),
    ('diego.design', 'pelada-quinta', 'member'),
    ('ricardo.alves', 'pelada-quinta', 'member'),
    ('thiago.costa', 'pelada-quinta', 'member'),
    ('pedro.augusto', 'pelada-quinta', 'member'),
    ('lucas.ferreira', 'pelada-quinta', 'member'),
    ('seu.antonio', 'pelada-quinta', 'member'),
    ('edson.pereira', 'pelada-quinta', 'member'),
    ('rafael.mendes', 'corre-sp', 'member'),
    ('ju.rocha', 'corre-sp', 'member'),
    ('vanessa.martins', 'corre-sp', 'member'),
    ('ana.beatriz', 'corre-sp', 'member'),
    ('marcos.vinicius', 'corre-sp', 'owner'),
    ('patricia.nunes', 'corre-sp', 'member'),
    ('camila.santos', 'corre-sp', 'member'),
    ('renata.campos', 'corre-sp', 'member')
) AS m(username, slug, role);

DO $$ BEGIN RAISE NOTICE '>>> Fase 4 OK: 3 comunidades e 30 membros inseridos.'; END $$;

-- ============================================================================
-- FASE 5: FOLLOWS (135 relacionamentos)
-- ============================================================================
INSERT INTO public.follows (follower_id, following_id, created_at)
SELECT
    (SELECT user_id FROM _seed_users WHERE username = f.follower),
    (SELECT user_id FROM _seed_users WHERE username = f.following),
    NOW()
FROM (VALUES
    ('rafael.mendes', 'ju.rocha'),
    ('rafael.mendes', 'diego.design'),
    ('rafael.mendes', 'ricardo.alves'),
    ('rafael.mendes', 'vanessa.martins'),
    ('rafael.mendes', 'carlos.henrique'),
    ('rafael.mendes', 'ana.beatriz'),
    ('rafael.mendes', 'marcos.vinicius'),
    ('rafael.mendes', 'camila.santos'),
    ('rafael.mendes', 'renata.campos'),
    ('ju.rocha', 'rafael.mendes'),
    ('ju.rocha', 'diego.design'),
    ('ju.rocha', 'vanessa.martins'),
    ('ju.rocha', 'ricardo.alves'),
    ('ju.rocha', 'ana.beatriz'),
    ('ju.rocha', 'marcos.vinicius'),
    ('ju.rocha', 'camila.santos'),
    ('diego.design', 'rafael.mendes'),
    ('diego.design', 'ju.rocha'),
    ('diego.design', 'ricardo.alves'),
    ('diego.design', 'carlos.henrique'),
    ('diego.design', 'thiago.costa'),
    ('diego.design', 'pedro.augusto'),
    ('ricardo.alves', 'rafael.mendes'),
    ('ricardo.alves', 'ju.rocha'),
    ('ricardo.alves', 'diego.design'),
    ('ricardo.alves', 'vanessa.martins'),
    ('ricardo.alves', 'carlos.henrique'),
    ('ricardo.alves', 'ana.beatriz'),
    ('ricardo.alves', 'marcos.vinicius'),
    ('ricardo.alves', 'thiago.costa'),
    ('ricardo.alves', 'fernanda.lima'),
    ('ricardo.alves', 'camila.santos'),
    ('ricardo.alves', 'pedro.augusto'),
    ('ricardo.alves', 'lucas.ferreira'),
    ('ricardo.alves', 'renata.campos'),
    ('ricardo.alves', 'seu.antonio'),
    ('ricardo.alves', 'dona.lucia'),
    ('vanessa.martins', 'rafael.mendes'),
    ('vanessa.martins', 'ju.rocha'),
    ('vanessa.martins', 'diego.design'),
    ('vanessa.martins', 'ricardo.alves'),
    ('vanessa.martins', 'carlos.henrique'),
    ('vanessa.martins', 'ana.beatriz'),
    ('vanessa.martins', 'marcos.vinicius'),
    ('vanessa.martins', 'fernanda.lima'),
    ('vanessa.martins', 'camila.santos'),
    ('vanessa.martins', 'renata.campos'),
    ('vanessa.martins', 'patricia.nunes'),
    ('vanessa.martins', 'dona.lucia'),
    ('carlos.henrique', 'rafael.mendes'),
    ('carlos.henrique', 'diego.design'),
    ('carlos.henrique', 'ricardo.alves'),
    ('carlos.henrique', 'thiago.costa'),
    ('carlos.henrique', 'pedro.augusto'),
    ('carlos.henrique', 'lucas.ferreira'),
    ('ana.beatriz', 'rafael.mendes'),
    ('ana.beatriz', 'ju.rocha'),
    ('ana.beatriz', 'vanessa.martins'),
    ('ana.beatriz', 'marcos.vinicius'),
    ('ana.beatriz', 'renata.campos'),
    ('ana.beatriz', 'camila.santos'),
    ('marcos.vinicius', 'rafael.mendes'),
    ('marcos.vinicius', 'ju.rocha'),
    ('marcos.vinicius', 'vanessa.martins'),
    ('marcos.vinicius', 'ana.beatriz'),
    ('marcos.vinicius', 'ricardo.alves'),
    ('marcos.vinicius', 'renata.campos'),
    ('marcos.vinicius', 'camila.santos'),
    ('marcos.vinicius', 'patricia.nunes'),
    ('thiago.costa', 'ricardo.alves'),
    ('thiago.costa', 'carlos.henrique'),
    ('thiago.costa', 'diego.design'),
    ('thiago.costa', 'lucas.ferreira'),
    ('thiago.costa', 'pedro.augusto'),
    ('thiago.costa', 'rafael.mendes'),
    ('fernanda.lima', 'vanessa.martins'),
    ('fernanda.lima', 'ricardo.alves'),
    ('fernanda.lima', 'ju.rocha'),
    ('fernanda.lima', 'rafael.mendes'),
    ('fernanda.lima', 'camila.santos'),
    ('camila.santos', 'rafael.mendes'),
    ('camila.santos', 'ju.rocha'),
    ('camila.santos', 'vanessa.martins'),
    ('camila.santos', 'ana.beatriz'),
    ('camila.santos', 'marcos.vinicius'),
    ('camila.santos', 'fernanda.lima'),
    ('camila.santos', 'renata.campos'),
    ('pedro.augusto', 'carlos.henrique'),
    ('pedro.augusto', 'diego.design'),
    ('pedro.augusto', 'ricardo.alves'),
    ('pedro.augusto', 'thiago.costa'),
    ('pedro.augusto', 'lucas.ferreira'),
    ('lucas.ferreira', 'thiago.costa'),
    ('lucas.ferreira', 'carlos.henrique'),
    ('lucas.ferreira', 'ricardo.alves'),
    ('lucas.ferreira', 'pedro.augusto'),
    ('lucas.ferreira', 'diego.design'),
    ('renata.campos', 'ricardo.alves'),
    ('renata.campos', 'vanessa.martins'),
    ('renata.campos', 'marcos.vinicius'),
    ('renata.campos', 'ana.beatriz'),
    ('renata.campos', 'rafael.mendes'),
    ('renata.campos', 'ju.rocha'),
    ('renata.campos', 'camila.santos'),
    ('renata.campos', 'fernanda.lima'),
    ('patricia.nunes', 'vanessa.martins'),
    ('patricia.nunes', 'marcos.vinicius'),
    ('patricia.nunes', 'ana.beatriz'),
    ('patricia.nunes', 'dona.lucia'),
    ('patricia.nunes', 'maria.helena'),
    ('dona.lucia', 'seu.antonio'),
    ('dona.lucia', 'jorge.ribeiro'),
    ('dona.lucia', 'maria.helena'),
    ('dona.lucia', 'edson.pereira'),
    ('dona.lucia', 'vanessa.martins'),
    ('dona.lucia', 'ricardo.alves'),
    ('seu.antonio', 'dona.lucia'),
    ('seu.antonio', 'jorge.ribeiro'),
    ('seu.antonio', 'edson.pereira'),
    ('seu.antonio', 'maria.helena'),
    ('seu.antonio', 'ricardo.alves'),
    ('seu.antonio', 'carlos.henrique'),
    ('jorge.ribeiro', 'dona.lucia'),
    ('jorge.ribeiro', 'seu.antonio'),
    ('jorge.ribeiro', 'maria.helena'),
    ('jorge.ribeiro', 'edson.pereira'),
    ('maria.helena', 'dona.lucia'),
    ('maria.helena', 'seu.antonio'),
    ('maria.helena', 'jorge.ribeiro'),
    ('maria.helena', 'patricia.nunes'),
    ('edson.pereira', 'seu.antonio'),
    ('edson.pereira', 'dona.lucia'),
    ('edson.pereira', 'jorge.ribeiro'),
    ('edson.pereira', 'carlos.henrique'),
    ('edson.pereira', 'thiago.costa')
) AS f(follower, following);

DO $$ BEGIN RAISE NOTICE '>>> Fase 5 OK: 135 follows inseridos.'; END $$;

-- ============================================================================
-- FASE 6: DESABILITAR TRIGGERS DE NOTIFICAÇÃO
-- Gamificação (pontos/badges/streaks) permanece ATIVA
-- ============================================================================
ALTER TABLE public.posts     DISABLE TRIGGER holofote_notification_trigger;
ALTER TABLE public.reactions DISABLE TRIGGER reaction_notification_simple_trigger;
ALTER TABLE public.comments  DISABLE TRIGGER comment_notification_correto_trigger;
ALTER TABLE public.feedbacks DISABLE TRIGGER feedback_notification_correto_trigger;

DO $$ BEGIN RAISE NOTICE '>>> Fase 6 OK: triggers de notificação desabilitados.'; END $$;

-- ============================================================================
-- FASE 7: POSTS GLOBAIS E DE COMUNIDADE (70 posts)
-- celebrated_person_name = @username da pessoa mencionada
-- ============================================================================
CREATE TEMP TABLE _seed_posts (
    str_id  text PRIMARY KEY,
    post_id uuid DEFAULT gen_random_uuid()
);

INSERT INTO _seed_posts (str_id) VALUES
    ('P01'),
    ('P02'),
    ('P03'),
    ('P04'),
    ('P05'),
    ('P06'),
    ('P07'),
    ('P08'),
    ('P09'),
    ('P10'),
    ('P11'),
    ('P12'),
    ('P13'),
    ('P14'),
    ('P15'),
    ('P16'),
    ('P17'),
    ('P18'),
    ('P19'),
    ('P20'),
    ('P21'),
    ('P22'),
    ('P23'),
    ('P24'),
    ('P25'),
    ('P26'),
    ('P27'),
    ('P28'),
    ('P29'),
    ('P30'),
    ('P31'),
    ('P32'),
    ('P33'),
    ('P34'),
    ('P35'),
    ('P36'),
    ('P37'),
    ('P38'),
    ('P39'),
    ('P40'),
    ('P41'),
    ('P42'),
    ('P43'),
    ('P44'),
    ('P45'),
    ('P46'),
    ('P47'),
    ('P48'),
    ('P49'),
    ('P50'),
    ('P51'),
    ('P52'),
    ('P53'),
    ('P54'),
    ('P55'),
    ('P56'),
    ('P57'),
    ('P58'),
    ('P59'),
    ('P60'),
    ('P61'),
    ('P62'),
    ('P63'),
    ('P64'),
    ('P65'),
    ('P66'),
    ('P67'),
    ('P68'),
    ('P69'),
    ('P70');

INSERT INTO public.posts (id, user_id, content, celebrated_person_name, type, community_id, created_at, updated_at)
SELECT
    sp.post_id,
    (SELECT user_id FROM _seed_users WHERE username = p.author),
    p.content,
    p.celebrated_person_name,
    p.type,
    CASE WHEN p.community IS NOT NULL
         THEN (SELECT community_id FROM _seed_communities WHERE slug = p.community)
         ELSE NULL END,
    p.created_at::timestamptz,
    p.created_at::timestamptz
FROM _seed_posts sp
JOIN (VALUES
    ('P01', 'rafael.mendes', 'Ontem a @ju.rocha ficou meia hora depois do expediente me ajudando a debugar um problema de CSS que eu já tava prestes a desistir. Não era responsabilidade dela, não ia render nenhum crédito, mas ela sentou do meu lado (virtualmente) e resolveu em 15 minutos o que eu tava apanhando há 2 horas. Obrigado, Ju.', '@ju.rocha', 'gratitude', NULL, '2026-03-16 18:30:00+00'),
    ('P02', 'ju.rocha', 'O @rafael.mendes chegou hoje na daily com aquele componente pronto que todo mundo achava que ia levar a sprint inteira. E sabe o que mais? Ele documentou tudo. TUDO. Rafa, você me inspira a ser uma dev melhor.', '@rafael.mendes', 'inspiration', NULL, '2026-03-17 10:15:00+00'),
    ('P03', 'diego.design', 'Minha avó mora longe e eu não consigo visitar tanto quanto queria. Mas toda vez que ligo pra @dona.lucia (que nem é minha avó de sangue, é vizinha da minha mãe), ela pergunta se eu tô comendo direito, se tô dormindo bem, se tô feliz. Dona Lúcia, a senhora me faz falta sem nem saber.', '@dona.lucia', 'memory', NULL, '2026-03-17 21:45:00+00'),
    ('P04', 'ricardo.alves', 'O @thiago.costa é estagiário há 4 meses. Hoje ele fez um code review no meu PR e encontrou um bug que eu, com 15 anos de experiência, não vi. Não ficou com medo de apontar, não pediu desculpa por discordar. Mandou a observação com respeito e estava certo. Esse moleque vai longe.', '@thiago.costa', 'achievement', 'time-tech', '2026-03-18 16:20:00+00'),
    ('P05', 'vanessa.martins', 'A @ana.beatriz tá passando por uma fase difícil pessoalmente (com a autorização dela pra eu contar isso). E mesmo assim, ela não deixou a peteca cair em nenhuma entrega. Mas o que eu quero reconhecer não é a produtividade — é a coragem de pedir ajuda quando precisou. Ana, obrigada por confiar em mim.', '@ana.beatriz', 'support', NULL, '2026-03-18 19:00:00+00'),
    ('P06', 'dona.lucia', 'O Antônio, meu vizinho de tantos anos... ontem ele apareceu aqui em casa com a prateleira da cozinha que tava caindo consertada. Eu nem tinha pedido, ele viu da última vez que veio tomar café e voltou com as ferramentas. Esse homem tem um coração que não cabe no peito.', '@seu.antonio', 'gratitude', NULL, '2026-03-19 08:15:00+00'),
    ('P07', 'seu.antonio', 'A Lúcia fez bolo de fubá pra mim ontem. Sem motivo. Disse que lembrou que eu gostava. Às vezes a gente subestima o poder de alguém lembrar da gente.', '@dona.lucia', 'gratitude', NULL, '2026-03-19 14:30:00+00'),
    ('P08', 'carlos.henrique', 'O @pedro.augusto podia ter ido embora depois do primeiro tempo (o cara tinha acordo com a esposa pra voltar cedo). Mas ficou porque tava 3x2 e a gente precisava dele no gol. Resultado: tomou esporro em casa, mas salvou o jogo. Pedro, sua esposa tem razão, mas a gente te ama.', '@pedro.augusto', 'gratitude', 'pelada-quinta', '2026-03-19 22:10:00+00'),
    ('P09', 'marcos.vinicius', 'A @camila.santos correu a primeira 10k dela hoje. Ela começou em janeiro sem conseguir fazer 1km sem parar. Quatro meses depois, cruzou a linha dos 10km com um sorriso que eu nunca vou esquecer. Cami, isso é só o começo.', '@camila.santos', 'achievement', 'corre-sp', '2026-03-20 11:00:00+00'),
    ('P10', 'thiago.costa', 'O @ricardo.alves podia ser aquele tech lead que só cobra e delega. Mas toda vez que eu travo em algo, ele para o que tá fazendo e senta comigo pra entender o problema. Não dá a resposta pronta — me faz pensar. Tô aprendendo mais em 4 meses do que em 2 anos de faculdade.', '@ricardo.alves', 'admiration', 'time-tech', '2026-03-20 17:45:00+00'),
    ('P11', 'ana.beatriz', 'Semana passada eu desabei numa call com a @vanessa.martins. Chorei, contei tudo, fiz aquele papel que a gente tem vergonha de fazer no trabalho. Sabe o que ela fez? Não deu conselho. Não tentou resolver. Só ouviu. Às vezes ouvir é o maior presente que alguém pode dar.', '@vanessa.martins', 'gratitude', NULL, '2026-03-21 20:30:00+00'),
    ('P12', 'fernanda.lima', 'Percebi um padrão no @rafael.mendes que quero registrar: em toda retro, ele fala pelo menos uma coisa positiva sobre alguém do time antes de falar de problemas. Parece pequeno mas muda o tom da conversa inteira. Comecei a fazer igual na minha squad.', '@rafael.mendes', 'inspiration', 'time-tech', '2026-03-21 09:40:00+00'),
    ('P13', 'patricia.nunes', 'Conheci a @maria.helena numa roda de leitura. Ela tem 73 anos e lê mais que qualquer pessoa que eu conheço. Mas o que me impressiona não é a quantidade — é como ela escuta a opinião de todo mundo com a mesma atenção, sem nunca fazer ninguém se sentir menor. Que eu tenha essa elegância quando chegar lá.', '@maria.helena', 'admiration', NULL, '2026-03-22 15:20:00+00'),
    ('P14', 'camila.santos', 'O @marcos.vinicius me mandou mensagem no sábado de manhã pra saber se eu ia pro treino. Eu não ia — tava chovendo, tava com preguiça, tava inventando desculpa. Ele disse: ''Vem, eu te espero no km 3.'' E esperou. Marcos, obrigada por não me deixar desistir.', '@marcos.vinicius', 'gratitude', 'corre-sp', '2026-03-22 19:00:00+00'),
    ('P15', 'pedro.augusto', 'Quinta passada o @carlos.henrique errou um gol feito (sim, a bola ia entrar sozinha e ele conseguiu errar). Todo mundo zoou, claro. Mas depois do jogo ele me mandou áudio perguntando se eu tava bem porque me viu quieto. O cara erra gol mas não erra a leitura de um amigo. Prioridades certas.', '@carlos.henrique', 'support', 'pelada-quinta', '2026-03-23 23:15:00+00'),
    ('P16', 'lucas.ferreira', 'O @thiago.costa e eu entramos juntos como estagiários. Tinha tudo pra ser competição. Mas quando eu travei na primeira task, ele sentou comigo e dividiu as anotações dele. A gente poderia estar competindo por vaga e em vez disso tá crescendo junto. Valeu, Thiago.', '@thiago.costa', 'support', 'time-tech', '2026-03-23 14:00:00+00'),
    ('P17', 'renata.campos', 'Preciso falar do @ricardo.alves como líder técnico. Em 6 meses trabalhando com ele, nunca vi ele puxar crédito pra si. Quando o projeto vai bem, ele fala ''o time entregou''. Quando algo dá errado, ele fala ''eu não vi esse risco''. Liderança é isso.', '@ricardo.alves', 'admiration', 'time-tech', '2026-03-24 11:30:00+00'),
    ('P18', 'jorge.ribeiro', 'Lembrei hoje do Edson me ensinando a trocar pneu em 1987. A gente mal se conhecia, eu tinha acabado de me mudar pro bairro. Ele parou o carro dele, veio até o meu e ficou ali até eu conseguir sozinho. Quase 40 anos depois, @edson.pereira ainda é assim: para o que tá fazendo pra ajudar.', '@edson.pereira', 'memory', NULL, '2026-03-24 07:30:00+00'),
    ('P19', 'maria.helena', 'A @patricia.nunes me ensinou que nunca é tarde pra aprender. Ela que é professora virou minha aluna quando eu comecei a contar histórias na roda de leitura. Me ouvir com aqueles olhos atentos me fez acreditar que minhas memórias ainda importam.', '@patricia.nunes', 'inspiration', NULL, '2026-03-25 10:00:00+00'),
    ('P20', 'vanessa.martins', 'Quero reconhecer a @fernanda.lima por algo que pouca gente viu: ela refez a dashboard de métricas 3 vezes porque não tava satisfeita com a clareza dos dados. Ninguém pediu, ninguém cobrou. Ela fez porque acredita que dado confuso desinforma. O resultado ficou impecável.', '@fernanda.lima', 'achievement', 'time-tech', '2026-03-25 16:00:00+00'),
    ('P21', 'edson.pereira', 'O Antônio carrega 70 anos nas costas e humildade no jeito. Outro dia tava ensinando o neto a lixar madeira com a mesma paciência que ensinou a mim 30 anos atrás. Não mudou. @seu.antonio, o senhor é uma aula.', '@seu.antonio', 'admiration', NULL, '2026-03-25 08:45:00+00'),
    ('P22', 'diego.design', 'Entreguei um layout semana passada que eu achava bom. O @rafael.mendes olhou, ficou quieto uns segundos e disse: ''E se a gente invertesse a hierarquia visual aqui?'' Poderia ter dito ''não gostei''. Em vez disso, me deu uma direção melhor sem invalidar o meu trabalho. Faz diferença demais.', '@rafael.mendes', 'gratitude', 'time-tech', '2026-03-26 13:15:00+00'),
    ('P23', 'ricardo.alves', 'A @renata.campos correu a maratona de São Paulo domingo. 42km. Sabe o que ela fez na segunda? Chegou no trabalho às 9 em ponto, com o joelho enfaixado e um sorriso. Quando perguntei se não queria folga, ela disse: ''Corri porque quis, trabalho porque gosto. Uma coisa não cancela a outra.'' Inspira.', '@renata.campos', 'inspiration', NULL, '2026-03-26 18:00:00+00'),
    ('P24', 'dona.lucia', 'Esse menino, o @diego.design, ligou pra mim outro dia só pra dizer que tava com saudade. Vocês não sabem o que isso significa pra quem mora sozinha. Ele não é da minha família, mas é da minha vida. Deus abençoe esse rapaz.', '@diego.design', 'gratitude', NULL, '2026-03-27 09:20:00+00'),
    ('P25', 'ana.beatriz', 'O @marcos.vinicius sempre chega primeiro no treino e sai por último. Mas não é por performance — é porque ele espera todo mundo chegar e se certifica que todo mundo terminou bem. Sábado passado ficou esperando eu terminar meu pace (lento, eu sei) sem pressa nenhuma. Líder é quem espera.', '@marcos.vinicius', 'admiration', 'corre-sp', '2026-03-27 17:30:00+00'),
    ('P26', 'carlos.henrique', 'O @diego.design não é o melhor jogador da pelada (desculpa, Diego). Mas é o cara que todo mundo quer no time. Sabe por quê? Porque ele comemora o gol dos outros como se fosse dele. Na quinta passada fez uma corrida de 30 metros pra abraçar o Lucas depois do gol. Esse espírito não se ensina.', '@diego.design', 'inspiration', 'pelada-quinta', '2026-03-28 22:40:00+00'),
    ('P27', 'ju.rocha', 'A @camila.santos tava insegura com a apresentação que ia fazer pro cliente. Me mandou o deck às 11 da noite pedindo opinião. Eu dei feedback honesto: 3 slides precisavam de ajuste. Sabe o que ela fez? Refez os 3 e me mandou de novo às 6 da manhã. Não pediu validação, pediu evolução. Camila, você é fera.', '@camila.santos', 'support', NULL, '2026-03-28 08:50:00+00'),
    ('P28', 'marcos.vinicius', 'O @rafael.mendes completou 100 dias seguidos de treino hoje. Cem. Chuva, sol, viagem, criança doente — ele achou um jeito. Nem todo dia foi uma corrida longa, às vezes foram 15 minutos de esteira no hotel. Mas a consistência tá aí. Rafa, chapéu.', '@rafael.mendes', 'achievement', 'corre-sp', '2026-03-29 07:15:00+00'),
    ('P29', 'thiago.costa', 'O @lucas.ferreira tava travado num bug há 2 dias e com vergonha de pedir ajuda. Eu percebi porque ele tava quieto demais no Slack. Chamei ele num privado e a gente resolveu em 40 min. Lucas, nunca tenha vergonha de travar. Todo mundo trava. O importante é não travar sozinho.', '@lucas.ferreira', 'support', NULL, '2026-03-29 15:30:00+00'),
    ('P30', 'seu.antonio', 'Outro dia eu e o @jorge.ribeiro ficamos sentados no banco da praça sem falar nada por uns 20 minutos. Só ali. Depois ele disse: ''Tá bom assim.'' E tava. Nem toda amizade precisa de conversa. Algumas só precisam de presença.', '@jorge.ribeiro', 'memory', NULL, '2026-03-30 16:45:00+00'),
    ('P31', 'vanessa.martins', 'Situação real: eu errei feio num alinhamento com stakeholder. Tipo, errei de verdade. O @ricardo.alves podia ter me exposto na reunião, podia ter corrigido na frente de todo mundo. Sabe o que ele fez? Me chamou no privado, me ajudou a montar um plano de correção e disse: ''A gente conserta junto.'' Liderança de verdade, pessoal.', '@ricardo.alves', 'gratitude', 'time-tech', '2026-03-30 19:15:00+00'),
    ('P32', 'fernanda.lima', 'Faço uma observação sobre a @vanessa.martins: ela é a pessoa que mais lembra de aniversários, datas importantes e gostos pessoais de cada um do time. Parece bobagem, mas quando ela manda um ''feliz aniversário, Fer, sei que você gosta de café coado então deixei um pacote na sua mesa'', isso cria pertencimento.', '@vanessa.martins', 'admiration', NULL, '2026-03-31 10:30:00+00'),
    ('P33', 'camila.santos', 'Obrigada @ju.rocha por ter sido honesta comigo sobre a apresentação. Eu queria ouvir ''tá ótimo'' e você me deu algo melhor: ''tá bom, mas pode ser excelente''. Esse feedback me fez crescer mais do que qualquer elogio faria.', '@ju.rocha', 'gratitude', NULL, '2026-03-31 12:00:00+00'),
    ('P34', 'pedro.augusto', 'O @thiago.costa tem 21 anos e já entende algo que muita gente de 40 não entende: que time é mais importante que ego. Na quinta passada ele tava jogando bem pra caramba, fazendo gol, dominando. Aí viu que o Lucas tava pra baixo e começou a passar a bola só pra ele. O Lucas fez o gol da virada. O sorriso do Thiago era maior que o do Lucas.', '@thiago.costa', 'admiration', 'pelada-quinta', '2026-04-01 23:00:00+00'),
    ('P35', 'maria.helena', 'Eu e a @dona.lucia nos conhecemos em 1985, numa fila de banco. Ela tava com um bebê no colo e eu ajudei a segurar a bolsa. Quarenta anos depois, aquele bebê já é pai, e nós duas ainda tomamos café juntas quando dá. Algumas amizades não precisam de motivo pra começar — só de disposição pra continuar.', '@dona.lucia', 'memory', NULL, '2026-04-01 09:00:00+00'),
    ('P36', 'rafael.mendes', 'Uma coisa sobre o @ricardo.alves que ninguém fala: ele responde mensagem de todo mundo. Estagiário, PM, designer, o cara de infra que ninguém conhece. Todo mundo tem acesso a ele. Isso parece básico, mas eu já trabalhei em lugar onde tech lead era intocável. O Ricardo não é assim. E isso muda tudo.', '@ricardo.alves', 'admiration', NULL, '2026-04-02 11:40:00+00'),
    ('P37', 'renata.campos', 'Quero celebrar a @ana.beatriz: ela começou a correr há 5 meses, como mãe solo, encaixando treino na hora do almoço. Sábado ela completou a primeira meia-maratona. 21km. Quando cruzou a linha, a primeira coisa que fez foi ligar pro filho. Ana, você ensina o Miguel pelo exemplo.', '@ana.beatriz', 'achievement', 'corre-sp', '2026-04-02 14:20:00+00'),
    ('P38', 'lucas.ferreira', 'O @carlos.henrique me explicou git rebase umas 5 vezes. Cinco. Na quinta vez eu entendi (mais ou menos). Ele podia ter perdido a paciência na segunda. Mas em nenhum momento ele fez eu me sentir burro. Carlos, obrigado por tratar minha ignorância com respeito.', '@carlos.henrique', 'gratitude', NULL, '2026-04-03 16:50:00+00'),
    ('P39', 'edson.pereira', 'Eu tenho 62 anos e jogo na pelada com moleque de 25. O @carlos.henrique nunca me tratou diferente. Pede passe, cobra marcação, comemora comigo. Não tem esse negócio de ''ah, o tio tá cansado''. Respeito é isso: me tratar como igual.', '@carlos.henrique', 'admiration', 'pelada-quinta', '2026-04-03 21:30:00+00'),
    ('P40', 'ju.rocha', 'O @diego.design recebeu um feedback duro sobre um layout na semana passada. Em vez de ficar na defensiva (que seria compreensível), ele veio no dia seguinte com 3 versões alternativas e perguntou: ''qual caminho vocês preferem?'' Maturidade profissional não tem nada a ver com idade.', '@diego.design', 'admiration', 'time-tech', '2026-04-04 09:30:00+00'),
    ('P41', 'diego.design', 'A @vanessa.martins percebeu que eu não tava bem antes de eu mesmo perceber. Me mandou mensagem: ''Quer tomar um café?'' Não perguntou o que eu tinha, não pressionou. Só ofereceu presença. Às vezes a gente só precisa de alguém que note.', '@vanessa.martins', 'support', NULL, '2026-04-04 20:00:00+00'),
    ('P42', 'patricia.nunes', 'Eu tenho 47 anos e achava que era tarde demais pra começar a correr. Aí vi a @ana.beatriz, mãe solo, trabalhando integral, fazendo meia-maratona. Se ela encontrou tempo, qual é a minha desculpa? Me inscrevi na minha primeira 5k por causa dela.', '@ana.beatriz', 'inspiration', 'corre-sp', '2026-04-04 07:45:00+00'),
    ('P43', 'ricardo.alves', 'O @carlos.henrique organiza a pelada toda quinta: reserva o campo, confirma quem vai, equilibra os times, traz a bola extra, lembra da água. Nunca pediu nada em troca. Nunca reclamou quando alguém fura em cima da hora. Carlos, você é o MVP fora de campo.', '@carlos.henrique', 'gratitude', 'pelada-quinta', '2026-04-05 12:30:00+00'),
    ('P44', 'ana.beatriz', 'A @renata.campos fez uma coisa que me marcou: no 1:1 dela comigo, em vez de falar de entrega, perguntou como eu tava de verdade. E quando eu disse ''tô bem'', ela ficou em silêncio e esperou. Aí eu falei de verdade. Ela sabia que a primeira resposta nunca é a real. Que gestora.', '@renata.campos', 'admiration', 'time-tech', '2026-04-05 18:45:00+00'),
    ('P45', 'marcos.vinicius', 'A @patricia.nunes quase desistiu no km 4 da primeira corrida dela. Eu tava do lado e só disse: ''Falta 1km. Vai andando se precisar, mas não para.'' Ela não parou. E depois me mandou mensagem: ''Você não me deixou desistir.'' Na real, ela que não desistiu. Eu só lembrei ela disso.', '@patricia.nunes', 'support', 'corre-sp', '2026-04-05 08:00:00+00'),
    ('P46', 'vanessa.martins', 'A @ju.rocha é mãe, designer, corredora e ainda arruma tempo pra fazer mentoria com duas juniores do time. Quando eu perguntei como ela dá conta, ela disse: ''Eu não dou. Eu escolho o que vou deixar cair e aceito.'' Essa honestidade é mais inspiradora que qualquer produtividade tóxica.', '@ju.rocha', 'inspiration', NULL, '2026-04-06 13:00:00+00'),
    ('P47', 'jorge.ribeiro', 'A @maria.helena escreveu um poema pro aniversário do meu neto. Ela nem conhece ele pessoalmente — conhece pelas histórias que eu conto. Mas o poema era tão certeiro que meu neto perguntou: ''Vô, a dona Helena me conhece?'' De certo modo, sim.', '@maria.helena', 'admiration', NULL, '2026-04-06 10:15:00+00'),
    ('P48', 'thiago.costa', 'Eu ia apagar uma mensagem no Slack porque achei que era boba demais. O @diego.design leu antes e respondeu: ''Essa ideia é boa, traz pro time.'' Aquela mensagem virou uma feature no produto. Diego, obrigado por ver valor no que eu quase joguei fora.', '@diego.design', 'gratitude', NULL, '2026-04-06 16:30:00+00'),
    ('P49', 'dona.lucia', 'Essa moça, a @vanessa.martins, me ligou dia desses pra saber se eu tava conseguindo mexer no app novo do banco. Ficou no telefone comigo 40 minutos. Quarenta! E com paciência, meu filho. Não deu risada, não ficou com pressa. Me explicou tudo como se eu fosse a pessoa mais importante do mundo naquele momento.', '@vanessa.martins', 'gratitude', NULL, '2026-04-07 07:50:00+00'),
    ('P50', 'rafael.mendes', 'O @carlos.henrique mandou mensagem no grupo de pais da escola perguntando se alguém tinha um colchão extra pro filho do amigo dele que tava numa situação difícil. Em 2 horas ele tinha juntado colchão, roupa, material escolar e 3 marmitas. Ele não pediu crédito. Eu só soube porque tava no grupo. Carlos, isso é caráter.', '@carlos.henrique', 'support', NULL, '2026-04-07 20:10:00+00'),
    ('P51', 'camila.santos', 'No treino de sábado a @ana.beatriz tava claramente num dia ruim. Mais lenta, sem energia, quase chorando. Eu diminuí meu ritmo e corri do lado dela sem falar nada. No km 3 ela disse: ''Obrigada por ficar.'' Não precisou de mais nada.', '@ana.beatriz', 'support', 'corre-sp', '2026-04-07 11:30:00+00'),
    ('P52', 'pedro.augusto', 'O @edson.pereira me contou que jogava no campinho do bairro dele quando era moleque — descalço, bola de meia. Quinta passada ele fez um gol de cobertura que eu juro que vi câmera lenta. 62 anos, senhoras e senhores. A bola não esquece quem ama ela.', '@edson.pereira', 'memory', 'pelada-quinta', '2026-04-08 22:45:00+00'),
    ('P53', 'renata.campos', 'Obrigada @marcos.vinicius por ter me esperado no km 38 da maratona quando minhas pernas travaram. Você tava com pace pra fazer seu melhor tempo e largou isso pra ficar comigo. Perdi a conta de quantas vezes eu disse ''vai, eu me viro'' e você respondeu ''eu sei que se vira, mas eu fico.'' Amigo é isso.', '@marcos.vinicius', 'gratitude', NULL, '2026-04-08 14:15:00+00'),
    ('P54', 'fernanda.lima', 'A @camila.santos encontrou um bug em produção sexta às 17h. Todo mundo tava já saindo. Ela não só reportou — ela rastreou a causa raiz, documentou e sugeriu o fix. Na segunda a gente só precisou aprovar. QA com senso de dono é outra coisa.', '@camila.santos', 'inspiration', 'time-tech', '2026-04-08 09:50:00+00'),
    ('P55', 'seu.antonio', 'O @edson.pereira me levou no médico segunda-feira. Eu podia ter ido de ônibus, mas ele fez questão. Ficou na sala de espera 3 horas lendo jornal. Na volta paramos pra tomar um café. Não disse nada demais. Mas tava lá.', '@edson.pereira', 'gratitude', NULL, '2026-04-09 15:00:00+00'),
    ('P56', 'carlos.henrique', 'O @lucas.ferreira fez o primeiro deploy dele em produção hoje. Sozinho. Sem ninguém segurando a mão. E funcionou de primeira. Eu lembro do primeiro deploy dele (que eu acompanhei de perto, de olho em tudo). Hoje ele não precisou de mim. Esse é o melhor elogio que um mentor pode receber: virar desnecessário.', '@lucas.ferreira', 'achievement', 'time-tech', '2026-04-09 17:20:00+00'),
    ('P57', 'dona.lucia', 'Eu e o @jorge.ribeiro fomos vizinhos por 25 anos antes dele se mudar pra Santos. Sabe o que eu mais sinto falta? Da buzina do carro dele de manhã, passando pra ir trabalhar. Era meu despertador. Ele nem sabia disso até eu contar agora.', '@jorge.ribeiro', 'memory', NULL, '2026-04-10 08:30:00+00'),
    ('P58', 'diego.design', 'A @camila.santos fez uma coisa que ninguém mais faz: ela testou meu protótipo como usuária real, não como QA. Em vez de listar bugs, ela me disse: ''Aqui eu fiquei confusa, aqui eu sorri, aqui eu desisti.'' Esse tipo de feedback vale mais que 100 tickets no Jira.', '@camila.santos', 'gratitude', NULL, '2026-04-10 14:40:00+00'),
    ('P59', 'vanessa.martins', 'Conheci a @patricia.nunes numa corrida e descobri que ela é professora de história. A gente começou falando de pace e terminou falando de como a educação no Brasil forma (ou deforma) cidadãos. Saí daquela conversa pensando diferente sobre 3 coisas. Pessoas que te fazem pensar são um presente.', '@patricia.nunes', 'admiration', NULL, '2026-04-11 18:20:00+00'),
    ('P60', 'ricardo.alves', 'A @vanessa.martins discordou de mim numa reunião. Na frente de todo mundo. Com argumentos. E tava certa. Eu poderia ter levado pro lado pessoal, mas em vez disso levei pro lado profissional: a gente precisa de gente que discorda com respeito e dados. Obrigado por não concordar comigo, Van.', '@vanessa.martins', 'gratitude', NULL, '2026-04-11 11:00:00+00'),
    ('P61', 'maria.helena', 'O @jorge.ribeiro consertou o portão da minha casa semana passada. Tem 76 anos e veio com a caixa de ferramentas na mão, como se fosse a coisa mais natural do mundo. Quando eu ofereci pagar, ele disse: ''Me paga com um café, dona Helena.'' O mundo precisa de mais Jorges.', '@jorge.ribeiro', 'gratitude', NULL, '2026-04-12 09:30:00+00'),
    ('P62', 'thiago.costa', 'A @renata.campos fez uma coisa na retro que eu nunca tinha visto uma gestora fazer: ela admitiu que errou. Na frente do time todo. Disse: ''Eu deveria ter protegido vocês daquela demanda e não protegi.'' Ninguém ficou com menos respeito por ela. Pelo contrário.', '@renata.campos', 'admiration', 'time-tech', '2026-04-12 15:45:00+00'),
    ('P63', 'ana.beatriz', 'Preciso agradecer a @camila.santos por ter corrido do meu lado sábado quando eu tava num dia péssimo. Ela não tentou me animar, não deu conselho, não perguntou o que eu tinha. Só ficou ali, no meu ritmo, em silêncio solidário. Às vezes o melhor apoio é simplesmente não ir embora.', '@camila.santos', 'gratitude', NULL, '2026-04-12 20:00:00+00'),
    ('P64', 'lucas.ferreira', 'O @ricardo.alves me disse uma frase outro dia que eu colei no monitor: ''Você não precisa saber tudo, só precisa saber perguntar.'' Parece clichê, mas vindo de alguém com 15 anos de experiência que ainda pergunta coisas no Stack Overflow, tem outro peso.', '@ricardo.alves', 'inspiration', NULL, '2026-04-13 10:45:00+00'),
    ('P65', 'jorge.ribeiro', 'A @dona.lucia manda foto de bolo pra mim toda semana. Não é pra me fazer inveja — é pra eu sentir que ainda tô conectado com o bairro. Cada foto é um pedacinho de casa. Lúcia, obrigado por não me deixar ser um ex-vizinho.', '@dona.lucia', 'gratitude', NULL, '2026-04-13 07:20:00+00'),
    ('P66', 'rafael.mendes', 'No dia que eu completei os 100 dias de treino, o @marcos.vinicius me deu um abraço e disse: ''Eu sabia que você ia conseguir. Você que não sabia.'' Cara, isso ficou ecoando na minha cabeça a semana inteira. Às vezes a gente precisa de alguém que acredite em nós antes da gente acreditar.', '@marcos.vinicius', 'gratitude', 'corre-sp', '2026-04-13 19:30:00+00'),
    ('P67', 'edson.pereira', 'O @thiago.costa me chamou de ''mestre'' na pelada outro dia. Eu ri. Mas depois pensei: esse moleque trata todo mundo mais velho com respeito sem ser forçado. Não é educação de fachada. É caráter. Os pais desse garoto acertaram.', '@thiago.costa', 'inspiration', 'pelada-quinta', '2026-04-14 21:00:00+00'),
    ('P68', 'camila.santos', 'A @fernanda.lima tem um dom que eu invejo: ela pega dados frios e transforma em histórias que convencem. Aquela dashboard que ela refez? O PM usou na reunião de board e o C-level pediu mais. Fer, seus dados contam histórias melhores que muita série.', '@fernanda.lima', 'admiration', 'time-tech', '2026-04-14 11:15:00+00'),
    ('P69', 'pedro.augusto', 'Uma vez o @seu.antonio me ensinou a afiar faca com pedra. Eu, um DevOps que não sabe pregar prego, aprendendo a afiar faca com um carpinteiro aposentado num churrasco. Aquela tarde vale mais que qualquer workshop de team building que eu já fui.', '@seu.antonio', 'memory', NULL, '2026-04-15 14:00:00+00'),
    ('P70', 'renata.campos', 'Quero reconhecer algo que a @fernanda.lima fez discretamente: ela montou um doc com todos os processos do time que ninguém tinha documentado. Ninguém pediu. Ela viu que onboarding de gente nova era caótico e resolveu. Quando a Patrícia entrou na squad, teve tudo escrito. Isso é senso de time.', '@fernanda.lima', 'achievement', NULL, '2026-04-15 16:50:00+00')
) AS p(str_id, author, content, celebrated_person_name, type, community, created_at)
ON sp.str_id = p.str_id;

DO $$ BEGIN RAISE NOTICE '>>> Fase 7 OK: 70 posts inseridos.'; END $$;

-- ============================================================================
-- FASE 8: CORRENTES E POSTS DE CORRENTES (4 correntes, 12 posts)
-- ============================================================================
CREATE TEMP TABLE _seed_chains (
    str_id   text PRIMARY KEY,
    chain_id uuid DEFAULT gen_random_uuid()
);

INSERT INTO _seed_chains (str_id) VALUES
    ('CH01'),
    ('CH02'),
    ('CH03'),
    ('CH04');

INSERT INTO public.chains (id, name, description, highlight_type, creator_id, status, is_memorias_vivas, created_at)
SELECT
    sc.chain_id, c.name, c.description, c.highlight_type,
    (SELECT user_id FROM _seed_users WHERE username = c.creator),
    c.status, c.is_mv, NOW()
FROM _seed_chains sc
JOIN (VALUES
    ('CH01', 'Quem te fez acreditar em você?', 'Conte sobre alguém que acreditou em você quando você mesmo não acreditava', 'inspiration', 'vanessa.martins', 'active', false),
    ('CH02', 'O conselho que eu carrego até hoje', 'Qual conselho alguém te deu que ainda guia suas decisões?', 'memory', 'seu.antonio', 'active', true),
    ('CH03', 'Um gesto pequeno que mudou seu dia', 'Às vezes não é o grande favor, é o detalhe. Conte sobre um gesto simples que fez diferença no seu dia.', 'gratitude', 'rafael.mendes', 'active', false),
    ('CH04', 'A pessoa que te ensinou sem saber', 'Alguém que te ensinou algo importante só pelo exemplo, sem nunca ter dado uma aula formal.', 'inspiration', 'ana.beatriz', 'active', false)

) AS c(str_id, name, description, highlight_type, creator, status, is_mv)
ON sc.str_id = c.str_id;

CREATE TEMP TABLE _seed_chain_posts (
    str_id  text PRIMARY KEY,
    post_id uuid DEFAULT gen_random_uuid()
);

INSERT INTO _seed_chain_posts (str_id) VALUES
    ('CP01'),
    ('CP02'),
    ('CP03'),
    ('CP04'),
    ('CP05'),
    ('CP06'),
    ('CP07'),
    ('CP08'),
    ('CP09'),
    ('CP10'),
    ('CP11'),
    ('CP12');

INSERT INTO public.posts (id, user_id, content, celebrated_person_name, type, chain_id, created_at, updated_at)
SELECT
    scp.post_id,
    (SELECT user_id FROM _seed_users WHERE username = cp.author),
    cp.content,
    cp.celebrated_person_name,
    cp.type,
    (SELECT chain_id FROM _seed_chains WHERE str_id = cp.chain_str_id),
    cp.created_at::timestamptz,
    cp.created_at::timestamptz
FROM _seed_chain_posts scp
JOIN (VALUES
    ('CP01', 'vanessa.martins', 'O @marcos.vinicius me convidou pra correr minha primeira meia quando eu achava que 5k era meu limite. Ele não disse ''você consegue''. Disse: ''Se você não conseguir, a gente volta andando.'' Tirou a pressão e me deu coragem. Corri os 21km.', '@marcos.vinicius', 'inspiration', 'CH01', '2026-03-26 20:30:00+00'),
    ('CP02', 'thiago.costa', 'Eu quase desisti do estágio na segunda semana. Achava que não era bom o suficiente. O @ricardo.alves me chamou pra um café e disse: ''Ninguém nasce sabendo. Você tem curiosidade, e isso não se ensina.'' Tô aqui por causa dessa conversa.', '@ricardo.alves', 'inspiration', 'CH01', '2026-03-28 13:00:00+00'),
    ('CP03', 'dona.lucia', 'Quando meu marido faleceu, eu achei que minha vida tinha acabado. A @maria.helena me ligava todo dia. Todo dia. Às vezes pra conversar, às vezes só pra dizer ''tô aqui''. Ela me fez acreditar que eu ainda tinha história pra viver. E eu tinha.', '@maria.helena', 'inspiration', 'CH01', '2026-03-31 09:30:00+00'),
    ('CP04', 'seu.antonio', 'O @edson.pereira me disse em 1995: ''Antônio, trabalha com as mãos mas pensa com a cabeça.'' Eu era carpinteiro bruto, fazia tudo no impulso. Depois daquele dia, comecei a planejar cada corte. Meus móveis ficaram melhores. Minha vida também.', '@edson.pereira', 'memory', 'CH02', '2026-03-24 10:00:00+00'),
    ('CP05', 'jorge.ribeiro', 'A @maria.helena me disse uma vez: ''Jorge, aposentar o corpo não é aposentar a cabeça.'' Eu tava virando sofá. Depois disso voltei a ler, comecei a caminhar no parque, entrei na roda de leitura. Ela salvou minha aposentadoria de ser uma espera pelo fim.', '@maria.helena', 'memory', 'CH02', '2026-03-27 08:15:00+00'),
    ('CP06', 'maria.helena', 'A @dona.lucia me disse algo simples que eu nunca esqueci: ''Helena, solidão é quando a gente para de ir atrás dos outros.'' Eu tava me isolando depois da aposentadoria. No dia seguinte liguei pra 3 amigas. Todas atenderam. A Lúcia tava certa.', '@dona.lucia', 'memory', 'CH02', '2026-03-30 11:00:00+00'),
    ('CP07', 'rafael.mendes', 'A @fernanda.lima deixou um post-it na minha mesa (sim, a gente ainda vai pro escritório às vezes) escrito: ''Aquele componente ficou lindo.'' Quatro palavras. Eu tava num dia em que achava que nada que eu fazia prestava. Aquele post-it ficou colado no meu monitor por 2 semanas.', '@fernanda.lima', 'gratitude', 'CH03', '2026-03-21 12:30:00+00'),
    ('CP08', 'camila.santos', 'A @ju.rocha me mandou um áudio de 12 segundos depois de uma reunião tensa: ''Cami, você mandou bem. Para de duvidar.'' Doze segundos. Às vezes é só isso que a gente precisa ouvir.', '@ju.rocha', 'gratitude', 'CH03', '2026-03-25 18:00:00+00'),
    ('CP09', 'pedro.augusto', 'O @carlos.henrique me mandou o link de uma vaga que tinha a minha cara. Nem era da empresa dele, nem ia beneficiar ele em nada. Só viu, lembrou de mim e mandou. Não usei a vaga, mas guardei o gesto.', '@carlos.henrique', 'gratitude', 'CH03', '2026-04-01 21:00:00+00'),
    ('CP10', 'ana.beatriz', 'A @renata.campos nunca me deu uma aula de liderança. Mas eu aprendo toda vez que vejo ela em reunião: como ela escuta antes de falar, como ela dá crédito, como ela assume erro. Eu copio ela descaradamente. Acho que ela nem sabe.', '@renata.campos', 'inspiration', 'CH04', '2026-04-03 13:45:00+00'),
    ('CP11', 'lucas.ferreira', 'O @seu.antonio me ensinou paciência sem dizer uma palavra sobre paciência. Foi num churrasco: eu queria virar a carne a cada 30 segundos. Ele pôs a mão no meu braço e disse: ''Espera. A carne avisa quando tá pronta.'' Eu uso isso no código agora. Sério.', '@seu.antonio', 'inspiration', 'CH04', '2026-04-07 15:30:00+00'),
    ('CP12', 'diego.design', 'A @patricia.nunes é professora e eu sou designer, mas ela me ensinou mais sobre comunicação visual do que qualquer curso. Um dia ela disse: ''Se o aluno não entendeu, o problema é do professor, não do aluno.'' Troquei ''aluno'' por ''usuário'' e mudou minha forma de projetar.', '@patricia.nunes', 'inspiration', 'CH04', '2026-04-11 10:15:00+00')

) AS cp(str_id, author, content, celebrated_person_name, type, chain_str_id, created_at)
ON scp.str_id = cp.str_id;

INSERT INTO public.chain_posts (post_id, chain_id, author_id, created_at)
SELECT
    scp.post_id,
    (SELECT chain_id FROM _seed_chains WHERE str_id = cp.chain_str_id),
    (SELECT user_id FROM _seed_users WHERE username = cp.author),
    NOW()
FROM _seed_chain_posts scp
JOIN (VALUES
    ('CP01', 'vanessa.martins', 'CH01'),
    ('CP02', 'thiago.costa', 'CH01'),
    ('CP03', 'dona.lucia', 'CH01'),
    ('CP04', 'seu.antonio', 'CH02'),
    ('CP05', 'jorge.ribeiro', 'CH02'),
    ('CP06', 'maria.helena', 'CH02'),
    ('CP07', 'rafael.mendes', 'CH03'),
    ('CP08', 'camila.santos', 'CH03'),
    ('CP09', 'pedro.augusto', 'CH03'),
    ('CP10', 'ana.beatriz', 'CH04'),
    ('CP11', 'lucas.ferreira', 'CH04'),
    ('CP12', 'diego.design', 'CH04')
) AS cp(str_id, author, chain_str_id)
ON scp.str_id = cp.str_id;

-- Atualizar first_post_id em cada corrente
UPDATE public.chains SET first_post_id = (SELECT post_id FROM _seed_chain_posts WHERE str_id = 'CP01') WHERE id = (SELECT chain_id FROM _seed_chains WHERE str_id = 'CH01');
UPDATE public.chains SET first_post_id = (SELECT post_id FROM _seed_chain_posts WHERE str_id = 'CP04') WHERE id = (SELECT chain_id FROM _seed_chains WHERE str_id = 'CH02');
UPDATE public.chains SET first_post_id = (SELECT post_id FROM _seed_chain_posts WHERE str_id = 'CP07') WHERE id = (SELECT chain_id FROM _seed_chains WHERE str_id = 'CH03');
UPDATE public.chains SET first_post_id = (SELECT post_id FROM _seed_chain_posts WHERE str_id = 'CP10') WHERE id = (SELECT chain_id FROM _seed_chains WHERE str_id = 'CH04');

DO $$ BEGIN RAISE NOTICE '>>> Fase 8 OK: 4 correntes e 12 posts de correntes inseridos.'; END $$;

-- ============================================================================
-- FASE 9: REAÇÕES (100 reações)
-- Gamificação ativa | Notificações desabilitadas
-- ============================================================================
CREATE TEMP TABLE _all_seed_posts AS
SELECT str_id, post_id FROM _seed_posts
UNION ALL
SELECT str_id, post_id FROM _seed_chain_posts;

INSERT INTO public.reactions (post_id, user_id, type, created_at)
SELECT
    (SELECT post_id FROM _all_seed_posts WHERE str_id = r.post_str_id),
    (SELECT user_id FROM _seed_users WHERE username = r.username),
    r.type,
    r.created_at::timestamptz
FROM (VALUES
    ('P01', 'vanessa.martins', 'loved', '2026-03-16 19:30:00+00'),
    ('P01', 'diego.design', 'claps', '2026-03-16 21:30:00+00'),
    ('P01', 'ricardo.alves', 'loved', '2026-03-16 23:30:00+00'),
    ('P02', 'vanessa.martins', 'claps', '2026-03-17 12:15:00+00'),
    ('P02', 'carlos.henrique', 'loved', '2026-03-17 14:15:00+00'),
    ('P03', 'vanessa.martins', 'hug', '2026-03-17 22:45:00+00'),
    ('P03', 'seu.antonio', 'loved', '2026-03-18 05:45:00+00'),
    ('P03', 'patricia.nunes', 'hug', '2026-03-18 09:45:00+00'),
    ('P04', 'rafael.mendes', 'claps', '2026-03-18 17:20:00+00'),
    ('P04', 'vanessa.martins', 'loved', '2026-03-18 18:20:00+00'),
    ('P04', 'lucas.ferreira', 'claps', '2026-03-18 19:20:00+00'),
    ('P04', 'carlos.henrique', 'claps', '2026-03-18 20:20:00+00'),
    ('P05', 'rafael.mendes', 'hug', '2026-03-18 20:00:00+00'),
    ('P05', 'ju.rocha', 'hug', '2026-03-18 21:00:00+00'),
    ('P05', 'renata.campos', 'loved', '2026-03-19 01:00:00+00'),
    ('P06', 'vanessa.martins', 'hug', '2026-03-19 12:15:00+00'),
    ('P06', 'jorge.ribeiro', 'loved', '2026-03-19 18:15:00+00'),
    ('P06', 'maria.helena', 'hug', '2026-03-20 08:15:00+00'),
    ('P07', 'dona.lucia', 'loved', '2026-03-19 16:30:00+00'),
    ('P07', 'vanessa.martins', 'hug', '2026-03-19 22:30:00+00'),
    ('P08', 'ricardo.alves', 'claps', '2026-03-19 22:40:00+00'),
    ('P08', 'diego.design', 'claps', '2026-03-19 23:10:00+00'),
    ('P08', 'thiago.costa', 'claps', '2026-03-20 00:10:00+00'),
    ('P09', 'rafael.mendes', 'claps', '2026-03-20 12:00:00+00'),
    ('P09', 'ju.rocha', 'claps', '2026-03-20 13:00:00+00'),
    ('P09', 'vanessa.martins', 'loved', '2026-03-20 14:00:00+00'),
    ('P09', 'ana.beatriz', 'claps', '2026-03-20 16:00:00+00'),
    ('P10', 'vanessa.martins', 'loved', '2026-03-20 18:45:00+00'),
    ('P10', 'rafael.mendes', 'claps', '2026-03-20 20:45:00+00'),
    ('P10', 'renata.campos', 'loved', '2026-03-21 05:45:00+00'),
    ('P11', 'ricardo.alves', 'hug', '2026-03-21 21:30:00+00'),
    ('P11', 'ju.rocha', 'hug', '2026-03-21 22:30:00+00'),
    ('P11', 'marcos.vinicius', 'hug', '2026-03-22 00:30:00+00'),
    ('P12', 'vanessa.martins', 'claps', '2026-03-21 11:40:00+00'),
    ('P12', 'camila.santos', 'loved', '2026-03-21 14:40:00+00'),
    ('P13', 'dona.lucia', 'loved', '2026-03-23 15:20:00+00'),
    ('P13', 'jorge.ribeiro', 'hug', '2026-03-24 03:20:00+00'),
    ('P14', 'rafael.mendes', 'loved', '2026-03-22 21:00:00+00'),
    ('P14', 'vanessa.martins', 'claps', '2026-03-22 23:00:00+00'),
    ('P14', 'ana.beatriz', 'loved', '2026-03-23 03:00:00+00'),
    ('P17', 'vanessa.martins', 'claps', '2026-03-24 12:30:00+00'),
    ('P17', 'rafael.mendes', 'loved', '2026-03-24 14:30:00+00'),
    ('P17', 'thiago.costa', 'claps', '2026-03-24 16:30:00+00'),
    ('P17', 'ana.beatriz', 'loved', '2026-03-24 19:30:00+00'),
    ('P18', 'dona.lucia', 'hug', '2026-03-24 13:30:00+00'),
    ('P18', 'seu.antonio', 'loved', '2026-03-24 19:30:00+00'),
    ('P18', 'maria.helena', 'hug', '2026-03-26 07:30:00+00'),
    ('P21', 'jorge.ribeiro', 'loved', '2026-03-25 12:45:00+00'),
    ('P21', 'dona.lucia', 'hug', '2026-03-25 16:45:00+00'),
    ('P24', 'seu.antonio', 'loved', '2026-03-27 11:20:00+00'),
    ('P24', 'vanessa.martins', 'hug', '2026-03-27 15:20:00+00'),
    ('P28', 'ju.rocha', 'claps', '2026-03-29 09:15:00+00'),
    ('P28', 'vanessa.martins', 'claps', '2026-03-29 11:15:00+00'),
    ('P28', 'camila.santos', 'claps', '2026-03-29 13:15:00+00'),
    ('P28', 'ana.beatriz', 'loved', '2026-03-29 15:15:00+00'),
    ('P30', 'dona.lucia', 'hug', '2026-03-31 04:45:00+00'),
    ('P30', 'maria.helena', 'loved', '2026-03-31 16:45:00+00'),
    ('P30', 'edson.pereira', 'loved', '2026-04-01 04:45:00+00'),
    ('P31', 'rafael.mendes', 'loved', '2026-03-30 20:15:00+00'),
    ('P31', 'ana.beatriz', 'claps', '2026-03-30 22:15:00+00'),
    ('P31', 'ju.rocha', 'loved', '2026-03-31 00:15:00+00'),
    ('P35', 'seu.antonio', 'hug', '2026-04-01 13:00:00+00'),
    ('P35', 'jorge.ribeiro', 'hug', '2026-04-01 17:00:00+00'),
    ('P35', 'vanessa.martins', 'loved', '2026-04-02 09:00:00+00'),
    ('P35', 'edson.pereira', 'hug', '2026-04-03 09:00:00+00'),
    ('P37', 'marcos.vinicius', 'claps', '2026-04-02 15:20:00+00'),
    ('P37', 'vanessa.martins', 'loved', '2026-04-02 17:20:00+00'),
    ('P37', 'camila.santos', 'claps', '2026-04-02 20:20:00+00'),
    ('P39', 'ricardo.alves', 'claps', '2026-04-03 22:00:00+00'),
    ('P39', 'pedro.augusto', 'claps', '2026-04-03 23:30:00+00'),
    ('P39', 'seu.antonio', 'loved', '2026-04-04 09:30:00+00'),
    ('P43', 'thiago.costa', 'claps', '2026-04-05 14:30:00+00'),
    ('P43', 'pedro.augusto', 'loved', '2026-04-05 16:30:00+00'),
    ('P43', 'diego.design', 'claps', '2026-04-05 18:30:00+00'),
    ('P47', 'dona.lucia', 'loved', '2026-04-06 16:15:00+00'),
    ('P47', 'seu.antonio', 'hug', '2026-04-06 22:15:00+00'),
    ('P49', 'rafael.mendes', 'hug', '2026-04-07 11:50:00+00'),
    ('P49', 'ricardo.alves', 'hug', '2026-04-07 15:50:00+00'),
    ('P52', 'carlos.henrique', 'claps', '2026-04-08 23:45:00+00'),
    ('P52', 'thiago.costa', 'claps', '2026-04-09 00:45:00+00'),
    ('P52', 'seu.antonio', 'loved', '2026-04-09 06:45:00+00'),
    ('P53', 'vanessa.martins', 'hug', '2026-04-08 16:15:00+00'),
    ('P53', 'ana.beatriz', 'hug', '2026-04-08 18:15:00+00'),
    ('P53', 'camila.santos', 'loved', '2026-04-08 22:15:00+00'),
    ('P56', 'ricardo.alves', 'claps', '2026-04-09 18:20:00+00'),
    ('P56', 'thiago.costa', 'claps', '2026-04-09 19:20:00+00'),
    ('P56', 'renata.campos', 'loved', '2026-04-09 22:20:00+00'),
    ('P56', 'rafael.mendes', 'claps', '2026-04-10 01:20:00+00'),
    ('P57', 'seu.antonio', 'hug', '2026-04-10 12:30:00+00'),
    ('P57', 'maria.helena', 'loved', '2026-04-10 16:30:00+00'),
    ('P57', 'edson.pereira', 'hug', '2026-04-11 08:30:00+00'),
    ('P66', 'vanessa.martins', 'loved', '2026-04-13 21:30:00+00'),
    ('P66', 'ju.rocha', 'claps', '2026-04-13 23:30:00+00'),
    ('P66', 'camila.santos', 'loved', '2026-04-14 03:30:00+00'),
    ('P67', 'carlos.henrique', 'loved', '2026-04-14 22:00:00+00'),
    ('P67', 'seu.antonio', 'loved', '2026-04-15 01:00:00+00'),
    ('P67', 'ricardo.alves', 'claps', '2026-04-15 05:00:00+00'),
    ('P70', 'vanessa.martins', 'loved', '2026-04-15 17:50:00+00'),
    ('P70', 'ricardo.alves', 'claps', '2026-04-15 19:50:00+00'),
    ('P70', 'camila.santos', 'claps', '2026-04-15 22:50:00+00')
) AS r(post_str_id, username, type, created_at);

DO $$ BEGIN RAISE NOTICE '>>> Fase 9 OK: 100 reações inseridas.'; END $$;

-- ============================================================================
-- FASE 10: COMENTÁRIOS (23 comentários)
-- ============================================================================
INSERT INTO public.comments (post_id, user_id, content, created_at)
SELECT
    (SELECT post_id FROM _all_seed_posts WHERE str_id = c.post_str_id),
    (SELECT user_id FROM _seed_users WHERE username = c.username),
    c.content,
    c.created_at::timestamptz
FROM (VALUES
    ('P04', 'lucas.ferreira', 'Cara, eu tava morrendo de medo de apontar aquilo. Obrigado por reconhecer, chefe.', '2026-03-18 18:20:00+00'),
    ('P04', 'vanessa.martins', 'Isso diz muito sobre a cultura que o Ricardo criou no time. Estagiário se sentir seguro pra discordar é raro.', '2026-03-18 21:20:00+00'),
    ('P06', 'jorge.ribeiro', 'O Antônio é assim desde que eu me lembro. Não espera pedir.', '2026-03-19 20:15:00+00'),
    ('P08', 'pedro.augusto', 'Eu não sou herói, sou burro mesmo kkkk mas valeu a bronca em casa', '2026-03-19 23:10:00+00'),
    ('P08', 'ricardo.alves', 'A esposa do Pedro, se estiver lendo: a culpa é do Carlos que marcou o jogo', '2026-03-20 00:10:00+00'),
    ('P09', 'rafael.mendes', 'Cami!!!!! Que orgulho! Lembro quando você disse que odiava correr hahaha', '2026-03-20 14:00:00+00'),
    ('P09', 'ana.beatriz', 'Chorei vendo essa foto. Sério. To muito feliz por você!', '2026-03-20 16:00:00+00'),
    ('P11', 'marcos.vinicius', 'Escutar é das coisas mais difíceis. Vanessa faz parecer fácil.', '2026-03-22 02:30:00+00'),
    ('P15', 'carlos.henrique', 'Eu QUASE fiz o gol ok? A bola desviou. Desviou. (Não desviou, mas me deixa sonhar.)', '2026-03-23 23:45:00+00'),
    ('P15', 'thiago.costa', 'o Carlos é assim, erra gol mas acerta amizade kkk', '2026-03-24 00:15:00+00'),
    ('P17', 'vanessa.martins', 'Posso confirmar: 100% verdade. O Ricardo nunca puxa crédito.', '2026-03-24 13:30:00+00'),
    ('P18', 'seu.antonio', 'Esse dia eu lembro. O Jorge era teimoso, não queria ajuda. Mas eu sou mais teimoso.', '2026-03-25 07:30:00+00'),
    ('P24', 'diego.design', 'Dona Lúcia, a senhora me faz mais falta do que a senhora imagina. Vou ligar hoje.', '2026-03-27 12:20:00+00'),
    ('P28', 'camila.santos', '100 dias!! Rafa, você me motivou a não faltar o treino de sábado quando tá chovendo', '2026-03-29 09:15:00+00'),
    ('P34', 'lucas.ferreira', 'Cara, eu nem sei o que dizer. Obrigado Thiago. De verdade.', '2026-04-02 02:00:00+00'),
    ('P35', 'dona.lucia', 'Minha querida Helena, não sabia que a senhora ia me fazer chorar logo cedo assim', '2026-04-01 13:00:00+00'),
    ('P37', 'ana.beatriz', 'Vocês vão me fazer chorar de novo. O Miguel ficou todo orgulhoso quando contei pra ele.', '2026-04-02 20:20:00+00'),
    ('P39', 'edson.pereira', 'Não me trata diferente pq sou velho? Gostei. Pq na próxima pelada eu passo por você de novo.', '2026-04-04 00:30:00+00'),
    ('P47', 'jorge.ribeiro', 'Helena, o Bento adorou. Pediu pra senhora escrever outro pro aniversário do irmão dele haha', '2026-04-06 12:15:00+00'),
    ('P52', 'edson.pereira', 'Descalço mesmo, e a bola era de meia com jornal dentro kkk. Mas o amor pela bola era de verdade.', '2026-04-08 23:45:00+00'),
    ('P56', 'lucas.ferreira', 'Caramba, tô emocionado. Obrigado Carlos. E obrigado por ter tido paciência comigo quando eu não sabia nada.', '2026-04-09 18:20:00+00'),
    ('P56', 'ricardo.alves', 'Esse é o ciclo bonito: a gente ensina, e um dia não precisa mais ensinar. Parabéns Lucas!', '2026-04-09 20:20:00+00'),
    ('P66', 'marcos.vinicius', 'Rafa, eu falei porque eu vi. Você que fez o trabalho difícil de acreditar. Orgulho de correr contigo.', '2026-04-13 20:30:00+00')
) AS c(post_str_id, username, content, created_at);

DO $$ BEGIN RAISE NOTICE '>>> Fase 10 OK: 23 comentários inseridos.'; END $$;

-- ============================================================================
-- FASE 11: FEEDBACKS (12 feedbacks)
-- Schema não-padrão: author_id = autor do POST | mentioned_user_id = quem escreveu o feedback
-- ============================================================================
INSERT INTO public.feedbacks (post_id, author_id, mentioned_user_id, feedback_text, created_at)
SELECT
    (SELECT post_id FROM _all_seed_posts WHERE str_id = fb.post_str_id),
    (SELECT user_id FROM _seed_users WHERE username = fb.post_author),
    (SELECT user_id FROM _seed_users WHERE username = fb.feedback_author),
    fb.content,
    fb.created_at::timestamptz
FROM (VALUES
    ('P01', 'rafael.mendes', 'ju.rocha', 'Rafa, a gente é time. Não precisa agradecer. Mas... obrigada por notar. Isso importa mais do que o CSS.', '2026-03-16 21:30:00+00'),
    ('P03', 'diego.design', 'dona.lucia', 'Meu filho, eu não sabia que você sentia isso. Agora eu sei. E agora eu vou ligar mais vezes. Cuida-se, viu?', '2026-03-18 21:45:00+00'),
    ('P05', 'vanessa.martins', 'ana.beatriz', 'Van, obrigada por contar essa história com tanto cuidado. E obrigada por ter sido o chão que eu precisava naquele dia.', '2026-03-18 21:00:00+00'),
    ('P07', 'seu.antonio', 'dona.lucia', 'Antônio, você fala pouco mas faz muito. Sempre foi assim. E é por isso que meu bolo de fubá é sempre pra você primeiro.', '2026-03-19 18:30:00+00'),
    ('P10', 'thiago.costa', 'ricardo.alves', 'Thiago, obrigado. Mas o mérito é todo seu: é a sua curiosidade que faz eu querer ensinar. Não para.', '2026-03-20 23:45:00+00'),
    ('P13', 'patricia.nunes', 'maria.helena', 'Patrícia querida, a elegância que você descreve é só o resultado de ter errado muito e aprendido a pedir desculpa. Obrigada pelo carinho.', '2026-03-24 15:20:00+00'),
    ('P17', 'renata.campos', 'ricardo.alves', 'Renata, eu só faço o que qualquer líder deveria fazer. Mas obrigado por enxergar isso. Faz eu querer continuar acertando.', '2026-03-24 19:30:00+00'),
    ('P22', 'diego.design', 'rafael.mendes', 'Diego, feedback bom é igual design bom: muda tudo sem a pessoa perceber que mudou. Fico feliz que funcionou.', '2026-03-26 18:15:00+00'),
    ('P31', 'vanessa.martins', 'ricardo.alves', 'Van, eu aprendi que liderar é proteger, não expor. Mas obrigado por reconhecer. Isso me motiva a continuar nesse caminho.', '2026-03-31 07:15:00+00'),
    ('P37', 'renata.campos', 'ana.beatriz', 'Renata, eu chorei lendo isso. O Miguel perguntou por que eu tava chorando e eu disse ''porque alguém viu a mamãe''. Obrigada.', '2026-04-02 18:20:00+00'),
    ('P53', 'renata.campos', 'marcos.vinicius', 'Renata, eu fiquei porque queria ficar. E porque no km 38, quando suas pernas param, é a cabeça que decide. A sua decidiu continuar. Eu só fiz companhia.', '2026-04-08 17:15:00+00'),
    ('P56', 'carlos.henrique', 'lucas.ferreira', 'Carlos, eu li isso umas 5 vezes. ''Virar desnecessário''. É isso. Obrigado por tudo, cara. De verdade.', '2026-04-09 19:20:00+00')
) AS fb(post_str_id, post_author, feedback_author, content, created_at);

DO $$ BEGIN RAISE NOTICE '>>> Fase 11 OK: 12 feedbacks inseridos.'; END $$;

-- ============================================================================
-- FASE 12: REABILITAR TRIGGERS DE NOTIFICAÇÃO
-- ============================================================================
ALTER TABLE public.posts     ENABLE TRIGGER holofote_notification_trigger;
ALTER TABLE public.reactions ENABLE TRIGGER reaction_notification_simple_trigger;
ALTER TABLE public.comments  ENABLE TRIGGER comment_notification_correto_trigger;
ALTER TABLE public.feedbacks ENABLE TRIGGER feedback_notification_correto_trigger;

-- Limpar notificações residuais geradas durante o seed
DELETE FROM public.notifications
WHERE from_user_id IN (SELECT user_id FROM _seed_users);

DO $$ BEGIN RAISE NOTICE '>>> Fase 12 OK: triggers reabilitados, notificações de seed limpas.'; END $$;

-- ============================================================================
-- FASE 13: LIMPEZA DAS TABELAS TEMPORÁRIAS
-- ============================================================================
DROP TABLE IF EXISTS _seed_users;
DROP TABLE IF EXISTS _seed_communities;
DROP TABLE IF EXISTS _seed_posts;
DROP TABLE IF EXISTS _seed_chains;
DROP TABLE IF EXISTS _seed_chain_posts;
DROP TABLE IF EXISTS _all_seed_posts;

DO $$ BEGIN RAISE NOTICE '>>> Fase 13 OK: tabelas temporárias removidas.'; END $$;
DO $$ BEGIN RAISE NOTICE '>>> SEED CONCLUÍDO COM SUCESSO! Execute o bloco de VALIDAÇÃO abaixo.'; END $$;

COMMIT;

-- ============================================================================
