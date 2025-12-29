-- ============================================================================
-- FUNÇÃO: extrair_estado_completo_banco
-- ============================================================================

CREATE OR REPLACE FUNCTION public.extrair_estado_completo_banco()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    resultado TEXT := '';
    rec RECORD;
    contador INTEGER;
BEGIN
    -- Cabeçalho
    resultado := resultado || E'============================================================================\n';
    resultado := resultado || E'EXTRAÇÃO COMPLETA DO BANCO HOLOSPOT - ' || now()::text || E'\n';
    resultado := resultado || E'============================================================================\n\n';
    
    -- 1. ESTATÍSTICAS GERAIS
    resultado := resultado || E'1. ESTATÍSTICAS GERAIS\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador FROM pg_stat_user_tables WHERE schemaname = 'public';
    resultado := resultado || 'TOTAL TABELAS: ' || contador || E'\n';
    
    SELECT COUNT(*) INTO contador FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prokind = 'f';
    resultado := resultado || 'TOTAL FUNÇÕES: ' || contador || E'\n';
    
    SELECT COUNT(*) INTO contador FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND NOT t.tgisinternal;
    resultado := resultado || 'TOTAL TRIGGERS: ' || contador || E'\n';
    
    resultado := resultado || E'\n';
    
    -- 2. TODAS AS TABELAS
    resultado := resultado || E'2. TODAS AS TABELAS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT relname as nome_tabela, n_tup_ins - n_tup_del as linhas
        FROM pg_stat_user_tables 
        WHERE schemaname = 'public' 
        ORDER BY relname
    LOOP
        resultado := resultado || 'TABELA: ' || rec.nome_tabela || ' | LINHAS: ' || COALESCE(rec.linhas, 0) || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 3. TODAS AS FUNÇÕES (LISTA)
    resultado := resultado || E'3. TODAS AS FUNÇÕES (LISTA)\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname, l.lanname, 
               CASE p.prosecdef WHEN true THEN 'DEFINER' ELSE 'INVOKER' END as seguranca
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        JOIN pg_language l ON p.prolang = l.oid
        WHERE n.nspname = 'public' AND p.prokind = 'f'
        ORDER BY p.proname
    LOOP
        resultado := resultado || 'FUNÇÃO: ' || rec.proname || ' | LINGUAGEM: ' || rec.lanname || ' | SEGURANÇA: ' || rec.seguranca || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 4. TODAS AS TRIGGERS (LISTA)
    resultado := resultado || E'4. TODAS AS TRIGGERS (LISTA)\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT t.tgname, c.relname as tabela, p.proname as funcao,
               CASE t.tgenabled WHEN 'O' THEN 'ENABLED' WHEN 'D' THEN 'DISABLED' ELSE 'OTHER' END as status
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        ORDER BY c.relname, t.tgname
    LOOP
        resultado := resultado || 'TRIGGER: ' || rec.tgname || ' | TABELA: ' || rec.tabela || ' | FUNÇÃO: ' || rec.funcao || ' | STATUS: ' || rec.status || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 5. CÓDIGO FONTE DE TODAS AS FUNÇÕES
    resultado := resultado || E'5. CÓDIGO FONTE DE TODAS AS FUNÇÕES\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname, pg_get_functiondef(p.oid) as definicao
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.prokind = 'f'
        ORDER BY p.proname
    LOOP
        resultado := resultado || E'\n-- FUNÇÃO: ' || rec.proname || E'\n';
        resultado := resultado || E'-- ============================================================================\n';
        resultado := resultado || rec.definicao || E';\n\n';
    END LOOP;
    
    -- 6. DEFINIÇÃO DE TODAS AS TRIGGERS
    resultado := resultado || E'6. DEFINIÇÃO DE TODAS AS TRIGGERS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT t.tgname, pg_get_triggerdef(t.oid) as definicao
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        ORDER BY t.tgname
    LOOP
        resultado := resultado || E'\n-- TRIGGER: ' || rec.tgname || E'\n';
        resultado := resultado || E'-- ============================================================================\n';
        resultado := resultado || rec.definicao || E';\n\n';
    END LOOP;
    
    -- 7. TRIGGERS POR TABELA
    resultado := resultado || E'7. TRIGGERS POR TABELA\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT c.relname as tabela, COUNT(*) as total_triggers, 
               string_agg(t.tgname, ', ' ORDER BY t.tgname) as lista_triggers
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        GROUP BY c.relname
        ORDER BY c.relname
    LOOP
        resultado := resultado || 'TABELA: ' || rec.tabela || ' | TRIGGERS: ' || rec.total_triggers || ' | LISTA: ' || rec.lista_triggers || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 8. FUNÇÕES USADAS POR TRIGGERS
    resultado := resultado || E'8. FUNÇÕES USADAS POR TRIGGERS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname as funcao, COUNT(*) as usado_por_triggers,
               string_agg(t.tgname, ', ' ORDER BY t.tgname) as lista_triggers
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        GROUP BY p.proname
        ORDER BY COUNT(*) DESC, p.proname
    LOOP
        resultado := resultado || 'FUNÇÃO: ' || rec.funcao || ' | USADA POR: ' || rec.usado_por_triggers || ' triggers | TRIGGERS: ' || rec.lista_triggers || E'\n';
    END LOOP;
    
    -- 9. VERIFICAÇÃO ESPECÍFICA: update_user_total_points
    resultado := resultado || E'\n9. VERIFICAÇÃO ESPECÍFICA: update_user_total_points\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador 
    FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'update_user_total_points';
    
    IF contador > 0 THEN
        resultado := resultado || 'FUNÇÃO update_user_total_points: EXISTE (' || contador || ' versões)' || E'\n';
        
        FOR rec IN 
            SELECT pg_get_functiondef(p.oid) as definicao
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.proname = 'update_user_total_points'
        LOOP
            resultado := resultado || E'\nCÓDIGO DA FUNÇÃO update_user_total_points:\n';
            resultado := resultado || rec.definicao || E';\n';
        END LOOP;
    ELSE
        resultado := resultado || 'FUNÇÃO update_user_total_points: NÃO EXISTE' || E'\n';
    END IF;
    
    -- 10. VERIFICAÇÃO ESPECÍFICA: level_up_notification_trigger
    resultado := resultado || E'\n10. VERIFICAÇÃO ESPECÍFICA: level_up_notification_trigger\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador 
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND t.tgname = 'level_up_notification_trigger';
    
    IF contador > 0 THEN
        resultado := resultado || 'TRIGGER level_up_notification_trigger: EXISTE' || E'\n';
        
        FOR rec IN 
            SELECT pg_get_triggerdef(t.oid) as definicao, c.relname as tabela
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'public' AND t.tgname = 'level_up_notification_trigger'
        LOOP
            resultado := resultado || 'TABELA: ' || rec.tabela || E'\n';
            resultado := resultado || 'DEFINIÇÃO: ' || rec.definicao || E'\n';
        END LOOP;
    ELSE
        resultado := resultado || 'TRIGGER level_up_notification_trigger: NÃO EXISTE' || E'\n';
    END IF;
    
    -- Rodapé
    resultado := resultado || E'\n============================================================================\n';
    resultado := resultado || E'EXTRAÇÃO COMPLETA FINALIZADA - ' || now()::text || E'\n';
    resultado := resultado || E'============================================================================\n';
    
    RETURN resultado;
END;
$function$

