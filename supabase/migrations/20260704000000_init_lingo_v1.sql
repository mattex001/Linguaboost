-- Lingo V1 schema: profiles + phrases (embedded explanation + SM-2 review state).

create extension if not exists unaccent;

-- ── profiles ────────────────────────────────────────────────────────────────

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text,
  email text,
  target_language text,
  learning_goal text,
  streak_count int not null default 0,
  last_active_date date,
  active_dates date[] not null default '{}',
  notifications_enabled bool not null default false,
  notification_start text,
  notification_end text,
  selected_theme text not null default 'theme_1',
  is_premium bool not null default false,
  trial_start_date timestamptz,
  onboarding_step int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);
create policy "profiles_delete_own" on public.profiles
  for delete using (auth.uid() = id);

-- Auto-create a profile row for every new auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── phrases ─────────────────────────────────────────────────────────────────

create table public.phrases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  source_text text not null,
  translated_text text not null,
  source_lang text not null default 'en',
  target_lang text not null,
  register_note text,
  category text not null,
  confidence text not null default 'high',
  confidence_note text,
  seeded bool not null default false,
  vocab_breakdown jsonb,
  grammar_note text,
  pronunciation jsonb,
  -- SM-2 review state; new phrases are immediately due
  ease_factor double precision not null default 2.5,
  interval_days int not null default 0,
  repetitions int not null default 0,
  next_review_at timestamptz not null default now(),
  last_result text,
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index phrases_user_due_idx on public.phrases (user_id, next_review_at);
create index phrases_user_created_idx on public.phrases (user_id, created_at desc);

alter table public.phrases enable row level security;

create policy "phrases_select_own" on public.phrases
  for select using (auth.uid() = user_id);
create policy "phrases_insert_own" on public.phrases
  for insert with check (auth.uid() = user_id);
create policy "phrases_update_own" on public.phrases
  for update using (auth.uid() = user_id);
create policy "phrases_delete_own" on public.phrases
  for delete using (auth.uid() = user_id);
