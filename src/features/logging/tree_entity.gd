class_name TreeEntity
extends Node2D
## Live tree instance in the 3/4 clearing with Durability (HP), Bark Hardness mitigation,
## Old-Growth Maturity Rank (m in 0..4), 30% Chip Yield on hit, and 70% Timberfall Jackpot on fell.
## Renders custom Aseprite textures assigned to %SpriteSlot, or a crisp species-coded pixel silhouette.

signal chip_yield_awarded(tree: TreeEntity, coins: float)
signal tree_felled(tree: TreeEntity, jackpot_coins: float, attacker_id: StringName, synergy_weight: float)

var species_data: SpeciesData
var species_id: StringName = &"pine"
var maturity_rank: int = 0
var max_hp: float = 20.0
var current_hp: float = 20.0
var bark_hardness: int = 0
var clearance_radius: float = 12.0
var kerf_vulnerability_bonus: float = 0.0
var is_felled: bool = false

var _shake_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

@onready var _visual_root: Node2D = get_node_or_null("%VisualRoot") as Node2D
@onready var _sprite_slot: Sprite2D = get_node_or_null("%SpriteSlot") as Sprite2D
@onready var _hp_bar: ProgressBar = get_node_or_null("%HpBar") as ProgressBar
@onready var _rank_badge: Label = get_node_or_null("%RankBadgeLabel") as Label


func setup_tree(data: SpeciesData, rank: int = 0) -> void:
	species_data = data
	if data == null:
		return
	species_id = data.id
	maturity_rank = clampi(rank, 0, 4)
	var hp_base: float = Balance.config.maturity_hp_base if Balance.config != null else 4.0
	max_hp = maxf(1.0, data.base_hp * pow(hp_base, float(maturity_rank)))
	current_hp = max_hp
	bark_hardness = data.bark_hardness
	clearance_radius = data.trunk_clearance_radius + float(maturity_rank) * 1.5
	kerf_vulnerability_bonus = 0.0
	is_felled = false
	if _sprite_slot != null:
		var drop_in_texture: Texture2D = AssetResolver.tree_sprite(species_id, maturity_rank)
		if drop_in_texture != null:
			_sprite_slot.texture = drop_in_texture
	_update_visuals()
	queue_redraw()


func compute_effective_coin_value() -> float:
	if species_data == null:
		return 1.0
	var yield_base: float = Balance.config.maturity_yield_base if Balance.config != null else 4.2
	var species_val: float = StatAggregator.query(&"species_coin_value", species_id, species_data.base_coin_value)
	var global_mult: float = StatAggregator.query(&"global_coin_multiplier", &"all", 1.0)
	var sap_mult: float = 1.0
	if Balance.config != null and Balance.config.sap_multiplier != null:
		var life_sap: float = StatAggregator.query(&"lifetime_sap_total", &"all", 0.0)
		sap_mult = Balance.config.sap_multiplier.evaluate(life_sap)
	return species_val * global_mult * sap_mult * pow(yield_base, float(maturity_rank))


func apply_kerf_shred(amount: float) -> void:
	if amount <= 0.0:
		return
	kerf_vulnerability_bonus = minf(0.50, kerf_vulnerability_bonus + amount)


