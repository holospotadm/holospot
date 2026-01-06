# 🏛️ Especificação da Funcionalidade: Memórias Vivas

**Autor**: Manus AI  
**Data**: 29 de dezembro de 2025  
**Versão**: 1.1

---

## 1. Visão Geral e Conceito

A funcionalidade **Memórias Vivas** é uma nova seção no HoloSpot dedicada a honrar e preservar a sabedoria, as histórias e as memórias dos membros mais velhos da nossa comunidade. O objetivo é criar um espaço onde pessoas com 60 anos ou mais possam compartilhar suas experiências de vida, e onde todos os outros membros possam ler, aprender e se conectar com essas narrativas.

### 1.1. Conceito Principal

- **Um feed especial**: "Memórias Vivas" funcionará como um feed de comunidade, visível para todos os usuários.
- **Restrição de postagem**: Apenas usuários com 60 anos ou mais poderão criar posts neste feed.
- **Interação aberta**: Todos os usuários, independentemente da idade, poderão reagir e comentar nos posts.
- **Feedback Especial (60+)**: Qualquer usuário com 60+ anos poderá dar um "Feedback" em um post do feed, destacando sua perspectiva e criando um diálogo entre os mais velhos.
- **Valorização**: O objetivo é criar um ambiente de respeito, aprendizado e conexão intergeracional.

### 1.2. Justificativa

Em nossa sociedade, muitas vezes as histórias e a sabedoria dos idosos são subvalorizadas. Esta funcionalidade busca:

- **Incentivar a atividade mental e social** dos idosos.
- **Preservar memórias** que de outra forma poderiam ser perdidas.
- **Criar pontes** entre diferentes gerações.
- **Enriquecer a comunidade** com perspectivas e experiências de vida únicas.

---

## 2. Especificações Funcionais

### 2.1. Acesso e Visibilidade

- **Acesso Universal**: O feed "Memórias Vivas" será visível para todos os usuários logados no HoloSpot.
- **Visibilidade Condicional de Postagem**: O botão/opção para criar um post no feed "Memórias Vivas" só aparecerá para usuários cuja idade, calculada a partir de `profiles.birth_date`, seja igual ou superior a 60 anos.

### 2.2. Interface do Usuário (UI)

- **Nome do Feed**: Memórias Vivas
- **Ícone/Emoji**: 📖 (Livro Aberto)
- **Identificação do Autor**: Nos posts deste feed, a idade do autor será exibida ao lado do nome. Ex: `Maria Silva • 72 anos`.
- **Formulário de Postagem**: Ao selecionar o feed "Memórias Vivas", o campo de menção (`@nome_da_pessoa`) será substituído por um campo **"Título"**.

### 2.3. Tipos de Post Específicos

Ao criar um post no feed "Memórias Vivas", o usuário poderá categorizá-lo com um dos seguintes tipos:

| Tipo | Emoji | Descrição |
|---|---|---|
| **Memória** | 💭 | Uma lembrança específica do passado |
| **Conselho** | 💡 | Sabedoria de vida para compartilhar |
| **Época de Ouro** | ✨ | Como era a vida antigamente |
| **História** | 📜 | Qualquer história, não apenas de família |
| **Lição de Vida** | 📚 | Aprendizado importante que tiveram |
| **Tradição** | 🎭 | Costumes, festas, receitas de família |

### 2.4. Sistema de Feedback Especial (60+)

- **Quem pode dar Feedback**: Qualquer usuário com 60+ anos.
- **Onde**: Em qualquer post do feed "Memórias Vivas".
- **Múltiplos Feedbacks**: Um post poderá ter múltiplos feedbacks de diferentes usuários 60+.
- **Destaque**: Os feedbacks terão um destaque visual em relação aos comentários comuns.

### 2.5. Gamificação Especial

Serão criados novos emblemas (badges) para incentivar a participação:

**Badges para quem POSTA (60+):**

| Badge | Nome | Critério |
|---|---|---|
| 📖 | **Contador de Histórias** | Primeiro post no feed "Memórias Vivas" |
| 🏛️ | **Guardião de Memórias** | 10 posts no feed |
| 👑 | **Sábio** | 50 posts no feed |
| ⭐ | **Inspirador** | Recebeu 100+ reações em posts do feed |

**Badges para quem INTERAGE (qualquer idade):**

