-- ==============================================================================
-- ADVERTISING SYSTEM SCHEMA
-- ==============================================================================

-- 1. CAMPAIGNS TABLE
create type campaign_status as enum ('active', 'paused', 'completed', 'scheduled');

create table public.advertising_campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_date timestamptz not null,
  end_date timestamptz not null,
  -- JSON array of target countries/cities. e.g. ["BO", "PE"] or ["Santa Cruz", "La Paz"]
  -- If null or empty, it targets everywhere.
  target_countries text[] default null,
  target_cities text[] default null, 
  
  max_impressions bigint, -- NULL means unlimited
  current_impressions bigint default 0,
  
  status campaign_status default 'scheduled',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. ADS / CREATIVES TABLE
create type ad_type as enum (
  'video_preroll', 
  'video_overlay', 
  'popup_image', 
  'popup_video', 
  'banner', 
  'blog_post', 
  'blog_scroll_video',
  'fullscreen_startup' -- New type for "always on" startup
);

create type ad_position as enum (
  'top', 
  'bottom', 
  'left_sidebar', 
  'right_sidebar', 
  'center', 
  'fullscreen',
  'video_overlay',
  'in_feed' -- For blog posts
);

create type ad_frequency as enum (
  'always_on_startup',
  'once_per_session',
  'every_x_minutes',
  'unlimited'
);

create table public.advertising_ads (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.advertising_campaigns(id) on delete cascade not null,
  
  title text not null,
  type ad_type not null,
  position ad_position not null,
  
  -- Media URL from Storage
  media_url text not null,
  -- Optional redirect URL on click
  redirect_url text,
  
  -- Weight for rotation algorithm (1-100). Higher = more frequent.
  weight int default 50,
  
  -- Startup frequency settings
  frequency ad_frequency default 'unlimited',
  frequency_minutes int default 0, -- Used if frequency is every_x_minutes
  
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 3. STATISTICS / ANALYTICS
create type ad_event_type as enum (
  'impression', 
  'click', 
  'skip', 
  'start', 
  'complete', 
  'midpoint'
);

create table public.advertising_stats (
  id uuid primary key default gen_random_uuid(),
  ad_id uuid references public.advertising_ads(id) on delete set null,
  campaign_id uuid references public.advertising_campaigns(id) on delete set null,
  
  event_type ad_event_type not null,
  
  -- Geo-data detected from Edge Function
  user_country text,
  user_city text,
  user_ip text, -- Optional: hash this for privacy if needed
  
  -- Device info
  device_type text, -- 'mobile', 'desktop', 'tablet'
  
  created_at timestamptz default now()
);

-- ==============================================================================
-- INDEXES & PERFORMANCE
-- ==============================================================================
create index idx_ads_campaign_id on public.advertising_ads(campaign_id);
create index idx_stats_ad_id on public.advertising_stats(ad_id);
create index idx_stats_campaign_id on public.advertising_stats(campaign_id);
create index idx_stats_created_at on public.advertising_stats(created_at);
create index idx_campaigns_status on public.advertising_campaigns(status);

-- ==============================================================================
-- RLS POLICIES
-- ==============================================================================
alter table public.advertising_campaigns enable row level security;
alter table public.advertising_ads enable row level security;
alter table public.advertising_stats enable row level security;

-- Public READ access for Campaigns and Ads (so the App can fetch them)
-- In a real production scenario, you might want to wrap this in an Edge Function 
-- effectively "hidding" the full table and only returning active ads.
-- But for this implementation, we will allow read access.
create policy "Public read access for active campaigns"
  on public.advertising_campaigns for select
  using (true);

create policy "Public read access for active ads"
  on public.advertising_ads for select
  using (true);

-- Only Authenticated Admins (Channel Editor users) can INSERT/UPDATE/DELETE
-- Assuming Channel Editor users are authenticated via Supabase Auth
create policy "Admins can manage campaigns"
  on public.advertising_campaigns for all
  using (auth.role() = 'authenticated');

create policy "Admins can manage ads"
  on public.advertising_ads for all
  using (auth.role() = 'authenticated');

-- Stats: Public can INSERT (track events), Admins can SELECT (view stats)
create policy "Public can insert stats"
  on public.advertising_stats for insert
  with check (true);

create policy "Admins can view stats"
  on public.advertising_stats for select
  using (auth.role() = 'authenticated');
