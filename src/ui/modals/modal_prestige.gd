class_name ModalPrestigeView
extends PanelContainer
## Heartwood Ascension 3-Ring Constellation modal bound via %UniqueNodeNames.
## Displays current Sap, Lifetime Sap multiplier, pending Sap gain, and the 16 sap_* upgrades
## grouped into Inner (6), Middle (5), and Outer (5) rings.

signal ascend_confirmed()
signal closed()

const UPGRADE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/upgrade_row_template.tscn")

const INNER_RING_IDS: Array[StringName] = [
	&"sap_heartwood_resonance_1",
	&"sap_pioneer_charter",
	&"sap_amber_distillation",
	&"sap_seasoned_joinery",
	&"sap_eternal_embers",
	&"sap_canopy_sanctuary_bond",
]

const MIDDLE_RING_IDS: Array[StringName] = [
	&"sap_heartwood_resonance_2",
	&"sap_guild_headquarters",
	&"sap_bulk_contracting",
	&"sap_cambium_overflow",
	&"sap_mycorrhizal_awakening",
]

const OUTER_RING_IDS: Array[StringName] = [
	&"sap_crucible_steel",
	&"sap_titan_feller",
	&"sap_golden_bough",
	&"sap_ancient_harmony",
	&"sap_world_tree_crown",
]

var wallet: WalletModule
var _sap_levels: Dictionary = {} # StringName -> int
var _row_views: Dictionary = {}  # StringName -> UpgradeRowView

@onready var _title_label: Label = get_node_or_null("%ModalTitleLabel") as Label
@onready var _sap_balance_label: Label = get_node_or_null("%SapBalanceLabel") as Label
@onready var _lifetime_sap_label: Label = get_node_or_null("%LifetimeSapLabel") as Label
@onready var _sap_mult_label: Label = get_node_or_null("%SapMultiplierLabel") as Label
@onready var _pending_sap_label: Label = get_node_or_null("%PendingSapLabel") as Label
@onready var _ascend_confirm_btn: Button = get_node_or_null("%AscendConfirmButton") as Button
@onready var _inner_ring_box: VBoxContainer = get_node_or_null("%InnerRingContainer") as VBoxContainer
@onready var _middle_ring_box: VBoxContainer = get_node_or_null("%MiddleRingContainer") as VBoxContainer
@onready var _outer_ring_box: VBoxContainer = get_node_or_null("%OuterRingContainer") as VBoxContainer
@onready var _close_btn: Button = get_node_or_null("%CloseButton") as Button


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(_on_close_pressed)
	if _ascend_confirm_btn != null:
		_ascend_confirm_btn.pressed.connect(_on_ascend_pressed)
	_build_constellation_rings()
	refresh_view()


func bind_wallet(external_wallet: WalletModule) -> void:
	wallet = external_wallet
	refresh_view()


func compute_pending_sap() -> float:
	if wallet == null or Balance.config == null or Balance.config.sap_gain == null:
		return 0.0
	return Balance.config.sap_gain.evaluate(wallet.run_coins_earned)


func refresh_view() -> void:
	if _title_label != null:
		_title_label.text = tr("KEY_MODULE_PRESTIGE")
	var cur_sap: float = wallet.get_balance(&"sap") if wallet != null else 0.0
	var life_sap: float = wallet.lifetime_sap if wallet != null else 0.0
	var mult: float = Balance.config.sap_multiplier.evaluate(life_sap) if (Balance.config != null and Balance.config.sap_multiplier != null) else 1.0
	var pending: float = compute_pending_sap()

	if _sap_balance_label != null:
		_sap_balance_label.text = "%s: %s" % [tr("KEY_RESOURCE_SAP"), NumberFormatter.format(cur_sap)]
	if _lifetime_sap_label != null:
		_lifetime_sap_label.text = "%s: %s" % [tr("KEY_UI_LIFETIME_SAP"), NumberFormatter.format(life_sap)]
	if _sap_mult_label != null:
		_sap_mult_label.text = "x%.2f" % mult
	if _pending_sap_label != null:
		_pending_sap_label.text = "+%s %s" % [NumberFormatter.format(pending), tr("KEY_RESOURCE_SAP")]
	if _ascend_confirm_btn != null:
		var min_sap: float = Balance.config.prestige_min_sap if Balance.config != null else 5.0
		_ascend_confirm_btn.disabled = pending < min_sap

	for uid in _row_views.keys():
		var row: UpgradeRowView = _row_views[uid]
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if row != null and upg != null:
			var lv: int = int(_sap_levels.get(uid, 0))
			row.bind_upgrade(upg, lv, 2, 1, wallet)


func _build_constellation_rings() -> void:
	_row_views.clear()
	_populate_ring(_inner_ring_box, INNER_RING_IDS)
	_populate_ring(_middle_ring_box, MIDDLE_RING_IDS)
	_populate_ring(_outer_ring_box, OUTER_RING_IDS)


func _populate_ring(container: VBoxContainer, ids: Array[StringName]) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for uid in ids:
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if upg == null:
			continue
		var row: UpgradeRowView = UPGRADE_ROW_SCENE.instantiate() as UpgradeRowView
		container.add_child(row)
		_row_views[uid] = row
		row.purchase_requested.connect(_on_sap_upgrade_purchased)


func _on_sap_upgrade_purchased(upgrade_id: StringName, count: int) -> void:
	var upg: UpgradeDefinitionData = Balance.upgrade(upgrade_id)
	if upg == null or wallet == null:
		return
	var cur_lv: int = int(_sap_levels.get(upgrade_id, 0))
	if cur_lv >= upg.max_level:
		return
	if wallet.spend_for_upgrade(upg, cur_lv, count):
		var new_lv: int = mini(upg.max_level, cur_lv + count)
		_sap_levels[upgrade_id] = new_lv
		StatAggregator.register_upgrade(upg, new_lv)
		EventBus.upgrade_purchased.emit(upgrade_id, new_lv)
		refresh_view()


func _on_ascend_pressed() -> void:
	var pending: float = compute_pending_sap()
	if wallet != null and pending > 0.0:
		wallet.add_currency(&"sap", pending, &"heartwood_ascension")
		var start_coins: float = StatAggregator.query(&"starting_coins", &"all", 0.0)
		wallet.reset_for_breakthrough(start_coins)
		StatAggregator.reset_for_breakthrough()
		EventBus.prestige_performed.emit(pending, wallet.get_balance(&"sap"))
	ascend_confirmed.emit()
	refresh_view()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
