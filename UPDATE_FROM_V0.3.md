# Как обновить репозиторий OneSpase с v0.3 на v0.4

Самый простой вариант с ПК:

1. Распакуй `OneSpase-v0.4.0-source.zip`.
2. В GitHub открой репозиторий OneSpase.
3. Замени содержимое `lib/` файлами из нового ZIP.
4. Замени `pubspec.yaml`.
5. Добавь папку `supabase/`.
6. Замени `.github/workflows/build-apk.yml` и `release-apk.yml`.
7. Оставь `assets/` из ZIP.
8. Commit changes.
9. Открой Actions и следи за `Build OneSpase APK`.

Если GitHub через браузер снова не загрузит `.github`, открой каждый workflow отдельно через:

Add file -> Create new file

и используй пути:

- `.github/workflows/build-apk.yml`
- `.github/workflows/release-apk.yml`
