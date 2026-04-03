-- Create users table extending auth.users
create table public.users (
  id uuid references auth.users not null primary key,
  email text not null,
  plan text default 'free',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Trigger auto-create user after auth
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create usage_limits table
create table public.usage_limits (
  user_id uuid references public.users not null primary key,
  daily_count integer default 0,
  last_reset timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Init user_limit automatically
create function public.handle_new_user_limit()
returns trigger as $$
begin
  insert into public.usage_limits (user_id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_public_user_created
  after insert on public.users
  for each row execute procedure public.handle_new_user_limit();

-- Create analyses table
create table public.analyses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  input_type text not null check (input_type in ('text', 'image')),
  content text not null,
  risk integer not null check (risk >= 0 and risk <= 100),
  classification text,
  result jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- NOVO: Intelligence Engine (scam_patterns)
create table public.scam_patterns (
  id uuid default gen_random_uuid() primary key,
  tipo text not null,
  exemplo_real text,
  risco_medio integer default 0,
  descricao text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- NOVO: Viralization Engine (referrals)
create table public.referrals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  invited_user_id uuid references public.users,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- NOVO: Monetization Engine (subscriptions)
create table public.subscriptions (
  user_id uuid references public.users not null primary key,
  plan text default 'premium',
  status text default 'active',
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- NOVO: Retention Engine (alerts)
create table public.alerts (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  risk_level text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Configuration
alter table public.users enable row level security;
alter table public.usage_limits enable row level security;
alter table public.analyses enable row level security;
alter table public.scam_patterns enable row level security;
alter table public.referrals enable row level security;
alter table public.subscriptions enable row level security;
alter table public.alerts enable row level security;

-- Policies
create policy "Users can view their own profile." on public.users for select using (auth.uid() = id);
create policy "Users can update their own profile." on public.users for update using (auth.uid() = id);
create policy "Users can view their own usage limits." on public.usage_limits for select using (auth.uid() = user_id);
create policy "Users can view their own analyses." on public.analyses for select using (auth.uid() = user_id);
create policy "Users can insert their own analyses." on public.analyses for insert with check (auth.uid() = user_id);

-- Leitura pública ou autenticada de alertas e padrões (para UI e Edge functions)
create policy "Anyone can read alerts." on public.alerts for select using (true);
create policy "Anyone can read patterns." on public.scam_patterns for select using (true);

-- Referrals and Subscriptions views
create policy "Users can view their referrals." on public.referrals for select using (auth.uid() = user_id);
create policy "Users can insert referrals." on public.referrals for insert with check (auth.uid() = user_id);
create policy "Users can view their own sub." on public.subscriptions for select using (auth.uid() = user_id);
