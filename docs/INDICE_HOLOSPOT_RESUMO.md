# Índice HoloSpot - Resumo para Implementação

## Definição
Métrica única que combina todas as dimensões de bem-estar social.

## Fórmula Integrada
```
Índice_HoloSpot = (
    Positividade_Recebida × 0.30 +
    Reciprocidade × 0.25 +
    Impacto_Gerado × 0.25 +
    Evolução_Engajamento × 0.20
) × Fator_Tempo × Fator_Consistência
```

## Componentes

### 1. Positividade Recebida (30%)
- **Posts Recebidos (PR)**: 25% - Número de posts destacando o usuário
- **Diversidade de Destacadores (DD)**: 30% - Pessoas únicas que destacaram
- **Consistência Temporal (CT)**: 25% - Regularidade do reconhecimento
- **Variedade de Tipos (VT)**: 20% - Tipos de destaque recebidos

### 2. Reciprocidade Social (25%)
- **Reciprocidade Direta (RD)**: 40% - Relacionamentos bidirecionais
- **Reciprocidade Indireta (RI)**: 20% - Conexões A→B→C→A
- **Tempo de Resposta (TR)**: 25% - Velocidade para retribuir
- **Qualidade dos Feedbacks (QF)**: 15% - Sentimento dos feedbacks

### 3. Impacto Social Gerado (25%)
- **Pessoas Destacadas (PD)**: 30% - Pessoas únicas destacadas
- **Reações Geradas (RG)**: 25% - Reações nos posts criados
- **Feedbacks Positivos (FP)**: 20% - Qualidade dos feedbacks recebidos
- **Efeito Cascata (EC)**: 25% - Pessoas que começaram a destacar após serem destacadas

### 4. Evolução do Engajamento (20%)
- Crescimento da Rede
- Melhoria na Qualidade
- Aumento da Frequência
- Redução de Inatividade

## Fatores de Ajuste

### Fator Tempo (FT)
- Objetivo: Valorizar usuários ativos há mais tempo
- Fórmula: `FT = min(1.2, 1 + (meses_ativo / 100))`
- Limite: Máximo 20% de bônus

### Fator Consistência (FC)
- Objetivo: Premiar regularidade
- Fórmula: `FC = 1 + (dias_consecutivos_ativo / 365) × 0.1`
- Limite: Máximo 10% de bônus

## Escala Final (0-100)

| Faixa | Nível | Descrição |
|-------|-------|-----------|
| 0-15 | 🌱 Iniciante | Começando a jornada de bem-estar social |
| 16-30 | 🌿 Crescendo | Desenvolvendo conexões positivas |
| 31-50 | 🌳 Estabelecido | Relacionamentos sólidos formados |
| 51-70 | 🌟 Influente | Impacto social significativo |
| 71-85 | 🏆 Inspirador | Catalisador de bem-estar comunitário |
| 86-100 | 👑 Lenda | Referência em positividade e gratidão |

## Visualização na Tela Principal (Aba Perfil)

### Painel Principal
- **Índice HoloSpot atual** (gauge visual)
- **Evolução temporal** (gráfico de linha)
- **Comparação com comunidade** (percentil)
- **Próxima meta** (barra de progresso)
