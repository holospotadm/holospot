# Infraestrutura — HoloSpot

Scripts de infraestrutura para o workflow autônomo de desenvolvimento do HoloSpot.

---

## Visão Geral

A partir de abril/2026, o workflow de desenvolvimento do HoloSpot passou a ser **100% autônomo**: o agente Manus executa SQL diretamente no Supabase via REST API, sem necessidade de intervenção manual do usuário no SQL Editor.

Esta pasta contém os scripts que viabilizam esse workflow.

---

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `exec_sql_setup.sql` | Script SQL que cria as funções `exec_sql` e `exec_sql_query` no banco, além da tabela de auditoria `_exec_sql_audit`. Deve ser executado **uma única vez** no Supabase SQL Editor. |
| `holospot_db.py` | Utilitário Python que permite executar SQL arbitrário via REST API. Usado pelo agente Manus durante o desenvolvimento. |
| `manus_setup.sh` | Script de setup automático do ambiente. Carrega credenciais, clona/atualiza o repositório, instala dependências e testa todas as conexões. Deve ser executado no início de cada task. |

---

## Uso

### Setup Inicial (uma vez)

1. Executar `exec_sql_setup.sql` no Supabase SQL Editor
2. Configurar `HOLOSPOT_credentials.env` na pasta do projeto Manus

### Início de Cada Task

```bash
source /home/ubuntu/projects/gui-dutra-53b39ed1/HOLOSPOT_setup.sh
```

### Executar SQL via Python

```python
import sys; sys.path.insert(0, '/home/ubuntu')
from holospot_db import exec_sql, exec_query

# DDL/DML
exec_sql("CREATE OR REPLACE FUNCTION ...")

# SELECT
rows = exec_query("SELECT * FROM profiles LIMIT 5")
```

---

## Segurança

As funções `exec_sql` e `exec_sql_query` são protegidas por:

1. **SECURITY DEFINER**: executam com permissão do owner (postgres)
2. **REVOKE público**: roles `anon` e `authenticated` não têm acesso
3. **Somente service_role**: apenas chamadas com a chave `service_role` funcionam
4. **Auditoria completa**: toda execução é registrada na tabela `_exec_sql_audit` com timestamp, SQL executado, resultado e tempo de execução

---

## Nota sobre Credenciais

O arquivo `HOLOSPOT_credentials.env` **não está neste repositório** por segurança. Ele fica na pasta do projeto Manus (`/home/ubuntu/projects/gui-dutra-53b39ed1/`) e contém:

- Supabase URL e Service Role Key
- Supabase Database Password e Connection String
- Vercel Token e Project ID
- GitHub User e Repo

---

**Criado em:** 2026-04-06
**Última atualização:** 2026-04-06
