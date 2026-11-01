-- =========================================================
-- OneSpase base schema (v0.4 foundation)
-- Repeatable base for profiles, feed and messenger tables.
-- =========================================================

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  username text not null,
  display_name text not null,
  bio text not null default '',
  status text not null default 'В OneSpase',
  avatar_url text,
  online boolean not null default false,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[A-Za-z0-9_]{3,30}$')
);

create unique index if not exists profiles_username_lower_unique
  on public.profiles (lower(username));

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 5000),
  media_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint follows_not_self check (follower_id <> following_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  title text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 8000),
  created_at timestamptz not null default now(),
  edited_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  kind text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

-- Drop policies so this can be re-run.
drop policy if exists "profiles readable by signed users" on public.profiles;
drop policy if exists "users insert own profile" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
drop policy if exists "posts readable by signed users" on public.posts;
drop policy if exists "users create own posts" on public.posts;
drop policy if exists "users edit own posts" on public.posts;
drop policy if exists "users delete own posts" on public.posts;
drop policy if exists "likes readable by signed users" on public.post_likes;
drop policy if exists "users create own likes" on public.post_likes;
drop policy if exists "users delete own likes" on public.post_likes;
drop policy if exists "comments readable by signed users" on public.comments;
drop policy if exists "users create own comments" on public.comments;
drop policy if exists "users delete own comments" on public.comments;
drop policy if exists "follows readable by signed users" on public.follows;
drop policy if exists "users follow as themselves" on public.follows;
drop policy if exists "users unfollow as themselves" on public.follows;
drop policy if exists "members can see conversations" on public.conversations;
drop policy if exists "signed users can create conversations" on public.conversations;
drop policy if exists "users can see their own memberships" on public.conversation_members;
drop policy if exists "users can join memberships created for them" on public.conversation_members;
drop policy if exists "members can read messages" on public.messages;
drop policy if exists "members send as themselves" on public.messages;
drop policy if exists "senders edit own messages" on public.messages;
drop policy if exists "senders delete own messages" on public.messages;
drop policy if exists "users read own notifications" on public.notifications;
drop policy if exists "users update own notifications" on public.notifications;

create policy "profiles readable by signed users"
  on public.profiles for select to authenticated using (true);
create policy "users insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "users update own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

create policy "posts readable by signed users"
  on public.posts for select to authenticated using (true);
create policy "users create own posts"
  on public.posts for insert to authenticated with check (auth.uid() = author_id);
create policy "users edit own posts"
  on public.posts for update to authenticated using (auth.uid() = author_id)
  with check (auth.uid() = author_id);
create policy "users delete own posts"
  on public.posts for delete to authenticated using (auth.uid() = author_id);

create policy "likes readable by signed users"
  on public.post_likes for select to authenticated using (true);
create policy "users create own likes"
  on public.post_likes for insert to authenticated with check (auth.uid() = user_id);
create policy "users delete own likes"
  on public.post_likes for delete to authenticated using (auth.uid() = user_id);

create policy "comments readable by signed users"
  on public.comments for select to authenticated using (true);
create policy "users create own comments"
  on public.comments for insert to authenticated with check (auth.uid() = author_id);
create policy "users delete own comments"
  on public.comments for delete to authenticated using (auth.uid() = author_id);

create policy "follows readable by signed users"
  on public.follows for select to authenticated using (true);
create policy "users follow as themselves"
  on public.follows for insert to authenticated with check (auth.uid() = follower_id);
create policy "users unfollow as themselves"
  on public.follows for delete to authenticated using (auth.uid() = follower_id);

create policy "members can see conversations"
  on public.conversations for select to authenticated using (
    created_by = auth.uid() or exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversations.id
        and cm.user_id = auth.uid()
    )
  );
create policy "signed users can create conversations"
  on public.conversations for insert to authenticated with check (created_by = auth.uid());

create policy "users can see their own memberships"
  on public.conversation_members for select to authenticated using (user_id = auth.uid());
create policy "users can join memberships created for them"
  on public.conversation_members for insert to authenticated with check (
    user_id = auth.uid() or exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.created_by = auth.uid()
    )
  );

create policy "members can read messages"
  on public.messages for select to authenticated using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id
        and cm.user_id = auth.uid()
    )
  );
create policy "members send as themselves"
  on public.messages for insert to authenticated with check (
    sender_id = auth.uid() and exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id
        and cm.user_id = auth.uid()
    )
  );
create policy "senders edit own messages"
  on public.messages for update to authenticated using (sender_id = auth.uid())
  with check (sender_id = auth.uid());
create policy "senders delete own messages"
  on public.messages for delete to authenticated using (sender_id = auth.uid());

