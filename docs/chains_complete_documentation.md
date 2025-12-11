# Documentação Completa: Sistema de Correntes

**Autor:** Manus AI  
**Data:** 03 de Dezembro de 2025  
**Versão:** 2.0 (Consolidada e Revisada)

## 1. Visão Geral

Este documento apresenta o plano completo para a implementação do sistema de "Correntes" (Chains) na plataforma. O objetivo é fomentar o engajamento contínuo e rastreável dos usuários através de sequências de posts temáticos. O plano abrange a funcionalidade principal das correntes, bem como um sistema de gamificação integrado, composto por badges e pontuação.

O documento está estruturado em duas partes principais, detalhando os aspectos funcionais e técnicos de cada componente:

---

# PARTE 1: IMPLEMENTAÇÃO DO SISTEMA DE CORRENTES

Esta seção detalha a funcionalidade central das correntes, abrangendo a estrutura de dados, as interações no frontend e a lógica de backend.

## 2. Estrutura do Banco de Dados

Para suportar o sistema de Correntes, serão introduzidas duas novas tabelas e uma alteração em uma tabela existente.

### 2.1. Tabela `chains`

Armazena as informações primárias de cada corrente criada.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `id` | `UUID` | Identificador único da corrente (Chave Primária). |
| `created_at` | `TIMESTAMPTZ` | Carimbo de data/hora da criação da corrente. |
| `creator_id` | `UUID` | ID do usuário que iniciou a corrente (Chave Estrangeira para `profiles.id`). |
| `name` | `TEXT` | Nome atribuído à corrente. |
| `description` | `TEXT` | Descrição detalhada da corrente, exibida em tooltips. |
| `highlight_type` | `TEXT` | Tipo de destaque fixo associado à corrente (e.g., "Apoio", "Inspiração"). |
| `status` | `TEXT` | Status da corrente ('pending', 'active', 'closed'). Default: 'pending'. |
| `start_date` | `TIMESTAMPTZ` | Data de início da corrente (quando o primeiro post é criado). |
| `end_date` | `TIMESTAMPTZ` | Data de fechamento da corrente (quando o criador a encerra). |
| `first_post_id` | `UUID` | ID do primeiro post que iniciou a corrente (Chave Estrangeira para `posts.id`). Preenchido após a publicação do primeiro post pelo criador. |

**Índices:**
- `creator_id` para otimização de consultas por criador.

### 2.2. Tabela `chain_posts`

Associa posts individuais a uma corrente e rastreia a origem de cada participação, permitindo a reconstrução da árvore de engajamento.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `id` | `UUID` | Identificador único da associação (Chave Primária). |
| `chain_id` | `UUID` | ID da corrente à qual o post pertence (Chave Estrangeira para `chains.id`). |
| `post_id` | `UUID` | ID do post que integra a corrente (Chave Estrangeira para `posts.id`). |
| `author_id` | `UUID` | ID do autor do post (Chave Estrangeira para `profiles.id`). |
| `parent_post_author_id` | `UUID` | ID do autor do post que serviu como ponto de entrada para a participação atual. `NULL` para o post inicial do criador da corrente. |
| `created_at` | `TIMESTAMPTZ` | Carimbo de data/hora da criação do post na corrente. |

**Índices:**
- `chain_id` para consultas por corrente.
- `post_id` para consultas por post.
- `parent_post_author_id` para rastreamento da cadeia de participação.

### 2.3. Alterações na Tabela `posts`

Uma nova coluna será adicionada à tabela `posts` para vincular posts diretamente às correntes.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `chain_id` | `UUID` | (Opcional) ID da corrente à qual o post pertence (Chave Estrangeira para `chains.id`). Será `NULL` se o post não estiver associado a uma corrente. |

**Índice:**
- `chain_id` para otimização de consultas de posts por corrente.

## 3. Alterações no Frontend

As modificações na interface do usuário serão implementadas na aba "Destacar" e na exibição de posts na timeline, proporcionando uma experiência fluida para criação e participação em correntes.

### 3.1. Aba "Destacar" - Gerenciamento de Correntes

**3.1.1. Botão "Criar Corrente"**

- **Localização:** Canto superior direito da aba "Destacar", alinhado ao texto "Destacar Alguém".
- **Estado Inicial:** Exibe o botão **"Criar Corrente 🔗"**.

**3.1.2. Modal de Criação de Corrente**