func apply_chop_damage(
	raw_damage: float,
	effective_penetration: int = 0,
	ignore_all_hardness: bool = false,
	attacker_id: StringName = &"simple_lumberjack",
	synergy_weight: float = 1.0
) -> Dictionary:
	if is_felled or raw_damage <= 0.0:
		return {"damage_dealt": 0.0, "chip_coins": 0.0, "jackpot_coins": 0.0, "felled": false}

	var delta_hardness: int = 0 if ignore_all_hardness else maxi(0, bark_hardness - effective_penetration)
	var mitigation: float = pow(0.80, float(delta_hardness))
	var final_damage: float = raw_damage * mitigation * (1.0 + kerf_vulnerability_bonus)
	var actual_hp_lost: float = minf(current_hp, final_damage)
	current_hp = maxf(0.0, current_hp - actual_hp_lost)

	var total_val: float = compute_effective_coin_value()
	var chip_frac: float = Balance.config.chip_yield_fraction if Balance.config != null else 0.30
	var chip_bonus: float = StatAggregator.query(&"chip_yield_bonus", &"all", 1.0)
	var hp_fraction_removed: float = actual_hp_lost / maxf(1.0, max_hp)
	var chip_coins: float = total_val * chip_frac * chip_bonus * hp_fraction_removed

	_shake_timer = 0.10
	_update_visuals()

	if chip_coins > 0.0:
		chip_yield_awarded.emit(self, chip_coins)

	var jackpot_coins: float = 0.0
	if current_hp <= 0.0001:
		is_felled = true
		var timber_frac: float = Balance.config.timberfall_yield_fraction if Balance.config != null else 0.70
		var jackpot_bonus: float = StatAggregator.query(&"timberfall_jackpot_bonus", &"all", 1.0)
		jackpot_coins = total_val * timber_frac * jackpot_bonus
		tree_felled.emit(self, jackpot_coins, attacker_id, synergy_weight)

	return {
		"damage_dealt": actual_hp_lost,
		"chip_coins": chip_coins,
		"jackpot_coins": jackpot_coins,
		"felled": is_felled,
	}


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
		_shake_offset = Vector2(2.0 if int(_shake_timer * 60.0) % 2 == 0 else -2.0, 0.0)
		if _visual_root != null:
			_visual_root.position = _shake_offset
		queue_redraw()
	elif _shake_offset != Vector2.ZERO:
		_shake_offset = Vector2.ZERO
		if _visual_root != null:
			_visual_root.position = Vector2.ZERO
		queue_redraw()


func _update_visuals() -> void:
	if _hp_bar != null:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current_hp
		_hp_bar.visible = current_hp < max_hp and not is_felled
	if _rank_badge != null:
		_rank_badge.visible = maturity_rank > 0
		_rank_badge.text = "R%d" % maturity_rank


func _draw() -> void:
	if _sprite_slot != null and _sprite_slot.texture != null:
		return
	var scale_mult: float = 1.0 + float(maturity_rank) * 0.14
	var ox: float = _shake_offset.x
	# Ground shadow ellipse
	draw_rect(Rect2(ox - 9.0 * scale_mult, -2.0, 18.0 * scale_mult, 4.0), Color(0.06, 0.10, 0.05, 0.55))
	# Trunk
	var trunk_col: Color = _trunk_color(species_id)
	var trunk_w: float = roundf(6.0 * scale_mult)
	var trunk_h: float = roundf(12.0 * scale_mult)
	draw_rect(Rect2(ox - trunk_w * 0.5, -trunk_h, trunk_w, trunk_h), trunk_col)
	# Layered pixel-art canopy
	var canopy_base: Color = _canopy_color(species_id)
	var canopy_hi: Color = canopy_base.lightened(0.18)
	var canopy_sh: Color = canopy_base.darkened(0.20)
	var cw: float = roundf(20.0 * scale_mult)
	var ch: float = roundf(16.0 * scale_mult)
	draw_rect(Rect2(ox - cw * 0.5, -trunk_h - ch + 2.0, cw, ch), canopy_sh)
	draw_rect(Rect2(ox - cw * 0.45, -trunk_h - ch, cw * 0.9, ch * 0.8), canopy_base)
	draw_rect(Rect2(ox - cw * 0.30, -trunk_h - ch - 3.0, cw * 0.6, ch * 0.5), canopy_hi)


func _trunk_color(sid: StringName) -> Color:
	match sid:
		&"birch":
			return Color(0.88, 0.85, 0.78, 1.0)
		&"giant_sequoia":
			return Color(0.58, 0.24, 0.16, 1.0)
		&"baobab":
			return Color(0.54, 0.42, 0.30, 1.0)
		_:
			return Color(0.42, 0.27, 0.16, 1.0)


func _canopy_color(sid: StringName) -> Color:
	match sid:
		&"pine":
			return Color(0.18, 0.46, 0.24, 1.0)
		&"birch":
			return Color(0.52, 0.72, 0.26, 1.0)
		&"oak":
			return Color(0.24, 0.56, 0.22, 1.0)
		&"sakura":
			return Color(0.94, 0.58, 0.74, 1.0)
		&"canadian_maple":
			return Color(0.88, 0.34, 0.16, 1.0)
		&"fir":
			return Color(0.16, 0.50, 0.46, 1.0)
		&"baobab":
			return Color(0.46, 0.62, 0.22, 1.0)
		&"socotra_dragon_tree":
			return Color(0.68, 0.22, 0.26, 1.0)
		&"giant_sequoia":
			return Color(0.14, 0.42, 0.20, 1.0)
		_:
			return Color(0.24, 0.54, 0.24, 1.0)
