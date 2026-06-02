extends Control
class_name PlayerCombatHUD

const STATUS_EFFECT_INFO_SCRIPT := preload("res://scripts/ui/StatusEffectInfo.gd")
const STATUS_EFFECT_POPUP_SCRIPT := preload("res://scripts/ui/StatusEffectPopup.gd")

var hp_label: Label
var energy_label: Label
var block_label: Label
var gold_label: Label
var status_label: Label
var status_row: HBoxContainer
var popup: StatusEffectPopup


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 58
	_build()


func update_values(current_hp: int, max_hp: int, current_energy: int, max_energy: int, block: int, gold: int, states: Array) -> void:
	if hp_label == null:
		_build()

	hp_label.text = "%d/%d" % [current_hp, max_hp]
	energy_label.text = "%d/%d" % [current_energy, max_energy]
	block_label.text = "%d" % block
	gold_label.text = "%d" % gold
	_refresh_status_chips(STATUS_EFFECT_INFO_SCRIPT.merge_states(states))


func _build() -> void:
	if hp_label != null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.13, 0.94)
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	style.set_border_width(SIDE_BOTTOM, 3)
	style.set_content_margin_all(10)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	hp_label = _add_icon_value(row, "heart", "0/0")
	_add_separator(row)
	energy_label = _add_icon_value(row, "energy", "0/0", "Energia")
	_add_separator(row)
	block_label = _add_icon_value(row, "shield", "0")
	_add_separator(row)
	gold_label = _add_icon_value(row, "coins", "0", "Oro")
	_add_separator(row)

	status_label = Label.new()
	status_label.text = "Estados"
	status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(status_label)

	status_row = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 4)
	status_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(status_row)

	popup = STATUS_EFFECT_POPUP_SCRIPT.new()
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup)


func _add_icon_value(parent: HBoxContainer, icon_kind: String, initial_text: String, fallback_text: String = "") -> Label:
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 5)
	group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(group)

	var icon := TextureRect.new()
	icon.texture = STATUS_EFFECT_INFO_SCRIPT.get_icon_texture(icon_kind)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.visible = icon.texture != null
	group.add_child(icon)

	if not fallback_text.is_empty() and icon.texture == null:
		var fallback := Label.new()
		fallback.text = fallback_text
		fallback.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		group.add_child(fallback)

	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	group.add_child(label)
	return label


func _add_separator(parent: HBoxContainer) -> void:
	var separator := VSeparator.new()
	separator.custom_minimum_size = Vector2(8, 0)
	parent.add_child(separator)


func _refresh_status_chips(states: Array) -> void:
	for child in status_row.get_children():
		child.queue_free()

	status_label.visible = not states.is_empty()
	status_row.visible = not states.is_empty()
	if states.is_empty():
		popup.hide_popup()

	for state in states:
		var state_dict: Dictionary = state
		var chip := Button.new()
		chip.text = STATUS_EFFECT_INFO_SCRIPT.get_chip_text(state_dict)
		chip.custom_minimum_size = Vector2(54, 26)
		chip.add_theme_font_size_override("font_size", 11)
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.pressed.connect(func(): popup.show_status(state_dict, Vector2(290, 52)))
		status_row.add_child(chip)
