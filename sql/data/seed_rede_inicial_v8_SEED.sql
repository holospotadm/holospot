-- ============================================================
-- HoloSpot: Seed Data v8 — Rede Inicial
-- Gerado em: 2026-04-28
-- Insumo: holospot_seed_complete_v3.json
-- 20 perfis | 3 comunidades | 135 follows
-- 82 posts | 4 correntes
-- 504 reações | 163 comentários | 71 feedbacks
--
-- ARQUITETURA v8: temp tables com IDs simbólicos (P01..P70, CP01..CP12)
-- Elimina todas as buscas por content — JOIN por str_id
-- Schema real consultado via information_schema em 2026-04-28
-- ============================================================

BEGIN;

-- ============================================================
-- FASE 0: Verificar UUID do Gui (ABORTARÁ se não encontrado)
-- ============================================================
DO $$
DECLARE
    gui_uuid uuid;
BEGIN
    SELECT id INTO gui_uuid FROM auth.users WHERE email = 'guilherme.dutra@b11c.com';
    IF gui_uuid IS NULL THEN
        RAISE EXCEPTION 'ERRO CRÍTICO: Perfil do Gui não encontrado! Abortando.';
    END IF;
    RAISE NOTICE 'UUID do Gui confirmado: %', gui_uuid;
END $$;

-- ============================================================
-- FASE 1: Limpeza total do banco
-- Deleta TUDO exceto guilherme.dutra@b11c.com
-- ============================================================
DELETE FROM public.notifications;
DELETE FROM public.points_history;
DELETE FROM public.user_badges;
DELETE FROM public.user_streaks;
DELETE FROM public.user_points;
DELETE FROM public.feedbacks;
DELETE FROM public.comments;
DELETE FROM public.reactions;
DELETE FROM public.chain_posts;
DELETE FROM public.chains;
DELETE FROM public.posts;
DELETE FROM public.community_members;
DELETE FROM public.communities;
DELETE FROM public.follows;
DELETE FROM public.messages;
DELETE FROM public.conversations;
DELETE FROM public.invites;
DELETE FROM public.waitlist;

DELETE FROM public.profiles
WHERE id != (SELECT id FROM auth.users WHERE email = 'guilherme.dutra@b11c.com');

DELETE FROM auth.users
WHERE email != 'guilherme.dutra@b11c.com';

UPDATE public.profiles
SET community_owner = false,
    has_completed_onboarding = false
WHERE id = (SELECT id FROM auth.users WHERE email = 'guilherme.dutra@b11c.com');

DO $$ BEGIN RAISE NOTICE 'FASE 1 concluída: banco limpo, Gui preservado.'; END $$;

-- ============================================================
-- FASE 2: Migration — adicionar campo bio em profiles (se não existir)
-- ============================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;

DO $$ BEGIN RAISE NOTICE 'FASE 2 concluída: campo bio garantido.'; END $$;

-- ============================================================
-- FASE 3: Inserir 20 usuários em auth.users
-- ============================================================
INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, role)
VALUES
    (gen_random_uuid(), 'rafael.mendes@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Rafael Mendes"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'ju.rocha@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Juliana Rocha"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'diego.design@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Diego Oliveira"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'ricardo.alves@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Ricardo Alves"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'dona.lucia@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"L\u00facia Maria Santos"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'seu.antonio@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Ant\u00f4nio Carlos Ferreira"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'vanessa.martins@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Vanessa Martins"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'carlos.henrique@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Carlos Henrique Lima"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'ana.beatriz@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Ana Beatriz Costa"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'marcos.vinicius@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Marcos Vin\u00edcius Souza"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'patricia.nunes@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Patr\u00edcia Nunes"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'thiago.costa@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Thiago Costa"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'fernanda.lima@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Fernanda Lima Oliveira"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'jorge.ribeiro@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Jorge Ribeiro"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'camila.santos@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Camila Santos Pereira"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'pedro.augusto@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Pedro Augusto Silva"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'maria.helena@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Maria Helena Duarte"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'lucas.ferreira@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Lucas Ferreira Neto"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'renata.campos@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Renata Campos"}'::jsonb, false, 'authenticated'),
    (gen_random_uuid(), 'edson.pereira@seed.holospot.com', now(), now(), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Edson Pereira"}'::jsonb, false, 'authenticated');

DO $$ BEGIN RAISE NOTICE 'FASE 3 concluída: 20 usuários criados em auth.users.'; END $$;

-- ============================================================
-- FASE 4: Inserir 20 profiles
-- ============================================================
INSERT INTO public.profiles (id, email, name, username, birth_date, timezone, bio, has_completed_onboarding, community_owner, created_at)
SELECT
    u.id,
    u.email,
    p.name,
    p.username,
    p.birth_date::date,
    'America/Sao_Paulo',
    p.bio,
    true,
    false,
    now()
FROM auth.users u
JOIN (VALUES
    ('rafael.mendes@seed.holospot.com', 'Rafael Mendes', 'rafael.mendes', '1991-07-14', 'Dev frontend, pai do Theo, corredor de fim de semana'),
    ('ju.rocha@seed.holospot.com', 'Juliana Rocha', 'ju.rocha', '1988-03-22', 'UX designer, mãe da Liz, tentando sobreviver ao home office'),
    ('diego.design@seed.holospot.com', 'Diego Oliveira', 'diego.design', '1995-11-03', 'Designer visual, fotógrafo nas horas vagas'),
    ('ricardo.alves@seed.holospot.com', 'Ricardo Alves', 'ricardo.alves', '1985-09-08', 'Tech lead, corintiano sofredor, churrasqueiro oficial'),
    ('dona.lucia@seed.holospot.com', 'Lúcia Maria Santos', 'dona.lucia', '1958-05-30', 'Aposentada, avó de 4, adora cozinhar e contar histórias'),
    ('seu.antonio@seed.holospot.com', 'Antônio Carlos Ferreira', 'seu.antonio', '1955-12-17', 'Carpinteiro aposentado, palmeirense raiz, avô coruja'),
    ('vanessa.martins@seed.holospot.com', 'Vanessa Martins', 'vanessa.martins', '1993-01-25', 'Product manager, corredora, viciada em café especial'),
    ('carlos.henrique@seed.holospot.com', 'Carlos Henrique Lima', 'carlos.henrique', '1990-04-11', 'Backend dev, pai de gêmeos, sobrevivente de deploy sexta à noite'),
    ('ana.beatriz@seed.holospot.com', 'Ana Beatriz Costa', 'ana.beatriz', '1987-08-19', 'Scrum master, mãe solo do Miguel, aprendendo a correr'),
    ('marcos.vinicius@seed.holospot.com', 'Marcos Vinícius Souza', 'marcos.vinicius', '1982-06-05', 'Gerente de projetos, triatleta, faz pão aos domingos'),
    ('patricia.nunes@seed.holospot.com', 'Patrícia Nunes', 'patricia.nunes', '1979-02-14', 'Professora de história, mãe da Clara e do Pedro, leitora compulsiva'),
    ('thiago.costa@seed.holospot.com', 'Thiago Costa', 'thiago.costa', '1997-10-28', 'Estagiário dev, estudante de CC, flamenguista convicto'),
    ('fernanda.lima@seed.holospot.com', 'Fernanda Lima Oliveira', 'fernanda.lima', '1992-12-01', 'Data analyst, cozinheira experimental, mãe de gato'),
    ('jorge.ribeiro@seed.holospot.com', 'Jorge Ribeiro', 'jorge.ribeiro', '1960-03-09', 'Engenheiro aposentado, avô do Bento, caminhante de parque'),
    ('camila.santos@seed.holospot.com', 'Camila Santos Pereira', 'camila.santos', '1994-07-22', 'QA engineer, violonista amadora, corredora de 5k'),
    ('pedro.augusto@seed.holospot.com', 'Pedro Augusto Silva', 'pedro.augusto', '1986-11-15', 'DevOps, pai da Sofia, vascaíno em terapia'),
    ('maria.helena@seed.holospot.com', 'Maria Helena Duarte', 'maria.helena', '1952-08-03', 'Professora aposentada, poeta de gaveta, bisavó do Mateus'),
    ('lucas.ferreira@seed.holospot.com', 'Lucas Ferreira Neto', 'lucas.ferreira', '1998-05-20', 'Dev júnior, gamer nas horas vagas, aprendendo a cozinhar'),
    ('renata.campos@seed.holospot.com', 'Renata Campos', 'renata.campos', '1983-09-12', 'Engineering manager, maratonista, mãe do Davi'),
    ('edson.pereira@seed.holospot.com', 'Edson Pereira', 'edson.pereira', '1963-04-18', 'Motorista de ônibus aposentado, são-paulino, avô do Nicolas')
) AS p(email, name, username, birth_date, bio) ON u.email = p.email;

DO $$ BEGIN RAISE NOTICE 'FASE 4 concluída: 20 profiles inseridos.'; END $$;

-- ============================================================
-- FASE 5: Criar temp table de mapeamento username → uuid
-- Usada por todas as fases seguintes
-- ============================================================
CREATE TEMP TABLE _seed_profile_map AS
SELECT username, id AS user_id
FROM public.profiles
WHERE email LIKE '%@seed.holospot.com';

DO $$ BEGIN RAISE NOTICE 'FASE 5 concluída: mapa de perfis criado.'; END $$;

-- ============================================================
-- FASE 6: Habilitar community_owner + criar comunidades e membros
-- ============================================================
UPDATE public.profiles SET community_owner = true
WHERE id = (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius');
UPDATE public.profiles SET community_owner = true
WHERE id = (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique');
UPDATE public.profiles SET community_owner = true
WHERE id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves');

INSERT INTO public.communities (id, name, slug, description, emoji, owner_id, created_at)
VALUES
    (gen_random_uuid(), 'Time Tech', 'time-tech', 'Nosso espaço pra reconhecer quem faz a diferença no dia a dia do trabalho', '💻', (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'), now()),
    (gen_random_uuid(), 'Pelada de Quinta', 'pelada-quinta', 'Quem joga junto, reconhece junto', '⚽', (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'), now()),
    (gen_random_uuid(), 'Corre SP', 'corre-sp', 'Corredores de São Paulo e região — cada km conta', '🏃', (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'), now());

INSERT INTO public.community_members (id, community_id, user_id, role, joined_at)
VALUES
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'), 'owner', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'time-tech'), (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'), 'owner', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'), (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'), 'owner', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'patricia.nunes'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'), 'member', now()),
    (gen_random_uuid(), (SELECT id FROM public.communities WHERE slug = 'corre-sp'), (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'), 'member', now());

DO $$ BEGIN RAISE NOTICE 'FASE 6 concluída: comunidades e membros criados.'; END $$;

-- ============================================================
-- FASE 7: Desabilitar os 8 triggers de notificação
-- Nomes confirmados via sql/triggers/ do repositório
-- ============================================================
ALTER TABLE public.posts DISABLE TRIGGER holofote_notification_trigger;
ALTER TABLE public.reactions DISABLE TRIGGER reaction_notification_simple_trigger;
ALTER TABLE public.comments DISABLE TRIGGER comment_notification_correto_trigger;
ALTER TABLE public.feedbacks DISABLE TRIGGER feedback_notification_correto_trigger;
ALTER TABLE public.follows DISABLE TRIGGER follow_notification_correto_trigger;
ALTER TABLE public.user_points DISABLE TRIGGER level_up_notification_trigger;
ALTER TABLE public.user_badges DISABLE TRIGGER badge_notify_only_trigger;
ALTER TABLE public.user_streaks DISABLE TRIGGER streak_notify_only_trigger;

DO $$ BEGIN RAISE NOTICE 'FASE 7 concluída: 8 triggers de notificação desabilitados.'; END $$;

-- ============================================================
-- FASE 8: Inserir 135 follows
-- ============================================================
INSERT INTO public.follows (follower_id, following_id, created_at)
SELECT
    (SELECT user_id FROM _seed_profile_map WHERE username = f.follower),
    (SELECT user_id FROM _seed_profile_map WHERE username = f.following),
    now()
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

DO $$ BEGIN RAISE NOTICE 'FASE 8 concluída: follows inseridos.'; END $$;

-- ============================================================
-- FASE 9: Inserir 70 posts globais e de comunidade
-- ============================================================
-- P01: rafael.mendes → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
    '@ju.rocha',
    'Ontem a @ju.rocha ficou meia hora depois do expediente me ajudando a debugar um problema de CSS que eu já tava prestes a desistir. Não era responsabilidade dela, não ia render nenhum crédito, mas ela sentou do meu lado (virtualmente) e resolveu em 15 minutos o que eu tava apanhando há 2 horas. Obrigado, Ju.',
    'gratitude',
    NULL,
    '2026-03-16 18:30:00+00'
);

-- P02: ju.rocha → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha'),
    '@rafael.mendes',
    'O @rafael.mendes chegou hoje na daily com aquele componente pronto que todo mundo achava que ia levar a sprint inteira. E sabe o que mais? Ele documentou tudo. TUDO. Rafa, você me inspira a ser uma dev melhor.',
    'inspiration',
    NULL,
    '2026-03-17 10:15:00+00'
);

-- P03: diego.design → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'),
    '@dona.lucia',
    'Minha avó mora longe e eu não consigo visitar tanto quanto queria. Mas toda vez que ligo pra @dona.lucia (que nem é minha avó de sangue, é vizinha da minha mãe), ela pergunta se eu tô comendo direito, se tô dormindo bem, se tô feliz. Dona Lúcia, a senhora me faz falta sem nem saber.',
    'memory',
    NULL,
    '2026-03-17 21:45:00+00'
);

-- P04: ricardo.alves → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'),
    '@thiago.costa',
    'O @thiago.costa é estagiário há 4 meses. Hoje ele fez um code review no meu PR e encontrou um bug que eu, com 15 anos de experiência, não vi. Não ficou com medo de apontar, não pediu desculpa por discordar. Mandou a observação com respeito e estava certo. Esse moleque vai longe.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-18 16:20:00+00'
);

-- P05: vanessa.martins → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '@ana.beatriz',
    'A @ana.beatriz tá passando por uma fase difícil pessoalmente (com a autorização dela pra eu contar isso). E mesmo assim, ela não deixou a peteca cair em nenhuma entrega. Mas o que eu quero reconhecer não é a produtividade — é a coragem de pedir ajuda quando precisou. Ana, obrigada por confiar em mim.',
    'support',
    NULL,
    '2026-03-18 19:00:00+00'
);

-- P06: dona.lucia → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia'),
    '@seu.antonio',
    'O Antônio, meu vizinho de tantos anos... ontem ele apareceu aqui em casa com a prateleira da cozinha que tava caindo consertada. Eu nem tinha pedido, ele viu da última vez que veio tomar café e voltou com as ferramentas. Esse homem tem um coração que não cabe no peito.',
    'gratitude',
    NULL,
    '2026-03-19 08:15:00+00'
);

-- P07: seu.antonio → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'),
    '@dona.lucia',
    'A Lúcia fez bolo de fubá pra mim ontem. Sem motivo. Disse que lembrou que eu gostava. Às vezes a gente subestima o poder de alguém lembrar da gente.',
    'gratitude',
    NULL,
    '2026-03-19 14:30:00+00'
);

-- P08: carlos.henrique → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'),
    '@pedro.augusto',
    'O @pedro.augusto podia ter ido embora depois do primeiro tempo (o cara tinha acordo com a esposa pra voltar cedo). Mas ficou porque tava 3x2 e a gente precisava dele no gol. Resultado: tomou esporro em casa, mas salvou o jogo. Pedro, sua esposa tem razão, mas a gente te ama.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-03-19 22:10:00+00'
);

-- P09: marcos.vinicius → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'),
    '@camila.santos',
    'A @camila.santos correu a primeira 10k dela hoje. Ela começou em janeiro sem conseguir fazer 1km sem parar. Quatro meses depois, cruzou a linha dos 10km com um sorriso que eu nunca vou esquecer. Cami, isso é só o começo.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-03-20 11:00:00+00'
);

-- P10: thiago.costa → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'),
    '@ricardo.alves',
    'O @ricardo.alves podia ser aquele tech lead que só cobra e delega. Mas toda vez que eu travo em algo, ele para o que tá fazendo e senta comigo pra entender o problema. Não dá a resposta pronta — me faz pensar. Tô aprendendo mais em 4 meses do que em 2 anos de faculdade.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-20 17:45:00+00'
);

