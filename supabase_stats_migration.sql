-- Add metadata column for detailed stats (article, item, etc.)
ALTER TABLE public.advertising_stats 
ADD COLUMN IF NOT EXISTS metadata jsonb default '{}'::jsonb,
ADD COLUMN IF NOT EXISTS user_agent text;

-- Rename user_ip if intended, or just ensure consistency. 
-- The logs show TS uses 'ip_address', SQL uses 'user_ip'. 
-- Let's stick to 'user_ip' in DB and fix TS.