- **Acionamento:** Ao clicar no botão "Criar Corrente 🔗".
- **Título:** "Criar Corrente 🔗".
- **Campos:**
    - **Nome da Corrente:** Campo de texto obrigatório.
    - **Descrição:** Área de texto obrigatória para detalhes da corrente.
    - **Tipo de Destaque:** Dropdown com as mesmas opções da aba "Destacar", obrigatório.
- **Ação:** Botão **"Criar"**.

**3.1.3. Pós-Criação da Corrente**

- O modal é fechado automaticamente.
- A interface retorna à aba "Destacar".
- O botão "Criar Corrente 🔗" é substituído por **"Cancelar Corrente"**.
- O nome da corrente recém-criada, **"[Nome da Corrente] 🔗"**, é exibido à esquerda do botão.
- Um tooltip contendo a descrição da corrente aparece **em cima do mouse** ao passar sobre o nome da corrente.
- O **tipo de destaque** selecionado na criação da corrente é fixado, impedindo alterações.
- O usuário pode agora criar um post, que será automaticamente vinculado à corrente ativa.

**3.1.4. Cancelamento da Corrente (Pelo Criador)**

- **Acionamento:** Clicar no botão "Cancelar Corrente".
- **Condição:** A corrente só pode ser deletada se nenhum post tiver sido criado nela.
- **Resultado:** A corrente é deletada, e a interface retorna ao estado inicial (botão "Criar Corrente 🔗").

**3.1.5. Corrente Ativa com Posts**

- Após a criação do primeiro post vinculado à corrente, o botão "Cancelar Corrente" desaparece.
- A corrente não pode mais ser deletada pelo criador.
- A interface da aba "Destacar" retorna ao seu estado inicial, permitindo a criação de posts comuns ou a participação em outras correntes.

### 3.2. Posts na Timeline - Interação com Correntes

**3.2.1. Destaque Visual**

- Ao lado do ícone de "tipo de post", será exibido o nome da corrente: **"[Nome da Corrente] 🔗"**.

**3.2.2. Modal de Visualização da Corrente**

- **Acionamento:** Clicar no destaque da corrente em um post.
- **Título:** "[Nome da Corrente] 🔗".
- **Informações:** Exibe o Nome, Descrição e Tipo de Destaque da corrente.
- **Ação:** Botão **"Participar"**.

**3.2.3. Participação em uma Corrente**

- **Acionamento:** Clicar no botão "Participar" no modal.
- **Rastreamento:** O ID do autor do post original (onde o usuário clicou para participar) é registrado para análise da cadeia.
- **Navegação:** O modal é fechado, e a aba "Destacar" é aberta automaticamente.
- **Interface:** O nome da corrente, **"[Nome da Corrente] 🔗"**, é exibido (com tooltip da descrição).
- **Ação:** O botão **"Cancelar"** (diferente de "Cancelar Corrente") é exibido.
- **Fixação:** O tipo de destaque da corrente é fixado.
- O usuário pode agora criar um post, que será vinculado à corrente selecionada.

**3.2.4. Cancelamento da Participação**

- **Acionamento:** Clicar no botão "Cancelar".
- **Resultado:** A seleção da corrente é removida, o tipo de destaque fixo é liberado, e a interface retorna ao estado inicial (botão "Criar Corrente 🔗").

**3.2.5. Pós-Criação de Post como Participante**

- Após a criação do post vinculado à corrente, o ID do autor do post original (que levou à participação) é guardado.
- A interface da aba "Destacar" retorna ao seu estado inicial.

### 3.3. Variáveis de Estado (Frontend)

Para gerenciar o estado das correntes no frontend, as seguintes variáveis serão essenciais:

| Variável | Tipo | Descrição |
| :--- | :--- | :--- |
| `activeChain` | `Object` ou `null` | Armazena os detalhes da corrente atualmente ativa (criada ou participada), incluindo `id`, `name`, `description`, `highlight_type`. |
| `isChainCreator` | `Boolean` | Indica se o usuário logado é o criador da `activeChain`. `true` para criadores, `false` para participantes. |
| `parentPostAuthorId` | `UUID` ou `null` | Armazena o ID do autor do post que serviu como gatilho para a participação em uma corrente. Relevante apenas para participantes. |

## 4. Funções SQL Necessárias

As seguintes funções SQL serão desenvolvidas para gerenciar o ciclo de vida das correntes e suas interações com posts.

### 4.1. `create_chain(p_creator_id UUID, p_name TEXT, p_description TEXT, p_highlight_type TEXT)`

