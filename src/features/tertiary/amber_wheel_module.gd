class_name AmberWheelModule
extends GameModule
## Tertiary Isolated Loop 1: The Amber Well & Resin Wheel.
## Inspired by the slot machine in Gambler's Table.
## Operates on an isolated plane to provide passive buffs and lucky windfalls
## without intertwining with primary logging crafting trees.

signal spin_completed(outcome_id: StringName, reward_desc: String)

@export var token_recharge_time_s: float = 60.0
@export var max_tokens: int = 5

var available_tokens: int = 1
var _token_timer: float = 0.0

# Multipliers granted by amber buffs
var permanent_amber_mult: float = 1.0
var frenzy_timer: float = 0.0
var frenzy_mult: float = 1.0


func _init() -> void:
	module_id = &"tertiary_amber_wheel"


func setup(context: Node) -> void:
	super.setup(context)
	EventBus.command_requested.connect(_on_command_requested)


func _exit_tree() -> void:
	if EventBus.command_requested.is_connected(_on_command_requested):
		EventBus.command_requested.disconnect(_on_command_requested)


func tick(delta: float) -> void:
	# Accumulate tokens
	if available_tokens < max_tokens:
		_token_timer += delta
		if _token_timer >= token_recharge_time_s:
			_token_timer -= token_recharge_time_s
			available_tokens = mini(available_tokens + 1, max_tokens)
			raise_event(&"amber_token_gained", {"tokens": available_tokens})

	# Handle frenzy duration
	if frenzy_timer > 0.0:
		frenzy_timer = maxf(0.0, frenzy_timer - delta)
		if frenzy_timer <= 0.0:
			frenzy_mult = 1.0
			raise_event(&"amber_frenzy_ended", {})


func offline_step(elapsed_seconds: float) -> void:
	var total_time := _token_timer + elapsed_seconds
	var gained := int(floor(total_time / token_recharge_time_s))
	available_tokens = mini(available_tokens + gained, max_tokens)
	_token_timer = fmod(total_time, token_recharge_time_s)


## Spin the wheel using one available token.
func spin() -> bool:
	if available_tokens <= 0:
		return false
	available_tokens -= 1

	# Outcomes:
	# 0: Amber Infusion (+1% permanent passive multiplier, capped at +50%)
	# 1: Amber Frenzy (+25% harvest speed for 60s)
	# 2: Resin Windfall (instant harvest burst)
	# 3: Golden Amber Drop (banks 1 bonus Sap immediately)
	var roll := randf()
	var outcome: StringName = &""
	var desc: String = ""

	if roll < 0.40:
		outcome = &"amber_infusion"
		permanent_amber_mult = minf(1.50, permanent_amber_mult + 0.01)
		desc = "+1% Permanent Amber Multiplier!"
	elif roll < 0.70:
		outcome = &"amber_frenzy"
		frenzy_timer = 60.0
		frenzy_mult = 1.25
		desc = "Amber Frenzy! +25% Speed for 60s!"
	elif roll < 0.90:
		outcome = &"resin_windfall"
		desc = "Resin Windfall! Instant log burst!"
		raise_event(&"amber_windfall_awarded", {})
	else:
		outcome = &"golden_amber"
		desc = "Golden Amber Drop! +1 Instant Sap!"
		request_command(&"earn_resource", {"resource_id": &"sap", "amount": 1.0, "source_id": &"amber_wheel"})

	spin_completed.emit(outcome, desc)
	raise_event(&"amber_spin_completed", {"outcome": outcome, "tokens_left": available_tokens})
	return true


func get_effective_multiplier() -> float:
	return permanent_amber_mult * frenzy_mult


func _on_command_requested(command_name: StringName, _payload: Dictionary) -> void:
	if command_name == &"spin_amber_wheel":
		spin()


func serialize() -> Dictionary:
	return {
		"available_tokens": available_tokens,
		"token_timer": _token_timer,
		"permanent_amber_mult": permanent_amber_mult,
		"frenzy_timer": frenzy_timer,
		"frenzy_mult": frenzy_mult,
	}


func deserialize(data: Dictionary) -> void:
	available_tokens = data.get("available_tokens", 1)
	_token_timer = data.get("token_timer", 0.0)
	permanent_amber_mult = data.get("permanent_amber_mult", 1.0)
	frenzy_timer = data.get("frenzy_timer", 0.0)
	frenzy_mult = data.get("frenzy_mult", 1.0)
