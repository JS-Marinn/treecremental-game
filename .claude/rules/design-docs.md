---
paths:
  - "design/**"
  - "docs/**"
---

# Design & Architecture Document Rules

- Every system design specification must include: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, and Acceptance Criteria.
- Every upgrade in the game must be itemized explicitly with its canonical ID, name, level cap, base cost, scaling formula, currency, and exact per-level mechanical effect. Summaries or placeholder ranges are prohibited.
- Cross-system entity names, currencies, and upgrade IDs must match `design/registry/entities.yaml`.
- Emojis and conversational filler are prohibited in all Markdown documentation.
