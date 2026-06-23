# Требования Opal

## 1. Назначение

Opal - desktop-приложение для markdown-заметок, близкое по базовому UX к Obsidian, но с встроенным AI-слоем: semantic search, hybrid search, RAG-чатом по заметкам, AI-summary, AI-tags, AI-backlinks и AI-suggestions через diff/patch.

## 2. Целевые платформы

1. MVP desktop: Windows, macOS, Linux.
2. Runtime: Electron + React + TypeScript + Tailwind для UI.
3. Local core: Go binary, поставляется вместе с Electron.
4. Возможное будущее расширение: мобильное приложение, web account portal.

## 3. Ключевые продуктовые принципы

1. Local-first: пользователь может пользоваться заметками без аккаунта и интернета.
2. Markdown-first: `.md` файлы являются источником истины и должны оставаться пригодными для чтения вне Opal.
3. Прозрачный AI: ответы должны показывать источники, а любые изменения заметок через AI применяются только после подтверждения пользователя.
4. Переносимость vault: служебные данные Opal не должны загрязнять пользовательские markdown-файлы, кроме явно согласованных настроек.
5. Privacy by default: локальные заметки не отправляются в облако без включенного sync, managed AI или явного действия пользователя.
6. Graceful degradation: если AI, embeddings или cloud недоступны, базовые заметки, FTS-поиск и graph должны продолжать работать.

## 4. Роли пользователей

1. Offline user: использует только локальные заметки, FTS и graph.
2. Local AI user: устанавливает Ollama и использует локальные embeddings/LLM.
3. BYOK user: указывает API key внешнего AI-провайдера.
4. Cloud user: входит в аккаунт для managed AI, sync, backup, billing и device management.

## 5. Состав MVP

### MVP-1: локальные заметки

1. Desktop app для Windows/macOS/Linux.
2. Запуск bundled Go core из Electron.
3. Open/create/import vault.
4. CRUD `.md` заметок.
5. Папки внутри vault.
6. Markdown editor + preview.
7. SQLite metadata.
8. FTS search.
9. Basic graph из wikilinks.
10. Backlinks.
11. Статус индексации.
12. File watcher для внешних изменений.

### MVP-2: семантический слой

1. Chunking markdown-документов.
2. Embeddings generation.
3. Semantic/vector search.
4. Гибридный поиск: FTS + vector + metadata ranking.
5. Связанные заметки.
6. Локальный AI-режим через Ollama.
7. BYOK AI-режим.

### MVP-3: AI-сценарии

1. RAG-чат по выбранному vault или subset заметок.
2. Ответы с источниками.
3. AI summary для заметки и группы заметок.
4. AI tags.
5. AI backlinks.
6. AI-suggestions через diff/patch.
7. История AI jobs и статусы ошибок.

### MVP-4: облачный слой

1. Аккаунт.
2. Sync.
3. Managed cloud AI.
4. Billing/limits.
5. Multi-device.
6. Backup/restore.
7. Device management.

## 6. Функциональные требования

### 6.1 Vault

1. Пользователь может создать новый vault в выбранной папке.
2. Пользователь может подключить существующий vault с `.md` файлами.
3. Пользователь может открыть один активный vault.
4. Пользователь может менять настройки vault: исключенные пути, AI-режим, включение sync, папку заметок по умолчанию, папку вложений.
5. Удаление vault из приложения не должно физически удалять папку vault.
6. Для каждого vault создается отдельное локальное служебное хранилище с `index.db`.
7. Vault должен поддерживать `.gitignore` как дополнительный источник исключений, если `UseGitIgnore = true`.

### 6.2 Заметки

1. Пользователь может создавать, читать, обновлять, переименовывать, перемещать, удалять и восстанавливать `.md` заметки.
2. Обновление заметки должно проверять `expected_version`.
3. Запись `.md` должна быть атомарной.
4. Удаление заметки по умолчанию мягкое: перенос в `.trash`.
5. Список заметок не должен возвращать полный `content`.
6. Открытие заметки читает актуальный content с диска.
7. Внешние изменения файлов должны попадать в индекс через watcher/rescan.

