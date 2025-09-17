# 🎮 Dados Iniciais do Sistema

Este diretório contém todos os dados essenciais para inicialização do sistema de gamificação HoloSpot.

## 📋 Estrutura dos Arquivos

### 01_badges_initial_data.sql
**Badges do Sistema de Gamificação**
- 20 badges organizados por categoria e raridade
- Sistema completo de conquistas e marcos
- Condições específicas para desbloqueio
- Progressão equilibrada de 0 a 2.000 pontos

### 02_levels_initial_data.sql
**Níveis de Progressão do Usuário**
- 10 levels com faixas de pontos bem definidas
- Progressão de Novato (0 pontos) a Imortal (10.000+ pontos)
- Cores e ícones únicos para cada nível
- Benefícios crescentes por nível

## 🏆 Sistema de Badges

### Categorias (4 tipos)
- **Milestone (6 badges):** Marcos importantes na jornada
- **Engagement (8 badges):** Atividade e engajamento
- **Social (3 badges):** Interação social e popularidade
- **Special (3 badges):** Conquistas especiais e únicas

### Raridades (5 níveis)
- **Common (8 badges):** Conquistas básicas e acessíveis
- **Uncommon (2 badges):** Atividade moderada
- **Rare (6 badges):** Engajamento consistente
- **Epic (2 badges):** Conquistas significativas
- **Legendary (2 badges):** Elite do sistema

### Progressão de Badges
```
Marcos Iniciais (0 pontos)
├── Primeiro Post 📝
├── Primeira Reação 👍
├── Primeiro Holofote 🌟
└── Primeira Interação 🎉

Engajamento Básico (100-200 pontos)
├── Engajador 💪 (50 reações)
├── Comentarista 💬 (25 comentários)
├── Consistente 📅 (7 dias streak)
└── Ativo 📖 (10 posts)

Atividade Regular (300-500 pontos)
├── Super Engajador 🔥 (200 reações)
├── Conversador 🗣️ (100 comentários)
├── Dedicado 🔥 (30 dias streak)
└── Feedback Master 📝 (50 feedbacks)

Conquistas Avançadas (600-1000 pontos)
├── Mentor 🧭 (25 pessoas destacadas)
├── Querido 💖 (500 reações recebidas)
├── Prolífico 📚 (50 posts)
└── Embaixador 🤝 (10 referrals)

Elite do Sistema (1500-2000 pontos)
├── Incansável 💎 (100 dias streak)
├── Influenciador 📈 (1000 interações)
└── Pioneiro 🚀 (early adopter)
```

## 📊 Sistema de Levels

### Progressão de Níveis
```
🌱 Novato (0-99 pontos)
└── Acesso básico

🔍 Iniciante (100-299 pontos)
└── Badge personalizado

⚡ Ativo (300-599 pontos)
└── Destaque no perfil

🤝 Engajado (600-999 pontos)
└── Estatísticas avançadas

📢 Influente (1000-1499 pontos)
└── Destaque especial nos posts

🎯 Expert (1500-2499 pontos)
└── Funcionalidades beta

🧭 Mentor (2500-3999 pontos)
└── Moderação de conteúdo

👑 Líder (4000-6999 pontos)
└── Criação de eventos

⭐ Lenda (7000-9999 pontos)
└── Hall da fama

💎 Imortal (10000+ pontos)
└── Status permanente
```

### Distribuição Esperada
- **60% dos usuários:** Novato-Ativo (0-599 pontos)
- **30% dos usuários:** Engajado-Influente (600-1499 pontos)
- **10% dos usuários:** Expert+ (1500+ pontos)

## 🚀 Deployment

### Ordem de Execução
1. **Criar tabelas** (usar arquivos de schema primeiro)
2. **01_badges_initial_data.sql** - Inserir badges
3. **02_levels_initial_data.sql** - Inserir levels
4. **Verificar integridade** dos dados

### Comandos de Deployment
```sql
-- Executar após criação das tabelas
\i sql/data/01_badges_initial_data.sql
\i sql/data/02_levels_initial_data.sql

-- Verificar inserção
SELECT COUNT(*) FROM badges; -- Deve retornar 20
SELECT COUNT(*) FROM levels; -- Deve retornar 10
```

### Verificações de Integridade
```sql
-- Verificar badges por categoria
SELECT category, COUNT(*) 
FROM badges 
GROUP BY category;

-- Verificar levels por faixa
SELECT name, min_points, max_points 
FROM levels 
ORDER BY points_required;

-- Verificar gaps nos levels
SELECT 
    l1.name as level_atual,
    l1.max_points as max_atual,
    l2.name as proximo_level,
    l2.min_points as min_proximo,
    (l2.min_points - l1.max_points) as gap
FROM levels l1
JOIN levels l2 ON l2.points_required > l1.points_required
WHERE NOT EXISTS (
    SELECT 1 FROM levels l3 
    WHERE l3.points_required > l1.points_required 
    AND l3.points_required < l2.points_required
)
ORDER BY l1.points_required;
```

## 🎯 Configuração de Produção

### Badges Ativos
Todos os 20 badges estão marcados como `is_active = true` por padrão.

### Ajustes Recomendados
- **Pontos necessários:** Ajustar baseado no comportamento real dos usuários
- **Condições:** Refinar valores baseado em métricas de engajamento
- **Novos badges:** Adicionar baseado em feedback da comunidade

### Monitoramento
- **Taxa de desbloqueio:** Quantos usuários conseguem cada badge
- **Tempo médio:** Quanto tempo leva para alcançar cada nível
- **Distribuição:** Como os usuários se distribuem pelos níveis

## 📈 Métricas de Sucesso

### Badges
- **Taxa de primeiro badge:** % de usuários que desbloqueiam pelo menos 1 badge
- **Badges por usuário:** Média de badges por usuário ativo
- **Progressão:** % de usuários que avançam de common para rare+

### Levels
- **Retenção por nível:** Taxa de retenção em cada nível
- **Tempo de progressão:** Tempo médio entre níveis
- **Distribuição:** % de usuários em cada faixa de nível

## 🔧 Manutenção

### Atualizações Futuras
- Novos badges baseados em funcionalidades
- Ajustes de balanceamento
- Eventos especiais e badges temporários
- Expansão do sistema de levels

### Backup
Estes dados são críticos para o funcionamento do sistema. Sempre fazer backup antes de modificações.

---

**Última Atualização:** Setembro 2025  
**Versão:** 1.0.0  
**Status:** Produção

