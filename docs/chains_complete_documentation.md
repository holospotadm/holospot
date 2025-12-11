# Documentação Completa: Sistema de Correntes

**Autor:** Manus AI  
**Data:** 03 de Dezembro de 2025  
**Versão:** 2.0 (Consolidada)

## 1. Visão Geral

Este documento descreve o plano completo para implementar o sistema de "Correntes" (Chains) na plataforma, incluindo a funcionalidade principal e o sistema de gamificação (badges e pontuação). O objetivo é permitir que usuários criem e participem de sequências de posts temáticos, incentivando o engajamento contínuo e rastreável.

O documento está dividido em duas partes principais:

**PARTE 1: IMPLEMENTAÇÃO DO SISTEMA DE CORRENTES**
1.  **Banco de Dados:** Novas tabelas para armazenar as correntes e os posts associados.
2.  **Frontend:** Alterações na interface do usuário para criar, participar e visualizar correntes.
3.  **Backend (Funções SQL):** Lógica para gerenciar o ciclo de vida das correntes.
4.  **Fluxos de Usuário:** Criador e participante.
5.  **Rastreamento e Análise:** Dados rastreáveis e consultas úteis.
6.  **Ordem de Implementação:** 6 fases sequenciais.

**PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES**
1.  **Badges:** 8 novos badges de criação e participação.
2.  **Pontuação:** Sistema de pontos para recompensar ações.
3.  **Funções SQL:** Funções de suporte para badges.
4.  **Triggers:** Automação de concessão de badges.
5.  **Ordem de Implementação:** 5 fases sequenciais.

**Nenhuma alteração será feita no código durante esta fase de planejamento.**

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

# PARTE 1: IMPLEMENTAÇÃO DO SISTEMA DE CORRENTES

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 2. Estrutura do Banco de Dados

Serão criadas duas novas tabelas para suportar o sistema de Correntes.

### a. Tabela `chains`

Esta tabela armazenará as informações principais de cada corrente criada.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `id` | `UUID` | Identificador único da corrente (Chave Primária). |
| `created_at` | `TIMESTAMPTZ` | Data e hora de criação. |
| `creator_id` | `UUID` | ID do usuário que criou a corrente (FK para `profiles.id`). |
| `name` | `TEXT` | Nome da corrente. |
| `description` | `TEXT` | Descrição da corrente (para o tooltip). |
| `highlight_type` | `TEXT` | Tipo de destaque fixo para a corrente (ex: "Apoio", "Inspiração"). |
| `is_active` | `BOOLEAN` | Indica se a corrente está ativa. Será `false` se o criador cancelar antes do primeiro post. |
| `first_post_id` | `UUID` | ID do primeiro post da corrente (FK para `posts.id`). Preenchido quando o criador posta. |

**Índices:**
- `creator_id`

### b. Tabela `chain_posts`

Esta tabela associará cada post a uma corrente e rastreará a sua origem, permitindo a reconstrução da sequência.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `id` | `UUID` | Identificador único da associação (Chave Primária). |
| `chain_id` | `UUID` | ID da corrente (FK para `chains.id`). |
| `post_id` | `UUID` | ID do post que faz parte da corrente (FK para `posts.id`). |
| `author_id` | `UUID` | ID do autor do post (FK para `profiles.id`). |
| `parent_post_author_id` | `UUID` | ID do autor do post que originou a participação (o post onde o usuário clicou em "Participar"). Será `NULL` para o criador. |
| `created_at` | `TIMESTAMPTZ` | Data e hora de criação do post na corrente. |

**Índices:**
- `chain_id`
- `post_id`
- `parent_post_author_id`

### c. Alterações na Tabela `posts`

Uma nova coluna será adicionada à tabela `posts` para facilitar a identificação de posts de corrente.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `chain_id` | `UUID` | (Opcional) ID da corrente à qual o post pertence (FK para `chains.id`). Será `NULL` se não for um post de corrente. |

**Índice:**
- `chain_id`

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 3. Alterações no Frontend

As alterações no frontend serão concentradas na aba "Destacar" e nos posts exibidos na timeline.

### a. Aba "Destacar" - Botão "Criar Corrente"

**Localização:** Canto superior direito, alinhado ao texto "Destacar Alguém".

