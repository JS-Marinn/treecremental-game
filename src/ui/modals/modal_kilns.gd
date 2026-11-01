class_name ModalKilnsView
extends PanelContainer
## Dedicated Loop 3 Modal ("Charcoal Kilns & Steam Boiler"):
## Displays live Charcoal and Ash balances, active carbonization cycle progress bar,
## the interactive Steam Boiler Thermal Overclock gauge + Stoke button, the 8 kiln_*
## upgrades, and a bottom "Back" button.

signal closed()

const UPGRADE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/upgrade_row_template.tscn")

var main_screen: MainScreen
var kiln_module: KilnModule
var _row_views: Dictionary = {} # StringName -> UpgradeRowView

@onready var _charcoal_label: Label = get_node_or_null("%CharcoalBalanceLabel") as Label
@onready var _ash_label: Label = get_node_or_null("%AshBalanceLabel") as Label
@onready var _cycle_bar: ProgressBar = get_node_or_null("%CycleProgressBar") as ProgressBar
@onready var _pressure_bar: ProgressBar = get_node_or_null("%BoilerPressureBar") as ProgressBar
@onready var _overclock_label: Label = get_node_or_null("%OverclockBonusLabel") as Label
@onready var _stoke_btn: Button = get_node_or_null("%StokeBoilerButton") as Button
@onready var _upgrades_list: VBoxContainer = get_node_or_null("%KilnUpgradesList") as VBoxContainer
@onready var _back_btn: Button = get_node_or_null("%BackButton") as Button


func _ready() -> void:
	if _back_btn != null:
		_back_btn.pressed.connect(func() -> void:
			closed.emit()
			queue_free()
		)
	if _stoke_btn != null:
		_stoke_btn.pressed.connect(_on_stoke_pressed)
	if is_instance_valid(EventBus):
		EventBus.resource_total_changed.connect(_on_resource_changed)
	_build_upgrade_rows()
	refresh_view()


func _process(_delta: float) -> void:
	if kiln_module != null:
		if _cycle_bar != null:
			_cycle_bar.value = clampf(kiln_module.cycle_progress * 100.0, 0.0, 100.0)
		if _pressure_bar != null:
			_pressure_bar.value = clampf(kiln_module.thermal_pressure * 100.0, 0.0, 100.0)
		if _overclock_label != null:
			_overclock_label.text = "+%d%% Global Speed" % int(roundf(kiln_module.get_overclock_speed_bonus() * 100.0))


func bind_dependencies(screen: MainScreen, kiln: KilnModule) -> void:
	main_screen = screen
	kiln_module = kiln
	refresh_view()


func refresh_view() -> void:
	if main_screen == null or main_screen.wallet == null:
		return
	var wallet: WalletModule = main_screen.wallet
	if _charcoal_label != null:
		_charcoal_label.text = "%s: %s" % [tr("KEY_RESOURCE_CHARCOAL"), NumberFormatter.format(wallet.get_balance(&"charcoal"))]
	if _ash_label != null:
		_ash_label.text = "%s: %s" % [tr("KEY_RESOURCE_ASH"), NumberFormatter.format(wallet.get_balance(&"ash"))]

	for uid in _row_views.keys():
		var row: UpgradeRowView = _row_views[uid]
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if row != null and upg != null:
			row.bind_upgrade(
				upg,
				main_screen.get_upgrade_level(uid),
				main_screen.current_act_index,
				main_screen.bulk_buy_mode,
				wallet
			)


func _build_upgrade_rows() -> void:
	_row_views.clear()
	if _upgrades_list == null:
		return
	for child in _upgrades_list.get_children():
		_upgrades_list.remove_child(child)
		child.queue_free()

	for upg in Balance.upgrades_for_category(&"charcoal_kilns"):
		var row: UpgradeRowView = UPGRADE_ROW_SCENE.instantiate() as UpgradeRowView
		_upgrades_list.add_child(row)
		_row_views[upg.id] = row
		row.purchase_requested.connect(_on_purchase_requested)


func _on_purchase_requested(upgrade_id: StringName, count: int) -> void:
	if main_screen != null:
		main_screen._on_upgrade_purchase_requested(upgrade_id, count)
		refresh_view()


func _on_stoke_pressed() -> void:
	if kiln_module != null:
		kiln_module.stoke_boiler(0.35)


func _on_resource_changed(_cid: StringName, _val: float) -> void:
	refresh_view()
