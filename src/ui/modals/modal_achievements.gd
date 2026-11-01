class_name ModalAchievementsView
extends PanelContainer
## Achievements gallery modal displaying all ~80 canonical achievements with live
## locked/unlocked state driven by AchievementModule. Cards are instantiated from
## scenes/ui/components/achievement_card_template.tscn and never built in code.

signal closed()

const ACHIEVEMENT_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/achievement_card_template.tscn")

var achievement_module: AchievementModule

@onready var _title_label: Label = get_node_or_null("%ModalTitleLabel") as Label
@onready var _unlocked_count_label: Label = get_node_or_null("%UnlockedCountLabel") as Label
@onready var _harmony_bonus_label: Label = get_node_or_null("%HarmonyBonusLabel") as Label
@onready var _achievement_grid: GridContainer = get_node_or_null("%AchievementGrid") as GridContainer
@onready var _close_btn: Button = get_node_or_null("%CloseButton") as Button


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(_on_close_pressed)
	if is_instance_valid(EventBus) and not EventBus.achievement_unlocked.is_connected(_on_achievement_unlocked):
		EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	refresh_view()


func bind_achievements(module: AchievementModule) -> void:
	achievement_module = module
	refresh_view()


func refresh_view() -> void:
	var unlocked_count: int = achievement_module.get_unlocked_count() if achievement_module != null else 0
	var total: int = Balance.achievement_ids().size()

	if _title_label != null:
		_title_label.text = tr("KEY_UI_BTN_ACHIEVEMENTS")
	if _unlocked_count_label != null:
		_unlocked_count_label.text = "%d / %d" % [unlocked_count, total]
	var bonus_per_ach: float = StatAggregator.query(&"achievement_coin_bonus", &"all", 1.0) - 1.0
	if _harmony_bonus_label != null:
		_harmony_bonus_label.text = "+%d%%" % int(round(float(unlocked_count) * bonus_per_ach * 100.0))

	if _achievement_grid == null:
		return
	for child in _achievement_grid.get_children():
		_achievement_grid.remove_child(child)
		child.queue_free()

	for ach_id in Balance.achievement_ids():
		var def: AchievementDefinitionData = Balance.achievement(ach_id)
		if def == null:
			continue
		var card: AchievementCardView = ACHIEVEMENT_CARD_SCENE.instantiate() as AchievementCardView
		_achievement_grid.add_child(card)
		var is_unlocked: bool = achievement_module != null and achievement_module.is_unlocked(ach_id)
		card.bind_achievement(def, is_unlocked, AssetResolver.achievement_icon(ach_id))


func _on_achievement_unlocked(_achievement_id: StringName) -> void:
	refresh_view()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