**Estado Inicial:**
- Exibir botão: **"Criar Corrente 🔗"**

**Ao clicar no botão:**
1. Abrir modal com título: **"Criar Corrente 🔗"**
2. Campos do modal:
   - **Nome da Corrente** (input text, obrigatório)
   - **Descrição** (textarea, obrigatório)
   - **Tipo de Destaque** (select, mesmas opções da aba Destacar, obrigatório)
3. Botão: **"Criar"**

**Após criar a corrente:**
1. Fechar o modal automaticamente.
2. Voltar para a aba "Destacar".
3. Substituir o botão "Criar Corrente 🔗" por: **"Cancelar Corrente"**
4. Exibir ao lado esquerdo do botão: **"[Nome da Corrente] 🔗"**
5. Ao passar o mouse sobre o nome da corrente, exibir tooltip **em cima do mouse** com a descrição da corrente.
6. **Fixar o tipo de destaque** no tipo escolhido na criação da corrente (sem possibilidade de alterar).
7. Permitir que o usuário crie um post destacando alguém, linkado à corrente.

**Ao clicar em "Cancelar Corrente":**
1. Deletar a corrente criada (apenas se nenhum post foi criado ainda).
2. Voltar ao estado inicial (botão "Criar Corrente 🔗").

**Após criar o primeiro post:**
1. O botão "Cancelar Corrente" desaparece.
2. A corrente não pode mais ser deletada.
3. O usuário volta ao estado inicial da aba "Destacar".

### b. Posts na Timeline - Destaque de Corrente

**Exibição:**
- Ao lado do ícone de "tipo de post", exibir: **"[Nome da Corrente] 🔗"**

**Ao clicar no destaque da corrente:**
1. Abrir modal com título: **"[Nome da Corrente] 🔗"**
2. Informações exibidas:
   - **Nome da Corrente**
   - **Descrição**
   - **Tipo de Destaque**
3. Botão: **"Participar"**

**Ao clicar em "Participar":**
1. Guardar o ID do autor do post no qual o usuário clicou (para rastreamento).
2. Fechar o modal.
3. Abrir automaticamente a aba "Destacar".
4. Exibir: **"[Nome da Corrente] 🔗"** (com tooltip da descrição ao passar o mouse).
5. Exibir botão: **"Cancelar"** (não "Cancelar Corrente").
6. **Fixar o tipo de destaque** no tipo da corrente.
7. Permitir que o usuário crie um post destacando alguém, linkado à corrente.

**Ao clicar em "Cancelar":**
1. Remover destaque de corrente selecionada.
2. Remover seleção fixa do tipo de destaque.
3. Voltar ao estado inicial (botão "Criar Corrente 🔗").

**Após criar o post:**
1. Guardar o autor do post pelo qual o usuário clicou (para rastreamento da cadeia).
2. Voltar ao estado inicial da aba "Destacar".

### c. Variáveis de Estado (Frontend)

Para gerenciar o estado da corrente no frontend, serão necessárias as seguintes variáveis:

| Variável | Tipo | Descrição |
| :--- | :--- | :--- |
| `activeChain` | `Object` ou `null` | Armazena a corrente ativa (criada ou participando). Contém: `id`, `name`, `description`, `highlight_type`. |
| `isChainCreator` | `Boolean` | `true` se o usuário criou a corrente, `false` se está participando. |
| `parentPostAuthorId` | `UUID` ou `null` | ID do autor do post que originou a participação (apenas para participantes). |

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 4. Funções SQL Necessárias

Serão criadas funções SQL para gerenciar o ciclo de vida das correntes.

### a. `create_chain`

**Descrição:** Cria uma nova corrente.

**Parâmetros:**
- `p_creator_id` (UUID): ID do usuário criador.
- `p_name` (TEXT): Nome da corrente.
- `p_description` (TEXT): Descrição da corrente.
- `p_highlight_type` (TEXT): Tipo de destaque.

**Retorna:** UUID da corrente criada.

**Lógica:**
1. Inserir registro na tabela `chains` com `is_active = true` e `first_post_id = NULL`.
2. Retornar o `id` da corrente.

### b. `cancel_chain`

**Descrição:** Cancela uma corrente (apenas se nenhum post foi criado).

