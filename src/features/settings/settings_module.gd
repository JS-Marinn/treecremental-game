class_name SettingsModule
extends GameModule
## Owns the live runtime settings state and applies changes to engine systems.
## UI controls dispatch EventBus.setting_changed; this module applies them, and
## SaveModule mirrors the same emissions into the persisted settings section.
##
## Accessibility filters (colorblind, reduce motion, screen shake) are stored and
## exposed through prepared hooks. The colorblind filter resolves its drop-in shader
## asset by AssetResolver naming convention and stays inert while the asset is absent.

const DEFAULT_STATE: Dictionary = {
	"audio": {"master": 0.8, "music": 0.7, "sfx": 0.85, "ui": 0.9},
	"display": {"window_mode": 0, "vsync": true},
	"gameplay": {"notation": 0, "locale": "en"},
	"accessibility": {"colorblind": 0, "reduce_motion": false, "screen_shake": true},
}

var _state: Dictionary = {}
var _colorblind_shader: Shader


func _init() -> void:
	module_id = &"settings"


func _ready() -> void:
	is_active = true
	_reset_to_defaults()
	_apply_all()
	if is_instance_valid(EventBus) and not EventBus.setting_changed.is_connected(_on_setting_changed):
		EventBus.setting_changed.connect(_on_setting_changed)


func get_setting(section: StringName, key: StringName) -> Variant:
	var section_key: String = String(section)
	var inner: Dictionary = _state.get(section_key, {})
	var key_str: String = String(key)
	if inner.has(key_str):
		return inner[key_str]
	var defaults: Dictionary = DEFAULT_STATE.get(section_key, {})
	return defaults.get(key_str)


## Returns the resolved colorblind post-process shader, or null when the drop-in
## shader asset has not been delivered yet.
func get_colorblind_shader() -> Shader:
	return _colorblind_shader


func serialize() -> Dictionary:
	return _state.duplicate(true)


func deserialize(data: Dictionary) -> void:
	_state = data.duplicate(true)
	_apply_all()


func _reset_to_defaults() -> void:
	_state = DEFAULT_STATE.duplicate(true)


func _apply_all() -> void:
	for section in _state.keys():
		var inner: Dictionary = _state[section]
		for key in inner.keys():
			_apply_setting(StringName(String(section)), StringName(String(key)), inner[key])


func _on_setting_changed(section: StringName, key: StringName, value: Variant) -> void:
	var section_key: String = String(section)
	if not _state.has(section_key):
		_state[section_key] = {}
	_state[section_key][String(key)] = value
	_apply_setting(section, key, value)


func _apply_setting(section: StringName, key: StringName, value: Variant) -> void:
	match section:
		&"audio":
			match key:
				&"master":
					_set_bus_volume(&"Master", float(value))
				&"music":
					_set_bus_volume(&"Music", float(value))
				&"sfx":
					_set_bus_volume(&"SFX", float(value))
				&"ui":
					_set_bus_volume(&"UI", float(value))
		&"display":
			match key:
				&"window_mode":
					_apply_window_mode(int(value))
				&"vsync":
					DisplayServer.window_set_vsync_mode(
						DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED
					)
		&"gameplay":
			match key:
				&"notation":
					NumberFormatter.active_mode = clampi(int(value), 0, 2) as NumberFormatter.Mode
					if is_instance_valid(EventBus):
						EventBus.notation_changed.emit()
				&"locale":
					LocaleResolver.apply_locale(String(value))
		&"accessibility":
			match key:
				&"colorblind":
					_apply_colorblind_filter(int(value))
				&"reduce_motion", &"screen_shake":
					# Stored for gameplay FX consumers; no asset pipeline required.
					pass


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_idx, -80.0 if clamped <= 0.0 else linear_to_db(clamped))


func _apply_window_mode(mode_index: int) -> void:
	match mode_index:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


func _apply_colorblind_filter(filter_index: int) -> void:
	var shader_name: StringName = &""
	match filter_index:
		1:
			shader_name = &"colorblind_deuteranopia"
		2:
			shader_name = &"colorblind_protanopia"
		3:
			shader_name = &"colorblind_tritanopia"
	if shader_name == &"":
		_colorblind_shader = null
		return
	var path: String = AssetResolver.shader_path(shader_name)
	_colorblind_shader = null if path == "" else (load(path) as Shader)
