# 🔒 POLÍTICAS DE SEGURANÇA (RLS)

## 📋 **ARQUIVOS**

- **rls_policies.sql** - Políticas Row Level Security

## 🔍 **PARA LISTAR POLÍTICAS ATIVAS**

Execute no Supabase:

```sql
-- Todas as políticas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Políticas de uma tabela específica
\d+ nome_da_tabela
```

## 🛡️ **TIPOS DE POLÍTICAS**

- **SELECT** - Controla quem pode ler dados
- **INSERT** - Controla quem pode inserir dados
- **UPDATE** - Controla quem pode atualizar dados
- **DELETE** - Controla quem pode deletar dados

## 👥 **ROLES PRINCIPAIS**

- **authenticated** - Usuários logados
- **anon** - Usuários anônimos
- **service_role** - Operações do sistema
