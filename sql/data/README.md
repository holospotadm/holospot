# 📊 DADOS INICIAIS

## 📋 **ARQUIVOS**

- **badges_real.sql** - Estrutura para dados reais dos badges
- **levels_real.sql** - Estrutura para dados reais dos levels

## 🔍 **PARA EXTRAIR DADOS REAIS**

Execute no Supabase:

```sql
-- Badges reais
SELECT id, name, description, icon, color, criteria, points_bonus, created_at, updated_at
FROM badges 
ORDER BY id;

-- Levels reais
SELECT id, name, min_points, color, benefits, created_at, updated_at
FROM levels 
ORDER BY id;
```

## 📈 **DADOS DE CONFIGURAÇÃO**

- **badges** - Sistema de conquistas
- **levels** - Níveis de gamificação

## 🎯 **DADOS OPERACIONAIS**

Para backup completo dos dados:

```sql
-- Exportar todos os dados
pg_dump --data-only --table=badges --table=levels nome_do_banco
```
