-- ============================================================================
-- MIGRAÇÃO: Adicionar Timezone à Tabela Profiles
-- ============================================================================
-- Adiciona coluna timezone para corrigir cálculo de streaks por fuso horário
-- ============================================================================

-- Adicionar coluna timezone à tabela profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'America/Sao_Paulo';

-- Comentário da nova coluna
COMMENT ON COLUMN public.profiles.timezone IS 
'Fuso horário do usuário para cálculo correto de streaks. 
Formato: timezone IANA (ex: America/Sao_Paulo, America/New_York, Europe/London)
Default: America/Sao_Paulo (Brasil)';

-- Atualizar usuários existentes para timezone do Brasil (padrão)
UPDATE public.profiles 
SET timezone = 'America/Sao_Paulo' 
WHERE timezone IS NULL;

-- ============================================================================
-- ÍNDICE PARA PERFORMANCE (OPCIONAL)
-- ============================================================================

-- Criar índice para consultas por timezone (se necessário no futuro)
CREATE INDEX IF NOT EXISTS idx_profiles_timezone 
ON public.profiles (timezone);

-- ============================================================================
-- VALIDAÇÃO
-- ============================================================================

-- Verificar se a coluna foi criada corretamente
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'timezone'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE '✅ Coluna timezone adicionada com sucesso à tabela profiles';
    ELSE
        RAISE EXCEPTION '❌ Erro: Coluna timezone não foi criada';
    END IF;
END $$;
