// Supabase Edge Function para enviar notificaciones push vía FCM v1 API
// Deploy: supabase functions deploy send-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create } from 'https://deno.land/x/djwt@v2.8/mod.ts'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
    title: string
    body: string
    type?: 'program' | 'news' | 'general'
    data?: Record<string, any>
    tokens?: string[]
    platform?: 'web' | 'android' | 'ios' | 'windows' | 'macos'
}

// Generar JWT para OAuth 2.0
async function createJWT(serviceAccount: any): Promise<string> {
    const header = { alg: "RS256", typ: "JWT" }

    const now = Math.floor(Date.now() / 1000)
    const payload = {
        iss: serviceAccount.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: now + 3600,
        iat: now,
    }

    // Importar private key
    const privateKey = await crypto.subtle.importKey(
        "pkcs8",
        pemToBinary(serviceAccount.private_key),
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    )

    return await create(header, payload, privateKey)
}

// Convertir PEM a ArrayBuffer
function pemToBinary(pem: string): ArrayBuffer {
    const b64 = pem
        .replace(/-----BEGIN PRIVATE KEY-----/, '')
        .replace(/-----END PRIVATE KEY-----/, '')
        .replace(/\s/g, '')

    const binary = atob(b64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
}

// Obtener access token de OAuth 2.0
async function getAccessToken(serviceAccount: any): Promise<string> {
    const jwt = await createJWT(serviceAccount)

    const response = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt,
        }),
    })

    const data = await response.json()
    return data.access_token
}

// Enviar notificación a un token usando FCM v1 API
async function sendToToken(
    supabase: any,
    projectId: string,
    token: string,
    title: string,
    body: string,
    data: Record<string, string>,
    accessToken: string
): Promise<boolean> {
    const notification: any = { title, body }

    // Si hay una imagen en los datos, agregarla al payload de notificación
    // IMPORTANTE: Solo agregar si es una URL válida y no vacía
    if (data && data.image && typeof data.image === 'string' && data.image.trim().length > 0) {
        notification.image = data.image.trim()
    }

    const message = {
        message: {
            token,
            notification,
            data,
        },
    }

    const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(message),
        }
    )

    if (!response.ok) {
        const errorText = await response.text()
        console.error(`Error enviando a token ${token.substring(0, 10)}...: ${response.status} ${errorText}`)

        // Si el token no es válido (404 o 400 UNREGISTERED), eliminarlo de la DB
        if (response.status === 404 || errorText.includes('UNREGISTERED')) {
            console.log(`Eliminando token inválido: ${token.substring(0, 10)}...`)
            await supabase.from('fcm_tokens').delete().eq('token', token)
        }

        return false
    }

    return true
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // Obtener credenciales desde secrets
        const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')
        const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')
        const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')

        if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
            throw new Error('Firebase credentials no configuradas en Supabase Secrets')
        }

        const serviceAccount = {
            project_id: FIREBASE_PROJECT_ID,
            client_email: FIREBASE_CLIENT_EMAIL,
            private_key: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }

        // Parsear body
        const payload: NotificationPayload = await req.json()
        const { title, body, type = 'general', data, tokens, platform } = payload

        if (!title || !body) {
            return new Response(
                JSON.stringify({ error: 'title y body son requeridos' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Inicializar Supabase
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        const supabase = createClient(supabaseUrl, supabaseKey)

        // Obtener tokens
        let targetTokens: string[] = tokens || []

        if (targetTokens.length === 0) {
            let query = supabase.from('fcm_tokens').select('token')
            if (platform) query = query.eq('platform', platform)

            const { data: tokenData, error } = await query
            if (error) throw new Error(`Error obteniendo tokens: ${error.message}`)

            targetTokens = tokenData?.map((row: any) => row.token) || []
        }

        if (targetTokens.length === 0) {
            return new Response(
                JSON.stringify({ error: 'No se encontraron tokens' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`Enviando a ${targetTokens.length} dispositivos`)

        // Obtener access token
        const accessToken = await getAccessToken(serviceAccount)

        // Preparar data como strings
        const notificationData: Record<string, string> = {}
        if (data) {
            for (const [key, value] of Object.entries(data)) {
                notificationData[key] = String(value)
            }
        }

        // Enviar a cada token (FCM v1 no soporta batch, enviar uno por uno)
        const results = await Promise.allSettled(
            targetTokens.map(token =>
                sendToToken(
                    supabase,
                    serviceAccount.project_id,
                    token,
                    title,
                    body,
                    notificationData,
                    accessToken
                )
            )
        )

        const successCount = results.filter(r => r.status === 'fulfilled' && r.value).length

        // Registrar en DB
        await supabase.from('notifications').insert({
            title,
            body,
            type,
            data: data || {},
        })

        return new Response(
            JSON.stringify({
                success: true,
                sentTo: successCount,
                total: targetTokens.length,
                failed: targetTokens.length - successCount,
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
