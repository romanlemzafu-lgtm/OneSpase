# Установка OneSpase v0.6

1. В Supabase SQL Editor сначала должна быть применена v0.5 migration.
2. Запусти целиком `supabase/v0_6_migration.sql`.
3. Authentication → Providers → Email: для регистрации без писем выключи `Confirm email`.
4. Для гостевого режима включи Anonymous Sign-Ins (необязательно, если гости не нужны).
5. В GitHub Secrets должны быть `SUPABASE_URL` и `SUPABASE_ANON_KEY`.
6. Загрузи файлы v0.6 в репозиторий, включая скрытую `.github`.
7. Actions → Build OneSpase APK.

## Owner
После входа владельца его UUID должен быть в `public.app_admins` с role=`owner` (как в v0.5).
Зарезервированные имена может использовать Owner. Чтобы привязать защищённый username к конкретному пользователю, вызови из Owner-инструмента/RPC `reserve_username`.

## Важно
v0.6 подарки бесплатные. Здесь нет оплаты, NFT, рынка или торговли за реальные деньги.
