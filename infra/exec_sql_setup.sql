-- ============================================================================
-- HoloSpot: Função exec_sql — Execução Remota de SQL via REST API
-- 
-- OBJETIVO: Permitir que o agente Manus execute qualquer comando SQL
-- (incluindo DDL: CREATE, ALTER, DROP) via chamada RPC da REST API,
-- eliminando a necessidade do usuário copiar/colar no SQL Editor.
--
-- SEGURANÇA:
-- 1. SECURITY DEFINER: roda com permissão do owner (postgres)
-- 2. Só acessível via service_role key (RLS não se aplica a service_role)
-- 3. Tabela de auditoria registra TUDO que é executado
-- 4. Revoke de acesso para roles públicos
--
-- EXECUÇÃO: Copie e cole este script inteiro no Supabase SQL Editor.
-- ============================================================================

-- 1. Criar tabela de auditoria
CREATE TABLE IF NOT EXISTS _exec_sql_audit (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    executed_at timestamptz DEFAULT now(),
    sql_text text NOT NULL,
    success boolean NOT NULL,
    result_message text,
    execution_time_ms numeric
);

-- Proteger a tabela de auditoria: ninguém lê/escreve via API pública
ALTER TABLE _exec_sql_audit ENABLE ROW LEVEL SECURITY;
-- Sem policies = ninguém acessa via anon/authenticated, só via service_role ou postgres

-- 2. Criar a função principal
CREATE OR REPLACE FUNCTION exec_sql(sql_text text)
RETURNS jsonb AS $$
DECLARE
    start_ts timestamptz;
    end_ts timestamptz;
    exec_time numeric;
    result_msg text;
BEGIN
    start_ts := clock_timestamp();
    
    -- Executar o SQL
    BEGIN
        EXECUTE sql_text;
        result_msg := 'OK';
        
        end_ts := clock_timestamp();
        exec_time := EXTRACT(MILLISECOND FROM (end_ts - start_ts));
        
        -- Registrar na auditoria
        INSERT INTO _exec_sql_audit (sql_text, success, result_message, execution_time_ms)
        VALUES (sql_text, true, result_msg, exec_time);
        
        RETURN jsonb_build_object(
            'success', true,
            'message', result_msg,
            'execution_time_ms', exec_time
        );
        
    EXCEPTION WHEN OTHERS THEN
        end_ts := clock_timestamp();
        exec_time := EXTRACT(MILLISECOND FROM (end_ts - start_ts));
        result_msg := SQLERRM;
        
        -- Registrar erro na auditoria
        INSERT INTO _exec_sql_audit (sql_text, success, result_message, execution_time_ms)
        VALUES (sql_text, false, result_msg, exec_time);
        
        RETURN jsonb_build_object(
            'success', false,
            'error', result_msg,
            'execution_time_ms', exec_time
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Criar função auxiliar para queries que retornam dados (SELECT)
CREATE OR REPLACE FUNCTION exec_sql_query(sql_text text)
RETURNS jsonb AS $$
DECLARE
    start_ts timestamptz;
    end_ts timestamptz;
    exec_time numeric;
    result_rows jsonb;
BEGIN
    start_ts := clock_timestamp();
    
    BEGIN
        EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' || sql_text || ') t'
        INTO result_rows;
        
        end_ts := clock_timestamp();
        exec_time := EXTRACT(MILLISECOND FROM (end_ts - start_ts));
        
        -- Registrar na auditoria
        INSERT INTO _exec_sql_audit (sql_text, success, result_message, execution_time_ms)
        VALUES (sql_text, true, 'QUERY OK - ' || COALESCE(jsonb_array_length(result_rows), 0) || ' rows', exec_time);
        
        RETURN jsonb_build_object(
            'success', true,
            'rows', COALESCE(result_rows, '[]'::jsonb),
            'row_count', COALESCE(jsonb_array_length(result_rows), 0),
            'execution_time_ms', exec_time
        );
        
    EXCEPTION WHEN OTHERS THEN
        end_ts := clock_timestamp();
        exec_time := EXTRACT(MILLISECOND FROM (end_ts - start_ts));
        
        INSERT INTO _exec_sql_audit (sql_text, success, result_message, execution_time_ms)
        VALUES (sql_text, false, SQLERRM, exec_time);
        
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'execution_time_ms', exec_time
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Revogar acesso público (só service_role e postgres podem chamar)
REVOKE ALL ON FUNCTION exec_sql(text) FROM public;
REVOKE ALL ON FUNCTION exec_sql(text) FROM anon;
REVOKE ALL ON FUNCTION exec_sql(text) FROM authenticated;

REVOKE ALL ON FUNCTION exec_sql_query(text) FROM public;
REVOKE ALL ON FUNCTION exec_sql_query(text) FROM anon;
REVOKE ALL ON FUNCTION exec_sql_query(text) FROM authenticated;

-- 5. Garantir que service_role tem acesso
GRANT EXECUTE ON FUNCTION exec_sql(text) TO service_role;
GRANT EXECUTE ON FUNCTION exec_sql_query(text) TO service_role;

-- 6. Teste rápido (deve retornar {"success": true, "message": "OK", ...})
SELECT exec_sql('SELECT 1');
SELECT exec_sql_query('SELECT current_user AS usuario, now() AS agora');
