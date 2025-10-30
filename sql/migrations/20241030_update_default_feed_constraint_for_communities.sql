-- Migration: Update default_feed constraint to support community feeds
-- Date: 2024-10-30
-- Description: Allows default_feed to accept 'recommended', 'following', or 'community-{uuid}'

-- 1. Remove old constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS check_default_feed_values;

-- 2. Add new constraint that accepts community feeds
ALTER TABLE profiles ADD CONSTRAINT check_default_feed_values 
CHECK (
    default_feed IN ('recommended', 'following') 
    OR 
    default_feed LIKE 'community-%'
);

-- 3. Verify constraint was created successfully
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'check_default_feed_values';
