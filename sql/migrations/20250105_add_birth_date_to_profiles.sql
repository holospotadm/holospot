-- ============================================================================
-- MIGRAÇÃO: Adicionar campo birth_date na tabela profiles
-- Data: 2025-01-05
-- Descrição: Adiciona campo de data de nascimento para calcular idade do usuário
-- ============================================================================

-- 1. Adicionar coluna birth_date na tabela profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS birth_date DATE;

-- 2. Adicionar comentário explicativo na coluna
COMMENT ON COLUMN public.profiles.birth_date IS 'Data de nascimento do usuário (formato: YYYY-MM-DD)';

-- 3. Criar função para calcular idade a partir da data de nascimento
CREATE OR REPLACE FUNCTION public.calculate_age(birth_date DATE)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $function$
BEGIN
    IF birth_date IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INTEGER;
END;
$function$;

-- 4. Comentário na função
COMMENT ON FUNCTION public.calculate_age(DATE) IS 'Calcula a idade em anos a partir da data de nascimento';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Após executar, verifique com:
-- SELECT id, username, birth_date, calculate_age(birth_date) as age FROM profiles LIMIT 5;


-- ============================================================================
-- FUNÇÃO ATUALIZADA: update_user_profile (com birth_date)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_profile(p_user_id uuid, p_name text DEFAULT NULL::text, p_username text DEFAULT NULL::text, p_avatar_url text DEFAULT NULL::text, p_default_feed text DEFAULT NULL::text, p_birth_date date DEFAULT NULL::date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_username_available BOOLEAN;
    v_result JSON;
BEGIN
    IF p_username IS NOT NULL THEN
        SELECT check_username_availability(p_username, p_user_id) INTO v_username_available;
        
        IF NOT v_username_available THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Username já está em uso'
            );
        END IF;
    END IF;
    
    UPDATE profiles
    SET
        name = COALESCE(p_name, name),
        username = COALESCE(p_username, username),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        default_feed = COALESCE(p_default_feed, default_feed),
        birth_date = COALESCE(p_birth_date, birth_date),
        updated_at = NOW()
    WHERE id = p_user_id;
    
    SELECT json_build_object(
        'success', true,
        'profile', row_to_json(p.*)
    )
    INTO v_result
    FROM profiles p
    WHERE p.id = p_user_id;
    
    RETURN v_result;
END;
$function$;
