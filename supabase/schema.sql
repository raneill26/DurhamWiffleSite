-- ============================================================================
-- Durham Softball - Supabase schema
-- Run once in the Supabase SQL editor (Dashboard > SQL Editor > New query).
--
-- Security model
--   * The browser only ever uses the ANON key. That is safe by design, but ONLY
--     because every table has Row Level Security on and no policies, so direct
--     table access is denied. All access goes through the functions below.
--   * Team passcodes are bcrypt hashed, never sent to the browser.
--   * The service_role key must NEVER appear in this repo or any page.
-- ============================================================================

create extension if not exists pgcrypto;

-- ============================================================================
-- IDEMPOTENT RESET
-- Postgres treats a changed argument list as a NEW function, so re-running this
-- file after a signature change would leave duplicate overloads behind and
-- PostgREST would refuse to choose between them. Drop every overload of our
-- own functions first, then recreate them below.
-- Tables and data are untouched.
-- ============================================================================
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('admin_assign_team',
        'admin_clear_players',
        'admin_delete_champion',
        'admin_delete_game',
        'admin_delete_org',
        'admin_delete_photo',
        'admin_delete_player',
        'admin_generate_schedule',
        'admin_list_players',
        'admin_login',
        'admin_new_season',
        'admin_registrations',
        'admin_save_champion',
        'admin_save_game',
        'admin_save_org',
        'admin_save_photo',
        'admin_save_player',
        'admin_set_current_season',
        'admin_set_paid',
        'admin_set_photo_placement',
        'admin_set_score',
        'admin_set_setting',
        'admin_set_team_passcode',
        'get_settings',
        'is_admin',
        'list_champions',
        'list_games',
        'list_organizations',
        'list_photos',
        'list_photos_by_placement',
        'list_players',
        'list_seasons',
        'mark_attendance',
        'public_teams',
        'register_player',
        'session_team',
        'set_admin_passcode',
        'set_team_passcode',
        'team_login',
        'team_roster')
  loop
    execute 'drop function if exists ' || r.sig;
  end loop;
end $$;


create table if not exists seasons (
  id          text primary key,
  label       text not null,
  starts_on   date,
  is_current  boolean not null default false
);
-- backfill columns missing from an older version of this table
alter table seasons add column if not exists label text;
alter table seasons add column if not exists starts_on date;
alter table seasons add column if not exists is_current boolean default false;

create table if not exists teams (
  id            text primary key,
  name          text not null,
  league        text not null check (league in ('A','B')),
  season_id     text not null references seasons(id) on delete cascade,
  passcode_hash text,
  created_at    timestamptz not null default now()
);
-- backfill columns missing from an older version of this table
alter table teams add column if not exists name text;
alter table teams add column if not exists league text check (league in ('A','B'));
alter table teams add column if not exists season_id text references seasons(id) on delete cascade;
alter table teams add column if not exists passcode_hash text;
alter table teams add column if not exists created_at timestamptz default now();

