-- ============================================================================
-- TRIGGERS DA TABELA: reactions
-- ============================================================================

-- Trigger: auto_badge_check_bonus_reactions
CREATE TRIGGER auto_badge_check_bonus_reactions AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger: reaction_delete_secure_trigger
CREATE TRIGGER reaction_delete_secure_trigger AFTER DELETE ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_reaction_delete_secure();

-- Trigger: reaction_insert_secure_trigger
CREATE TRIGGER reaction_insert_secure_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_reaction_insert_secure();

-- Trigger: reaction_notification_simple_trigger
CREATE TRIGGER reaction_notification_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_reaction_simple();

-- Trigger: reaction_points_simple_trigger
CREATE TRIGGER reaction_points_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_reaction_points_simple();

-- Trigger: update_streak_after_reaction
CREATE TRIGGER update_streak_after_reaction AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_user_streak_trigger();