- **Descrição:** Cria um novo registro na tabela `chains`.
- **Retorna:** O `id` (UUID) da corrente recém-criada.
- **Lógica:** Insere uma nova linha em `chains` com `status = 'pending'` e `first_post_id = NULL`.

### 4.2. `cancel_chain(p_chain_id UUID, p_user_id UUID)`

- **Descrição:** Inativa uma corrente, permitindo seu cancelamento apenas se nenhum post tiver sido associado a ela.
- **Retorna:** `BOOLEAN` indicando sucesso (`true`) ou falha (`false`).
- **Lógica:** Verifica se `p_user_id` corresponde ao `creator_id` da corrente e se `first_post_id` é `NULL`. Se ambas as condições forem verdadeiras, deleta o registro da corrente.

### 4.3. `add_post_to_chain(p_chain_id UUID, p_post_id UUID, p_author_id UUID, p_parent_post_author_id UUID DEFAULT NULL)`

- **Descrição:** Vincula um post a uma corrente e registra a participação.
- **Retorna:** `VOID`.
- **Lógica:**
    1. Insere um registro na tabela `chain_posts`.
    2. Atualiza a coluna `chain_id` na tabela `posts` para o `p_post_id` fornecido.
    3. Se `p_parent_post_author_id` for `NULL` (indicando que o post é do criador da corrente), atualiza `chains.first_post_id` com o `p_post_id`, `status` para 'active' e `start_date` para a data/hora atual.

### 4.4. `get_chain_info(p_chain_id UUID)`

- **Descrição:** Recupera informações detalhadas sobre uma corrente específica.
- **Retorna:** Um objeto `JSON` contendo `id`, `name`, `description`, `highlight_type`, `creator_id`, `first_post_id` e `total_posts` (contagem de posts na corrente).
- **Lógica:** Consulta a tabela `chains` e realiza uma contagem de posts associados na tabela `chain_posts`.

### 4.5. `get_chain_tree(p_chain_id UUID)`

- **Descrição:** Constrói e retorna a estrutura hierárquica dos posts dentro de uma corrente, útil para análises de propagação.
- **Retorna:** Um objeto `JSON` representando a árvore de posts.
- **Lógica:** Utiliza uma consulta recursiva na tabela `chain_posts` para mapear as relações `parent_post_author_id`.

### 4.6. `close_chain(p_chain_id UUID, p_user_id UUID)`

- **Descrição:** Encerra uma corrente ativa, impedindo novas participações. **Implementação futura.**
- **Retorna:** `BOOLEAN` indicando sucesso (`true`) ou falha (`false`).
- **Lógica:** 
    1. Verifica se `p_user_id` corresponde ao `creator_id` da corrente.
    2. Verifica se `status` é 'active' (corrente deve estar ativa para ser fechada).
    3. Se ambas as condições forem verdadeiras, atualiza `status` para 'closed' e `end_date` para a data/hora atual.
    4. Retorna `true` se sucesso, `false` se falha.

## 5. Fluxos de Usuário

Esta seção detalha as interações do usuário com o sistema de Correntes, tanto para o criador quanto para o participante.

### 5.1. Fluxo do Criador da Corrente

```mermaid
graph TD
    A[Usuário acessa aba 
"Destacar"]
    A --> B{Clica em "Criar Corrente 🔗"}
    B --> C[Abre Modal "Criar Corrente 🔗"]
    C --> D[Preenche: Nome, Descrição, Tipo de Destaque]
    D --> E{Clica "Criar"}
    E --> F[Modal fecha, Frontend armazena activeChain]
    F --> G[Botão muda para "Cancelar Corrente"]
    G --> H[Exibe "[Nome da Corrente] 🔗" com Tooltip]
    H --> I[Tipo de Destaque Fixo]
    I --> J{Usuário interage}

    J --> K{Clica "Cancelar Corrente"}
    K --> L{Nenhum post criado?}
    L -- Sim --> M[Backend: cancel_chain()]
    M --> N[Corrente deletada]
    N --> O[Volta ao estado inicial]
    L -- Não --> P[Erro: Corrente não pode ser cancelada]

    J --> Q[Cria Post Destacando Alguém]
    Q --> R[Post é criado e linkado à corrente]
    R --> S[Backend: add_post_to_chain()]
    S --> T[Corrente não pode mais ser cancelada]
    T --> U[Volta ao estado inicial da aba "Destacar"]
```

### 5.2. Fluxo do Participante da Corrente

