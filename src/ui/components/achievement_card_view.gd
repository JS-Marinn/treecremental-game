class_name AchievementCardView
extends PanelContainer
## Single achievement card inside ModalAchievementsView, bound via %UniqueNodeNames.
## Icons are loaded by AssetResolver naming convention and are optional: when the
## icon asset has not been delivered, the icon slot stays empty.

var achievement_data: AchievementDefinitionData
var unlocked: bool = false

@onready var _icon_rect: TextureRect = get_node_or_null("%AchIconRect") as TextureRect
@onready var _title_label: Label = get_node_or_null("%AchTitleLabel") as Label
@onready var _desc_label: Label = get_node_or_null("%AchDescLabel") as Label
@onready var _status_label: Label = get_node_or_null("%AchStatusLabel") as Label


func bind_achievement(data: AchievementDefinitionData, is_unlocked: bool, icon: Texture2D = null) -> void:
	achievement_data = data
	unlocked = is_unlocked
	if data == null:
		return
	if _title_label != null:
		_title_label.text = tr(data.name_key())
	if _desc_label != null:
		_desc_label.text = tr(data.desc_key())
	if _icon_rect != null:
		_icon_rect.texture = icon
	if _status_label != null:
		_status_label.text = tr("KEY_ACH_STATUS_UNLOCKED") if unlocked else tr("KEY_ACH_STATUS_LOCKED")
		_status_label.add_theme_color_override(
			"font_color",
			Color(0.62, 0.92, 0.55, 1.0) if unlocked else Color(0.62, 0.60, 0.55, 1.0)
		)
