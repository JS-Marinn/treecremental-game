# Project Navigation & Onboarding Guide (v0.6)

This document enables any developer or AI coding agent to orient themselves in the `Treecremental` repository and resume work in under 60 seconds.

---

## 1. Cold-Start Resume Protocol (How to Pick Up Where Work Left Off)

Whenever a human developer or AI session opens this repository, follow these 4 steps in order:

1. **Check the Session Checkpoint (`production/session-state/active.md`)**
   - Read the `<!-- CHECKPOINT -->` block at the top of `production/session-state/active.md`. It records the exact current task, the next concrete action, active branch, and any blockers.
   - Check `production/stage.txt` and `project.yaml` to confirm the active lifecycle stage (currently `planning`).
2. **Review Master Rules (`CLAUDE.md` and `.claude/rules/*.md`)**
   - Verify all non-negotiable constraints before touching any file:
     - **Hyper-modular composable data architecture**: All systems communicate via `EventBus` and evaluate modifiers through a central `StatAggregator` query bus so design changes never break existing systems or require refactoring.
     - **Single main-loop currency (`coins`) & self-contained Sawmill**: Harvesting trees generates `coins` directly. The Sawmill requires zero input material; assigning `Simple Lumberjacks` to the Sawmill permanently increases each tree species' base `coins` value and generates `processed_logs` to upgrade Sawmill worker capacity and working speed.
     - **Strict 3-worker-type scope**: Only `simple_lumberjack`, `heavy_sawyer`, and `swift_cleaver` exist. All 3 chop all tree species; **only `simple_lumberjack`** can be shared with the Sawmill.
     - **Tree unlocking via Spawn Probability & Quantity Caps**: New tree species are never purchased directly as shop items; they are unlocked and scaled via `prop_<species>` upgrades.
     - **Right-Hand Docked UI (`208x360 px`) + 3/4 Clearing (`432x360 px`)**: Delivered during development as clean, human-editable Godot `.tscn` Control wireframes.
     - **Zero hardcoded numbers/formulas**, **zero offline mechanics**, **zero emojis/AI artifacts**, and **zero-trace `Autopilot-Godot` Git isolation**.
3. **Consult the Master Design & Upgrade Specification (`docs/architecture/treecremental_design_doc.md`)**
   - Contains the complete v0.6 system architecture, the 3-Act Plateau-Curve mathematical model, the Right-Hand Docked UI specification, and the **unabridged itemized catalog of all 87 upgrade tracks (538 levels)**.
4. **Cross-Reference the Entity Registry (`design/registry/entities.yaml`)**
   - Before referencing any species, worker type, currency, gameplay loop, synergy, or upgrade ID in data or code, verify its canonical `snake_case` identifier in `design/registry/entities.yaml`.

---

## 2. Directory Map & Ownership Boundaries