**Parâmetros:**
- `p_chain_id` (UUID): ID da corrente.
- `p_user_id` (UUID): ID do usuário (para validar que é o criador).

**Retorna:** BOOLEAN (sucesso ou falha).

**Lógica:**
1. Verificar se `p_user_id` é o criador da corrente.
2. Verificar se `first_post_id` é `NULL`.
3. Se sim, atualizar `is_active = false`.
4. Retornar `true` se sucesso, `false` se falha.

### c. `add_post_to_chain`

**Descrição:** Adiciona um post a uma corrente.

**Parâmetros:**
- `p_chain_id` (UUID): ID da corrente.
- `p_post_id` (UUID): ID do post criado.
- `p_author_id` (UUID): ID do autor do post.
- `p_parent_post_author_id` (UUID, opcional): ID do autor do post que originou a participação (NULL para o criador).

**Retorna:** VOID.

**Lógica:**
1. Inserir registro na tabela `chain_posts`.
2. Atualizar `posts.chain_id` com o `p_chain_id`.
3. Se `p_parent_post_author_id` for `NULL` (criador), atualizar `chains.first_post_id` com `p_post_id`.

### d. `get_chain_info`

**Descrição:** Retorna informações de uma corrente.

**Parâmetros:**
- `p_chain_id` (UUID): ID da corrente.

**Retorna:** JSON com:
- `id`
- `name`
- `description`
- `highlight_type`
- `creator_id`
- `first_post_id`
- `total_posts` (contagem de posts na corrente)

**Lógica:**
1. Buscar dados de `chains`.
2. Contar posts em `chain_posts`.
3. Retornar JSON.

### e. `get_chain_tree`

**Descrição:** Retorna a árvore de posts de uma corrente (para análise futura).

**Parâmetros:**
- `p_chain_id` (UUID): ID da corrente.

**Retorna:** JSON com a estrutura hierárquica dos posts.

**Lógica:**
1. Buscar todos os posts de `chain_posts` para a corrente.
2. Construir árvore usando `parent_post_author_id`.
3. Retornar JSON.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 5. Fluxos de Usuário

### a. Fluxo: Criador da Corrente

```
1. Usuário acessa aba "Destacar"
2. Clica em "Criar Corrente 🔗"
3. Preenche modal (Nome, Descrição, Tipo de Destaque)
4. Clica em "Criar"
5. Modal fecha, botão vira "Cancelar Corrente"
6. Nome da corrente aparece ao lado do botão (com tooltip)
7. Tipo de destaque fica fixo
8. [OPÇÃO A] Usuário clica em "Cancelar Corrente"
   → Corrente é deletada
   → Volta ao estado inicial
9. [OPÇÃO B] Usuário cria post destacando alguém
   → Post é criado e linkado à corrente
   → Corrente não pode mais ser cancelada
   → Usuário volta ao estado inicial da aba "Destacar"
```

### b. Fluxo: Participante da Corrente

```
1. Usuário vê post com destaque "[Nome da Corrente] 🔗"
2. Clica no destaque
3. Modal abre com informações da corrente
4. Clica em "Participar"
5. Modal fecha, aba "Destacar" abre automaticamente
6. Nome da corrente aparece (com tooltip)
7. Botão "Cancelar" aparece
8. Tipo de destaque fica fixo
9. [OPÇÃO A] Usuário clica em "Cancelar"
   → Corrente é removida da seleção
   → Volta ao estado inicial
10. [OPÇÃO B] Usuário cria post destacando alguém
    → Post é criado e linkado à corrente
    → ID do autor do post original é guardado
    → Usuário volta ao estado inicial da aba "Destacar"
```

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 6. Rastreamento e Análise

O sistema de correntes permitirá rastreamento completo da cadeia de participação.

### a. Dados Rastreáveis

| Dado | Descrição |
| :--- | :--- |
| **Criador** | Quem iniciou a corrente. |
| **Primeiro Post** | Post inicial da corrente. |
| **Total de Posts** | Quantos posts foram criados na corrente. |
| **Árvore de Participação** | Quem participou a partir de qual post. |
| **Profundidade da Cadeia** | Quantos níveis de participação existem. |
| **Taxa de Conversão** | Quantos usuários que viram a corrente participaram. |

### b. Consultas Úteis

