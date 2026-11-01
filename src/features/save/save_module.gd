class_name SaveModule
extends GameModule
## Versioned atomic JSON save/load for the single save slot (user://save_slot_1.json).
## Strictly zero offline progression: the elapsed wall-clock time since the last save
## is recorded for diagnostics only and never grants any resources or progression.
##
## State is collected from the bound MainScreen (wallet, upgrade levels, act index,
## roster assignments), SawmillModule, KilnModule, AchievementModule, and the settings
## mirror maintained from EventBus.setting_changed emissions.

const SAVE_FILE_PATH: String = "user://save_slot_1.json"
const TMP_SUFFIX: String = ".tmp"
const BAK_SUFFIX: String = ".bak"
const SCHEMA_VERSION: int = 1
const AUTOSAVE_INTERVAL_S: float = 20.0

var save_file_path: String = SAVE_FILE_PATH
var main_screen: MainScreen
var sawmill_module: SawmillModule
var kiln_module: KilnModule
var achievement_module: AchievementModule

var _settings_state: Dictionary = {} # String (section) -> Dictionary (String key -> Variant)
var _autosave_timer: float = 0.0


func _init() -> void:
	module_id = &"save"


func _ready() -> void:
	is_active = true
	if is_instance_valid(EventBus):
		if not EventBus.setting_changed.is_connected(_on_setting_changed):
			EventBus.setting_changed.connect(_on_setting_changed)
		if not EventBus.breakthrough_reached.is_connected(_on_breakthrough_reached):
			EventBus.breakthrough_reached.connect(_on_breakthrough_reached)


func bind_dependencies(
	screen: MainScreen,
	sawmill: SawmillModule = null,
	kiln: KilnModule = null,
	achievements: AchievementModule = null
) -> void:
	main_screen = screen
	sawmill_module = sawmill
	kiln_module = kiln
	achievement_module = achievements


func _process(delta: float) -> void:
	if not is_active:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL_S:
		_autosave_timer = 0.0
		save_now()


func collect_state() -> Dictionary:
	var state: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
	}
	if main_screen != null:
		state["screen"] = main_screen.serialize_state()
		if main_screen.wallet != null:
			state["wallet"] = main_screen.wallet.serialize()
		var assignments: Dictionary = {}
		for sid in main_screen.roster_dispatcher.get_all_station_assignments().keys():
			assignments[String(sid)] = main_screen.roster_dispatcher.get_station_assigned(sid)
		state["roster"] = {"sawmill_assignments": assignments}
	if sawmill_module != null:
		state["sawmill"] = sawmill_module.serialize()
	if kiln_module != null:
		state["kiln"] = kiln_module.serialize()
	if achievement_module != null:
		state["achievements"] = achievement_module.serialize()
	state["settings"] = _settings_state.duplicate(true)
	return state


## Serializes the full game state and writes it atomically (tmp -> rotate .bak -> rename).
func save_now() -> bool:
	var data: Dictionary = collect_state()
	var json: String = JSON.stringify(data, "\t")
	var dir_path: String = "user://"
	var file_name: String = save_file_path
	if save_file_path.contains("/"):
		var slash_idx: int = save_file_path.rfind("/")
		dir_path = save_file_path.substr(0, slash_idx + 1)
		file_name = save_file_path.substr(slash_idx + 1)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return false
	var tmp_name: String = file_name + TMP_SUFFIX
	var tmp_file := FileAccess.open(dir_path.path_join(tmp_name), FileAccess.WRITE)
	if tmp_file == null:
		return false
	tmp_file.store_string(json)
	tmp_file.flush()
	tmp_file.close()
	if dir.file_exists(file_name):
		if dir.file_exists(file_name + BAK_SUFFIX):
			dir.remove(file_name + BAK_SUFFIX)
		dir.rename(file_name, file_name + BAK_SUFFIX)
	dir.rename(tmp_name, file_name)
	return true


## Loads the newest valid save (falling back to the .bak) and applies it to every
## bound system. Returns false when no valid save exists.
func load_and_apply() -> bool:
	var data: Dictionary = _migrate_legacy(_read_valid_save())
	if data.is_empty():
		return false
	apply_state(data)
	return true


func apply_state(data: Dictionary) -> void:
	var saved_at: float = float(data.get("saved_at_unix", 0.0))
	if saved_at > 0.0:
		# Zero offline progression: elapsed time is diagnostic only, nothing is granted.
		var elapsed_s: float = maxf(0.0, Time.get_unix_time_from_system() - saved_at)
		print("SaveModule: %.0f seconds elapsed since last save. Offline progression: none." % elapsed_s)

	var wallet_data: Dictionary = data.get("wallet", {})
	if main_screen != null and main_screen.wallet != null and not wallet_data.is_empty():
		main_screen.wallet.deserialize(wallet_data)

	if main_screen != null:
		var screen_data: Dictionary = data.get("screen", {})
		if not screen_data.is_empty():
			main_screen.restore_state(screen_data)
		var roster_data: Dictionary = data.get("roster", {})
		var assignments: Dictionary = roster_data.get("sawmill_assignments", {})
		main_screen.roster_dispatcher.restore_station_assignments(assignments)

	if sawmill_module != null:
		sawmill_module.deserialize(data.get("sawmill", {}))
	if kiln_module != null:
		kiln_module.deserialize(data.get("kiln", {}))
	if achievement_module != null:
		achievement_module.deserialize(data.get("achievements", {}))

	var settings: Dictionary = data.get("settings", {})
	for section in settings.keys():
		var inner: Variant = settings[section]
		if not (inner is Dictionary):
			continue
		for key in inner.keys():
			if is_instance_valid(EventBus):
				EventBus.setting_changed.emit(StringName(String(section)), StringName(String(key)), inner[key])


func _read_valid_save() -> Dictionary:
	var main_data: Dictionary = _read_json(save_file_path)
	if not main_data.is_empty():
		return main_data
	return _read_json(save_file_path + BAK_SUFFIX)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	if text.strip_edges() == "":
		return {}
	var json := JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK or not (json.data is Dictionary):
		return {}
	return json.data


func _migrate_legacy(data: Dictionary) -> Dictionary:
	# Schema v1 is the first shipped schema; legacy key names are mapped defensively.
	var migrated := data.duplicate(true)
	var legacy_map: Dictionary = {"wallet_data": "wallet", "upgrades": "screen"}
	for legacy_key in legacy_map.keys():
		if migrated.has(legacy_key) and not migrated.has(legacy_map[legacy_key]):
			migrated[legacy_map[legacy_key]] = migrated[legacy_key]
	return migrated


func _on_setting_changed(section: StringName, key: StringName, value: Variant) -> void:
	var section_key: String = String(section)
	if not _settings_state.has(section_key):
		_settings_state[section_key] = {}
	_settings_state[section_key][String(key)] = value


func _on_breakthrough_reached(_act_index: int) -> void:
	save_now()
