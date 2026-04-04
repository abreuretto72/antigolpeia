import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0'

const SUPABASE_URL         = Deno.env.get('SUPABASE_URL')              ?? ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': SUPABASE_URL || '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verificar autenticação do usuário que quer se deletar
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userClient = createClient(SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user } } = await userClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userId = user.id

    // 2. Usar service role para deletar todos os dados do usuário
    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // Deletar dados nas tabelas (em ordem para respeitar foreign keys)
    await Promise.all([
      admin.from('analyses').delete().eq('user_id', userId),
      admin.from('authority_reports').delete().eq('victim_id', userId),
      admin.from('backups').delete().eq('id', userId),
    ])

    // community_fraud_patterns são anonimizados — não vinculados ao user_id.
    // Mantemos na base comunitária (LGPD art. 16: dados anonimizados podem ser mantidos).

    // 3. Deletar o usuário do Supabase Auth (admin)
    const { error: deleteError } = await admin.auth.admin.deleteUser(userId)
    if (deleteError) {
      throw new Error(`Failed to delete auth user: ${deleteError.message}`)
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
