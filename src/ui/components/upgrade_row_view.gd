class_name UpgradeRowView
extends PanelContainer
## Reusable upgrade card prefab bound exclusively via %UniqueNodeNames.
## Designers can rearrange, resize, or reskin child nodes in scenes/ui/components/upgrade_row_template.tscn
## without breaking any code bindings.

signal purchase_requested(upgrade_id: StringName, count: int)
signal worker_assign_delta_requested(species_id: StringName, delta: int)

var upgrade_data: UpgradeDefinitionData
var current_level: int = 0
var current_act_index: int = 0
var bulk_buy_mode: int = 1 # 1, 10, or -1 (MAX)
var assigned_workers: int = 0
var max_station_slots: int = 0

@onready var _icon_rect: ColorRect = get_node_or_null("%IconRect") as ColorRect
@onready var _title_label: Label = get_node_or_null("%TitleLabel") as Label
@onready var _level_label: Label = get_node_or_null("%LevelLabel") as Label
@onready var _level_pips: ProgressBar = get_node_or_null("%LevelPips") as ProgressBar
@onready var _effect_label: Label = get_node_or_null("%EffectLabel") as Label
@onready var _cost_label: Label = get_node_or_null("%CostLabel") as Label
@onready var _buy_button: Button = get_node_or_null("%BuyButton") as Button
@onready var _worker_assign_row: Control = get_node_or_null("%WorkerAssignRow") as Control
@onready var _assign_minus_btn: Button = get_node_or_null("%AssignMinusButton") as Button
@onready var _assigned_workers_label: Label = get_node_or_null("%AssignedWorkersLabel") as Label
@onready var _assign_plus_btn: Button = get_node_or_null("%AssignPlusButton") as Button


func _ready() -> void:
	if _buy_button != null and not _buy_button.pressed.is_connected(_on_buy_pressed):
		_buy_button.pressed.connect(_on_buy_pressed)
	if _assign_minus_btn != null and not _assign_minus_btn.pressed.is_connected(_on_assign_minus):
		_assign_minus_btn.pressed.connect(_on_assign_minus)
	if _assign_plus_btn != null and not _assign_plus_btn.pressed.is_connected(_on_assign_plus):
		_assign_plus_btn.pressed.connect(_on_assign_plus)
	refresh_view()


func bind_upgrade(
	data: UpgradeDefinitionData,
	level: int,
	act_index: int = 0,
	buy_mode: int = 1,
	wallet: WalletModule = null
) -> void:
	upgrade_data = data
	current_level = level
	current_act_index = act_index
	bulk_buy_mode = buy_mode
	refresh_view(wallet)


func set_sawmill_worker_assignment(assigned: int, max_slots: int, can_add: bool) -> void:
	assigned_workers = assigned
	max_station_slots = max_slots
	if _worker_assign_row != null:
		var is_sawmill_station: bool = (
			upgrade_data != null
			and upgrade_data.category == &"sawmill_per_species_value_and_slots"
		)
		_worker_assign_row.visible = is_sawmill_station
		if is_sawmill_station:
			if _assigned_workers_label != null:
				_assigned_workers_label.text = "%d/%d" % [assigned_workers, max_station_slots]
			if _assign_minus_btn != null:
				_assign_minus_btn.disabled = assigned_workers <= 0
			if _assign_plus_btn != null:
				_assign_plus_btn.disabled = (not can_add) or assigned_workers >= max_station_slots


func compute_purchase_count(wallet: WalletModule = null) -> int:
	if upgrade_data == null:
		return 0
	var cap: int = upgrade_data.get_act_cap(current_act_index)
	var remaining: int = maxi(0, cap - current_level)
	if remaining <= 0:
		return 0
	if bulk_buy_mode == 1:
		return 1
	if bulk_buy_mode == 10:
		return mini(10, remaining)
	# MAX mode (-1)
	if wallet != null and upgrade_data.cost_curve != null:
		var budget: float = wallet.get_balance(upgrade_data.cost_currency_id)
		var affordable: int = upgrade_data.cost_curve.max_affordable(current_level, budget)
		return clampi(affordable, 1, remaining)
	return remaining


func refresh_view(wallet: WalletModule = null) -> void:
	if upgrade_data == null:
		return
	var cap: int = upgrade_data.get_act_cap(current_act_index)
	var is_capped: bool = current_level >= cap

	if _title_label != null:
		var raw_key: String = upgrade_data.name_key()
		var translated: String = tr(raw_key)
		_title_label.text = translated if translated != raw_key else _humanize_id(upgrade_data.id)

	if _level_label != null:
		_level_label.text = "Lv.%d/%d" % [current_level, cap]

	if _level_pips != null:
		_level_pips.max_value = float(maxi(1, cap))
		_level_pips.value = float(clampi(current_level, 0, cap))

	if _effect_label != null:
		_effect_label.text = _format_effect_preview()

	var buy_count: int = compute_purchase_count(wallet)
	var total_cost: float = upgrade_data.evaluate_cost(current_level, buy_count) if buy_count > 0 else 0.0

	if _cost_label != null:
		if is_capped:
			_cost_label.text = tr("KEY_UI_MAXED") if tr("KEY_UI_MAXED") != "KEY_UI_MAXED" else "MAX"
		else:
			var curr_label: String = _short_currency(upgrade_data.cost_currency_id)
			_cost_label.text = "%s %s" % [NumberFormatter.format(total_cost), curr_label]

	if _buy_button != null:
		if is_capped:
			_buy_button.text = "MAX"
			_buy_button.disabled = true
		else:
			_buy_button.text = "+%d" % buy_count
			if wallet != null:
				_buy_button.disabled = not wallet.can_afford_upgrade(upgrade_data, current_level, buy_count)
			else:
				_buy_button.disabled = false

	if _icon_rect != null:
		_icon_rect.color = _category_color(upgrade_data.category)

	if _worker_assign_row != null:
		var is_sawmill_station: bool = upgrade_data.category == &"sawmill_per_species_value_and_slots"
		_worker_assign_row.visible = is_sawmill_station


