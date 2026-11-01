extends Node
## Boot entry point (res://src/boot/boot.tscn).
## Initializes LocaleResolver, instantiates the Right-Hand Docked MainScreen, mounts the
## 3/4 LoggingClearing into %WorldRoot, instantiates SawmillModule (Loop 2), KilnModule (Loop 3),
## AviaryModule (Loop 4), MyceliumModule (Loop 5), PrestigeModule, and the Milestone 6 meta
## systems (AudioModule, SettingsModule, AchievementModule, SaveModule), and wires the
## separated loop modals (The Sawmill, Charcoal Kilns, Canopy Aviary & Mycelium,
## Heartwood Prestige, Feats, and Settings).

const MAIN_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/main_screen.tscn")
const LOGGING_CLEARING_SCENE: PackedScene = preload("res://scenes/world/logging_clearing.tscn")
const MODAL_SAWMILL_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_sawmill.tscn")
const MODAL_KILNS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_kilns.tscn")
const MODAL_ECOLOGY_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_ecology.tscn")
const MODAL_PRESTIGE_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_prestige.tscn")
const MODAL_ACHIEVEMENTS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_achievements.tscn")
const MODAL_SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_settings.tscn")

var main_screen: MainScreen
var logging_camp: LoggingCampModule
var sawmill_module: SawmillModule
var kiln_module: KilnModule
var aviary_module: AviaryModule
var mycelium_module: MyceliumModule
var prestige_module: PrestigeModule
var audio_module: AudioModule
var settings_module: SettingsModule
var achievement_module: AchievementModule
var save_module: SaveModule


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

	aviary_module = AviaryModule.new()
	aviary_module.name = "AviaryModule"
	aviary_module.bind_wallet(main_screen.wallet)
	add_child(aviary_module)

	var world_root: Node2D = main_screen.get_world_root()
	if world_root != null:
		logging_camp = LOGGING_CLEARING_SCENE.instantiate() as LoggingCampModule
		logging_camp.bind_wallet(main_screen.wallet)
		world_root.add_child(logging_camp)

	mycelium_module = MyceliumModule.new()
	mycelium_module.name = "MyceliumModule"
	mycelium_module.bind_dependencies(main_screen.wallet, logging_camp)
	add_child(mycelium_module)

	prestige_module = PrestigeModule.new()
	prestige_module.name = "PrestigeModule"
	prestige_module.bind_dependencies(main_screen, sawmill_module, kiln_module, logging_camp)
	add_child(prestige_module)

	# Milestone 6 meta systems: audio buses first so SettingsModule can apply volumes.
	audio_module = AudioModule.new()
	audio_module.name = "AudioModule"
	add_child(audio_module)

	settings_module = SettingsModule.new()
	settings_module.name = "SettingsModule"
	add_child(settings_module)

	achievement_module = AchievementModule.new()
	achievement_module.name = "AchievementModule"
	add_child(achievement_module)
	achievement_module.sync_upgrade_levels_from_screen(main_screen)
	kiln_module.cycle_completed.connect(achievement_module.notify_kiln_cycle_completed)
	kiln_module.thermal_pressure_changed.connect(achievement_module.notify_thermal_pressure_changed)

	save_module = SaveModule.new()
	save_module.name = "SaveModule"
	save_module.bind_dependencies(main_screen, sawmill_module, kiln_module, achievement_module)
	add_child(save_module)

	if is_instance_valid(EventBus):
		EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
		EventBus.worker_assigned.connect(_on_worker_assigned)
		EventBus.synergy_triggered.connect(_on_synergy_triggered)
		EventBus.setting_changed.connect(_on_setting_changed)

	get_tree().auto_accept_quit = false

	save_module.load_and_apply()
	if prestige_module != null:
		prestige_module.sync_sap_resonance()
	if logging_camp != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())
		logging_camp.fill_clearing_to_capacity()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_module != null:
			save_module.save_now()
		get_tree().quit()


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


func _on_setting_changed(section: StringName, key: StringName, _value: Variant) -> void:
	if section == &"gameplay" and key == &"locale" and main_screen != null:
		main_screen.apply_localization()


func _on_modal_requested(modal_id: StringName) -> void:
	if main_screen == null:
		return
	match modal_id:
		&"sawmill":
			var modal: ModalSawmillView = MODAL_SAWMILL_SCENE.instantiate() as ModalSawmillView
			main_screen.show_modal(modal)
			modal.bind_main_screen(main_screen)
		&"kilns":
			var modal: ModalKilnsView = MODAL_KILNS_SCENE.instantiate() as ModalKilnsView
			main_screen.show_modal(modal)
			modal.bind_dependencies(main_screen, kiln_module)
		&"ecology":
			var modal: ModalEcologyView = MODAL_ECOLOGY_SCENE.instantiate() as ModalEcologyView
			main_screen.show_modal(modal)
			modal.bind_dependencies(main_screen, aviary_module, mycelium_module)
		&"prestige":
			var modal: ModalPrestigeView = MODAL_PRESTIGE_SCENE.instantiate() as ModalPrestigeView
			main_screen.show_modal(modal)
			modal.bind_dependencies(main_screen, prestige_module)
		&"achievements":
			var modal: ModalAchievementsView = MODAL_ACHIEVEMENTS_SCENE.instantiate() as ModalAchievementsView
			main_screen.show_modal(modal)
			modal.bind_achievements(achievement_module)
		&"settings":
			var modal: ModalSettingsView = MODAL_SETTINGS_SCENE.instantiate() as ModalSettingsView
			main_screen.show_modal(modal)
			modal.bind_settings(settings_module)
			modal.closed.connect(func() -> void: main_screen.apply_localization())
