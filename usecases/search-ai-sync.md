# Дополнительные use cases: поиск, AI, sync и desktop-оболочка

Существующие UC-001..UC-006 для vault и UC-007.. для заметок остаются закрепленными в текущих файлах. Этот документ продолжает сценарии без изменения существующих контрактов.

## UC-009. Создать папку

Пользователь создает папку внутри активного vault.

1. UI отправляет `path` или `parent_folder + name`.
2. Backend нормализует путь и проверяет, что он остается внутри vault.
3. Backend проверяет конфликт имени.
4. Backend создает папку на диске.
5. Backend обновляет metadata/index.
6. Backend возвращает FolderDTO.

## UC-010. Переименовать или переместить папку

Пользователь меняет имя папки или переносит ее внутри vault.

1. UI отправляет `source_path` и `target_path`.
2. Backend проверяет, что оба пути внутри vault.
3. Backend проверяет конфликты.
4. Backend перемещает папку на диске.
5. Backend обновляет paths у вложенных notes.
6. Backend ставит jobs `index_note` для затронутых notes и `update_links` при необходимости.

## UC-011. Добавить вложение

Пользователь добавляет файл-вложение к заметке.

1. UI передает ссылку на исходный файл и целевую заметку.
2. Backend копирует файл в `attachments_folder`.
3. Backend генерирует безопасное имя при конфликте.
4. Backend создает запись attachment в index.db.
5. Backend возвращает markdown link для вставки в заметку.

## UC-012. Обработать внешнее изменение файла

Пользователь или другая программа изменяет `.md` файл в vault.

1. File watcher получает событие create/update/delete/rename.
2. Backend debounce-ит события.
3. Backend читает актуальное состояние файла.
4. Backend обновляет metadata.
5. Backend ставит jobs для FTS, links, chunks и embeddings invalidation.
6. UI получает событие об изменении, если заметка открыта.

## UC-013. Выполнить полное повторное сканирование vault

Пользователь запускает ручной rebuild индекса или приложение делает это после сбоя.

1. Backend сканирует vault с учетом `excluded_paths` и `.gitignore`.
2. Backend сверяет найденные файлы с index.db.
3. Missing files помечаются deleted/stale.
4. New/changed files получают jobs `index_note`.
5. Links/chunks/embeddings пересчитываются только для измененных файлов, если возможно.
6. UI показывает progress и ошибки.

## UC-014. Выполнить FTS-поиск

Пользователь ищет текст по заметкам.

1. UI отправляет query, filters, pagination.
2. Backend выполняет FTS по index.db.
3. Backend формирует snippets.
4. Backend возвращает SearchResultDTO без полного content.

## UC-015. Выполнить семантический поиск

Пользователь ищет по смыслу.

1. UI отправляет query и filters.
2. Backend проверяет, что embeddings provider настроен.
3. Backend строит embedding запроса.
4. Backend ищет ближайшие chunks в vector index.
5. Backend группирует chunks по notes.
6. Backend возвращает результаты со score и исходными chunks.

## UC-016. Выполнить гибридный поиск

Пользователь использует единый поиск.

1. UI отправляет query, mode=`hybrid`, filters.
2. Backend параллельно получает FTS score и vector score, если embeddings доступны.
3. Backend применяет ranking policy: title/path boosts, recency, tags, exact matches.
4. Backend возвращает объяснимые score components.
5. Если semantic layer недоступен, backend возвращает FTS results и warning.

## UC-017. Показать связанные заметки

Пользователь открывает related notes для текущей заметки.

1. UI отправляет note_id.
2. Backend получает chunks/embedding заметки.
3. Backend ищет похожие заметки.
4. Backend добавляет сигналы backlinks, tags, shared links.
5. Backend возвращает список related notes с причиной связи.

## UC-018. Настроить AI-режим

Пользователь выбирает `local`, `byok` или `managed`.

1. UI отправляет выбранный mode и параметры provider/model.
2. Backend валидирует параметры.
3. Секреты сохраняются в OS credential storage.
4. Backend выполняет connection test.
5. Vault settings обновляются только после успешной проверки или явного подтверждения пользователя.

## UC-019. Сгенерировать embeddings для vault

