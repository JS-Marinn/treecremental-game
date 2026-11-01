---
paths:
  - "src/ui/**"
---

# UI Code & Godot Scene Groundwork Rules

- **Division of Labor (Editable Godot Mockup Groundwork Only)**: Do NOT build complex, heavily styled, or procedurally generated UIs in GDScript. Provide clean, human-editable `.tscn` wireframe mockup scenes using standard Godot `Control` containers (`HBoxContainer`, `MarginContainer`, `VBoxContainer`, `GridContainer`, `PanelContainer`) and `%UniqueNodeNames` (`unique_name_in_owner = true`) so the developer can visually rearrange, resize, and skin the UI directly inside the Godot 2D Editor without breaking script references.
- **Right-Hand Docked HUD Layout (`640x360` Base)**:
  - **Left/Center Column (`432x360 px`)**: Contains the `432x28 px` Top Resource & Breakthrough Strip above the `432x332 px` oblique 3/4 top-down Logging Compound (`SubViewportContainer` / `Node2D` with `y_sort_enabled = true`).
  - **Right-Hand Docked Command Panel (`208x360 px`)**: Permanently docked right-side panel housing the loop tabs (`Trees`, `Workers`, `Mill`, `Roots`), bulk-buy buttons (`x1`, `x10`, `MAX`), scrollable upgrade cards, and footer modal buttons (`Prestige`, `Achievements`, `Settings`).
- **Zero Procedural UI Construction**: Never instantiate layout containers, hardcode pixel coordinates, or build styleboxes inside `.gd` scripts. All layout structure belongs in `.tscn` files and a shared `Theme` resource (`res://assets/ui/default_theme.tres`).
- **Display-Only UI State Contract**: UI scripts must never own or directly mutate game state; they subscribe to `EventBus` signals for display updates and call `EventBus.request(command_name, payload)` to dispatch player actions.
- **Localization & Accessibility**: All user-facing text must resolve through `TranslationServer` (`tr("KEY_...")`). Interactive controls must support mouse, keyboard, and gamepad focus navigation. Color must never be the sole indicator of state or tier.
- **Zero Emojis**: Emojis and decorative non-ASCII symbols are prohibited.
