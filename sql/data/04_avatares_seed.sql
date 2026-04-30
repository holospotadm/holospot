-- ============================================================================
-- ARQUIVO: 04_avatares_seed.sql
-- Data: 2026-04-30
-- Autor: Manus (executor) | Claude (briefing) | Gui Dutra (PO)
-- Referência: HOLOSPOT_briefing_avatares_seed.md
-- ============================================================================
--
-- Propósito: Preencher a coluna avatar_url nos 20 perfis seed da rede HoloSpot.
--
-- Contexto:
--   Os 20 perfis seed foram criados com avatar_url = NULL, exibindo placeholder
--   colorido no app. As fotos foram geradas via Gemini Nano Banana Pro, revisadas
--   pelo Claude e aprovadas pelo Gui. Foram redimensionadas de 1024x1024 PNG para
--   512x512 JPEG (qualidade 90), redução de ~90% no peso.
--
-- Storage:
--   Bucket: avatars
--   Prefixo: seed/
--   URL base: https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/
--   Upload realizado via API REST do Supabase com service_role_key (upsert=true).
--   Acesso público confirmado (HTTP 200 em amostras ana-beatriz.jpg e vanessa-martins.jpg).
--
-- Garantia: O perfil do Gui (guilherme.dutra) NÃO é afetado por este script.
--           Cada UPDATE filtra por username explícito de um dos 20 perfis seed.
--
-- Status: EXECUTADO com sucesso em 2026-04-30 via exec_sql (SECURITY DEFINER).
--         Validação: 20/20 perfis com avatar_url preenchido confirmado.
-- ============================================================================

-- Atualização dos avatares dos perfis seed
-- Não toca no perfil do Gui (guilherme.dutra) por design

UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/ana-beatriz.jpg' WHERE username = 'ana.beatriz';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/camila-santos.jpg' WHERE username = 'camila.santos';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/carlos-henrique.jpg' WHERE username = 'carlos.henrique';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/diego-design.jpg' WHERE username = 'diego.design';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/dona-lucia.jpg' WHERE username = 'dona.lucia';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/edson-pereira.jpg' WHERE username = 'edson.pereira';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/fernanda-lima.jpg' WHERE username = 'fernanda.lima';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/jorge-ribeiro.jpg' WHERE username = 'jorge.ribeiro';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/ju-rocha.jpg' WHERE username = 'ju.rocha';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/lucas-ferreira.jpg' WHERE username = 'lucas.ferreira';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/marcos-vinicius.jpg' WHERE username = 'marcos.vinicius';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/maria-helena.jpg' WHERE username = 'maria.helena';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/patricia-nunes.jpg' WHERE username = 'patricia.nunes';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/pedro-augusto.jpg' WHERE username = 'pedro.augusto';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/rafael-mendes.jpg' WHERE username = 'rafael.mendes';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/renata-campos.jpg' WHERE username = 'renata.campos';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/ricardo-alves.jpg' WHERE username = 'ricardo.alves';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/seu-antonio.jpg' WHERE username = 'seu.antonio';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/thiago-costa.jpg' WHERE username = 'thiago.costa';
UPDATE public.profiles SET avatar_url = 'https://dwcmrbrhyuflhtymbhll.supabase.co/storage/v1/object/public/avatars/seed/vanessa-martins.jpg' WHERE username = 'vanessa.martins';

-- Validação pós-execução
-- Resultado esperado: 20 linhas, todas com avatar_url preenchido com URL seed/
SELECT username, avatar_url
FROM public.profiles
WHERE username IN (
  'ana.beatriz', 'camila.santos', 'carlos.henrique', 'diego.design',
  'dona.lucia', 'edson.pereira', 'fernanda.lima', 'jorge.ribeiro',
  'ju.rocha', 'lucas.ferreira', 'marcos.vinicius', 'maria.helena',
  'patricia.nunes', 'pedro.augusto', 'rafael.mendes', 'renata.campos',
  'ricardo.alves', 'seu.antonio', 'thiago.costa', 'vanessa.martins'
)
ORDER BY username;

-- Verificar que o Gui não foi tocado
-- Resultado esperado: avatar_url do Gui intacto (URL do Google)
SELECT username, avatar_url FROM public.profiles WHERE username = 'guilherme.dutra';
