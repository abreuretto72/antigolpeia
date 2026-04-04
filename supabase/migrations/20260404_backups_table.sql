-- Tabela de backup de Whitelist e Blacklist por usuário
-- Aplicar no Supabase SQL Editor ou via CLI: supabase db push

create table if not exists public.backups (
  id         uuid references auth.users not null primary key,
  whitelist  jsonb not null default '[]'::jsonb,
  blacklist  jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Row Level Security: cada usuário acessa apenas o próprio backup
alter table public.backups enable row level security;

create policy "Users manage own backup"
  on public.backups
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Índice para lookup rápido por user_id
create index if not exists backups_id_idx on public.backups (id);
