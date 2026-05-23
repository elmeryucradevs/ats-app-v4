-- ==============================================================================
-- ADD LOCAL PATH COLUMN TO PROGRAMS TABLE
-- Run this in your Supabase SQL Editor to support separate absolute local path storage.
-- ==============================================================================

ALTER TABLE public.programs 
ADD COLUMN IF NOT EXISTS local_path text;
