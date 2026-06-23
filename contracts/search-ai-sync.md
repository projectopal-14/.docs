# Контракты поиска, индексации, AI и sync

Предлагаемые контракты для функций после базового CRUD. Существующие контракты не меняются.

## Общие модели

### JobDTO

```go
type JobDTO struct {
    ID          string
    VaultID     string
    Type        string
    Status      string
    Progress    float64
    ErrorCode   *string
    ErrorMessage *string
    CreatedAt   time.Time
    StartedAt   *time.Time
    FinishedAt  *time.Time
}
```

### SearchResultDTO

```go
type SearchResultDTO struct {
    NoteID      string
    Path        string
    Title       string
    Snippet     string
    Score       float64
    ScoreParts  map[string]float64
    ChunkID     *string
    Highlights  []string
}
```

### CitationDTO

```go
type CitationDTO struct {
    NoteID  string
    Path    string
    Title   string
    Heading *string
    ChunkID *string
    Snippet string
}
```

## Индексация

### Получить статус индексации

GET `/vaults/{vault_id}/index/status`

Ответ: `200`.

```json
{
  "status": "idle",
  "pending_jobs": 0,
  "failed_jobs": 0,
  "notes_total": 1200,
  "notes_indexed": 1198,
  "chunks_total": 8800,
  "chunks_embedded": 8600,
  "last_scan_at": "2026-06-23T00:00:00Z"
}
```

Ошибки: `404`.

### Запустить rescan

POST `/vaults/{vault_id}/index/rescan`

Request:

```json
{
  "mode": "incremental"
}
```

`mode`: `incremental` или `full`.

Ответ: `202`, `JobDTO`.

Ошибки: `400`, `404`, `409`.

### Получить список jobs

GET `/vaults/{vault_id}/jobs?status=failed&type=index_note&limit=100`

Ответ: `200`, список `JobDTO`.

Ошибки: `404`.

### Повторить failed jobs

POST `/vaults/{vault_id}/jobs/retry`

Request:

```json
{
  "job_ids": ["job_1", "job_2"]
}
```

Ответ: `202`.

```json
{
  "queued": 2
}
```

Ошибки: `400`, `404`.

## Поиск

### Искать заметки

POST `/vaults/{vault_id}/search`

Request:

```json
{
  "query": "project roadmap",
  "mode": "hybrid",
  "filters": {
    "folders": ["work"],
    "tags": ["project"],
    "note_ids": [],
    "updated_after": null,
    "updated_before": null
  },
  "limit": 20,
  "cursor": null
}
```

`mode`: `fts`, `semantic`, `hybrid`.

Ответ: `200`.

```json
{
  "items": [],
  "next_cursor": null,
  "warnings": []
}
```

Элементы списка имеют тип `SearchResultDTO`.

Ошибки: `400`, `404`, `409`.

`409` может использоваться, когда запрошенный semantic mode недоступен, потому что embeddings не настроены.

### Связанные заметки

GET `/vaults/{vault_id}/notes/{note_id}/related?limit=20`

Ответ: `200`.

```json
{
  "items": [
    {
      "note_id": "note_1",
      "title": "Roadmap",
      "path": "work/roadmap.md",
      "score": 0.87,
      "reasons": ["semantic_similarity", "shared_tag"]
    }
  ]
}
```

Ошибки: `404`, `409`.

## AI-настройки

### Получить AI-настройки

GET `/vaults/{vault_id}/ai/settings`

Ответ: `200`.

```json
{
  "enabled": true,
  "mode": "local",
  "chat_model": "llama3.1",
  "embedding_model": "nomic-embed-text",
  "provider": "ollama",
  "api_key_configured": false
}
```

Ошибки: `404`.

### Обновить AI-настройки

PATCH `/vaults/{vault_id}/ai/settings`

Request:

```json
{
  "enabled": true,
  "mode": "byok",
  "provider": "openai",
  "chat_model": "provider-chat-model",
  "embedding_model": "provider-embedding-model",
  "api_key": "secret"
}
```

Ответ: `200`, настройки без raw secret.

Ошибки: `400`, `404`, `409`.

Секреты должны храниться в OS credential storage.

### Проверить AI provider

POST `/vaults/{vault_id}/ai/test`

Request:

```json
{
  "mode": "local",
  "provider": "ollama",
  "chat_model": "llama3.1",
  "embedding_model": "nomic-embed-text"
}
```

Ответ: `200`.

```json
{
  "ok": true,
  "available_models": ["llama3.1", "nomic-embed-text"],
  "latency_ms": 120
}
```

Ошибки: `400`, `404`, `503`.

## Embeddings

### Запустить индексацию embeddings

POST `/vaults/{vault_id}/embeddings/rebuild`

Request:

```json
{
  "scope": "stale",
  "model": "nomic-embed-text"
}
```

`scope`: `stale`, `all`, `selected_notes`.

Ответ: `202`, `JobDTO`.

Ошибки: `400`, `404`, `409`.

### Приостановить embeddings jobs

POST `/vaults/{vault_id}/embeddings/pause`

Ответ: `204`.

Ошибки: `404`.

### Возобновить embeddings jobs

