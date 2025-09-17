-- ============================================================================
-- TRIGGERS DA TABELA REACTIONS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 6
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: auto_badge_check_bonus_reactions
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_reactions AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER: reaction_delete_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER reaction_delete_secure_trigger AFTER DELETE ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_delete_secure();

-- TRIGGER: reaction_insert_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER reaction_insert_secure_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_insert_secure();

-- TRIGGER: reaction_notification_simple_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER reaction_notification_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_simple();

-- TRIGGER: reaction_points_simple_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER reaction_points_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_points_simple();

-- TRIGGER: update_streak_after_reaction
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_streak_after_reaction AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

