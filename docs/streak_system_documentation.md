# Documentação Completa do Sistema de Streak

## Visão Geral

O sistema de streak foi projetado para incentivar o engajamento diário dos usuários. Ele rastreia dias consecutivos de atividade, recompensa os usuários com pontos bônus ao atingir marcos (milestones) e fornece notificações para mantê-los engajados.

## Componentes Principais

O sistema é composto por:

- **Tabela `user_streaks`**: Armazena o estado atual do streak de cada usuário.
- **Funções SQL**: Lógica para calcular, atualizar e recompensar streaks.
- **Triggers de Banco de Dados**: Disparam a atualização do streak após atividades.
- **Código Frontend**: Exibe o streak e as notificações para o usuário.

---

## 1. Como o Streak é Contabilizado

### a. Definição de "Atividade"

Uma "atividade" que conta para o streak é definida como qualquer uma das seguintes ações **realizadas pelo usuário**:

- **Criar um post** (`posts.user_id`)
- **Escrever um comentário** (`comments.user_id`)
- **Dar um feedback** (`feedbacks.mentioned_user_id`)
- **Adicionar uma reação** (`reactions.user_id`)

**Importante:** Apenas ações **ativas** do usuário contam para o streak. Ações recebidas de outros usuários (como comentários recebidos, reações recebidas) **NÃO** contam para o streak.

### b. Lógica de Contagem de Dias Consecutivos

A função principal para isso é a `update_user_streak_incremental`. Ela é chamada automaticamente sempre que um usuário realiza uma das atividades acima.

A lógica segue 4 cenários:

| Cenário | Condição | Ação |
| :--- | :--- | :--- |
| **1. Primeira Atividade** | Não há registro de streak para o usuário. | `current_streak` é definido como **1**. |
| **2. Atividade no Mesmo Dia** | A última atividade foi no mesmo dia da atividade atual. | O streak **não muda**. |
| **3. Atividade Consecutiva** | A última atividade foi no dia anterior. | `current_streak` é **incrementado em 1**. |
| **4. Streak Quebrado** | A última atividade foi antes de ontem. | `current_streak` é **resetado para 1**. |

**Importante:** A lógica leva em conta o **fuso horário (timezone)** do usuário, garantindo que o dia termine e comece na hora certa para cada um.

---

## 2. Ativação de Milestones e Bônus

### a. Detecção de Milestones

Quando o `current_streak` é incrementado (Cenário 3), o sistema verifica se um novo milestone foi atingido. Os milestones são:

- **7 dias**
- **30 dias**
- **182 dias** (6 meses)
- **365 dias** (1 ano)

A detecção ocorre na função `update_user_streak_incremental` e a variável `milestone_reached` é definida como `true`.

### b. Notificação de Milestone

Um trigger na tabela `user_streaks` (`handle_streak_notification_only`) detecta a mudança no `current_streak` e, se um milestone foi atingido, chama a função `notify_streak_milestone_correct` para criar uma notificação para o usuário.

### c. Cálculo dos Pontos Bônus

Quando `milestone_reached` é `true`, a função `apply_streak_bonus_retroactive` é chamada. Ela faz o seguinte:

1. **Calcula o bônus**: Chama a função `calculate_streak_bonus`.
2. **Valida o bônus**: Verifica se o bônus já foi aplicado recentemente.
3. **Insere os pontos**: Adiciona os pontos no `points_history`.
4. **Atualiza o total**: Chama `recalculate_user_points_secure` para atualizar o total de pontos do usuário.

### d. Lógica de Cálculo do Bônus

A função `calculate_streak_bonus` calcula o bônus da seguinte forma:

| Milestone | Bônus |
| :--- | :--- |
| **7 dias** | **+20%** dos pontos ganhos nos últimos 7 dias |
| **30 dias** | **+50%** dos pontos ganhos nos últimos 30 dias |
| **182 dias** | **+80%** dos pontos ganhos nos últimos 182 dias |
| **365 dias** | **+100%** dos pontos ganhos nos últimos 365 dias |

