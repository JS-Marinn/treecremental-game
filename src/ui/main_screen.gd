class_name MainScreen
extends Control
## Right-Hand Docked main gameplay interface (640x360 split: 432x360 Left Compound + 208x360 Right Command Dock).
## Binds exclusively via %UniqueNodeNames so all Control containers in scenes/ui/main_screen.tscn
## can be moved, resized, or restyled in the Godot 2D Editor without breaking any script logic.

signal modal_requested(modal_id: StringName)

enum DockTab {
	TREES = 0,
	CREW = 1,
	MILL = 2,
	ROOTS = 3,
}

const UPGRADE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/upgrade_row_template.tscn")

var wallet: WalletModule
var roster_dispatcher: RosterDispatcher = RosterDispatcher.new()
var current_tab: DockTab = DockTab.TREES
var current_act_index: int = 0
var bulk_buy_mode: int = 1 # 1, 10, or -1 (MAX)

var _upgrade_levels: Dictionary = {}   # StringName -> int
var _row_views: Dictionary = {}        # StringName -> UpgradeRowView

@onready var _left_compound_col: Control = get_node_or_null("%LeftCompoundColumn") as Control
@onready var _top_resource_bar: Control = get_node_or_null("%TopResourceBar") as Control
@onready var _coins_label: Label = get_node_or_null("%CoinsLabel") as Label
@onready var _processed_logs_label: Label = get_node_or_null("%ProcessedLogsLabel") as Label
@onready var _charcoal_label: Label = get_node_or_null("%CharcoalLabel") as Label
@onready var _sap_label: Label = get_node_or_null("%SapLabel") as Label
@onready var _act_badge_label: Label = get_node_or_null("%ActBadgeLabel") as Label
@onready var _breakthrough_bar: ProgressBar = get_node_or_null("%BreakthroughProgressBar") as ProgressBar
@onready var _ascend_button: Button = get_node_or_null("%AscendButton") as Button

@onready var _compound_viewport: Control = get_node_or_null("%CompoundViewportContainer") as Control
@onready var _world_root: Node2D = get_node_or_null("%WorldRoot") as Node2D
@onready var _synergy_banner: Label = get_node_or_null("%SynergyBannerLabel") as Label
@onready var _right_command_dock: Control = get_node_or_null("%RightCommandDock") as Control

@onready var _tab_trees_btn: Button = get_node_or_null("%TabTreesButton") as Button
@onready var _tab_crew_btn: Button = get_node_or_null("%TabCrewButton") as Button
@onready var _tab_mill_btn: Button = get_node_or_null("%TabMillButton") as Button
@onready var _tab_roots_btn: Button = get_node_or_null("%TabRootsButton") as Button

@onready var _buy_x1_btn: Button = get_node_or_null("%BuyX1Button") as Button
@onready var _buy_x10_btn: Button = get_node_or_null("%BuyX10Button") as Button
@onready var _buy_max_btn: Button = get_node_or_null("%BuyMaxButton") as Button
@onready var _lumberjack_pool_label: Label = get_node_or_null("%SimpleLumberjackPoolLabel") as Label

@onready var _upgrade_list: VBoxContainer = get_node_or_null("%UpgradeList") as VBoxContainer
@onready var _bottom_access_bar: Control = get_node_or_null("%BottomLoopAccessBar") as Control
@onready var _prestige_modal_btn: Button = get_node_or_null("%PrestigeModalButton") as Button
@onready var _achievements_modal_btn: Button = get_node_or_null("%AchievementsModalButton") as Button
@onready var _settings_modal_btn: Button = get_node_or_null("%SettingsModalButton") as Button
@onready var _sawmill_loop_btn: Button = get_node_or_null("%SawmillLoopButton") as Button
@onready var _kilns_loop_btn: Button = get_node_or_null("%KilnsLoopButton") as Button
@onready var _ecology_loop_btn: Button = get_node_or_null("%EcologyLoopButton") as Button
@onready var _modal_host: Control = get_node_or_null("%ModalHost") as Control


func _ready() -> void:
	if wallet == null:
		wallet = WalletModule.new()
		add_child(wallet)
	_init_default_upgrade_levels()
	_connect_ui_signals()
	_connect_event_bus()
	apply_localization()
	select_tab(DockTab.TREES)
	refresh_top_bar()


func bind_wallet(external_wallet: WalletModule) -> void:
	if wallet != null and wallet != external_wallet and wallet.get_parent() == self:
		wallet.queue_free()
	wallet = external_wallet
	refresh_top_bar()
	refresh_upgrade_rows()


func get_world_root() -> Node2D:
	return _world_root


