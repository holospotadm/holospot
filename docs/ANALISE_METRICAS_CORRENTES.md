# 📊 ANÁLISE DE MÉTRICAS - INTEGRAÇÃO COM CORRENTES

> **Documento de Análise e Propostas**  
> HoloSpot - Dezembro 2024

---

## 📋 ÍNDICE

1. [Métricas Atuais do Modal Impacto Detalhado](#1-métricas-atuais-do-modal-impacto-detalhado)
2. [Dados Disponíveis de Correntes](#2-dados-disponíveis-de-correntes)
3. [Alterações Propostas nas Métricas Existentes](#3-alterações-propostas-nas-métricas-existentes)
4. [Novas Métricas Específicas de Correntes](#4-novas-métricas-específicas-de-correntes)
5. [Novas Métricas Gerais Utilizando Dados de Correntes](#5-novas-métricas-gerais-utilizando-dados-de-correntes)
6. [Priorização e Recomendações](#6-priorização-e-recomendações)

---

## 1. MÉTRICAS ATUAIS DO MODAL IMPACTO DETALHADO

### 1.1 Visão Geral

O modal "📊 Impacto Detalhado" apresenta **6 métricas principais**, **1 gráfico temporal** e **insights personalizados**.

### 1.2 Métricas Implementadas

| # | Métrica | Descrição | Cálculo |
|---|---------|-----------|---------|
| 1 | 🤝 **Reciprocidade Real** | % de pessoas que retribuíram seus destaques | `(pessoas que retribuíram / pessoas destacadas) × 100` |
| 2 | 💝 **Índice de Altruísmo** | Balanço entre dar e receber holofotes | `holofotes_dados : holofotes_recebidos` |
| 3 | ⚡ **Alcance Efetivo** | % de posts que geraram interação | `(posts com interação / total posts) × 100` |
| 4 | 🎯 **Taxa de Engajamento** | Média de interações por post | `total_interações / total_posts` |
| 5 | 🌐 **Impacto Médio** | Pessoas únicas alcançadas por post | `pessoas_únicas / total_posts` |
| 6 | 🔗 **Rede de Engajamento** | Total de pessoas conectadas | Soma de conexões únicas |

### 1.3 Gráfico Temporal

- **Período:** Últimos 30 dias
- **Dados:** Posts criados e Holofotes recebidos por dia
- **Tipo:** Gráfico de linha com área preenchida

### 1.4 Insights Personalizados

Sistema gera 6 insights automáticos baseados em faixas de avaliação:

| Métrica | Baixo | Médio | Alto |
|---------|-------|-------|------|
| Reciprocidade | < 40% | 40-70% | ≥ 70% |
| Engajamento | < 1.0 | 1.0-2.0 | ≥ 2.0 |
| Impacto | < 1.0 | 1.0-2.0 | ≥ 2.0 |
| Alcance | < 30% | 30-60% | ≥ 60% |
| Rede | < 5 | 5-15 | ≥ 15 |

---

## 2. DADOS DISPONÍVEIS DE CORRENTES

### 2.1 Estrutura de Dados

#### Tabela `chains`
```sql
id                  UUID        -- Identificador único
creator_id          UUID        -- Quem criou a corrente
name                TEXT        -- Nome da corrente
description         TEXT        -- Descrição
highlight_type      TEXT        -- Tipo de destaque fixo
status              TEXT        -- pending, active, closed
start_date          TIMESTAMPTZ -- Quando iniciou
end_date            TIMESTAMPTZ -- Quando fechou
first_post_id       UUID        -- Primeiro post
created_at          TIMESTAMPTZ -- Data de criação
```

#### Tabela `chain_posts`
```sql
id                    UUID        -- Identificador único
chain_id              UUID        -- Corrente associada
post_id               UUID        -- Post associado
author_id             UUID        -- Autor do post
parent_post_author_id UUID        -- Autor do post que originou (NULL = criador)
created_at            TIMESTAMPTZ -- Data de participação
```

#### Tabela `posts` (campo adicionado)
```sql
chain_id              UUID        -- Corrente à qual pertence (NULL = post normal)
```

### 2.2 Métricas Já Calculadas em `get_chain_info`

- `total_posts` - Total de posts na corrente
- `total_participants` - Participantes únicos

### 2.3 Dados Deriváveis

| Dado | Como Calcular |
|------|---------------|
| Correntes criadas por usuário | `COUNT(*) FROM chains WHERE creator_id = ?` |
| Correntes participadas | `COUNT(DISTINCT chain_id) FROM chain_posts WHERE author_id = ?` |
| Profundidade máxima | Recursão via `parent_post_author_id` |
| Co-participantes | Usuários que participaram das mesmas correntes |
| Taxa de sucesso | Correntes active / correntes criadas |

---

## 3. ALTERAÇÕES PROPOSTAS NAS MÉTRICAS EXISTENTES

### 3.1 🤝 Reciprocidade Real

#### Situação Atual
Conta apenas menções diretas: se A destacou B e B destacou A = recíproco.

#### Proposta de Alteração
**Incluir participações em correntes como forma de reciprocidade indireta.**

| Tipo de Reciprocidade | Descrição | Peso |
|-----------------------|-----------|------|
| Direta | A destacou B, B destacou A | 1.0 |
| Via Corrente | A criou corrente, B participou | 0.5 |

#### Novo Cálculo
```
Reciprocidade = (
    menções_diretas_recíprocas × 1.0 + 
    participações_em_minhas_correntes × 0.5
) / total_pessoas_que_destaquei
```

#### Impacto
- Aumenta reciprocidade para criadores de correntes populares
- Incentiva criação de correntes como forma de engajamento

---

### 3.2 💝 Índice de Altruísmo

#### Situação Atual
Compara holofotes dados vs recebidos (1:1).

#### Proposta de Alteração
**Ponderar correntes criadas como "dar multiplicado".**

| Ação | Peso |
|------|------|
| Post normal | 1x |
| Corrente criada | 2x ou 3x |
| Participação em corrente | 1x |

#### Novo Cálculo
```
Holofotes_Dados_Ponderado = posts_normais + (correntes_criadas × 2)
Altruísmo = Holofotes_Dados_Ponderado : Holofotes_Recebidos
```

#### Justificativa
Criar uma corrente demanda mais esforço e gera mais valor para a comunidade.

---

### 3.3 ⚡ Alcance Efetivo

#### Situação Atual
% de posts que geraram alguma interação.

#### Proposta de Alteração
**Exibir alcance separado para posts normais vs posts de corrente.**

#### Nova Visualização
```
Alcance Geral: 45%
├── Posts normais: 35%
└── Posts em correntes: 72%
```

#### Justificativa
Posts em correntes naturalmente têm maior engajamento; separar permite análise mais precisa.

---

### 3.4 🎯 Taxa de Engajamento

#### Situação Atual
`(reações + comentários + feedbacks) / total_posts`

#### Proposta de Alteração
**Incluir participações geradas em correntes que você criou.**

#### Novo Cálculo
```
Engajamento = (
    reações + comentários + feedbacks + 
    participações_em_minhas_correntes
) / total_posts
```

#### Impacto
Valoriza criadores de correntes que geram engajamento em cadeia.

---

### 3.5 🌐 Impacto Médio

#### Situação Atual
Pessoas únicas que interagiram / total de posts.

#### Proposta de Alteração
**Contar participantes de correntes como pessoas impactadas.**

#### Novo Cálculo
```
Pessoas_Impactadas = (
    pessoas_que_reagiram ∪ 
    pessoas_que_comentaram ∪ 
    participantes_das_minhas_correntes
)
Impacto = Pessoas_Impactadas / total_posts
```

---

### 3.6 🔗 Rede de Engajamento

#### Situação Atual
Conexões via menções e reações.

#### Proposta de Alteração
**Incluir 3 novos tipos de conexão via correntes.**

| Tipo de Conexão | Descrição |
|-----------------|-----------|
| Existente | Pessoas que você mencionou/reagiu |
| **Nova** | Participantes das suas correntes |
| **Nova** | Criadores de correntes que você participou |
| **Nova** | Co-participantes (mesma corrente) |

#### Impacto
Rede pode crescer significativamente com correntes ativas.

---

## 4. NOVAS MÉTRICAS ESPECÍFICAS DE CORRENTES

### 4.1 ⛓️ Poder de Corrente

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Capacidade de criar correntes que engajam |
| **Cálculo** | `média de participantes por corrente criada` |
| **Visualização** | Número + gráfico de barras por corrente |
| **Faixas** | Baixo (<3), Médio (3-10), Alto (>10) |
| **Insight** | "Suas correntes atraem em média X participantes" |

---

### 4.2 🌊 Profundidade de Propagação

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Nível máximo de propagação das suas correntes |
| **Cálculo** | Recursão via `parent_post_author_id` |
| **Exemplo** | Você → A → B → C = profundidade 3 |
| **Visualização** | Número ou mini-árvore |
| **Insight** | "Sua corrente mais viral alcançou X níveis" |

---

### 4.3 🏆 Índice de Iniciativa

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Proporção criar vs participar |
| **Cálculo** | `criadas / (criadas + participadas)` |
| **Faixas** | |
| | < 0.3 = "Seguidor" |
| | 0.3-0.7 = "Equilibrado" |
| | > 0.7 = "Líder" |

---

### 4.4 🎯 Taxa de Sucesso de Correntes

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | % de correntes que se tornaram ativas |
| **Cálculo** | `correntes_ativas / correntes_criadas × 100` |
| **Insight** | "X% das suas correntes ganharam participantes" |

---

### 4.5 🔄 Fidelidade de Correntes

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | % de participantes recorrentes |
| **Cálculo** | `participantes_em_2+_correntes / total_participantes` |
| **Insight** | "X% das pessoas voltam para suas correntes" |

---

### 4.6 🌈 Diversidade de Correntes

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Variedade de tipos de destaque |
| **Cálculo** | `COUNT(DISTINCT highlight_type)` |
| **Insight** | "Você participa de X tipos diferentes de correntes" |

---

## 5. NOVAS MÉTRICAS GERAIS UTILIZANDO DADOS DE CORRENTES

### 5.1 🌟 Índice de Influência Social

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Capacidade de mobilizar pessoas |
| **Componentes** | |
| | + Participantes em suas correntes |
| | + Pessoas que reagiram aos seus posts |
| | + Pessoas que você inspirou a criar correntes |
| **Cálculo** | Soma ponderada dos componentes |
| **Visualização** | Score de 0-100 |

---

### 5.2 📈 Momentum de Engajamento

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Tendência de crescimento do engajamento |
| **Cálculo** | `(engajamento_últimos_7_dias / engajamento_7_dias_anteriores) - 1` |
| **Inclui** | Reações + comentários + participações em correntes |
| **Visualização** | Seta ↑↓ com % |
| **Insight** | "Seu engajamento cresceu X% esta semana" |

---

### 5.3 🔗 Coeficiente de Conexão

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Qualidade das conexões (não apenas quantidade) |
| **Cálculo** | |
| | Conexões fortes = interações mútuas + co-participação em correntes |
| | Conexões fracas = interação única |
| | Coeficiente = fortes / (fortes + fracas) |
| **Insight** | "X% das suas conexões são fortes" |

---

### 5.4 🎭 Perfil de Engajamento

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Como você prefere engajar |
| **Dimensões** | |
| | Criador (cria correntes e posts) |
| | Participante (participa de correntes) |
| | Reator (reage e comenta) |
| | Conector (menciona muitas pessoas) |
| **Visualização** | Gráfico radar |

---

### 5.5 ⏱️ Velocidade de Resposta da Rede

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Quão rápido sua rede responde |
| **Cálculo** | Tempo médio entre post e primeira interação |
| **Inclui** | Reações, comentários, participações em correntes |
| **Insight** | "Sua rede responde em média em X horas" |

---

### 5.6 🌐 Alcance Viral

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Pessoas alcançadas indiretamente |
| **Cálculo** | |
| | Nível 1 = pessoas que você mencionou |
| | Nível 2 = pessoas que participaram das suas correntes |
| | Nível 3 = pessoas alcançadas pelos participantes |
| **Visualização** | Círculos concêntricos |

---

### 5.7 💎 Índice de Valor Gerado

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Valor total que você gera para a comunidade |
| **Componentes** | |
| | + Posts criados × peso |
| | + Correntes criadas × peso maior |
| | + Participações em correntes × peso |
| | + Reações dadas × peso menor |
| **Visualização** | Score único |

---

### 5.8 🤝 Índice de Colaboração

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Quanto você colabora com outros |
| **Cálculo** | |
| | + Participações em correntes de outros |
| | + Comentários construtivos |
| | + Feedbacks dados |
| | - Posts sem interação com outros |
| **Insight** | "Você é X% colaborativo" |

---

### 5.9 📊 Consistência de Engajamento

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Regularidade do engajamento ao longo do tempo |
| **Cálculo** | Desvio padrão das interações diárias |
| **Faixas** | |
| | Baixo desvio = Consistente |
| | Alto desvio = Irregular |
| **Insight** | "Você mantém engajamento consistente" |

---

### 5.10 🎯 Score de Relevância

| Aspecto | Descrição |
|---------|-----------|
| **O que mede** | Quão relevante você é para a comunidade |
| **Componentes** | |
| | + Correntes com alta participação |
| | + Posts com alto engajamento |
| | + Menções recebidas |
| | + Participações em correntes populares |
| **Visualização** | Ranking ou percentil |

---

## 6. PRIORIZAÇÃO E RECOMENDAÇÕES

### 6.1 Matriz de Priorização

| Métrica | Valor | Complexidade | Prioridade |
|---------|-------|--------------|------------|
| **Rede de Engajamento** (alteração) | Alto | Baixa | 🔴 Alta |
| **Poder de Corrente** | Alto | Baixa | 🔴 Alta |
| **Profundidade de Propagação** | Alto | Média | 🔴 Alta |
| **Índice de Iniciativa** | Médio | Baixa | 🟡 Média |
| **Taxa de Engajamento** (alteração) | Médio | Baixa | 🟡 Média |
| **Momentum de Engajamento** | Alto | Média | 🟡 Média |
| **Perfil de Engajamento** | Alto | Alta | 🟡 Média |
| **Coeficiente de Conexão** | Médio | Alta | 🟢 Baixa |
| **Alcance Viral** | Alto | Alta | 🟢 Baixa |
| **Score de Relevância** | Alto | Alta | 🟢 Baixa |

### 6.2 Recomendação de Implementação

#### Fase 1 - Quick Wins (1-2 dias)
1. Alterar **Rede de Engajamento** para incluir conexões via correntes
2. Implementar **Poder de Corrente** (média de participantes)
3. Implementar **Índice de Iniciativa** (criar vs participar)

#### Fase 2 - Métricas Intermediárias (3-5 dias)
4. Implementar **Profundidade de Propagação**
5. Alterar **Taxa de Engajamento** para incluir participações
6. Implementar **Momentum de Engajamento**

#### Fase 3 - Métricas Avançadas (1-2 semanas)
7. Implementar **Perfil de Engajamento** (gráfico radar)
8. Implementar **Alcance Viral** (círculos concêntricos)
9. Implementar **Score de Relevância**

### 6.3 Considerações Técnicas

| Aspecto | Recomendação |
|---------|--------------|
| **Performance** | Criar funções SQL otimizadas para cálculos complexos |
| **Cache** | Implementar cache para métricas que não mudam frequentemente |
| **Atualização** | Métricas simples = tempo real; Complexas = batch diário |
| **Visualização** | Usar Chart.js existente; adicionar gráfico radar |

### 6.4 Perguntas para Decisão

1. Implementar todas as alterações nas métricas existentes ou apenas algumas?
2. Criar seção separada "📊 Impacto em Correntes" ou integrar?
3. Quais novas métricas são prioritárias para o MVP?
4. Deseja gráficos específicos (árvore de propagação, radar)?

---

## 📎 ANEXOS

### A. Queries SQL de Referência

```sql
-- Correntes criadas por usuário
SELECT COUNT(*) FROM chains WHERE creator_id = ?;

-- Correntes participadas
SELECT COUNT(DISTINCT chain_id) FROM chain_posts WHERE author_id = ?;

-- Média de participantes por corrente
SELECT AVG(participant_count) FROM (
    SELECT chain_id, COUNT(DISTINCT author_id) as participant_count
    FROM chain_posts
    WHERE chain_id IN (SELECT id FROM chains WHERE creator_id = ?)
    GROUP BY chain_id
) sub;

-- Profundidade máxima (recursivo)
WITH RECURSIVE chain_depth AS (
    SELECT post_id, author_id, parent_post_author_id, 0 as depth
    FROM chain_posts WHERE parent_post_author_id IS NULL
    UNION ALL
    SELECT cp.post_id, cp.author_id, cp.parent_post_author_id, cd.depth + 1
    FROM chain_posts cp
    JOIN chain_depth cd ON cp.parent_post_author_id = cd.author_id
)
SELECT MAX(depth) FROM chain_depth WHERE chain_id = ?;
```

### B. Estrutura de Dados para Novas Métricas

```javascript
// Objeto de métricas expandido
const metricsWithChains = {
    // Métricas existentes (alteradas)
    reciprocity: { value: 0, includesChains: true },
    altruism: { given: 0, received: 0, chainBonus: 0 },
    reach: { normal: 0, chains: 0, combined: 0 },
    engagement: { base: 0, chainParticipations: 0, total: 0 },
    impact: { base: 0, chainParticipants: 0, total: 0 },
    network: { direct: 0, viaChains: 0, total: 0 },
    
    // Novas métricas de correntes
    chainPower: { average: 0, max: 0, total: 0 },
    propagationDepth: { max: 0, average: 0 },
    initiativeIndex: { created: 0, participated: 0, ratio: 0 },
    chainSuccessRate: { active: 0, total: 0, rate: 0 },
    
    // Novas métricas gerais
    socialInfluence: { score: 0, percentile: 0 },
    engagementMomentum: { current: 0, previous: 0, change: 0 },
    connectionCoefficient: { strong: 0, weak: 0, ratio: 0 },
    engagementProfile: { creator: 0, participant: 0, reactor: 0, connector: 0 }
};
```

---

*Documento gerado em Dezembro 2024*  
*HoloSpot - Plataforma de Reconhecimento Social*
