-- Tabela de denúncias a autoridades por usuário
-- Aplicar no Supabase SQL Editor ou via CLI: supabase db push

create table if not exists public.authority_reports (
  id             uuid primary key default gen_random_uuid(),
  victim_id      uuid references auth.users not null,
  offender_phone text not null,
  cleaned_message text not null,
  ipqs_score     int not null default 0,
  created_at     timestamptz not null default now()
);

-- Row Level Security: usuário vê apenas as próprias denúncias
alter table public.authority_reports enable row level security;

drop policy if exists "Users manage own reports" on public.authority_reports;

create policy "Users manage own reports"
  on public.authority_reports
  for all
  using (auth.uid() = victim_id)
  with check (auth.uid() = victim_id);

-- Índice para lookup por usuário
create index if not exists authority_reports_victim_idx
  on public.authority_reports (victim_id);

-- Índice para dedup temporal
create index if not exists authority_reports_phone_victim_idx
  on public.authority_reports (offender_phone, victim_id, created_at);