**Exemplo:** Se um usuário atinge 7 dias de streak e ganhou **100 pontos** nesses 7 dias, ele recebe um bônus de **20 pontos** (100 * 0.20).

#### Quais Pontos São Incluídos no Cálculo?

O bônus é calculado com base em **TODOS os pontos** do usuário no período, incluindo:

**Ações do Usuário:**
- `post_created` (10 pts)
- `comment_given` (7 pts)
- `reaction_given` (3 pts)
- `feedback_given` (10 pts)
- `holofote_given` (20 pts)

**Ações Recebidas de Outros:**
- `comment_received` (5 pts)
- `reaction_received` (2 pts)
- `feedback_received` (8 pts)
- `holofote_received` (15 pts)

**Conquistas:**
- `badge_earned` (variável)

**Pontos EXCLUÍDOS:**
- `streak_bonus` (para evitar duplicação)
- `streak_bonus_retroactive` (para evitar duplicação)
- `streak_bonus_correction` (para evitar duplicação)

**Resumo:** O streak incentiva o usuário a **ser ativo**, mas o bônus recompensa tanto a **atividade** quanto o **engajamento recebido**.

### e. Validação de Bônus (Correção Importante)

Conforme sua sugestão, a validação foi corrigida para permitir que o usuário receba o bônus novamente em **streaks diferentes**.

A função `apply_streak_bonus_retroactive` agora verifica se o bônus já foi aplicado **nos últimos X dias**, com uma margem de segurança:

| Milestone | Período de Verificação |
| :--- | :--- |
| **7 dias** | Últimos **10 dias** |
| **30 dias** | Últimos **35 dias** |
| **182 dias** | Últimos **190 dias** |
| **365 dias** | Últimos **370 dias** |

Isso garante que, se um usuário quebrar o streak e começar um novo, ele **poderá receber o bônus novamente** ao atingir o mesmo milestone.

---

## 3. Fluxo Completo (Exemplo: Comentário)

1. **Usuário faz um comentário.**
2. O código frontend chama a função `addComment`.
3. Após o comentário ser salvo, a função `checkStreakAfterActivity('comment_added')` é chamada.
4. `checkStreakAfterActivity` chama a função SQL `update_user_streak_with_data`.
5. `update_user_streak_with_data` chama `update_user_streak_incremental`.
6. `update_user_streak_incremental`:
   - Incrementa o `current_streak` de 6 para 7.
   - Detecta que o milestone de 7 dias foi atingido (`milestone_reached = true`).
   - Chama `apply_streak_bonus_retroactive`.
7. `apply_streak_bonus_retroactive`:
   - Calcula o bônus (ex: 28 pontos).
   - Verifica se o bônus de 7 dias já foi aplicado nos últimos 10 dias.
   - Se não, insere **28 pontos** no `points_history`.
   - Chama `recalculate_user_points_secure` para adicionar 28 ao total de pontos do usuário.
8. O trigger `handle_streak_notification_only` na tabela `user_streaks` é disparado e cria a notificação de milestone.
9. O frontend recebe a confirmação e exibe o streak atualizado e a notificação.

Espero que esta documentação detalhada ajude a esclarecer todo o fluxo!


---

## 4. Triggers de Banco de Dados

O sistema utiliza triggers para automatizar a atualização do streak após cada atividade.

### a. Trigger `update_user_streak_trigger`

Este trigger é associado às tabelas:
- `posts`
- `comments`
- `feedbacks`
- `reactions`

**Quando é disparado:** Após a inserção de um novo registro (`AFTER INSERT`).

**O que faz:** Chama a função `update_user_streak` (que internamente chama `update_user_streak_incremental`) para o usuário que realizou a atividade.

