class_name ModalSettingsView
extends PanelContainer
## Editable Settings modal wireframe bound via %UniqueNodeNames.
## Covers Display, 4-bus Audio sliders, Accessibility toggles, Number Notation, and Language (en, es_419, es_ES).

signal closed()

@onready var _title_label: Label = get_node_or_null("%ModalTitleLabel") as Label
@onready var _display_mode_option: OptionButton = get_node_or_null("%DisplayModeOption") as OptionButton
@onready var _vsync_check: CheckBox = get_node_or_null("%VsyncCheck") as CheckBox
@onready var _master_slider: HSlider = get_node_or_null("%MasterSlider") as HSlider
@onready var _music_slider: HSlider = get_node_or_null("%MusicSlider") as HSlider
@onready var _sfx_slider: HSlider = get_node_or_null("%SfxSlider") as HSlider
@onready var _ui_slider: HSlider = get_node_or_null("%UiSlider") as HSlider
@onready var _colorblind_option: OptionButton = get_node_or_null("%ColorblindOption") as OptionButton
@onready var _reduce_motion_check: CheckBox = get_node_or_null("%ReduceMotionCheck") as CheckBox
@onready var _screen_shake_check: CheckBox = get_node_or_null("%ScreenShakeCheck") as CheckBox
@onready var _notation_option: OptionButton = get_node_or_null("%NotationOption") as OptionButton
@onready var _locale_option: OptionButton = get_node_or_null("%LocaleOption") as OptionButton
@onready var _close_btn: Button = get_node_or_null("%CloseButton") as Button


func _ready() -> void:
	_populate_options()
	_connect_controls()
	apply_localization()


func apply_localization() -> void:
	if _title_label != null:
		_title_label.text = tr("KEY_MENU_SETTINGS")
	if _vsync_check != null:
		_vsync_check.text = tr("KEY_DISPLAY_VSYNC")
	if _reduce_motion_check != null:
		_reduce_motion_check.text = tr("KEY_ACCESSIBILITY_REDUCE_MOTION")
	if _screen_shake_check != null:
		_screen_shake_check.text = tr("KEY_ACCESSIBILITY_SCREEN_SHAKE")


func _populate_options() -> void:
	if _display_mode_option != null and _display_mode_option.item_count == 0:
		_display_mode_option.add_item("Windowed", 0)
		_display_mode_option.add_item("Borderless", 1)
		_display_mode_option.add_item("Fullscreen", 2)

	if _colorblind_option != null and _colorblind_option.item_count == 0:
		_colorblind_option.add_item("None", 0)
		_colorblind_option.add_item("Deuteranopia", 1)
		_colorblind_option.add_item("Protanopia", 2)
		_colorblind_option.add_item("Tritanopia", 3)

	if _notation_option != null and _notation_option.item_count == 0:
		_notation_option.add_item("Standard (1.5K)", NumberFormatter.Mode.STANDARD)
		_notation_option.add_item("Scientific (1.50e3)", NumberFormatter.Mode.SCIENTIFIC)
		_notation_option.add_item("Engineering (1.50e3)", NumberFormatter.Mode.ENGINEERING)

	if _locale_option != null and _locale_option.item_count == 0:
		_locale_option.add_item("English (en)", 0)
		_locale_option.add_item("Espanol LatAm (es_419)", 1)
		_locale_option.add_item("Espanol Espana (es_ES)", 2)


func _connect_controls() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(_on_close_pressed)
	if _master_slider != null:
		_master_slider.value_changed.connect(func(v: float) -> void: EventBus.setting_changed.emit(&"audio", &"master", v))
	if _music_slider != null:
		_music_slider.value_changed.connect(func(v: float) -> void: EventBus.setting_changed.emit(&"audio", &"music", v))
	if _sfx_slider != null:
		_sfx_slider.value_changed.connect(func(v: float) -> void: EventBus.setting_changed.emit(&"audio", &"sfx", v))
	if _ui_slider != null:
		_ui_slider.value_changed.connect(func(v: float) -> void: EventBus.setting_changed.emit(&"audio", &"ui", v))
	if _notation_option != null:
		_notation_option.item_selected.connect(func(idx: int) -> void:
			EventBus.setting_changed.emit(&"gameplay", &"notation", idx)
			EventBus.notation_changed.emit())
	if _locale_option != null:
		_locale_option.item_selected.connect(func(idx: int) -> void:
			var loc: String = LocaleResolver.SUPPORTED_LOCALES[clampi(idx, 0, LocaleResolver.SUPPORTED_LOCALES.size() - 1)]
			LocaleResolver.apply_locale(loc)
			apply_localization()
			EventBus.setting_changed.emit(&"gameplay", &"locale", loc))


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
