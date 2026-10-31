# Project Navigation & Onboarding Guide

This document enables any developer or AI coding agent to orient themselves in the `Treecremental` repository and resume work in under 60 seconds.

---

## 1. Cold-Start Resume Protocol (How to Pick Up Where Work Left Off)

Whenever a human developer or AI session opens this repository, follow these 4 steps in order:

1. **Check the Session Checkpoint (`production/session-state/active.md`)**
   - Read the `<!-- CHECKPOINT -->` block at the top of `production/session-state/active.md`. It records the exact current task, the next concrete action, active branch, and any blockers.
   - Check `production/stage.txt` and `project.yaml` to confirm the active lifecycle stage (currently `planning`).
2. **Review Master Rules (`CLAUDE.md` and `.claude/rules/*.md`)**
   - Verify all non-negotiable constraints before touching any file:
     - **Zero hardcoded numbers or formulas** in GDScript (`src/`).
     - **Zero offline progression mechanics** (active session design only).
     - **Zero emojis or AI-generated conversational artifacts** in code, comments, or documentation.
     - **100% localized strings** through `i18n/game_text.csv` (`KEY_...` format, English base).
3. **Consult the Master Design & Upgrade Specification (`docs/architecture/treecremental_design_doc.md`)**
   - Contains the complete system architecture, the 3-Act Plateau-Curve mathematical model, the 4 UI/gameplay mockups, and the **unabridged itemized catalog of all 87 upgrade tracks (542 levels)**.
4. **Cross-Reference the Entity Registry (`design/registry/entities.yaml`)**
   - Before referencing any species, resource currency, gameplay loop, or upgrade ID in data or code, verify its canonical `snake_case` identifier in `design/registry/entities.yaml`.

---

## 2. Directory Map & Ownership Boundaries

```text
treecremental-game/
|-- CLAUDE.md                        # AI agent master entrypoint and rules summary
|-- AGENTS.md                        # Secondary agent entrypoint pointer
|-- README.md                        # Human developer overview and quick commands
|-- project.yaml                     # Machine-readable project configuration (source of truth)
|-- project.godot                    # Godot 4.7 project configuration (640x360, integer scale)
|-- .claude/
|   `-- rules/                       # Path-scoped engineering and documentation rules
|       |-- gameplay-code.md         # Rules for src/**
|       |-- ui-code.md               # Rules for src/ui/**
|       |-- data-files.md            # Rules for data/** and i18n/**
|       `-- design-docs.md           # Rules for design/** and docs/**
|-- data/                            # Externalized game balance and configuration (.tres)
|   |-- balance/
|   |   |-- balance_default.tres     # Active BalanceConfig profile
|   |   `-- curves/                  # Shared FormulaCurve resources (hire, tool, sawmill)
|   |-- species/                     # 9 SpeciesData resources (pine.tres .. giant_sequoia.tres)
|   `-- settings/                    # NotationConfig (notation_default.tres)
|-- design/
|   |-- registry/
|   |   `-- entities.yaml            # Canonical IDs for all species, currencies, loops, upgrades
|   |-- art/
|   |   `-- art_steam_blueprint.md   # Standalone Art & Steam Marketing continuation prompt
|   `-- mockups/                     # 2D pixel-art UI and gameplay visual mockups
|       |-- mockup_gameplay_hud.jpg
|       |-- mockup_subloops_panel.jpg
|       |-- mockup_prestige_tree.jpg
|       `-- mockup_settings_i18n.jpg
|-- docs/
|   |-- NAVIGATION.md                # This onboarding and navigation guide
|   |-- architecture/
|   |   `-- treecremental_design_doc.md  # Master Architecture, Systems & Itemized Upgrade Doc
|   `-- engine-reference/
|       `-- godot/                   # Godot 4.7 API reference and GDScript best practices
|-- i18n/
|   |-- game_text.csv                # Master English (en) + es_419 + es_ES translation table
|   `-- ui_en.csv                    # Base UI string keys
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

### 3.1 Run the Pacing Simulator
```powershell
python tools/balance_sim/sim.py
```
To test human player efficiency (e.g., 78% optimal purchase timing):
```powershell
python tools/balance_sim/sim.py bot_efficiency=0.78
```

### 3.2 Recalibrate Breakthrough Gates
```powershell
python tools/balance_sim/calibrate.py
```

### 3.3 Export Baseline `.tres` Files from Simulator Parameters
```powershell
python tools/export_balance_tres.py
```

### 3.4 Run Headless Godot Schema & Math Smoke Tests
```powershell
& "C:\Users\MrSeb\OneDrive\Desktop\Godot.exe" --headless --path . res://tests/smoke/smoke_formulas.tscn
```
Expected output: `SMOKE RESULT: PASS (0 failures)`.
