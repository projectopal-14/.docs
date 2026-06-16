# Vault
## модель данных
```
type Vault struct {
    ID             string
    Name           string
    Path           string
    Description    string
    IsActive       bool
    Status         VaultStatus
    IndexingStatus IndexingStatus
    CreatedAt      time.Time
    UpdatedAt      time.Time
    LastOpenedAt   *time.Time
    Settings       VaultSettings
}
```
```
type VaultSettings struct {
    DefaultNotesFolder  string   `json:"default_notes_folder"`
    AttachmentsFolder   string   `json:"attachments_folder"`
    ExcludedPaths       []string `json:"excluded_paths"`
    AIEnabled           bool     `json:"ai_enabled"`
    AIMode              string   `json:"ai_mode"`
    SyncEnabled         bool     `json:"sync_enabled"`
    UseGitIgnore        bool     `json:"use_git_ignore"`
}
```
## Контракт
### Создать
POST /vaults
```
{
  "name": "Personal Notes",
  "path": "D:/Notes/Personal"
}
```
ответ: 201, модель
ошибки: 400, 404, 409

### Подключение существующего vault
POST /vaults/import
```
{
  "path": "D:/Obsidian/MyVault"
}
```
ответ: 201, модель
ошибки: 400, 404

### Получить список vault-ов
GET /vaults
ответ: 200, список моделей (без пагинации)

### Получить vault по id
GET /vaults/{vault_id}
ответ: 200, модель
ошибки: 404

### Обновить vault
PATCH /vaults/{vault_id}
```
{
  "name": "Work Notes",
  "settings": {
    "excluded_paths": [".git", "node_modules", "archive"],
    "ai_mode": "local"
  }
}
```
ответ: 200, обновленная модель
ошибки: 200, 404

### Удалить
DELETE /vaults/{vault_id}
ответ: 204, 404

### Открыть / активировать vault
POST /vaults/{vault_id}/open
ответ: 204, 404