create table if not exists players (
  id          uuid primary key default gen_random_uuid(),
  full_name   text not null,
  email       text not null,
  phone       text,
  team_id     text references teams(id) on delete set null,
  season_id   text not null references seasons(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (email, season_id)
);
-- backfill columns missing from an older version of this table
alter table players add column if not exists full_name text;
alter table players add column if not exists email text;
alter table players add column if not exists phone text;
alter table players add column if not exists team_id text references teams(id) on delete set null;
alter table players add column if not exists season_id text references seasons(id) on delete cascade;
alter table players add column if not exists created_at timestamptz default now();

-- One signed waiver per player per season.
create table if not exists waivers (
  id               uuid primary key default gen_random_uuid(),
  player_id        uuid not null references players(id) on delete cascade,
  season_id        text not null references seasons(id) on delete cascade,
  waiver_version   text not null,
  signed_name      text not null,
  signed_at        timestamptz not null default now(),
  -- Evidence for ESIGN / UETA: exactly what they agreed to, and that they meant it.
  agreed_text_hash text not null,
  signature_image  text,   -- data URL of the drawn signature, null if typed
  ip_address       inet,
  user_agent       text,
  unique (player_id, season_id)
);
-- backfill columns missing from an older version of this table
alter table waivers add column if not exists player_id uuid references players(id) on delete cascade;
alter table waivers add column if not exists season_id text references seasons(id) on delete cascade;
alter table waivers add column if not exists waiver_version text;
alter table waivers add column if not exists signed_name text;
alter table waivers add column if not exists signed_at timestamptz default now();
alter table waivers add column if not exists agreed_text_hash text;
alter table waivers add column if not exists signature_image text;
alter table waivers add column if not exists ip_address inet;
alter table waivers add column if not exists user_agent text;

create table if not exists registrations (
  id           uuid primary key default gen_random_uuid(),
  player_id    uuid not null references players(id) on delete cascade,
  season_id    text not null references seasons(id) on delete cascade,
  amount_cents integer,
  currency     text not null default 'usd',
  status       text not null default 'pending'
               check (status in ('pending','paid','refunded','waived')),
  provider     text,
  provider_ref text,
  created_at   timestamptz not null default now(),
  unique (player_id, season_id)
);
-- backfill columns missing from an older version of this table
alter table registrations add column if not exists player_id uuid references players(id) on delete cascade;
alter table registrations add column if not exists season_id text references seasons(id) on delete cascade;
alter table registrations add column if not exists amount_cents integer;
alter table registrations add column if not exists currency text default 'usd';
alter table registrations add column if not exists status text default 'pending' check (status in ('pending','paid','refunded','waived'));
alter table registrations add column if not exists provider text;
alter table registrations add column if not exists provider_ref text;
alter table registrations add column if not exists created_at timestamptz default now();

create table if not exists attendance (
  id          uuid primary key default gen_random_uuid(),
  game_id     integer not null,
  team_id     text not null references teams(id) on delete cascade,
  player_id   uuid not null references players(id) on delete cascade,
  status      text not null default 'in' check (status in ('in','out','maybe')),
  noted_by    text,
  updated_at  timestamptz not null default now(),
  unique (game_id, player_id)
);
-- backfill columns missing from an older version of this table
alter table attendance add column if not exists game_id integer;
alter table attendance add column if not exists team_id text references teams(id) on delete cascade;
alter table attendance add column if not exists player_id uuid references players(id) on delete cascade;
alter table attendance add column if not exists status text default 'in' check (status in ('in','out','maybe'));
alter table attendance add column if not exists noted_by text;
alter table attendance add column if not exists updated_at timestamptz default now();

create index if not exists attendance_game_team_idx on attendance (game_id, team_id);
create index if not exists players_team_idx on players (team_id, season_id);

create table if not exists team_sessions (
  token      uuid primary key default gen_random_uuid(),
  team_id    text not null references teams(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '12 hours'
);
-- backfill columns missing from an older version of this table
alter table team_sessions add column if not exists team_id text references teams(id) on delete cascade;
alter table team_sessions add column if not exists expires_at timestamptz default now() + interval '12 hours';

-- Deny everything by default. No policies are created on purpose.
alter table seasons       enable row level security;
alter table teams         enable row level security;
alter table players       enable row level security;
alter table waivers       enable row level security;
alter table registrations enable row level security;
alter table attendance    enable row level security;
alter table team_sessions enable row level security;

-- ---------------------------------------------------------------- public read
create or replace function public_teams(p_season text)
returns table (id text, name text, league text, has_login boolean)
language sql security definer set search_path = public, extensions as $$
  select t.id, t.name, t.league, (t.passcode_hash is not null)
  from teams t where t.season_id = p_season order by t.name;
$$;

-- ---------------------------------------------------------------- team login
create or replace function team_login(p_team_id text, p_passcode text)
returns table (token uuid, team_id text, team_name text, expires_at timestamptz)
language plpgsql security definer set search_path = public, extensions as $$
#variable_conflict use_column
-- token, team_id and expires_at are all output variables AND real columns.
declare v_hash text; v_name text; v_token uuid; v_exp timestamptz;
begin
  select t.passcode_hash, t.name into v_hash, v_name from teams t where t.id = p_team_id;
  if v_hash is null or not (crypt(p_passcode, v_hash) = v_hash) then
    raise exception 'invalid passcode' using errcode = '28000';
  end if;
  delete from team_sessions s where s.expires_at < now();
  insert into team_sessions (team_id) values (p_team_id)
    returning team_sessions.token, team_sessions.expires_at into v_token, v_exp;
  token := v_token;
  team_id := p_team_id;
  team_name := v_name;
  expires_at := v_exp;
  return next;
end; $$;

create or replace function session_team(p_token uuid)
returns text language sql security definer set search_path = public, extensions as $$
  select team_id from team_sessions where token = p_token and expires_at > now();
$$;

-- ---------------------------------------------------------------- attendance

create or replace function mark_attendance(
  p_token uuid, p_game_id integer, p_player_id uuid, p_status text, p_noted_by text default null)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_team text;
begin
  v_team := session_team(p_token);
  if v_team is null then raise exception 'session expired' using errcode = '28000'; end if;
  if not exists (select 1 from players where id = p_player_id and team_id = v_team) then
    raise exception 'player not on this team' using errcode = '42501';
  end if;
  insert into attendance (game_id, team_id, player_id, status, noted_by)
  values (p_game_id, v_team, p_player_id, p_status, p_noted_by)
  on conflict (game_id, player_id)
  do update set status = excluded.status, noted_by = excluded.noted_by, updated_at = now();
end; $$;

-- ---------------------------------------------------------------- registration

-- ---------------------------------------------------------------- grants
-- ---------------------------------------------------------------- admin only
-- Run from the SQL editor:  select set_team_passcode('alp416', 'legion2026');
create or replace function set_team_passcode(p_team_id text, p_passcode text)
returns void language sql security definer set search_path = public, extensions as $$
  update teams set passcode_hash = crypt(p_passcode, gen_salt('bf', 10)) where id = p_team_id;
$$;
-- ============================================================================
-- ADMIN
-- Lets the league owner manage photos and roll the season over without code.
-- Same pattern as team login: one passcode, hashed, server-verified, token.
-- ============================================================================

create table if not exists admin_settings (
  id            boolean primary key default true check (id),
  passcode_hash text
);
-- backfill columns missing from an older version of this table
alter table admin_settings add column if not exists passcode_hash text;
insert into admin_settings (id) values (true) on conflict (id) do nothing;

create table if not exists admin_sessions (
  token      uuid primary key default gen_random_uuid(),
  expires_at timestamptz not null default now() + interval '8 hours'
);
-- backfill columns missing from an older version of this table
alter table admin_sessions add column if not exists expires_at timestamptz default now() + interval '8 hours';

create table if not exists photos (
  id         uuid primary key default gen_random_uuid(),
  url        text not null,
  caption    text,
  season_id  text references seasons(id) on delete set null,
  sort_order integer not null default 0,
  is_wide    boolean not null default false,
  created_at timestamptz not null default now()
);
-- backfill columns missing from an older version of this table
alter table photos add column if not exists url text;
alter table photos add column if not exists caption text;
alter table photos add column if not exists season_id text references seasons(id) on delete set null;
alter table photos add column if not exists sort_order integer default 0;
alter table photos add column if not exists is_wide boolean default false;
alter table photos add column if not exists created_at timestamptz default now();

create table if not exists champions (
  id        uuid primary key default gen_random_uuid(),
  season_id text references seasons(id) on delete set null,
  label     text not null,              -- 'Spring 2025' when there is no season row
  league    text,
  team_name text,
  photo_url text,
  caption   text
);
-- backfill columns missing from an older version of this table
alter table champions add column if not exists season_id text references seasons(id) on delete set null;
alter table champions add column if not exists label text;
alter table champions add column if not exists league text;
alter table champions add column if not exists team_name text;
alter table champions add column if not exists photo_url text;
alter table champions add column if not exists caption text;

alter table admin_settings enable row level security;
alter table admin_sessions enable row level security;
alter table photos         enable row level security;
alter table champions      enable row level security;

-- Set the admin passcode from the SQL editor:
--   select set_admin_passcode('something-long');
create or replace function set_admin_passcode(p_passcode text)
returns void language sql security definer set search_path = public, extensions as $$
  update admin_settings set passcode_hash = crypt(p_passcode, gen_salt('bf', 10)) where id;
$$;
create or replace function admin_login(p_passcode text)
returns table (token uuid, expires_at timestamptz)
language plpgsql security definer set search_path = public, extensions as $$
#variable_conflict use_column
-- RETURNS TABLE names become plpgsql variables, so a bare column of the same
-- name is ambiguous. Resolve clashes in favour of the column.
declare v_hash text; v_token uuid; v_exp timestamptz;
begin
  select a.passcode_hash into v_hash from admin_settings a where a.id;
  if v_hash is null or not (crypt(p_passcode, v_hash) = v_hash) then
    raise exception 'invalid passcode' using errcode = '28000';
  end if;
  delete from admin_sessions s where s.expires_at < now();
  insert into admin_sessions default values
    returning admin_sessions.token, admin_sessions.expires_at into v_token, v_exp;
  token := v_token;
  expires_at := v_exp;
  return next;
end; $$;

create or replace function is_admin(p_token uuid)
returns boolean language sql security definer set search_path = public, extensions as $$
  select exists (select 1 from admin_sessions where token = p_token and expires_at > now());
$$;
-- ---------------------------------------------------------------- photos
create or replace function list_photos(p_season text default null)
returns table (id uuid, url text, caption text, season_id text, sort_order integer, is_wide boolean)
language sql security definer set search_path = public, extensions as $$
  select p.id, p.url, p.caption, p.season_id, p.sort_order, p.is_wide
  from photos p
  where p_season is null or p.season_id = p_season
  order by p.sort_order, p.created_at desc;
$$;

create or replace function admin_save_photo(
  p_token uuid, p_id uuid, p_url text, p_caption text, p_season text,
  p_sort integer default 0, p_wide boolean default false)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_id uuid;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_id is null then
    insert into photos (url, caption, season_id, sort_order, is_wide)
    values (p_url, p_caption, p_season, p_sort, p_wide) returning id into v_id;
  else
    update photos set url=p_url, caption=p_caption, season_id=p_season,
                      sort_order=p_sort, is_wide=p_wide
    where id=p_id returning id into v_id;
  end if;
  return v_id;
end; $$;

create or replace function admin_delete_photo(p_token uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  delete from photos where id = p_id;
end; $$;

-- ---------------------------------------------------------------- champions
create or replace function list_champions()
returns table (id uuid, label text, league text, team_name text, photo_url text, caption text)
language sql security definer set search_path = public, extensions as $$
  select c.id, c.label, c.league, c.team_name, c.photo_url, c.caption
  from champions c order by c.label desc;
$$;

create or replace function admin_save_champion(
  p_token uuid, p_id uuid, p_label text, p_league text,
  p_team text, p_photo text, p_caption text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_id uuid;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_id is null then
    insert into champions (label, league, team_name, photo_url, caption)
    values (p_label, p_league, p_team, p_photo, p_caption) returning id into v_id;
  else
    update champions set label=p_label, league=p_league, team_name=p_team,
                         photo_url=p_photo, caption=p_caption
    where id=p_id returning id into v_id;
  end if;
  return v_id;
end; $$;

create or replace function admin_delete_champion(p_token uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  delete from champions where id = p_id;
end; $$;

-- ---------------------------------------------------------------- seasons
create or replace function list_seasons()
returns table (id text, label text, starts_on date, is_current boolean, team_count bigint)
language sql security definer set search_path = public, extensions as $$
  select s.id, s.label, s.starts_on, s.is_current,
         (select count(*) from teams t where t.season_id = s.id)
  from seasons s order by s.starts_on desc nulls last, s.id desc;
$$;

-- Roll the league into a new season. Optionally carry the current teams over,
-- which is the normal case: same charities, fresh records.
create or replace function admin_new_season(
  p_token uuid, p_id text, p_label text, p_starts date,
  p_copy_teams boolean default true, p_make_current boolean default true)
returns text language plpgsql security definer set search_path = public, extensions as $$
declare v_prev text;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_id is null or length(trim(p_id)) = 0 then raise exception 'season id required'; end if;

  select id into v_prev from seasons where is_current limit 1;

  insert into seasons (id, label, starts_on, is_current)
  values (trim(p_id), p_label, p_starts, false)
  on conflict (id) do update set label = excluded.label, starts_on = excluded.starts_on;

  if p_copy_teams and v_prev is not null then
    insert into teams (id, name, league, season_id)
    select t.id || '-' || trim(p_id), t.name, t.league, trim(p_id)
    from teams t where t.season_id = v_prev
    on conflict (id) do nothing;
  end if;

  if p_make_current then
    update seasons set is_current = false;
    update seasons set is_current = true where id = trim(p_id);
  end if;

  return trim(p_id);
end; $$;

create or replace function admin_set_current_season(p_token uuid, p_id text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  update seasons set is_current = false;
  update seasons set is_current = true where id = p_id;
end; $$;

create or replace function admin_set_team_passcode(p_token uuid, p_team_id text, p_passcode text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  update teams set passcode_hash = crypt(p_passcode, gen_salt('bf', 10)) where id = p_team_id;
end; $$;

-- ============================================================================
-- Storage bucket for uploaded photos.
-- Create a PUBLIC bucket named "photos" in Dashboard > Storage, then run this
-- so signed-in admins can upload and the public can read.
-- ============================================================================
-- insert into storage.buckets (id, name, public) values ('photos','photos',true)
--   on conflict (id) do nothing;
--
-- create policy "public read photos" on storage.objects
--   for select using (bucket_id = 'photos');
-- create policy "anon upload photos" on storage.objects
--   for insert with check (bucket_id = 'photos');

-- ============================================================================
-- SCHEDULE, ROSTERS, RESULTS  (admin-managed)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- An earlier version of this file created `games` with different column names
-- (home_team_id / away_team_id, integer id). Adding columns on top of that
-- would leave the table with both sets and a wrong id type, so rebuild it
-- instead. Only ever rebuilds when the table holds no rows: if there are
-- games recorded, it stops and asks you to deal with them deliberately.
-- ----------------------------------------------------------------------------
do $$
declare n integer;
begin
  if to_regclass('public.games') is not null
     and not exists (select 1 from information_schema.columns
                     where table_schema='public' and table_name='games'
                       and column_name='home_team') then
    execute 'select count(*) from games' into n;
    if n > 0 then
      raise exception
        'games has % rows in an old layout. Export them, run "drop table games cascade", then re-run this file.', n;
    end if;
    drop table games cascade;
    raise notice 'rebuilt the empty games table in the current layout';
  end if;
end $$;

create table if not exists games (
  id          uuid primary key default gen_random_uuid(),
  season_id   text not null references seasons(id) on delete cascade,
  legacy_id   integer,                    -- the league's own game id, if any
  game_date   date not null,
  game_time   time not null,
  home_team   text not null references teams(id) on delete cascade,
  away_team   text not null references teams(id) on delete cascade,
  league      text check (league in ('A','B')),
  venue       text default 'Pineywood Park',
  home_score  integer,
  away_score  integer,
  status      text not null default 'scheduled'
              check (status in ('scheduled','final','rainout','forfeit')),
  created_at  timestamptz not null default now(),
  check (home_team <> away_team)
);
-- backfill columns missing from an older version of this table
alter table games add column if not exists season_id text references seasons(id) on delete cascade;
alter table games add column if not exists legacy_id integer;
alter table games add column if not exists game_date date;
alter table games add column if not exists game_time time;
alter table games add column if not exists home_team text references teams(id) on delete cascade;
alter table games add column if not exists away_team text references teams(id) on delete cascade;
alter table games add column if not exists league text check (league in ('A','B'));
alter table games add column if not exists venue text default 'Pineywood Park';
alter table games add column if not exists home_score integer;
alter table games add column if not exists away_score integer;
alter table games add column if not exists status text default 'scheduled' check (status in ('scheduled','final','rainout','forfeit'));
alter table games add column if not exists created_at timestamptz default now();
create index if not exists games_season_date_idx on games (season_id, game_date, game_time);

alter table games enable row level security;

-- photo placement: where a photo is allowed to surface
alter table photos add column if not exists placement text not null default 'gallery';
-- 'gallery' | 'home' | 'hero' | 'champions'

-- ---------------------------------------------------------------- public read
create or replace function list_games(p_season text)
returns table (id uuid, legacy_id integer, game_date date, game_time time,
               home_team text, away_team text, league text, venue text,
               home_score integer, away_score integer, status text)
language sql security definer set search_path = public, extensions as $$
  select g.id, g.legacy_id, g.game_date, g.game_time, g.home_team, g.away_team,
         g.league, g.venue, g.home_score, g.away_score, g.status
  from games g where g.season_id = p_season
  order by g.game_date, g.game_time;
$$;

create or replace function list_players(p_season text)
returns table (id uuid, full_name text, email text, team_id text, waiver_signed boolean)
language sql security definer set search_path = public, extensions as $$
  select p.id, p.full_name, p.email, p.team_id,
         exists (select 1 from waivers w where w.player_id = p.id and w.season_id = p.season_id)
  from players p where p.season_id = p_season order by p.team_id nulls first, p.full_name;
$$;

-- ---------------------------------------------------------------- games admin
create or replace function admin_save_game(
  p_token uuid, p_id uuid, p_season text, p_date date, p_time time,
  p_home text, p_away text, p_venue text default 'Pineywood Park',
  p_home_score integer default null, p_away_score integer default null,
  p_status text default 'scheduled')
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_id uuid; v_league text;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_home = p_away then raise exception 'a team cannot play itself'; end if;
  select league into v_league from teams where id = p_home and season_id = p_season;
  if v_league is null then raise exception 'home team is not in this season'; end if;
  if not exists (select 1 from teams where id = p_away and season_id = p_season) then
    raise exception 'away team is not in this season';
  end if;

  if p_id is null then
    insert into games (season_id, game_date, game_time, home_team, away_team, league,
                       venue, home_score, away_score, status)
    values (p_season, p_date, p_time, p_home, p_away, v_league,
            coalesce(p_venue,'Pineywood Park'), p_home_score, p_away_score, p_status)
    returning id into v_id;
  else
    update games set game_date=p_date, game_time=p_time, home_team=p_home, away_team=p_away,
                     league=v_league, venue=coalesce(p_venue,'Pineywood Park'),
                     home_score=p_home_score, away_score=p_away_score, status=p_status
    where id=p_id returning id into v_id;
  end if;
  return v_id;
end; $$;

create or replace function admin_delete_game(p_token uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  delete from games where id = p_id;
end; $$;

create or replace function admin_set_score(
  p_token uuid, p_id uuid, p_home_score integer, p_away_score integer, p_status text default 'final')
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  update games set home_score=p_home_score, away_score=p_away_score, status=p_status where id=p_id;
end; $$;

-- Generate a full round-robin slate for a season. Wipes any existing scheduled
-- games for that season first (finals and results are preserved).
create or replace function admin_generate_schedule(
  p_token uuid, p_season text, p_first_date date, p_weeks integer,
  p_first_time time default '09:10', p_slot_minutes integer default 55)
returns integer language plpgsql security definer set search_path = public, extensions as $$
declare
  v_made integer := 0;
  v_week integer;
  v_date date;
  v_slot integer;
  r record;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;

  delete from games where season_id = p_season and status = 'scheduled';

  for v_week in 0 .. p_weeks - 1 loop
    v_date := p_first_date + (v_week * 7);
    v_slot := 0;
    for r in
      -- circle-method pairing per league, rotated by week
      with t as (
        select id, league, row_number() over (partition by league order by name) - 1 as n,
               count(*) over (partition by league) as total
        from teams where season_id = p_season
      ),
      pairs as (
        select a.league,
               case when v_week % 2 = 0 then a.id else b.id end as home,
               case when v_week % 2 = 0 then b.id else a.id end as away,
               a.n as ord
        from t a join t b
          on a.league = b.league
         and b.n = ( (a.total - 1) - ((a.n + v_week) % (a.total - 1)) ) % a.total
         and a.n < b.n
      )
      select * from pairs order by league, ord
    loop
      insert into games (season_id, game_date, game_time, home_team, away_team, league)
      values (p_season, v_date,
              p_first_time + (v_slot * p_slot_minutes || ' minutes')::interval,
              r.home, r.away, r.league);
      v_slot := v_slot + 1;
      v_made := v_made + 1;
    end loop;
  end loop;
  return v_made;
end; $$;

-- ---------------------------------------------------------------- roster admin
create or replace function admin_save_player(
  p_token uuid, p_id uuid, p_season text, p_name text, p_email text, p_team text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_id uuid;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if length(trim(p_name)) < 2 then raise exception 'name required'; end if;
  if p_id is null then
    insert into players (full_name, email, team_id, season_id)
    values (trim(p_name), lower(trim(p_email)), nullif(p_team,''), p_season)
    on conflict (email, season_id) do update
      set full_name = excluded.full_name, team_id = excluded.team_id
    returning id into v_id;
  else
    update players set full_name=trim(p_name), email=lower(trim(p_email)), team_id=nullif(p_team,'')
    where id=p_id returning id into v_id;
  end if;
  return v_id;
end; $$;

create or replace function admin_delete_player(p_token uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  delete from players where id = p_id;
end; $$;

create or replace function admin_list_players(p_token uuid, p_season text)
returns table (id uuid, full_name text, email text, team_id text, waiver_signed boolean)
language plpgsql security definer set search_path = public, extensions as $$
#variable_conflict use_column
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  return query
    select p.id, p.full_name, p.email, p.team_id,
           exists (select 1 from waivers w where w.player_id = p.id and w.season_id = p.season_id)
    from players p where p.season_id = p_season
    order by p.team_id nulls first, p.full_name;
end; $$;

-- ---------------------------------------------------------------- photo placement
create or replace function admin_set_photo_placement(
  p_token uuid, p_id uuid, p_placement text, p_sort integer)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  update photos set placement = p_placement, sort_order = p_sort where id = p_id;
end; $$;

create or replace function list_photos_by_placement(p_placement text)
returns table (id uuid, url text, caption text, season_id text, sort_order integer, is_wide boolean)
language sql security definer set search_path = public, extensions as $$
  select p.id, p.url, p.caption, p.season_id, p.sort_order, p.is_wide
  from photos p where p.placement = p_placement order by p.sort_order, p.created_at desc;
$$;

-- ============================================================================
-- ORGANIZATIONS  (the charities themselves, admin-managed)
--
-- One row per non-profit, independent of any season. `status` drives the
-- Non-Profit Partners page. League membership is per season and lives in
-- `teams`, so an org can be A League one season and inactive the next
-- without losing its description or logo.
-- ============================================================================

create table if not exists organizations (
  id          text primary key,               -- 'aps', 'bike', matches data.js ids
  name        text not null,
  short_name  text,
  cause       text,                           -- one-line summary
  blurb       text,                           -- the full charity description
  logo_url    text,
  website     text,                           -- their own site
  legacy_url  text,                           -- their page on the old site
  status      text not null default 'inactive'
              check (status in ('active','inactive','former')),
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);
-- backfill columns missing from an older version of this table
alter table organizations add column if not exists name text;
alter table organizations add column if not exists short_name text;
alter table organizations add column if not exists cause text;
alter table organizations add column if not exists blurb text;
alter table organizations add column if not exists logo_url text;
alter table organizations add column if not exists website text;
alter table organizations add column if not exists legacy_url text;
alter table organizations add column if not exists status text default 'inactive' check (status in ('active','inactive','former'));
alter table organizations add column if not exists sort_order integer default 0;
alter table organizations add column if not exists created_at timestamptz default now();

-- Public read: everything except nothing. These are all public-facing fields.
create or replace function list_organizations(p_season text default null)
returns table (id text, name text, short_name text, cause text, blurb text,
               logo_url text, website text, legacy_url text, status text, league text)
language sql security definer set search_path = public, extensions as $$
  select o.id, o.name, o.short_name, o.cause, o.blurb, o.logo_url, o.website,
         o.legacy_url, o.status,
         (select t.league from teams t
           where t.id = o.id and t.season_id = coalesce(p_season,
                 (select s.id from seasons s where s.is_current limit 1)))
  from organizations o
  order by o.sort_order, o.name;
$$;

-- Create or update an org, and its league membership for a season in one go.
-- p_league null removes it from that season's teams.
create or replace function admin_save_org(
  p_token uuid, p_id text, p_name text, p_short text, p_cause text, p_blurb text,
  p_logo text, p_website text, p_legacy text, p_status text,
  p_season text default null, p_league text default null)
returns text language plpgsql security definer set search_path = public, extensions as $$
declare v_season text; v_id text;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;

  v_id := lower(regexp_replace(trim(p_id), '[^a-zA-Z0-9]+', '', 'g'));
  if length(v_id) < 2 then raise exception 'id must be at least 2 letters or digits'; end if;
  if length(trim(coalesce(p_name,''))) < 2 then raise exception 'name required'; end if;
  if p_status not in ('active','inactive','former') then raise exception 'bad status'; end if;
  if p_status = 'active' and p_league is null then
    raise exception 'an active partner needs a league';
  end if;
  if p_league is not null and p_league not in ('A','B') then raise exception 'league must be A or B'; end if;

  insert into organizations (id, name, short_name, cause, blurb, logo_url, website, legacy_url, status)
  values (v_id, trim(p_name), nullif(trim(coalesce(p_short,'')),''), p_cause, p_blurb,
          nullif(trim(coalesce(p_logo,'')),''), nullif(trim(coalesce(p_website,'')),''),
          nullif(trim(coalesce(p_legacy,'')),''), p_status)
  on conflict (id) do update set
    name=excluded.name, short_name=excluded.short_name, cause=excluded.cause,
    blurb=excluded.blurb, logo_url=excluded.logo_url, website=excluded.website,
    legacy_url=excluded.legacy_url, status=excluded.status;

  v_season := coalesce(p_season, (select s.id from seasons s where s.is_current limit 1));

  if v_season is not null then
    if p_league is null then
      delete from teams where id = v_id and season_id = v_season;
    else
      insert into teams (id, name, league, season_id)
      values (v_id, trim(p_name), p_league, v_season)
      on conflict (id) do update set name=excluded.name, league=excluded.league,
                                     season_id=excluded.season_id;
    end if;
  end if;

  return v_id;
end; $$;

create or replace function admin_delete_org(p_token uuid, p_id text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if exists (select 1 from games g join teams t on t.id in (g.home_team, g.away_team) where t.id = p_id) then
    raise exception 'this org has games on record, set it to past instead of deleting';
  end if;
  delete from organizations where id = p_id;
end; $$;

-- ============================================================================
-- REGISTRATION WINDOW + INTAKE
-- ============================================================================

create table if not exists site_settings (
  key   text primary key,
  value text
);
-- backfill columns missing from an older version of this table
alter table site_settings add column if not exists value text;

insert into site_settings (key, value) values
  ('registration_open','false'),
  ('registration_closed_message',
   'Registration for Summer 2026 has now closed. We ended up with 20 teams and more than 350 players on a roster!' || chr(10) || chr(10) ||
   'Our next season starts in March, registration starts in January! Email playncinc@gmail.com to get added to our newsletter for reminders!' || chr(10) || chr(10) ||
   'Thank you!')
on conflict (key) do nothing;

create or replace function get_settings()
returns table (key text, value text)
language sql security definer set search_path = public, extensions as $$
  select s.key, s.value from site_settings s;
$$;

create or replace function admin_set_setting(p_token uuid, p_key text, p_value text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  insert into site_settings (key, value) values (p_key, p_value)
  on conflict (key) do update set value = excluded.value;
end; $$;

-- Intake fields. team_id stays null until an admin assigns it.
alter table players add column if not exists shirt_size        text;
alter table players add column if not exists preferred_team_id text;

-- Registration now records a preference, never a roster placement.
create or replace function register_player(
  p_season text, p_full_name text, p_email text, p_phone text, p_team_id text,
  p_waiver_version text, p_signed_name text, p_agreed_hash text, p_user_agent text,
  p_signature_image text default null, p_shirt_size text default null)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_player uuid;
begin
  if coalesce((select value from site_settings where key='registration_open'),'false') <> 'true' then
    raise exception 'registration is closed';
  end if;
  if length(trim(p_full_name)) < 2 then raise exception 'name required'; end if;
  if p_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'valid email required'; end if;
  if length(trim(p_signed_name)) < 2 then raise exception 'signature required'; end if;

  insert into players (full_name, email, phone, preferred_team_id, shirt_size, season_id)
  values (trim(p_full_name), lower(trim(p_email)), p_phone,
          nullif(p_team_id,''), nullif(p_shirt_size,''), p_season)
  on conflict (email, season_id) do update
    set full_name = excluded.full_name, phone = excluded.phone,
        preferred_team_id = excluded.preferred_team_id, shirt_size = excluded.shirt_size
  returning id into v_player;

  insert into waivers (player_id, season_id, waiver_version, signed_name, agreed_text_hash,
                       user_agent, signature_image)
  values (v_player, p_season, p_waiver_version, trim(p_signed_name), p_agreed_hash,
          p_user_agent, p_signature_image)
  on conflict (player_id, season_id) do nothing;

  insert into registrations (player_id, season_id, status)
  values (v_player, p_season, 'pending')
  on conflict (player_id, season_id) do nothing;

  return v_player;
end; $$;

-- The intake table the admin works from.
create or replace function admin_registrations(p_token uuid, p_season text)
returns table (player_id uuid, full_name text, email text, phone text,
               preferred_team_id text, shirt_size text, waiver_signed boolean,
               paid boolean, team_id text)
language plpgsql security definer set search_path = public, extensions as $$
#variable_conflict use_column
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  return query
    select p.id, p.full_name, p.email, p.phone, p.preferred_team_id, p.shirt_size,
           exists (select 1 from waivers w where w.player_id = p.id and w.season_id = p.season_id),
           coalesce((select r.status = 'paid' from registrations r
                      where r.player_id = p.id and r.season_id = p.season_id), false),
           p.team_id
    from players p where p.season_id = p_season
    order by (p.team_id is not null), p.full_name;
end; $$;

create or replace function admin_assign_team(p_token uuid, p_player uuid, p_team text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  update players set team_id = nullif(p_team,'') where id = p_player;
end; $$;

create or replace function admin_set_paid(p_token uuid, p_player uuid, p_season text, p_paid boolean)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  insert into registrations (player_id, season_id, status)
  values (p_player, p_season, case when p_paid then 'paid' else 'pending' end)
  on conflict (player_id, season_id) do update
    set status = case when p_paid then 'paid' else 'pending' end;
end; $$;

-- Wipe the player base between seasons. Waivers, registrations and attendance
-- cascade from players, so this clears the lot for that season.
create or replace function admin_clear_players(p_token uuid, p_season text, p_confirm text)
returns integer language plpgsql security definer set search_path = public, extensions as $$
declare n integer;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_confirm <> 'CLEAR' then raise exception 'confirmation phrase did not match'; end if;
  select count(*) into n from players where season_id = p_season;
  delete from players where season_id = p_season;
  return n;
end; $$;



-- ============================================================================
-- ROSTER ORDER  (captains reorder their own attendance sheet)
-- ============================================================================

alter table players add column if not exists roster_order integer;

-- The earlier version of this function returned four columns. A return type
-- cannot be changed in place, so drop it before recreating.
drop function if exists team_roster(uuid, integer);

-- Roster now comes back in the captain's chosen order, unordered players last.
create or replace function team_roster(p_token uuid, p_game_id integer)
returns table (player_id uuid, full_name text, status text, waiver_signed boolean, roster_order integer)
language plpgsql security definer set search_path = public, extensions as $$
#variable_conflict use_column
declare v_team text;
begin
  v_team := session_team(p_token);
  if v_team is null then raise exception 'session expired' using errcode = '28000'; end if;
  return query
    select p.id, p.full_name,
           coalesce(a.status, 'maybe'),
           exists (select 1 from waivers w where w.player_id = p.id and w.season_id = p.season_id),
           p.roster_order
    from players p
    left join attendance a on a.player_id = p.id and a.game_id = p_game_id
    where p.team_id = v_team
    order by p.roster_order nulls last, p.full_name;
end; $$;

-- Captains save the whole order in one call: an array of player ids in order.
create or replace function set_roster_order(p_token uuid, p_ids uuid[])
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_team text; i integer;
begin
  v_team := session_team(p_token);
  if v_team is null then raise exception 'session expired' using errcode = '28000'; end if;
  for i in 1 .. coalesce(array_length(p_ids, 1), 0) loop
    update players set roster_order = i
    where id = p_ids[i] and team_id = v_team;   -- scoped: cannot touch another team
  end loop;
end; $$;



-- ============================================================================
-- PLAYER EDITING AND DEDUPLICATION
--
-- A player added by hand and the same person registering online produce two
-- rows, because the upsert key is (email, season_id) and the manual row often
-- has no email. These let the admin fix records in place and merge duplicates.
-- ============================================================================

-- Full edit by id. Unlike admin_save_player this never upserts on email, so
-- correcting someone's address cannot silently collide into another row.
create or replace function admin_update_player(
  p_token uuid, p_id uuid, p_name text, p_email text, p_phone text,
  p_shirt text, p_team text, p_preferred text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_season text; v_clash uuid;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if length(trim(coalesce(p_name,''))) < 2 then raise exception 'name required'; end if;

  select season_id into v_season from players where id = p_id;
  if v_season is null then raise exception 'player not found'; end if;

  if nullif(trim(coalesce(p_email,'')),'') is not null then
    select id into v_clash from players
     where season_id = v_season and lower(email) = lower(trim(p_email)) and id <> p_id;
    if v_clash is not null then
      raise exception 'another player this season already uses that email. Merge them instead.';
    end if;
  end if;

  update players set
    full_name         = trim(p_name),
    email             = lower(nullif(trim(coalesce(p_email,'')),'')),
    phone             = nullif(trim(coalesce(p_phone,'')),''),
    shirt_size        = nullif(trim(coalesce(p_shirt,'')),''),
    team_id           = nullif(p_team,''),
    preferred_team_id = nullif(p_preferred,'')
  where id = p_id;
end; $$;

-- Record or clear a waiver on someone's behalf, for players entered by hand
-- who signed on paper or in a previous system.
create or replace function admin_set_waiver(p_token uuid, p_id uuid, p_signed boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_season text; v_name text;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  select season_id, full_name into v_season, v_name from players where id = p_id;
  if v_season is null then raise exception 'player not found'; end if;

  if p_signed then
    insert into waivers (player_id, season_id, waiver_version, signed_name,
                         agreed_text_hash, user_agent)
    values (p_id, v_season, 'admin-recorded', v_name,
            'recorded-by-admin', coalesce(p_note,'entered by league admin'))
    on conflict (player_id, season_id) do nothing;
  else
    delete from waivers where player_id = p_id and season_id = v_season;
  end if;
end; $$;

-- Fold a duplicate into the record you want to keep, then remove it.
create or replace function admin_merge_players(p_token uuid, p_keep uuid, p_drop uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_season text;
begin
  if not is_admin(p_token) then raise exception 'not signed in' using errcode='28000'; end if;
  if p_keep = p_drop then raise exception 'pick two different players'; end if;

  select season_id into v_season from players where id = p_keep;
  if v_season is null then raise exception 'player to keep not found'; end if;
  if not exists (select 1 from players where id = p_drop and season_id = v_season) then
    raise exception 'both players must be in the same season';
  end if;

  -- fill blanks on the kept record from the duplicate
  update players k set
    email             = coalesce(k.email, d.email),
    phone             = coalesce(k.phone, d.phone),
    shirt_size        = coalesce(k.shirt_size, d.shirt_size),
    team_id           = coalesce(k.team_id, d.team_id),
    preferred_team_id = coalesce(k.preferred_team_id, d.preferred_team_id),
    roster_order      = coalesce(k.roster_order, d.roster_order)
  from players d where k.id = p_keep and d.id = p_drop;

  -- keep a waiver if either had one
  insert into waivers (player_id, season_id, waiver_version, signed_name, agreed_text_hash, user_agent)
  select p_keep, v_season, w.waiver_version, w.signed_name, w.agreed_text_hash, w.user_agent
  from waivers w where w.player_id = p_drop
  on conflict (player_id, season_id) do nothing;

  -- keep a payment if either had one
  update registrations r set status = 'paid'
  where r.player_id = p_keep and r.season_id = v_season
    and exists (select 1 from registrations d
                where d.player_id = p_drop and d.season_id = v_season and d.status = 'paid');

  -- move attendance across, skipping games the kept record already has
  update attendance a set player_id = p_keep
  where a.player_id = p_drop
    and not exists (select 1 from attendance b where b.player_id = p_keep and b.game_id = a.game_id);

  delete from players where id = p_drop;
end; $$;

-- ============================================================================
-- PERMISSIONS  (last, after every function exists)
--
-- Postgres grants EXECUTE to PUBLIC on every new function and anon inherits
-- PUBLIC, so revoking from anon alone is not enough. Strip PUBLIC and anon
-- from all of our functions, then grant back only what the site calls.
-- ============================================================================
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in ('admin_assign_team',
        'admin_clear_players',
        'admin_delete_champion',
        'admin_delete_game',
        'admin_delete_org',
        'admin_delete_photo',
        'admin_delete_player',
        'admin_generate_schedule',
        'admin_list_players',
        'admin_login',
        'admin_merge_players',
        'admin_new_season',
        'admin_registrations',
        'admin_save_champion',
        'admin_save_game',
        'admin_save_org',
        'admin_save_photo',
        'admin_save_player',
        'admin_set_current_season',
        'admin_set_paid',
        'admin_set_photo_placement',
        'admin_set_score',
        'admin_set_setting',
        'admin_set_team_passcode',
        'admin_set_waiver',
        'admin_update_player',
        'get_settings',
        'is_admin',
        'list_champions',
        'list_games',
        'list_organizations',
        'list_photos',
        'list_photos_by_placement',
        'list_players',
        'list_seasons',
        'mark_attendance',
        'public_teams',
        'register_player',
        'session_team',
        'set_admin_passcode',
        'set_roster_order',
        'set_team_passcode',
        'team_login',
        'team_roster')
  loop
    execute 'revoke all on function ' || r.sig || ' from public, anon';
  end loop;
end $$;

revoke all on all tables in schema public from anon;

grant execute on function public_teams(text) to anon;
grant execute on function team_login(text, text) to anon;
grant execute on function team_roster(uuid, integer) to anon;
grant execute on function set_roster_order(uuid, uuid[]) to anon;
grant execute on function mark_attendance(uuid, integer, uuid, text, text) to anon;
grant execute on function register_player(text, text, text, text, text, text, text, text, text, text, text) to anon;
grant execute on function admin_login(text) to anon;
grant execute on function get_settings() to anon;
grant execute on function list_photos(text) to anon;
grant execute on function list_photos_by_placement(text) to anon;
grant execute on function list_champions() to anon;
grant execute on function list_seasons() to anon;
grant execute on function list_games(text) to anon;
grant execute on function list_organizations(text) to anon;
grant execute on function admin_set_setting(uuid, text, text) to anon;
grant execute on function admin_registrations(uuid, text) to anon;
grant execute on function admin_assign_team(uuid, uuid, text) to anon;
grant execute on function admin_set_paid(uuid, uuid, text, boolean) to anon;
grant execute on function admin_clear_players(uuid, text, text) to anon;
grant execute on function admin_update_player(uuid, uuid, text, text, text, text, text, text) to anon;
grant execute on function admin_set_waiver(uuid, uuid, boolean, text) to anon;
grant execute on function admin_merge_players(uuid, uuid, uuid) to anon;
grant execute on function admin_save_org(uuid, text, text, text, text, text, text, text, text, text, text, text) to anon;
grant execute on function admin_delete_org(uuid, text) to anon;
grant execute on function admin_save_photo(uuid, uuid, text, text, text, integer, boolean) to anon;
grant execute on function admin_delete_photo(uuid, uuid) to anon;
grant execute on function admin_set_photo_placement(uuid, uuid, text, integer) to anon;
grant execute on function admin_save_champion(uuid, uuid, text, text, text, text, text) to anon;
grant execute on function admin_delete_champion(uuid, uuid) to anon;
grant execute on function admin_new_season(uuid, text, text, date, boolean, boolean) to anon;
grant execute on function admin_set_current_season(uuid, text) to anon;
grant execute on function admin_set_team_passcode(uuid, text, text) to anon;
grant execute on function admin_save_game(uuid, uuid, text, date, time, text, text, text, integer, integer, text) to anon;
grant execute on function admin_delete_game(uuid, uuid) to anon;
grant execute on function admin_set_score(uuid, uuid, integer, integer, text) to anon;
grant execute on function admin_generate_schedule(uuid, text, date, integer, time, integer) to anon;
grant execute on function admin_save_player(uuid, uuid, text, text, text, text) to anon;
grant execute on function admin_delete_player(uuid, uuid) to anon;
grant execute on function admin_list_players(uuid, text) to anon;

-- Deliberately NOT granted, so a visitor cannot call them:
--   is_admin, session_team, list_players, set_admin_passcode, set_team_passcode
-- Those are for the SQL editor and for other functions to call internally.

notify pgrst, 'reload schema';
