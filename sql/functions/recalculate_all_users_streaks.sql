-- ============================================================================
-- FUNÇÃO: recalculate_all_users_streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_users_streaks()
 RETURNS TABLE(user_id uuid, username character varying, old_streak integer, new_streak integer, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user RECORD;
    v_old_streak INTEGER;
    v_new_streak INTEGER;
    v_total_users INTEGER := 0;
    v_processed_users INTEGER := 0;
    v_start_time TIMESTAMP;
BEGIN
    v_start_time := NOW();
    SELECT COUNT(*) INTO v_total_users FROM profiles;
    RAISE NOTICE '🔄 Iniciando recálculo de streaks para % usuários...', v_total_users;
    
    FOR v_user IN SELECT p.id, p.username FROM profiles p ORDER BY p.id LOOP
        v_processed_users := v_processed_users + 1;
        
        SELECT current_streak INTO v_old_streak FROM user_streaks WHERE user_streaks.user_id = v_user.id;
        IF v_old_streak IS NULL THEN v_old_streak := 0; END IF;
        
        BEGIN
            PERFORM recalculate_user_streak_from_scratch(v_user.id);
            SELECT current_streak INTO v_new_streak FROM user_streaks WHERE user_streaks.user_id = v_user.id;
            IF v_new_streak IS NULL THEN v_new_streak := 0; END IF;
            
            IF v_processed_users % 10 = 0 THEN
                RAISE NOTICE '📊 Progresso: %/% usuários processados (%.1f%%)', 
                    v_processed_users, v_total_users, (v_processed_users::FLOAT / v_total_users::FLOAT * 100);
            END IF;
            
            RETURN QUERY SELECT v_user.id, v_user.username::VARCHAR(50), v_old_streak, v_new_streak,
                CASE 
                    WHEN v_old_streak = v_new_streak THEN '✅ Sem mudança'
                    WHEN v_old_streak < v_new_streak THEN '📈 Aumentou'
                    ELSE '📉 Diminuiu'
                END::TEXT;
                
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erro ao processar usuário %: %', v_user.username, SQLERRM;
            RETURN QUERY SELECT v_user.id, v_user.username::VARCHAR(50), v_old_streak, 0::INTEGER,
                ('❌ Erro: ' || SQLERRM)::TEXT;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Recálculo completo! % usuários processados em %', v_processed_users, (NOW() - v_start_time);
END;
$function$

