# Загрузка OneSpase v0.5 в GitHub

С ПК удобнее, но через браузер тоже можно:

1. Распакуй ZIP.
2. GitHub -> репозиторий OneSpase -> Add file -> Upload files.
3. Загрузи содержимое папки, а не сам ZIP.
4. Убедись, что `.github/workflows/build-apk.yml` существует.
5. Commit changes в `main`.
6. Вкладка Actions -> Build OneSpase APK.
7. После успешной сборки скачай artifact `OneSpase-v0.5.0-APK`.

До загрузки желательно применить `supabase/v0_5_migration.sql` в Supabase.
