import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0'

const ANTHROPIC_API_KEY   = Deno.env.get('ANTHROPIC_API_KEY') ?? ''
const SUPABASE_URL        = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': SUPABASE_URL || '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SYSTEM_PROMPT = `Você é especialista em golpes digitais no Brasil.

Considere exemplos reais de fraudes comuns em WhatsApp, SMS, e-mail e redes:
- "Oi mãe, troquei de número. Preciso que você me faça um PIX urgente..."
- "PIX errado preciso que devolva"
- "Boleto atrasado urgente. Pague ou será protestado."
- "Entrega bloqueada correios. Clique aqui."
- "Conta bancária bloqueada por segurança."
- "Link falso de banco"
- "Promoção falsa de prêmios."

Avalie incisivamente:
- urgência emocional
- pedido de dinheiro / boletos / PIX
- engenharia social
- inconsistência de linguagem e links
Se houver dúvida, classifique como suspeito ou golpe. Seja excessivamente cauteloso para proteger o usuário.

RETORNE APENAS JSON VÁLIDO NO FORMATO EXATO, sem texto adicional:
{
  "risco": numero de 0 a 100,
  "classificacao": "seguro" ou "suspeito" ou "golpe",
  "tipo_golpe": "Resumo do que se trata ou N/A",
  "explicacao": "Explicação direta voltada a alertar a vítima.",
  "sinais_alerta": ["Sinal 1", "Sinal 2"],
  "acao_imediata": "Instrução clara ao usuário",
  "nivel_urgencia": "baixo" ou "medio" ou "alto" ou "extremo",
  "confianca": numero de 0 a 100,
  "golpe_conhecido": true ou false
}`

// ── Sanitização de PII (LGPD) ──────────────────────────────────────────────
// Remove dados pessoais identificáveis antes de persistir no banco.
// Aplicado a QUALQUER conteúdo antes do INSERT — nunca guardamos PII raw.
function sanitizePii(text: string): string {
  return text
    // CPF: 000.000.000-00 ou 00000000000
    .replace(/\b\d{3}[\.\s]?\d{3}[\.\s]?\d{3}[-\.\s]?\d{2}\b/g, '[CPF]')
    // Telefone BR: +55 11 99999-9999, (11) 99999-9999, 11999999999
    .replace(/(?:\+?55\s?)?(?:\(?\d{2}\)?\s?)(?:9\s?)?\d{4,5}[-\s]?\d{4}/g, '[TELEFONE]')
    // E-mail
    .replace(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g, '[EMAIL]')
    // Nome próprio heurístico: 2+ palavras capitalizadas consecutivas (ex.: "João da Silva")
    .replace(/\b([A-ZÁÉÍÓÚÀÃÕÂÊÔÜÇ][a-záéíóúàãõâêôüç]+)(\s+[A-ZÁÉÍÓÚÀÃÕÂÊÔÜÇ][a-záéíóúàãõâêôüç]+){1,4}\b/g, '[NOME]')
}

function extractJson(text: string): string {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/)
  if (fenced) return fenced[1].trim()
  const braceStart = text.indexOf('{')
  const braceEnd = text.lastIndexOf('}')
  if (braceStart !== -1 && braceEnd !== -1) return text.slice(braceStart, braceEnd + 1)
  return text.trim()
}

async function getConfig(): Promise<{ model: string }> {
  try {
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    const { data } = await adminClient
      .from('app_settings')
      .select('key, value')
      .in('key', ['ai_model'])
    const map = Object.fromEntries((data ?? []).map((r: { key: string; value: string }) => [r.key, r.value]))
    return { model: map['ai_model'] ?? 'claude-haiku-4-5-20251001' }
  } catch {
    return { model: 'claude-haiku-4-5-20251001' }
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const userClient = createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user } } = await userClient.auth.getUser()
    if (!user) throw new Error('Unauthorized')

    const { input_type, content, skip_save } = await req.json()

    if (!content || typeof content !== 'string') {
      throw new Error('content is required')
    }

    const { model } = await getConfig()

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: 'MENSAGEM:\n' + content }],
      }),
    })

    const data = await response.json()
    if (!data.content?.[0]?.text) {
      throw new Error('Anthropic error: ' + JSON.stringify(data))
    }

    const result = JSON.parse(extractJson(data.content[0].text))

    if (!skip_save) {
      // ── Sanitizar PII antes de persistir — NUNCA salvar raw ──────────────
      const sanitizedContent = sanitizePii(content)

      await userClient.from('analyses').insert({
        user_id: user.id,
        input_type,
        content: sanitizedContent,        // PII removido
        risk: result.risco,
        classification: result.classificacao,
        result,
      })
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Internal error'
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