-- P11: ana.beatriz → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
    '@vanessa.martins',
    'Semana passada eu desabei numa call com a @vanessa.martins — chorei, contei tudo, fiz aquele papel que a gente tem vergonha de fazer no trabalho. Sabe o que ela fez? Não deu conselho. Não tentou resolver. Só ouviu. Às vezes ouvir é o maior presente que alguém pode dar.',
    'gratitude',
    NULL,
    '2026-03-21 20:30:00+00'
);

-- P12: fernanda.lima → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima'),
    '@rafael.mendes',
    'Percebi um padrão no @rafael.mendes que quero registrar: em toda retro, ele fala pelo menos uma coisa positiva sobre alguém do time antes de falar de problemas. Parece pequeno mas muda o tom da conversa inteira. Comecei a fazer igual na minha squad.',
    'inspiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-21 09:40:00+00'
);

-- P13: patricia.nunes → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'patricia.nunes'),
    '@maria.helena',
    'Conheci a @maria.helena numa roda de leitura. Ela tem 73 anos e lê mais que qualquer pessoa que eu conheço. Mas o que me impressiona não é a quantidade — é como ela escuta a opinião de todo mundo com a mesma atenção, sem nunca fazer ninguém se sentir menor. Que eu tenha essa elegância quando chegar lá.',
    'admiration',
    NULL,
    '2026-03-22 15:20:00+00'
);

-- P14: camila.santos → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'),
    '@marcos.vinicius',
    'O @marcos.vinicius me mandou mensagem no sábado de manhã pra saber se eu ia pro treino. Eu não ia — tava chovendo, tava com preguiça, tava inventando desculpa. Ele disse: ''Vem, eu te espero no km 3.'' E esperou. Marcos, obrigada por não me deixar desistir.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-03-22 19:00:00+00'
);

-- P15: pedro.augusto → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'),
    '@carlos.henrique',
    'Quinta passada o @carlos.henrique errou um gol feito (sim, a bola ia entrar sozinha e ele conseguiu errar). Todo mundo zoou, claro. Mas depois do jogo ele me mandou áudio perguntando se eu tava bem porque me viu quieto. O cara erra gol mas não erra a leitura de um amigo. Prioridades certas.',
    'support',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-03-23 23:15:00+00'
);

-- P16: lucas.ferreira → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'),
    '@thiago.costa',
    'O @thiago.costa e eu entramos juntos como estagiários. Tinha tudo pra ser competição. Mas quando eu travei na primeira task, ele sentou comigo e dividiu as anotações dele. A gente poderia estar competindo por vaga e em vez disso tá crescendo junto. Valeu, Thiago.',
    'support',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-23 14:00:00+00'
);

-- P17: renata.campos → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'),
    '@ricardo.alves',
    'Preciso falar do @ricardo.alves como líder técnico. Em 6 meses trabalhando com ele, nunca vi ele puxar crédito pra si. Quando o projeto vai bem, ele fala ''o time entregou''. Quando algo dá errado, ele fala ''eu não vi esse risco''. Liderança é isso.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-24 11:30:00+00'
);

-- P18: jorge.ribeiro → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro'),
    '@edson.pereira',
    'Lembrei hoje do Edson me ensinando a trocar pneu em 1987. A gente mal se conhecia, eu tinha acabado de me mudar pro bairro. Ele parou o carro dele, veio até o meu e ficou ali até eu conseguir sozinho. Quase 40 anos depois, @edson.pereira ainda é assim: para o que tá fazendo pra ajudar.',
    'memory',
    NULL,
    '2026-03-24 07:30:00+00'
);

-- P19: maria.helena → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena'),
    '@patricia.nunes',
    'A @patricia.nunes me ensinou que nunca é tarde pra aprender. Ela que é professora virou minha aluna quando eu comecei a contar histórias na roda de leitura. Me ouvir com aqueles olhos atentos me fez acreditar que minhas memórias ainda importam.',
    'inspiration',
    NULL,
    '2026-03-25 10:00:00+00'
);

-- P20: vanessa.martins → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '@fernanda.lima',
    'Quero reconhecer a @fernanda.lima por algo que pouca gente viu: ela refez a dashboard de métricas 3 vezes porque não tava satisfeita com a clareza dos dados. Ninguém pediu, ninguém cobrou. Ela fez porque acredita que dado confuso desinforma. O resultado ficou impecável.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-25 16:00:00+00'
);

-- P21: edson.pereira → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira'),
    '@seu.antonio',
    'O Antônio carrega 70 anos nas costas e humildade no jeito. Outro dia tava ensinando o neto a lixar madeira com a mesma paciência que ensinou a mim 30 anos atrás. Não mudou. @seu.antonio é uma aula viva.',
    'admiration',
    NULL,
    '2026-03-25 08:45:00+00'
);

-- P22: diego.design → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'),
    '@rafael.mendes',
    'Entreguei um layout semana passada que eu achava bom. O @rafael.mendes olhou, ficou quieto uns segundos e disse: ''E se a gente invertesse a hierarquia visual aqui?'' Poderia ter dito ''não gostei''. Em vez disso, me deu uma direção melhor sem invalidar o meu trabalho. Faz diferença demais.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-26 13:15:00+00'
);

-- P23: ricardo.alves → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'),
    '@renata.campos',
    'A @renata.campos correu a maratona de São Paulo domingo. 42km. Sabe o que ela fez na segunda? Chegou no trabalho às 9 em ponto, com o joelho enfaixado e um sorriso. Quando perguntei se não queria folga, ela disse: ''Corri porque quis, trabalho porque gosto. Uma coisa não cancela a outra.'' Inspira.',
    'inspiration',
    NULL,
    '2026-03-26 18:00:00+00'
);

-- P24: dona.lucia → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia'),
    '@diego.design',
    'Esse menino, o @diego.design — ligou pra mim outro dia só pra dizer que tava com saudade. Vocês não sabem o que isso significa pra quem mora sozinha. Ele não é da minha família, mas é da minha vida. Deus abençoe esse rapaz.',
    'gratitude',
    NULL,
    '2026-03-27 09:20:00+00'
);

-- P25: ana.beatriz → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
    '@marcos.vinicius',
    'O @marcos.vinicius sempre chega primeiro no treino e sai por último. Mas não é por performance — é porque ele espera todo mundo chegar e se certifica que todo mundo terminou bem. Sábado passado ficou esperando eu terminar meu pace (lento, eu sei) sem pressa nenhuma. Líder é quem espera.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-03-27 17:30:00+00'
);

-- P26: carlos.henrique → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'),
    '@diego.design',
    'O @diego.design não é o melhor jogador da pelada (desculpa, Diego). Mas é o cara que todo mundo quer no time. Sabe por quê? Porque ele comemora o gol dos outros como se fosse dele. Na quinta passada fez uma corrida de 30 metros pra abraçar o Lucas depois do gol. Esse espírito não se ensina.',
    'inspiration',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-03-28 22:40:00+00'
);

-- P27: ju.rocha → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha'),
    '@camila.santos',
    'A @camila.santos tava insegura com a apresentação que ia fazer pro cliente. Me mandou o deck às 11 da noite pedindo opinião. Eu dei feedback honesto: 3 slides precisavam de ajuste. Sabe o que ela fez? Refez os 3 e me mandou de novo às 6 da manhã. Não pediu validação, pediu evolução. Camila, você é fera.',
    'support',
    NULL,
    '2026-03-28 08:50:00+00'
);

-- P28: marcos.vinicius → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'),
    '@rafael.mendes',
    'O @rafael.mendes completou 100 dias seguidos de treino hoje. Cem. Chuva, sol, viagem, criança doente — ele achou um jeito. Nem todo dia foi uma corrida longa, às vezes foram 15 minutos de esteira no hotel. Mas a consistência tá aí. Rafa, chapéu.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-03-29 07:15:00+00'
);

-- P29: thiago.costa → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'),
    '@lucas.ferreira',
    'O @lucas.ferreira tava travado num bug há 2 dias e com vergonha de pedir ajuda. Eu percebi porque ele tava quieto demais no Slack. Chamei ele num privado e a gente resolveu em 40 min. Lucas, nunca tenha vergonha de travar. Todo mundo trava. O importante é não travar sozinho.',
    'support',
    NULL,
    '2026-03-29 15:30:00+00'
);

-- P30: seu.antonio → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'),
    '@jorge.ribeiro',
    'Outro dia eu e o @jorge.ribeiro ficamos sentados no banco da praça sem falar nada por uns 20 minutos. Só ali. Depois ele disse: ''Tá bom assim.'' E tava. Nem toda amizade precisa de conversa. Algumas só precisam de presença.',
    'memory',
    NULL,
    '2026-03-30 16:45:00+00'
);

-- P31: vanessa.martins → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '@ricardo.alves',
    'Situação real: eu errei feio num alinhamento com stakeholder. Tipo, errei de verdade. O @ricardo.alves podia ter me exposto na reunião, podia ter corrigido na frente de todo mundo. Sabe o que ele fez? Me chamou no privado, me ajudou a montar um plano de correção e disse: ''A gente conserta junto.'' Liderança de verdade, pessoal.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-03-30 19:15:00+00'
);

-- P32: fernanda.lima → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima'),
    '@vanessa.martins',
    'Faço uma observação sobre a @vanessa.martins — ela é a pessoa que mais lembra de aniversários, datas importantes e gostos pessoais de cada um do time. Parece bobagem, mas quando ela manda um ''feliz aniversário, Fer, sei que você gosta de café coado então deixei um pacote na sua mesa'', isso cria pertencimento.',
    'admiration',
    NULL,
    '2026-03-31 10:30:00+00'
);

-- P33: camila.santos → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'),
    '@ju.rocha',
    'Obrigada @ju.rocha por ter sido honesta comigo sobre a apresentação. Eu queria ouvir ''tá ótimo'' e você me deu algo melhor: ''tá bom, mas pode ser excelente''. Esse feedback me fez crescer mais do que qualquer elogio faria.',
    'gratitude',
    NULL,
    '2026-03-31 12:00:00+00'
);

-- P34: pedro.augusto → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'),
    '@thiago.costa',
    'O @thiago.costa tem 21 anos e já entende algo que muita gente de 40 não entende: que time é mais importante que ego. Na quinta passada ele tava jogando bem pra caramba, fazendo gol, dominando. Aí viu que o Lucas tava pra baixo e começou a passar a bola só pra ele. O Lucas fez o gol da virada. O sorriso do Thiago era maior que o do Lucas.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-04-01 23:00:00+00'
);

-- P35: maria.helena → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena'),
    '@dona.lucia',
    'Eu e a @dona.lucia nos conhecemos em 1985, numa fila de banco. Ela tava com um bebê no colo e eu ajudei a segurar a bolsa. Quarenta anos depois, aquele bebê já é pai, e nós duas ainda tomamos café juntas quando dá. Algumas amizades não precisam de motivo pra começar — só de disposição pra continuar.',
    'memory',
    NULL,
    '2026-04-01 09:00:00+00'
);

-- P36: rafael.mendes → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
    '@ricardo.alves',
    'Uma coisa sobre o @ricardo.alves que ninguém fala: ele responde mensagem de todo mundo. Estagiário, PM, designer, o cara de infra que ninguém conhece. Todo mundo tem acesso a ele. Isso parece básico, mas eu já trabalhei em lugar onde tech lead era intocável. O Ricardo não é assim. E isso muda tudo.',
    'admiration',
    NULL,
    '2026-04-02 11:40:00+00'
);

-- P37: renata.campos → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'),
    '@ana.beatriz',
    'Quero celebrar a @ana.beatriz — ela começou a correr há 5 meses, como mãe solo, encaixando treino na hora do almoço. Sábado ela completou a primeira meia-maratona. 21km. Quando cruzou a linha, a primeira coisa que fez foi ligar pro filho. Ana, você ensina o Miguel pelo exemplo.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-04-02 14:20:00+00'
);

-- P38: lucas.ferreira → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'),
    '@carlos.henrique',
    'O @carlos.henrique me explicou git rebase umas 5 vezes. Cinco. Na quinta vez eu entendi (mais ou menos). Ele podia ter perdido a paciência na segunda. Mas em nenhum momento ele fez eu me sentir burro. Carlos, obrigado por tratar minha ignorância com respeito.',
    'gratitude',
    NULL,
    '2026-04-03 16:50:00+00'
);

-- P39: edson.pereira → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira'),
    '@carlos.henrique',
    'Eu tenho 62 anos e jogo na pelada com moleque de 25. O @carlos.henrique nunca me tratou diferente. Pede passe, cobra marcação, comemora comigo. Não tem esse negócio de ''ah, o tio tá cansado''. Respeito é isso: me tratar como igual.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-04-03 21:30:00+00'
);

-- P40: ju.rocha → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha'),
    '@diego.design',
    'O @diego.design recebeu um feedback duro sobre um layout na semana passada. Em vez de ficar na defensiva (que seria compreensível), ele veio no dia seguinte com 3 versões alternativas e perguntou: ''qual caminho vocês preferem?'' Maturidade profissional não tem nada a ver com idade.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-04 09:30:00+00'
);

-- P41: diego.design → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'),
    '@vanessa.martins',
    'A @vanessa.martins percebeu que eu não tava bem antes de eu mesmo perceber. Me mandou mensagem: ''Quer tomar um café?'' Não perguntou o que eu tinha, não pressionou. Só ofereceu presença. Às vezes a gente só precisa de alguém que note.',
    'support',
    NULL,
    '2026-04-04 20:00:00+00'
);

-- P42: patricia.nunes → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'patricia.nunes'),
    '@ana.beatriz',
    'Eu tenho 47 anos e achava que era tarde demais pra começar a correr. Aí vi a @ana.beatriz — mãe solo, trabalhando integral, fazendo meia-maratona. Se ela encontrou tempo, qual é a minha desculpa? Me inscrevi na minha primeira 5k por causa dela.',
    'inspiration',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-04-04 07:45:00+00'
);

-- P43: ricardo.alves → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'),
    '@carlos.henrique',
    'O @carlos.henrique organiza a pelada toda quinta: reserva o campo, confirma quem vai, equilibra os times, traz a bola extra, lembra da água. Nunca pediu nada em troca. Nunca reclamou quando alguém fura em cima da hora. Carlos, você é o MVP fora de campo.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-04-05 12:30:00+00'
);

-- P44: ana.beatriz → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
    '@renata.campos',
    'A @renata.campos fez uma coisa que me marcou: no 1:1 dela comigo, em vez de falar de entrega, perguntou como eu tava de verdade. E quando eu disse ''tô bem'', ela ficou em silêncio e esperou. Aí eu falei de verdade. Ela sabia que a primeira resposta nunca é a real. Que gestora.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-05 18:45:00+00'
);

-- P45: marcos.vinicius → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius'),
    '@patricia.nunes',
    'A @patricia.nunes quase desistiu no km 4 da primeira corrida dela. Eu tava do lado e só disse: ''Falta 1km. Vai andando se precisar, mas não para.'' Ela não parou. E depois me mandou mensagem: ''Você não me deixou desistir.'' Na real, ela que não desistiu. Eu só lembrei ela disso.',
    'support',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-04-05 08:00:00+00'
);

-- P46: vanessa.martins → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '@ju.rocha',
    'A @ju.rocha é mãe, designer, corredora e ainda arruma tempo pra fazer mentoria com duas juniores do time. Quando eu perguntei como ela dá conta, ela disse: ''Eu não dou. Eu escolho o que vou deixar cair e aceito.'' Essa honestidade é mais inspiradora que qualquer produtividade tóxica.',
    'inspiration',
    NULL,
    '2026-04-06 13:00:00+00'
);

-- P47: jorge.ribeiro → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro'),
    '@maria.helena',
    'A @maria.helena escreveu um poema pro aniversário do meu neto. Ela nem conhece ele pessoalmente — conhece pelas histórias que eu conto. Mas o poema era tão certeiro que meu neto perguntou: ''Vô, a dona Helena me conhece?'' De certo modo, sim.',
    'admiration',
    NULL,
    '2026-04-06 10:15:00+00'
);

-- P48: thiago.costa → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'),
    '@diego.design',
    'Eu ia apagar uma mensagem no Slack porque achei que era boba demais. O @diego.design leu antes e respondeu: ''Essa ideia é boa, traz pro time.'' Aquela mensagem virou uma feature no produto. Diego, obrigado por ver valor no que eu quase joguei fora.',
    'gratitude',
    NULL,
    '2026-04-06 16:30:00+00'
);

