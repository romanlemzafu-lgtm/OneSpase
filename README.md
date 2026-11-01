# OneSpase v0.4.0 — Online Foundation

OneSpase — уютная смесь соцсети и мессенджера с собственной визуальной системой.

## Что нового в v0.4

- новый тёмный интерфейс с фирменным фиолетовым акцентом;
- 5 основных разделов: Лента, Чаты, Люди, События, Профиль;
- новый экран диалога;
- новый профиль и отдельный экран настроек;
- регистрация/вход по email OTP-коду;
- создание профиля после подтверждения почты;
- поиск пользователей по имени и `@username`;
- демо-режим, если Supabase ещё не подключён;
- SQL-схема Supabase для профилей, постов, лайков, комментариев, подписок, диалогов, сообщений и уведомлений;
- GitHub Actions для сборки APK с Supabase Secrets.

## Важно про эту APK

Если `SUPABASE_URL` и `SUPABASE_ANON_KEY` не заданы, приложение запускается в демо-режиме. Интерфейс, локальная лента, комментарии и локальные чаты работают, но email-коды и серверный поиск требуют Supabase.

## Подключение Supabase

### 1. Создай проект Supabase

После создания открой SQL Editor и выполни:

`supabase/schema.sql`

### 2. Включи код вместо magic link

В Supabase открой Authentication -> Email Templates -> Magic Link / OTP.
В шаблоне должен использоваться токен:

```html
<h2>Код OneSpase</h2>
<p>Введи этот код в приложении:</p>
<h1>{{ .Token }}</h1>
```

### 3. Добавь GitHub Secrets

В репозитории OneSpase:

Settings -> Secrets and variables -> Actions -> New repository secret

Создай два секрета:

- `SUPABASE_URL` — Project URL из Supabase
- `SUPABASE_ANON_KEY` — anon/publishable key из Supabase

Никогда не добавляй `service_role` key в мобильное приложение или GitHub workflow для APK.

### 4. Собери APK

После push в `main` workflow `Build OneSpase APK` запустится автоматически.

Actions -> Build OneSpase APK -> успешный запуск -> Artifacts -> `OneSpase-v0.4.0-APK`.

## Локальный запуск

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL="YOUR_URL" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_ANON_KEY"
```

Без этих параметров можно использовать кнопку `Открыть демо OneSpase`.

## Следующий этап

- настоящий список диалогов из Supabase;
- Realtime-сообщения между двумя телефонами;
- заявки в друзья / подписки;
- серверная лента;
- загрузка аватарок и фото;
- push-уведомления;
- затем голосовые сообщения и WebRTC-звонки.
