# OneSpase v0.5.0

OneSpase is a cozy social network + messenger prototype inspired by familiar messenger/social patterns while keeping its own branding and UI.

## v0.5 focus

This release turns the messenger layer into a real online system:

- guest online accounts;
- Google OAuth entry point;
- profiles + unique usernames;
- people search;
- direct chats;
- Realtime messages;
- editing/deleting own messages;
- read state;
- verification badges;
- protected Owner Panel.

## Before building

1. Create/configure Supabase.
2. If your v0.4 database already exists, run:
   `supabase/v0_5_migration.sql`
3. Enable Anonymous Sign-Ins in Supabase Authentication settings.
4. Add GitHub repository secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
5. Upload the project to GitHub and let Actions build the APK.

## Google login

The button is implemented, but Google sign-in only works after the Google provider is enabled in Supabase and Google OAuth credentials are configured. The APK already contains the `onespase://login-callback` deep link through GitHub Actions.

## Owner Panel

The panel is hidden until your account UUID is registered as owner in `public.app_admins`.

After you create your account, copy your Account ID from OneSpase Settings or Supabase Authentication -> Users and run:

```sql
insert into public.app_admins (user_id, role)
values ('YOUR-UUID-HERE'::uuid, 'owner')
on conflict (user_id) do update set role = 'owner';
```

Do not put an owner password or service-role key inside the APK.
