extends CanvasLayer
class_name ZoneBossRewardScreen

signal reward_selected(reward_data: Dictionary)

const CARD_MIN_SIZE := Vector2(240, 300)
const ICON_SIZE := Vector2(72, 72)

@onready var root: Control = $Root
@onready var options_container: HBoxContainer = $Root/Panel/MarginContainer/VBoxContainer/OptionsContainer

var selection_locked := false


func _ready() -> void:
	layer = 70
	visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_rewards(reward_options: Array[Dictionary]) -> void:
	selection_locked = false
	_clear_options()

	for reward_data in reward_options:
		options_container.add_child(_create_reward_button(reward_data))

	visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP


func hide_rewards() -> void:
	visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_options()


func _create_reward_button(reward_data: Dictionary) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = CARD_MIN_SIZE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): _on_reward_pressed(button, reward_data))

	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path: String = String(reward_data.get("icon_path", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path) as Texture2D
	content.add_child(icon)

	var title: Label = Label.new()
	title.text = String(reward_data.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35, 1.0))
	content.add_child(title)

	var description: Label = Label.new()
	description.text = String(reward_data.get("description", ""))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 13)
	description.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84, 1.0))
	content.add_child(description)

	var preview: Label = Label.new()
	preview.text = String(reward_data.get("preview", ""))
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_theme_font_size_override("font_size", 12)
	preview.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0, 1.0))
	content.add_child(preview)

	return button


func _on_reward_pressed(button: Button, reward_data: Dictionary) -> void:
	if selection_locked:
		return

	selection_locked = true
	for child in options_container.get_children():
		if child is Button:
			(child as Button).disabled = true
	button.modulate = Color(1.18, 1.10, 0.78, 1.0)
	reward_selected.emit(reward_data)


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()
