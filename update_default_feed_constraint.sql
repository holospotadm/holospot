-- Script para atualizar constraint check_default_feed_values
-- Permite valores: 'recommended', 'following', ou 'community-{uuid}'

-- 1. Remover constraint antiga
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS check_default_feed_values;

-- 2. Adicionar nova constraint que aceita comunidades
ALTER TABLE profiles ADD CONSTRAINT check_default_feed_values 
CHECK (
    default_feed IN ('recommended', 'following') 
    OR 
    default_feed LIKE 'community-%'
);

-- Verificar se a constraint foi criada corretamente
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'check_default_feed_values';
