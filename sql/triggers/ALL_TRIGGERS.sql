-- ============================================================================
-- TODOS OS TRIGGERS DO HOLOSPOT - EXTRAÇÃO FINAL GARANTIDA
-- ============================================================================
-- Total: 29 triggers
-- Método: Extração direta do conteúdo bruto
-- Garantia: NADA foi perdido
-- ============================================================================

-- TRIGGER 1: auto_badge_check_bonus_comments
-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_comments AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER 2: auto_badge_check_bonus_feedbacks
-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_feedbacks AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER 3: auto_badge_check_bonus_posts
-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_posts AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER 4: auto_badge_check_bonus_reactions
-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_reactions AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER 5: auto_badge_check_bonus_user_points
-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_user_points AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER 6: badge_notify_only_trigger
-- ============================================================================

CREATE TRIGGER badge_notify_only_trigger AFTER INSERT ON public.user_badges FOR EACH ROW EXECUTE FUNCTION handle_badge_notification_only();

-- TRIGGER 7: comment_delete_secure_trigger
-- ============================================================================

CREATE TRIGGER comment_delete_secure_trigger AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_delete_secure();

-- TRIGGER 8: comment_insert_secure_trigger
-- ============================================================================

CREATE TRIGGER comment_insert_secure_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_insert_secure();

-- TRIGGER 9: comment_notification_correto_trigger
-- ============================================================================

CREATE TRIGGER comment_notification_correto_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_notification_correto();

-- TRIGGER 10: comment_notify_only_trigger (REMOVIDO - CAUSAVA DUPLICATAS)
-- ============================================================================
-- Este trigger foi removido pois causava notificações duplicadas
-- Mantido apenas comment_notification_correto_trigger

-- CREATE TRIGGER comment_notify_only_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_notification_only();

-- TRIGGER 11: feedback_insert_secure_trigger
-- ============================================================================

CREATE TRIGGER feedback_insert_secure_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION handle_feedback_insert_secure();

-- TRIGGER 12: feedback_notification_correto_trigger
-- ============================================================================

CREATE TRIGGER feedback_notification_correto_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION handle_feedback_notification_correto();

-- TRIGGER 13: follow_notification_correto_trigger
-- ============================================================================

CREATE TRIGGER follow_notification_correto_trigger AFTER INSERT ON public.follows FOR EACH ROW EXECUTE FUNCTION handle_follow_notification_correto();

-- TRIGGER 14: holofote_notification_trigger
-- ============================================================================

CREATE TRIGGER holofote_notification_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION handle_holofote_notification();

-- TRIGGER 15: level_up_notification_trigger
-- ============================================================================

CREATE TRIGGER level_up_notification_trigger AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION handle_level_up_notification();

-- TRIGGER 16: post_insert_secure_trigger
-- ============================================================================

CREATE TRIGGER post_insert_secure_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION handle_post_insert_secure();

-- TRIGGER 17: reaction_delete_secure_trigger
-- ============================================================================

CREATE TRIGGER reaction_delete_secure_trigger AFTER DELETE ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_delete_secure();

-- TRIGGER 18: reaction_insert_secure_trigger
-- ============================================================================

CREATE TRIGGER reaction_insert_secure_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_insert_secure();

-- TRIGGER 19: reaction_notification_simple_trigger
-- ============================================================================

CREATE TRIGGER reaction_notification_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_simple();

-- TRIGGER 20: reaction_points_simple_trigger
-- ============================================================================

CREATE TRIGGER reaction_points_simple_trigger AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION handle_reaction_points_simple();

-- TRIGGER 21: streak_notify_only_trigger
-- ============================================================================

CREATE TRIGGER streak_notify_only_trigger AFTER UPDATE ON public.user_streaks FOR EACH ROW EXECUTE FUNCTION handle_streak_notification_only();

-- TRIGGER 22: trigger_generate_username
-- ============================================================================

CREATE TRIGGER trigger_generate_username BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION generate_username_from_email();

-- TRIGGER 23: update_badges_updated_at
-- ============================================================================

CREATE TRIGGER update_badges_updated_at BEFORE UPDATE ON public.badges FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER 24: update_streak_after_comment
-- ============================================================================

CREATE TRIGGER update_streak_after_comment AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

-- TRIGGER 25: update_streak_after_feedback
-- ============================================================================

CREATE TRIGGER update_streak_after_feedback AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

-- TRIGGER 26: update_streak_after_post
-- ============================================================================

CREATE TRIGGER update_streak_after_post AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

-- TRIGGER 27: update_streak_after_reaction
-- ============================================================================

CREATE TRIGGER update_streak_after_reaction AFTER INSERT ON public.reactions FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

-- TRIGGER 28: update_user_points_updated_at
-- ============================================================================

CREATE TRIGGER update_user_points_updated_at BEFORE UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER 29: level_up_notification_trigger
-- ============================================================================

CREATE TRIGGER level_up_notification_trigger AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION handle_level_up_notification();

