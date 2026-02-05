-- EMERGENCY DEBUG: Temporarily disable RLS to confirm it's the issue
ALTER TABLE public.advertising_campaigns DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertising_ads DISABLE ROW LEVEL SECURITY;

-- OR keeps RLS but adds a "allow all" policy
CREATE POLICY "Allow All Debug" ON public.advertising_campaigns FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All Debug Ads" ON public.advertising_ads FOR ALL USING (true) WITH CHECK (true);
