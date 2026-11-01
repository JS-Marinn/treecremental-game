class_name ModalEcologyView
extends PanelContainer
## Dedicated Tertiary Loops Modal ("Canopy Aviary & Mycelium Network"):
## Displays live Birdseed & Spores balances, active generation rates, the 16
## aviary_* and myc_* upgrades (which persist across Breakthroughs), and a bottom "Back" button.

signal closed()

const UPGRADE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/upgrade_row_template.tscn")

var main_screen: MainScreen
var aviary_module: AviaryModule
var mycelium_module: MyceliumModule
var _row_views: Dictionary = {} # StringName -> UpgradeRowView

@onready var _birdseed_label: Label = get_node_or_null("%BirdseedBalanceLabel") as Label
@onready var _spores_label: Label = get_node_or_null("%SporesBalanceLabel") as Label
@onready var _upgrades_list: VBoxContainer = get_node_or_null("%EcologyUpgradesList") as VBoxContainer
@onready var _back_btn: Button = get_node_or_null("%BackButton") as Button


func _ready() -> void:
	if _back_btn != null:
		_back_btn.pressed.connect(func() -> void:
			closed.emit()
			queue_free()
		)
	if is_instance_valid(EventBus):
		EventBus.resource_total_changed.connect(_on_resource_changed)
	_build_upgrade_rows()
	refresh_view()


func bind_dependencies(screen: MainScreen, aviary: AviaryModule = null, mycelium: MyceliumModule = null) -> void:
	main_screen = screen
	aviary_module = aviary
	mycelium_module = mycelium
	refresh_view()


func refresh_view() -> void:
	if main_screen == null or main_screen.wallet == null:
		return
	var wallet: WalletModule = main_screen.wallet
	if _birdseed_label != null:
		_birdseed_label.text = "%s: %s" % [tr("KEY_RESOURCE_BIRDSEED"), NumberFormatter.format(wallet.get_balance(&"birdseed"))]
	if _spores_label != null:
		_spores_label.text = "%s: %s" % [tr("KEY_RESOURCE_SPORES"), NumberFormatter.format(wallet.get_balance(&"spores"))]

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

	for cat in [&"canopy_aviary", &"mycelium_network"]:
		for upg in Balance.upgrades_for_category(cat):
			var row: UpgradeRowView = UPGRADE_ROW_SCENE.instantiate() as UpgradeRowView
			_upgrades_list.add_child(row)
			_row_views[upg.id] = row
			row.purchase_requested.connect(_on_purchase_requested)


func _on_purchase_requested(upgrade_id: StringName, count: int) -> void:
	if main_screen != null:
		main_screen._on_upgrade_purchase_requested(upgrade_id, count)
		refresh_view()


func _on_resource_changed(_cid: StringName, _val: float) -> void:
	refresh_view()
