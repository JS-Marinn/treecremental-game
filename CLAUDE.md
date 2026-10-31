# Treecremental -- Master Agent & Developer Configuration

This repository uses the structural architecture and context-management conventions generalized from Claude Code Game Studios for Godot 4 development.

## Current Project Stage

- **Stage**: `planning` (see `production/stage.txt` and `project.yaml`).
- **Directive**: Do NOT begin gameplay or UI implementation until the planning phase is formally signed off and `project.stage` is advanced to `production`.

## Technology Stack

- **Engine**: Godot 4.7.2 (`gl_compatibility` renderer)
- **Language**: GDScript (statically typed)
- **Resolution & Scaling**: 640x360 base viewport, `canvas_items` stretch, `integer` scaling, nearest-neighbor texture filtering, 2D pixel snapping enabled
- **Camera & Spatial View**: Oblique 3/4 top-down full-screen clearing (`Node2D` world with `y_sort_enabled = true`), central spawn hub, radial species groves, autonomous worker agents, world-space floating `+LOGS` popups, and a minimalist perimeter overlay HUD
- **Version Control**: Git with trunk-based development and Conventional Commits

## Mandatory Cold-Start Protocol (Read First)

Any human developer or AI agent starting or resuming a session in this repository MUST read these files in order:

1. `production/session-state/active.md` -- Read the `CHECKPOINT` block first. The file on disk is the persistent memory across sessions.
2. `project.yaml` -- Machine-readable project configuration and constraints.
3. `docs/NAVIGATION.md` -- Complete directory map, architectural boundaries, and verification commands.
4. `design/registry/entities.yaml` -- Single source of truth for all canonical IDs (species, currencies, loops, upgrades, achievements).
5. `docs/architecture/treecremental_design_doc.md` -- Master Architecture, 3/4 Top-Down Spatial Layout, Editable UI Groundwork Plan, Itemized Upgrades, and Math Specification.

## Strict Architectural & Code Rules

1. **Zero Hardcoded Values**: Numerical parameters, costs, scaling factors, and formulas are strictly prohibited inside GDScript logic. All numbers and curves reside in `data/` as `.tres` Resources (`FormulaCurve`, `BalanceConfig`, `SpeciesData`, `CostBundle`).
2. **Zero Offline Mechanics**: Treecremental is a focused 3-to-4-hour active/semi-idle experience. Offline time-delta progression (`offline_step`, offline efficiency multipliers, away-from-keyboard catchup) is strictly prohibited.
3. **Editable Godot UI Mockup Groundwork Only**: During development, do NOT build complex or procedurally generated UIs in code. Lay down clean, easily editable `.tscn` Control-node wireframes using standard containers and `%UniqueNodeNames` so the human developer can visually edit and style the UI in the Godot Editor.
4. **Zero Emojis & Zero AI Artifacts**: Emojis, decorative Unicode symbols, conversational filler comments, and ASCII section banners are strictly prohibited across all code, data files, and documentation.
5. **Decoupled Event Bus & Modules**: Gameplay loops communicate exclusively through `EventBus` (`src/core/event_bus.gd`). UI nodes are display-only and never mutate game state directly.
6. **English-First Localization (i18n)**: All code identifiers, translation keys (`KEY_...`), and base strings in `i18n/game_text.csv` are authored in English (`en`), mapped to Steamworks API language codes (`english` -> `en`, `latam` -> `es_419`, `spanish` -> `es_ES`) via `LocaleResolver`.

## Rule Definitions

- `.claude/rules/gameplay-code.md`
- `.claude/rules/ui-code.md`
- `.claude/rules/data-files.md`
- `.claude/rules/design-docs.md`