-- P49: dona.lucia → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia'),
    '@vanessa.martins',
    'Essa moça, a @vanessa.martins — me ligou dia desses pra saber se eu tava conseguindo mexer no app novo do banco. Ficou no telefone comigo 40 minutos. Quarenta! E com paciência, meu filho. Não deu risada, não ficou com pressa. Me explicou tudo como se eu fosse a pessoa mais importante do mundo naquele momento.',
    'gratitude',
    NULL,
    '2026-04-07 07:50:00+00'
);

-- P50: rafael.mendes → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
    '@carlos.henrique',
    'O @carlos.henrique mandou mensagem no grupo de pais da escola perguntando se alguém tinha um colchão extra pro filho do amigo dele que tava numa situação difícil. Em 2 horas ele tinha juntado colchão, roupa, material escolar e 3 marmitas. Ele não pediu crédito. Eu só soube porque tava no grupo. Carlos, isso é caráter.',
    'support',
    NULL,
    '2026-04-07 20:10:00+00'
);

-- P51: camila.santos → support
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'),
    '@ana.beatriz',
    'No treino de sábado a @ana.beatriz tava claramente num dia ruim. Mais lenta, sem energia, quase chorando. Eu diminuí meu ritmo e corri do lado dela sem falar nada. No km 3 ela disse: ''Obrigada por ficar.'' Não precisou de mais nada.',
    'support',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-04-07 11:30:00+00'
);

-- P52: pedro.augusto → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'),
    '@edson.pereira',
    'O @edson.pereira me contou que jogava no campinho do bairro dele quando era moleque — descalço, bola de meia. Quinta passada ele fez um gol de cobertura que eu juro que vi câmera lenta. 62 anos, senhoras e senhores. A bola não esquece quem ama ela.',
    'memory',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-04-08 22:45:00+00'
);

-- P53: renata.campos → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'),
    '@marcos.vinicius',
    'Obrigada @marcos.vinicius por ter me esperado no km 38 da maratona quando minhas pernas travaram. Você tava com pace pra fazer seu melhor tempo e largou isso pra ficar comigo. Perdi a conta de quantas vezes eu disse ''vai, eu me viro'' e você respondeu ''eu sei que se vira, mas eu fico.'' Amigo é isso.',
    'gratitude',
    NULL,
    '2026-04-08 14:15:00+00'
);

-- P54: fernanda.lima → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima'),
    '@camila.santos',
    'A @camila.santos encontrou um bug em produção sexta às 17h. Todo mundo tava já saindo. Ela não só reportou — ela rastreou a causa raiz, documentou e sugeriu o fix. Na segunda a gente só precisou aprovar. QA com senso de dono é outra coisa.',
    'inspiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-08 09:50:00+00'
);

-- P55: seu.antonio → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'),
    '@edson.pereira',
    'O @edson.pereira me levou no médico segunda-feira. Eu podia ter ido de ônibus, mas ele fez questão. Ficou na sala de espera 3 horas lendo jornal. Na volta paramos pra tomar um café. Não disse nada demais. Mas tava lá.',
    'gratitude',
    NULL,
    '2026-04-09 15:00:00+00'
);

-- P56: carlos.henrique → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique'),
    '@lucas.ferreira',
    'O @lucas.ferreira fez o primeiro deploy dele em produção hoje. Sozinho. Sem ninguém segurando a mão. E funcionou de primeira. Eu lembro do primeiro deploy dele (que eu acompanhei de perto, de olho em tudo). Hoje ele não precisou de mim. Esse é o melhor elogio que um mentor pode receber: virar desnecessário.',
    'achievement',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-09 17:20:00+00'
);

-- P57: dona.lucia → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia'),
    '@jorge.ribeiro',
    'Eu e o @jorge.ribeiro fomos vizinhos por 25 anos antes dele se mudar pra Santos. Sabe o que eu mais sinto falta? Da buzina do carro dele de manhã, passando pra ir trabalhar. Era meu despertador. Ele nem sabia disso até eu contar agora.',
    'memory',
    NULL,
    '2026-04-10 08:30:00+00'
);

-- P58: diego.design → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'),
    '@camila.santos',
    'A @camila.santos fez uma coisa que ninguém mais faz: ela testou meu protótipo como usuária real, não como QA. Em vez de listar bugs, ela me disse: ''Aqui eu fiquei confusa, aqui eu sorri, aqui eu desisti.'' Esse tipo de feedback vale mais que 100 tickets no Jira.',
    'gratitude',
    NULL,
    '2026-04-10 14:40:00+00'
);

-- P59: vanessa.martins → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '@patricia.nunes',
    'Conheci a @patricia.nunes numa corrida e descobri que ela é professora de história. A gente começou falando de pace e terminou falando de como a educação no Brasil forma (ou deforma) cidadãos. Saí daquela conversa pensando diferente sobre 3 coisas. Pessoas que te fazem pensar são um presente.',
    'admiration',
    NULL,
    '2026-04-11 18:20:00+00'
);

-- P60: ricardo.alves → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves'),
    '@vanessa.martins',
    'A @vanessa.martins discordou de mim numa reunião. Na frente de todo mundo. Com argumentos. E tava certa. Eu poderia ter levado pro lado pessoal, mas em vez disso levei pro lado profissional: a gente precisa de gente que discorda com respeito e dados. Obrigado por não concordar comigo, Van.',
    'gratitude',
    NULL,
    '2026-04-11 11:00:00+00'
);

-- P61: maria.helena → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena'),
    '@jorge.ribeiro',
    'O @jorge.ribeiro consertou o portão da minha casa semana passada. Tem 76 anos e veio com a caixa de ferramentas na mão, como se fosse a coisa mais natural do mundo. Quando eu ofereci pagar, ele disse: ''Me paga com um café, dona Helena.'' O mundo precisa de mais Jorges.',
    'gratitude',
    NULL,
    '2026-04-12 09:30:00+00'
);

-- P62: thiago.costa → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'),
    '@renata.campos',
    'A @renata.campos fez uma coisa na retro que eu nunca tinha visto uma gestora fazer: ela admitiu que errou. Na frente do time todo. Disse: ''Eu deveria ter protegido vocês daquela demanda e não protegi.'' Ninguém ficou com menos respeito por ela. Pelo contrário.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-12 15:45:00+00'
);

-- P63: ana.beatriz → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
    '@camila.santos',
    'Preciso agradecer a @camila.santos por ter corrido do meu lado sábado quando eu tava num dia péssimo. Ela não tentou me animar, não deu conselho, não perguntou o que eu tinha. Só ficou ali, no meu ritmo, em silêncio solidário. Às vezes o melhor apoio é simplesmente não ir embora.',
    'gratitude',
    NULL,
    '2026-04-12 20:00:00+00'
);

-- P64: lucas.ferreira → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'),
    '@ricardo.alves',
    'O @ricardo.alves me disse uma frase outro dia que eu colei no monitor: ''Você não precisa saber tudo, só precisa saber perguntar.'' Parece clichê, mas vindo de alguém com 15 anos de experiência que ainda pergunta coisas no Stack Overflow, tem outro peso.',
    'inspiration',
    NULL,
    '2026-04-13 10:45:00+00'
);

-- P65: jorge.ribeiro → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro'),
    '@dona.lucia',
    'A @dona.lucia manda foto de bolo pra mim toda semana. Não é pra me fazer inveja — é pra eu sentir que ainda tô conectado com o bairro. Cada foto é um pedacinho de casa. Lúcia, obrigado por não me deixar ser um ex-vizinho.',
    'gratitude',
    NULL,
    '2026-04-13 07:20:00+00'
);

-- P66: rafael.mendes → gratitude
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
    '@marcos.vinicius',
    'No dia que eu completei os 100 dias de treino, o @marcos.vinicius me deu um abraço e disse: ''Eu sabia que você ia conseguir. Você que não sabia.'' Cara, isso ficou ecoando na minha cabeça a semana inteira. Às vezes a gente precisa de alguém que acredite em nós antes da gente acreditar.',
    'gratitude',
    (SELECT id FROM public.communities WHERE slug = 'corre-sp'),
    '2026-04-13 19:30:00+00'
);

-- P67: edson.pereira → inspiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira'),
    '@thiago.costa',
    'O @thiago.costa me chamou de ''mestre'' na pelada outro dia. Eu ri. Mas depois pensei: esse moleque trata todo mundo mais velho com respeito sem ser forçado. Não é educação de fachada. É caráter. Os pais desse garoto acertaram.',
    'inspiration',
    (SELECT id FROM public.communities WHERE slug = 'pelada-quinta'),
    '2026-04-14 21:00:00+00'
);

-- P68: camila.santos → admiration
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'),
    '@fernanda.lima',
    'A @fernanda.lima tem um dom que eu invejo: ela pega dados frios e transforma em histórias que convencem. Aquela dashboard que ela refez? O PM usou na reunião de board e o C-level pediu mais. Fer, seus dados contam histórias melhores que muita série.',
    'admiration',
    (SELECT id FROM public.communities WHERE slug = 'time-tech'),
    '2026-04-14 11:15:00+00'
);

-- P69: pedro.augusto → memory
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'),
    '@seu.antonio',
    'Uma vez o @seu.antonio me ensinou a afiar faca com pedra. Eu, um DevOps que não sabe pregar prego, aprendendo a afiar faca com um carpinteiro aposentado num churrasco. Aquela tarde vale mais que qualquer workshop de team building que eu já fui.',
    'memory',
    NULL,
    '2026-04-15 14:00:00+00'
);

-- P70: renata.campos → achievement
INSERT INTO public.posts (user_id, celebrated_person_name, content, type, community_id, created_at)
VALUES (
    (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos'),
    '@fernanda.lima',
    'Quero reconhecer algo que a @fernanda.lima fez discretamente: ela montou um doc com todos os processos do time que ninguém tinha documentado. Ninguém pediu. Ela viu que onboarding de gente nova era caótico e resolveu. Quando a Patrícia entrou na squad, teve tudo escrito. Isso é senso de time.',
    'achievement',
    NULL,
    '2026-04-15 16:50:00+00'
);

DO $$ BEGIN RAISE NOTICE 'FASE 9 concluída: posts globais/comunidade inseridos.'; END $$;

-- ============================================================
-- FASE 10: Inserir 4 correntes e 12 posts de correntes
-- chain_posts: (chain_id, post_id, author_id) — sem position (não existe no banco)
-- ============================================================

-- Corrente: CH01 — Quem te fez acreditar em você?
INSERT INTO public.chains (name, description, highlight_type, is_memorias_vivas, creator_id, created_at)
VALUES (
    'Quem te fez acreditar em você?',
    'Conte sobre alguém que acreditou em você quando você mesmo não acreditava',
    'inspiration',
    false,
    (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
    '2026-03-26 20:30:00+00'
);

    -- CP01: vanessa.martins
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins'),
        '@marcos.vinicius',
        'O @marcos.vinicius me convidou pra correr minha primeira meia quando eu achava que 5k era meu limite. Ele não disse ''você consegue''. Disse: ''Se você não conseguir, a gente volta andando.'' Tirou a pressão e me deu coragem. Corri os 21km.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        '2026-03-26 20:30:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?') AND created_at = '2026-03-26 20:30:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
    );

    -- CP02: thiago.costa
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa'),
        '@ricardo.alves',
        'Eu quase desisti do estágio na segunda semana. Achava que não era bom o suficiente. O @ricardo.alves me chamou pra um café e disse: ''Ninguém nasce sabendo. Você tem curiosidade, e isso não se ensina.'' Tô aqui por causa dessa conversa.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        '2026-03-28 13:00:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?') AND created_at = '2026-03-28 13:00:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa')
    );

    -- CP03: dona.lucia
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia'),
        '@maria.helena',
        'Quando meu marido faleceu, eu achei que minha vida tinha acabado. A @maria.helena me ligava todo dia. Todo dia. Às vezes pra conversar, às vezes só pra dizer ''tô aqui''. Ela me fez acreditar que eu ainda tinha história pra viver. E eu tinha.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        '2026-03-31 09:30:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?') AND created_at = '2026-03-31 09:30:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia')
    );

-- Corrente: CH02 — O conselho que eu carrego até hoje
INSERT INTO public.chains (name, description, highlight_type, is_memorias_vivas, creator_id, created_at)
VALUES (
    'O conselho que eu carrego até hoje',
    'Qual conselho alguém te deu que ainda guia suas decisões?',
    'memory',
    true,
    (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'),
    '2026-03-24 10:00:00+00'
);

    -- CP04: seu.antonio
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio'),
        '@edson.pereira',
        'O @edson.pereira me disse em 1995: ''Antônio, trabalha com as mãos mas pensa com a cabeça.'' Eu era carpinteiro bruto, fazia tudo no impulso. Depois daquele dia, comecei a planejar cada corte. Meus móveis ficaram melhores. Minha vida também.',
        'memory',
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        '2026-03-24 10:00:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje') AND created_at = '2026-03-24 10:00:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio')
    );

    -- CP05: jorge.ribeiro
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro'),
        '@maria.helena',
        'A @maria.helena me disse uma vez: ''Jorge, aposentar o corpo não é aposentar a cabeça.'' Eu tava virando sofá. Depois disso voltei a ler, comecei a caminhar no parque, entrei na roda de leitura. Ela salvou minha aposentadoria de ser uma espera pelo fim.',
        'memory',
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        '2026-03-27 08:15:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje') AND created_at = '2026-03-27 08:15:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro')
    );

    -- CP06: maria.helena
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena'),
        '@dona.lucia',
        'A @dona.lucia me disse algo simples que eu nunca esqueci: ''Helena, solidão é quando a gente para de ir atrás dos outros.'' Eu tava me isolando depois da aposentadoria. No dia seguinte liguei pra 3 amigas. Todas atenderam. A Lúcia tava certa.',
        'memory',
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        '2026-03-30 11:00:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje') AND created_at = '2026-03-30 11:00:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena')
    );

-- Corrente: CH03 — Um gesto pequeno que mudou seu dia
INSERT INTO public.chains (name, description, highlight_type, is_memorias_vivas, creator_id, created_at)
VALUES (
    'Um gesto pequeno que mudou seu dia',
    'Às vezes não é o grande favor, é o detalhe. Conte sobre um gesto simples que fez diferença no seu dia.',
    'gratitude',
    false,
    (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
    '2026-03-21 12:30:00+00'
);

    -- CP07: rafael.mendes
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes'),
        '@fernanda.lima',
        'A @fernanda.lima deixou um post-it na minha mesa (sim, a gente ainda vai pro escritório às vezes) escrito: ''Aquele componente ficou lindo.'' Quatro palavras. Eu tava num dia em que achava que nada que eu fazia prestava. Aquele post-it ficou colado no meu monitor por 2 semanas.',
        'gratitude',
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        '2026-03-21 12:30:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia') AND created_at = '2026-03-21 12:30:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes')
    );

    -- CP08: camila.santos
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos'),
        '@ju.rocha',
        'A @ju.rocha me mandou um áudio de 12 segundos depois de uma reunião tensa: ''Cami, você mandou bem. Para de duvidar.'' Doze segundos. Às vezes é só isso que a gente precisa ouvir.',
        'gratitude',
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        '2026-03-25 18:00:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia') AND created_at = '2026-03-25 18:00:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos')
    );

    -- CP09: pedro.augusto
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto'),
        '@carlos.henrique',
        'O @carlos.henrique me mandou o link de uma vaga que tinha a minha cara. Nem era da empresa dele, nem ia beneficiar ele em nada. Só viu, lembrou de mim e mandou. Não usei a vaga, mas guardei o gesto.',
        'gratitude',
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        '2026-04-01 21:00:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia') AND created_at = '2026-04-01 21:00:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto')
    );

