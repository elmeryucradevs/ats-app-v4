
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

        const { ad_id, campaign_id, event_type, ip_address, user_agent } = await req.json()

        // 1. Insert Stat Record
        const { error: statError } = await supabaseClient
            .from('advertising_stats')
            .insert({
                ad_id,
                campaign_id,
                event_type,
                ip_address: ip_address || 'unknown', // Ideally get from request headers if possible (req.headers.get('x-forwarded-for'))
                user_agent: user_agent || 'unknown'
            })

        if (statError) throw statError

        // 2. Increment Campaign Counter (RPC or separate update)
        // We update 'current_impressions' if event is impression
        if (event_type === 'impression') {
            // We can do this via an RPC or direct update. Direct update here.
            // Get current
            const { data: campaign, error: getError } = await supabaseClient
                .from('advertising_campaigns')
                .select('current_impressions')
                .eq('id', campaign_id)
                .single()

            if (!getError && campaign) {
                await supabaseClient
                    .from('advertising_campaigns')
                    .update({ current_impressions: (campaign.current_impressions || 0) + 1 })
                    .eq('id', campaign_id)
            }
        }

        return new Response(
            JSON.stringify({ success: true }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
