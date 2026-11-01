---
paths:
  - "data/**"
  - "i18n/**"
---

# Data & Localization File Rules (v0.6)

- File naming: lowercase `snake_case` only (e.g., `canadian_maple.tres`, `balance_default.tres`, `game_text.csv`).
- Every entity ID in `data/` (species, worker types, currencies, synergies, upgrades) must be registered in `design/registry/entities.yaml`.
- Every species `.tres` file in `data/species/` must have matching `KEY_TREE_<ID>_NAME` and `KEY_TREE_<ID>_DESC` entries in `i18n/game_text.csv`.
- Every worker type must have matching `KEY_WORKER_<ID>_NAME` and `KEY_WORKER_<ID>_DESC` entries in `i18n/game_text.csv` and define its `allowed_loop_ids` array in data so loop placement never requires code changes.
- `i18n/game_text.csv` is the single canonical localization table (`en`, `es_419`, `es_ES`). Do not create duplicate or partial CSV tables.
- No orphaned data resources; every `.tres` file must be loaded by `Balance` or referenced by an active configuration resource.
- Emojis are prohibited in localization strings and resource fields.
