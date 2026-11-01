# Upgrade your existing OneSpase database to v0.5

## 1. Supabase SQL

Open Supabase -> SQL Editor -> New query.
Copy all of:

`supabase/v0_5_migration.sql`

Paste it and press Run.
Expected result: Success / No rows returned.

## 2. Enable guest accounts

Supabase -> Authentication -> Sign In / Providers (wording can vary) -> Anonymous Sign-Ins -> Enable.

Guest accounts are real authenticated Supabase users. If the user signs out, clears app data, or deletes the app, that anonymous identity cannot be recovered until it is linked to a permanent provider.

## 3. GitHub Secrets

Repository -> Settings -> Secrets and variables -> Actions:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Use the project URL and publishable/anon key. Never put a service-role/secret key in the mobile app.

## 4. Become the OneSpase owner

Install the APK, create your OneSpase account, then open Settings and copy `ID аккаунта`.

Back in Supabase SQL Editor, run:

```sql
insert into public.app_admins (user_id, role)
values ('PASTE-YOUR-ACCOUNT-UUID-HERE'::uuid, 'owner')
on conflict (user_id) do update set role = 'owner';
```

Restart/relogin. `Owner Panel` appears in Settings.

## 5. Google (optional for first test)

Guest sign-in is enough to test messenger on two phones immediately.
Google requires enabling the Google Auth provider in Supabase and configuring Google OAuth credentials. The app code and Android deep-link are already included.
