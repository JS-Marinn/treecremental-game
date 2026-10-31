---
paths:
  - "src/**"
---

# Gameplay & Core Code Rules

- All gameplay values, costs, caps, and scaling curves must load from external `.tres` Resource files in `data/`. Hardcoding numbers or formulas in GDScript is prohibited.
- Use `delta` for all time-dependent runtime calculations.
- Offline progression (`offline_step`, away-from-keyboard time-delta catchup, or offline efficiency bonuses) is prohibited. The game is an active/semi-idle experience designed for a 3-to-4-hour completion window.
- Never reference UI nodes from gameplay or core scripts. Emit signals on `EventBus` (`src/core/event_bus.gd`).
- Every gameplay module must inherit from `GameModule` (`src/core/game_module.gd`) and register with `ModuleRegistry` (`src/core/module_registry.gd`).
- Emojis, non-ASCII decorative characters, and conversational AI comments are prohibited in all source files.
- All variables, parameters, and return types must use explicit GDScript static typing.
