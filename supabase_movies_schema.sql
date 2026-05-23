-- ==============================================================================
-- MOVIES DATABASE SCHEMA
-- ==============================================================================

-- 1. Create the movies_database table
create table public.movies_database (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  local_path text not null,
  created_at timestamptz default now()
);

-- ==============================================================================
-- INDEXES & PERFORMANCE
-- ==============================================================================
create index idx_movies_database_name on public.movies_database(name);

-- ==============================================================================
-- RLS POLICIES
-- ==============================================================================
alter table public.movies_database enable row level security;

-- Only Authenticated Admins (Channel Editor users) can SELECT/INSERT/UPDATE/DELETE
create policy "Admins can manage movies database"
  on public.movies_database for all
  using (auth.role() = 'authenticated');
