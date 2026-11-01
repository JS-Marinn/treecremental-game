class_name SawmillLaneView
extends PanelContainer
## Single horizontal species lane inside The Sawmill modal (modeled after Image 2 "The Mines").
## Left/Center: Dark timber sawmill track with overhead lanterns, sawblade/chest on the left,
## timber stack on the right, species icon + live multiplier header, and animated Simple Lumberjacks
## walking back and forth along the lane.
## Right: Worker assignment counter (0 / N  +  -) on top, and two compact upgrade tiles (Lv/Max) below.

signal worker_delta_requested(species_id: StringName, delta: int)
signal upgrade_purchase_requested(upgrade_id: StringName)

var species_id: StringName = &""
var _assigned_workers: int = 0
var _max_slots: int = 1
var _walk_phase: float = 0.0
var _worker_sprites: Array[ColorRect] = []

@onready var _species_icon: TextureRect = get_node_or_null("%SpeciesIcon") as TextureRect
@onready var _lane_title_label: Label = get_node_or_null("%LaneTitleLabel") as Label
@onready var _workers_layer: Control = get_node_or_null("%LaneWorkersLayer") as Control
@onready var _assigned_label: Label = get_node_or_null("%AssignedCountLabel") as Label
@onready var _plus_btn: Button = get_node_or_null("%PlusWorkerButton") as Button
@onready var _minus_btn: Button = get_node_or_null("%MinusWorkerButton") as Button
@onready var _station_upg_btn: Button = get_node_or_null("%StationUpgradeButton") as Button
@onready var _station_lv_label: Label = get_node_or_null("%StationLevelLabel") as Label
@onready var _speed_upg_btn: Button = get_node_or_null("%SpeedUpgradeButton") as Button
@onready var _speed_lv_label: Label = get_node_or_null("%SpeedLevelLabel") as Label


func _ready() -> void:
	if _plus_btn != null:
		_plus_btn.pressed.connect(func() -> void: worker_delta_requested.emit(species_id, 1))
	if _minus_btn != null:
		_minus_btn.pressed.connect(func() -> void: worker_delta_requested.emit(species_id, -1))
	if _station_upg_btn != null:
		_station_upg_btn.pressed.connect(func() -> void:
			upgrade_purchase_requested.emit(StringName("mill_%s" % String(species_id)))
		)
	if _speed_upg_btn != null:
		_speed_upg_btn.pressed.connect(func() -> void:
			upgrade_purchase_requested.emit(&"mill_undershot_wheel")
		)


func _process(delta: float) -> void:
	if _assigned_workers <= 0 or _workers_layer == null:
		return
	_walk_phase = fmod(_walk_phase + delta * 0.85, 1.0)
	var track_w: float = maxf(120.0, _workers_layer.size.x - 56.0)
	for i in range(_worker_sprites.size()):
		var spr: ColorRect = _worker_sprites[i]
		if spr == null or not is_instance_valid(spr):
			continue
		var phase_i: float = fmod(_walk_phase + float(i) * 0.27, 1.0)
		var ping_pong: float = 1.0 - absf(phase_i * 2.0 - 1.0)
		spr.position = Vector2(28.0 + ping_pong * track_w, 26.0 + float(i % 2) * 8.0)


func bind_lane(
	sp: SpeciesData,
	assigned: int,
	max_slots: int,
	can_assign_more: bool,
	station_upg: UpgradeDefinitionData,
	station_lv: int,
	speed_upg: UpgradeDefinitionData,
	speed_lv: int,
	act_index: int,
	wallet: WalletModule
) -> void:
	if sp == null:
		return
	species_id = sp.id
	_assigned_workers = maxi(0, assigned)
	_max_slots = maxi(1, max_slots)

	if _species_icon != null:
		_species_icon.texture = _make_wood_badge(sp.id)

	var eff_mult: float = StatAggregator.query(&"species_coin_value", sp.id, 1.0)
	var sp_name: String = tr(sp.name_key())
	if _lane_title_label != null:
		_lane_title_label.text = "%s   x%s %s" % [
			sp_name,
			NumberFormatter.format(eff_mult),
			tr("KEY_RESOURCE_COINS")
		]

	if _assigned_label != null:
		_assigned_label.text = "%d / %d" % [_assigned_workers, _max_slots]
	if _plus_btn != null:
		_plus_btn.disabled = (not can_assign_more) or (_assigned_workers >= _max_slots)
	if _minus_btn != null:
		_minus_btn.disabled = (_assigned_workers <= 0)

	if station_upg != null:
		var st_cap: int = station_upg.get_act_cap(act_index)
		var st_cost: float = station_upg.evaluate_cost(station_lv, 1)
		if _station_lv_label != null:
			_station_lv_label.text = "%d/%d" % [station_lv, st_cap]
		if _station_upg_btn != null:
			_station_upg_btn.text = "Slot\n%s" % ("MAX" if station_lv >= st_cap else NumberFormatter.format(st_cost))
			_station_upg_btn.disabled = (station_lv >= st_cap) or (wallet != null and not wallet.can_afford_upgrade(station_upg, station_lv, 1))

	if speed_upg != null:
		var sp_cap: int = speed_upg.get_act_cap(act_index)
		var sp_cost: float = speed_upg.evaluate_cost(speed_lv, 1)
		if _speed_lv_label != null:
			_speed_lv_label.text = "%d/%d" % [speed_lv, sp_cap]
		if _speed_upg_btn != null:
			_speed_upg_btn.text = "Gear\n%s" % ("MAX" if speed_lv >= sp_cap else NumberFormatter.format(sp_cost))
			_speed_upg_btn.disabled = (speed_lv >= sp_cap) or (wallet != null and not wallet.can_afford_upgrade(speed_upg, speed_lv, 1))

	_sync_worker_sprites()


func _sync_worker_sprites() -> void:
	if _workers_layer == null:
		return
	var target_vis: int = mini(_assigned_workers, 6)
	while _worker_sprites.size() > target_vis:
		var last: ColorRect = _worker_sprites.pop_back()
		if last != null and is_instance_valid(last):
			last.queue_free()
	while _worker_sprites.size() < target_vis:
		var w := ColorRect.new()
		w.custom_minimum_size = Vector2(8, 12)
		w.size = Vector2(8, 12)
		w.color = Color(0.86, 0.24, 0.20, 1.0)
		_workers_layer.add_child(w)
		_worker_sprites.append(w)


func _make_wood_badge(sid: StringName) -> ImageTexture:
	var h: int = abs(sid.hash())
	var col := Color(
		0.45 + float(h % 40) / 100.0,
		0.32 + float((h >> 3) % 45) / 100.0,
		0.18 + float((h >> 5) % 35) / 100.0,
		1.0
	)
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(col.darkened(0.35))
	img.fill_rect(Rect2i(2, 2, 10, 10), col)
	img.fill_rect(Rect2i(4, 4, 6, 6), col.lightened(0.22))
	return ImageTexture.create_from_image(img)