func has_valid_layout_containers() -> bool:
	return (
		_left_compound_col != null
		and _top_resource_bar != null
		and _compound_viewport != null
		and _bottom_access_bar != null
		and _right_command_dock != null
	)


func set_synergy_banner_text(text: String) -> void:
	if _synergy_banner != null:
		_synergy_banner.text = text


func get_upgrade_level(upgrade_id: StringName) -> int:
	if _upgrade_levels.has(upgrade_id):
		return int(_upgrade_levels[upgrade_id])
	var upg: UpgradeDefinitionData = Balance.upgrade(upgrade_id)
	return upg.initial_level if upg != null else 0


func serialize_state() -> Dictionary:
	var levels: Dictionary = {}
	for uid in _upgrade_levels.keys():
		levels[String(uid)] = int(_upgrade_levels[uid])
	return {
		"upgrade_levels": levels,
		"current_act_index": current_act_index,
		"bulk_buy_mode": bulk_buy_mode,
	}


func restore_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_act_index = clampi(int(data.get("current_act_index", 0)), 0, 2)
	set_bulk_buy_mode(int(data.get("bulk_buy_mode", 1)))
	var levels: Dictionary = data.get("upgrade_levels", {})
	for key in levels.keys():
		var uid := StringName(String(key))
		if Balance.upgrade(uid) != null:
			set_upgrade_level(uid, maxi(0, int(float(levels[key]))))
	refresh_top_bar()


func set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	_upgrade_levels[upgrade_id] = level
	var upg: UpgradeDefinitionData = Balance.upgrade(upgrade_id)
	if upg != null:
		StatAggregator.register_upgrade(upg, level)
	refresh_upgrade_rows()


func select_tab(tab: DockTab) -> void:
	current_tab = tab
	if _tab_trees_btn != null:
		_tab_trees_btn.button_pressed = (tab == DockTab.TREES)
	if _tab_crew_btn != null:
		_tab_crew_btn.button_pressed = (tab == DockTab.CREW)
	if _tab_mill_btn != null:
		_tab_mill_btn.button_pressed = (tab == DockTab.MILL)
	if _tab_roots_btn != null:
		_tab_roots_btn.button_pressed = (tab == DockTab.ROOTS)
	_rebuild_upgrade_list_for_tab(tab)


func set_bulk_buy_mode(mode: int) -> void:
	bulk_buy_mode = mode
	if _buy_x1_btn != null:
		_buy_x1_btn.button_pressed = (mode == 1)
	if _buy_x10_btn != null:
		_buy_x10_btn.button_pressed = (mode == 10)
	if _buy_max_btn != null:
		_buy_max_btn.button_pressed = (mode == -1)
	refresh_upgrade_rows()


func get_visible_upgrade_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for uid in _row_views.keys():
		ids.append(uid)
	return ids


func apply_localization() -> void:
	if _tab_trees_btn != null:
		_tab_trees_btn.text = tr("KEY_HUD_TAB_TREES")
	if _tab_crew_btn != null:
		_tab_crew_btn.text = tr("KEY_HUD_TAB_CREW")
	if _tab_mill_btn != null:
		_tab_mill_btn.text = tr("KEY_HUD_TAB_MILL")
	if _tab_roots_btn != null:
		_tab_roots_btn.text = tr("KEY_HUD_TAB_ROOTS")
	if _buy_x1_btn != null:
		_buy_x1_btn.text = tr("KEY_UI_BUY_X1")
	if _buy_x10_btn != null:
		_buy_x10_btn.text = tr("KEY_UI_BUY_X10")
	if _buy_max_btn != null:
		_buy_max_btn.text = tr("KEY_UI_BUY_MAX")
	if _prestige_modal_btn != null:
		_prestige_modal_btn.text = tr("KEY_UI_BTN_HEARTWOOD")
	if _achievements_modal_btn != null:
		_achievements_modal_btn.text = tr("KEY_UI_BTN_ACHIEVEMENTS")
	if _settings_modal_btn != null:
		_settings_modal_btn.text = tr("KEY_MENU_SETTINGS")
	if _ascend_button != null:
		_ascend_button.text = tr("KEY_UI_BTN_ASCEND")
	refresh_top_bar()
	refresh_upgrade_rows()


