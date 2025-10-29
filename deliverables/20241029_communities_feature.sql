-- ============================================
-- MIGRATION: Communities Feature
-- Descrição: Adiciona funcionalidade completa de Comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- Versão: 1.0.0
-- ============================================

-- ========================================
-- PARTE 1: MODIFICAÇÕES EM TABELAS EXISTENTES
-- ========================================

-- 1.1: Adicionar campo community_owner em profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS community_owner BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_profiles_community_owner ON profiles(community_owner) WHERE community_owner = true;

COMMENT ON COLUMN profiles.community_owner IS 'Se o usuário pode criar comunidades';

-- Habilitar para @guilherme.dutra
UPDATE profiles 
SET community_owner = true 
WHERE username = 'guilherme.dutra';

-- 1.2: Adicionar campo community_id em posts
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES communities(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_posts_community ON posts(community_id) WHERE community_id IS NOT NULL;

COMMENT ON COLUMN posts.community_id IS 'ID da comunidade (NULL = post global)';

-- ========================================
-- PARTE 2: CRIAR NOVAS TABELAS
-- ========================================

-- 2.1: Tabela communities
CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    emoji TEXT DEFAULT '🏢',
    logo_url TEXT,
    owner_id UUID REFERENCES profiles(id) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_communities_owner ON communities(owner_id);
CREATE INDEX IF NOT EXISTS idx_communities_slug ON communities(slug);
CREATE INDEX IF NOT EXISTS idx_communities_active ON communities(is_active) WHERE is_active = true;

COMMENT ON TABLE communities IS 'Comunidades privadas do HoloSpot';
COMMENT ON COLUMN communities.id IS 'ID único da comunidade';
COMMENT ON COLUMN communities.name IS 'Nome da comunidade';
COMMENT ON COLUMN communities.slug IS 'URL amigável (único)';
COMMENT ON COLUMN communities.description IS 'Descrição da comunidade';
COMMENT ON COLUMN communities.emoji IS 'Emoji que representa a comunidade';
COMMENT ON COLUMN communities.logo_url IS 'URL do logo da comunidade';
COMMENT ON COLUMN communities.owner_id IS 'ID do dono da comunidade';
COMMENT ON COLUMN communities.created_at IS 'Data de criação';
COMMENT ON COLUMN communities.updated_at IS 'Data da última atualização';
COMMENT ON COLUMN communities.is_active IS 'Se a comunidade está ativa';

-- 2.2: Tabela community_members
CREATE TABLE IF NOT EXISTS community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(community_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_members_community ON community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user ON community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_members_active ON community_members(community_id, is_active) WHERE is_active = true;

COMMENT ON TABLE community_members IS 'Membros das comunidades';
COMMENT ON COLUMN community_members.id IS 'ID único do membro';
COMMENT ON COLUMN community_members.community_id IS 'ID da comunidade';
COMMENT ON COLUMN community_members.user_id IS 'ID do usuário';
COMMENT ON COLUMN community_members.role IS 'Papel do membro (owner, member)';
COMMENT ON COLUMN community_members.joined_at IS 'Data de entrada na comunidade';
COMMENT ON COLUMN community_members.is_active IS 'Se o membro está ativo';

-- ========================================
-- PARTE 3: RLS POLICIES
-- ========================================

-- 3.1: RLS para communities
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view community" ON communities;
DROP POLICY IF EXISTS "Only community owners can create communities" ON communities;
DROP POLICY IF EXISTS "Owner can update community" ON communities;
DROP POLICY IF EXISTS "Owner can delete community" ON communities;

CREATE POLICY "Members can view community"
ON communities FOR SELECT
USING (
    id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

CREATE POLICY "Only community owners can create communities"
ON communities FOR INSERT
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM profiles WHERE community_owner = true
    )
);

CREATE POLICY "Owner can update community"
ON communities FOR UPDATE
USING (auth.uid() = owner_id);

CREATE POLICY "Owner can delete community"
ON communities FOR DELETE
USING (auth.uid() = owner_id);

-- 3.2: RLS para community_members
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view other members" ON community_members;
DROP POLICY IF EXISTS "Owner can add members" ON community_members;
DROP POLICY IF EXISTS "Owner can update members" ON community_members;
DROP POLICY IF EXISTS "Owner can remove members" ON community_members;

CREATE POLICY "Members can view other members"
ON community_members FOR SELECT
USING (
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

CREATE POLICY "Owner can add members"
ON community_members FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = community_members.community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
    )
);

CREATE POLICY "Owner can update members"
ON community_members FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);

CREATE POLICY "Owner can remove members"
ON community_members FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);

-- 3.3: Atualizar RLS para posts
DROP POLICY IF EXISTS "Users can view posts" ON posts;
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Owner can delete community posts" ON posts;
DROP POLICY IF EXISTS "Owner can update community posts" ON posts;

