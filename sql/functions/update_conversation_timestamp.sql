-- Função RPC para atualizar updated_at das conversas
-- Esta função bypassa Row Level Security (RLS) usando SECURITY DEFINER
-- Execute este SQL no Supabase SQL Editor

CREATE OR REPLACE FUNCTION update_conversation_timestamp(conversation_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE conversations
  SET updated_at = NOW()
  WHERE id = conversation_id_param;
END;
$$;

-- Dar permissão para usuários autenticados chamarem esta função
GRANT EXECUTE ON FUNCTION update_conversation_timestamp(UUID) TO authenticated;
