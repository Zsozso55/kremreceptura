-- ============================================================
--  Receptúra — Supabase schema
--  Run this in your project's SQL Editor (Database -> SQL Editor -> New query).
-- ============================================================

-- ---- tables ----
create table if not exists public.ingredients (
  id          text primary key,
  user_id     uuid not null default auth.uid(),
  name        text not null,
  unit        text,
  stock       numeric default 0,
  min_stock   numeric default 0,
  price       numeric default 0,
  expiry      date,
  notes       text default '',
  seed_key    text,
  created_at  timestamptz default now()
);

create table if not exists public.recipes (
  id          text primary key,
  user_id     uuid not null default auth.uid(),
  name        text not null,
  yield_text  text default '',
  description text default '',
  items       jsonb default '[]'::jsonb,
  steps       jsonb default '[]'::jsonb,
  seed_key    text,
  created_at  timestamptz default now()
);

create table if not exists public.batches (
  id          text primary key,
  user_id     uuid not null default auth.uid(),
  date        date,
  recipe_id   text,
  recipe_name text,
  multiplier  numeric,
  lines       jsonb default '[]'::jsonb,
  created_at  timestamptz default now()
);

-- ---- row level security: each account sees only its own rows ----
alter table public.ingredients enable row level security;
alter table public.recipes     enable row level security;
alter table public.batches     enable row level security;

drop policy if exists "own ingredients" on public.ingredients;
drop policy if exists "own recipes"     on public.recipes;
drop policy if exists "own batches"     on public.batches;

create policy "own ingredients" on public.ingredients
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own recipes" on public.recipes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own batches" on public.batches
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- realtime: live sync across devices ----
alter publication supabase_realtime add table public.ingredients;
alter publication supabase_realtime add table public.recipes;
alter publication supabase_realtime add table public.batches;

-- ============================================================
--  UPDATE (2026-06): batch number + SDS (safety data sheet)
--  Run this once in the SQL Editor if you set the app up earlier.
-- ============================================================

-- new ingredient columns
alter table public.ingredients add column if not exists batch    text;
alter table public.ingredients add column if not exists sds_path text;
alter table public.ingredients add column if not exists sds_name text;

-- storage bucket for the uploaded SDS files (private)
insert into storage.buckets (id, name, public)
values ('sds', 'sds', false)
on conflict (id) do nothing;

-- storage policies: any signed-in account may manage files in the 'sds' bucket
drop policy if exists "sds read"   on storage.objects;
drop policy if exists "sds insert" on storage.objects;
drop policy if exists "sds update" on storage.objects;
drop policy if exists "sds delete" on storage.objects;

create policy "sds read"   on storage.objects for select to authenticated using (bucket_id = 'sds');
create policy "sds insert" on storage.objects for insert to authenticated with check (bucket_id = 'sds');
create policy "sds update" on storage.objects for update to authenticated using (bucket_id = 'sds');
create policy "sds delete" on storage.objects for delete to authenticated using (bucket_id = 'sds');

-- ============================================================
--  UPDATE (2026-07): cleaning log (hygiene gate before batches)
--  Run this once in the SQL Editor if you set the app up earlier.
-- ============================================================

create table if not exists public.cleanings (
  id          text primary key,
  user_id     uuid not null default auth.uid(),
  ts          timestamptz not null default now(),
  done_by     text default '',
  steps       jsonb default '[]'::jsonb,
  note        text default '',
  created_at  timestamptz default now()
);

alter table public.cleanings enable row level security;
drop policy if exists "own cleanings" on public.cleanings;
create policy "own cleanings" on public.cleanings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter publication supabase_realtime add table public.cleanings;