**Observação especial para feedbacks:** Para a tabela `feedbacks`, o trigger atualiza o streak tanto do autor (`author_id`) quanto do usuário mencionado (`mentioned_user_id`), pois ambos estão participando da interação.

### b. Trigger `handle_streak_notification_only`

Este trigger é associado à tabela `user_streaks`.

**Quando é disparado:** Após uma atualização (`AFTER UPDATE`).

**O que faz:**
- Verifica se o `current_streak` atingiu um novo milestone.
- Se sim, chama `notify_streak_milestone_correct` para criar uma notificação.

**Lógica de detecção:** Compara o valor antigo (`OLD.current_streak`) com o novo (`NEW.current_streak`) para identificar se um milestone foi ultrapassado.

---

## 5. Código Frontend

O código frontend é responsável por:
- Exibir o streak atual do usuário.
- Chamar a atualização do streak após atividades.
- Mostrar notificações de milestone.
- Executar debug automático (em desenvolvimento).

### a. Função `checkStreakAfterActivity`

Esta função é chamada após cada atividade. Ela:

1. Chama a função SQL `update_user_streak_with_data` via RPC do Supabase.
2. Recebe o resultado com:
   - `current_streak`: Streak atual.
   - `longest_streak`: Maior streak já alcançado.
   - `last_activity_date`: Data da última atividade.
   - `milestone_reached`: Se um milestone foi atingido.
   - `milestone_value`: Qual milestone foi atingido.
   - `bonus_points`: Pontos bônus calculados.
3. Atualiza a interface com o novo streak.
4. Se `milestone_reached` for `true`, executa o debug automático (em desenvolvimento).

### b. Onde `checkStreakAfterActivity` é chamada

A função é chamada após:

- **Criar um post**: `await checkStreakAfterActivity('post_created');`
- **Escrever um comentário**: `await checkStreakAfterActivity('comment_added');`
- **Dar um feedback**: `await checkStreakAfterActivity('feedback_given');`
- **Adicionar uma reação**: `await checkStreakAfterActivity('reaction_added');`

### c. Debug Automático

Quando o streak atinge 7 dias ou mais, o sistema executa automaticamente a função `debug_streak_bonus` para verificar:

- Quantos pontos foram ganhos no período.
- Quanto bônus foi calculado.
- Se o bônus será inserido ou não.
- Motivo se não for inserido.

Isso é útil para desenvolvimento e diagnóstico de problemas.

---

## 6. Tabela `user_streaks`

A tabela `user_streaks` armazena o estado atual do streak de cada usuário.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `user_id` | UUID | ID do usuário (chave primária). |
| `current_streak` | INTEGER | Número de dias consecutivos de atividade. |
| `longest_streak` | INTEGER | Maior streak já alcançado pelo usuário. |
| `last_activity_date` | DATE | Data da última atividade registrada. |
| `next_milestone` | INTEGER | Próximo milestone a ser atingido (7, 30, 182 ou 365). |
| `updated_at` | TIMESTAMP | Data e hora da última atualização. |

---

## 7. Funções SQL Principais

### a. `update_user_streak_incremental`

**Descrição:** Atualiza o streak de forma incremental (100x mais rápido que a versão antiga).

**Parâmetros:**
- `p_user_id`: UUID do usuário.

**Retorna:** Uma tabela com:
- `current_streak`
- `longest_streak`
- `last_activity_date`
- `milestone_reached`
- `milestone_value`
- `bonus_points`

**Lógica:** Implementa os 4 cenários descritos na seção 1.b.

### b. `apply_streak_bonus_retroactive`

**Descrição:** Aplica o bônus de pontos quando um milestone é atingido.

**Parâmetros:**
- `p_user_id`: UUID do usuário.

**Lógica:**
1. Busca o `current_streak` do usuário.
2. Determina qual milestone foi atingido.
3. Calcula o bônus usando `calculate_streak_bonus`.
4. Verifica se o bônus já foi aplicado nos últimos X dias.
5. Se não, insere os pontos no `points_history`.
6. Atualiza o total de pontos do usuário.

