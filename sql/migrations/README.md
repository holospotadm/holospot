# 🔄 Migrações do Banco de Dados

Este diretório contém as migrações sequenciais do banco de dados do HoloSpot.

## 📋 **Migrações Disponíveis**

### **001_add_missing_foreign_keys.sql**
- **Data:** 2025-09-16
- **Objetivo:** Adicionar integridade referencial básica
- **Tabelas:** user_points, feedbacks
- **FKs adicionadas:** 4
- **Impacto:** Melhora integridade dos dados

### **002_add_performance_indexes.sql**
- **Data:** 2025-09-16
- **Objetivo:** Otimizar consultas frequentes
- **Tabelas:** posts, comments
- **Índices adicionados:** 4
- **Impacto:** Melhora performance significativamente

## 🚀 **Como Executar**

### **Ordem de Execução:**
1. Execute as migrações em ordem numérica
2. Sempre teste em ambiente de desenvolvimento primeiro
3. Execute em horário de baixo tráfego

### **Exemplo:**
```sql
-- 1. Executar migration 001
\i 001_add_missing_foreign_keys.sql

-- 2. Executar migration 002  
\i 002_add_performance_indexes.sql
```

## ⚠️ **Considerações Importantes**

### **Antes de Executar:**
- ✅ Fazer backup do banco
- ✅ Verificar espaço em disco disponível
- ✅ Executar em horário de baixo tráfego
- ✅ Monitorar performance durante execução

### **Durante a Execução:**
- 📊 Índices são criados com `CONCURRENTLY` (não bloqueia)
- 🔒 FKs podem bloquear temporariamente
- ⏱️ Tempo estimado: 1-5 minutos por migration

### **Após a Execução:**
- ✅ Verificar se todas as constraints foram criadas
- ✅ Monitorar uso dos novos índices
- ✅ Verificar performance das queries otimizadas

## 📊 **Monitoramento**

### **Verificar FKs criadas:**
```sql
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```

### **Verificar índices criados:**
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
```

### **Monitorar uso dos índices:**
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as "Vezes usado",
    idx_tup_read as "Tuplas lidas"
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%'
ORDER BY idx_scan DESC;
```

## 🔄 **Rollback**

Cada migration inclui comandos de rollback comentados. Para reverter:

```sql
-- Migration 002 rollback
DROP INDEX CONCURRENTLY IF EXISTS idx_posts_active_feed;
DROP INDEX CONCURRENTLY IF EXISTS idx_posts_user_active;
DROP INDEX CONCURRENTLY IF EXISTS idx_posts_mentions_active;
DROP INDEX CONCURRENTLY IF EXISTS idx_comments_by_post_ordered;

-- Migration 001 rollback
ALTER TABLE user_points DROP CONSTRAINT IF EXISTS fk_user_points_level;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_post;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_author;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_mentioned_user;
```

## 📈 **Benefícios Esperados**

### **Migration 001 - FKs:**
- ✅ Integridade referencial garantida
- ✅ Prevenção de dados órfãos
- ✅ Melhor consistência do sistema

### **Migration 002 - Índices:**
- ⚡ Feed principal 5-10x mais rápido
- ⚡ Perfil do usuário 3-5x mais rápido
- ⚡ Sistema de holofotes 5-10x mais rápido
- ⚡ Comentários 2-3x mais rápidos

## 🎯 **Próximas Migrações**

Futuras migrações podem incluir:
- Otimizações adicionais de índices
- Novos campos ou tabelas
- Melhorias de performance
- Ajustes de segurança

**Sempre seguir a numeração sequencial e documentar adequadamente!**

