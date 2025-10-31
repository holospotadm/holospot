-- Migration: Adicionar função update_conversation_timestamp
-- Data: 2024-10-31
-- Descrição: Função RPC para atualizar updated_at de conversas (bypass RLS)
-- Contexto: Necessário para ordenar conversas por última mensagem

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

-- Dar permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION update_conversation_timestamp(UUID) TO authenticated;
