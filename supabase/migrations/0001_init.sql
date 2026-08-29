-- Tunefy Supabase schema — 0001_init
-- Run this in: Dashboard → SQL Editor → New query → Run.

create extension if not exists "pgcrypto";

-- ─── Profiles (identity: Supabase auth uid; anonymous users get a real uid) ──
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text,
  email      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ─── Key/value settings snapshot (theme, autoplay, language, etc.) ──────────
create table if not exists public.settings (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  key        text not null,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (profile_id, key)
);

-- ─── Liked songs (one row per song, upsert by video_id) ─────────────────────
create table if not exists public.liked_songs (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  video_id   text not null,
  song       jsonb not null,
  created_at timestamptz not null default now(),
  unique (profile_id, video_id)
);
create index if not exists liked_songs_profile_idx on public.liked_songs (profile_id);

-- ─── Listening history (latest play per song) ───────────────────────────────
create table if not exists public.history (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  video_id   text not null,
  song       jsonb not null,
  played_at  timestamptz not null default now(),
  unique (profile_id, video_id)
);
create index if not exists history_profile_idx on public.history (profile_id, played_at desc);

-- ─── Subscriptions (YouTube channels) ───────────────────────────────────────
create table if not exists public.subscriptions (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  channel_id text not null,
  data       jsonb not null,
  created_at timestamptz not null default now(),
  unique (profile_id, channel_id)
);
create index if not exists subscriptions_profile_idx on public.subscriptions (profile_id);

-- ─── Playlists (whole document per playlist — matches the app model) ────────
create table if not exists public.playlists (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name       text not null,
  data       jsonb not null,
  created_at timestamptz not null default now(),
  unique (profile_id, name)
);
create index if not exists playlists_profile_idx on public.playlists (profile_id);

-- ─── Row Level Security: every user only touches their own rows ─────────────
alter table public.profiles enable row level security;
alter table public.settings enable row level security;
alter table public.liked_songs enable row level security;
alter table public.history enable row level security;
alter table public.subscriptions enable row level security;
alter table public.playlists enable row level security;

drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using (auth.uid() = id);
drop policy if exists "profiles_insert" on public.profiles;
create policy "profiles_insert" on public.profiles
  for insert with check (auth.uid() = id);
drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "profiles_delete" on public.profiles;
create policy "profiles_delete" on public.profiles
  for delete using (auth.uid() = id);

drop policy if exists "settings_own" on public.settings;
create policy "settings_own" on public.settings
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

drop policy if exists "liked_own" on public.liked_songs;
create policy "liked_own" on public.liked_songs
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

drop policy if exists "history_own" on public.history;
create policy "history_own" on public.history
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

drop policy if exists "subscriptions_own" on public.subscriptions;
create policy "subscriptions_own" on public.subscriptions
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

drop policy if exists "playlists_own" on public.playlists;
create policy "playlists_own" on public.playlists
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ─── updated_at upkeep ──────────────────────────────────────────────────────
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
drop trigger if exists settings_touch on public.settings;
create trigger settings_touch before update on public.settings
  for each row execute function public.touch_updated_at();