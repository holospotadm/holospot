#!/usr/bin/env python3
"""
Fix: popular community_id nos posts da chain Memórias Vivas.

Diagnóstico:
- A função get_community_feed busca posts por WHERE p.community_id = p_community_id
- Os 3 posts da chain MV têm community_id = NULL (comunidade não existia quando o seed rodou)
- Fix: UPDATE posts SET community_id = (id da comunidade memorias-vivas) WHERE chain_id IN (chains com is_memorias_vivas = true)
"""

import os
import json
import requests

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json"
}

def exec_sql(sql):
    resp = requests.post(
        f"{SUPABASE_URL}/rest/v1/rpc/exec_sql_query",
        headers=headers,
        json={"sql_text": sql}
    )
    return resp.json()

def main():
    print("=== Fix: community_id nos posts da chain Memórias Vivas ===\n")

    # Passo 1: Verificar estado atual
    print("1. Estado atual dos posts da chain MV:")
    result = exec_sql("""
        SELECT p.id, p.community_id, p.chain_id, LEFT(p.content, 60) as content
        FROM posts p
        WHERE p.chain_id IN (SELECT id FROM chains WHERE is_memorias_vivas = true)
    """)
    for row in result.get("rows", []):
        print(f"   - Post {row['id'][:8]}... | community_id: {row['community_id']} | chain_id: {row['chain_id'][:8]}...")
    print()

    # Passo 2: Verificar ID da comunidade MV
    print("2. ID da comunidade Memórias Vivas:")
    result = exec_sql("SELECT id, name, slug FROM communities WHERE slug = 'memorias-vivas'")
    mv_id = None
    for row in result.get("rows", []):
        mv_id = row['id']
        print(f"   - ID: {mv_id} | Name: {row['name']} | Slug: {row['slug']}")
    print()

    if not mv_id:
        print("❌ Comunidade memorias-vivas não encontrada! Abortando.")
        return

    # Passo 3: Executar UPDATE
    print("3. Executando UPDATE...")
    update_sql = f"""
        UPDATE posts
        SET community_id = '{mv_id}'
        WHERE chain_id IN (SELECT id FROM chains WHERE is_memorias_vivas = true)
        AND community_id IS NULL
    """
    result = exec_sql(update_sql)
    if result.get("success"):
        print(f"   ✅ UPDATE executado com sucesso! Rows afetadas: {result.get('row_count', '?')}")
    else:
        print(f"   ❌ Erro no UPDATE: {result}")
    print()

    # Passo 4: Validação
    print("4. Validação pós-UPDATE:")
    result = exec_sql("""
        SELECT p.id, p.community_id, c.name as community_name
        FROM posts p
        LEFT JOIN communities c ON c.id = p.community_id
        WHERE p.chain_id IN (SELECT id FROM chains WHERE is_memorias_vivas = true)
    """)
    all_ok = True
    for row in result.get("rows", []):
        ok = row['community_id'] == mv_id
        status = "✅" if ok else "❌"
        print(f"   {status} Post {row['id'][:8]}... | community_id: {row['community_id']} | community: {row['community_name']}")
        if not ok:
            all_ok = False
    print()

    # Passo 5: Testar get_community_feed
    print("5. Testando get_community_feed com o ID da comunidade MV:")
    result = exec_sql(f"""
        SELECT COUNT(*) as total FROM posts WHERE community_id = '{mv_id}'
    """)
    total = result.get("rows", [{}])[0].get("total", 0)
    print(f"   Posts com community_id = MV: {total}")
    print()

    if all_ok:
        print("✅ FIX CONCLUÍDO — Feed Memórias Vivas deve estar populado agora.")
    else:
        print("⚠️ Alguns posts ainda sem community_id correto. Verificar manualmente.")

if __name__ == "__main__":
    main()
