# Контракты заметок, папок и вложений

Этот файл добавляет предлагаемые контракты для сценариев заметок. Существующий файл `contracts/contracts.md` не изменяется и остается источником текущего контракта vault.

## Модели данных

### NoteDTO

```go
type NoteDTO struct {
    ID            string
    VaultID       string
    Title         string
    Path          string
    Folder        string
    Status        NoteStatus
    Version       int64
    Content       *string
    ContentHash   string
    SizeBytes     int64
    CreatedAt     time.Time
    UpdatedAt     time.Time
    DeletedAt     *time.Time
    Tags          []string
    Frontmatter   map[string]any
}
```

### NoteListItemDTO

```go
type NoteListItemDTO struct {
    ID          string
    VaultID     string
    Title       string
    Path        string
    Folder      string
    Status      NoteStatus
    Version     int64
    ContentHash string
    UpdatedAt   time.Time
    Tags        []string
}
```

### FolderDTO

```go
type FolderDTO struct {
    VaultID   string
    Path      string
    Name      string
    Parent    string
    CreatedAt time.Time
    UpdatedAt time.Time
}
```

### AttachmentDTO

```go
type AttachmentDTO struct {
    ID        string
    VaultID   string
    NoteID    *string
    Name      string
    Path      string
    MimeType  string
    SizeBytes int64
    CreatedAt time.Time
}
```

## Заметки

### Создать заметку

POST `/vaults/{vault_id}/notes`

Request:

```json
{
  "title": "Meeting notes",
  "folder": "work/meetings",
  "content": "# Meeting notes\n"
}
```

Ответ: `201`, `NoteDTO` с `content`.

Ошибки: `400`, `404`, `409`.

### Получить список заметок

GET `/vaults/{vault_id}/notes?folder=work&status=active&limit=100&cursor=...`

Ответ: `200`.

```json
{
  "items": [],
  "next_cursor": null
}
```

Элементы списка имеют тип `NoteListItemDTO`. Полный `content` не возвращается.

Ошибки: `404`.

### Получить заметку

GET `/vaults/{vault_id}/notes/{note_id}`

Ответ: `200`, `NoteDTO` с `content`.

Ошибки: `404`.

### Обновить content заметки

PUT `/vaults/{vault_id}/notes/{note_id}/content`

Request:

```json
{
  "content": "# Updated\n",
  "expected_version": 12
}
```

Ответ: `200`, обновленный `NoteDTO` с `content`.

Ошибки: `400`, `404`, `409`.

`409` означает конфликт версий и должен включать текущую metadata заметки.

### Переименовать заметку

PATCH `/vaults/{vault_id}/notes/{note_id}/rename`

Request:

```json
{
  "title": "New title",
  "expected_version": 12
}
```

Ответ: `200`, обновленный `NoteDTO`.

Ошибки: `400`, `404`, `409`.

### Переместить заметку

PATCH `/vaults/{vault_id}/notes/{note_id}/move`

Request:

```json
{
  "target_folder": "archive/2026",
  "expected_version": 12
}
```

Ответ: `200`, обновленный `NoteDTO`.

Ошибки: `400`, `404`, `409`.

### Удалить заметку

DELETE `/vaults/{vault_id}/notes/{note_id}`

Ответ: `204`.

Ошибки: `404`, `409`.

Поведение по умолчанию - мягкое удаление через перенос файла в `.trash`.

### Восстановить заметку

POST `/vaults/{vault_id}/notes/{note_id}/restore`

Request:

```json
{
  "restore_path": "optional/path.md",
  "on_conflict": "suggest_new_name"
}
```

Ответ: `200`, восстановленный `NoteDTO`.

Ошибки: `400`, `404`, `409`.

## Папки

### Создать папку

POST `/vaults/{vault_id}/folders`

Request:

```json
{
  "path": "work/meetings"
}
```

Ответ: `201`, `FolderDTO`.

Ошибки: `400`, `404`, `409`.

### Получить список папок

GET `/vaults/{vault_id}/folders`

Ответ: `200`, список `FolderDTO`.

Ошибки: `404`.

### Переместить или переименовать папку

PATCH `/vaults/{vault_id}/folders`

Request:

```json
{
  "source_path": "work/meetings",
  "target_path": "work/archive/meetings"
}
```

Ответ: `200`, обновленный `FolderDTO`.

Ошибки: `400`, `404`, `409`.

### Удалить папку

DELETE `/vaults/{vault_id}/folders?path=work/archive`

Ответ: `204`.

Ошибки: `400`, `404`, `409`.

`409` возвращается, когда папка не пуста и recursive delete не был явно запрошен.

## Вложения

### Добавить вложение

POST `/vaults/{vault_id}/attachments`

Запрос использует `multipart/form-data`:

- `file`
- `note_id` optional
- `target_folder` optional

Ответ: `201`.

```json
{
  "attachment": {},
  "markdown_link": "![image](attachments/image.png)"
}
```

Ошибки: `400`, `404`, `409`, `413`.

### Получить список вложений

GET `/vaults/{vault_id}/attachments?note_id=...`

Ответ: `200`, список `AttachmentDTO`.

Ошибки: `404`.

### Удалить вложение

DELETE `/vaults/{vault_id}/attachments/{attachment_id}`

Ответ: `204`.

Ошибки: `404`, `409`.

`409` возвращается, когда на вложение еще есть ссылки и force delete не был запрошен.

## Формат ошибки

Все endpoints должны использовать единый формат ошибки:

```json
{
  "code": "note_version_conflict",
  "message": "Note was changed by another operation.",
  "details": {}
}
```
