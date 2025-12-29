# Estrutura SQL do HoloSpot

Este diretório contém toda a estrutura do banco de dados do HoloSpot, organizada para facilitar manutenção e versionamento.

## Estrutura de Diretórios

```
sql/
├── schema/          # Definições de tabelas (CREATE TABLE)
├── functions/       # Funções PL/pgSQL (1 arquivo por função)
├── triggers/        # Triggers agrupados por tabela
├── constraints/     # Constraints agrupados por tabela
├── policies/        # Policies RLS agrupadas por tabela
└── migrations/      # Migrações incrementais
```

## Convenções de Nomenclatura

### Schema (Tabelas)
- Formato: `NN_nome_tabela.sql` (NN = número sequencial)
- Exemplo: `01_profiles.sql`, `02_posts.sql`

### Functions
- Formato: `nome_funcao.sql`
- Funções com overload: `nome_funcao_v2.sql`, `nome_funcao_v3.sql`

### Triggers
- Formato: `nome_tabela_triggers.sql`
- Contém todos os triggers de uma tabela

### Constraints
- Formato: `nome_tabela_constraints.sql`
- Contém todas as constraints de uma tabela

### Policies
- Formato: `nome_tabela_policies.sql`
- Contém todas as policies RLS de uma tabela

## Como Usar

### Aplicar Alterações
1. Faça as alterações nos arquivos SQL correspondentes
2. Execute o SQL no Supabase SQL Editor
3. Commit as alterações no GitHub

### Criar Nova Migração
1. Crie um arquivo em `migrations/` com formato `YYYYMMDD_descricao.sql`
2. Inclua apenas as alterações incrementais
3. Execute no Supabase e faça commit

## Última Atualização
Extraído do banco de dados em: 2025-12-29 08:43:29