| Badge | Nome | Critério |
|---|---|---|
| 👂 | **Ouvinte** | Reagiu a 10 posts do feed |
| 💬 | **Curioso** | Comentou em 10 posts do feed |
| 🤝 | **Conectado às Raízes** | Interagiu com 50 posts |
| 💖 | **Honrador** | Reagiu a 100 posts do feed |

---

## 3. Especificações Técnicas

### 3.1. Banco de Dados (Supabase)

**Tabela `communities`:**

- Adicionar uma nova comunidade:
  - `id`: UUID (gerado automaticamente)
  - `name`: `Memórias Vivas`
  - `description`: `Um espaço para compartilhar e honrar as histórias e sabedorias dos nossos membros com 60+ anos.`
  - `emoji`: `📖`
  - `is_age_restricted`: `true` (nova coluna booleana)
  - `min_age_to_post`: `60` (nova coluna integer)
  - `allow_multiple_feedbacks`: `true` (nova coluna booleana)

**Tabela `posts`:**

- A coluna `mentioned_user_id` será `NULL` para posts no feed "Memórias Vivas".
- A coluna `title` (já existente) será usada para o título do post.

**Tabela `badges`:**

- Adicionar os 8 novos emblemas com seus respectivos critérios.

### 3.2. Políticas de Segurança (RLS)

**Tabela `posts`:**

- **Política de INSERT (para a comunidade "Memórias Vivas")**:
  - **Nome**: `Allow 60+ to post in Memórias Vivas`
  - **Ação**: `INSERT`
  - **Condição**: `(community_id = <ID_DA_COMUNIDADE>) AND (SELECT calculate_age(birth_date) FROM public.profiles WHERE id = auth.uid()) >= 60`

**Tabela `feedbacks`:**

- **Política de INSERT (para posts do "Memórias Vivas")**:
  - **Nome**: `Allow 60+ to give feedback in Memórias Vivas`
  - **Ação**: `INSERT`
  - **Condição**: `(post_id IN (SELECT id FROM public.posts WHERE community_id = <ID_DA_COMUNIDADE>)) AND (SELECT calculate_age(birth_date) FROM public.profiles WHERE id = auth.uid()) >= 60`

### 3.3. Frontend (index.html)

**Formulário de Criação de Post:**

- **Visibilidade do Feed**: A opção "Memórias Vivas" no dropdown de comunidades só será visível se `calculate_age(currentUser.birth_date) >= 60`.
- **Campo de Título**: Ao selecionar o feed "Memórias Vivas", o campo de menção (`@nome_da_pessoa`) será substituído por um campo **"Título"**.

**Renderização de Posts:**

- **Idade do Autor**: Exibir a idade do autor nos posts do feed.
- **Botão de Feedback**: Para posts do feed "Memórias Vivas", o botão "Dar Feedback" será visível para todos os usuários 60+.

### 3.4. Funções do Banco (PostgreSQL)

- **`calculate_age(DATE)`**: Função já existente.
- **Novas funções para badges**: Criar funções de trigger para conceder os novos emblemas.

---

## 4. Plano de Implementação (Fases)

1. **Fase 1: Banco de Dados**
   - Criar migração SQL para:
     - Adicionar colunas `is_age_restricted`, `min_age_to_post`, `allow_multiple_feedbacks` na tabela `communities`.
     - Inserir a comunidade "Memórias Vivas".
     - Adicionar os 8 novos emblemas na tabela `badges`.
     - Criar as novas policies RLS para `posts` e `feedbacks`.

2. **Fase 2: Frontend - Lógica de Postagem**
   - Implementar a lógica de visibilidade condicional no formulário de criação de post.
   - Implementar a troca do campo de menção para título.

3. **Fase 3: Frontend - Visualização e Feedback**
   - Adicionar o feed "Memórias Vivas" no menu.
   - Implementar a exibição da idade do autor.
   - Implementar a lógica do botão "Dar Feedback" para usuários 60+.

4. **Fase 4: Gamificação**
   - Criar as funções de trigger no banco para conceder os novos emblemas.

5. **Fase 5: Testes e Lançamento**
   - Testar todos os cenários.

---

Este documento serve como um guia completo para a implementação da funcionalidade "Memórias Vivas". Qualquer alteração no escopo deve ser refletida aqui.
