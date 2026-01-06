-- ============================================================================
-- TRIGGERS: Memórias Vivas
-- Descrição: Triggers para verificação de badges do Memórias Vivas
-- ============================================================================

-- Trigger para posts
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_posts ON public.posts;
CREATE TRIGGER check_memorias_vivas_badges_on_posts
    AFTER INSERT ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();

-- Trigger para reactions
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_reactions ON public.reactions;
CREATE TRIGGER check_memorias_vivas_badges_on_reactions
    AFTER INSERT ON public.reactions
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();

-- Trigger para comments
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_comments ON public.comments;
CREATE TRIGGER check_memorias_vivas_badges_on_comments
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();