CREATE POLICY "Users can view posts"
ON posts FOR SELECT
USING (
    community_id IS NULL OR
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

CREATE POLICY "Users can create posts"
ON posts FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND (
        community_id IS NULL OR
        community_id IN (
            SELECT community_id FROM community_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    )
);

CREATE POLICY "Owner can delete community posts"
ON posts FOR DELETE
USING (
    auth.uid() = user_id OR
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);

CREATE POLICY "Owner can update community posts"
ON posts FOR UPDATE
USING (
    auth.uid() = user_id OR
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);

-- ========================================
-- PARTE 4: FUNÇÕES
-- ========================================

-- 4.1: Função create_community
CREATE OR REPLACE FUNCTION create_community(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_community_id UUID;
    v_is_community_owner BOOLEAN;
BEGIN
    IF auth.uid() != p_owner_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    SELECT community_owner INTO v_is_community_owner
    FROM profiles
    WHERE id = p_owner_id;
    
    IF NOT v_is_community_owner THEN
        RAISE EXCEPTION 'User is not authorized to create communities';
    END IF;
    
    INSERT INTO communities (name, slug, description, emoji, owner_id)
    VALUES (p_name, p_slug, p_description, COALESCE(p_emoji, '🏢'), p_owner_id)
    RETURNING id INTO v_community_id;
    
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (v_community_id, p_owner_id, 'owner');
    
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_owner_id,
        'Owner de Comunidade',
        'Criou uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN v_community_id;
END;
$$;

COMMENT ON FUNCTION create_community IS 'Cria uma nova comunidade e adiciona o owner como membro';

-- 4.2: Função update_community
CREATE OR REPLACE FUNCTION update_community(
    p_community_id UUID,
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_logo_url TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM communities 
        WHERE id = p_community_id 
        AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can update community';
    END IF;
    
    UPDATE communities
    SET 
        name = p_name,
        slug = p_slug,
        description = p_description,
        emoji = COALESCE(p_emoji, emoji),
        logo_url = p_logo_url,
        updated_at = NOW()
    WHERE id = p_community_id;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION update_community IS 'Atualiza informações de uma comunidade (apenas owner)';

-- 4.3: Função add_community_member
CREATE OR REPLACE FUNCTION add_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can add members';
    END IF;
    
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, 'member')
    ON CONFLICT (community_id, user_id) DO UPDATE
    SET is_active = true;
    
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_user_id,
        'Membro de Comunidade',
        'Entrou em uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION add_community_member IS 'Adiciona um membro à comunidade (apenas owner)';

-- 4.4: Função remove_community_member
CREATE OR REPLACE FUNCTION remove_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can remove members';
    END IF;
    
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Owner cannot remove themselves';
    END IF;
    
    UPDATE community_members
    SET is_active = false
    WHERE community_id = p_community_id AND user_id = p_user_id;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION remove_community_member IS 'Remove um membro da comunidade (apenas owner)';

-- 4.5: Função get_community_feed
CREATE OR REPLACE FUNCTION get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    mentioned_user_id UUID,
    person_name TEXT,
    content TEXT,
    image_url TEXT,
    created_at TIMESTAMP,
    likes_count INTEGER,
    comments_count INTEGER,
    user_has_liked BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.celebrated_person_name,
        p.mentioned_user_id,
        p.person_name,
        p.content,
        p.image_url,
        p.created_at,
        p.likes_count,
        p.comments_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = p_user_id) as user_has_liked
    FROM posts p
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_community_feed IS 'Retorna feed de posts de uma comunidade (apenas membros)';

-- ========================================
-- PARTE 5: TRIGGERS
-- ========================================

-- 5.1: Trigger para badge de primeiro post em comunidade
CREATE OR REPLACE FUNCTION award_first_community_post_badge()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.community_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM posts 
            WHERE user_id = NEW.user_id 
            AND community_id = NEW.community_id 
            AND id != NEW.id
        ) THEN
            INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
            VALUES (
                NEW.user_id,
                'Primeiro Post na Comunidade',
                'Fez o primeiro post em uma comunidade',
                NOW()
            )
            ON CONFLICT (user_id, badge_name) DO NOTHING;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_award_first_community_post_badge ON posts;

CREATE TRIGGER trigger_award_first_community_post_badge
AFTER INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION award_first_community_post_badge();

COMMENT ON FUNCTION award_first_community_post_badge IS 'Atribui badge ao fazer primeiro post em comunidade';

-- ========================================
-- FIM DA MIGRATION
-- ========================================

-- Verificação final
DO $$
BEGIN
    RAISE NOTICE '✅ Migration 20241029_communities_feature executada com sucesso!';
    RAISE NOTICE '📊 Tabelas criadas: communities, community_members';
    RAISE NOTICE '🔧 Funções criadas: 5 funções';
    RAISE NOTICE '🔒 RLS policies configuradas';
    RAISE NOTICE '⚡ Triggers configurados';
    RAISE NOTICE '👤 @guilherme.dutra habilitado como community_owner';
END $$;

