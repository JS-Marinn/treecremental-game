class_name ModalSawmillView
extends PanelContainer
## Dedicated Sawmill Loop Modal ("The Sawmill"), modeled after Image 2 ("The Mines"):
## Displays horizontal processing lanes for each tree species with walking Simple Lumberjack
## workers, +/- worker assignment per species lane, compact Slot/Gear upgrade buttons,
## Crew Quarters capacity expansion, and a bottom "Back" button.

signal closed()

const SAWMILL_LANE_SCENE: PackedScene = preload("res://scenes/ui/components/sawmill_lane_template.tscn")

var main_screen: MainScreen
var _lane_views: Dictionary = {} # StringName (species_id) -> SawmillLaneView

@onready var _title_label: Label = get_node_or_null("%ModalTitleLabel") as Label
@onready var _logs_balance_label: Label = get_node_or_null("%LogsBalanceLabel") as Label
@onready var _worker_pool_label: Label = get_node_or_null("%WorkerPoolLabel") as Label
@onready var _quarters_upg_btn: Button = get_node_or_null("%QuartersUpgradeButton") as Button
@onready var _lanes_list: VBoxContainer = get_node_or_null("%LanesList") as VBoxContainer
@onready var _back_btn: Button = get_node_or_null("%BackButton") as Button


func _ready() -> void:
	if _back_btn != null:
		_back_btn.pressed.connect(func() -> void:
			closed.emit()
			queue_free()
		)
	if _quarters_upg_btn != null:
		_quarters_upg_btn.pressed.connect(_on_quarters_upgrade_pressed)
	if is_instance_valid(EventBus):
		EventBus.resource_total_changed.connect(_on_resource_changed)
	_build_lanes()
	refresh_view()


func bind_main_screen(screen: MainScreen) -> void:
	main_screen = screen
	refresh_view()


func refresh_view() -> void:
	if main_screen == null or main_screen.wallet == null:
		return
	var wallet: WalletModule = main_screen.wallet
	var disp: RosterDispatcher = main_screen.roster_dispatcher
	var act_idx: int = main_screen.current_act_index

	if _title_label != null:
		_title_label.text = tr("KEY_MODULE_SAWMILL")
	if _logs_balance_label != null:
		_logs_balance_label.text = "%s: %s" % [
			tr("KEY_RESOURCE_PROCESSED_LOGS"),
			NumberFormatter.format(wallet.get_balance(&"processed_logs"))
		]

	var total_simple: int = maxi(
		main_screen.get_upgrade_level(&"hire_simple_lumberjack"),
		disp.get_total_hired(&"simple_lumberjack")
	)
	var used_in_mill: int = disp.get_total_sawmill_assigned()
	var max_mill_cap: int = disp.get_sawmill_max_capacity()
	var can_assign_more: bool = (used_in_mill < max_mill_cap) and (used_in_mill < total_simple)

	if _worker_pool_label != null:
		_worker_pool_label.text = "%s: %d / %d" % [
			tr("KEY_WORKER_SIMPLE_LUMBERJACK_NAME"),
			used_in_mill,
			mini(total_simple, max_mill_cap)
		]

	var q_upg: UpgradeDefinitionData = Balance.upgrade(&"mill_crew_quarters")
	if _quarters_upg_btn != null and q_upg != null:
		var q_lv: int = main_screen.get_upgrade_level(&"mill_crew_quarters")
		var q_cap: int = q_upg.get_act_cap(act_idx)
		var q_cost: float = q_upg.evaluate_cost(q_lv, 1)
		_quarters_upg_btn.text = "%s Lv.%d/%d (%s)" % [
			tr("KEY_UPG_MILL_CREW_QUARTERS_NAME"),
			q_lv,
			q_cap,
			"MAX" if q_lv >= q_cap else NumberFormatter.format(q_cost)
		]
		_quarters_upg_btn.disabled = (q_lv >= q_cap) or (not wallet.can_afford_upgrade(q_upg, q_lv, 1))

	var speed_upg: UpgradeDefinitionData = Balance.upgrade(&"mill_undershot_wheel")
	var speed_lv: int = main_screen.get_upgrade_level(&"mill_undershot_wheel")

	for sid in _lane_views.keys():
		var lane: SawmillLaneView = _lane_views[sid]
		var sp: SpeciesData = Balance.species(sid)
		var st_upg: UpgradeDefinitionData = Balance.upgrade(StringName("mill_%s" % String(sid)))
		var st_lv: int = main_screen.get_upgrade_level(StringName("mill_%s" % String(sid)))
		if lane != null and sp != null:
			lane.bind_lane(
				sp,
				disp.get_station_assigned(sid),
				disp.get_station_max_slots(sid),
				can_assign_more,
				st_upg,
				st_lv,
				speed_upg,
				speed_lv,
				act_idx,
				wallet
			)


func _build_lanes() -> void:
	_lane_views.clear()
	if _lanes_list == null:
		return
	for child in _lanes_list.get_children():
		_lanes_list.remove_child(child)
		child.queue_free()

	for sid in Balance.species_ids():
		var lane: SawmillLaneView = SAWMILL_LANE_SCENE.instantiate() as SawmillLaneView
		_lanes_list.add_child(lane)
		_lane_views[sid] = lane
		lane.worker_delta_requested.connect(_on_lane_worker_delta)
		lane.upgrade_purchase_requested.connect(_on_lane_upgrade_purchase)


func _on_lane_worker_delta(species_id: StringName, delta: int) -> void:
	if main_screen != null:
		main_screen._on_sawmill_assign_delta_requested(species_id, delta)
		refresh_view()


func _on_lane_upgrade_purchase(upgrade_id: StringName) -> void:
	if main_screen != null:
		main_screen._on_upgrade_purchase_requested(upgrade_id, 1)
		refresh_view()


func _on_quarters_upgrade_pressed() -> void:
	if main_screen != null:
		main_screen._on_upgrade_purchase_requested(&"mill_crew_quarters", 1)
		refresh_view()


func _on_resource_changed(_cid: StringName, _val: float) -> void:
	refresh_view()
