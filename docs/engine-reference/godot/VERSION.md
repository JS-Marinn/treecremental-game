# Godot Engine -- Version Reference

| Field | Value |
|---|---|
| **Engine Version** | Godot 4.7.2.stable.official.ed1daf0bf |
| **Installed Local Binary** | `C:\Users\MrSeb\OneDrive\Desktop\Godot.exe` |
| **Renderer** | `gl_compatibility` |
| **Project Pinned** | 2026-10-30 |

## Key GDScript & Engine Conventions (Godot 4.5 - 4.7)

1. **Lambdas capture local primitive variables by value**: Mutating an outer `int`, `float`, or `bool` inside a lambda modifies a local copy. When a signal callback needs to mutate shared state in tests or handlers, store the state inside a `Dictionary`, `Array`, or object instance.
2. **Recursive functions must be class methods**: Do not write recursive lambdas assigned to local `Callable` variables; use private class helper methods (`func _visit(...) -> void`).
3. **Typed method overrides**: In Godot 4.7, overriding a method with a declared return type inherits that return type requirement.
4. **PackedArray element assignment**: Assigning a single index (`arr[i] = v`) on a `PackedInt32Array` or `PackedFloat64Array` does not trigger a property setter; reassign the array when a setter must fire.
