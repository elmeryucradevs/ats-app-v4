-- ==============================================================================
-- UPDATE MOVIES DATABASE TABLE SCHEMA WITH FULL TMDB METADATA
-- Run this in your Supabase SQL Editor to support detailed movie metadata.
-- ==============================================================================

ALTER TABLE public.movies_database 
ADD COLUMN IF NOT EXISTS image_url text,
ADD COLUMN IF NOT EXISTS content_rating text,
ADD COLUMN IF NOT EXISTS duration integer,
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS category text DEFAULT 'cine',
ADD COLUMN IF NOT EXISTS release_year integer,
ADD COLUMN IF NOT EXISTS vmix_input_name text;

-- Performance index for category search
CREATE INDEX IF NOT EXISTS idx_movies_database_category ON public.movies_database(category);
