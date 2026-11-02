-- =========================================================
-- OneSpase v0.6 migration
-- Run AFTER v0.5 migration.
-- Adds: profile customization, protected usernames, gifts,
-- emoji packs, free-gift rate limit and helper RPCs.
-- Safe to run more than once.
-- =========================================================

-- ---------------------------------------------------------
-- 1. Profile customization
-- ---------------------------------------------------------
alter table public.profiles
  add column if not exists profile_theme text not null default 'purple',
  add column if not exists emoji_status text not null default '',
  add column if not exists music_title text not null default '',
  add column if not exists featured_channel text not null default '';

alter table public.profiles
  drop constraint if exists profiles_profile_theme_check;
alter table public.profiles
  add constraint profiles_profile_theme_check
  check (profile_theme in ('purple', 'blue', 'sunset', 'mint'));

-- ---------------------------------------------------------
-- 2. Protected / reserved usernames
-- ---------------------------------------------------------
create table if not exists public.username_reservations (
  username text primary key,
  reserved_for uuid references public.profiles(id) on delete set null,
  owner_only boolean not null default true,
  reason text,
  created_at timestamptz not null default now()
);

alter table public.username_reservations enable row level security;

-- No public policies: clients should not enumerate the reserve list.

insert into public.username_reservations (username, owner_only, reason)
values
  ('onespase', true, 'Official OneSpase identity'),
  ('roma', true, 'Reserved by OneSpase owner'),
  ('kotost', true, 'Reserved by OneSpase owner'),
  ('mzdiff', true, 'Reserved by OneSpase owner'),
  ('telegram', true, 'Protected third-party brand name'),
  ('vk', true, 'Protected third-party brand name'),
  ('vkontakte', true, 'Protected third-party brand name'),
  ('whatsapp', true, 'Protected third-party brand name'),
  ('instagram', true, 'Protected third-party brand name'),
  ('facebook', true, 'Protected third-party brand name'),
  ('messenger', true, 'Protected third-party brand name'),
  ('discord', true, 'Protected third-party brand name'),
  ('signal', true, 'Protected third-party brand name'),
  ('snapchat', true, 'Protected third-party brand name'),
  ('tiktok', true, 'Protected third-party brand name'),
  ('youtube', true, 'Protected third-party brand name'),
  ('twitter', true, 'Protected third-party brand name'),
  ('threads', true, 'Protected third-party brand name'),
  ('viber', true, 'Protected third-party brand name'),
  ('wechat', true, 'Protected third-party brand name'),
  ('line', true, 'Protected third-party brand name')
on conflict (username) do nothing;

