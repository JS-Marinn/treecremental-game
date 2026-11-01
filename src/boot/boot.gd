extends Node
## Boot entry point (res://src/boot/boot.tscn).
## Initializes LocaleResolver, instantiates the Right-Hand Docked MainScreen, mounts the
## 3/4 LoggingClearing into %WorldRoot, instantiates SawmillModule (Loop 2) and KilnModule (Loop 3),
## and wires EventBus upgrade/worker/synergy/boiler signals.

const MAIN_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/main_screen.tscn")
const LOGGING_CLEARING_SCENE: PackedScene = preload("res://scenes/world/logging_clearing.tscn")
const MODAL_PRESTIGE_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_prestige.tscn")
const MODAL_ACHIEVEMENTS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_achievements.tscn")
const MODAL_SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_settings.tscn")

var main_screen: MainScreen
var logging_camp: LoggingCampModule
var sawmill_module: SawmillModule
var kiln_module: KilnModule


func _ready() -> void:
	LocaleResolver.ensure_loaded()
	main_screen = MAIN_SCREEN_SCENE.instantiate() as MainScreen
	add_child(main_screen)
	main_screen.modal_requested.connect(_on_modal_requested)

	sawmill_module = SawmillModule.new()
	sawmill_module.name = "SawmillModule"
	sawmill_module.bind_dependencies(main_screen.wallet, main_screen.roster_dispatcher)
	add_child(sawmill_module)

	kiln_module = KilnModule.new()
	kiln_module.name = "KilnModule"
	kiln_module.bind_wallet(main_screen.wallet)
	add_child(kiln_module)
	kiln_module.thermal_pressure_changed.connect(_on_thermal_pressure_changed)

	var world_root: Node2D = main_screen.get_world_root()
	if world_root != null:
		logging_camp = LOGGING_CLEARING_SCENE.instantiate() as LoggingCampModule
		logging_camp.bind_wallet(main_screen.wallet)
		world_root.add_child(logging_camp)
		if logging_camp.compound_landmark != null:
			logging_camp.compound_landmark.stoke_requested.connect(func() -> void: kiln_module.stoke_boiler())
			_sync_compound_landmark()

	if is_instance_valid(EventBus):
		EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
		EventBus.worker_assigned.connect(_on_worker_assigned)
		EventBus.synergy_triggered.connect(_on_synergy_triggered)


func _on_upgrade_purchased(_upgrade_id: StringName, _new_level: int) -> void:
	if logging_camp != null and main_screen != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())
		logging_camp.fill_clearing_to_capacity()
		_sync_compound_landmark()


func _on_worker_assigned(_worker_id: StringName, _loop_id: StringName, _target_id: StringName, _assigned_count: int) -> void:
	if logging_camp != null and main_screen != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())
		_sync_compound_landmark()


func _on_thermal_pressure_changed(_new_pressure: float, _speed_bonus: float) -> void:
	_sync_compound_landmark()


func _sync_compound_landmark() -> void:
	if logging_camp != null and logging_camp.compound_landmark != null and main_screen != null and kiln_module != null:
		logging_camp.compound_landmark.set_visual_state(
			main_screen._get_total_sawmill_assigned(),
			kiln_module.thermal_pressure
		)


func _on_synergy_triggered(_species_id: StringName, synergy_id: StringName, _duration_s: float) -> void:
	if main_screen != null:
		var key: String = "KEY_SYNERGY_%s_NAME" % String(synergy_id).to_upper()
		main_screen.set_synergy_banner_text(tr(key))


func _on_modal_requested(modal_id: StringName) -> void:
	if main_screen == null:
		return
	match modal_id:
		&"prestige":
			var modal: ModalPrestigeView = MODAL_PRESTIGE_SCENE.instantiate() as ModalPrestigeView
			modal.bind_wallet(main_screen.wallet)
			main_screen.show_modal(modal)
		&"achievements":
			var modal: ModalAchievementsView = MODAL_ACHIEVEMENTS_SCENE.instantiate() as ModalAchievementsView
			main_screen.show_modal(modal)
		&"settings":
			var modal: ModalSettingsView = MODAL_SETTINGS_SCENE.instantiate() as ModalSettingsView
			main_screen.show_modal(modal)
			modal.closed.connect(func() -> void: main_screen.apply_localization())
