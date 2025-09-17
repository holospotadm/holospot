# 🔗 RELACIONAMENTOS

## 📋 **ARQUIVOS**

- **foreign_keys.sql** - Mapeamento de foreign keys

## 🔍 **PARA LISTAR RELACIONAMENTOS**

Execute no Supabase:

```sql
-- Todas as foreign keys
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
```

## 🗺️ **MAPA DE RELACIONAMENTOS**

```
profiles (usuários)
├── posts (author_id)
├── comments (author_id)
├── reactions (user_id)
├── feedbacks (author_id, mentioned_user_id)
├── follows (follower_id, following_id)
├── user_points (user_id)
├── user_badges (user_id)
├── user_streaks (user_id)
├── points_history (user_id)
└── notifications (user_id, from_user_id)

posts
├── comments (post_id)
├── reactions (post_id)
└── feedbacks (post_id)

badges
└── user_badges (badge_id)

levels
└── user_points (level_id)
```
