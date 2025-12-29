-- ============================================================================
-- FUNÇÃO: extrair_sistema_streak_completo
-- ============================================================================

CREATE OR REPLACE FUNCTION public.extrair_sistema_streak_completo()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    resultado TEXT := '';
    func_record RECORD;
    col_record RECORD;
    call_record RECORD;
    trigger_record RECORD;
    data_record RECORD;
    query_text TEXT;
BEGIN
    resultado := resultado || E'============================================================================\n';
    resultado := resultado || 'EXTRAÇÃO COMPLETA DO SISTEMA DE STREAK - ' || NOW() || E'\n';
    resultado := resultado || E'============================================================================\n\n';

    -- 1. ESTRUTURA DA TABELA user_streaks
    resultado := resultado || E'1. ESTRUTURA DA TABELA user_streaks\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR col_record IN 
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_streaks'
        ORDER BY ordinal_position
    LOOP
        resultado := resultado || 'COLUNA: ' || col_record.column_name || 
                    ' | TIPO: ' || col_record.data_type || 
                    ' | NULLABLE: ' || col_record.is_nullable || 
                    ' | DEFAULT: ' || COALESCE(col_record.column_default, 'NULL') || E'\n';
    END LOOP;

    -- 2. DADOS ATUAIS DA TABELA user_streaks (usando apenas colunas que existem)
    resultado := resultado || E'\n2. DADOS ATUAIS DA TABELA user_streaks\n';
    resultado := resultado || E'============================================================================\n';
    
    -- Construir query dinamicamente baseado nas colunas que existem
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) INTO query_text
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'user_streaks';
    
    IF query_text IS NOT NULL THEN
        -- Usar updated_at para ordenação se existir, senão usar primeira coluna
        FOR data_record IN 
            EXECUTE 'SELECT ' || query_text || ' FROM user_streaks ORDER BY updated_at DESC LIMIT 10'
        LOOP
            resultado := resultado || 'DADOS: ' || data_record::text || E'\n';
        END LOOP;
    ELSE
        resultado := resultado || 'TABELA user_streaks VAZIA OU NÃO EXISTE' || E'\n';
    END IF;

    -- 3. TRIGGERS RELACIONADOS A STREAK
    resultado := resultado || E'\n3. TRIGGERS RELACIONADOS A STREAK\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR trigger_record IN 
        SELECT t.tgname, c.relname, p.proname,
               CASE 
                   WHEN t.tgtype & 2 = 2 THEN 'BEFORE'
                   ELSE 'AFTER'
               END ||
               CASE 
                   WHEN t.tgtype & 4 = 4 THEN ' INSERT'
                   ELSE ''
               END ||
               CASE 
                   WHEN t.tgtype & 8 = 8 THEN ' DELETE'
                   ELSE ''
               END ||
               CASE 
                   WHEN t.tgtype & 16 = 16 THEN ' UPDATE'
                   ELSE ''
               END as timing,
               CASE t.tgenabled
                   WHEN 'O' THEN 'ENABLED'
                   WHEN 'D' THEN 'DISABLED'
                   ELSE 'OTHER'
               END as status
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE n.nspname = 'public'
        AND (
            t.tgname LIKE '%streak%' OR
            p.proname LIKE '%streak%' OR
            c.relname = 'user_streaks'
        )
        AND NOT t.tgisinternal
        ORDER BY c.relname, t.tgname
    LOOP
        resultado := resultado || 'TRIGGER: ' || trigger_record.tgname || 
                    ' | TABELA: ' || trigger_record.relname || 
                    ' | FUNÇÃO: ' || trigger_record.proname || 
                    ' | TIMING: ' || trigger_record.timing || 
                    ' | STATUS: ' || trigger_record.status || E'\n';
    END LOOP;

    -- 4. FUNÇÕES QUE CHAMAM OUTRAS FUNÇÕES DE STREAK
    resultado := resultado || E'\n4. FUNÇÕES QUE CHAMAM OUTRAS FUNÇÕES DE STREAK\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR call_record IN 
        SELECT proname,
               CASE 
                   WHEN prosrc LIKE '%update_user_streak%' THEN 'update_user_streak'
                   WHEN prosrc LIKE '%calculate_user_streak%' THEN 'calculate_user_streak'
                   WHEN prosrc LIKE '%calculate_consecutive_days%' THEN 'calculate_consecutive_days'
                   WHEN prosrc LIKE '%notify_streak_milestone%' THEN 'notify_streak_milestone'
                   ELSE 'outras_funcoes_streak'
               END as calls_function
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND (
            prosrc LIKE '%update_user_streak%' OR
            prosrc LIKE '%calculate_user_streak%' OR
            prosrc LIKE '%calculate_consecutive_days%' OR
            prosrc LIKE '%notify_streak_milestone%'
        )
        ORDER BY proname
    LOOP
        resultado := resultado || 'FUNÇÃO: ' || call_record.proname || 
                    ' | CHAMA: ' || call_record.calls_function || E'\n';
    END LOOP;

    -- 5. CÓDIGO DAS FUNÇÕES DE STREAK
    resultado := resultado || E'\n5. CÓDIGO DAS FUNÇÕES DE STREAK\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR func_record IN 
        SELECT proname, pg_get_functiondef(p.oid) as codigo
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' 
        AND (
            p.proname LIKE '%streak%' OR
            p.proname LIKE '%consecutive%'
        )
        ORDER BY p.proname
    LOOP
        resultado := resultado || E'\n-- FUNÇÃO: ' || func_record.proname || E'\n';
        resultado := resultado || E'-- ============================================================================\n';
        resultado := resultado || func_record.codigo || E'\n\n';
    END LOOP;

    -- 6. VERIFICAÇÃO DE ATIVIDADES RECENTES
    resultado := resultado || E'6. ATIVIDADES RECENTES (ÚLTIMOS 7 DIAS)\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR data_record IN 
        SELECT user_id, action_type, DATE(created_at) as data_atividade, COUNT(*) as total_acoes
        FROM points_history 
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY user_id, action_type, DATE(created_at)
        ORDER BY data_atividade DESC, user_id
        LIMIT 20
    LOOP
        resultado := resultado || 'USER: ' || data_record.user_id || 
                    ' | AÇÃO: ' || data_record.action_type || 
                    ' | DATA: ' || data_record.data_atividade || 
                    ' | TOTAL: ' || data_record.total_acoes || E'\n';
    END LOOP;

    -- 7. NOTIFICAÇÕES DE STREAK
    resultado := resultado || E'\n7. NOTIFICAÇÕES DE STREAK RECENTES\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR data_record IN 
        SELECT user_id, type, message, created_at
        FROM notifications 
        WHERE (type LIKE '%streak%' OR message LIKE '%consecutiv%' OR message LIKE '%streak%')
        ORDER BY created_at DESC
        LIMIT 10
    LOOP
        resultado := resultado || 'USER: ' || data_record.user_id || 
                    ' | TIPO: ' || data_record.type || 
                    ' | MENSAGEM: ' || SUBSTRING(data_record.message, 1, 50) || '...' ||
                    ' | DATA: ' || data_record.created_at || E'\n';
    END LOOP;

    -- 8. VERIFICAR SE HÁ TRIGGERS EM TABELAS DE ATIVIDADE QUE ATUALIZAM STREAK
    resultado := resultado || E'\n8. TRIGGERS EM TABELAS DE ATIVIDADE QUE PODEM AFETAR STREAK\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR trigger_record IN 
        SELECT t.tgname, c.relname, p.proname,
               CASE t.tgenabled
                   WHEN 'O' THEN 'ENABLED'
                   WHEN 'D' THEN 'DISABLED'
                   ELSE 'OTHER'
               END as status,
               CASE 
                   WHEN p.prosrc LIKE '%streak%' THEN 'SIM - contém código de streak'
                   WHEN c.relname IN ('posts', 'comments', 'reactions', 'feedbacks') THEN 'POSSÍVEL - tabela de atividade'
                   ELSE 'NÃO'
               END as afeta_streak
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE n.nspname = 'public'
        AND c.relname IN ('posts', 'comments', 'reactions', 'feedbacks')
        AND NOT t.tgisinternal
        ORDER BY c.relname, t.tgname
    LOOP
        resultado := resultado || 'TRIGGER: ' || trigger_record.tgname || 
                    ' | TABELA: ' || trigger_record.relname || 
                    ' | FUNÇÃO: ' || trigger_record.proname || 
                    ' | STATUS: ' || trigger_record.status || 
                    ' | AFETA_STREAK: ' || trigger_record.afeta_streak || E'\n';
    END LOOP;

    -- 9. RESUMO FINAL
    resultado := resultado || E'\n9. RESUMO FINAL\n';
    resultado := resultado || E'============================================================================\n';
    
    -- Contar funções de streak
    SELECT COUNT(*) INTO data_record FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
    AND (p.proname LIKE '%streak%' OR p.proname LIKE '%consecutive%');
    
    resultado := resultado || 'TOTAL FUNÇÕES DE STREAK: ' || data_record || E'\n';
    
    -- Contar triggers de streak
    SELECT COUNT(*) INTO data_record FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_proc p ON t.tgfoid = p.oid
    WHERE n.nspname = 'public'
    AND (t.tgname LIKE '%streak%' OR p.proname LIKE '%streak%')
    AND NOT t.tgisinternal;
    
    resultado := resultado || 'TOTAL TRIGGERS DE STREAK: ' || data_record || E'\n';
    
    -- Contar usuários com streak
    SELECT COUNT(*) INTO data_record FROM user_streaks;
    resultado := resultado || 'TOTAL USUÁRIOS COM STREAK: ' || data_record || E'\n';

    resultado := resultado || E'\n============================================================================\n';
    resultado := resultado || 'EXTRAÇÃO DO SISTEMA DE STREAK FINALIZADA - ' || NOW() || E'\n';
    resultado := resultado || E'============================================================================\n';

    RETURN resultado;
END;
$function$