```mermaid
graph TD
    A[Usuário vê Post com Destaque "[Nome da Corrente] 🔗"]
    A --> B{Clica no Destaque}
    B --> C[Abre Modal "[Nome da Corrente] 🔗"]
    C --> D[Exibe: Nome, Descrição, Tipo de Destaque]
    D --> E{Clica "Participar"}
    E --> F[Frontend: Guarda parentPostAuthorId]
    F --> G[Modal fecha, Abre aba "Destacar"]
    G --> H[Exibe "[Nome da Corrente] 🔗" com Tooltip]
    H --> I[Botão "Cancelar" aparece]
    I --> J[Tipo de Destaque Fixo]
    J --> K{Usuário interage}

    K --> L{Clica "Cancelar"}
    L --> M[Remove seleção da corrente]
    M --> N[Libera tipo de destaque fixo]
    N --> O[Volta ao estado inicial]

    K --> P[Cria Post Destacando Alguém]
    P --> Q[Post é criado e linkado à corrente]
    Q --> R[Backend: add_post_to_chain()]
    R --> S[Guarda parentPostAuthorId no chain_posts]
    S --> T[Volta ao estado inicial da aba "Destacar"]
```

## 6. Rastreamento e Análise

O sistema de correntes foi projetado para permitir um rastreamento abrangente da cadeia de participação, fornecendo insights valiosos sobre o engajamento e a propagação de conteúdo.

### 6.1. Dados Rastreáveis

| Dado | Descrição |
| :--- | :--- |
| **Criador da Corrente** | Identifica o usuário que iniciou a corrente. |
| **Primeiro Post da Corrente** | O post que marca o início oficial da corrente. |
| **Total de Posts na Corrente** | Contagem de todos os posts vinculados a uma corrente específica. |
| **Árvore de Participação** | Representação hierárquica de como os usuários participaram, a partir de qual post. |
| **Profundidade da Cadeia** | O número máximo de níveis de participação em uma corrente. |
| **Taxa de Conversão** | Métrica que indica quantos usuários que visualizaram a corrente decidiram participar.

### 6.2. Consultas SQL Úteis

**Exemplo 1: Contagem total de posts em uma corrente específica**
```sql
SELECT COUNT(*) FROM chain_posts WHERE chain_id = <chain_id>;
```

**Exemplo 2: Listagem de todos os usuários que participaram de uma corrente**
```sql
SELECT DISTINCT author_id FROM chain_posts WHERE chain_id = <chain_id>;
```

**Exemplo 3: Determinação da profundidade máxima de uma cadeia de participação**
```sql
WITH RECURSIVE chain_tree AS (
  SELECT post_id, author_id, parent_post_author_id, 1 AS depth
  FROM chain_posts
  WHERE chain_id = <chain_id> AND parent_post_author_id IS NULL
  
  UNION ALL
  
  SELECT cp.post_id, cp.author_id, cp.parent_post_author_id, ct.depth + 1
  FROM chain_posts cp
  JOIN chain_tree ct ON cp.parent_post_author_id = ct.author_id
  WHERE cp.chain_id = <chain_id>
)
SELECT MAX(depth) FROM chain_tree;
```

## 7. Considerações de Implementação

### 7.1. Validações

- **Frontend:**
    - **Nome da Corrente:** Mínimo de 3 e máximo de 50 caracteres.
    - **Descrição:** Mínimo de 10 e máximo de 200 caracteres.
    - **Tipo de Destaque:** Deve corresponder a um dos tipos válidos predefinidos.

- **Backend:**
    - **Cancelamento:** O usuário que tenta cancelar uma corrente deve ser o criador.
    - **Integridade:** O cancelamento só é permitido se a corrente não possuir posts associados (`first_post_id` é `NULL`).
    - **Validade de `parent_post_author_id`:** O ID do autor do post pai deve corresponder a um post existente na corrente.
    - **Fechamento de Corrente:** O usuário que tenta fechar uma corrente deve ser o criador, e a corrente deve estar com `status = 'active'`. **Implementação futura.**

### 7.2. Permissões (Row Level Security - RLS)

- **Tabela `chains`:**
    - **Leitura:** Todos os usuários podem visualizar correntes com `status = 'active'` ou `status = 'closed'`.
    - **Escrita/Atualização:** Apenas o criador pode modificar ou inativar sua própria corrente (com restrições de `first_post_id` e `status`).

- **Tabela `chain_posts`:**
    - **Leitura:** Todos os usuários podem visualizar os posts de uma corrente.
    - **Escrita:** Apenas usuários autenticados podem adicionar posts a uma corrente com `status = 'active'` (correntes fechadas não aceitam novos posts).