### 6.3 Папки и вложения

1. Пользователь может создавать, переименовывать, перемещать и удалять папки внутри vault.
2. Папка не может выходить за границы vault через `..`, symlink escape или absolute path injection.
3. Attachments хранятся в `VaultSettings.AttachmentsFolder`.
4. Поддерживаемые вложения MVP: изображения, PDF, любые бинарные файлы как ссылки.
5. Удаление заметки не должно автоматически удалять вложения, если они используются другими заметками.

### 6.4 Markdown-редактор

1. Режимы: edit, preview, split.
2. Поддержка markdown, code blocks, tables, task lists, wikilinks, frontmatter.
3. Автосохранение должно использовать тот же контракт обновления заметки с версией.
4. При конфликте версии UI показывает выбор: reload, overwrite, create copy.
5. Preview не должен выполнять небезопасный HTML/JS из заметок.

### 6.5 Ссылки, backlinks и graph

1. Индексатор извлекает wikilinks `[[Note]]`, markdown links и headings.
2. Backlinks строятся из индекса links.
3. Graph view показывает notes как nodes, links как edges.
4. Broken links должны отображаться отдельно.
5. Переименование заметки должно ставить job `update_links`; автоматическое переписывание ссылок требует отдельного подтверждения пользователя.

### 6.6 Индексация и jobs

1. Индексация выполняется асинхронными jobs.
2. Jobs должны быть идемпотентными.
3. Для каждого job хранится status, progress, timestamps, error.
4. Индексатор должен поддерживать полный rescan vault.
5. Изменение файла должно инвалидировать FTS/chunks/embeddings/links этой заметки.
6. UI должен показывать общий indexing status и список ошибок.

### 6.7 Поиск

1. FTS search работает без AI и без embeddings.
2. Semantic search доступен только при настроенном embeddings provider.
3. Гибридный поиск объединяет FTS, vector score, recency, title/path boosts и tag boosts.
4. Результат поиска содержит фрагменты совпадений и metadata источника.
5. Поиск должен уметь ограничиваться folder, tags, date range и note ids.
6. Empty query в обычном поиске не должен запускать дорогой semantic поиск.

### 6.8 AI-режимы

1. `local`: пользователь устанавливает Ollama, core вызывает локальный endpoint.
2. `byok`: пользователь указывает provider, model и API key; core вызывает выбранного provider напрямую.
3. `managed`: пользователь входит в аккаунт, core вызывает cloud API продукта.
4. Переключение режима не должно ломать заметки и базовые индексы.
5. API keys должны храниться в OS keychain/credential storage, а не в plain SQLite.
6. Для каждого режима нужна проверка подключения и доступных моделей.

### 6.9 RAG-чат

1. Chat работает по выбранному vault.
2. Пользователь может ограничить context: selected notes, folder, tags, current note.
3. Ответ должен возвращать цитаты источников: note id/path, heading, snippet/chunk reference.
4. Если источников недостаточно, ответ должен явно сообщать об этом.
5. Chat history хранится локально; sync истории является отдельной настройкой.
6. Пользователь может удалить chat history.

### 6.10 AI-suggestions

1. AI не изменяет `.md` файлы напрямую.
2. AI возвращает suggestion с patch/diff.
3. UI показывает diff и позволяет принять полностью, принять частично или отклонить.
4. Применение suggestion использует `expected_version`.
5. Applied suggestion создает `note_version`.
6. Suggestions должны иметь audit trail: тип prompt, model, timestamps, status, затронутые заметки.

### 6.11 Sync, backup и cloud

1. Sync опционален и требует аккаунта.
2. Пользователь может включить sync отдельно для каждого vault.
3. Конфликты sync не должны молча затирать локальные изменения.
4. Базовый конфликт-резолвинг: latest safe copy + conflict copy + UI merge later.
5. Backup является отдельной возможностью от live sync.
6. Пользователь может удалить устройство из аккаунта.
7. Managed AI лимиты должны быть видны в UI до отправки дорогих запросов.

### 6.12 Настройки

