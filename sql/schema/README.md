# 🏗️ SCHEMA DAS TABELAS

## 📋 **ARQUIVOS**

- **tables_definitions.sql** - Definições de todas as 14 tabelas
- **ALL_TABLES.sql** - Estrutura básica (placeholder)

## 🔍 **PARA OBTER DEFINIÇÕES COMPLETAS**

Execute no Supabase:

```sql
-- Estrutura de uma tabela específica
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'nome_da_tabela' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Constraints de uma tabela
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = (SELECT oid FROM pg_class WHERE relname = 'nome_da_tabela');
```

## 📊 **TABELAS PRINCIPAIS**

- **profiles** - Perfis dos usuários
- **posts** - Posts do sistema
- **comments** - Comentários nos posts
- **reactions** - Reações (likes, etc.)
- **feedbacks** - Sistema de feedbacks
- **follows** - Sistema de seguir usuários
- **user_points** - Pontuação dos usuários
- **user_badges** - Badges conquistados
- **user_streaks** - Streaks de engajamento
- **notifications** - Sistema de notificações
- **points_history** - Histórico de pontos
- **badges** - Definição dos badges
- **levels** - Níveis de gamificação