-- Corrente: CH04 — A pessoa que te ensinou sem saber
INSERT INTO public.chains (name, description, highlight_type, is_memorias_vivas, creator_id, created_at)
VALUES (
    'A pessoa que te ensinou sem saber',
    'Alguém que te ensinou algo importante só pelo exemplo, sem nunca ter dado uma aula formal.',
    'inspiration',
    false,
    (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
    '2026-04-03 13:45:00+00'
);

    -- CP10: ana.beatriz
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz'),
        '@renata.campos',
        'A @renata.campos nunca me deu uma aula de liderança. Mas eu aprendo toda vez que vejo ela em reunião: como ela escuta antes de falar, como ela dá crédito, como ela assume erro. Eu copio ela descaradamente. Acho que ela nem sabe.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        '2026-04-03 13:45:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber') AND created_at = '2026-04-03 13:45:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz')
    );

    -- CP11: lucas.ferreira
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira'),
        '@seu.antonio',
        'O @seu.antonio me ensinou paciência sem dizer uma palavra sobre paciência. Foi num churrasco: eu queria virar a carne a cada 30 segundos. Ele pôs a mão no meu braço e disse: ''Espera. A carne avisa quando tá pronta.'' Eu uso isso no código agora. Sério.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        '2026-04-07 15:30:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber') AND created_at = '2026-04-07 15:30:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira')
    );

    -- CP12: diego.design
    INSERT INTO public.posts (user_id, celebrated_person_name, content, type, chain_id, created_at)
    VALUES (
        (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design'),
        '@patricia.nunes',
        'A @patricia.nunes é professora e eu sou designer, mas ela me ensinou mais sobre comunicação visual do que qualquer curso. Um dia ela disse: ''Se o aluno não entendeu, o problema é do professor, não do aluno.'' Troquei ''aluno'' por ''usuário'' e mudou minha forma de projetar.',
        'inspiration',
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        '2026-04-11 10:15:00+00'
    );
    INSERT INTO public.chain_posts (chain_id, post_id, author_id)
    VALUES (
        (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber'),
        (SELECT id FROM public.posts WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber') AND created_at = '2026-04-11 10:15:00+00' LIMIT 1),
        (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design')
    );

-- Atualizar first_post_id nas correntes
UPDATE public.chains SET first_post_id = (
    SELECT id FROM public.posts
    WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?')
    AND created_at = '2026-03-26 20:30:00+00' LIMIT 1
) WHERE name = 'Quem te fez acreditar em você?';
UPDATE public.chains SET first_post_id = (
    SELECT id FROM public.posts
    WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje')
    AND created_at = '2026-03-24 10:00:00+00' LIMIT 1
) WHERE name = 'O conselho que eu carrego até hoje';
UPDATE public.chains SET first_post_id = (
    SELECT id FROM public.posts
    WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia')
    AND created_at = '2026-03-21 12:30:00+00' LIMIT 1
) WHERE name = 'Um gesto pequeno que mudou seu dia';
UPDATE public.chains SET first_post_id = (
    SELECT id FROM public.posts
    WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber')
    AND created_at = '2026-04-03 13:45:00+00' LIMIT 1
) WHERE name = 'A pessoa que te ensinou sem saber';

DO $$ BEGIN RAISE NOTICE 'FASE 10 concluída: correntes e posts de correntes inseridos.'; END $$;

-- ============================================================
-- FASE 11: Criar _seed_post_map (str_id → post_id + created_at)
-- Esta é a peça central da arquitetura v8
-- Todas as reactions/comments/feedbacks usam JOIN nesta tabela
-- ============================================================
CREATE TEMP TABLE _seed_post_map (
    str_id   text PRIMARY KEY,
    post_id  uuid NOT NULL,
    author   text NOT NULL,
    created_at timestamptz NOT NULL
);

-- Posts globais (P01..P70)
INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P01', id, 'rafael.mendes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes')
AND created_at = '2026-03-16 18:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P02', id, 'ju.rocha', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha')
AND created_at = '2026-03-17 10:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P03', id, 'diego.design', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design')
AND created_at = '2026-03-17 21:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P04', id, 'ricardo.alves', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves')
AND created_at = '2026-03-18 16:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P05', id, 'vanessa.martins', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
AND created_at = '2026-03-18 19:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P06', id, 'dona.lucia', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia')
AND created_at = '2026-03-19 08:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P07', id, 'seu.antonio', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio')
AND created_at = '2026-03-19 14:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P08', id, 'carlos.henrique', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique')
AND created_at = '2026-03-19 22:10:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P09', id, 'marcos.vinicius', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius')
AND created_at = '2026-03-20 11:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P10', id, 'thiago.costa', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa')
AND created_at = '2026-03-20 17:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P11', id, 'ana.beatriz', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz')
AND created_at = '2026-03-21 20:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P12', id, 'fernanda.lima', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima')
AND created_at = '2026-03-21 09:40:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P13', id, 'patricia.nunes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'patricia.nunes')
AND created_at = '2026-03-22 15:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P14', id, 'camila.santos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos')
AND created_at = '2026-03-22 19:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P15', id, 'pedro.augusto', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto')
AND created_at = '2026-03-23 23:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P16', id, 'lucas.ferreira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira')
AND created_at = '2026-03-23 14:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P17', id, 'renata.campos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos')
AND created_at = '2026-03-24 11:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P18', id, 'jorge.ribeiro', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro')
AND created_at = '2026-03-24 07:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P19', id, 'maria.helena', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena')
AND created_at = '2026-03-25 10:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P20', id, 'vanessa.martins', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
AND created_at = '2026-03-25 16:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P21', id, 'edson.pereira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira')
AND created_at = '2026-03-25 08:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P22', id, 'diego.design', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design')
AND created_at = '2026-03-26 13:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P23', id, 'ricardo.alves', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves')
AND created_at = '2026-03-26 18:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P24', id, 'dona.lucia', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia')
AND created_at = '2026-03-27 09:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P25', id, 'ana.beatriz', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz')
AND created_at = '2026-03-27 17:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P26', id, 'carlos.henrique', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique')
AND created_at = '2026-03-28 22:40:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P27', id, 'ju.rocha', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha')
AND created_at = '2026-03-28 08:50:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P28', id, 'marcos.vinicius', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius')
AND created_at = '2026-03-29 07:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P29', id, 'thiago.costa', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa')
AND created_at = '2026-03-29 15:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P30', id, 'seu.antonio', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio')
AND created_at = '2026-03-30 16:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P31', id, 'vanessa.martins', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
AND created_at = '2026-03-30 19:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P32', id, 'fernanda.lima', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima')
AND created_at = '2026-03-31 10:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P33', id, 'camila.santos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos')
AND created_at = '2026-03-31 12:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P34', id, 'pedro.augusto', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto')
AND created_at = '2026-04-01 23:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P35', id, 'maria.helena', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena')
AND created_at = '2026-04-01 09:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P36', id, 'rafael.mendes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes')
AND created_at = '2026-04-02 11:40:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P37', id, 'renata.campos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos')
AND created_at = '2026-04-02 14:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P38', id, 'lucas.ferreira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira')
AND created_at = '2026-04-03 16:50:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P39', id, 'edson.pereira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira')
AND created_at = '2026-04-03 21:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P40', id, 'ju.rocha', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ju.rocha')
AND created_at = '2026-04-04 09:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P41', id, 'diego.design', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design')
AND created_at = '2026-04-04 20:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P42', id, 'patricia.nunes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'patricia.nunes')
AND created_at = '2026-04-04 07:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P43', id, 'ricardo.alves', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves')
AND created_at = '2026-04-05 12:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P44', id, 'ana.beatriz', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz')
AND created_at = '2026-04-05 18:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P45', id, 'marcos.vinicius', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'marcos.vinicius')
AND created_at = '2026-04-05 08:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P46', id, 'vanessa.martins', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
AND created_at = '2026-04-06 13:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P47', id, 'jorge.ribeiro', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro')
AND created_at = '2026-04-06 10:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P48', id, 'thiago.costa', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa')
AND created_at = '2026-04-06 16:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P49', id, 'dona.lucia', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia')
AND created_at = '2026-04-07 07:50:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P50', id, 'rafael.mendes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes')
AND created_at = '2026-04-07 20:10:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P51', id, 'camila.santos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos')
AND created_at = '2026-04-07 11:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P52', id, 'pedro.augusto', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto')
AND created_at = '2026-04-08 22:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P53', id, 'renata.campos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos')
AND created_at = '2026-04-08 14:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P54', id, 'fernanda.lima', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'fernanda.lima')
AND created_at = '2026-04-08 09:50:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P55', id, 'seu.antonio', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'seu.antonio')
AND created_at = '2026-04-09 15:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P56', id, 'carlos.henrique', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'carlos.henrique')
AND created_at = '2026-04-09 17:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P57', id, 'dona.lucia', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'dona.lucia')
AND created_at = '2026-04-10 08:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P58', id, 'diego.design', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'diego.design')
AND created_at = '2026-04-10 14:40:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P59', id, 'vanessa.martins', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'vanessa.martins')
AND created_at = '2026-04-11 18:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P60', id, 'ricardo.alves', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ricardo.alves')
AND created_at = '2026-04-11 11:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P61', id, 'maria.helena', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'maria.helena')
AND created_at = '2026-04-12 09:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P62', id, 'thiago.costa', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'thiago.costa')
AND created_at = '2026-04-12 15:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P63', id, 'ana.beatriz', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'ana.beatriz')
AND created_at = '2026-04-12 20:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P64', id, 'lucas.ferreira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'lucas.ferreira')
AND created_at = '2026-04-13 10:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P65', id, 'jorge.ribeiro', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'jorge.ribeiro')
AND created_at = '2026-04-13 07:20:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P66', id, 'rafael.mendes', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'rafael.mendes')
AND created_at = '2026-04-13 19:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P67', id, 'edson.pereira', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'edson.pereira')
AND created_at = '2026-04-14 21:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P68', id, 'camila.santos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'camila.santos')
AND created_at = '2026-04-14 11:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P69', id, 'pedro.augusto', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'pedro.augusto')
AND created_at = '2026-04-15 14:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'P70', id, 'renata.campos', created_at
FROM public.posts WHERE user_id = (SELECT user_id FROM _seed_profile_map WHERE username = 'renata.campos')
AND created_at = '2026-04-15 16:50:00+00' LIMIT 1;

-- Posts de correntes (CP01..CP12)
INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP01', id, 'vanessa.martins', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?')
AND created_at = '2026-03-26 20:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP02', id, 'thiago.costa', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?')
AND created_at = '2026-03-28 13:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP03', id, 'dona.lucia', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Quem te fez acreditar em você?')
AND created_at = '2026-03-31 09:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP04', id, 'seu.antonio', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje')
AND created_at = '2026-03-24 10:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP05', id, 'jorge.ribeiro', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje')
AND created_at = '2026-03-27 08:15:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP06', id, 'maria.helena', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'O conselho que eu carrego até hoje')
AND created_at = '2026-03-30 11:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP07', id, 'rafael.mendes', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia')
AND created_at = '2026-03-21 12:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP08', id, 'camila.santos', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia')
AND created_at = '2026-03-25 18:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP09', id, 'pedro.augusto', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Um gesto pequeno que mudou seu dia')
AND created_at = '2026-04-01 21:00:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP10', id, 'ana.beatriz', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber')
AND created_at = '2026-04-03 13:45:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP11', id, 'lucas.ferreira', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber')
AND created_at = '2026-04-07 15:30:00+00' LIMIT 1;

INSERT INTO _seed_post_map (str_id, post_id, author, created_at)
SELECT 'CP12', id, 'diego.design', created_at
FROM public.posts
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'A pessoa que te ensinou sem saber')
AND created_at = '2026-04-11 10:15:00+00' LIMIT 1;

DO $$
DECLARE cnt int;
BEGIN
    SELECT COUNT(*) INTO cnt FROM _seed_post_map;
    IF cnt != 82 THEN
        RAISE EXCEPTION 'ERRO: _seed_post_map tem % entradas, esperado 82. Verifique os INSERTs de posts.', cnt;
    END IF;
    RAISE NOTICE 'FASE 11 concluída: mapa de posts criado com % entradas.', cnt;
END $$;

-- ============================================================
-- FASE 12: Inserir 504 reações via JOIN em _seed_post_map
-- ============================================================
INSERT INTO public.reactions (user_id, post_id, type, created_at)
SELECT
    (SELECT user_id FROM _seed_profile_map WHERE username = r.username),
    m.post_id,
    r.reaction_type,
    m.created_at + (r.delay_hours || ' hours')::interval
