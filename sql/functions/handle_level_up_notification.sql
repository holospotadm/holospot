-- ============================================================================
-- FUNÇÃO: handle_level_up_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_level_up_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_level_name TEXT;
    new_level_name TEXT;
    level_info RECORD;
    message_text TEXT;
BEGIN
    -- Verificar se o nível realmente mudou
    IF OLD.level_id IS DISTINCT FROM NEW.level_id THEN
        
        -- Buscar informações do novo nível
        SELECT name, color INTO level_info
        FROM public.levels 
        WHERE id = NEW.level_id;
        
        -- Buscar nome do nível anterior (se existir)
        IF OLD.level_id IS NOT NULL THEN
            SELECT name INTO old_level_name
            FROM public.levels 
            WHERE id = OLD.level_id;
        ELSE
            old_level_name := 'Iniciante';
        END IF;
        
        -- Montar mensagem de parabéns (SEM BENEFÍCIOS)
        message_text := '🎉 Parabéns! Você subiu para o nível "' || level_info.name || '"';
        
        -- Criar notificação de nível
        PERFORM create_single_notification(
            NEW.user_id,
            NULL,  -- Notificação do sistema
            'level_up',
            message_text,
            3  -- Alta prioridade
        );
        
        RAISE NOTICE 'LEVEL UP: % subiu de % (ID:%) para % (ID:%)', 
            NEW.user_id, old_level_name, OLD.level_id, level_info.name, NEW.level_id;
    END IF;
    
    RETURN NEW;
END;
$function$

