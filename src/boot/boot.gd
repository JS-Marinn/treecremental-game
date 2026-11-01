extends Node
## Boot entry point (res://src/boot/boot.tscn).
## Initializes LocaleResolver, instantiates the Right-Hand Docked MainScreen, and wires overlay modals.

const MAIN_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/main_screen.tscn")
const MODAL_PRESTIGE_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_prestige.tscn")
const MODAL_ACHIEVEMENTS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_achievements.tscn")
const MODAL_SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/modals/modal_settings.tscn")

var main_screen: MainScreen


func _ready() -> void:
	LocaleResolver.ensure_loaded()
	main_screen = MAIN_SCREEN_SCENE.instantiate() as MainScreen
	add_child(main_screen)
	main_screen.modal_requested.connect(_on_modal_requested)


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
