-- ============================================================================
-- TRIGGERS DA TABELA: posts
-- ============================================================================

-- Trigger: auto_badge_check_bonus_posts
CREATE TRIGGER auto_badge_check_bonus_posts AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger: holofote_notification_trigger
CREATE TRIGGER holofote_notification_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_holofote_notification();

-- Trigger: post_insert_secure_trigger
CREATE TRIGGER post_insert_secure_trigger AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_post_insert_secure();

-- Trigger: trigger_award_first_community_post_badge
CREATE TRIGGER trigger_award_first_community_post_badge AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION award_first_community_post_badge();

-- Trigger: update_streak_after_post
CREATE TRIGGER update_streak_after_post AFTER INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_user_streak_trigger();

