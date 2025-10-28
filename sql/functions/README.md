# SQL Functions

## 📁 Estrutura

Este diretório contém **APENAS** o arquivo `ALL_FUNCTIONS.sql`, que é a **fonte única de verdade** para todas as funções SQL do HoloSpot.

### Arquivo Principal

- **`ALL_FUNCTIONS.sql`** - Contém todas as 117 funções SQL do sistema

## 🚫 NÃO Criar Arquivos Individuais

**Todas as novas funções devem ser adicionadas ao `ALL_FUNCTIONS.sql`.**

Não crie arquivos `.sql` individuais para funções. Isso evita:
- ❌ Duplicação de código
- ❌ Inconsistências entre arquivos
- ❌ Dificuldade de manutenção
- ❌ Confusão sobre qual versão está implementada

## ✅ Como Adicionar Nova Função

1. Abra `ALL_FUNCTIONS.sql`
2. Vá para o final do arquivo
3. Adicione sua função seguindo o padrão:

```sql

-- FUNÇÃO: nome_da_funcao
-- ============================================================================

CREATE OR REPLACE FUNCTION public.nome_da_funcao(...)
...
$function$
;

COMMENT ON FUNCTION public.nome_da_funcao IS 
'Descrição da função';
```

4. Commit e push
5. Execute no Supabase SQL Editor

## 📊 Funções Disponíveis

Total: **117 funções** (incluindo `get_feed_posts`)

Para ver a lista completa, consulte o arquivo `ALL_FUNCTIONS.sql`.

## 🔄 Histórico

- **v6.0-stable**: Reorganização completa - todas as funções consolidadas em ALL_FUNCTIONS.sql
- Arquivos individuais removidos para manter consistência
