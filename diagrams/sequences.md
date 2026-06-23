# Сиквенс-диаграммы

Диаграммы описывают основные потоки Opal. Существующие use cases и контракты не меняются.

## 1. Запуск desktop-приложения и local core

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant Main as Electron main
    participant Core as Go local core
    participant Preload as Electron preload
    participant UI as React UI

    User->>Main: Запускает Opal
    Main->>Core: Стартует bundled Go binary
    Core->>Core: Выбирает loopback port
    Core->>Core: Создает local session token
    Core-->>Main: Port + health status
    Main->>Preload: Передает allowlisted API и token
    Preload->>UI: Открывает ограниченный client API
    UI->>Core: GET /health
    Core-->>UI: ok
    UI-->>User: Показывает shell приложения
```

## 2. Создание нового vault

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as React UI
    participant Core as Go core
    participant FS as File system
    participant DB as SQLite index.db
    participant Jobs as Job queue

    User->>UI: Выбирает папку и имя vault
    UI->>Core: POST /vaults
    Core->>FS: Проверяет путь и права
    alt Папки нет
        Core->>FS: Создает папку vault
    end
    Core->>DB: Создает запись vault
    Core->>FS: Создает app data storage для vault
    Core->>DB: Помечает vault активным
    Core->>Jobs: Ставит scan_vault
    Core-->>UI: 201 VaultDTO
    UI-->>User: Открывает созданный vault
```

## 3. Подключение существующего vault и первичная индексация

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as React UI
    participant Core as Go core
    participant FS as File system
    participant DB as SQLite index.db
    participant Indexer as Indexer worker

    User->>UI: Выбирает папку с .md файлами
    UI->>Core: POST /vaults/import
    Core->>FS: Проверяет существование и доступ
    Core->>DB: Регистрирует vault
    Core-->>UI: 201 VaultDTO
    Core->>Indexer: Запускает scan_vault job
    Indexer->>FS: Обходит .md файлы с учетом excluded_paths
    loop Для каждой заметки
        Indexer->>FS: Читает markdown
        Indexer->>DB: Обновляет notes, FTS, links
    end
    Indexer->>DB: Обновляет indexing status
    UI->>Core: GET /vaults/{vault_id}/index/status
    Core-->>UI: progress/status
```

## 4. Сохранение заметки с expected_version

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as Editor UI
    participant Core as Go core
    participant FS as File system
    participant DB as SQLite index.db
    participant Jobs as Job queue

    User->>UI: Редактирует markdown
    UI->>Core: PUT /vaults/{vault_id}/notes/{note_id}/content
    Core->>DB: Проверяет note_id и expected_version
    alt Версия актуальна
        Core->>FS: Атомарно перезаписывает .md файл
        Core->>DB: Обновляет content_hash и version
        Core->>DB: Создает note_version
        Core->>Jobs: Ставит index_note
        Core-->>UI: 200 NoteDTO
        UI-->>User: Показывает сохраненное состояние
    else Конфликт версий
        Core-->>UI: 409 note_version_conflict
        UI-->>User: Предлагает reload, overwrite или create copy
    end
```

## 5. Гибридный поиск

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as Search UI
    participant Core as Go core
    participant DB as SQLite FTS
    participant Embed as Embeddings provider
    participant Vector as Vector index
    participant Ranker as Ranking policy

    User->>UI: Вводит поисковый запрос
    UI->>Core: POST /vaults/{vault_id}/search mode=hybrid
    par FTS branch
        Core->>DB: Выполняет FTS query
        DB-->>Core: FTS matches
    and Semantic branch
        Core->>Embed: Строит embedding запроса
        Embed-->>Core: Query vector
        Core->>Vector: Ищет nearest chunks
        Vector-->>Core: Vector matches
    end
    Core->>Ranker: Объединяет score, recency, tags, title/path boosts
    Ranker-->>Core: Ranked SearchResultDTO
    Core-->>UI: 200 results + warnings
    UI-->>User: Показывает snippets и score components
```

## 6. RAG-чат по заметкам

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as Chat UI
    participant Core as Go core
    participant Retrieval as Retrieval service
    participant DB as SQLite index.db
    participant AI as AI provider

    User->>UI: Задает вопрос по vault
    UI->>Core: POST /vaults/{vault_id}/ai/chats/{chat_id}/messages
    Core->>Retrieval: Retrieval по question и scope
    Retrieval->>DB: Ищет relevant chunks через hybrid search
    DB-->>Retrieval: Chunks + metadata
    Retrieval-->>Core: Context + citations
    Core->>AI: Prompt с вопросом и context
    AI-->>Core: Answer
    Core->>DB: Сохраняет message, answer, citations, usage
    Core-->>UI: Answer + citations + model metadata
    UI-->>User: Показывает ответ и источники
```

## 7. AI-suggestion через diff/patch

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as Editor UI
    participant Core as Go core
    participant FS as File system
    participant DB as SQLite index.db
    participant AI as AI provider
    participant Jobs as Job queue

    User->>UI: Просит улучшить заметку
    UI->>Core: POST /vaults/{vault_id}/ai/suggestions
    Core->>FS: Читает актуальный markdown
    Core->>AI: Запрос suggestion
    AI-->>Core: Patch/diff
    Core->>DB: Сохраняет suggestion со status=ready
    Core-->>UI: Suggestion with diff
    UI-->>User: Показывает diff
    User->>UI: Подтверждает apply
    UI->>Core: POST /suggestions/{suggestion_id}/apply
    Core->>DB: Проверяет expected_version
    Core->>FS: Атомарно применяет patch
    Core->>DB: Создает note_version
    Core->>Jobs: Ставит index_note
    Core-->>UI: 200 updated notes
```

## 8. Конфликт sync

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant UI as Sync UI
    participant Core as Go core
    participant Local as Local vault
    participant Cloud as Opal cloud
    participant DB as SQLite sync_state

    Core->>Local: Видит локальное изменение заметки
    Core->>Cloud: Получает remote version
    Cloud-->>Core: Remote version отличается
    Core->>DB: Создает sync conflict
    Core-->>UI: conflict event
    UI-->>User: Показывает local и remote версии
    User->>UI: Выбирает keep_both/use_local/use_remote/manual_merge
    UI->>Core: POST /sync/conflicts/{conflict_id}/resolve
    Core->>Local: Применяет выбранную стратегию без потери данных
    Core->>DB: Обновляет sync_state
    Core->>Cloud: Отправляет resolved version при необходимости
    Core-->>UI: 200 resolved
```
