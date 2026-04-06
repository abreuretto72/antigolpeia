import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0'

const TWILIO_ACCOUNT_SID  = Deno.env.get('TWILIO_ACCOUNT_SID')  ?? ''
const TWILIO_AUTH_TOKEN   = Deno.env.get('TWILIO_AUTH_TOKEN')   ?? ''
const TWILIO_LOOKUP_URL   = Deno.env.get('TWILIO_LOOKUP_URL')   ?? 'https://lookups.twilio.com/v2/PhoneNumbers'
const SUPABASE_URL        = Deno.env.get('SUPABASE_URL')        ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Autenticar o usuário Supabase — garante que apenas usuários do app chamam esta função
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseClient = createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { phone } = await req.json()
    if (!phone || typeof phone !== 'string') {
      return new Response(JSON.stringify({ error: 'Phone number required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Sanitizar: aceitar apenas + e dígitos
    const sanitized = phone.replace(/[^\d+]/g, '')
    if (sanitized.length < 8 || sanitized.length > 16) {
      return new Response(JSON.stringify({ success: false, error: 'Invalid phone number' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Chamar Twilio Lookup API server-side — credentials nunca saem do servidor
    const url = `${TWILIO_LOOKUP_URL}/${encodeURIComponent(sanitized)}?Fields=sim_swap`
    const credentials = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)

    const twilioRes = await fetch(url, {
      headers: { Authorization: `Basic ${credentials}` },
    })

    const twilioData = await twilioRes.json()

    if (!twilioRes.ok) {
      return new Response(JSON.stringify({
        success: false,
        error: twilioData.message ?? 'Twilio error',
      }), {
        status: 200, // retorna 200 para o app tratar como falha graceful
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const simSwap = twilioData.sim_swap
    return new Response(JSON.stringify({
      success: true,
      isSwapped: simSwap?.swapped ?? false,
      last_swap: simSwap?.last_sim_swap_date ?? null,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal error'
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