### 7.3. Notificações (Futuras)

O sistema pode ser expandido para incluir notificações automatizadas, como:

- Alerta para o criador quando um novo usuário participa de sua corrente.
- Notificação para o participante quando alguém se engaja a partir de seu post.
- Avisos quando uma corrente atinge um número significativo de participantes.

### 7.4. Pontuação (Futura)

Embora detalhada na Parte 2, a integração de um sistema de pontuação pode incluir:

- Pontos pela criação de correntes.
- Pontos pela participação em correntes.
- Bônus para o criador quando sua corrente atinge marcos de participação.

## 8. Ordem de Implementação Sugerida

Para uma implementação estruturada e eficiente, sugere-se a seguinte sequência de fases:

### Fase 1: Banco de Dados
1. Criação da tabela `chains`.
2. Criação da tabela `chain_posts`.
3. Adição da coluna `chain_id` à tabela `posts`.
4. Criação dos índices necessários.
5. Configuração das políticas de RLS.

### Fase 2: Funções SQL (Backend)
1. Implementação da função `create_chain`.
2. Implementação da função `cancel_chain`.
3. Implementação da função `add_post_to_chain`.
4. Implementação da função `get_chain_info`.
5. Implementação da função `get_chain_tree` (opcional, para análises futuras).
6. Implementação da função `close_chain` (**implementação futura**).

### Fase 3: Frontend - Criação de Correntes
1. Desenvolvimento do botão "Criar Corrente 🔗".
2. Implementação do modal de criação de corrente.
3. Integração com a função `create_chain`.
4. Gerenciamento do estado da corrente ativa no frontend (botão "Cancelar Corrente", exibição do nome, tooltip).
5. Fixação do tipo de destaque.
6. Implementação da lógica de cancelamento de corrente no frontend.

### Fase 4: Frontend - Participação em Correntes
1. Exibição do destaque de corrente nos posts da timeline.
2. Implementação do modal de visualização da corrente.
3. Desenvolvimento do botão "Participar".
4. Lógica de participação (abertura da aba "Destacar" com a corrente selecionada).
5. Implementação do botão "Cancelar" (para remover a seleção da corrente).

### Fase 5: Integração e Testes
1. Modificação da função de criação de post para incluir `chain_id`.
2. Chamada de `add_post_to_chain` ao criar posts vinculados.
3. Armazenamento correto de `parent_post_author_id`.
4. Testes abrangentes do fluxo completo (criação, participação, cancelamento).

### Fase 6: Ajustes e Otimizações
1. Testes de cancelamento de corrente em diferentes cenários.
2. Verificação da rastreabilidade da cadeia de participação.
3. Ajustes na UI/UX para otimizar a experiência do usuário.

## 9. Arquivos a Serem Modificados/Criados

### 9.1. Banco de Dados (SQL)
- `sql/schema/chains.sql` (novo)
- `sql/schema/chain_posts.sql` (novo)
- `sql/migrations/YYYYMMDD_add_chain_id_to_posts.sql` (novo)
- `sql/functions/create_chain.sql` (novo)
- `sql/functions/cancel_chain.sql` (novo)
- `sql/functions/add_post_to_chain.sql` (novo)
- `sql/functions/get_chain_info.sql` (novo)
- `sql/functions/get_chain_tree.sql` (novo, opcional)
- `sql/functions/close_chain.sql` (novo, **implementação futura**)

### 9.2. Frontend (HTML/JavaScript)
- `index.html` (modificações na aba "Destacar" e na exibição de posts)

## 10. Diagramas

### 10.1. Diagrama de Entidade-Relacionamento (Simplificado)

```mermaid
erDiagram
    chains ||--o{ chain_posts : "tem"
    posts ||--o{ chain_posts : "contém"
    chains { UUID id PK, TIMESTAMPTZ created_at, UUID creator_id FK, TEXT name, TEXT description, TEXT highlight_type, TEXT status, TIMESTAMPTZ start_date, TIMESTAMPTZ end_date, UUID first_post_id FK }
    chain_posts { UUID id PK, UUID chain_id FK, UUID post_id FK, UUID author_id FK, UUID parent_post_author_id FK, TIMESTAMPTZ created_at }
    posts { UUID id PK, UUID chain_id FK, ... }
```

### 10.2. Fluxograma de Criação de Corrente