POST `/vaults/{vault_id}/embeddings/resume`

Ответ: `204`.

Ошибки: `404`.

## RAG-чат

### Создать чат

POST `/vaults/{vault_id}/ai/chats`

Request:

```json
{
  "title": "Questions about project roadmap",
  "scope": {
    "mode": "vault",
    "note_ids": [],
    "folders": [],
    "tags": []
  }
}
```

Ответ: `201`.

```json
{
  "id": "chat_1",
  "title": "Questions about project roadmap",
  "scope": {}
}
```

Ошибки: `400`, `404`, `409`.

### Задать вопрос в чат

POST `/vaults/{vault_id}/ai/chats/{chat_id}/messages`

Request:

```json
{
  "question": "What are the main risks?",
  "scope_override": null
}
```

Ответ: `200`.

```json
{
  "message_id": "msg_2",
  "answer": "The main risks are ...",
  "citations": [],
  "usage": {
    "input_tokens": 1200,
    "output_tokens": 250
  },
  "model": "llama3.1"
}
```

`citations` имеют тип `CitationDTO`.

Ошибки: `400`, `404`, `409`, `429`, `503`.

### Получить сообщения чата

GET `/vaults/{vault_id}/ai/chats/{chat_id}/messages`

Ответ: `200`, список сообщений с citations.

Ошибки: `404`.

### Удалить чат

DELETE `/vaults/{vault_id}/ai/chats/{chat_id}`

Ответ: `204`.

Ошибки: `404`.

## AI-suggestions

### Создать suggestion

POST `/vaults/{vault_id}/ai/suggestions`

Request:

```json
{
  "type": "summary_insert",
  "note_ids": ["note_1"],
  "instruction": "Add a short summary at the top."
}
```

Ответ: `202`, `JobDTO`.

Ошибки: `400`, `404`, `409`, `429`, `503`.

### Получить suggestion

GET `/vaults/{vault_id}/ai/suggestions/{suggestion_id}`

Ответ: `200`.

```json
{
  "id": "sug_1",
  "status": "ready",
  "type": "summary_insert",
  "patches": [
    {
      "note_id": "note_1",
      "expected_version": 12,
      "diff": "--- old\n+++ new\n"
    }
  ]
}
```

Ошибки: `404`.

### Применить suggestion

POST `/vaults/{vault_id}/ai/suggestions/{suggestion_id}/apply`

Request:

```json
{
  "patch_ids": ["patch_1"],
  "expected_versions": {
    "note_1": 12
  }
}
```

Ответ: `200`, обновленные заметки.

Ошибки: `400`, `404`, `409`.

### Отклонить suggestion

POST `/vaults/{vault_id}/ai/suggestions/{suggestion_id}/reject`

Ответ: `204`.

Ошибки: `404`.

## Аккаунт и managed cloud

### Получить статус аккаунта

GET `/account`

Ответ: `200`.

```json
{
  "authenticated": true,
  "email": "user@example.com",
  "plan": "pro",
  "managed_ai_enabled": true
}
```

### Начать авторизацию

POST `/account/login`

Ответ: `200`.

```json
{
  "auth_url": "https://opal.example/auth"
}
```

### Выйти из аккаунта

POST `/account/logout`

Ответ: `204`.

## Sync

### Получить статус sync

GET `/vaults/{vault_id}/sync/status`

Ответ: `200`.

```json
{
  "enabled": true,
  "status": "idle",
  "last_sync_at": "2026-06-23T00:00:00Z",
  "pending_uploads": 0,
  "pending_downloads": 0,
  "conflicts": 0
}
```

Ошибки: `404`, `401`.

### Включить sync

POST `/vaults/{vault_id}/sync/enable`

Request:

```json
{
  "remote_vault_id": null
}
```

Ответ: `202`, `JobDTO`.

Ошибки: `400`, `401`, `404`, `409`.

### Выключить sync

POST `/vaults/{vault_id}/sync/disable`

Ответ: `204`.

Ошибки: `401`, `404`.

### Получить список конфликтов sync

GET `/vaults/{vault_id}/sync/conflicts`

Ответ: `200`.

```json
{
  "items": []
}
```

Ошибки: `401`, `404`.

### Разрешить конфликт sync

POST `/vaults/{vault_id}/sync/conflicts/{conflict_id}/resolve`

Request:

```json
{
  "strategy": "keep_both"
}
```

`strategy`: `use_local`, `use_remote`, `keep_both`, `manual_merge`.

Ответ: `200`.

Ошибки: `400`, `401`, `404`, `409`.

## Диагностика

### Экспортировать диагностику

POST `/diagnostics/export`

Request:

```json
{
  "include_logs": true,
  "include_system_info": true,
  "include_note_content": false
}
```

Ответ: `200`.

```json
{
  "path": "C:/Users/user/AppData/Local/Opal/diagnostics/opal-diagnostics.zip"
}
```

Ошибки: `400`, `500`.

## Формат ошибки

```json
{
  "code": "semantic_search_unavailable",
  "message": "Semantic search requires configured embeddings.",
  "details": {
    "missing": "embedding_model"
  }
}
```
