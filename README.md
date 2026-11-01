# Treecremental

A 2D pixel-art incremental game built in Godot 4.7. Propagate 9 tree species across a 3/4 top-down forest clearing using dynamic spawn probability and quantity upgrades, deploy 3 distinct worker types (`Simple Lumberjacks`, `Heavy Sawyers`, and `Swift Cleavers`) to earn `Coins`, send shared `Simple Lumberjacks` to the Water-Powered Sawmill to amplify individual tree species values and upgrade Sawmill workforce capacity and speed via `Processed Logs`, fire Brick Charcoal Kilns, cultivate a Canopy Aviary and underground Mycelium Root Network, and ascend through the Heartwood Sap constellation.

## Project Status

- **Current Stage**: `planning` (v0.6 — Architectural design, hyper-modular `StatAggregator` specification, 3-Act Plateau-Curve mathematical model, itemized 87-upgrade catalog, and Right-Hand Docked UI groundwork phase).
- **Target Playthrough Duration**: ~3.0 hours for main campaign completion (*The Great Felling*); ~4.0 hours for 100% achievement and upgrade completion.
- **Session Model**: Active/semi-idle continuous session. Zero offline progression mechanics.

## Navigation for Developers & AI Agents

To pick up where work left off at any point:

1. **Session Checkpoint**: Read [`production/session-state/active.md`](production/session-state/active.md) first.
2. **Onboarding & Directory Map**: Read [`docs/NAVIGATION.md`](docs/NAVIGATION.md).
3. **Master Architecture & Complete Upgrade Catalog (v0.6)**: Read [`docs/architecture/treecremental_design_doc.md`](docs/architecture/treecremental_design_doc.md).
4. **Canonical Entity & Upgrade Registry (v0.6)**: Read [`design/registry/entities.yaml`](design/registry/entities.yaml).
5. **Art & Steam Store Blueprint (v0.6)**: Read [`design/art/art_steam_blueprint.md`](design/art/art_steam_blueprint.md).
6. **Agent Rules & Coding Standards**: Read [`CLAUDE.md`](CLAUDE.md) and [`.claude/rules/`](.claude/rules/).