```mermaid
graph TD
    A[Usuário acessa aba "Destacar"]
    A --> B{Clica em "Criar Corrente 🔗"}
    B --> C[Abre Modal "Criar Corrente 🔗"]
    C --> D[Preenche: Nome, Descrição, Tipo de Destaque]
    D --> E{Clica "Criar"}
    E --> F[Modal fecha, Frontend armazena activeChain]
    F --> G[Botão muda para "Cancelar Corrente"]
    G --> H[Exibe "[Nome da Corrente] 🔗" com Tooltip]
    H --> I[Tipo de Destaque Fixo]
    I --> J{Usuário interage}

    J --> K{Clica "Cancelar Corrente"}
    K --> L{Nenhum post criado?}
    L -- Sim --> M[Backend: cancel_chain()]
    M --> N[Corrente deletada]
    N --> O[Volta ao estado inicial]
    L -- Não --> P[Erro: Corrente não pode ser cancelada]

    J --> Q[Cria Post Destacando Alguém]
    Q --> R[Post é criado e linkado à corrente]
    R --> S[Backend: add_post_to_chain()]
    S --> T[Corrente não pode mais ser cancelada]
    T --> U[Volta ao estado inicial da aba "Destacar"]
```

### 10.3. Fluxograma de Participação em Corrente

```mermaid
graph TD
    A[Usuário vê Post com Destaque "[Nome da Corrente] 🔗"]
    A --> B{Clica no Destaque}
    B --> C[Abre Modal "[Nome da Corrente] 🔗"]
    C --> D[Exibe: Nome, Descrição, Tipo de Destaque]
    D --> E{Clica "Participar"}
    E --> F[Frontend: Guarda parentPostAuthorId]
    F --> G[Modal fecha, Abre aba "Destacar"]
    G --> H[Exibe "[Nome da Corrente] 🔗" com Tooltip]
    H --> I[Botão "Cancelar" aparece]
    I --> J[Tipo de Destaque Fixo]
    J --> K{Usuário interage}

    K --> L{Clica "Cancelar"}
    L --> M[Remove seleção da corrente]
    M --> N[Libera tipo de destaque fixo]
    N --> O[Volta ao estado inicial]

    K --> P[Cria Post Destacando Alguém]
    P --> Q[Post é criado e linkado à corrente]
    Q --> R[Backend: add_post_to_chain()]
    R --> S[Guarda parentPostAuthorId no chain_posts]
    S --> T[Volta ao estado inicial da aba "Destacar"]
```

## 11. Considerações Finais sobre a Implementação

O sistema de Correntes representa uma funcionalidade robusta para impulsionar o engajamento e a criação de conteúdo temático. A abordagem modular proposta facilita a implementação e permite futuras expansões, como análises de correntes, gamificação avançada e notificações personalizadas.

**Funcionalidade de Fechamento de Correntes:** A estrutura do banco de dados foi preparada para suportar o fechamento de correntes (campos `status`, `start_date`, `end_date`). A função `close_chain` está documentada e pronta para implementação futura, permitindo que criadores encerrem suas correntes e impeçam novas participações, mantendo o histórico visível.

---

# PARTE 2: GAMIFICAÇÃO DO SISTEMA DE CORRENTES

Esta seção detalha a integração de elementos de gamificação ao sistema de Correntes, visando incentivar a criação e participação ativa dos usuários através de badges e um sistema de pontuação.

## 12. Novos Badges de Correntes

Serão introduzidos 8 novos badges para reconhecer e recompensar a atividade dos usuários no sistema de Correntes. A lógica de concessão será integrada à função `auto_badge_check_bonus`.

### 12.1. Badges de Criação de Correntes

| Nome do Badge | Ícone | Raridade | Condição para Conceder |
| :--- | :--- | :--- | :--- |
| **Iniciador** | 🔗 | Comum | Criar sua primeira corrente. |
| **Conector** | ⛓️ | Raro | Criar 5 correntes. |
| **Engrenagem** | ⚙️ | Épico | Criar 20 correntes. |
| **Corrente Viral** | 🔥 | Lendário | Criar uma corrente que atinja 50 participantes. |

### 12.2. Badges de Participação em Correntes

| Nome do Badge | Ícone | Raridade | Condição para Conceder |
| :--- | :--- | :--- | :--- |
| **Elo** | 🔗 | Comum | Participar da sua primeira corrente. |
| **Corrente Forte** | 💪 | Raro | Participar de 10 correntes diferentes. |
| **Multiplicador** | 📈 | Épico | Participar de 50 correntes diferentes. |
| **Elo Profundo** | 🌊 | Lendário | Participar de uma corrente com profundidade 10 (10 níveis de participação). |

