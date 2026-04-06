"""
HoloSpot DB Utility — Executa SQL arbitrário no Supabase via REST API.

Este utilitário permite que o agente Manus execute qualquer comando SQL
(incluindo DDL: CREATE, ALTER, DROP) no banco de dados do HoloSpot
sem necessidade de acesso direto ao PostgreSQL.

Pré-requisitos:
    - Variáveis de ambiente SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY configuradas
    - Funções exec_sql e exec_sql_query criadas no banco (ver infra/exec_sql_setup.sql)

Uso:
    from holospot_db import exec_sql, exec_query

    # DDL/DML (CREATE, ALTER, DROP, INSERT, UPDATE, DELETE)
    result = exec_sql("CREATE OR REPLACE FUNCTION ...")
    # result = {"success": true, "message": "OK", "execution_time_ms": 1.23}

    # SELECT (retorna lista de dicts)
    rows = exec_query("SELECT * FROM profiles LIMIT 5")
    # rows = [{"id": "...", "name": "..."}, ...]

    # SELECT com metadados
    result = exec_query_raw("SELECT count(*) as total FROM posts")
    # result = {"success": true, "rows": [...], "row_count": 1, "execution_time_ms": 0.5}

CLI:
    python3 holospot_db.py 'SELECT 1'
"""
import os, json, urllib.request


def _get_config():
    url = os.environ.get('SUPABASE_URL', '')
    key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY', '')
    if not url or not key:
        env_file = '/home/ubuntu/projects/gui-dutra-53b39ed1/HOLOSPOT_credentials.env'
        if os.path.exists(env_file):
            with open(env_file) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        k, v = line.split('=', 1)
                        os.environ[k] = v
            url = os.environ.get('SUPABASE_URL', '')
            key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY', '')
    return url, key


def _call_rpc(func_name, params):
    url, key = _get_config()
    req = urllib.request.Request(
        f'{url}/rest/v1/rpc/{func_name}',
        data=json.dumps(params).encode(),
        headers={
            'apikey': key,
            'Authorization': f'Bearer {key}',
            'Content-Type': 'application/json'
        },
        method='POST'
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def exec_sql(sql_text):
    """Executa DDL/DML (CREATE, ALTER, DROP, INSERT, UPDATE, DELETE).
    Retorna dict com success/error."""
    return _call_rpc('exec_sql', {'sql_text': sql_text})


def exec_query(sql_text):
    """Executa SELECT e retorna rows como lista de dicts."""
    result = _call_rpc('exec_sql_query', {'sql_text': sql_text})
    if result.get('success'):
        return result.get('rows', [])
    else:
        raise Exception(f"Query failed: {result.get('error')}")


def exec_query_raw(sql_text):
    """Executa SELECT e retorna o dict completo
    (success, rows, row_count, execution_time_ms)."""
    return _call_rpc('exec_sql_query', {'sql_text': sql_text})


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        sql = ' '.join(sys.argv[1:])
        print(json.dumps(exec_sql(sql), indent=2))
    else:
        print("Uso: python3 holospot_db.py 'SQL AQUI'")