create or replace function public.username_allowed(candidate text, claimant uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  normalized text := lower(trim(coalesce(candidate, '')));
  row_data public.username_reservations%rowtype;
begin
  if normalized = '' then return false; end if;

  select * into row_data
  from public.username_reservations r
  where r.username = normalized;

  if not found then return true; end if;
  if row_data.reserved_for is not null and row_data.reserved_for = claimant then
    return true;
  end if;
  if public.is_owner() then return true; end if;
  return false;
end;
$$;

revoke all on function public.username_allowed(text, uuid) from public;
grant execute on function public.username_allowed(text, uuid) to authenticated;

create or replace function public.protect_reserved_username()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.username := lower(trim(new.username));
  if not public.username_allowed(new.username, new.id) then
    raise exception 'Reserved username: contact OneSpase owner';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_reserved_username_trigger on public.profiles;
create trigger protect_reserved_username_trigger
before insert or update of username on public.profiles
for each row execute function public.protect_reserved_username();

create or replace function public.reserve_username(
  target_username text,
  target_user uuid default null,
  reserve_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized text := lower(trim(replace(coalesce(target_username, ''), '@', '')));
begin
  if not public.is_owner() then
    raise exception 'Owner access required';
  end if;
  if normalized !~ '^[a-z0-9_]{3,30}$' then
    raise exception 'Invalid username';
  end if;

  insert into public.username_reservations(username, reserved_for, owner_only, reason)
  values(normalized, target_user, target_user is null, nullif(trim(coalesce(reserve_reason, '')), ''))
  on conflict (username) do update set
    reserved_for = excluded.reserved_for,
    owner_only = excluded.owner_only,
    reason = excluded.reason;
end;
$$;

revoke all on function public.reserve_username(text, uuid, text) from public;
grant execute on function public.reserve_username(text, uuid, text) to authenticated;

-- ---------------------------------------------------------
-- 3. Gifts: free beta system, no real-money trading
-- ---------------------------------------------------------
create table if not exists public.gift_catalog (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  emoji text not null,
  rarity text not null default 'common'
    check (rarity in ('common', 'rare', 'epic', 'legendary')),
  accent text not null default 'purple',
  description text not null default '',
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create sequence if not exists public.gift_serial_seq start 1;

create table if not exists public.user_gifts (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  gift_id uuid not null references public.gift_catalog(id) on delete restrict,
  serial_number bigint not null default nextval('public.gift_serial_seq'),
  note text,
  pinned boolean not null default false,
  received_at timestamptz not null default now()
);

create index if not exists user_gifts_recipient_idx
  on public.user_gifts(recipient_id, received_at desc);
create index if not exists user_gifts_sender_daily_idx
  on public.user_gifts(sender_id, received_at desc);

alter table public.gift_catalog enable row level security;
alter table public.user_gifts enable row level security;

drop policy if exists "gift catalog readable" on public.gift_catalog;
create policy "gift catalog readable"
  on public.gift_catalog for select to authenticated using (enabled = true);

drop policy if exists "own gifts readable" on public.user_gifts;
create policy "own gifts readable"
  on public.user_gifts for select to authenticated
  using (recipient_id = auth.uid() or sender_id = auth.uid());

insert into public.gift_catalog(slug, title, emoji, rarity, accent, description, sort_order)
values
  ('rocket', 'Ракета', '🚀', 'common', 'blue', 'Первый подарок OneSpase', 10),
  ('purple_heart', 'Фиолетовое сердце', '💜', 'rare', 'purple', 'Тёплый подарок для профиля', 20),
  ('moon', 'Лунный свет', '🌙', 'rare', 'blue', 'Для ночных чатов', 30),
  ('crown', 'Корона', '👑', 'epic', 'sunset', 'Особенный подарок', 40),
  ('comet', 'Комета', '☄️', 'legendary', 'purple', 'Редкий подарок ранней beta', 50)
on conflict (slug) do update set
  title = excluded.title,
  emoji = excluded.emoji,
  rarity = excluded.rarity,
  accent = excluded.accent,
  description = excluded.description,
  sort_order = excluded.sort_order;

create or replace function public.send_free_gift(
  target_user uuid,
  gift_slug text,
  gift_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  selected_gift uuid;
  created_id uuid;
  sent_today integer;
begin
  if me is null then raise exception 'Authentication required'; end if;
  if target_user = me then raise exception 'Cannot send a gift to yourself'; end if;
  if not exists(select 1 from public.profiles where id = target_user) then
    raise exception 'User not found';
  end if;

  select id into selected_gift
  from public.gift_catalog
  where slug = gift_slug and enabled = true;
  if selected_gift is null then raise exception 'Gift not found'; end if;

  select count(*) into sent_today
  from public.user_gifts
  where sender_id = me
    and received_at >= date_trunc('day', now());
  if sent_today >= 10 then raise exception 'Daily gift limit reached'; end if;

  insert into public.user_gifts(recipient_id, sender_id, gift_id, note)
  values(target_user, me, selected_gift, left(nullif(trim(coalesce(gift_note, '')), ''), 280))
  returning id into created_id;
  return created_id;
end;
$$;

revoke all on function public.send_free_gift(uuid, text, text) from public;
grant execute on function public.send_free_gift(uuid, text, text) to authenticated;

create or replace function public.list_my_gifts()
returns table (
  id uuid,
  slug text,
  title text,
  emoji text,
  rarity text,
  accent text,
  description text,
  serial_number bigint,
  sender_name text,
  received_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ug.id,
    gc.slug,
    gc.title,
    gc.emoji,
    gc.rarity,
    gc.accent,
    gc.description,
    ug.serial_number,
    p.display_name as sender_name,
    ug.received_at
  from public.user_gifts ug
  join public.gift_catalog gc on gc.id = ug.gift_id
  join public.profiles p on p.id = ug.sender_id
  where ug.recipient_id = auth.uid()
  order by ug.pinned desc, ug.received_at desc;
$$;

revoke all on function public.list_my_gifts() from public;
grant execute on function public.list_my_gifts() to authenticated;

-- ---------------------------------------------------------
-- 4. Emoji packs beta
-- ---------------------------------------------------------
create table if not exists public.emoji_packs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  slug text not null unique,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.emoji_items (
  id bigint generated by default as identity primary key,
  pack_id uuid not null references public.emoji_packs(id) on delete cascade,
  emoji text not null,
  sort_order integer not null default 0
);

alter table public.emoji_packs enable row level security;
alter table public.emoji_items enable row level security;

drop policy if exists "public emoji packs readable" on public.emoji_packs;
create policy "public emoji packs readable"
  on public.emoji_packs for select to authenticated
  using (is_public = true or owner_id = auth.uid());

drop policy if exists "emoji items readable with pack" on public.emoji_items;
create policy "emoji items readable with pack"
  on public.emoji_items for select to authenticated
  using (exists(
    select 1 from public.emoji_packs ep
    where ep.id = pack_id and (ep.is_public = true or ep.owner_id = auth.uid())
  ));

create or replace function public.create_emoji_pack(
  pack_title text,
  pack_slug text,
  pack_emojis text[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  normalized text := lower(trim(replace(coalesce(pack_slug, ''), '@', '')));
  new_id uuid;
  idx integer := 0;
  item text;
begin
  if me is null then raise exception 'Authentication required'; end if;
  if length(trim(coalesce(pack_title, ''))) < 2 then raise exception 'Title too short'; end if;
  if normalized !~ '^[a-z0-9_]{3,30}$' then raise exception 'Invalid pack slug'; end if;
  if cardinality(pack_emojis) < 1 or cardinality(pack_emojis) > 50 then
    raise exception 'Pack must contain 1..50 emoji';
  end if;

  insert into public.emoji_packs(owner_id, title, slug)
  values(me, left(trim(pack_title), 60), normalized)
  returning id into new_id;

  foreach item in array pack_emojis loop
    idx := idx + 1;
    insert into public.emoji_items(pack_id, emoji, sort_order)
    values(new_id, left(item, 16), idx);
  end loop;
  return new_id;
end;
$$;

revoke all on function public.create_emoji_pack(text, text, text[]) from public;
grant execute on function public.create_emoji_pack(text, text, text[]) to authenticated;

create or replace function public.list_my_emoji_packs()
returns table (
  id uuid,
  title text,
  slug text,
  emojis text[],
  is_public boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ep.id,
    ep.title,
    ep.slug,
    coalesce(array_agg(ei.emoji order by ei.sort_order) filter (where ei.id is not null), '{}'::text[]) as emojis,
    ep.is_public
  from public.emoji_packs ep
  left join public.emoji_items ei on ei.pack_id = ep.id
  where ep.owner_id = auth.uid()
  group by ep.id
  order by ep.created_at desc;
$$;

revoke all on function public.list_my_emoji_packs() from public;
grant execute on function public.list_my_emoji_packs() to authenticated;

-- ---------------------------------------------------------
-- 5. Refresh profile RPCs with customization fields
-- ---------------------------------------------------------
drop function if exists public.get_profile_with_badge(uuid);
create function public.get_profile_with_badge(target_user uuid)
returns table (
  id uuid,
  display_name text,
  username text,
  status text,
  bio text,
  avatar_url text,
  online boolean,
  verification text,
  profile_theme text,
  emoji_status text,
  music_title text,
  featured_channel text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return query
  select p.id, p.display_name, p.username, p.status, p.bio, p.avatar_url,
         p.online, coalesce(b.badge, 'none'), p.profile_theme,
         p.emoji_status, p.music_title, p.featured_channel
  from public.profiles p
  left join public.account_badges b on b.user_id = p.id
  where p.id = target_user
  limit 1;
end;
$$;

revoke all on function public.get_profile_with_badge(uuid) from public;
grant execute on function public.get_profile_with_badge(uuid) to authenticated;

drop function if exists public.search_people(text, boolean);
create function public.search_people(
  search_text text default '',
  include_self boolean default false
)
returns table (
  id uuid,
  display_name text,
  username text,
  status text,
  bio text,
  avatar_url text,
  online boolean,
  verification text,
  profile_theme text,
  emoji_status text,
  music_title text,
  featured_channel text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text := trim(coalesce(search_text, ''));
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return query
  select p.id, p.display_name, p.username, p.status, p.bio, p.avatar_url,
         p.online, coalesce(b.badge, 'none'), p.profile_theme,
         p.emoji_status, p.music_title, p.featured_channel
  from public.profiles p
  left join public.account_badges b on b.user_id = p.id
  where (include_self or p.id <> auth.uid())
    and (q = '' or p.username ilike '%' || q || '%' or p.display_name ilike '%' || q || '%')
  order by p.online desc, p.display_name asc
  limit 40;
end;
$$;

revoke all on function public.search_people(text, boolean) from public;
grant execute on function public.search_people(text, boolean) to authenticated;

-- ---------------------------------------------------------
-- 6. Grants (RLS still applies)
-- ---------------------------------------------------------
grant select on public.gift_catalog to authenticated;
grant select on public.user_gifts to authenticated;
grant select on public.emoji_packs to authenticated;
grant select on public.emoji_items to authenticated;