func refresh_top_bar() -> void:
	if wallet == null:
		return
	if _coins_label != null:
		_coins_label.text = "%s: %s" % [tr("KEY_RESOURCE_COINS"), NumberFormatter.format(wallet.get_balance(&"coins"))]
	if _processed_logs_label != null:
		_processed_logs_label.text = "%s: %s" % [tr("KEY_RESOURCE_LOGS_SHORT"), NumberFormatter.format(wallet.get_balance(&"processed_logs"))]
	if _charcoal_label != null:
		_charcoal_label.text = "%s: %s" % [tr("KEY_RESOURCE_CHARCOAL"), NumberFormatter.format(wallet.get_balance(&"charcoal"))]
	if _sap_label != null:
		_sap_label.text = "%s: %s" % [tr("KEY_RESOURCE_SAP"), NumberFormatter.format(wallet.get_balance(&"sap"))]
	if _act_badge_label != null:
		_act_badge_label.text = "Act %s" % ["I" if current_act_index == 0 else ("II" if current_act_index == 1 else "III")]
	if _breakthrough_bar != null and Balance.config != null:
		var gate: float = Balance.config.get_gate_coins(current_act_index)
		_breakthrough_bar.max_value = maxf(1.0, gate)
		_breakthrough_bar.value = clampf(wallet.run_coins_earned, 0.0, gate)
		if _ascend_button != null:
			_ascend_button.visible = wallet.run_coins_earned >= gate


func refresh_upgrade_rows() -> void:
	var total_simple: int = maxi(get_upgrade_level(&"hire_simple_lumberjack"), roster_dispatcher.get_total_hired(&"simple_lumberjack"))
	var used_in_mill: int = roster_dispatcher.get_total_sawmill_assigned()
	var max_mill_cap: int = roster_dispatcher.get_sawmill_max_capacity()
	var can_assign_more_global: bool = (used_in_mill < max_mill_cap) and (used_in_mill < total_simple)

	if _lumberjack_pool_label != null:
		_lumberjack_pool_label.visible = (current_tab == DockTab.MILL)
		_lumberjack_pool_label.text = "%d/%d" % [used_in_mill, mini(total_simple, max_mill_cap)]
	if _sawmill_loop_btn != null:
		_sawmill_loop_btn.text = "Sawmill (%d)" % used_in_mill if used_in_mill > 0 else "Sawmill"

	for uid in _row_views.keys():
		var row: UpgradeRowView = _row_views[uid]
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if row == null or upg == null:
			continue
		var lv: int = get_upgrade_level(uid)
		row.bind_upgrade(upg, lv, current_act_index, bulk_buy_mode, wallet)
		if upg.category == &"sawmill_per_species_value_and_slots":
			var sid: StringName = upg.target_entity_id
			var assigned: int = roster_dispatcher.get_station_assigned(sid)
			var slots: int = roster_dispatcher.get_station_max_slots(sid)
			row.set_sawmill_worker_assignment(assigned, slots, can_assign_more_global)


func show_modal(modal_control: Control) -> void:
	if _modal_host == null or modal_control == null:
		return
	for child in _modal_host.get_children():
		child.queue_free()
	_modal_host.add_child(modal_control)


func _init_default_upgrade_levels() -> void:
	for uid in Balance.upgrade_ids():
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if upg != null and upg.initial_level > 0:
			_upgrade_levels[uid] = upg.initial_level
			StatAggregator.register_upgrade(upg, upg.initial_level)


func reset_in_run_upgrades_for_breakthrough() -> void:
	var preserved: Dictionary = {}
	for uid in _upgrade_levels.keys():
		var upg: UpgradeDefinitionData = Balance.upgrade(uid)
		if upg != null and not upg.resets_on_breakthrough:
			preserved[uid] = int(_upgrade_levels[uid])
	_upgrade_levels = preserved
	_init_default_upgrade_levels()
	var bonus_simple: int = int(StatAggregator.query(&"starting_simple_lumberjacks", &"simple_lumberjack", 0.0))
	if bonus_simple > 0:
		var hire_simple: UpgradeDefinitionData = Balance.upgrade(&"hire_simple_lumberjack")
		if hire_simple != null:
			var start_lv: int = 1 + bonus_simple
			_upgrade_levels[&"hire_simple_lumberjack"] = start_lv
			StatAggregator.register_upgrade(hire_simple, start_lv)
	refresh_top_bar()
	refresh_upgrade_rows()


func _rebuild_upgrade_list_for_tab(tab: DockTab) -> void:
	_row_views.clear()
	if _upgrade_list == null:
		return
	for child in _upgrade_list.get_children():
		_upgrade_list.remove_child(child)
		child.queue_free()

	var categories: Array[StringName] = _categories_for_tab(tab)
	for cat in categories:
		var upgrades: Array[UpgradeDefinitionData] = Balance.upgrades_for_category(cat)
		for upg in upgrades:
			var row: UpgradeRowView = UPGRADE_ROW_SCENE.instantiate() as UpgradeRowView
			_upgrade_list.add_child(row)
			_row_views[upg.id] = row
			row.purchase_requested.connect(_on_upgrade_purchase_requested)
			row.worker_assign_delta_requested.connect(_on_sawmill_assign_delta_requested)
	refresh_upgrade_rows()


