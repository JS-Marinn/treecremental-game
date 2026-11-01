extends Node
## Boot entry point (res://src/boot/boot.tscn).
## Initializes LocaleResolver, instantiates the Right-Hand Docked MainScreen, mounts the
## 3/4 LoggingClearing into %WorldRoot, and wires EventBus upgrade/worker/synergy signals.

const MAIN_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/main_screen.tscn")
const LOGGING_CLEARING_SCENE: PackedScene = preload("res://scenes/world/logging_clearing.tscn")
const MODAL_PRESTIGE_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_prestige.tscn")
const MODAL_ACHIEVEMENTS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_achievements.tscn")
const MODAL_SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_settings.tscn")

var main_screen: MainScreen
var logging_camp: LoggingCampModule


func _ready() -> void:
	LocaleResolver.ensure_loaded()
	main_screen = MAIN_SCREEN_SCENE.instantiate() as MainScreen
	add_child(main_screen)
	main_screen.modal_requested.connect(_on_modal_requested)

	var world_root: Node2D = main_screen.get_world_root()
	if world_root != null:
		logging_camp = LOGGING_CLEARING_SCENE.instantiate() as LoggingCampModule
		logging_camp.bind_wallet(main_screen.wallet)
		world_root.add_child(logging_camp)

	if is_instance_valid(EventBus):
		EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
		EventBus.worker_assigned.connect(_on_worker_assigned)
		EventBus.synergy_triggered.connect(_on_synergy_triggered)


func _on_upgrade_purchased(_upgrade_id: StringName, _new_level: int) -> void:
	if logging_camp != null and main_screen != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())
		logging_camp.fill_clearing_to_capacity()


func _on_worker_assigned(_worker_id: StringName, _loop_id: StringName, _target_id: StringName, _assigned_count: int) -> void:
	if logging_camp != null and main_screen != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())


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