**Exemplo 1: Total de posts em uma corrente**
```sql
SELECT COUNT(*) FROM chain_posts WHERE chain_id = '<chain_id>';
```

**Exemplo 2: Usuários que participaram**
```sql
SELECT DISTINCT author_id FROM chain_posts WHERE chain_id = '<chain_id>';
```

**Exemplo 3: Profundidade máxima da cadeia**
```sql
WITH RECURSIVE chain_tree AS (
  SELECT post_id, author_id, parent_post_author_id, 1 AS depth
  FROM chain_posts
  WHERE chain_id = '<chain_id>' AND parent_post_author_id IS NULL
  
  UNION ALL
  
  SELECT cp.post_id, cp.author_id, cp.parent_post_author_id, ct.depth + 1
  FROM chain_posts cp
  JOIN chain_tree ct ON cp.parent_post_author_id = ct.author_id
  WHERE cp.chain_id = '<chain_id>'
)
SELECT MAX(depth) FROM chain_tree;
```

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 7. Considerações de Implementação

### a. Validações Necessárias

**Frontend:**
- Nome da corrente: mínimo 3 caracteres, máximo 50.
- Descrição: mínimo 10 caracteres, máximo 200.
- Tipo de destaque: deve ser um dos tipos válidos.

**Backend:**
- Verificar se o usuário é o criador antes de cancelar.
- Verificar se a corrente já tem posts antes de permitir cancelamento.
- Garantir que `parent_post_author_id` seja válido (autor de um post existente na corrente).

### b. Permissões (RLS - Row Level Security)

**Tabela `chains`:**
- Todos podem ler correntes ativas.
- Apenas o criador pode cancelar (se `first_post_id` for NULL).

**Tabela `chain_posts`:**
- Todos podem ler.
- Apenas autenticados podem inserir.

### c. Notificações

**Possíveis notificações futuras:**
- Quando alguém participa da corrente que você criou.
- Quando alguém participa a partir do seu post.
- Quando a corrente atinge X participantes.

### d. Pontuação

**Possível sistema de pontos futuro:**
- Criar corrente: +X pontos.
- Participar de corrente: +Y pontos.
- Corrente atingir Z participantes: bônus para o criador.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 8. Ordem de Implementação Sugerida

Para garantir uma implementação organizada e testável, sugere-se a seguinte ordem:

### Fase 1: Banco de Dados
1. Criar tabela `chains`.
2. Criar tabela `chain_posts`.
3. Adicionar coluna `chain_id` em `posts`.
4. Criar índices.
5. Configurar RLS (Row Level Security).

### Fase 2: Funções SQL
1. Implementar `create_chain`.
2. Implementar `cancel_chain`.
3. Implementar `add_post_to_chain`.
4. Implementar `get_chain_info`.
5. Implementar `get_chain_tree` (opcional, para análise futura).

### Fase 3: Frontend - Criação
1. Adicionar botão "Criar Corrente 🔗" na aba "Destacar".
2. Criar modal de criação de corrente.
3. Implementar lógica de criação (chamada à função `create_chain`).
4. Implementar estado de corrente ativa (botão "Cancelar Corrente", nome, tooltip).
5. Fixar tipo de destaque.
6. Implementar cancelamento de corrente.

### Fase 4: Frontend - Participação
1. Adicionar destaque de corrente nos posts.
2. Criar modal de visualização de corrente.
3. Implementar botão "Participar".
4. Implementar lógica de participação (abrir aba "Destacar" com corrente selecionada).
5. Implementar botão "Cancelar" (remover seleção).

### Fase 5: Integração
1. Modificar função de criação de post para incluir `chain_id`.
2. Chamar `add_post_to_chain` ao criar post linkado.
3. Guardar `parent_post_author_id` corretamente.
4. Testar fluxo completo (criador e participante).

### Fase 6: Testes e Ajustes
1. Testar cancelamento de corrente antes do primeiro post.
2. Testar impossibilidade de cancelar após primeiro post.
3. Testar rastreamento da cadeia.
4. Testar tooltip e exibição de informações.
5. Ajustar UI/UX conforme necessário.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 9. Arquivos a Serem Modificados/Criados

