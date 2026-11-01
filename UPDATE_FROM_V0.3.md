# Обновление OneSpase до v0.5

1. Распакуй `OneSpase-v0.5.0-source.zip`.
2. В репозитории OneSpase замени текущие файлы содержимым ZIP.
3. Не забудь скрытую папку `.github`.
4. В Supabase SQL Editor запусти `supabase/v0_5_migration.sql`.
5. В Supabase включи Anonymous Sign-Ins.
6. Проверь GitHub Secrets: `SUPABASE_URL` и `SUPABASE_ANON_KEY`.
7. Commit changes в `main`.
8. Открой Actions -> `Build OneSpase APK`.
9. После зелёной галочки скачай artifact `OneSpase-v0.5.0-APK`.

Google-вход можно настроить позже. Для первого онлайн-теста двух телефонов достаточно гостевого входа.
