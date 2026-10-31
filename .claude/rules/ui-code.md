---
paths:
  - "src/ui/**"
---

# UI Code & Godot Scene Groundwork Rules

- **Division of Labor (Editable Godot Mockup Groundwork Only)**: Do NOT build complex, heavily styled, or procedurally generated UIs in GDScript. Provide clean, human-editable `.tscn` wireframe mockup scenes using standard Godot `Control` containers (`CanvasLayer`, `MarginContainer`, `VBoxContainer`, `HBoxContainer`, `GridContainer`, `PanelContainer`) and `%UniqueNodeNames` (`unique_name_in_owner = true`) so the developer can visually rearrange, resize, and skin the UI directly inside the Godot 2D Editor without breaking script references.
- **Zero Procedural UI Construction**: Never instantiate layout containers, hardcode pixel coordinates, or build styleboxes inside `.gd` scripts. All layout structure belongs in `.tscn` files and a shared `Theme` resource (`res://assets/ui/default_theme.tres`).
- **Minimalist Perimeter HUD & On-Demand Overlays**: The main gameplay screen uses a 100% full-viewport oblique 3/4 top-down forest clearing (`640x360`). Never dock permanent wide panels on the side of the main viewport. Keep the HUD anchored to the screen perimeter (top-left currency counter and stacked menu buttons, top-center camp/Act header, top-right achievements/settings buttons, bottom-center logging rate readout). Upgrades, Sub-Loops, Prestige, Achievements, and Settings open as toggleable overlay panels (`visible = true/false`).
- **Display-Only UI State Contract**: UI scripts must never own or directly mutate game state; they subscribe to `EventBus` signals for display updates and call `EventBus.request(command_name, payload)` to dispatch player actions.
- **Localization & Accessibility**: All user-facing text must resolve through `TranslationServer` (`tr("KEY_...")`). Interactive controls must support mouse, keyboard, and gamepad focus navigation. Color must never be the sole indicator of state or tier.
- **Zero Emojis**: Emojis and decorative non-ASCII symbols are prohibited.
