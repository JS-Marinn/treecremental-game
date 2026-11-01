class_name AudioModule
extends GameModule
## Audio bus plumbing for the drop-in asset pipeline.
## This module never generates or synthesizes audio content: sound effects and music
## are real asset files loaded through AssetResolver naming conventions. When an asset
## has not been delivered yet, the event simply produces no sound.

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const SFX_COOLDOWN_MS: int = 50

var _last_sfx_ms: Dictionary = {} # StringName -> int
var _music_player: AudioStreamPlayer


func _init() -> void:
	module_id = &"audio"


func _ready() -> void:
	is_active = true
	_ensure_buses()
	_connect_event_bus()


## Creates the Music, SFX, and UI buses under Master when they do not exist yet.
func _ensure_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var bus_idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, bus_name)
		AudioServer.set_bus_send(bus_idx, BUS_MASTER)


func has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


## Plays the drop-in sound effect for a logical event id on the SFX bus.
## Missing assets produce no sound and no errors.
func play_sfx(event_id: StringName) -> void:
	var path: String = AssetResolver.sfx_path(event_id)
	if path == "":
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - int(_last_sfx_ms.get(event_id, -SFX_COOLDOWN_MS)) < SFX_COOLDOWN_MS:
		return
	_last_sfx_ms[event_id] = now_ms
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


## Starts looping background music for a track id on the Music bus. Missing assets
## produce no sound and no errors.
func play_music(track_id: StringName) -> void:
	var path: String = AssetResolver.music_path(track_id)
	if path == "":
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = BUS_MUSIC
		add_child(_music_player)
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()


func _connect_event_bus() -> void:
	if not is_instance_valid(EventBus):
		return
	if not EventBus.resource_gained.is_connected(_on_resource_gained):
		EventBus.resource_gained.connect(_on_resource_gained)
	if not EventBus.synergy_triggered.is_connected(_on_synergy_triggered):
		EventBus.synergy_triggered.connect(_on_synergy_triggered)
	if not EventBus.upgrade_purchased.is_connected(_on_upgrade_purchased):
		EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	if not EventBus.breakthrough_reached.is_connected(_on_breakthrough_reached):
		EventBus.breakthrough_reached.connect(_on_breakthrough_reached)


func _on_resource_gained(currency_id: StringName, _amount: float, source_id: StringName) -> void:
	if currency_id == &"coins" and Balance.species(source_id) != null:
		play_sfx(&"wood_chop")


func _on_synergy_triggered(_species_id: StringName, _synergy_id: StringName, _duration_s: float) -> void:
	play_sfx(&"timberfall")


func _on_upgrade_purchased(_upgrade_id: StringName, _new_level: int) -> void:
	play_sfx(&"button_click")


func _on_breakthrough_reached(_act_index: int) -> void:
	play_sfx(&"breakthrough_fanfare")