### Banco de Dados (SQL)
- `sql/schema/chains.sql` (novo)
- `sql/schema/chain_posts.sql` (novo)
- `sql/migrations/YYYYMMDD_add_chain_id_to_posts.sql` (novo)
- `sql/functions/create_chain.sql` (novo)
- `sql/functions/cancel_chain.sql` (novo)
- `sql/functions/add_post_to_chain.sql` (novo)
- `sql/functions/get_chain_info.sql` (novo)
- `sql/functions/get_chain_tree.sql` (novo, opcional)

### Frontend (HTML/JavaScript)
- `index.html` (modificar aba "Destacar" e exibição de posts)

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 10. Diagramas

### a. Diagrama de Entidade-Relacionamento (Simplificado)

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   chains    │         │ chain_posts  │         │    posts    │
├─────────────┤         ├──────────────┤         ├─────────────┤
│ id (PK)     │◄────────│ chain_id (FK)│         │ id (PK)     │
│ creator_id  │         │ post_id (FK) │────────►│ chain_id    │
│ name        │         │ author_id    │         │ ...         │
│ description │         │ parent_post_ │         └─────────────┘
│ highlight_  │         │ author_id    │
│ type        │         │ created_at   │
│ is_active   │         └──────────────┘
│ first_post_ │
│ id          │
│ created_at  │
└─────────────┘
```

### b. Fluxograma de Criação de Corrente

```
[Usuário clica "Criar Corrente"]
            ↓
[Preenche modal: Nome, Descrição, Tipo]
            ↓
[Clica "Criar"]
            ↓
[Backend: create_chain()]
            ↓
[Retorna chain_id]
            ↓
[Frontend: Armazena activeChain]
            ↓
[Exibe "Cancelar Corrente" + Nome + Tooltip]
            ↓
[Fixa tipo de destaque]
            ↓