func _categories_for_tab(tab: DockTab) -> Array[StringName]:
	match tab:
		DockTab.TREES:
			return [&"species_propagation"]
		DockTab.CREW:
			return [&"worker_roster_and_gear", &"compound_and_synergy"]
		DockTab.MILL:
			return [&"sawmill_per_species_value_and_slots", &"sawmill_capacity_and_speed", &"charcoal_kilns"]
		DockTab.ROOTS:
			return [&"canopy_aviary", &"mycelium_network"]
		_:
			return [&"species_propagation"]


func _get_total_sawmill_assigned() -> int:
	return roster_dispatcher.get_total_sawmill_assigned()


func _on_upgrade_purchase_requested(upgrade_id: StringName, count: int) -> void:
	var upg: UpgradeDefinitionData = Balance.upgrade(upgrade_id)
	if upg == null or wallet == null or count <= 0:
		return
	var cur_lv: int = get_upgrade_level(upgrade_id)
	var cap: int = upg.get_act_cap(current_act_index)
	var actual_count: int = mini(count, maxi(0, cap - cur_lv))
	if actual_count <= 0:
		return
	if wallet.spend_for_upgrade(upg, cur_lv, actual_count):
		var new_lv: int = cur_lv + actual_count
		_upgrade_levels[upgrade_id] = new_lv
		StatAggregator.register_upgrade(upg, new_lv)
		EventBus.upgrade_purchased.emit(upgrade_id, new_lv)
		refresh_top_bar()
		refresh_upgrade_rows()


func _on_sawmill_assign_delta_requested(species_id: StringName, delta: int) -> void:
	if roster_dispatcher.try_adjust_station_assignment(species_id, delta, &"simple_lumberjack"):
		refresh_upgrade_rows()


func _connect_ui_signals() -> void:
	if _tab_trees_btn != null:
		_tab_trees_btn.pressed.connect(func() -> void: select_tab(DockTab.TREES))
	if _tab_crew_btn != null:
		_tab_crew_btn.pressed.connect(func() -> void: select_tab(DockTab.CREW))
	if _tab_mill_btn != null:
		_tab_mill_btn.pressed.connect(func() -> void: select_tab(DockTab.MILL))
	if _tab_roots_btn != null:
		_tab_roots_btn.pressed.connect(func() -> void: select_tab(DockTab.ROOTS))

	if _buy_x1_btn != null:
		_buy_x1_btn.pressed.connect(func() -> void: set_bulk_buy_mode(1))
	if _buy_x10_btn != null:
		_buy_x10_btn.pressed.connect(func() -> void: set_bulk_buy_mode(10))
	if _buy_max_btn != null:
		_buy_max_btn.pressed.connect(func() -> void: set_bulk_buy_mode(-1))

	if _prestige_modal_btn != null:
		_prestige_modal_btn.pressed.connect(func() -> void: modal_requested.emit(&"prestige"))
	if _achievements_modal_btn != null:
		_achievements_modal_btn.pressed.connect(func() -> void: modal_requested.emit(&"achievements"))
	if _settings_modal_btn != null:
		_settings_modal_btn.pressed.connect(func() -> void: modal_requested.emit(&"settings"))
	if _sawmill_loop_btn != null:
		_sawmill_loop_btn.pressed.connect(func() -> void: modal_requested.emit(&"sawmill"))
	if _kilns_loop_btn != null:
		_kilns_loop_btn.pressed.connect(func() -> void: modal_requested.emit(&"kilns"))
	if _ecology_loop_btn != null:
		_ecology_loop_btn.pressed.connect(func() -> void: modal_requested.emit(&"ecology"))
	if _ascend_button != null:
		_ascend_button.pressed.connect(func() -> void: modal_requested.emit(&"prestige"))


func _connect_event_bus() -> void:
	if not is_instance_valid(EventBus):
		return
	if not EventBus.resource_total_changed.is_connected(_on_resource_changed):
		EventBus.resource_total_changed.connect(_on_resource_changed)
	if not EventBus.notation_changed.is_connected(_on_notation_changed):
		EventBus.notation_changed.connect(_on_notation_changed)


func _on_resource_changed(_resource_id: StringName, _new_total: float) -> void:
	refresh_top_bar()
	refresh_upgrade_rows()


func _on_notation_changed() -> void:
	refresh_top_bar()
	refresh_upgrade_rows()
