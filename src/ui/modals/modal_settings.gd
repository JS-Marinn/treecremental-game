class_name ModalSettingsView
extends PanelContainer
## Editable Settings modal wireframe bound via %UniqueNodeNames.
## Covers Display, 4-bus Audio sliders, Accessibility toggles, Number Notation, and
## Language (en, es_419, es_ES). All controls dispatch EventBus.setting_changed and
## initialize their values from SettingsModule via bind_settings.

signal closed()

var settings_module: SettingsModule

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


## Initializes every control from the live SettingsModule state.
func bind_settings(module: SettingsModule) -> void:
	settings_module = module
	if module == null:
		return
	if _master_slider != null:
		_master_slider.value = float(module.get_setting(&"audio", &"master"))
	if _music_slider != null:
		_music_slider.value = float(module.get_setting(&"audio", &"music"))
	if _sfx_slider != null:
		_sfx_slider.value = float(module.get_setting(&"audio", &"sfx"))
	if _ui_slider != null:
		_ui_slider.value = float(module.get_setting(&"audio", &"ui"))
	if _display_mode_option != null:
		_display_mode_option.select(clampi(int(module.get_setting(&"display", &"window_mode")), 0, 2))
	if _vsync_check != null:
		_vsync_check.button_pressed = bool(module.get_setting(&"display", &"vsync"))
	if _colorblind_option != null:
		_colorblind_option.select(clampi(int(module.get_setting(&"accessibility", &"colorblind")), 0, 3))
	if _reduce_motion_check != null:
		_reduce_motion_check.button_pressed = bool(module.get_setting(&"accessibility", &"reduce_motion"))
	if _screen_shake_check != null:
		_screen_shake_check.button_pressed = bool(module.get_setting(&"accessibility", &"screen_shake"))
	if _notation_option != null:
		var notation_idx: int = 0
		match NumberFormatter.active_mode:
			NumberFormatter.Mode.SCIENTIFIC:
				notation_idx = 1
			NumberFormatter.Mode.ENGINEERING:
				notation_idx = 2
		_notation_option.select(notation_idx)
	if _locale_option != null:
		var current_locale: String = LocaleResolver.sanitize_locale(TranslationServer.get_locale())
		_locale_option.select(clampi(LocaleResolver.SUPPORTED_LOCALES.find(current_locale), 0, 2))


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
		_display_mode_option.add_item(tr("KEY_DISPLAY_WINDOWED"), 0)
		_display_mode_option.add_item(tr("KEY_DISPLAY_BORDERLESS"), 1)
		_display_mode_option.add_item(tr("KEY_DISPLAY_FULLSCREEN"), 2)

	if _colorblind_option != null and _colorblind_option.item_count == 0:
		_colorblind_option.add_item("None", 0)
		_colorblind_option.add_item("Deuteranopia", 1)
		_colorblind_option.add_item("Protanopia", 2)
		_colorblind_option.add_item("Tritanopia", 3)

	if _notation_option != null and _notation_option.item_count == 0:
		_notation_option.add_item(tr("KEY_NOTATION_STANDARD"), NumberFormatter.Mode.STANDARD)
		_notation_option.add_item(tr("KEY_NOTATION_SCIENTIFIC"), NumberFormatter.Mode.SCIENTIFIC)
		_notation_option.add_item(tr("KEY_NOTATION_ENGINEERING"), NumberFormatter.Mode.ENGINEERING)

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
	if _display_mode_option != null:
		_display_mode_option.item_selected.connect(func(idx: int) -> void: EventBus.setting_changed.emit(&"display", &"window_mode", idx))
	if _vsync_check != null:
		_vsync_check.toggled.connect(func(on: bool) -> void: EventBus.setting_changed.emit(&"display", &"vsync", on))
	if _colorblind_option != null:
		_colorblind_option.item_selected.connect(func(idx: int) -> void: EventBus.setting_changed.emit(&"accessibility", &"colorblind", idx))
	if _reduce_motion_check != null:
		_reduce_motion_check.toggled.connect(func(on: bool) -> void: EventBus.setting_changed.emit(&"accessibility", &"reduce_motion", on))
	if _screen_shake_check != null:
		_screen_shake_check.toggled.connect(func(on: bool) -> void: EventBus.setting_changed.emit(&"accessibility", &"screen_shake", on))
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
