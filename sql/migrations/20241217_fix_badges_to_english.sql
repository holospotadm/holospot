-- ============================================================================
-- MIGRATION: Corrigir badges de correntes para padrão em inglês
-- ============================================================================
-- DESCRIÇÃO:
-- - Corrige raridade de português para inglês (comum→common, raro→rare, etc)
-- - Corrige categoria de português para inglês (correntes→chains)
-- ============================================================================

-- Corrigir raridade dos badges de correntes
UPDATE badges 
SET rarity = CASE rarity
    WHEN 'comum' THEN 'common'
    WHEN 'raro' THEN 'rare'
    WHEN 'épico' THEN 'epic'
    WHEN 'lendário' THEN 'legendary'
    ELSE rarity
END
WHERE category = 'correntes' OR rarity IN ('comum', 'raro', 'épico', 'lendário');

-- Corrigir categoria dos badges de correntes
UPDATE badges 
SET category = 'chains'
WHERE category = 'correntes';

-- Verificar resultado
SELECT name, rarity, category FROM badges WHERE category = 'chains' OR name IN ('Iniciador', 'Conector', 'Engrenagem', 'Corrente Viral', 'Elo', 'Corrente Forte', 'Multiplicador', 'Elo Profundo');

-- ✅ Badges corrigidos para padrão em inglês