create policy "users read own notifications"
  on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "users update own notifications"
  on public.notifications for update to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, username, display_name)
  values (
    new.id,
    new.email,
    'user_' || substr(replace(new.id::text, '-', ''), 1, 10),
    'Новый пользователь'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.posts to authenticated;
grant select, insert, update, delete on public.post_likes to authenticated;
grant select, insert, update, delete on public.comments to authenticated;
grant select, insert, update, delete on public.follows to authenticated;
grant select, insert, update, delete on public.conversations to authenticated;
grant select, insert, update, delete on public.conversation_members to authenticated;
grant select, insert, update, delete on public.messages to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;
-- =========================================================
-- OneSpase v0.5 migration
-- Run AFTER the v0.4 base schema in Supabase SQL Editor.
-- Adds: real direct chats RPC, read receipts, verification badges,
-- owner/admin controls, audit log and safe profile search.
-- Safe to run more than once.
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- 1. Message read state
-- ---------------------------------------------------------
alter table public.messages
  add column if not exists read_at timestamptz;

-- ---------------------------------------------------------
-- 2. Verification badges
-- ---------------------------------------------------------
create table if not exists public.account_badges (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  badge text not null default 'none'
    check (badge in ('none', 'blue', 'red', 'purple')),
  reason text,
  issued_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.account_badges enable row level security;

drop policy if exists "badges readable by signed users"
  on public.account_badges;
create policy "badges readable by signed users"
  on public.account_badges
  for select
  to authenticated
  using (true);

-- No INSERT/UPDATE/DELETE policy for users on purpose.
-- Badge changes are only possible through the protected RPC below.

-- ---------------------------------------------------------
-- 3. Admin/owner registry
-- ---------------------------------------------------------
create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null default 'owner'
    check (role in ('owner', 'admin', 'moderator')),
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;

-- Intentionally no client policies on app_admins.
-- The client only gets the boolean result from is_owner().

-- ---------------------------------------------------------
-- 4. Moderation audit
-- ---------------------------------------------------------
create table if not exists public.moderation_audit (
  id bigint generated by default as identity primary key,
  actor_id uuid not null references public.profiles(id) on delete cascade,
  target_user_id uuid not null references public.profiles(id) on delete cascade,
  action text not null,
  badge text,
  reason text,
  created_at timestamptz not null default now()
);

alter table public.moderation_audit enable row level security;

-- ---------------------------------------------------------
-- 5. Owner check
-- ---------------------------------------------------------
create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  );
$$;

revoke all on function public.is_owner() from public;
grant execute on function public.is_owner() to authenticated;

-- ---------------------------------------------------------
-- 6. Safe profile lookup with badge
-- ---------------------------------------------------------
create or replace function public.get_profile_with_badge(target_user uuid)
returns table (
  id uuid,
  display_name text,
  username text,
  status text,
  bio text,
  avatar_url text,
  online boolean,
  verification text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  return query
  select
    p.id,
    p.display_name,
    p.username,
    p.status,
    p.bio,
    p.avatar_url,
    p.online,
    coalesce(b.badge, 'none') as verification
  from public.profiles p
  left join public.account_badges b on b.user_id = p.id
  where p.id = target_user
  limit 1;
end;
$$;

revoke all on function public.get_profile_with_badge(uuid) from public;
grant execute on function public.get_profile_with_badge(uuid) to authenticated;

drop function if exists public.search_people(text);
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
  verification text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text := trim(coalesce(search_text, ''));
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  return query
  select
    p.id,
    p.display_name,
    p.username,
    p.status,
    p.bio,
    p.avatar_url,
    p.online,
    coalesce(b.badge, 'none') as verification
  from public.profiles p
  left join public.account_badges b on b.user_id = p.id
  where (include_self or p.id <> auth.uid())
    and (
      q = ''
      or p.username ilike '%' || q || '%'
      or p.display_name ilike '%' || q || '%'
    )
  order by p.online desc, p.display_name asc
  limit 40;
end;
$$;

revoke all on function public.search_people(text, boolean) from public;
grant execute on function public.search_people(text, boolean) to authenticated;

-- ---------------------------------------------------------
-- 7. Secure badge assignment
-- ---------------------------------------------------------
create or replace function public.set_verification_badge(
  target_user uuid,
  new_badge text,
  badge_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_owner() then
    raise exception 'Owner access required';
  end if;

  if new_badge not in ('none', 'blue', 'red', 'purple') then
    raise exception 'Unknown badge type';
  end if;

  if not exists (select 1 from public.profiles p where p.id = target_user) then
    raise exception 'User not found';
  end if;

  insert into public.account_badges (
    user_id,
    badge,
    reason,
    issued_by,
    updated_at
  )
  values (
    target_user,
    new_badge,
    nullif(trim(coalesce(badge_reason, '')), ''),
    auth.uid(),
    now()
  )
  on conflict (user_id) do update set
    badge = excluded.badge,
    reason = excluded.reason,
    issued_by = excluded.issued_by,
    updated_at = now();

  insert into public.moderation_audit (
    actor_id,
    target_user_id,
    action,
    badge,
    reason
  )
  values (
    auth.uid(),
    target_user,
    'verification_changed',
    new_badge,
    nullif(trim(coalesce(badge_reason, '')), '')
  );
end;
$$;

revoke all on function public.set_verification_badge(uuid, text, text) from public;
grant execute on function public.set_verification_badge(uuid, text, text)
  to authenticated;

create or replace function public.list_badge_audit()
returns table (
  id bigint,
  target_username text,
  badge text,
  reason text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_owner() then
    raise exception 'Owner access required';
  end if;

  return query
  select
    a.id,
    p.username as target_username,
    a.badge,
    a.reason,
    a.created_at
  from public.moderation_audit a
  join public.profiles p on p.id = a.target_user_id
  order by a.created_at desc
  limit 100;
end;
$$;

revoke all on function public.list_badge_audit() from public;
grant execute on function public.list_badge_audit() to authenticated;

-- ---------------------------------------------------------
-- 8. Direct conversation creation / reuse
-- ---------------------------------------------------------
create or replace function public.start_direct_conversation(target_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  found_id uuid;
  new_id uuid;
begin
  if me is null then
    raise exception 'Authentication required';
  end if;

  if target_user = me then
    raise exception 'Cannot start a direct chat with yourself';
  end if;

  if not exists (select 1 from public.profiles p where p.id = target_user) then
    raise exception 'User not found';
  end if;

  select c.id
  into found_id
  from public.conversations c
  where c.is_group = false
    and exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = c.id and cm.user_id = me
    )
    and exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = c.id and cm.user_id = target_user
    )
    and (
      select count(*)
      from public.conversation_members cm
      where cm.conversation_id = c.id
    ) = 2
  limit 1;

  if found_id is not null then
    return found_id;
  end if;

  insert into public.conversations (is_group, created_by)
  values (false, me)
  returning id into new_id;

  insert into public.conversation_members (conversation_id, user_id)
  values
    (new_id, me),
    (new_id, target_user)
  on conflict do nothing;

  return new_id;
end;
$$;

revoke all on function public.start_direct_conversation(uuid) from public;
grant execute on function public.start_direct_conversation(uuid) to authenticated;

-- ---------------------------------------------------------
-- 9. Conversation list for messenger UI
-- ---------------------------------------------------------
create or replace function public.list_my_conversations()
returns table (
  conversation_id uuid,
  peer_id uuid,
  peer_name text,
  peer_username text,
  peer_status text,
  peer_online boolean,
  verification text,
  last_message text,
  last_message_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'Authentication required';
  end if;

  return query
  select
    c.id as conversation_id,
    p.id as peer_id,
    p.display_name as peer_name,
    p.username as peer_username,
    p.status as peer_status,
    p.online as peer_online,
    coalesce(b.badge, 'none') as verification,
    coalesce(lm.body, '') as last_message,
    lm.created_at as last_message_at
  from public.conversation_members mine
  join public.conversations c
    on c.id = mine.conversation_id
  join public.conversation_members peer_member
    on peer_member.conversation_id = c.id
   and peer_member.user_id <> me
  join public.profiles p
    on p.id = peer_member.user_id
  left join public.account_badges b
    on b.user_id = p.id
  left join lateral (
    select m.body, m.created_at
    from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) lm on true
  where mine.user_id = me
    and c.is_group = false
  order by lm.created_at desc nulls last, c.created_at desc;
end;
$$;

revoke all on function public.list_my_conversations() from public;
grant execute on function public.list_my_conversations() to authenticated;

-- ---------------------------------------------------------
-- 10. Read receipts
-- ---------------------------------------------------------
create or replace function public.mark_conversation_read(target_conversation uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = target_conversation
      and cm.user_id = me
  ) then
    raise exception 'Not a conversation member';
  end if;

  update public.messages m
  set read_at = now()
  where m.conversation_id = target_conversation
    and m.sender_id <> me
    and m.read_at is null;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ---------------------------------------------------------
-- 11. Grants for Data API
-- ---------------------------------------------------------
grant usage on schema public to authenticated;

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.posts to authenticated;
grant select, insert, update, delete on public.post_likes to authenticated;
grant select, insert, update, delete on public.comments to authenticated;
grant select, insert, update, delete on public.follows to authenticated;
grant select, insert, update, delete on public.conversations to authenticated;
grant select, insert, update, delete on public.conversation_members to authenticated;
grant select, insert, update, delete on public.messages to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;
grant select on public.account_badges to authenticated;

-- Do NOT grant direct access to app_admins or moderation_audit.
revoke all on public.app_admins from anon, authenticated;
revoke all on public.moderation_audit from anon, authenticated;

-- ---------------------------------------------------------
-- 12. Realtime for live messages
-- ---------------------------------------------------------
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- =========================================================
-- IMPORTANT OWNER BOOTSTRAP
-- After you create your own OneSpase account, copy its UUID from
-- Settings -> Account ID or Supabase Authentication -> Users.
-- Then run ONCE (replace UUID):
--
-- insert into public.app_admins (user_id, role)
-- values ('YOUR-UUID-HERE'::uuid, 'owner')
-- on conflict (user_id) do update set role = 'owner';
-- =========================================================