### c. `calculate_streak_bonus`

**Descrição:** Calcula o valor do bônus baseado no milestone e nos pontos ganhos no período.

**Parâmetros:**
- `p_user_id`: UUID do usuário.
- `p_milestone`: Milestone atingido (7, 30, 182 ou 365).

**Retorna:** Número inteiro com o valor do bônus.

**Lógica:**
1. Define o multiplicador baseado no milestone.
2. Busca os pontos ganhos nos últimos X dias (excluindo bônus anteriores).
3. Calcula: `bônus = pontos_do_período × (multiplicador - 1)`.

### d. `notify_streak_milestone_correct`

**Descrição:** Cria uma notificação quando um milestone é atingido.

**Parâmetros:**
- `p_user_id`: UUID do usuário.
- `p_milestone_days`: Milestone atingido.
- `p_bonus_points`: Pontos bônus (opcional).

**Lógica:** Insere uma notificação na tabela `notifications` com tipo `streak_milestone`.

### e. `recalculate_user_points_secure`

**Descrição:** Recalcula o total de pontos do usuário somando todos os registros de `points_history`.

**Parâmetros:**
- `p_user_id`: UUID do usuário.

**Retorna:** Total de pontos.

**Lógica:** Soma todos os `points_earned` do usuário e atualiza a tabela `user_points`.

### f. `debug_streak_bonus`

**Descrição:** Função de debug que retorna JSON com todas as informações do cálculo de bônus.

**Parâmetros:**
- `p_user_id`: UUID do usuário.

**Retorna:** JSON com:
- `current_streak`
- `milestone`
- `days_back`
- `check_days`
- `multiplier`
- `points_period`
- `calculation`
- `bonus_points`
- `already_applied`
- `will_insert`
- `reason_not_insert`

---

## 8. Cenários Especiais

### a. Usuário Quebra o Streak

Quando um usuário não realiza nenhuma atividade por 2 ou mais dias:

1. O `current_streak` é resetado para **1** na próxima atividade.
2. O `longest_streak` é preservado.
3. O `next_milestone` volta para **7**.

### b. Usuário Atinge o Mesmo Milestone Novamente

Graças à correção implementada, se um usuário:

1. Atinge 7 dias → recebe 28 pontos.
2. Quebra o streak.
3. Passa mais de 10 dias.
4. Atinge 7 dias novamente → **recebe 28 pontos de novo**.

Isso é possível porque a validação verifica apenas os últimos X dias, não para sempre.

### c. Múltiplas Atividades no Mesmo Dia

Se um usuário faz várias atividades no mesmo dia:

- O streak **não é incrementado** nas atividades subsequentes.
- A função retorna `milestone_reached: false`.
- Apenas a **primeira atividade do dia** pode incrementar o streak.

---

## 9. Esclarecimento Importante: Estrutura da Tabela Feedbacks

A tabela `feedbacks` tem uma estrutura que pode causar confusão. É importante entender corretamente os campos:

### Estrutura da Tabela

```sql
CREATE TABLE feedbacks (
    id BIGINT PRIMARY KEY,
    post_id UUID,              -- Post sobre o qual o feedback é dado
    author_id UUID,            -- AUTOR DO POST (não do feedback!)
    mentioned_user_id UUID,    -- USUÁRIO MENCIONADO = AUTOR DO FEEDBACK
    feedback_text TEXT,
    created_at TIMESTAMPTZ
);
```

### Como Funciona

**Exemplo prático:**

1. João cria um post mencionando Maria (`@maria`)
2. Maria dá um feedback sobre o post de João
3. Registro criado na tabela `feedbacks`:
   - `post_id` = ID do post do João
   - `author_id` = **João** (autor do post, quem recebe o feedback)
   - `mentioned_user_id` = **Maria** (mencionada no post, quem deu o feedback)
   - `feedback_text` = texto do feedback escrito por Maria