#### O que é Profundidade de Participação?

A **profundidade de participação** representa o número de "níveis" de distância que um usuário está do criador original da corrente. É uma métrica que indica o quão longe uma corrente se propagou de pessoa para pessoa.

**Exemplo Prático:**

- **Nível 0 (Profundidade 0):** João cria a corrente.
- **Nível 1 (Profundidade 1):** Maria vê o post de João e participa.
- **Nível 2 (Profundidade 2):** Pedro vê o post de Maria e participa.
- **Nível 3 (Profundidade 3):** Ana vê o post de Pedro e participa.
- ...
- **Nível 10 (Profundidade 10):** Carlos vê o post de alguém no nível 9 e participa.

Para ganhar o badge **"Elo Profundo"**, Carlos precisa estar no nível 10 ou mais profundo. Isso significa que a corrente passou por 10 pessoas antes de chegar até ele.

**Visualização da Cadeia:**
```
João (criador) → Maria → Pedro → Ana → ... → Carlos
  ↓                ↓       ↓       ↓           ↓
Nível 0         Nível 1  Nível 2  Nível 3      Nível 10
```

**Importância da Métrica:**
- **Viralização:** Mede o quão longe uma corrente se espalhou.
- **Engajamento:** Indica que a corrente está gerando interesse contínuo.
- **Recompensa:** Premia usuários que se engajam com conteúdo altamente propagado.

**Cálculo Técnico:**
O sistema rastreia o `parent_post_author_id` em cada participação, criando uma árvore de engajamento. A profundidade é calculada contando o número de "saltos" desde o criador até o participante atual.

### 12.3. Implementação dos Badges

1.  **Adicionar Badges na Tabela `badges`:** Inserir os 8 novos badges com seus atributos (nome, ícone, raridade, condição e valor).
2.  **Atualizar Função `auto_badge_check_bonus`:** Modificar a função para incluir a verificação das novas condições de badges relacionadas a correntes.
3.  **Criar Funções de Suporte:** Desenvolver funções auxiliares para calcular as métricas necessárias para as condições dos badges:
    - `count_user_created_chains(p_user_id)`: Retorna o número de correntes criadas por um usuário.
    - `count_user_participated_chains(p_user_id)`: Retorna o número de correntes distintas em que um usuário participou.
    - `get_chain_participants_count(p_chain_id)`: Retorna o número total de participantes únicos em uma corrente.
    - `get_user_participation_depth(p_user_id, p_chain_id)`: Retorna a profundidade máxima de participação de um usuário em uma corrente específica.

## 13. Sistema de Pontuação para Correntes

Serão introduzidos novos tipos de ação (`action_type`) na tabela `points_history` para recompensar diretamente a criação e participação em correntes.

### 13.1. Pontos por Ação

| Ação | `action_type` | Pontos |
| :--- | :--- | :--- |
| **Criar uma corrente** | `chain_created` | **+25 pontos** |
| **Participar de uma corrente** | `chain_participated` | **+15 pontos** |

### 13.2. Implementação da Pontuação

1.  **Atualizar Função `create_chain`:** Após a criação bem-sucedida de uma corrente, um registro `chain_created` será inserido em `points_history` para o criador.
2.  **Atualizar Função `add_post_to_chain`:** Quando um post é adicionado a uma corrente por um participante (ou seja, `p_parent_post_author_id` não é `NULL`), um registro `chain_participated` será inserido em `points_history` para o autor do post.
3.  **Atualizar Função `recalculate_user_points_secure`:** Garantir que os novos `action_type` (`chain_created`, `chain_participated`) sejam corretamente considerados no cálculo do total de pontos do usuário.

## 14. Alterações Necessárias no Banco de Dados

### 14.1. Tabela `badges`

Inserir os 8 novos badges de correntes. O script SQL para isso é:

```sql
INSERT INTO badges (name, icon, rarity, condition_type, condition_value, bonus_points) VALUES
-- Badges de Criação
("Iniciador", "🔗", "comum", "chains_created", 1, 50),
("Conector", "⛓️", "raro", "chains_created", 5, 150),
("Engrenagem", "⚙️", "épico", "chains_created", 20, 500),
("Corrente Viral", "🔥", "lendário", "chains_created_with_participants", 50, 1000),

-- Badges de Participação
("Elo", "🔗", "comum", "chains_participated", 1, 50),
("Corrente Forte", "💪", "raro", "chains_participated", 10, 150),
("Multiplicador", "📈", "épico", "chains_participated", 50, 500),
("Elo Profundo", "🌊", "lendário", "chain_participation_depth", 10, 1000);
```