┌───────────┴───────────┐
│                       │
[Cancelar Corrente]   [Criar Post]
│                       │
[cancel_chain()]      [add_post_to_chain()]
│                       │
[Deleta corrente]     [Corrente ativa]
│                       │
[Volta ao normal]     [Volta ao normal]
```

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 11. Considerações Finais

O sistema de Correntes é uma funcionalidade poderosa para incentivar engajamento e criar sequências temáticas rastreáveis. A implementação sugerida é modular e permite expansões futuras, como:

- **Análise de Correntes:** Dashboards mostrando as correntes mais populares.
- **Gamificação:** Badges para criadores de correntes virais.
- **Notificações:** Avisos quando alguém participa da sua corrente.
- **Pontuação:** Sistema de pontos para criadores e participantes.

A estrutura de banco de dados foi projetada para permitir rastreamento completo da cadeia de participação, possibilitando análises profundas sobre o alcance e impacto de cada corrente.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

**Fim do Plano de Implementação**


---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---


# Plano Complementar: Gamificação do Sistema de Correntes

**Autor:** Manus AI  
**Data:** 03 de Dezembro de 2025  
**Versão:** 1.0

## 1. Visão Geral

Este documento complementa o plano de implementação do sistema de Correntes, detalhando a adição de:

1.  **Badges:** Novas conquistas relacionadas à criação e participação em correntes.
2.  **Pontuação:** Sistema de pontos para recompensar a criação e participação.

O objetivo é aumentar o engajamento e incentivar o uso da nova funcionalidade.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 2. Novos Badges de Correntes

Serão criados novos badges para reconhecer a atividade dos usuários no sistema de Correntes. A lógica de concessão será integrada à função `auto_badge_check_bonus`.

### a. Badges de Criação de Correntes

| Nome do Badge | Ícone | Raridade | Condição para Conceder |
| :--- | :--- | :--- | :--- |
| **Iniciador** | 🔗 | Comum | Criar sua primeira corrente. |
| **Conector** | ⛓️ | Raro | Criar 5 correntes. |
| **Engrenagem** | ⚙️ | Épico | Criar 20 correntes. |
| **Corrente Viral** | 🔥 | Lendário | Criar uma corrente que atinja 50 participantes. |

### b. Badges de Participação em Correntes

| Nome do Badge | Ícone | Raridade | Condição para Conceder |
| :--- | :--- | :--- | :--- |
| **Elo** | 🔗 | Comum | Participar da sua primeira corrente. |
| **Corrente Forte** | 💪 | Raro | Participar de 10 correntes diferentes. |
| **Multiplicador** | 📈 | Épico | Participar de 50 correntes diferentes. |
| **Elo Profundo** | 🌊 | Lendário | Participar de uma corrente com profundidade 10 (10 níveis de participação). |

### c. Implementação dos Badges

1.  **Adicionar Badges na Tabela `badges`:**
    - Inserir os 8 novos badges com seus nomes, ícones, raridades e condições.

2.  **Atualizar Função `auto_badge_check_bonus`:**
    - Adicionar lógica para verificar as novas condições:
      - Contar correntes criadas pelo usuário.
      - Contar correntes participadas pelo usuário.
      - Verificar o número de participantes em correntes criadas pelo usuário.
      - Verificar a profundidade da participação do usuário em correntes.

3.  **Criar Funções de Suporte:**
    - `count_user_created_chains(p_user_id)`: Retorna o número de correntes criadas.
    - `count_user_participated_chains(p_user_id)`: Retorna o número de correntes participadas.
    - `get_chain_participants_count(p_chain_id)`: Retorna o número de participantes em uma corrente.
    - `get_user_participation_depth(p_user_id, p_chain_id)`: Retorna a profundidade da participação de um usuário em uma corrente.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 3. Sistema de Pontuação para Correntes

Serão criados novos `action_type` na tabela `points_history` para recompensar a criação e participação em correntes.

### a. Pontos por Ação

| Ação | `action_type` | Pontos |
| :--- | :--- | :--- |
| **Criar uma corrente** | `chain_created` | **+25 pontos** |
| **Participar de uma corrente** | `chain_participated` | **+15 pontos** |

### b. Implementação da Pontuação

1.  **Atualizar Função `create_chain`:**
    - Após criar a corrente com sucesso, inserir um registro em `points_history`:
      - `user_id` = `p_creator_id`
      - `points_earned` = 25
      - `action_type` = `chain_created`
      - `reference_id` = ID da corrente criada

2.  **Atualizar Função `add_post_to_chain`:**
    - Após adicionar o post à corrente, verificar se é uma participação (não o criador).
    - Se `p_parent_post_author_id` **NÃO** for `NULL`:
      - Inserir um registro em `points_history`:
        - `user_id` = `p_author_id` (quem está participando)
        - `points_earned` = 15
        - `action_type` = `chain_participated`
        - `reference_id` = ID da corrente

3.  **Atualizar Função `recalculate_user_points_secure`:**
    - Garantir que os novos `action_type` (`chain_created`, `chain_participated`) sejam incluídos na soma total de pontos.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 4. Alterações Necessárias no Banco de Dados

### a. Tabela `badges`

Inserir os 8 novos badges relacionados a correntes.

**Script SQL:**
```sql
INSERT INTO badges (name, icon, rarity, condition_type, condition_value, bonus_points) VALUES
-- Badges de Criação
('Iniciador', '🔗', 'comum', 'chains_created', 1, 50),
('Conector', '⛓️', 'raro', 'chains_created', 5, 150),
('Engrenagem', '⚙️', 'épico', 'chains_created', 20, 500),
('Corrente Viral', '🔥', 'lendário', 'chains_created_with_participants', 50, 1000),

-- Badges de Participação
('Elo', '🔗', 'comum', 'chains_participated', 1, 50),
('Corrente Forte', '💪', 'raro', 'chains_participated', 10, 150),
('Multiplicador', '📈', 'épico', 'chains_participated', 50, 500),
('Elo Profundo', '🌊', 'lendário', 'chain_participation_depth', 10, 1000);
```

### b. Tabela `points_history`

Nenhuma alteração estrutural necessária. Os novos `action_type` serão inseridos dinamicamente.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 5. Funções SQL Necessárias

### a. `count_user_created_chains`

**Descrição:** Retorna o número de correntes criadas por um usuário.

**Parâmetros:**
- `p_user_id` (UUID): ID do usuário.

**Retorna:** INTEGER (número de correntes criadas).

**Lógica:**
```sql
CREATE OR REPLACE FUNCTION count_user_created_chains(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COUNT(*) 
        FROM chains 
        WHERE creator_id = p_user_id 
        AND is_active = true
    );
