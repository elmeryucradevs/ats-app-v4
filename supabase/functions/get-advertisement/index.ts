
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
        )

        const { position, type, city, country } = await req.json()

        // 1. Get active campaigns
        const now = new Date().toISOString()
        const { data: campaigns, error: campError } = await supabaseClient
            .from('advertising_campaigns')
            .select('id, target_countries, target_cities, max_impressions, current_impressions')
            .eq('status', 'active')
            .lte('start_date', now)
            .gte('end_date', now)

        if (campError) throw campError

        if (!campaigns || campaigns.length === 0) {
            return new Response(JSON.stringify({ ad: null }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }

        // 2. Filter campaigns by Geo and Impressions Limit
        const validCampaignIds = campaigns.filter(c => {
            // Check impressions limit
            if (c.max_impressions && c.current_impressions >= c.max_impressions) return false;

            // Check Country
            if (c.target_countries && c.target_countries.length > 0 && country) {
                if (!c.target_countries.includes(country)) return false;
            }

            // Check City
            if (c.target_cities && c.target_cities.length > 0 && city) {
                if (!c.target_cities.includes(city)) return false;
            }

            return true;
        }).map(c => c.id);

        if (validCampaignIds.length === 0) {
            return new Response(JSON.stringify({ ad: null }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }

        // 3. Get suitable Ads from valid campaigns
        let query = supabaseClient
            .from('advertising_ads')
            .select('*')
            .in('campaign_id', validCampaignIds)
            .eq('is_active', true)
            .eq('position', position)

        if (type) {
            query = query.eq('type', type)
        }

        const { data: ads, error: adError } = await query

        if (adError) throw adError

        if (!ads || ads.length === 0) {
            return new Response(JSON.stringify({ ad: null }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }

        // 4. Select Ad based on Weight (Weighted Random Selection)
        // Calculate total weight
        const totalWeight = ads.reduce((sum, ad) => sum + (ad.weight || 0), 0);
        let random = Math.random() * totalWeight;

        let selectedAd = ads[0];
        for (const ad of ads) {
            random -= (ad.weight || 0);
            if (random <= 0) {
                selectedAd = ad;
                break;
            }
        }

        return new Response(
            JSON.stringify({ ad: selectedAd }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