```text
treecremental-game/
|-- CLAUDE.md                        # AI agent master entrypoint and rules summary (v0.6)
|-- AGENTS.md                        # Secondary agent entrypoint pointer (mirror of CLAUDE.md)
|-- README.md                        # Human developer overview and quick links
|-- project.yaml                     # Machine-readable project configuration (source of truth)
|-- project.godot                    # Godot 4.7 project configuration (640x360, integer scale)
|-- .gitignore                       # Excludes .godot/, addons/autopilot/, tests/autopilot/, override.cfg
|-- .claude/
|   `-- rules/                       # Path-scoped engineering and documentation rules
|       |-- gameplay-code.md         # Rules for src/** (Hyper-modular StatAggregator contract)
|       |-- ui-code.md               # Rules for src/ui/** (Right-Hand Docked editable .tscn contract)
|       |-- data-files.md            # Rules for data/** and i18n/**
|       `-- design-docs.md           # Rules for design/** and docs/**
|-- data/                            # Externalized game balance and configuration (.tres)
|   |-- balance/
|   |   |-- balance_default.tres     # Active BalanceConfig profile
|   |   `-- curves/                  # Shared FormulaCurve resources
|   |-- species/                     # 9 SpeciesData resources (pine.tres .. giant_sequoia.tres)
|   `-- settings/                    # NotationConfig (notation_default.tres)
|-- design/
|   |-- registry/
|   |   `-- entities.yaml            # Canonical IDs for all 3 acts, 9 species, 3 workers, 7 currencies, 87 upgrades
|   |-- art/
|   |   `-- art_steam_blueprint.md   # Standalone Art & Steam Marketing continuation prompt (v0.6)
|   `-- mockups/                     # Visual reference and 2D pixel-art UI/gameplay mockups
|       |-- reference_camera_and_hud_layout.jpg  # 3/4 camera angle reference only (not HUD or art style)
|       |-- mockup_gameplay_v05_final.jpg        # Right-Hand Docked UI + 3/4 clearing layout mockup
|       |-- mockup_logging_camp_clearing.jpg     # 3/4 clearing concept mockup
|       |-- mockup_subloops_panel.jpg            # Secondary & Tertiary loops split-view mockup
|       |-- mockup_prestige_tree.jpg             # Heartwood Ascension prestige constellation mockup
|       `-- mockup_settings_i18n.jpg             # System settings, accessibility & i18n modal mockup
|-- docs/
|   |-- NAVIGATION.md                # This onboarding and navigation guide
|   |-- architecture/
|   |   `-- treecremental_design_doc.md  # Master Architecture, Systems & Itemized 87-Upgrade Doc (v0.6)
|   `-- engine-reference/
|       `-- godot/
|           `-- VERSION.md           # Godot 4.7.2 API reference and GDScript best practices
|-- i18n/
|   `-- game_text.csv                # Single canonical English (en) + es_419 + es_ES translation table
|-- production/
|   |-- stage.txt                    # Current lifecycle gate ("planning")
|   `-- session-state/
|       `-- active.md                # Living session checkpoint for handoffs
|-- src/                             # GDScript source root (Core schemas only during planning)
|   |-- boot/
|   |   `-- boot.tscn                # Minimal entry scene
|   `-- core/
|       |-- event_bus.gd             # Global signal bus (Autoload: EventBus)
|       |-- balance.gd               # Balance loader & species registry (Autoload: Balance)
|       |-- game_module.gd           # Base contract for decoupled gameplay modules
|       |-- module_registry.gd       # Topological dependency sorter for GameModules
|       |-- locale_resolver.gd       # Steamworks API language code mapper
|       |-- number_formatter.gd      # Standard / Scientific / Engineering number formatter
|       `-- data/                    # Resource class definitions
|           |-- formula_curve.gd     # Designer-editable mathematical curve resource
|           |-- balance_config.gd    # Global balance profile resource
|           |-- species_data.gd      # Per-tree species configuration resource
|           |-- cost_item.gd         # Single-currency cost component
|           |-- cost_bundle.gd       # Multi-currency cost evaluation bundle
|           `-- notation_config.gd   # Number formatting configuration resource
|-- tests/
|   `-- smoke/
|       |-- smoke_formulas.gd        # Headless verification of curves, caps, and species data
|       `-- smoke_formulas.tscn
`-- tools/
    |-- export_balance_tres.py       # Bootstrap generator syncing sim.py params to data/*.tres
    `-- balance_sim/
        |-- sim.py                   # 3-Act Plateau-Curve pacing simulator
        `-- calibrate.py             # Analytical Breakthrough gate calibrator
```

---

## 3. Standard Verification Commands

All verification tools can be executed from the repository root (`C:\Users\MrSeb\GodotProjects\treecremental-game`) without opening a GUI:

### 3.1 Run Headless Godot Schema & Math Smoke Tests
```powershell
& "C:\Users\MrSeb\OneDrive\Desktop\Godot.exe" --headless --path . res://tests/smoke/smoke_formulas.tscn
```
Expected output: `SMOKE RESULT: PASS (0 failures)`.

### 3.2 Run the Pacing Simulator
```powershell
python tools/balance_sim/sim.py
```