END;
$$;
```

### b. `count_user_participated_chains`

**Descrição:** Retorna o número de correntes em que um usuário participou (excluindo as que criou).

**Parâmetros:**
- `p_user_id` (UUID): ID do usuário.

**Retorna:** INTEGER (número de correntes participadas).

**Lógica:**
```sql
CREATE OR REPLACE FUNCTION count_user_participated_chains(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT chain_id) 
        FROM chain_posts 
        WHERE author_id = p_user_id 
        AND parent_post_author_id IS NOT NULL
    );
END;
$$;
```

### c. `get_chain_participants_count`

**Descrição:** Retorna o número de participantes em uma corrente.

**Parâmetros:**
- `p_chain_id` (UUID): ID da corrente.

**Retorna:** INTEGER (número de participantes).

**Lógica:**
```sql
CREATE OR REPLACE FUNCTION get_chain_participants_count(p_chain_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT author_id) 
        FROM chain_posts 
        WHERE chain_id = p_chain_id
    );
END;
$$;
```

### d. `get_user_participation_depth`

**Descrição:** Retorna a profundidade máxima da participação de um usuário em uma corrente.

**Parâmetros:**
- `p_user_id` (UUID): ID do usuário.
- `p_chain_id` (UUID): ID da corrente.

**Retorna:** INTEGER (profundidade máxima).

**Lógica:**
```sql
CREATE OR REPLACE FUNCTION get_user_participation_depth(p_user_id UUID, p_chain_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_max_depth INTEGER := 0;
BEGIN
    WITH RECURSIVE chain_tree AS (
        -- Nível 0: Criador da corrente
        SELECT post_id, author_id, parent_post_author_id, 0 AS depth
        FROM chain_posts
        WHERE chain_id = p_chain_id 
        AND parent_post_author_id IS NULL
        
        UNION ALL
        
        -- Níveis subsequentes
        SELECT cp.post_id, cp.author_id, cp.parent_post_author_id, ct.depth + 1
        FROM chain_posts cp
        JOIN chain_tree ct ON cp.parent_post_author_id = ct.author_id
        WHERE cp.chain_id = p_chain_id
    )
    SELECT MAX(depth) INTO v_max_depth
    FROM chain_tree
    WHERE author_id = p_user_id;
    
    RETURN COALESCE(v_max_depth, 0);
END;
$$;
```

### e. Atualizar `auto_badge_check_bonus`

**Descrição:** Adicionar verificação dos novos badges de correntes.

**Lógica a ser adicionada:**
```sql
-- Verificar badges de criação de correntes
WHEN v_badge.condition_type = 'chains_created' THEN
    v_condition_met := count_user_created_chains(p_user_id) >= v_badge.condition_value;

-- Verificar badge "Corrente Viral"
WHEN v_badge.condition_type = 'chains_created_with_participants' THEN
    v_condition_met := EXISTS (
        SELECT 1 FROM chains c
        WHERE c.creator_id = p_user_id
        AND get_chain_participants_count(c.id) >= v_badge.condition_value
    );

-- Verificar badges de participação em correntes
WHEN v_badge.condition_type = 'chains_participated' THEN
    v_condition_met := count_user_participated_chains(p_user_id) >= v_badge.condition_value;

-- Verificar badge "Elo Profundo"
WHEN v_badge.condition_type = 'chain_participation_depth' THEN
    v_condition_met := EXISTS (
        SELECT 1 FROM chain_posts cp
        WHERE cp.author_id = p_user_id
        AND get_user_participation_depth(p_user_id, cp.chain_id) >= v_badge.condition_value
    );
```

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 6. Triggers e Automação

Para garantir que os badges sejam concedidos automaticamente, será necessário adicionar triggers.

### a. Trigger: Verificar Badges ao Criar Corrente

**Quando:** Após inserir um registro em `chains`.

**Ação:** Chamar `auto_badge_check_bonus` para o criador.

**SQL:**
```sql
CREATE OR REPLACE FUNCTION check_badges_after_chain_created()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM auto_badge_check_bonus(NEW.creator_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_check_badges_after_chain_created
AFTER INSERT ON chains
FOR EACH ROW
EXECUTE FUNCTION check_badges_after_chain_created();
```

### b. Trigger: Verificar Badges ao Participar de Corrente

**Quando:** Após inserir um registro em `chain_posts` (com `parent_post_author_id` não nulo).

**Ação:** Chamar `auto_badge_check_bonus` para o participante.

**SQL:**
```sql
CREATE OR REPLACE FUNCTION check_badges_after_chain_participation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.parent_post_author_id IS NOT NULL THEN
        PERFORM auto_badge_check_bonus(NEW.author_id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_check_badges_after_chain_participation
AFTER INSERT ON chain_posts
FOR EACH ROW
EXECUTE FUNCTION check_badges_after_chain_participation();
```

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 7. Ordem de Implementação Sugerida

Para garantir uma implementação organizada, sugere-se a seguinte ordem:

### Fase 1: Funções de Suporte
1. Criar `count_user_created_chains`.
2. Criar `count_user_participated_chains`.
3. Criar `get_chain_participants_count`.
4. Criar `get_user_participation_depth`.

### Fase 2: Badges
1. Inserir os 8 novos badges na tabela `badges`.
2. Atualizar a função `auto_badge_check_bonus` com as novas condições.

### Fase 3: Pontuação
1. Atualizar `create_chain` para inserir pontos.
2. Atualizar `add_post_to_chain` para inserir pontos.
3. Verificar se `recalculate_user_points_secure` inclui os novos `action_type`.

### Fase 4: Triggers
1. Criar trigger para verificar badges ao criar corrente.
2. Criar trigger para verificar badges ao participar de corrente.

### Fase 5: Testes
1. Testar criação de corrente e concessão de pontos.
2. Testar participação em corrente e concessão de pontos.
3. Testar concessão de badges:
   - Criar 1 corrente → Badge "Iniciador".
   - Participar de 1 corrente → Badge "Elo".
   - Criar corrente com 50 participantes → Badge "Corrente Viral".
   - Participar em profundidade 10 → Badge "Elo Profundo".

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 8. Arquivos a Serem Criados/Modificados

### Banco de Dados (SQL)
- `sql/migrations/YYYYMMDD_add_chain_badges.sql` (novo)
- `sql/functions/count_user_created_chains.sql` (novo)
- `sql/functions/count_user_participated_chains.sql` (novo)
- `sql/functions/get_chain_participants_count.sql` (novo)
- `sql/functions/get_user_participation_depth.sql` (novo)
- `sql/functions/auto_badge_check_bonus.sql` (modificar)
- `sql/functions/create_chain.sql` (modificar)
- `sql/functions/add_post_to_chain.sql` (modificar)
- `sql/triggers/check_badges_after_chain_created.sql` (novo)
- `sql/triggers/check_badges_after_chain_participation.sql` (novo)

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 9. Resumo da Pontuação

| Ação | Pontos Diretos | Badge Possível | Pontos do Badge |
| :--- | :--- | :--- | :--- |
| **Criar 1ª corrente** | +25 | Iniciador (Comum) | +50 |
| **Criar 5 correntes** | +125 (5×25) | Conector (Raro) | +150 |
| **Criar 20 correntes** | +500 (20×25) | Engrenagem (Épico) | +500 |
| **Corrente com 50 participantes** | +25 | Corrente Viral (Lendário) | +1000 |
| **Participar 1ª corrente** | +15 | Elo (Comum) | +50 |
| **Participar 10 correntes** | +150 (10×15) | Corrente Forte (Raro) | +150 |
| **Participar 50 correntes** | +750 (50×15) | Multiplicador (Épico) | +500 |
| **Participar profundidade 10** | +15 | Elo Profundo (Lendário) | +1000 |

**Exemplo de Ganho Total:**
- Usuário cria 1 corrente: **25 + 50 = 75 pontos**
- Usuário participa de 10 correntes: **150 + 50 + 150 = 350 pontos**

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

## 10. Considerações Finais

O sistema de gamificação proposto para as Correntes incentivará tanto a criação quanto a participação, recompensando usuários com pontos e badges. A estrutura é escalável e permite a adição de novos badges e condições no futuro.

**Possíveis Expansões Futuras:**
- Badge para corrente com maior profundidade da plataforma.
- Badge para usuário que participou de correntes de todos os tipos de destaque.
- Sistema de ranking de criadores de correntes mais virais.
- Notificações quando um badge de corrente é conquistado.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

---

**Fim do Plano Complementar**