Пользователь включает семантический поиск или меняет embeddings model.

1. Backend создает jobs `chunk_note` для заметок без актуальных chunks.
2. Backend создает jobs `embed_chunk`.
3. Jobs выполняются с rate limit и pause/resume.
4. Ошибки provider сохраняются в jobs.
5. UI показывает coverage: сколько notes/chunks проиндексировано.

## UC-020. Задать вопрос RAG-чату по vault

Пользователь спрашивает чат о своих заметках.

1. UI отправляет question, vault_id, optional scope.
2. Backend выполняет retrieval: hybrid search по relevant chunks.
3. Backend формирует prompt с ограничением context.
4. Backend вызывает AI provider согласно текущему AI-режиму.
5. Backend возвращает answer, citations, model metadata и usage.
6. UI показывает источники и позволяет открыть цитируемые заметки.

## UC-021. Задать вопрос по текущей заметке

Пользователь задает вопрос с ограничением на открытую заметку.

1. UI отправляет question и current note_id.
2. Backend ограничивает retrieval chunks текущей заметкой и связанными notes, если пользователь включил расширенный контекст.
3. Backend вызывает AI provider.
4. Backend возвращает answer with sources.

## UC-022. Сгенерировать summary заметки

Пользователь просит краткое содержание заметки.

1. UI отправляет note_id.
2. Backend читает актуальный content с диска.
3. Backend вызывает AI provider.
4. Backend возвращает summary без изменения файла.
5. Пользователь может вставить summary в заметку через отдельное действие.

## UC-023. Сгенерировать tags

Пользователь просит предложить tags для заметки.

1. Backend читает content и existing tags.
2. Backend вызывает AI provider.
3. Backend возвращает suggested tags.
4. UI показывает diff/frontmatter preview.
5. Применение tags выполняется как patch AI-suggestion.

## UC-024. Предложить backlinks

Пользователь просит найти потенциальные связи.

1. Backend использует semantic similarity, title matches и existing graph.
2. Backend возвращает candidate notes с объяснением.
3. UI позволяет вставить wikilinks вручную или через suggestion patch.

## UC-025. Применить AI-suggestion

AI предлагает изменение заметки через diff/patch.

1. UI показывает diff.
2. Пользователь выбирает apply, partial apply или reject.
3. UI отправляет suggestion_id и expected_version.
4. Backend проверяет актуальную версию заметки.
5. Backend применяет patch атомарно.
6. Backend создает note_version.
7. Backend ставит job `index_note`.

## UC-026. Переключиться в managed cloud AI

Пользователь входит в аккаунт и включает managed AI.

1. UI открывает auth flow.
2. Backend получает access token через безопасный callback.
3. Backend сохраняет token в OS credential storage.
4. Backend получает available models и limits.
5. Пользователь выбирает managed AI-режим.
6. Backend обновляет settings.

## UC-027. Включить sync для vault

Пользователь включает sync в настройках vault.

1. Backend проверяет, что пользователь авторизован.
2. Backend создает remote vault или связывает с существующим.
3. Backend делает initial sync plan.
4. UI показывает объем данных и предупреждения.
5. После подтверждения backend запускает sync jobs.

## UC-028. Разрешить конфликт sync

Одна заметка изменена на двух устройствах.

1. Backend обнаруживает divergent versions.
2. Backend сохраняет обе версии без потери данных.
3. UI показывает conflict state.
4. Пользователь выбирает local, remote, keep both или manual merge.
5. Backend применяет выбор и ставит `index_note`.

## UC-029. Экспортировать diagnostics bundle

Пользователь сообщает о проблеме.

1. UI вызывает export diagnostics.
2. Backend собирает app/core logs, system metadata, indexing errors, provider status.
3. Backend удаляет secrets и содержимое заметок.
4. Backend создает archive.
5. UI показывает путь к archive.

## UC-030. Запустить desktop-приложение и local core

Пользователь открывает приложение.

1. Electron main запускает Go core binary.
2. Core выбирает свободный loopback port или использует configured port.
3. Core создает local session token.
4. Preload exposes limited API для renderer.
5. Renderer работает только через allowlisted IPC/local API.
6. При закрытии приложения Electron корректно останавливает core.