### 14.2. Tabela `points_history`

Não são necessárias alterações estruturais. Os novos `action_type` (`chain_created`, `chain_participated`) serão inseridos dinamicamente.

## 15. Funções SQL Necessárias

### 15.1. Funções de Suporte para Badges

- **`count_user_created_chains(p_user_id UUID)`:** Retorna o número de correntes ativas criadas por `p_user_id`.
- **`count_user_participated_chains(p_user_id UUID)`:** Retorna a contagem de correntes distintas em que `p_user_id` participou (excluindo as que criou).
- **`get_chain_participants_count(p_chain_id UUID)`:** Retorna o número de autores únicos de posts em uma corrente.
- **`get_user_participation_depth(p_user_id UUID, p_chain_id UUID)`:** Retorna a profundidade máxima de participação de `p_user_id` em `p_chain_id`.

### 15.2. Atualização da Função `auto_badge_check_bonus`

Será necessário adicionar blocos `WHEN` para cada novo `condition_type` dentro da função `auto_badge_check_bonus` para verificar as condições dos badges de correntes.

## 16. Triggers e Automação

Para automatizar a concessão de badges e pontos, serão implementados triggers no banco de dados.

### 16.1. Trigger: `trigger_check_badges_after_chain_created`

- **Evento:** `AFTER INSERT ON chains`.
- **Ação:** Chama `auto_badge_check_bonus(NEW.creator_id)` para verificar e conceder badges de criação de correntes.

### 16.2. Trigger: `trigger_check_badges_after_chain_participation`

- **Evento:** `AFTER INSERT ON chain_posts`.
- **Condição:** Apenas se `NEW.parent_post_author_id IS NOT NULL` (indicando uma participação, não o post inicial do criador).
- **Ação:** Chama `auto_badge_check_bonus(NEW.author_id)` para verificar e conceder badges de participação em correntes.

## 17. Ordem de Implementação Sugerida

Para uma implementação eficiente da gamificação, sugere-se a seguinte sequência de fases, a ser executada após a implementação da funcionalidade base das correntes (Parte 1):

### Fase 1: Funções de Suporte
1. Criação das funções `count_user_created_chains`, `count_user_participated_chains`, `get_chain_participants_count` e `get_user_participation_depth`.

### Fase 2: Badges
1. Inserção dos 8 novos badges na tabela `badges`.
2. Atualização da função `auto_badge_check_bonus` com a lógica para os novos `condition_type`.

### Fase 3: Pontuação
1. Modificação da função `create_chain` para registrar `chain_created` em `points_history`.
2. Modificação da função `add_post_to_chain` para registrar `chain_participated` em `points_history`.
3. Verificação e ajuste de `recalculate_user_points_secure` para incluir os novos `action_type`.

### Fase 4: Triggers
1. Criação do trigger `trigger_check_badges_after_chain_created`.
2. Criação do trigger `trigger_check_badges_after_chain_participation`.

### Fase 5: Testes e Validação
1. Testes de concessão de pontos por criação e participação.
2. Testes de concessão de todos os 8 badges em diferentes cenários.

## 18. Arquivos a Serem Criados/Modificados

### 18.1. Banco de Dados (SQL)
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

## 19. Resumo da Pontuação e Ganhos

Esta tabela resume os pontos diretos e os pontos de bônus de badges que um usuário pode ganhar ao interagir com o sistema de Correntes.

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

**Exemplo de Ganhos Totais:**
- **Criação de 1 Corrente:** 25 pontos (diretos) + 50 pontos (badge Iniciador) = **75 pontos**.
- **Participação em 10 Correntes:** 150 pontos (diretos) + 50 pontos (badge Elo) + 150 pontos (badge Corrente Forte) = **350 pontos**.

## 20. Considerações Finais sobre a Gamificação

O sistema de gamificação proposto visa não apenas recompensar, mas também guiar o comportamento do usuário, incentivando a criação de correntes de alta qualidade e a participação ativa. A estrutura é flexível para futuras expansões, permitindo a introdução de novos desafios e recompensas.

**Possíveis Expansões Futuras:**
- Badges para correntes que atingem a maior profundidade na plataforma.
- Badges para usuários que participam de correntes de todos os tipos de destaque.
- Sistema de ranking para criadores de correntes mais virais.
- Notificações em tempo real quando um badge de corrente é conquistado.

---

**Fim da Documentação Completa**
