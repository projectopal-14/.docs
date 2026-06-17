В качестве источника истины выступают сами заметки в формате .md
SQLite хранит только метаданные

## UC-007. Создать заметку
Пользователь создает новую .md заметку в активном vault-е.
1. UI отправляет title, folder, content.
2. Backend валидирует title/path.
3. Backend создает .md файл.
4. Backend создает запись notes в index.db.
5. Backend ставит job index_note.
6. Backend возвращает NoteDTO.

## UC-008. Получить список заметок
Пользователь открывает список заметок в vault-е.
1. UI вызывает GET /vaults/{vault_id}/notes.
2. Backend читает notes из index.db.
3. Возвращает краткие данные без полного content.

UC-003. Открыть заметку
Пользователь кликает на заметку.
1. UI вызывает GET /vaults/{vault_id}/notes/{note_id}.
2. Backend проверяет note_id.
3. Backend читает .md файл с диска.
4. Backend возвращает content + metadata.

UC-004. Обновить заметку
Пользователь редактирует markdown.
1. UI отправляет новый content и expected_version.
2. Backend проверяет, что заметка существует.
3. Backend проверяет version, чтобы не затереть акутуальное  изменение.
4. Backend атомарно перезаписывает .md файл.
5. Backend обновляет notes.content_hash.
6. Backend создает note_version.
7. Backend ставит job index_note.
8. Возвращает обновленную NoteDTO.

UC-005. Переименовать заметку
Пользователь меняет название заметки.
1. UI отправляет новый title.
2. Backend строит новый filename.
3. Проверяет конфликт имени.
4. Переименовывает .md файл.
5. Обновляет path/title в notes.
6. Ставит job index_note.
7. Ставит job update_links.

UC-006. Переместить заметку
Пользователь переносит заметку в другую папку в рамках одно vault.
1. UI отправляет target_folder.
2. Backend проверяет folder.
3. Перемещает файл.
4. Обновляет path.
5. Ставит job index_note.

UC-007. Удалить заметку
Мягкое удаление
1. UI вызывает DELETE.
2. Backend переносит файл в .trash.
3. Помечает note как deleted.
4. Удаляет/помечает chunks, links, embeddings как stale.
5. Ставит job cleanup_note_index.

UC-008. Восстановить заметку
1. UI вызывает restore.
2. Backend проверяет original_path.
3. Если путь свободен — возвращает файл.
4. Если путь занят — предлагает новое имя.
5. Обновляет status = active.
6. Ставит job index_note.