func _format_effect_preview() -> String:
	if upgrade_data == null or upgrade_data.modifiers.is_empty():
		return ""
	var mod: StatModifierData = upgrade_data.modifiers[0]
	if mod == null:
		return ""
	var next_lv: int = maxi(1, current_level)
	var val: float = mod.evaluate(next_lv)
	var label: String = _short_domain(mod.target_domain)
	match mod.operation:
		StatModifierData.Operation.ADD:
			return "+%s %s" % [NumberFormatter.format(val), label]
		StatModifierData.Operation.MUL_ADD:
			return "+%d%% %s" % [int(round(val * 100.0)), label]
		StatModifierData.Operation.MUL_COMPOUND:
			return "x%.2f %s" % [val, label]
		_:
			return label


func _short_domain(domain: StringName) -> String:
	match domain:
		&"species_spawn_weight":
			return "spawn weight"
		&"species_max_quantity":
			return "max trees"
		&"worker_roster_count":
			return "crew count"
		&"worker_chop_power":
			return "chop power"
		&"worker_attack_rate":
			return "swing speed"
		&"worker_move_speed":
			return "move speed"
		&"worker_crit_chance":
			return "crit chance"
		&"worker_crit_damage":
			return "crit damage"
		&"species_coin_value":
			return "tree value"
		&"global_coin_multiplier":
			return "all coin value"
		&"sawmill_work_speed":
			return "mill speed"
		&"sawmill_max_workers":
			return "mill capacity"
		&"kiln_cycle_speed":
			return "kiln speed"
		&"global_work_speed":
			return "global speed"
		_:
			return String(domain).replace("_", " ")


func _short_currency(cid: StringName) -> String:
	match cid:
		&"coins":
			return "Coins"
		&"processed_logs":
			return "Logs"
		&"charcoal":
			return "Charcoal"
		&"ash":
			return "Ash"
		&"birdseed":
			return "Seed"
		&"spores":
			return "Spores"
		&"sap":
			return "Sap"
		_:
			return String(cid).capitalize()


func _category_color(cat: StringName) -> Color:
	match cat:
		&"species_propagation":
			return Color(0.28, 0.58, 0.30, 1.0)
		&"worker_roster_and_gear":
			return Color(0.76, 0.52, 0.24, 1.0)
		&"compound_and_synergy":
			return Color(0.62, 0.44, 0.26, 1.0)
		&"sawmill_per_species_value_and_slots", &"sawmill_capacity_and_speed":
			return Color(0.32, 0.54, 0.68, 1.0)
		&"charcoal_kilns":
			return Color(0.78, 0.34, 0.22, 1.0)
		&"canopy_aviary":
			return Color(0.82, 0.68, 0.26, 1.0)
		&"mycelium_network":
			return Color(0.56, 0.38, 0.68, 1.0)
		&"heartwood_prestige":
			return Color(0.90, 0.72, 0.22, 1.0)
		_:
			return Color(0.45, 0.45, 0.45, 1.0)


func _humanize_id(raw_id: StringName) -> String:
	var s: String = String(raw_id)
	if s.begins_with("prop_"):
		return "Propagate: " + s.trim_prefix("prop_").replace("_", " ").capitalize()
	if s.begins_with("hire_"):
		return "Hire: " + s.trim_prefix("hire_").replace("_", " ").capitalize()
	if s.begins_with("gear_"):
		return "Gear: " + s.trim_prefix("gear_").replace("_", " ").capitalize()
	if s.begins_with("mill_") and upgrade_data != null and upgrade_data.category == &"sawmill_per_species_value_and_slots":
		return "Mill: " + s.trim_prefix("mill_").replace("_", " ").capitalize()
	for prefix in ["camp_", "mill_", "kiln_", "aviary_bird_", "aviary_", "myc_", "sap_"]:
		if s.begins_with(prefix):
			s = s.trim_prefix(prefix)
			break
	return s.replace("_", " ").capitalize()


func _on_buy_pressed() -> void:
	if upgrade_data == null:
		return
	var count: int = compute_purchase_count()
	if count > 0:
		purchase_requested.emit(upgrade_data.id, count)


func _on_assign_minus() -> void:
	if upgrade_data != null and upgrade_data.target_entity_id != &"":
		worker_assign_delta_requested.emit(upgrade_data.target_entity_id, -1)


func _on_assign_plus() -> void:
	if upgrade_data != null and upgrade_data.target_entity_id != &"":
		worker_assign_delta_requested.emit(upgrade_data.target_entity_id, 1)
