class_name ModalAchievementsView
extends PanelContainer
## Editable Achievements gallery modal bound via %UniqueNodeNames.

signal closed()

const PREVIEW_ACHIEVEMENTS: Array[Dictionary] = [
	{"id": &"first_timber", "name_key": "KEY_ACH_FIRST_TIMBER_NAME", "desc_key": "KEY_ACH_FIRST_TIMBER_DESC"},
	{"id": &"breakthrough_1", "name_key": "KEY_ACH_BREAKTHROUGH_1_NAME", "desc_key": "KEY_ACH_BREAKTHROUGH_1_DESC"},
	{"id": &"great_felling", "name_key": "KEY_ACH_GREAT_FELLING_NAME", "desc_key": "KEY_ACH_GREAT_FELLING_DESC"},
]

var unlocked_ids: Array[StringName] = []

@onready var _title_label: Label = get_node_or_null("%ModalTitleLabel") as Label
@onready var _unlocked_count_label: Label = get_node_or_null("%UnlockedCountLabel") as Label
@onready var _harmony_bonus_label: Label = get_node_or_null("%HarmonyBonusLabel") as Label
@onready var _achievement_grid: GridContainer = get_node_or_null("%AchievementGrid") as GridContainer
@onready var _close_btn: Button = get_node_or_null("%CloseButton") as Button


func _ready() -> void:
	if _close_btn != null:
		_close_btn.pressed.connect(_on_close_pressed)
	refresh_view()


func refresh_view() -> void:
	if _title_label != null:
		_title_label.text = tr("KEY_UI_BTN_ACHIEVEMENTS")
	if _unlocked_count_label != null:
		_unlocked_count_label.text = "%d / 80" % unlocked_ids.size()
	var bonus_per_ach: float = StatAggregator.query(&"achievement_coin_bonus", &"all", 0.0)
	if _harmony_bonus_label != null:
		_harmony_bonus_label.text = "+%d%%" % int(round(float(unlocked_ids.size()) * bonus_per_ach * 100.0))

	if _achievement_grid == null:
		return
	for child in _achievement_grid.get_children():
		_achievement_grid.remove_child(child)
		child.queue_free()

	for ach in PREVIEW_ACHIEVEMENTS:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(165, 42)
		var vbox := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = tr(String(ach["name_key"]))
		var desc_lbl := Label.new()
		desc_lbl.text = tr(String(ach["desc_key"]))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_lbl)
		vbox.add_child(desc_lbl)
		card.add_child(vbox)
		_achievement_grid.add_child(card)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
