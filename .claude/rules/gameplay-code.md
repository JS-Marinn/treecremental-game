---
paths:
  - "src/**"
---

# Gameplay & Core Code Rules (Hyper-Modular Architecture)

- **Zero Hardcoded Values**: All gameplay values, costs, caps, allowed loop assignments (`allowed_loop_ids`), and scaling curves must load from external `.tres` Resource files in `data/`. Hardcoding numbers, formulas, or worker/tree counts in GDScript is prohibited.
- **Extreme Modularity & Composable `StatAggregator` Pattern**:
  - Gameplay modules (`LoggingCampModule`, `SawmillModule`, `KilnModule`, `AviaryModule`, `MyceliumModule`) must never directly reference or depend on one another.
  - All cross-system bonuses (e.g., Sawmill increasing a tree species' base coin value, Boiler thermal overclock, Aviary buffs, Mycelium symbiosis, Sap multipliers) must be registered as data-driven modifiers on a central `StatAggregator` and queried by `(domain, stat_key)`.
  - Adding, removing, or changing a worker type, tree species, currency, or loop assignment must require zero refactoring of existing GDScript modules.
- **Use `delta` for all time-dependent runtime calculations.**
- **Zero Offline Progression**: `offline_step`, away-from-keyboard time-delta catchup, and offline efficiency bonuses are strictly prohibited.
- **Decoupled UI Contract**: Never reference UI nodes from gameplay or core scripts. Emit signals on `EventBus` (`src/core/event_bus.gd`).
- **Strict Hygiene**: Emojis, non-ASCII decorative characters, and conversational AI comments are prohibited in all source files. All variables, parameters, and return types must use explicit GDScript static typing.
