-- ============================================================================
-- FUNÇÕES DE UTILITY - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de funções: 2
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- FUNÇÃO: count_user_referrals
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.count_user_referrals(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.user_referrals
        WHERE referrer_id = p_user_id
        AND is_active = true
    );
END;
$function$
;

-- FUNÇÃO: extrair_estado_completo_banco
-- ============================================================================

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
    
    --