FROM (VALUES
    ('CP01', 'ju.rocha', 'loved', 3.7),
    ('CP01', 'rafael.mendes', 'loved', 9.2),
    ('CP01', 'camila.santos', 'hug', 10.8),
    ('CP01', 'lucas.ferreira', 'loved', 15.7),
    ('CP01', 'ana.beatriz', 'loved', 25.6),
    ('CP02', 'diego.design', 'claps', 2.6),
    ('CP02', 'marcos.vinicius', 'loved', 6.7),
    ('CP02', 'fernanda.lima', 'loved', 13.2),
    ('CP02', 'ju.rocha', 'loved', 23.9),
    ('CP02', 'maria.helena', 'hug', 39.3),
    ('CP02', 'lucas.ferreira', 'loved', 45.7),
    ('CP02', 'rafael.mendes', 'loved', 47.6),
    ('CP03', 'maria.helena', 'loved', 9.2),
    ('CP03', 'vanessa.martins', 'hug', 14.9),
    ('CP03', 'lucas.ferreira', 'hug', 16.5),
    ('CP03', 'jorge.ribeiro', 'hug', 18.6),
    ('CP03', 'pedro.augusto', 'hug', 23.2),
    ('CP03', 'seu.antonio', 'hug', 23.4),
    ('CP03', 'patricia.nunes', 'loved', 24.0),
    ('CP03', 'edson.pereira', 'loved', 26.7),
    ('CP03', 'diego.design', 'loved', 61.5),
    ('CP04', 'maria.helena', 'loved', 40.6),
    ('CP04', 'carlos.henrique', 'claps', 64.6),
    ('CP05', 'dona.lucia', 'hug', 1.2),
    ('CP05', 'fernanda.lima', 'hug', 5.5),
    ('CP05', 'patricia.nunes', 'hug', 14.1),
    ('CP05', 'ricardo.alves', 'claps', 15.6),
    ('CP05', 'maria.helena', 'loved', 21.7),
    ('CP05', 'pedro.augusto', 'claps', 22.8),
    ('CP05', 'vanessa.martins', 'loved', 26.0),
    ('CP06', 'patricia.nunes', 'hug', 3.9),
    ('CP06', 'thiago.costa', 'hug', 10.3),
    ('CP06', 'dona.lucia', 'loved', 18.4),
    ('CP06', 'edson.pereira', 'claps', 23.7),
    ('CP07', 'dona.lucia', 'hug', 1.0),
    ('CP07', 'ricardo.alves', 'loved', 1.7),
    ('CP07', 'diego.design', 'loved', 7.8),
    ('CP07', 'carlos.henrique', 'hug', 12.6),
    ('CP07', 'fernanda.lima', 'loved', 15.0),
    ('CP07', 'ju.rocha', 'hug', 20.4),
    ('CP07', 'vanessa.martins', 'claps', 23.2),
    ('CP07', 'patricia.nunes', 'loved', 31.7),
    ('CP07', 'maria.helena', 'hug', 55.4),
    ('CP08', 'renata.campos', 'hug', 13.5),
    ('CP08', 'carlos.henrique', 'loved', 18.5),
    ('CP08', 'seu.antonio', 'hug', 22.6),
    ('CP08', 'ana.beatriz', 'loved', 42.9),
    ('CP08', 'rafael.mendes', 'loved', 56.7),
    ('CP09', 'maria.helena', 'loved', 4.3),
    ('CP09', 'ju.rocha', 'loved', 11.6),
    ('CP09', 'rafael.mendes', 'hug', 12.6),
    ('CP10', 'lucas.ferreira', 'hug', 1.1),
    ('CP10', 'edson.pereira', 'loved', 7.9),
    ('CP10', 'ju.rocha', 'loved', 10.1),
    ('CP10', 'fernanda.lima', 'hug', 15.3),
    ('CP10', 'vanessa.martins', 'hug', 17.5),
    ('CP10', 'maria.helena', 'claps', 19.2),
    ('CP10', 'carlos.henrique', 'hug', 22.8),
    ('CP10', 'rafael.mendes', 'hug', 31.1),
    ('CP10', 'camila.santos', 'hug', 61.6),
    ('CP11', 'camila.santos', 'claps', 7.5),
    ('CP11', 'carlos.henrique', 'hug', 11.9),
    ('CP11', 'dona.lucia', 'hug', 12.0),
    ('CP11', 'ana.beatriz', 'hug', 13.3),
    ('CP11', 'jorge.ribeiro', 'hug', 14.0),
    ('CP11', 'seu.antonio', 'hug', 22.5),
    ('CP11', 'diego.design', 'hug', 42.9),
    ('CP11', 'fernanda.lima', 'hug', 56.7),
    ('CP11', 'marcos.vinicius', 'claps', 61.0),
    ('CP12', 'pedro.augusto', 'hug', 3.7),
    ('CP12', 'lucas.ferreira', 'loved', 6.9),
    ('CP12', 'fernanda.lima', 'loved', 8.3),
    ('CP12', 'camila.santos', 'hug', 20.0),
    ('CP12', 'carlos.henrique', 'claps', 31.6),
    ('CP12', 'ana.beatriz', 'loved', 34.8),
    ('CP12', 'ju.rocha', 'loved', 35.5),
    ('P01', 'vanessa.martins', 'loved', 1),
    ('P01', 'diego.design', 'claps', 3),
    ('P01', 'ricardo.alves', 'loved', 5),
    ('P01', 'pedro.augusto', 'loved', 7.0),
    ('P01', 'fernanda.lima', 'hug', 14.4),
    ('P01', 'lucas.ferreira', 'loved', 14.6),
    ('P01', 'diego.design', 'hug', 57.7),
    ('P02', 'vanessa.martins', 'claps', 2),
    ('P02', 'carlos.henrique', 'loved', 4),
    ('P02', 'ricardo.alves', 'claps', 8.6),
    ('P02', 'thiago.costa', 'claps', 28.9),
    ('P03', 'vanessa.martins', 'hug', 1),
    ('P03', 'camila.santos', 'claps', 5.0),
    ('P03', 'seu.antonio', 'loved', 8),
    ('P03', 'patricia.nunes', 'hug', 12),
    ('P03', 'edson.pereira', 'loved', 18.7),
    ('P04', 'rafael.mendes', 'claps', 1),
    ('P04', 'vanessa.martins', 'loved', 2),
    ('P04', 'lucas.ferreira', 'claps', 3),
    ('P04', 'carlos.henrique', 'claps', 4),
    ('P04', 'thiago.costa', 'loved', 9.2),
    ('P04', 'fernanda.lima', 'claps', 22.5),
    ('P05', 'rafael.mendes', 'hug', 1),
    ('P05', 'ju.rocha', 'hug', 2),
    ('P05', 'marcos.vinicius', 'hug', 2.1),
    ('P05', 'renata.campos', 'loved', 6),
    ('P05', 'ana.beatriz', 'hug', 8.1),
    ('P05', 'carlos.henrique', 'claps', 17.4),
    ('P05', 'fernanda.lima', 'hug', 19.8),
    ('P05', 'pedro.augusto', 'loved', 21.3),
    ('P06', 'seu.antonio', 'loved', 0.6),
    ('P06', 'vanessa.martins', 'hug', 4),
    ('P06', 'jorge.ribeiro', 'loved', 10),
    ('P06', 'carlos.henrique', 'loved', 11.5),
    ('P06', 'edson.pereira', 'claps', 12.1),
    ('P06', 'vanessa.martins', 'loved', 14.5),
    ('P06', 'diego.design', 'hug', 21.3),
    ('P06', 'renata.campos', 'loved', 22.6),
    ('P06', 'maria.helena', 'hug', 24),
    ('P06', 'patricia.nunes', 'hug', 31.3),
    ('P06', 'jorge.ribeiro', 'hug', 40.3),
    ('P07', 'dona.lucia', 'loved', 2),
    ('P07', 'vanessa.martins', 'hug', 8),
    ('P07', 'jorge.ribeiro', 'hug', 9.3),
    ('P07', 'fernanda.lima', 'claps', 12.0),
    ('P07', 'vanessa.martins', 'loved', 23.7),
    ('P07', 'patricia.nunes', 'loved', 68.3),
    ('P08', 'ricardo.alves', 'claps', 0.5),
    ('P08', 'diego.design', 'claps', 1),
    ('P08', 'thiago.costa', 'claps', 2),
    ('P08', 'vanessa.martins', 'hug', 5.7),
    ('P08', 'diego.design', 'loved', 8.4),
    ('P08', 'pedro.augusto', 'hug', 12.7),
    ('P08', 'renata.campos', 'loved', 13.4),
    ('P08', 'rafael.mendes', 'loved', 17.7),
    ('P08', 'seu.antonio', 'loved', 23.9),
    ('P08', 'ricardo.alves', 'loved', 44.3),
    ('P09', 'rafael.mendes', 'claps', 1),
    ('P09', 'ju.rocha', 'claps', 2),
    ('P09', 'vanessa.martins', 'loved', 3),
    ('P09', 'ana.beatriz', 'claps', 5),
    ('P09', 'ana.beatriz', 'hug', 27.4),
    ('P10', 'camila.santos', 'claps', 0.8),
    ('P10', 'vanessa.martins', 'loved', 1),
    ('P10', 'rafael.mendes', 'claps', 3),
    ('P10', 'ana.beatriz', 'claps', 4.8),
    ('P10', 'marcos.vinicius', 'claps', 5.0),
    ('P10', 'edson.pereira', 'claps', 10.2),
    ('P10', 'renata.campos', 'loved', 12),
    ('P10', 'ricardo.alves', 'hug', 15.9),
    ('P10', 'renata.campos', 'claps', 17.6),
    ('P10', 'maria.helena', 'claps', 27.6),
    ('P10', 'ju.rocha', 'claps', 28.7),
    ('P11', 'ricardo.alves', 'hug', 1),
    ('P11', 'ju.rocha', 'hug', 2),
    ('P11', 'marcos.vinicius', 'hug', 4),
    ('P11', 'jorge.ribeiro', 'loved', 9.7),
    ('P11', 'rafael.mendes', 'hug', 11.9),
    ('P11', 'fernanda.lima', 'claps', 37.7),
    ('P12', 'vanessa.martins', 'claps', 2),
    ('P12', 'camila.santos', 'loved', 5),
    ('P13', 'ana.beatriz', 'hug', 4.9),
    ('P13', 'dona.lucia', 'loved', 24),
    ('P13', 'dona.lucia', 'claps', 31.6),
    ('P13', 'jorge.ribeiro', 'hug', 36),
    ('P14', 'rafael.mendes', 'loved', 2),
    ('P14', 'vanessa.martins', 'claps', 4),
    ('P14', 'ana.beatriz', 'loved', 8),
    ('P14', 'ju.rocha', 'loved', 16.3),
    ('P14', 'renata.campos', 'claps', 17.3),
    ('P14', 'patricia.nunes', 'loved', 22.4),
    ('P14', 'marcos.vinicius', 'loved', 27.5),
    ('P14', 'lucas.ferreira', 'claps', 41.7),
    ('P14', 'vanessa.martins', 'loved', 57.8),
    ('P14', 'seu.antonio', 'hug', 71.8),
    ('P15', 'rafael.mendes', 'loved', 2.3),
    ('P15', 'thiago.costa', 'hug', 4.0),
    ('P15', 'lucas.ferreira', 'loved', 6.7),
    ('P15', 'maria.helena', 'loved', 7.0),
    ('P15', 'jorge.ribeiro', 'loved', 17.4),
    ('P15', 'seu.antonio', 'claps', 50.2),
    ('P15', 'carlos.henrique', 'loved', 50.5),
    ('P15', 'ricardo.alves', 'loved', 54.6),
    ('P15', 'diego.design', 'hug', 64.6),
    ('P16', 'ju.rocha', 'loved', 2.9),
    ('P16', 'carlos.henrique', 'hug', 22.4),
    ('P16', 'patricia.nunes', 'hug', 43.5),
    ('P17', 'vanessa.martins', 'claps', 1),
    ('P17', 'dona.lucia', 'claps', 1.4),
    ('P17', 'rafael.mendes', 'loved', 3),
    ('P17', 'pedro.augusto', 'claps', 4.2),
    ('P17', 'thiago.costa', 'claps', 5),
    ('P17', 'ana.beatriz', 'loved', 8),
    ('P17', 'carlos.henrique', 'claps', 16.2),
    ('P18', 'vanessa.martins', 'loved', 2.1),
    ('P18', 'dona.lucia', 'hug', 6),
    ('P18', 'seu.antonio', 'loved', 12),
    ('P18', 'patricia.nunes', 'hug', 12.5),
    ('P18', 'thiago.costa', 'claps', 14.1),
    ('P18', 'dona.lucia', 'claps', 14.5),
    ('P18', 'edson.pereira', 'claps', 21.6),
    ('P18', 'ricardo.alves', 'hug', 39.9),
    ('P18', 'maria.helena', 'loved', 44.9),
    ('P18', 'maria.helena', 'hug', 48),
    ('P20', 'lucas.ferreira', 'loved', 3.4),
    ('P20', 'pedro.augusto', 'claps', 9.4),
    ('P20', 'ju.rocha', 'claps', 13.5),
    ('P20', 'ana.beatriz', 'loved', 13.9),
    ('P20', 'marcos.vinicius', 'hug', 16.2),
    ('P21', 'rafael.mendes', 'claps', 2.5),
    ('P21', 'jorge.ribeiro', 'loved', 4),
    ('P21', 'dona.lucia', 'hug', 8),
    ('P21', 'carlos.henrique', 'claps', 8.4),
    ('P21', 'patricia.nunes', 'claps', 10.9),
    ('P21', 'maria.helena', 'loved', 21.7),
    ('P21', 'vanessa.martins', 'claps', 56.3),
    ('P22', 'ju.rocha', 'loved', 5.1),
    ('P22', 'vanessa.martins', 'hug', 6.2),
    ('P22', 'camila.santos', 'hug', 10.5),
    ('P22', 'fernanda.lima', 'hug', 18.1),
    ('P22', 'seu.antonio', 'loved', 20.4),
    ('P22', 'dona.lucia', 'loved', 48.9),
    ('P23', 'marcos.vinicius', 'claps', 3.8),
    ('P23', 'seu.antonio', 'loved', 6.6),
    ('P23', 'renata.campos', 'claps', 6.9),
    ('P23', 'patricia.nunes', 'loved', 7.0),
    ('P23', 'ana.beatriz', 'claps', 10.4),
    ('P23', 'camila.santos', 'claps', 13.3),
    ('P23', 'vanessa.martins', 'hug', 16.8),
    ('P23', 'maria.helena', 'claps', 17.1),
    ('P23', 'rafael.mendes', 'claps', 18.2),
    ('P23', 'pedro.augusto', 'claps', 18.5),
    ('P23', 'ju.rocha', 'loved', 42.3),
    ('P24', 'renata.campos', 'loved', 1.7),
    ('P24', 'seu.antonio', 'loved', 2),
    ('P24', 'fernanda.lima', 'hug', 2.4),
    ('P24', 'lucas.ferreira', 'loved', 3.5),
    ('P24', 'vanessa.martins', 'hug', 6),
    ('P24', 'patricia.nunes', 'loved', 8.2),
    ('P24', 'jorge.ribeiro', 'hug', 9.8),
    ('P24', 'edson.pereira', 'loved', 10.0),
    ('P24', 'maria.helena', 'hug', 15.6),
    ('P24', 'seu.antonio', 'hug', 18.2),
    ('P25', 'marcos.vinicius', 'claps', 6.1),
    ('P25', 'camila.santos', 'loved', 6.3),
    ('P25', 'renata.campos', 'claps', 9.2),
    ('P25', 'ju.rocha', 'claps', 22.8),
    ('P25', 'diego.design', 'claps', 58.5),
    ('P26', 'lucas.ferreira', 'loved', 2.9),
    ('P26', 'diego.design', 'claps', 27.6),
    ('P26', 'edson.pereira', 'loved', 52.8),
    ('P28', 'ju.rocha', 'claps', 2),
    ('P28', 'vanessa.martins', 'claps', 4),
    ('P28', 'camila.santos', 'claps', 6),
    ('P28', 'ana.beatriz', 'loved', 8),
    ('P28', 'renata.campos', 'claps', 9.4),
    ('P28', 'camila.santos', 'loved', 10.7),
    ('P28', 'ju.rocha', 'loved', 17.7),
    ('P28', 'lucas.ferreira', 'hug', 19.5),
    ('P28', 'rafael.mendes', 'loved', 20.5),
    ('P28', 'patricia.nunes', 'loved', 21.2),
    ('P28', 'thiago.costa', 'claps', 32.7),
    ('P28', 'fernanda.lima', 'claps', 35.7),
    ('P29', 'ana.beatriz', 'loved', 11.6),
    ('P29', 'lucas.ferreira', 'loved', 16.8),
    ('P29', 'ricardo.alves', 'hug', 19.1),
    ('P29', 'diego.design', 'hug', 57.1),
    ('P30', 'fernanda.lima', 'loved', 3.3),
    ('P30', 'vanessa.martins', 'hug', 6.4),
    ('P30', 'dona.lucia', 'hug', 12),
    ('P30', 'maria.helena', 'loved', 24),
    ('P30', 'edson.pereira', 'loved', 36),
    ('P31', 'rafael.mendes', 'loved', 1),
    ('P31', 'thiago.costa', 'hug', 2.2),
    ('P31', 'ana.beatriz', 'claps', 3),
    ('P31', 'renata.campos', 'hug', 4.0),
    ('P31', 'seu.antonio', 'hug', 4.8),
    ('P31', 'ju.rocha', 'loved', 5),
    ('P31', 'edson.pereira', 'hug', 12.8),
    ('P31', 'marcos.vinicius', 'loved', 13.1),
    ('P31', 'ricardo.alves', 'loved', 14.8),
    ('P31', 'diego.design', 'hug', 20.7),
    ('P31', 'fernanda.lima', 'hug', 20.9),
    ('P31', 'ju.rocha', 'hug', 23.9),
    ('P31', 'camila.santos', 'loved', 46.9),
    ('P31', 'lucas.ferreira', 'loved', 50.6),
    ('P31', 'carlos.henrique', 'hug', 51.6),
    ('P31', 'maria.helena', 'loved', 53.1),
    ('P32', 'patricia.nunes', 'claps', 5.9),
    ('P32', 'diego.design', 'loved', 11.1),
    ('P32', 'thiago.costa', 'claps', 22.4),
    ('P32', 'ricardo.alves', 'claps', 45.8),
    ('P32', 'edson.pereira', 'claps', 61.8),
    ('P33', 'vanessa.martins', 'claps', 27.4),
    ('P34', 'lucas.ferreira', 'claps', 10.0),
    ('P34', 'ana.beatriz', 'loved', 10.8),
    ('P34', 'diego.design', 'claps', 59.3),
    ('P35', 'dona.lucia', 'hug', 2.6),
    ('P35', 'seu.antonio', 'hug', 4),
    ('P35', 'rafael.mendes', 'hug', 7.9),
    ('P35', 'jorge.ribeiro', 'hug', 8),
    ('P35', 'patricia.nunes', 'claps', 13.3),
    ('P35', 'edson.pereira', 'claps', 14.3),
    ('P35', 'carlos.henrique', 'loved', 16.2),
    ('P35', 'vanessa.martins', 'claps', 16.8),
    ('P35', 'vanessa.martins', 'loved', 24),
    ('P35', 'ju.rocha', 'loved', 43.4),
    ('P35', 'edson.pereira', 'hug', 48),
    ('P35', 'jorge.ribeiro', 'loved', 63.1),
    ('P36', 'renata.campos', 'loved', 5.8),
    ('P36', 'thiago.costa', 'claps', 11.2),
    ('P36', 'pedro.augusto', 'claps', 15.3),
    ('P36', 'patricia.nunes', 'loved', 21.2),
    ('P36', 'vanessa.martins', 'claps', 22.4),
    ('P36', 'ju.rocha', 'claps', 22.8),
    ('P36', 'fernanda.lima', 'claps', 38.9),
    ('P36', 'carlos.henrique', 'loved', 43.9),
    ('P37', 'marcos.vinicius', 'claps', 1),
    ('P37', 'vanessa.martins', 'loved', 3),
    ('P37', 'camila.santos', 'claps', 6),
    ('P37', 'marcos.vinicius', 'loved', 8.0),
    ('P37', 'ju.rocha', 'claps', 8.3),
    ('P37', 'seu.antonio', 'loved', 16.0),
    ('P37', 'maria.helena', 'loved', 22.4),
    ('P37', 'patricia.nunes', 'claps', 30.1),
    ('P37', 'ana.beatriz', 'loved', 35.5),
    ('P37', 'rafael.mendes', 'claps', 42.3),
    ('P37', 'fernanda.lima', 'hug', 55.3),
    ('P38', 'jorge.ribeiro', 'loved', 4.1),
    ('P38', 'pedro.augusto', 'hug', 20.5),
    ('P38', 'rafael.mendes', 'hug', 40.3),
    ('P38', 'diego.design', 'claps', 42.2),
    ('P39', 'ricardo.alves', 'claps', 0.5),
    ('P39', 'pedro.augusto', 'claps', 2),
    ('P39', 'carlos.henrique', 'claps', 2.8),
    ('P39', 'lucas.ferreira', 'claps', 9.3),
    ('P39', 'seu.antonio', 'loved', 12),
    ('P39', 'thiago.costa', 'claps', 26.2),
    ('P39', 'fernanda.lima', 'claps', 32.2),
    ('P39', 'diego.design', 'claps', 45.3),
    ('P41', 'seu.antonio', 'hug', 16.2),
    ('P42', 'ju.rocha', 'claps', 6.1),
    ('P42', 'camila.santos', 'loved', 8.8),
    ('P42', 'renata.campos', 'loved', 14.8),
    ('P42', 'marcos.vinicius', 'claps', 16.6),
    ('P42', 'carlos.henrique', 'loved', 23.8),
    ('P42', 'vanessa.martins', 'claps', 33.6),
    ('P42', 'ana.beatriz', 'claps', 37.7),
    ('P42', 'pedro.augusto', 'claps', 55.6),
    ('P43', 'thiago.costa', 'claps', 2),
    ('P43', 'pedro.augusto', 'loved', 4),
    ('P43', 'diego.design', 'claps', 6),
    ('P43', 'ana.beatriz', 'hug', 19.5),
    ('P43', 'lucas.ferreira', 'loved', 23.3),
    ('P43', 'diego.design', 'hug', 28.3),
    ('P43', 'carlos.henrique', 'loved', 32.4),
    ('P43', 'edson.pereira', 'hug', 63.9),
    ('P44', 'lucas.ferreira', 'loved', 1.1),
    ('P44', 'renata.campos', 'claps', 13.1),
    ('P44', 'ricardo.alves', 'claps', 16.3),
    ('P44', 'marcos.vinicius', 'loved', 19.9),
    ('P44', 'jorge.ribeiro', 'hug', 22.0),
    ('P44', 'vanessa.martins', 'hug', 41.6),
    ('P44', 'pedro.augusto', 'claps', 69.1),
    ('P45', 'vanessa.martins', 'claps', 6.0),
    ('P45', 'rafael.mendes', 'hug', 9.2),
    ('P45', 'fernanda.lima', 'claps', 13.2),
    ('P45', 'ricardo.alves', 'hug', 66.5),
    ('P46', 'lucas.ferreira', 'hug', 9.9),
    ('P46', 'rafael.mendes', 'claps', 13.3),
    ('P46', 'ricardo.alves', 'claps', 15.6),
    ('P46', 'ana.beatriz', 'claps', 20.4),
    ('P46', 'thiago.costa', 'claps', 65.1),
    ('P47', 'dona.lucia', 'loved', 6),
    ('P47', 'seu.antonio', 'hug', 12),
    ('P47', 'maria.helena', 'loved', 33.9),
    ('P47', 'edson.pereira', 'loved', 39.8),
    ('P49', 'vanessa.martins', 'loved', 2.0),
    ('P49', 'jorge.ribeiro', 'loved', 3.5),
    ('P49', 'rafael.mendes', 'hug', 4),
    ('P49', 'ricardo.alves', 'hug', 8),
    ('P49', 'seu.antonio', 'loved', 14.5),
    ('P49', 'fernanda.lima', 'hug', 15.0),
    ('P49', 'maria.helena', 'loved', 52.3),
    ('P49', 'diego.design', 'hug', 55.6),
    ('P50', 'jorge.ribeiro', 'loved', 14.8),
    ('P50', 'marcos.vinicius', 'loved', 15.4),
    ('P50', 'maria.helena', 'hug', 21.9),
    ('P50', 'dona.lucia', 'hug', 23.9),
    ('P51', 'rafael.mendes', 'loved', 1.9),
    ('P51', 'jorge.ribeiro', 'hug', 2.6),
    ('P51', 'carlos.henrique', 'claps', 16.2),
    ('P51', 'patricia.nunes', 'loved', 18.0),
    ('P51', 'pedro.augusto', 'claps', 19.9),
    ('P51', 'ju.rocha', 'loved', 22.9),
    ('P51', 'vanessa.martins', 'loved', 26.5),
    ('P51', 'renata.campos', 'loved', 39.0),
    ('P51', 'ana.beatriz', 'loved', 69.2),
    ('P52', 'carlos.henrique', 'claps', 1),
    ('P52', 'thiago.costa', 'claps', 2),
    ('P52', 'diego.design', 'hug', 3.0),
    ('P52', 'seu.antonio', 'loved', 8),
    ('P52', 'ana.beatriz', 'hug', 18.4),
    ('P52', 'marcos.vinicius', 'claps', 53.5),
    ('P52', 'thiago.costa', 'hug', 64.6),
    ('P53', 'vanessa.martins', 'hug', 2),
    ('P53', 'vanessa.martins', 'loved', 3.9),
    ('P53', 'ana.beatriz', 'hug', 4),
    ('P53', 'camila.santos', 'loved', 8),
    ('P53', 'rafael.mendes', 'loved', 68.2),
    ('P54', 'rafael.mendes', 'loved', 10.4),
    ('P54', 'ju.rocha', 'claps', 17.5),
    ('P55', 'maria.helena', 'hug', 2.4),
    ('P55', 'rafael.mendes', 'loved', 14.8),
    ('P56', 'dona.lucia', 'loved', 0.9),
    ('P56', 'ricardo.alves', 'claps', 1),
    ('P56', 'thiago.costa', 'claps', 2),
    ('P56', 'renata.campos', 'loved', 5),
    ('P56', 'lucas.ferreira', 'claps', 5.5),
    ('P56', 'rafael.mendes', 'claps', 8),
    ('P56', 'renata.campos', 'claps', 8.1),
    ('P56', 'marcos.vinicius', 'claps', 8.2),
    ('P56', 'seu.antonio', 'loved', 9.8),
    ('P56', 'rafael.mendes', 'loved', 20.1),
    ('P56', 'patricia.nunes', 'hug', 20.3),
    ('P56', 'pedro.augusto', 'loved', 27.5),
    ('P56', 'ju.rocha', 'claps', 32.4),
    ('P56', 'fernanda.lima', 'loved', 44.0),
    ('P56', 'vanessa.martins', 'claps', 48.0),
    ('P56', 'camila.santos', 'hug', 51.6),
    ('P57', 'seu.antonio', 'hug', 4),
    ('P57', 'seu.antonio', 'loved', 4.6),
    ('P57', 'maria.helena', 'loved', 8),
    ('P57', 'lucas.ferreira', 'claps', 11.4),
    ('P57', 'jorge.ribeiro', 'hug', 16.5),
    ('P57', 'edson.pereira', 'claps', 23.7),
    ('P57', 'edson.pereira', 'hug', 24),
    ('P57', 'patricia.nunes', 'loved', 27.6),
    ('P57', 'vanessa.martins', 'loved', 55.0),
    ('P58', 'fernanda.lima', 'loved', 7.2),
    ('P58', 'ju.rocha', 'loved', 11.4),
    ('P58', 'edson.pereira', 'hug', 28.3),
    ('P58', 'patricia.nunes', 'hug', 52.4),
    ('P59', 'ju.rocha', 'hug', 4.9),
    ('P59', 'fernanda.lima', 'claps', 23.0),
    ('P60', 'renata.campos', 'hug', 2.4),
    ('P60', 'camila.santos', 'hug', 3.5),
    ('P60', 'vanessa.martins', 'loved', 8.4),
    ('P60', 'lucas.ferreira', 'loved', 9.6),
    ('P60', 'ana.beatriz', 'hug', 22.1),
    ('P60', 'thiago.costa', 'hug', 38.9),
    ('P60', 'rafael.mendes', 'loved', 56.6),
    ('P60', 'fernanda.lima', 'loved', 70.3),
    ('P61', 'jorge.ribeiro', 'hug', 15.7),
    ('P61', 'vanessa.martins', 'hug', 59.5),
    ('P62', 'lucas.ferreira', 'hug', 5.8),
    ('P62', 'ricardo.alves', 'hug', 8.4),
    ('P62', 'carlos.henrique', 'claps', 9.4),
    ('P62', 'vanessa.martins', 'loved', 20.3),
    ('P62', 'diego.design', 'loved', 64.1),
    ('P63', 'ju.rocha', 'hug', 4.3),
    ('P63', 'rafael.mendes', 'hug', 6.1),
    ('P63', 'vanessa.martins', 'loved', 13.9),
    ('P63', 'dona.lucia', 'claps', 18.2),
    ('P63', 'camila.santos', 'loved', 61.3),
    ('P63', 'renata.campos', 'claps', 67.4),
    ('P64', 'patricia.nunes', 'claps', 2.4),
    ('P64', 'ju.rocha', 'loved', 3.4),
    ('P64', 'fernanda.lima', 'hug', 9.8),
    ('P64', 'camila.santos', 'claps', 11.1),
    ('P64', 'marcos.vinicius', 'loved', 28.4),
    ('P64', 'carlos.henrique', 'hug', 66.5),
    ('P66', 'vanessa.martins', 'loved', 2),
    ('P66', 'camila.santos', 'hug', 2.0),
    ('P66', 'ju.rocha', 'claps', 4),
    ('P66', 'renata.campos', 'loved', 6.1),
    ('P66', 'camila.santos', 'loved', 8),
    ('P66', 'marcos.vinicius', 'hug', 13.1),
    ('P66', 'diego.design', 'hug', 17.4),
    ('P66', 'ana.beatriz', 'hug', 18.7),
    ('P66', 'dona.lucia', 'loved', 22.6),
    ('P66', 'patricia.nunes', 'hug', 24.9),
    ('P67', 'carlos.henrique', 'loved', 1),
    ('P67', 'seu.antonio', 'loved', 4),
    ('P67', 'ricardo.alves', 'claps', 8),
    ('P67', 'seu.antonio', 'hug', 9.7),
    ('P67', 'thiago.costa', 'claps', 12.4),
    ('P67', 'lucas.ferreira', 'loved', 23.4),
    ('P67', 'diego.design', 'claps', 23.6),
    ('P68', 'carlos.henrique', 'claps', 8.8),
    ('P68', 'diego.design', 'claps', 14.2),
    ('P68', 'ricardo.alves', 'loved', 20.0),
    ('P68', 'lucas.ferreira', 'claps', 47.0),
    ('P69', 'edson.pereira', 'hug', 1.4),
    ('P69', 'thiago.costa', 'loved', 6.9),
    ('P69', 'dona.lucia', 'loved', 9.9),
    ('P69', 'seu.antonio', 'hug', 9.9),
    ('P69', 'maria.helena', 'hug', 20.8),
    ('P69', 'vanessa.martins', 'loved', 40.3),
    ('P70', 'vanessa.martins', 'loved', 1),
    ('P70', 'ricardo.alves', 'claps', 3),
    ('P70', 'camila.santos', 'claps', 6),
    ('P70', 'lucas.ferreira', 'claps', 8.2),
    ('P70', 'pedro.augusto', 'claps', 11.0),
    ('P70', 'ju.rocha', 'claps', 17.4),
    ('P70', 'jorge.ribeiro', 'claps', 19.1),
    ('P70', 'fernanda.lima', 'claps', 32.7),
    ('P70', 'ana.beatriz', 'loved', 53.5)
) AS r(post_str_id, username, reaction_type, delay_hours)
JOIN _seed_post_map m ON m.str_id = r.post_str_id;

