-- OneSpase v0.4 online foundation
-- Run this once in Supabase SQL Editor.

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

-- Profiles
create policy "profiles readable by signed users"
  on public.profiles for select to authenticated using (true);
create policy "users insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "users update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

-- Posts + comments + likes
create policy "posts readable by signed users"
  on public.posts for select to authenticated using (true);
create policy "users create own posts"
  on public.posts for insert to authenticated with check (auth.uid() = author_id);
create policy "users edit own posts"
  on public.posts for update to authenticated using (auth.uid() = author_id);
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

-- Follow graph
create policy "follows readable by signed users"
  on public.follows for select to authenticated using (true);
create policy "users follow as themselves"
  on public.follows for insert to authenticated with check (auth.uid() = follower_id);
create policy "users unfollow as themselves"
  on public.follows for delete to authenticated using (auth.uid() = follower_id);

-- Conversations
create policy "members can see conversations"
  on public.conversations for select to authenticated using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = id and cm.user_id = auth.uid()
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
  on public.messages for update to authenticated using (sender_id = auth.uid());
create policy "senders delete own messages"
  on public.messages for delete to authenticated using (sender_id = auth.uid());

create policy "users read own notifications"
  on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "users update own notifications"
  on public.notifications for update to authenticated using (user_id = auth.uid());

-- Create an empty profile row after email OTP creates a user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
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
  for each row execute procedure public.handle_new_user();

-- Realtime tables used later by chat/feed UI.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
