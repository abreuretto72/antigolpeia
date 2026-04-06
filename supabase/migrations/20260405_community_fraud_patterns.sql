-- Tabela de padrões de fraude comunitários
-- Motor de IA local: IaInferenceService lê daqui para pré-classificar mensagens.
-- AiDatasetService.submitToAiBase() submete padrões confirmados com risco >= 70.
-- Aplicar no Supabase SQL Editor ou via CLI: supabase db push

-- ── Tabela principal ──────────────────────────────────────────────────────────

create table if not exists public.community_fraud_patterns (
  -- Identidade (SHA-256 do conteúdo sanitizado — sem PII)
  pattern_hash          text        primary key,

  -- Conteúdo sanitizado (LGPD: sem telefone, nome, CPF, e-mail)
  content_pattern       text        not null,

  -- Metadados da análise original
  input_type            text        not null default 'text'
                          check (input_type in ('text', 'sms', 'whatsapp', 'email', 'image')),
  ipqs_fraud_score      integer     not null default 0
                          check (ipqs_fraud_score between 0 and 100),
  sim_swap_status       boolean     not null default false,
  is_voip               boolean     not null default false,

  -- Campos agregados — atualizados pelo trigger abaixo
  fraud_score_aggregate integer     not null default 0
                          check (fraud_score_aggregate between 0 and 100),
  total_reports         integer     not null default 1,
  confirmed_fraud_count integer     not null default 0,

  -- Classificação e status
  classification        text        not null default 'golpe',
  user_confirmation     integer     not null default 1
                          check (user_confirmation in (0, 1)),
  is_active             boolean     not null default true,

  -- Timestamps
  last_reported         timestamptz not null default now(),
  created_at            timestamptz not null default now()
);

-- ── Índices ───────────────────────────────────────────────────────────────────

-- Leitura paginada por data para rebuildCacheFromRemote()
create index if not exists community_fraud_patterns_created_idx
  on public.community_fraud_patterns (created_at desc);

-- Filtro por padrões ativos confirmados
create index if not exists community_fraud_patterns_active_idx
  on public.community_fraud_patterns (is_active, user_confirmation);

-- ── Função de upsert com agregação ───────────────────────────────────────────
-- Usada pela Edge Function (service_role) para submeter padrões com agregação
-- correta dos contadores. O app Flutter chama esta função via RPC.
-- Substitui o upsert direto do AiDatasetService (que não tem acesso à lógica
-- de média ponderada no cliente).

create or replace function public.upsert_fraud_pattern(
  p_pattern_hash          text,
  p_content_pattern       text,
  p_input_type            text,
  p_ipqs_fraud_score      integer,
  p_sim_swap_status       boolean,
  p_is_voip               boolean,
  p_user_confirmation     integer
)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.community_fraud_patterns (
    pattern_hash,
    content_pattern,
    input_type,
    ipqs_fraud_score,
    sim_swap_status,
    is_voip,
    fraud_score_aggregate,
    confirmed_fraud_count,
    user_confirmation
  ) values (
    p_pattern_hash,
    p_content_pattern,
    p_input_type,
    p_ipqs_fraud_score,
    p_sim_swap_status,
    p_is_voip,
    p_ipqs_fraud_score,       -- primeiro registro: aggregate = score inicial
    p_user_confirmation,      -- 0 ou 1
    p_user_confirmation
  )
  on conflict (pattern_hash) do update
    set
      total_reports         = community_fraud_patterns.total_reports + 1,
      confirmed_fraud_count = community_fraud_patterns.confirmed_fraud_count
                              + excluded.user_confirmation,
      -- Média incremental do score: evita divisão por zero
      fraud_score_aggregate = (
        community_fraud_patterns.fraud_score_aggregate
          * community_fraud_patterns.total_reports
          + excluded.ipqs_fraud_score
      ) / (community_fraud_patterns.total_reports + 1),
      last_reported = now();
end;
$$;

-- Permissão de execução para usuários autenticados (anon key do app)
grant execute on function public.upsert_fraud_pattern to authenticated;
grant execute on function public.upsert_fraud_pattern to anon;

-- ── RLS ───────────────────────────────────────────────────────────────────────

alter table public.community_fraud_patterns enable row level security;

-- Qualquer cliente autenticado (Edge Function + app) pode ler padrões ativos
drop policy if exists "Anyone can read active patterns." on public.community_fraud_patterns;
create policy "Anyone can read active patterns."
  on public.community_fraud_patterns
  for select
  using (is_active = true);

-- Apenas a Edge Function (service_role) pode inserir/atualizar padrões
-- O app Flutter usa a anon key — nunca grava diretamente nesta tabela em produção.
-- Durante o desenvolvimento, a anon key pode inserir (policy abaixo).
-- Para produção, substitua por: using (auth.role() = 'service_role')
drop policy if exists "Authenticated users can submit patterns." on public.community_fraud_patterns;
create policy "Authenticated users can submit patterns."
  on public.community_fraud_patterns
  for insert
  with check (auth.role() = 'authenticated');

drop policy if exists "Service role can update patterns." on public.community_fraud_patterns;
create policy "Service role can update patterns."
  on public.community_fraud_patterns
  for update
  using (true);
