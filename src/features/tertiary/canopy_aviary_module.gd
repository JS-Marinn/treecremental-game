class_name CanopyAviaryModule
extends GameModule
## Tertiary Isolated Loop 2: Canopy Aviary & Bird Sanctuary.
## A gentle, isolated background collector that grants passive multipliers
## without tangling into primary logging recipes.

signal bird_attracted(species_id: StringName, bonus_desc: String)

# Bird species and their passive benefits:
# - owl: +15% offline progress efficiency
# - woodpecker: +10% base log yield
# - waxwing: +10% sawmill plank conversion
# - falcon: +15% breakthrough progress speed
# - phoenix: +25% Sap multiplier power

const BIRD_CATALOG: Dictionary = {
	&"owl": {"name": "Screech Owl", "bonus": "offline_efficiency", "amount": 0.15, "cost_seed": 10},
	&"woodpecker": {"name": "Downy Woodpecker", "bonus": "log_yield", "amount": 0.10, "cost_seed": 25},
	&"waxwing": {"name": "Cedar Waxwing", "bonus": "sawmill_yield", "amount": 0.10, "cost_seed": 50},
	&"falcon": {"name": "Peregrine Falcon", "bonus": "breakthrough_speed", "amount": 0.15, "cost_seed": 100},
	&"phoenix": {"name": "Grove Phoenix", "bonus": "sap_boost", "amount": 0.25, "cost_seed": 250},
}

var birdseed: float = 0.0
var seed_rate_per_sec: float = 0.25 # 1 seed every 4 seconds passively
var roosted_birds: Dictionary = {}  # StringName -> int (count of each bird)


func _init() -> void:
	module_id = &"tertiary_aviary"


func setup(context: Node) -> void:
	super.setup(context)
	EventBus.command_requested.connect(_on_command_requested)


func _exit_tree() -> void:
	if EventBus.command_requested.is_connected(_on_command_requested):
		EventBus.command_requested.disconnect(_on_command_requested)


func tick(delta: float) -> void:
	birdseed += seed_rate_per_sec * delta


func offline_step(elapsed_seconds: float) -> void:
	birdseed += seed_rate_per_sec * elapsed_seconds * get_offline_mult()


func attract_bird(bird_id: StringName) -> bool:
	if not BIRD_CATALOG.has(bird_id):
		return false
	var info: Dictionary = BIRD_CATALOG[bird_id]
	var cost: float = float(info.get("cost_seed", 10.0))
	if birdseed < cost:
		return false
	birdseed -= cost
	roosted_birds[bird_id] = roosted_birds.get(bird_id, 0) + 1

	var desc: String = "%s attracted! (+%d%% %s)" % [
		info.get("name", "Bird"),
		int(float(info.get("amount", 0.0)) * 100.0),
		info.get("bonus", "bonus")
	]
	bird_attracted.emit(bird_id, desc)
	raise_event(&"bird_roosted", {"bird_id": bird_id, "count": roosted_birds[bird_id]})
	return true


func get_bonus_multiplier(bonus_key: String) -> float:
	var total_mult: float = 1.0
	for b_id in roosted_birds:
		var info: Dictionary = BIRD_CATALOG[b_id]
		if info.get("bonus") == bonus_key:
			var amt: float = float(info.get("amount", 0.0))
			var cnt: int = int(roosted_birds[b_id])
			total_mult += amt * cnt
	return total_mult


func get_offline_mult() -> float:
	return get_bonus_multiplier("offline_efficiency")


func get_log_yield_mult() -> float:
	return get_bonus_multiplier("log_yield")


func get_sawmill_yield_mult() -> float:
	return get_bonus_multiplier("sawmill_yield")


func get_breakthrough_speed_mult() -> float:
	return get_bonus_multiplier("breakthrough_speed")


func get_sap_boost_mult() -> float:
	return get_bonus_multiplier("sap_boost")


func _on_command_requested(command_name: StringName, payload: Dictionary) -> void:
	if command_name == &"attract_bird":
		var b_id: StringName = payload.get("bird_id", &"")
		attract_bird(b_id)


func serialize() -> Dictionary:
	return {
		"birdseed": birdseed,
		"roosted_birds": roosted_birds.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	birdseed = data.get("birdseed", 0.0)
	if data.has("roosted_birds") and data["roosted_birds"] is Dictionary:
		roosted_birds = data["roosted_birds"].duplicate()
