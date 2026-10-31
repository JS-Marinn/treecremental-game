---
paths:
  - "data/**"
  - "i18n/**"
---

# Data & Localization File Rules

- File naming: lowercase `snake_case` only (e.g., `canadian_maple.tres`, `balance_default.tres`, `game_text.csv`).
- Every entity ID in `data/` must be registered in `design/registry/entities.yaml`.
- Every species `.tres` file in `data/species/` must have matching `KEY_TREE_<ID>_NAME` and `KEY_TREE_<ID>_DESC` entries in `i18n/game_text.csv`.
- No orphaned data resources; every `.tres` file must be loaded by `Balance` or referenced by an active configuration resource.
- Emojis are prohibited in localization strings and resource fields.