1. Настройки приложения: тема, язык, telemetry, update channel, AI-режим по умолчанию.
2. Vault settings: folders, excluded paths, indexing, AI enabled, sync enabled.
3. AI-настройки: provider, models, embeddings model, context limits, API key status.
4. Privacy settings: cloud features, telemetry, chat history sync, crash reports.

## 7. Нефункциональные требования

### 7.1 Безопасность

1. Electron renderer не должен иметь прямой Node.js access.
2. IPC должен быть ограничен allowlist API.
3. Local core должен слушать только loopback interface.
4. Local API должен иметь session token или аналогичную защиту от произвольных локальных клиентов.
5. Markdown preview должен санитайзить HTML.
6. API keys хранятся в OS keychain/credential storage.
7. Managed cloud должен поддерживать revoke tokens и device logout.

### 7.2 Приватность

1. По умолчанию заметки не покидают устройство.
2. При включении BYOK пользователь должен видеть, что selected content будет отправляться внешнему provider.
3. При включении managed AI пользователь должен видеть, какие данные уходят в cloud.
4. Telemetry должна быть opt-in или явно выключаемой.

### 7.3 Надежность

1. Потеря питания во время сохранения заметки не должна оставлять файл в частично записанном состоянии.
2. SQLite migrations должны быть версионированы.
3. Index rebuild должен восстанавливать служебные данные из markdown-файлов.
4. Повреждение `index.db` не должно уничтожать vault.
5. Watcher должен иметь fallback на manual rescan.

### 7.4 Целевые показатели производительности

1. Открытие приложения до shell UI: до 3 секунд на типовой машине.
2. Открытие заметки из списка: до 200 мс без тяжелых AI операций.
3. FTS search по 10k заметок: до 500 мс для обычного запроса.
4. UI не должен блокироваться индексацией.
5. Embeddings generation должна быть throttled и pause/resume capable.
6. Large vault target для проектирования: 50k notes, 5 GB markdown + attachments.

### 7.5 Наблюдаемость

1. Локальные logs для Electron и Go core.
2. User-visible diagnostics для indexing, AI provider, sync.
3. Export diagnostics bundle без секретов.
4. Crash reports только при разрешении пользователя.

### 7.6 Доступность и i18n

1. Keyboard-first navigation для основных сценариев.
2. Поддержка high contrast themes.
3. UI strings должны быть готовы к i18n.
4. Минимум два языка в перспективе: English и Russian.

## 8. Данные и SQLite

Минимальные таблицы для планирования:

1. `vaults`
2. `notes`
3. `note_versions`
4. `folders`
5. `attachments`
6. `links`
7. `chunks`
8. `embeddings`
9. `fts_notes`
10. `jobs`
11. `ai_settings`
12. `ai_chats`
13. `ai_messages`
14. `ai_suggestions`
15. `sync_state`
16. `devices`

SQLite не должен считаться источником истины для markdown content. Любые производные данные должны пересоздаваться из файлов.

## 9. Ошибки и UX-состояния

1. Vault path missing.
2. Vault permission denied.
3. Note version conflict.
4. Note path conflict.
5. Ошибка индексации.
6. Embeddings provider unavailable.
7. AI provider quota exceeded.
8. Managed cloud unauthorized.
9. Конфликт sync.
10. Offline-режим.

Каждая ошибка должна иметь machine-readable code и user-facing message.

## 10. Явно не в MVP

1. Real-time collaborative editing.
2. Public note publishing.
3. Plugin marketplace.
4. End-to-end encrypted sync, если не будет отдельно спроектирован.
5. Mobile app.
6. Browser web editor.

## 11. Открытые вопросы

1. Нужно ли хранить `.opal/` внутри vault или все служебное состояние только в app data?
2. Нужен ли импорт настроек из Obsidian: tags, canvas, plugins, attachments paths?
3. Нужно ли поддерживать Mermaid, LaTeX, callouts и Obsidian-specific markdown в MVP-1?
4. Какой vector index использовать в SQLite: sqlite-vss, sqlite-vec, custom table или отдельный локальный индекс?
5. Какой минимальный cloud backend нужен для managed AI до полноценного sync?
6. Нужно ли шифрование локального index.db?