DO $$ BEGIN RAISE NOTICE 'FASE 12 concluída: reações inseridas.'; END $$;

-- ============================================================
-- FASE 13: Inserir 163 comentários via JOIN em _seed_post_map
-- ============================================================
INSERT INTO public.comments (user_id, post_id, content, created_at)
SELECT
    (SELECT user_id FROM _seed_profile_map WHERE username = c.username),
    m.post_id,
    c.comment_content,
    m.created_at + (c.delay_hours || ' hours')::interval
FROM (VALUES
    ('CP01', 'ana.beatriz', 'Esse ''a gente volta andando'' é técnica de motivação que funciona. Marcos, você é mestre.', 3),
    ('CP01', 'marcos.vinicius', 'Van, eu só te lembrei do que você já era capaz. O mérito foi seu nos 21km.', 6),
    ('CP02', 'lucas.ferreira', 'Eu também quase desisti na segunda semana, Thiago. Que bom que ficou.', 4),
    ('CP02', 'ricardo.alves', 'Curiosidade é tudo. Thiago, valeu por ter ficado.', 7),
    ('CP03', 'jorge.ribeiro', 'Helena tem esse dom. Salvar gente sem fazer barulho.', 6),
    ('CP03', 'vanessa.martins', 'Que história. Dona Lúcia, obrigada por compartilhar isso aqui.', 14),
    ('CP04', 'edson.pereira', 'Antônio, eu falei aquilo numa hora qualquer e o senhor levou pra vida. É honra.', 8),
    ('CP05', 'maria.helena', 'Jorge, vou ser eternamente grata por você ter me ouvido naquele dia.', 6),
    ('CP05', 'dona.lucia', 'Helena salva a aposentadoria de muita gente. Inclusive a minha.', 14),
    ('CP06', 'patricia.nunes', 'Vou anotar essa frase. ''Solidão é parar de ir atrás dos outros.'' Forte demais.', 5),
    ('CP07', 'fernanda.lima', 'Rafa, eu nem lembrava desse post-it. Que bom que importou. ❤️', 4),
    ('CP07', 'ju.rocha', 'Quatro palavras mudam dia. Vou começar a deixar bilhetinhos pelo time.', 9),
    ('CP08', 'ju.rocha', 'Cami, você merecia ouvir. Tava bom mesmo. ✨', 5),
    ('CP09', 'carlos.henrique', 'Pedro, você é dos melhores devs que conheço. Eu manderia 10 vagas se aparecessem.', 4),
    ('CP10', 'renata.campos', 'Ana, eu não sabia que isso era visível. Obrigada. Vou tentar continuar assim.', 6),
    ('CP10', 'vanessa.martins', 'A Ana tá certa. Renata, você lidera mais pelo exemplo do que pelas reuniões.', 11),
    ('CP11', 'pedro.augusto', '''A carne avisa quando tá pronta'' = ''o código avisa quando tá pronto''. Mesma sabedoria. 🍖💻', 4),
    ('CP12', 'patricia.nunes', 'Diego, fico feliz que algo de aula de pedagogia tenha chegado em design. Você usa bem!', 5),
    ('CP12', 'ju.rocha', 'Se o usuário não entendeu, o problema é da gente. Vou colar isso no Figma.', 10),
    ('P01', 'diego.design', 'Ju é fora da curva mesmo. A gente tem sorte de ter ela no time.', 4),
    ('P01', 'ricardo.alves', 'Esse tipo de coisa não aparece em OKR mas faz a diferença real. 🙌', 8),
    ('P02', 'vanessa.martins', 'Documentação é amor, gente. Quem documenta cuida do próximo dev. Rafa é assim mesmo.', 3),
    ('P02', 'fernanda.lima', 'Esse componente salvou minha sprint, sério. Pode falar dele em todas as retros que eu apoio.', 6),
    ('P03', 'ju.rocha', 'Diego, isso aqui é puro afeto. Que coisa linda.', 5),
    ('P03', 'patricia.nunes', 'Quem é vizinho da gente também é família. Dona Lúcia parece um tesouro.', 14),
    ('P04', 'lucas.ferreira', 'Cara, eu tava morrendo de medo de apontar aquilo. Obrigado por reconhecer, chefe.', 2),
    ('P04', 'vanessa.martins', 'Isso diz muito sobre a cultura que o Ricardo criou no time. Estagiário se sentir seguro pra discordar é raro.', 5),
    ('P05', 'renata.campos', 'Ana, força. E Van, obrigada por cuidar do time além do trabalho.', 4),
    ('P05', 'marcos.vinicius', 'Pedir ajuda é coragem. Reconhecer essa coragem é mais raro ainda. ✊', 12),
    ('P06', 'jorge.ribeiro', 'O Antônio é assim desde que eu me lembro. Não espera pedir.', 12),
    ('P07', 'jorge.ribeiro', 'Bolo de fubá da Lúcia é coisa séria. Antônio, o senhor é privilegiado.', 6),
    ('P07', 'edson.pereira', 'Casal raiz. 👏', 18),
    ('P08', 'pedro.augusto', 'Eu não sou herói, sou burro mesmo kkkk mas valeu a bronca em casa', 1),
    ('P08', 'ricardo.alves', 'A esposa do Pedro, se estiver lendo: a culpa é do Carlos que marcou o jogo', 2),
    ('P09', 'rafael.mendes', 'Cami!!!!! Que orgulho! Lembro quando você disse que odiava correr hahaha', 3),
    ('P09', 'ana.beatriz', 'Chorei vendo essa foto. Sério. To muito feliz por você!', 5),
    ('P10', 'vanessa.martins', 'Posso confirmar: o Ricardo é assim com TODO mundo. Não muda quando vira liderança.', 2),
    ('P10', 'lucas.ferreira', 'Thiago tá certíssimo. O Ricardo me explicou o mesmo bug umas 4 vezes sem reclamar uma vez.', 5),
    ('P11', 'marcos.vinicius', 'Escutar é das coisas mais difíceis. Vanessa faz parecer fácil.', 6),
    ('P12', 'ju.rocha', 'Comecei a notar isso depois desse post da Fer. É verdade!', 4),
    ('P12', 'ana.beatriz', 'Vou copiar essa prática nas minhas retros também. Bora propagar.', 8),
    ('P13', 'vanessa.martins', 'Saber escutar é o que me falta. Maria Helena é referência.', 6),
    ('P14', 'ana.beatriz', 'Isso de esperar no km3 já fizeram comigo TBM. O Marcos é bom demais.', 4),
    ('P14', 'renata.campos', 'Esse é o líder que muda jornada. Cami, parabéns por não desistir.', 7),
    ('P15', 'carlos.henrique', 'Eu QUASE fiz o gol ok? A bola desviou. Desviou. (Não desviou, mas me deixa sonhar.)', 0.5),
    ('P15', 'thiago.costa', 'o Carlos é assim, erra gol mas acerta amizade kkk', 1),
    ('P16', 'carlos.henrique', 'Os dois juntos são monstros. Adoro ver vocês crescerem.', 3),
    ('P16', 'ricardo.alves', 'Thiago, eu tava torcendo pra acontecer essa parceria. Continua.', 6),
    ('P17', 'vanessa.martins', 'Posso confirmar: 100% verdade. O Ricardo nunca puxa crédito.', 2),
    ('P17', 'rafael.mendes', 'Endorso 1000%. Ricardo é exemplo de como liderança deveria ser ensinada.', 3),
    ('P17', 'ana.beatriz', 'Esse ''eu não vi esse risco'' é a humildade que falta em muito gestor. 👏', 5),
    ('P18', 'seu.antonio', 'Esse dia eu lembro. O Jorge era teimoso, não queria ajuda. Mas eu sou mais teimoso.', 24),
    ('P19', 'patricia.nunes', 'Helena, ler isso me emocionou. A senhora me ensina muito mais do que eu ensino.', 3),
    ('P19', 'dona.lucia', 'Helena minha querida, suas memórias importam sim. Pra todas nós.', 11),
    ('P20', 'ricardo.alves', 'Fer, aquela dashboard tá sendo usada até pelo board agora. Você não imagina o impacto.', 4),
    ('P20', 'rafael.mendes', 'Refazer 3 vezes sem ninguém pedir é amor pelo ofício. 🙏', 7),
    ('P21', 'dona.lucia', 'Edson, você descreveu o Antônio de verdade. Ele não muda mesmo.', 6),
    ('P21', 'jorge.ribeiro', 'Trinta anos depois, mesmas mãos, mesma paciência. Privilégio conhecer.', 9),
    ('P22', 'ju.rocha', 'Esse ''e se a gente invertesse'' é técnica de feedback que vou usar a vida inteira.', 4),
    ('P23', 'marcos.vinicius', 'A Renata é máquina. Mas o que ela falou sobre ''uma coisa não cancela a outra'' é filosofia de vida.', 5),
    ('P23', 'vanessa.martins', 'Renata é a prova viva de que disciplina não exclui prazer. Aprendi muito vendo ela.', 9),
    ('P23', 'ana.beatriz', 'Quero ser Renata quando crescer. 👑', 14),
    ('P24', 'diego.design', 'Dona Lúcia, a senhora me faz mais falta do que a senhora imagina. Vou ligar hoje.', 3),
    ('P25', 'rafael.mendes', '''Líder é quem espera'' — vou colar isso no meu monitor.', 3),
    ('P25', 'patricia.nunes', 'Comecei a correr por causa do Marcos. Ele espera mesmo, ninguém fica pra trás.', 8),
    ('P26', 'pedro.augusto', 'Diego é o cara que toda pelada precisa. Não joga muito mas levanta o moral. Hahaha.', 2),
    ('P26', 'lucas.ferreira', 'Aquele abraço foi épico. Quase chorei.', 5),
    ('P26', 'thiago.costa', 'Diego é o MVP emocional da pelada, oficialmente.', 11),
    ('P27', 'vanessa.martins', 'Cami é a definição de quem busca evolução, não validação. ❤️', 4),
    ('P28', 'camila.santos', '100 dias!! Rafa, você me motivou a não faltar o treino de sábado quando tá chovendo', 2),
    ('P28', 'ricardo.alves', 'Cem dias é muita coisa. Parabéns Rafa.', 3),
    ('P28', 'ana.beatriz', 'Esses 15 minutos de esteira no hotel são os que mais valem. Disciplina é nos dias difíceis.', 5),
    ('P28', 'renata.campos', 'Inspirador demais. 🏃‍♂️', 7),
    ('P29', 'carlos.henrique', 'Thiago, isso é maturidade. Notar que alguém tá quieto demais é radar de bom amigo.', 4),
    ('P29', 'ricardo.alves', 'Esse tipo de coisa não cabe em PR review mas é o que segura o time.', 7),
    ('P31', 'rafael.mendes', 'Esse ''a gente conserta junto'' deveria ser regra de gestão.', 4),
    ('P31', 'fernanda.lima', 'Ricardo é referência. Vanessa também, por reconhecer isso publicamente. 💪', 8),
    ('P32', 'ju.rocha', 'Van é puro cuidado. Lembrar do café coado da Fer é o tipo de detalhe que cria família.', 3),
    ('P32', 'ricardo.alves', 'Van, você é o tecido conjuntivo desse time. Sério.', 6),
    ('P33', 'rafael.mendes', 'Ju dá o melhor feedback do mundo. Honesto sem ser duro.', 5),
    ('P34', 'lucas.ferreira', 'Cara, eu nem sei o que dizer. Obrigado Thiago. De verdade.', 3),
    ('P34', 'ricardo.alves', 'Esse moleque vai longe mesmo. Time é maior que ego, e o Thiago entendeu cedo.', 4),
    ('P34', 'lucas.ferreira', 'Eu lembro daquele jogo. Quando o Thiago começou a passar pra mim eu pensei: ''tá com pena ou tá vendo''. Era ver.', 6),
    ('P34', 'diego.design', 'Aí sim. 🔥', 12),
    ('P35', 'dona.lucia', 'Minha querida Helena, não sabia que a senhora ia me fazer chorar logo cedo assim', 4),
    ('P35', 'vanessa.martins', 'Que história linda. 40 anos de café juntas. ❤️', 6),
    ('P35', 'patricia.nunes', 'Isso aqui é literatura. Helena, você escreve com o coração.', 10),
    ('P36', 'thiago.costa', 'Posso confirmar que ele responde estagiário sim. Isso me marcou no primeiro mês.', 4),
    ('P36', 'ana.beatriz', 'Acessibilidade é forma de respeito. Ricardo tem isso.', 8),
    ('P37', 'marcos.vinicius', 'Ana, foi lindo ver você cruzar. O Miguel deve ter ficado orgulhosíssimo.', 3),
    ('P37', 'ana.beatriz', 'Vocês vão me fazer chorar de novo. O Miguel ficou todo orgulhoso quando contei pra ele.', 6),
    ('P37', 'vanessa.martins', 'Mãe solo correndo meia maratona é sobrenatural. 👏', 8),
    ('P37', 'camila.santos', 'Você inspirou metade do grupo de corrida, Ana. Sério.', 14),
    ('P38', 'thiago.costa', 'Git rebase é troll mesmo. Carlos teve paciência de santo.', 3),
    ('P38', 'ricardo.alves', 'Tratar ignorância com respeito é virtude rara. Carlos manda bem.', 6),
    ('P39', 'edson.pereira', 'Não me trata diferente pq sou velho? Gostei. Pq na próxima pelada eu passo por você de novo.', 3),
    ('P40', 'vanessa.martins', 'Diego cresceu absurdamente. Recebia feedback e travava. Hoje vem com 3 versões.', 4),
    ('P40', 'rafael.mendes', 'Maturidade é isso mesmo. Diego, parabéns. 🎯', 7),
    ('P41', 'ricardo.alves', 'Van tem esse radar. Percebe antes de qualquer um.', 5),
    ('P42', 'ana.beatriz', 'Patrícia, você vai amar correr. E vai chorar na primeira 5k, te aviso.', 3),
    ('P42', 'marcos.vinicius', 'Bem-vinda, Patrícia! O grupo te espera.', 6),
    ('P43', 'pedro.augusto', 'MVP fora de campo é a definição certa. Sem o Carlos não tem pelada.', 2),
    ('P43', 'thiago.costa', 'Carlos, valeu por carregar tudo nas costas, cara. Sem você a gente tava perdido.', 5),
    ('P43', 'diego.design', 'Confirma. Carlos é o pilar invisível. 🏛️', 9),
    ('P44', 'vanessa.martins', 'Esse silêncio depois do ''tô bem'' é técnica de gestão de gente, viu. Renata sabe.', 3),
    ('P44', 'fernanda.lima', 'Quero aprender essa habilidade. Renata é referência.', 7),
    ('P45', 'patricia.nunes', 'Marcos, vou guardar essas palavras. ''Você não me deixou desistir'' tá ficando comigo.', 4),
    ('P45', 'renata.campos', 'Esse ''falta 1km'' salvou a vida de muita gente que eu conheço. 👏', 8),
    ('P46', 'ana.beatriz', 'Honestidade > produtividade tóxica. Ju é fora da casinha.', 5),
    ('P46', 'rafael.mendes', 'Aceitar que algo vai cair é mais maduro que fingir que dá conta de tudo.', 9),
    ('P47', 'jorge.ribeiro', 'Helena, o Bento adorou. Pediu pra senhora escrever outro pro aniversário do irmão dele haha', 2),
    ('P47', 'dona.lucia', 'Helena escreve poema do jeito que vê a alma das pessoas. Que dom.', 5),
    ('P47', 'patricia.nunes', 'Helena, eu amo seus poemas. Quando vai me deixar publicar um na escola?', 12),
    ('P49', 'ricardo.alves', 'Van é assim com todo mundo, Dona Lúcia. A senhora não viu nada ainda.', 6),
    ('P49', 'ju.rocha', 'Quarenta minutos no telefone com paciência é amor. 💛', 11),
    ('P50', 'ricardo.alves', 'Caráter mesmo. Esse tipo de coisa o Carlos não conta, eu sempre fico sabendo por terceiros.', 4),
    ('P50', 'ju.rocha', 'Em 2h ele juntou tudo isso? Que rede, que solidariedade. 🙏', 8),
    ('P51', 'renata.campos', 'Cami, você tem o instinto certo. Silêncio solidário é raro e poderoso.', 5),
    ('P51', 'ana.beatriz', 'Cami, sério. Sem você eu teria parado. Obrigada de novo.', 9),
    ('P52', 'edson.pereira', 'Descalço mesmo, e a bola era de meia com jornal dentro kkk. Mas o amor pela bola era de verdade.', 1),
    ('P52', 'carlos.henrique', 'Aquele gol foi obra de arte. 62 anos? Senhor Edson, o senhor é fenômeno.', 3),
    ('P52', 'thiago.costa', 'Câmera lenta literal. Eu tava lá e ainda não acredito.', 6),
    ('P52', 'lucas.ferreira', 'Quero jogar bola assim aos 62. 🐐', 10),
    ('P53', 'ana.beatriz', '''Eu sei que se vira, mas eu fico'' é a frase que eu queria ter ouvido a vida inteira.', 5),
    ('P53', 'vanessa.martins', 'Choro toda vez que penso em 38km. Vocês dois são guerreiros.', 9),
    ('P54', 'ricardo.alves', 'QA com senso de dono é o que eleva o produto inteiro. Cami, parabéns.', 3),
    ('P54', 'ju.rocha', 'Sexta às 17h e ela não fugiu? Cami, que disciplina.', 7),
    ('P55', 'dona.lucia', 'Esses dois são família escolhida. Quanta sorte ter um amigo assim.', 4),
    ('P55', 'jorge.ribeiro', 'Café no caminho de volta é a melhor parte. 👴☕', 8),
    ('P56', 'lucas.ferreira', 'Caramba, tô emocionado. Obrigado Carlos. E obrigado por ter tido paciência comigo quando eu não sabia nada.', 1),
    ('P56', 'ricardo.alves', 'Esse é o ciclo bonito: a gente ensina, e um dia não precisa mais ensinar. Parabéns Lucas!', 3),
    ('P56', 'ricardo.alves', 'Esse ''virar desnecessário'' é a melhor definição de mentor que já li. Carlos, mandou bem.', 4),
    ('P56', 'thiago.costa', 'Lucas, parabéns!! Em breve a gente também tá ali.', 8),
    ('P56', 'vanessa.martins', 'Esse momento merece ser eternizado. Que orgulho do time.', 12),
    ('P57', 'jorge.ribeiro', 'Lúcia, eu não sabia disso. Vou começar a buzinar de novo só pra senhora ouvir. 😂', 6),
    ('P57', 'maria.helena', 'A Lúcia tem o dom de ver poesia no cotidiano. ❤️', 11),
    ('P58', 'rafael.mendes', '''Aqui eu fiquei confusa, aqui eu sorri, aqui eu desisti'' — gold standard de feedback de UX.', 5),
    ('P58', 'fernanda.lima', 'Vou pedir pra Cami testar tudo que eu fizer daqui pra frente.', 9),
    ('P59', 'patricia.nunes', 'Van, foi uma das melhores conversas que tive em meses. Bora repetir.', 4),
    ('P60', 'rafael.mendes', 'Discordar com argumento e dado, sem ego. Os dois acertaram aí. 👏', 5),
    ('P60', 'renata.campos', 'Esse tipo de cultura precisa ser celebrado. Bom demais.', 9),
    ('P61', 'dona.lucia', 'O Jorge é assim mesmo. Caixa de ferramentas e coração grande.', 5),
    ('P61', 'patricia.nunes', '''Me paga com um café''. Que homem. ☕', 10),
    ('P62', 'ana.beatriz', 'Admitir erro publicamente é o ato de liderança mais subestimado que existe. Renata é exemplo.', 4),
    ('P62', 'ricardo.alves', 'Pelo contrário mesmo. Eu sai daquela retro com mais respeito por ela.', 8),
    ('P63', 'marcos.vinicius', 'Vocês duas são prova de que companheirismo no esporte muda vidas.', 6),
    ('P63', 'renata.campos', 'Silêncio solidário é a melhor invenção. ❤️', 10),
    ('P64', 'thiago.costa', 'Ele continua perguntando no Stack Overflow??? KKKKKK Ricardo, gosto cada vez mais.', 3),
    ('P64', 'carlos.henrique', '''Saber perguntar'' é a habilidade mais subestimada de dev sênior. Anote, juniores.', 6),
    ('P65', 'dona.lucia', 'Jorge, você sempre vai ser do bairro, não importa onde more. Beijo.', 4),
    ('P65', 'seu.antonio', 'Bolo da Lúcia conecta gente. Verdade. 🍰', 12),
    ('P66', 'marcos.vinicius', 'Rafa, eu falei porque eu vi. Você que fez o trabalho difícil de acreditar. Orgulho de correr contigo.', 1),
    ('P66', 'ana.beatriz', 'Acreditar em alguém antes da pessoa acreditar em si é dom de mentor.', 4),
    ('P66', 'vanessa.martins', 'Cem dias e contando. Rafa, você é exemplo agora pra muita gente.', 9),
    ('P67', 'thiago.costa', 'Senhor Edson, MEU MESTRE! 🙏 Honra jogar com o senhor.', 4),
    ('P67', 'carlos.henrique', 'Thiago é assim em tudo. Educação que vem de casa.', 8),
    ('P68', 'ricardo.alves', 'Fernanda transforma número em narrativa. É uma habilidade rara.', 5),
    ('P68', 'vanessa.martins', 'Aquela dashboard mudou conversas no board. Fer, parabéns. 📊', 9),
    ('P69', 'carlos.henrique', 'DevOps aprendendo a afiar faca com carpinteiro. Brasileiro é incrível. 😂', 4),
    ('P69', 'lucas.ferreira', 'Tarde melhor que workshop é forte. Confirmo.', 9),
    ('P69', 'seu.antonio', 'Pedro, qualquer dia desses traz a faca de novo. Tá ficando boa, falta um pouco mais.', 18),
    ('P70', 'ricardo.alves', 'Documentação invisível é a mais valiosa. Fer, mandou bem demais.', 4),
    ('P70', 'patricia.nunes', 'Posso confirmar que cheguei no time e tinha tudo escrito. Salvação. 🙏', 7)
) AS c(post_str_id, username, comment_content, delay_hours)
JOIN _seed_post_map m ON m.str_id = c.post_str_id;

DO $$ BEGIN RAISE NOTICE 'FASE 13 concluída: comentários inseridos.'; END $$;

-- ============================================================
-- FASE 14: Inserir 71 feedbacks via JOIN em _seed_post_map
-- mentioned_user_id = quem dá o feedback | author_id = autor do post
-- ============================================================
INSERT INTO public.feedbacks (mentioned_user_id, author_id, post_id, feedback_text, created_at)
SELECT
    (SELECT user_id FROM _seed_profile_map WHERE username = fb.username),
    (SELECT user_id FROM _seed_profile_map WHERE username = m.author),
    m.post_id,
    fb.feedback_content,
    m.created_at + (fb.delay_hours || ' hours')::interval
FROM (VALUES
    ('CP05', 'maria.helena', 'Jorge, eu tava com medo de te perder pra aposentadoria. Você voltou pra vida. Obrigada por ter ouvido.', 8),
    ('CP10', 'renata.campos', 'Ana, copia mesmo. Eu copio gente que admiro. É como a liderança se propaga. Obrigada por ser observadora.', 14),
    ('CP11', 'seu.antonio', 'Lucas, paciência com madeira é a mesma com a vida. Ainda bem que serviu pro código. Espera. Funciona.', 10),
    ('P01', 'ju.rocha', 'Rafa, a gente é time. Não precisa agradecer. Mas... obrigada por notar. Isso importa mais do que o CSS.', 3),
    ('P02', 'rafael.mendes', 'Ju, fico envergonhado com tanta coisa boa. Mas obrigado. Documentar é só não querer que ninguém sofra o que eu sofri. 😅', 5),
    ('P03', 'dona.lucia', 'Meu filho, eu não sabia que você sentia isso. Agora eu sei. E agora eu vou ligar mais vezes. Cuida-se, viu?', 24),
    ('P04', 'thiago.costa', 'Ricardo, você nem imagina o que esse post fez comigo. Tava me cobrando demais e isso me deu ar. Obrigado de verdade, chefe.', 7),
    ('P05', 'ana.beatriz', 'Van, obrigada por contar essa história com tanto cuidado. E obrigada por ter sido o chão que eu precisava naquele dia.', 2),
    ('P06', 'seu.antonio', 'Lúcia, prateleira a gente conserta com martelo. O que a senhora me dá com bolo de fubá não tem ferramenta pra explicar.', 16),
    ('P07', 'dona.lucia', 'Antônio, você fala pouco mas faz muito. Sempre foi assim. E é por isso que meu bolo de fubá é sempre pra você primeiro.', 4),
    ('P08', 'pedro.augusto', 'Carlos kkkkkk valeu pelo reconhecimento. Mas vê se da próxima a gente já chega ganhando, pra eu poder ir embora antes da bronca.', 8),
    ('P09', 'camila.santos', 'Marcos, eu não teria começado se não fosse você falando ''vem só pra caminhar, não precisa correr''. Você abriu uma porta que eu nem sabia que existia.', 10),
    ('P10', 'ricardo.alves', 'Thiago, obrigado. Mas o mérito é todo seu: é a sua curiosidade que faz eu querer ensinar. Não para.', 6),
    ('P11', 'vanessa.martins', 'Ana, escutar você foi privilégio. E você não fez ''aquele papel'' coisa nenhuma — você foi humana, e isso é coragem.', 6),
    ('P12', 'rafael.mendes', 'Fer, eu faço isso porque um chefe meu lá atrás fazia. Ele nunca vai saber que ainda mora nas retros do nosso time. ❤️', 8),
    ('P13', 'maria.helena', 'Patrícia querida, a elegância que você descreve é só o resultado de ter errado muito e aprendido a pedir desculpa. Obrigada pelo carinho.', 48),
    ('P14', 'marcos.vinicius', 'Cami, eu te esperaria na hora que fosse. Foi você que apareceu. Sempre foi você.', 7),
    ('P15', 'carlos.henrique', 'Pedro, eu ERREI o gol. Mas notar amigo eu nunca erro. Continua aí, irmão.', 5),
    ('P16', 'thiago.costa', 'Lucas, foi a melhor decisão que eu tomei no estágio. Crescer junto > competir sozinho. Sempre.', 4),
    ('P17', 'ricardo.alves', 'Renata, eu só faço o que qualquer líder deveria fazer. Mas obrigado por enxergar isso. Faz eu querer continuar acertando.', 8),
    ('P18', 'edson.pereira', 'Jorge, eu lembro daquele dia. Você era teimoso pra caramba mas tinha mão boa. Quase 40 anos. Pô. 🥹', 30),
    ('P19', 'patricia.nunes', 'Helena, fui eu que ganhei nessa troca. Suas memórias são herança que vou levar. Nunca vou parar de ouvir.', 5),
    ('P20', 'fernanda.lima', 'Van, dado confuso é dado que magoa. Refazer 3 vezes foi pouco. Faria de novo. Obrigada por ver isso.', 10),
    ('P21', 'seu.antonio', 'Edson, com você eu aprendi a ser paciente. Lixar madeira foi a parte fácil. Difícil foi não passar a bronca pro meu neto. 😄', 10),
    ('P22', 'rafael.mendes', 'Diego, feedback bom é igual design bom: muda tudo sem a pessoa perceber que mudou. Fico feliz que funcionou.', 5),
    ('P23', 'renata.campos', 'Ricardo, obrigada. Mas honestamente: fui só por gosto. Não tem mérito em fazer o que a gente ama.', 9),
    ('P24', 'diego.design', 'Dona Lúcia, a senhora é que faz parte da minha vida. Vou continuar ligando. Promessa.', 6),
    ('P25', 'marcos.vinicius', 'Ana, esperar todo mundo é o mínimo. Você me deu mais aprendizado correndo no seu pace do que muitos treinos.', 11),
    ('P26', 'diego.design', 'Carlos, eu jogo mal mesmo, sem polêmica kkkk mas comemorar gol dos outros é onde sou bom. Vocês me trouxeram pra pelada e eu nunca vou esquecer.', 4),
    ('P27', 'camila.santos', 'Ju, foi seu feedback honesto que me fez melhorar. 6h da manhã refazendo é resultado de você ter me tratado com seriedade. Obrigada.', 6),
    ('P28', 'rafael.mendes', 'Marcos, 100 dias eu corri. Mas começar foi você. Continua puxando a galera. ❤️', 8),
    ('P29', 'lucas.ferreira', 'Thiago, eu tava prestes a desistir do bug. Sua mensagem mudou meu dia. Obrigado, irmão.', 5),
    ('P31', 'ricardo.alves', 'Van, eu aprendi que liderar é proteger, não expor. Mas obrigado por reconhecer. Isso me motiva a continuar nesse caminho.', 12),
    ('P32', 'vanessa.martins', 'Fer, você gosta de café coado e eu gosto de saber que vocês são gente, não recurso. É só isso.', 7),
    ('P33', 'ju.rocha', 'Cami, foi meu papel falar verdade. O seu foi ouvir. E você ouviu de coração aberto. Isso é quase tudo.', 5),
    ('P34', 'thiago.costa', 'Pedro, sorri porque o Lucas merecia o gol. Time é fácil quando todo mundo sabe que vai ter dia de cada um. 🤝', 6),
    ('P35', 'dona.lucia', 'Helena minha querida, a gente se conheceu pelo acaso e ficou pelo querer. Que sorte a minha.', 8),
    ('P36', 'ricardo.alves', 'Rafa, responder mensagem é o mínimo do mínimo. Mas obrigado. Vou continuar.', 6),
    ('P37', 'ana.beatriz', 'Renata, eu chorei lendo isso. O Miguel perguntou por que eu tava chorando e eu disse ''porque alguém viu a mamãe''. Obrigada.', 4),
    ('P38', 'carlos.henrique', 'Lucas, ignorância não existe. Existe coisa que você ainda não viu. Cinco vezes ou cinquenta, a gente repete sem julgar.', 5),
    ('P39', 'carlos.henrique', 'Senhor Edson, idade não tira jogador da pelada. Tira só os que param de jogar. O senhor não é desses.', 6),
    ('P40', 'diego.design', 'Ju, o feedback antes era sobre mim. Hoje entendi que é sobre o trabalho. Mudou tudo.', 5),
    ('P41', 'vanessa.martins', 'Diego, eu só perguntei se queria café. Você que aceitou. Obrigada por ter aceitado.', 8),
    ('P42', 'ana.beatriz', 'Patrícia, espero te ver chegando na largada da sua 5k. Vou tá lá te esperando no fim. ❤️', 4),
    ('P43', 'carlos.henrique', 'Ricardo, organizo porque amo ver vocês. Não é favor. É privilégio. E a bola extra é porque a primeira sempre sai.', 6),
    ('P44', 'renata.campos', 'Ana, o silêncio depois do ''tô bem'' eu aprendi com terapia, não com livro de gestão. 😅 Mas funciona.', 6),
    ('P45', 'patricia.nunes', 'Marcos, eu queria mesmo desistir. Mas seu jeito de não pressionar me deu coragem. Foi seu pace que me carregou.', 7),
    ('P46', 'ju.rocha', 'Van, eu falei aquilo num momento de desabafo. Mas se serviu pra alguém, fico feliz. Honestidade é o meu jeito de cuidar.', 8),
    ('P47', 'maria.helena', 'Jorge, escrever sobre o Bento foi como escrever sobre meu próprio neto. Suas histórias me chegam. ❤️', 9),
    ('P48', 'diego.design', 'Thiago, ideia boa não pode morrer no rascunho. Que bom que segurei essa.', 6),
    ('P49', 'vanessa.martins', 'Dona Lúcia, a senhora foi a pessoa mais importante do mundo naquele momento mesmo. Banco é confuso pra todo mundo. Mas a senhora aprendeu rápido!', 12),
    ('P50', 'carlos.henrique', 'Rafa, era uma família que precisava de ajuda. A gente tinha o que dar. Não tem mérito.', 7),
    ('P51', 'ana.beatriz', 'Cami, você ficou e isso foi tudo. ''Obrigada por ficar'' é a frase mais importante que eu disse esse mês.', 6),
    ('P52', 'edson.pereira', 'Pedro, aquele gol foi sorte. Mas o amor pela bola é o que carrega. Continua jogando. Sempre.', 9),
    ('P53', 'marcos.vinicius', 'Renata, eu fiquei porque queria ficar. E porque no km 38, quando suas pernas param, é a cabeça que decide. A sua decidiu continuar. Eu só fiz companhia.', 3),
    ('P54', 'camila.santos', 'Fer, sexta às 17h achei que ninguém ia ver. Obrigada por celebrar isso. Deu sentido.', 6),
    ('P55', 'edson.pereira', 'Antônio, ônibus eu já dirigi a vida toda. Não ia deixar o senhor pegar um. Café no fim foi bônus.', 8),
    ('P56', 'lucas.ferreira', 'Carlos, eu li isso umas 5 vezes. ''Virar desnecessário''. É isso. Obrigado por tudo, cara. De verdade.', 2),
    ('P57', 'jorge.ribeiro', 'Lúcia, vou voltar a passar buzinando, prometo. A senhora me faz lembrar que ainda sou parte daí.', 7),
    ('P58', 'camila.santos', 'Diego, testar como gente é melhor do que testar como QA mesmo. A gente desiste de coisas todo dia. Era pra você saber.', 7),
    ('P59', 'patricia.nunes', 'Van, conversar com você é remédio. A gente nunca sabe se a corrida foi pelos km ou pelo papo. Bora repetir.', 6),
    ('P60', 'vanessa.martins', 'Ricardo, discordar de você é seguro. É isso que faz a equipe funcionar. Obrigada por aceitar a discussão.', 7),
    ('P61', 'jorge.ribeiro', 'Helena, café com a senhora vale mais que dinheiro. Pode chamar quando precisar de qualquer outra coisa. ☕', 6),
    ('P62', 'renata.campos', 'Thiago, errei mesmo. E queria que vocês soubessem. Saúde organizacional começa no líder admitir.', 7),
    ('P63', 'camila.santos', 'Ana, ficar foi fácil. Difícil é a gente saber quando NÃO falar. Pratiquei muito pra aprender.', 6),
    ('P64', 'ricardo.alves', 'Lucas, eu pergunto no Stack Overflow porque o Google é meu chefe. Curiosidade é vitamina, não só ferramenta. ✨', 5),
    ('P65', 'dona.lucia', 'Jorge, a foto é pra você se lembrar do cheiro de casa. Fica longe quanto quiser, mas não fica de longe. ❤️', 5),
    ('P67', 'thiago.costa', 'Senhor Edson, meus pais vão amar saber que o senhor reparou. Educação se aprende ouvindo gente como o senhor.', 7),
    ('P68', 'fernanda.lima', 'Cami, dado é gente. Sempre foi. Que bom que tô conseguindo contar a história certa.', 7),
    ('P69', 'seu.antonio', 'Pedro, faca afia com pedra mas amizade afia com tempo. A gente afiou as duas naquela tarde. 🪵', 12),
    ('P70', 'fernanda.lima', 'Renata, onboarding caótico me incomodava. Ninguém merece chegar sem mapa. Ainda tem coisa pra documentar, mas começou.', 6)
) AS fb(post_str_id, username, feedback_content, delay_hours)
JOIN _seed_post_map m ON m.str_id = fb.post_str_id;

DO $$ BEGIN RAISE NOTICE 'FASE 14 concluída: feedbacks inseridos.'; END $$;

-- ============================================================
-- FASE 15: Reabilitar os 8 triggers de notificação
-- ============================================================
ALTER TABLE public.posts ENABLE TRIGGER holofote_notification_trigger;
ALTER TABLE public.reactions ENABLE TRIGGER reaction_notification_simple_trigger;
ALTER TABLE public.comments ENABLE TRIGGER comment_notification_correto_trigger;
ALTER TABLE public.feedbacks ENABLE TRIGGER feedback_notification_correto_trigger;
ALTER TABLE public.follows ENABLE TRIGGER follow_notification_correto_trigger;
ALTER TABLE public.user_points ENABLE TRIGGER level_up_notification_trigger;
ALTER TABLE public.user_badges ENABLE TRIGGER badge_notify_only_trigger;
ALTER TABLE public.user_streaks ENABLE TRIGGER streak_notify_only_trigger;

DO $$ BEGIN RAISE NOTICE 'FASE 15 concluída: triggers reabilitados.'; END $$;

-- ============================================================
-- FASE 16: Limpar notificações residuais de gamificação
-- ============================================================
DELETE FROM public.notifications
WHERE created_at >= '2026-03-16'
  AND user_id != (SELECT id FROM auth.users WHERE email = 'guilherme.dutra@b11c.com');

DO $$ BEGIN RAISE NOTICE 'FASE 16 concluída: notificações residuais limpas.'; END $$;

COMMIT;

-- ============================================================
-- SEED v8 CONCLUÍDO
-- Execute o arquivo VALIDACAO.sql para confirmar os resultados
-- ============================================================