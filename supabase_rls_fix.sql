-- Allow authenticated users to INSERT
-- Ensure the policy for INSERT covers the role properly.
-- Fixing "Admins can manage campaigns" to explicitly include INSERT/UPDATE/DELETE
DROP POLICY IF EXISTS "Admins can manage campaigns" ON public.advertising_campaigns;

CREATE POLICY "Admins can manage campaigns"
  ON public.advertising_campaigns
  FOR ALL
  USING (auth.role() = 'authenticated');

-- Also check Ads table just in case
DROP POLICY IF EXISTS "Admins can manage ads" ON public.advertising_ads;

CREATE POLICY "Admins can manage ads"
  ON public.advertising_ads
  FOR ALL
  USING (auth.role() = 'authenticated');
