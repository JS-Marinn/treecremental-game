class_name MainMenuView
extends Control
## Editable title screen wireframe bound via %UniqueNodeNames.

signal play_requested()
signal settings_requested()
signal quit_requested()

@onready var _title_label: Label = get_node_or_null("%TitleLabel") as Label
@onready var _subtitle_label: Label = get_node_or_null("%SubtitleLabel") as Label
@onready var _play_btn: Button = get_node_or_null("%PlayButton") as Button
@onready var _settings_btn: Button = get_node_or_null("%SettingsButton") as Button
@onready var _quit_btn: Button = get_node_or_null("%QuitButton") as Button


func _ready() -> void:
	if _play_btn != null:
		_play_btn.pressed.connect(func() -> void: play_requested.emit())
	if _settings_btn != null:
		_settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	if _quit_btn != null:
		_quit_btn.pressed.connect(func() -> void: quit_requested.emit())
	apply_localization()


func apply_localization() -> void:
	if _title_label != null:
		_title_label.text = tr("KEY_GAME_TITLE")
	if _subtitle_label != null:
		_subtitle_label.text = tr("KEY_ACT_1_DESC")
	if _play_btn != null:
		_play_btn.text = tr("KEY_MENU_PLAY")
	if _settings_btn != null:
		_settings_btn.text = tr("KEY_MENU_SETTINGS")
	if _quit_btn != null:
		_quit_btn.text = tr("KEY_MENU_QUIT")
