# ⛓️ Especificação da Funcionalidade: Correntes do Memórias Vivas

**Autor**: Manus AI  
**Data**: 07 de janeiro de 2026  
**Versão**: 1.2 (Revisado)

---

## 1. Visão Geral e Conceito

Esta especificação detalha a implementação de **Correntes** dentro do feed **Memórias Vivas**. O objetivo é permitir que usuários com 60+ anos criem narrativas colaborativas, onde cada post é um elo de uma história maior. A participação é restrita, mas a visibilidade é pública, permitindo que todas as gerações apreciem as histórias.

### 1.1. Resumo das Correções (Versão 1.1)

- **Visibilidade Pública**: As correntes e posts do Memórias Vivas serão **visíveis para todos os usuários**, independentemente da idade. A restrição se aplica apenas à **participação** (criação de posts na corrente).
- **Estrutura da Tabela `chains`**: A coluna `highlight_type` existente será utilizada para armazenar o tipo de post da corrente (ex: `memoria_mv`), eliminando a necessidade de uma nova coluna `post_type`.
- **Comportamento de Postagem**: Esclarecido que o **Feed** e o **Tipo de Post** são travados na interface do usuário apenas durante a criação ou participação em uma corrente, replicando o comportamento padrão de correntes.

### 1.1. Conceito Principal

- **Criação Exclusiva (60+)**: Apenas usuários com 60+ anos podem iniciar uma Corrente do Memórias Vivas.
- **Tema Definido**: O criador da corrente escolhe um dos 6 tipos de post do Memórias Vivas (ex: 📖 Memória, 💡 Conselho) para definir o tema da corrente.
- **Tema Definido**: O criador da corrente escolhe um dos 6 tipos de post do Memórias Vivas para definir o tema, que será armazenado na coluna `highlight_type`.
- **Participação Restrita (60+)**: Apenas usuários com 60+ anos podem adicionar novos posts (elos) a uma Corrente do Memórias Vivas.
- **Visibilidade Universal**: Todos os usuários podem visualizar as correntes e seus respectivos posts no feed.
- **Feed e Tipo de Post Fixos (na Ação)**: Ao criar o primeiro post de uma corrente do Memórias Vivas ou ao adicionar um novo post a ela, a interface de postagem travará a seleção do feed em "📖 Memórias Vivas" e fixará o tipo de post, garantindo a consistência da corrente.

---

## 2. Especificação Funcional

### 2.1. Fluxo de Criação da Corrente (Usuário 60+)

1.  **Início**: O usuário clica no botão "Criar Corrente" na aba "Destacar".
2.  **Modal de Seleção de Tipo**: 
    - O modal exibe os 6 tipos de post comuns.
    - Adicionalmente, exibe os 6 tipos de post do Memórias Vivas, identificados com o emoji do feed (ex: "📖 Memória", "💡 Conselho").
3.  **Escolha do Tipo**:
    - **Cenário A (Post Comum)**: Se o usuário escolhe um tipo de post comum, o fluxo segue normalmente, criando uma corrente pública.
    - **Cenário B (Post Memórias Vivas)**: Se o usuário escolhe um tipo de post do Memórias Vivas:
        - Uma nova corrente é criada no banco de dados com uma flag `is_memorias_vivas = true`.
        - O usuário é redirecionado para a página "Destacar".
4.  **Página "Destacar" (Pós-seleção)**:
    - O dropdown de **Feed** é automaticamente selecionado e **travado** em "📖 Memórias Vivas".
    - O campo de menção (`@nome_da_pessoa`) é substituído pelo campo **"Título"**.
    - O usuário não pode alterar o **Feed** nem o **Tipo de Post**, a menos que cancele a criação da corrente.
5.  **Publicação**: O usuário preenche o título, o conteúdo e publica o primeiro post, que se torna o início da corrente.

### 2.2. Fluxo de Interação

- **Usuário 60+**: Vê o post da corrente e o botão "Continuar esta corrente". Ao clicar, é levado à página de postagem com o **Feed** e o **Tipo de Post** travados para adicionar seu elo à história.
- **Usuário < 60**: Vê o post da corrente e todas as suas interações (reações, comentários), mas o botão "Continuar esta corrente" **não será visível ou estará desabilitado**, impedindo a participação.



---

## 3. Especificação Técnica

### 3.1. Banco de Dados

- **Tabela `chains`**:
    - Adicionar nova coluna: `is_memorias_vivas BOOLEAN DEFAULT false NOT NULL`.
    - **Nenhuma outra coluna é necessária**. A coluna `highlight_type` existente será usada para definir o tema da corrente.

### 3.2. Políticas de Segurança (RLS)

- **Policy de `SELECT` na tabela `chains`**:
    - A política existente `Correntes ativas e fechadas são públicas` já atende ao requisito de visibilidade universal. Nenhuma alteração é necessária, pois ela não discrimina com base em `is_memorias_vivas`.



- **Policy de `INSERT` na tabela `posts` (para Correntes)**:
    - A lógica para adicionar um post a uma corrente (`chain_id IS NOT NULL`) deve ser atualizada para impor a restrição de idade.
    - A nova policy deve verificar:
        - **SE** a corrente correspondente ao `chain_id` tiver `is_memorias_vivas = true`, **ENTÃO** a função `can_post_in_memorias_vivas(auth.uid())` deve retornar `true`.
        - **SENÃO** (se `is_memorias_vivas = false`), a inserção é permitida para qualquer usuário autenticado (comportamento padrão).

### 3.3. Frontend (index.html)

- **Modal "Criar Corrente" (`showChainModal`)**:
    - Adicionar lógica para verificar a idade do usuário (`calculateAge(currentUser.birth_date)`).
    - Se idade >= 60, renderizar os 6 tipos de post do Memórias Vivas no modal.

- **Função `createChain(postType)`**:
    - Se `postType` for do tipo Memórias Vivas, a chamada para a função de banco de dados `create_chain` deve passar um parâmetro adicional para setar `is_memorias_vivas = true`.

- **Renderização do Post no Feed**:
    - A lógica de renderização do post precisa ser ajustada para esconder o botão "Continuar esta corrente" se o post pertencer a uma corrente do Memórias Vivas (`chain.is_memorias_vivas = true`) e o usuário logado tiver menos de 60 anos.

- **Página "Destacar" (`populateDestacarDropdown`)**:
    - Ao carregar, verificar se `window.activeChain` existe e se é uma corrente do Memórias Vivas.
    - Se sim, travar os dropdowns de **Feed** (em "Memórias Vivas") e de **Tipo de Post** (no tipo da corrente) e desabilitá-los.
    - Adicionar um botão "Cancelar Corrente" que limpa `window.activeChain` e recarrega o formulário.

---

## 4. Plano de Implementação (Fases)

| Fase | Descrição | Estimativa |
|------|-----------|------------|
| **1** | **Banco de Dados**: Criar migração SQL para adicionar `is_memorias_vivas` à tabela `chains`. Atualizar a RLS policy de `INSERT` para a tabela `posts`. | 1.5 horas |
| **2** | **Backend**: Modificar a função `create_chain` para aceitar o novo parâmetro `is_memorias_vivas`. | 0.5 horas |
| **3** | **Frontend**: Atualizar a chamada da função `createChain` no JavaScript e implementar a lógica de visibilidade do botão "Continuar esta corrente". | 1.5 horas |
| **4** | **Testes**: Realizar testes completos de ponta a ponta, validando os cenários de criação (60+), participação (60+) e visualização (todos). | 1 hora |
| **Total** | | **4.5 horas** |
