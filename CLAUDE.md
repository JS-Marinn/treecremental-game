# Treecremental -- Master Agent & Developer Configuration (v0.6)

This repository uses the structural architecture and context-management conventions generalized from Claude Code Game Studios for Godot 4 development.

## Current Project Stage

- **Stage**: `planning` (see `production/stage.txt` and `project.yaml`).
- **Directive**: Do NOT begin gameplay or UI implementation until the planning phase is formally signed off and `project.stage` is advanced to `production`.

## Technology Stack

- **Engine**: Godot 4.7.2 (`gl_compatibility` renderer)
- **Language**: GDScript (statically typed)
- **Resolution & Scaling**: 640x360 base viewport, `canvas_items` stretch, `integer` scaling, nearest-neighbor texture filtering, 2D pixel snapping enabled
- **Viewport Split & Spatial View**:
  - **Left/Center Column (`432x360 px`)**: `432x28 px` Top Resource & Breakthrough Strip above a `432x332 px` oblique 3/4 top-down Logging Clearing (`Node2D` world with `y_sort_enabled = true`) featuring dynamic tree plots, a visible Sawmill & Kiln Yard corner, and **3 distinct worker types** (`Simple Lumberjack`, `Heavy Sawyer`, `Swift Cleaver`).
  - **Right-Hand Docked Command Panel (`208x360 px`)**: Permanently docked right-side HUD housing loop tabs (`Trees`, `Crew`, `Mill`, `Roots`), bulk-buy buttons, and scrollable upgrade cards.
- **Version Control**: Git with trunk-based development and Conventional Commits

## Mandatory Cold-Start Protocol (Read First)

Any human developer or AI agent starting or resuming a session in this repository MUST read these files in order:

1. `production/session-state/active.md` -- Read the `CHECKPOINT` block first. The file on disk is the persistent memory across sessions.
2. `project.yaml` -- Machine-readable project configuration and constraints.
3. `docs/NAVIGATION.md` -- Complete directory map, architectural boundaries, and verification commands.
4. `design/registry/entities.yaml` -- Single source of truth for all canonical IDs (species, worker types, currencies, loops, upgrades).
5. `docs/architecture/treecremental_design_doc.md` -- Master Architecture (v0.6), Hyper-Modular `StatAggregator` Design, Sawmill Value-Amplification Loop, 3 Worker Types, and Itemized Upgrades.

## Strict Architectural & Code Rules

1. **Extreme Modularity & Zero-Refactor Extensibility**: All entities (`WorkerArchetypeData`, `SpeciesData`, `UpgradeDefinitionData`, `StatModifierData`) are composable `.tres` data resources evaluated through a central `StatAggregator`. Changing worker counts, allowed loop placements (`allowed_loop_ids`), currencies, or upgrade effects must never break existing systems or require GDScript refactoring.
2. **Single Main Currency & Sawmill Value Loop**: The main loop uses a single primary currency (`coins`). The Sawmill requires **zero input materials** to operate: assigning `Simple Lumberjacks` to process a wood type in the Sawmill permanently raises that tree species' base `coins` value in the main loop and generates `processed_logs` used to upgrade Sawmill worker capacity and working speed.
3. **Strict 3-Worker-Type Scope & Placement**: Only 3 worker types exist (`simple_lumberjack`, `heavy_sawyer`, `swift_cleaver`). All 3 can chop all tree types, differentiated by stats/behaviors. **Only `simple_lumberjack`** can be shared between the Main Loop and the Sawmill; `heavy_sawyer` and `swift_cleaver` operate exclusively in the Main Loop.
4. **Tree Unlocking via Spawn Probability & Quantity Caps**: New tree species are NEVER purchased directly as shop items. Progression uses Species Propagation upgrades (`prop_<species>`) that unlock and increase each species' Spawn Probability Weight ($W_i$) and Max Concurrent Quantity Cap ($Q_i$).
5. **Zero Offline Mechanics**: Offline time-delta progression (`offline_step`, offline efficiency multipliers, away-from-keyboard catchup) is strictly prohibited.
6. **Editable Godot UI Mockup Groundwork Only**: During development, lay down clean, easily editable `.tscn` Control-node wireframes using the right-hand docked layout (`HBoxContainer` split) and `%UniqueNodeNames` so the human developer can visually edit and style the UI in the Godot Editor.
7. **Zero-Trace `Autopilot-Godot` Testing Isolation**: Keep `addons/autopilot/`, `.autopilot/`, `tests/autopilot/`, and `override.cfg` strictly isolated and git-ignored, and sanitize `project.godot` before committing.
8. **Zero Emojis & Zero AI Artifacts**: Emojis, decorative Unicode symbols, and conversational AI comments are strictly prohibited across all code, data files, and documentation.
9. **English-First Localization (i18n)**: All code identifiers, translation keys (`KEY_...`), and base strings in `i18n/game_text.csv` are authored in English (`en`), mapped to Steamworks API language codes (`english` -> `en`, `latam` -> `es_419`, `spanish` -> `es_ES`) via `LocaleResolver`.
