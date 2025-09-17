-- ============================================================================
-- TRIGGERS DA TABELA POSTS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 4
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: auto_badge_check_bonus_posts
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_posts AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER: holofote_notification_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER holofote_notification_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION handle_holofote_notification();

-- TRIGGER: post_insert_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER post_insert_secure_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION handle_post_insert_secure();

-- TRIGGER: update_streak_after_post
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_streak_after_post AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