### Mapeamento de Campos

| Campo | Representa | Exemplo |
|:---|:---|:---|
| `author_id` | Autor do **post** (quem **recebe** o feedback) | João |
| `mentioned_user_id` | Usuário mencionado (quem **dá** o feedback) | Maria |

### Pontuação

Quando Maria dá feedback no post de João:

- **Maria ganha 10 pontos** (`feedback_given`) → identificada por `mentioned_user_id`
- **João ganha 8 pontos** (`feedback_received`) → identificado por `author_id`

### Contabilização no Streak

Para verificar se um usuário deu feedback em um dia:

```sql
SELECT COUNT(*) FROM feedbacks 
WHERE mentioned_user_id = p_user_id  -- Usuário que DEU o feedback
AND (created_at AT TIME ZONE timezone)::DATE = data_verificada;
```

**Nota importante:** `mentioned_user_id` identifica quem **escreveu** o feedback, não quem recebeu.

---

## 10. Resumo do Fluxo Completo

```
[Usuário faz atividade]
        ↓
[Trigger dispara update_user_streak_trigger]
        ↓
[Chama update_user_streak_incremental]
        ↓
[Verifica cenário: Primeira / Mesmo Dia / Consecutivo / Quebrado]
        ↓
[Atualiza current_streak na tabela user_streaks]
        ↓
[Se milestone atingido] → [Chama apply_streak_bonus_retroactive]
        ↓
[Calcula bônus via calculate_streak_bonus]
        ↓
[Verifica se já foi aplicado nos últimos X dias]
        ↓
[Se não] → [Insere pontos no points_history]
        ↓
[Chama recalculate_user_points_secure]
        ↓
[Atualiza total de pontos do usuário]
        ↓
[Trigger handle_streak_notification_only dispara]
        ↓
[Cria notificação de milestone]
        ↓
[Frontend exibe streak atualizado e notificação]
```

---

## 11. Considerações de Performance

### a. Lógica Incremental

A função `update_user_streak_incremental` foi criada para substituir a antiga `calculate_user_streak`, que era extremamente lenta (1460 queries).

A versão incremental faz apenas **2 queries**:
1. Buscar o estado atual do streak.
2. Atualizar o estado.

Isso resulta em uma performance **100x mais rápida**.

### b. Recálculo do Zero

A função `recalculate_user_streak_from_scratch` ainda existe para casos especiais onde é necessário recalcular o histórico completo, mas **não deve ser usada em produção** devido à sua lentidão.

### c. Recálculo em Massa

A função `recalculate_all_users_streaks` permite recalcular o streak de **todos os usuários** de uma vez. Deve ser usada apenas em situações excepcionais, como após uma mudança na lógica do sistema.

---

## 12. Pontos de Atenção

### a. Fuso Horário

O sistema usa o `timezone` armazenado na tabela `profiles` para determinar o dia correto para cada usuário. Isso garante que um usuário no Brasil e outro no Japão tenham seus dias calculados corretamente.

### b. Validação de Bônus

A validação de bônus foi corrigida para permitir múltiplos streaks. Certifique-se de que a migration `20241203_fix_streak_bonus_validation_multiple_streaks.sql` foi executada.

### c. Debug Automático

O debug automático está ativo apenas quando `current_streak >= 7`. Ele pode ser desativado removendo o código correspondente no frontend.

---

## 13. Melhorias Futuras

Algumas melhorias que podem ser implementadas:

- **Notificações de Lembrete**: Avisar o usuário quando ele está prestes a perder o streak.
- **Visualização de Histórico**: Mostrar um gráfico com o histórico de streaks do usuário.
- **Badges de Streak**: Conceder badges especiais para streaks longos.
- **Competição de Streaks**: Ranking de usuários com maiores streaks.

---

**Autor:** Manus AI  
**Data:** 03 de Dezembro de 2025  
**Versão:** 1.0
