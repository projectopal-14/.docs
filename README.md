# Документация Opal

Документация для Opal: desktop-приложения для markdown-заметок с AI-функциями, семантическим поиском и RAG-чатом по vault-у.

## Карта документов

- [requirements.md](requirements.md) - продуктовые, функциональные и нефункциональные требования.
- [usecases/usecases.md](usecases/usecases.md) - существующие use cases для vault. Не менять без согласования.
- [usecases/notes.md](usecases/notes.md) - существующие use cases для заметок. Не менять без согласования.
- [usecases/search-ai-sync.md](usecases/search-ai-sync.md) - новые use cases для индексации, поиска, AI, sync и desktop-оболочки.
- [contracts/contracts.md](contracts/contracts.md) - существующие контракты vault. Не менять без согласования.
- [contracts/notes.md](contracts/notes.md) - предлагаемые контракты заметок, папок и вложений.
- [contracts/search-ai-sync.md](contracts/search-ai-sync.md) - предлагаемые контракты поиска, индексации, AI, аккаунта и sync.
- [diagrams/sequences.md](diagrams/sequences.md) - сиквенс-диаграммы для ключевых сценариев.

## Принципы

1. Markdown-файлы являются источником истины.
2. SQLite хранит служебное состояние: метаданные, FTS, chunks, links, jobs, suggestions, embeddings/vector index.
3. Local Go core отвечает за vault, файлы, индексацию, поиск, embeddings, RAG и AI-оркестрацию.
4. Electron UI не работает с файлами напрямую: все операции идут через локальный core.
5. AI-режимы должны быть взаимозаменяемыми на уровне use cases: local Ollama, BYOK provider, managed cloud.
6. Существующие use cases и контракты считаются закрепленными и меняются только после явного согласования.
