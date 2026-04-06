#!/bin/bash
# ============================================================================
# HoloSpot - Setup Automático do Ambiente
# 
# Este script configura TUDO que o agente precisa para trabalhar no HoloSpot.
# Deve ser executado no início de qualquer task que envolva o HoloSpot.
#
# Uso: source /home/ubuntu/projects/gui-dutra-53b39ed1/HOLOSPOT_setup.sh
# ============================================================================

set -e

PROJECT_DIR="/home/ubuntu/projects/gui-dutra-53b39ed1"
ENV_FILE="${PROJECT_DIR}/HOLOSPOT_credentials.env"
REPO_DIR="/home/ubuntu/holospot"

echo "=========================================="
echo "HoloSpot - Setup do Ambiente"
echo "=========================================="

# 1. Carregar variáveis de ambiente
echo "[1/6] Carregando credenciais..."
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    export SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY SUPABASE_PROJECT_REF
    export SUPABASE_DB_PASSWORD SUPABASE_DB_CONNECTION_STRING
    export VERCEL_TOKEN VERCEL_PROJECT_ID
    export HOLOSPOT_GITHUB_USER HOLOSPOT_GITHUB_REPO
    echo "  OK - Credenciais carregadas"
else
    echo "  ERRO - Arquivo de credenciais não encontrado: $ENV_FILE"
    return 1 2>/dev/null || exit 1
fi

# 2. Garantir que .bashrc carrega as variáveis automaticamente
if ! grep -q 'HOLOSPOT_credentials.env' /home/ubuntu/.bashrc 2>/dev/null; then
    echo "" >> /home/ubuntu/.bashrc
    echo "# HoloSpot Environment (auto-configurado)" >> /home/ubuntu/.bashrc
    echo "[ -f ${ENV_FILE} ] && { set -a; source ${ENV_FILE}; set +a; }" >> /home/ubuntu/.bashrc
    echo "  OK - .bashrc atualizado"
else
    echo "  OK - .bashrc já configurado"
fi

# 3. Clonar/atualizar repositório
echo "[2/6] Configurando repositório GitHub..."
if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    git pull origin main --quiet 2>/dev/null && echo "  OK - Repositório atualizado" || echo "  AVISO - Pull falhou, usando versão local"
else
    gh repo clone holospotadm/holospot "$REPO_DIR" 2>/dev/null && echo "  OK - Repositório clonado" || echo "  AVISO - Clone falhou"
fi

# 4. Instalar dependências Python
echo "[3/6] Verificando dependências..."
python3 -c "import psycopg2" 2>/dev/null || {
    sudo pip3 install psycopg2-binary --quiet 2>/dev/null
    echo "  Instalado: psycopg2"
}
echo "  OK - Dependências verificadas"

# 5. Instalar utilitário Python para exec_sql
echo "[4/6] Instalando utilitário holospot_db..."
cat > /home/ubuntu/holospot_db.py << 'PYEOF'
"""
HoloSpot DB Utility — Executa SQL arbitrário no Supabase via REST API.

Uso:
    from holospot_db import exec_sql, exec_query

    exec_sql("CREATE OR REPLACE FUNCTION ...")   # DDL/DML (retorna success/error)
    exec_query("SELECT * FROM profiles LIMIT 5") # SELECT (retorna rows)
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
    """Executa DDL/DML (CREATE, ALTER, DROP, INSERT, UPDATE, DELETE). Retorna dict com success/error."""
    return _call_rpc('exec_sql', {'sql_text': sql_text})

def exec_query(sql_text):
    """Executa SELECT e retorna rows como lista de dicts."""
    result = _call_rpc('exec_sql_query', {'sql_text': sql_text})
    if result.get('success'):
        return result.get('rows', [])
    else:
        raise Exception(f"Query failed: {result.get('error')}")

def exec_query_raw(sql_text):
    """Executa SELECT e retorna o dict completo (success, rows, row_count, execution_time_ms)."""
    return _call_rpc('exec_sql_query', {'sql_text': sql_text})

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        sql = ' '.join(sys.argv[1:])
        print(json.dumps(exec_sql(sql), indent=2))
    else:
        print("Uso: python3 holospot_db.py 'SQL AQUI'")
PYEOF
echo "  OK - /home/ubuntu/holospot_db.py instalado"

# 6. Testar conexões
echo "[5/6] Testando conexões..."

# Supabase REST API
SUPABASE_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
    "${SUPABASE_URL}/rest/v1/profiles?select=username&limit=1" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" 2>/dev/null)
if [ "$SUPABASE_TEST" = "200" ]; then
    echo "  OK - Supabase REST API conectada"
else
    echo "  ERRO - Supabase REST API retornou HTTP $SUPABASE_TEST"
fi

# Supabase exec_sql (DDL remoto)
EXEC_SQL_TEST=$(python3 -c "
import sys; sys.path.insert(0, '/home/ubuntu')
from holospot_db import exec_sql
r = exec_sql('SELECT 1')
print('OK' if r.get('success') else 'ERRO')
" 2>/dev/null)
if [ "$EXEC_SQL_TEST" = "OK" ]; then
    echo "  OK - Supabase exec_sql (DDL remoto) funcionando"
else
    echo "  AVISO - exec_sql não disponível (precisa criar a função no banco)"
fi

# Vercel
VERCEL_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.vercel.com/v9/projects/${VERCEL_PROJECT_ID}" \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" 2>/dev/null)
if [ "$VERCEL_TEST" = "200" ]; then
    echo "  OK - Vercel conectada"
else
    echo "  ERRO - Vercel retornou HTTP $VERCEL_TEST"
fi

# GitHub
GH_TEST=$(gh auth status 2>&1 | grep -c "Logged in" || true)
if [ "$GH_TEST" -ge 1 ]; then
    echo "  OK - GitHub conectado"
else
    echo "  AVISO - GitHub CLI pode não estar logado"
fi

echo "[6/6] Setup completo!"
echo ""
echo "=========================================="
echo "Resumo das conexões:"
echo "  Supabase REST: ${SUPABASE_URL}"
echo "  Supabase DDL:  exec_sql via RPC"
echo "  Vercel:        Projeto ${VERCEL_PROJECT_ID}"
echo "  GitHub:        ${HOLOSPOT_GITHUB_REPO}"
echo "  Repo local:    ${REPO_DIR}"
echo ""
echo "Utilitário Python: from holospot_db import exec_sql, exec_query"
echo "=========================================="
