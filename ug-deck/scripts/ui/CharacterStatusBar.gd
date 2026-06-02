extends Control
class_name CharacterStatusBar

const STATUS_EFFECT_INFO_SCRIPT := preload("res://scripts/ui/StatusEffectInfo.gd")
const STATUS_EFFECT_POPUP_SCRIPT := preload("res://scripts/ui/StatusEffectPopup.gd")

var bar: ProgressBar
var icon_rect: TextureRect
var primary_label: Label
var secondary_label: Label
var status_row: HBoxContainer
var popup: StatusEffectPopup
var bar_tween: Tween

var current_hp := 0
var max_hp := 1
var current_block := 0
var current_states: Array = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(176, 50)
	size = custom_minimum_size
	z_index = 100
	_build()


func update_values(display_name: String, hp: int, maximum_hp: int, block: int, states: Array = []) -> void:
	if bar == null:
		_build()

	current_hp = hp
	max_hp = maxi(maximum_hp, 1)
	current_block = maxi(block, 0)
	current_states = STATUS_EFFECT_INFO_SCRIPT.merge_states(states)
	visible = current_hp > 0

	var has_block := current_block > 0
	icon_rect.texture = STATUS_EFFECT_INFO_SCRIPT.get_icon_texture("shield" if has_block else "heart")
	primary_label.text = "%d" % current_block if has_block else "%d/%d" % [current_hp, max_hp]
	secondary_label.text = "%d/%d" % [current_hp, max_hp] if has_block else display_name
	secondary_label.visible = not secondary_label.text.is_empty()

	if has_block:
		bar.max_value = maxf(maxf(float(max_hp), float(current_block)), 1.0)
		_set_bar_value_smooth(current_block)
		_set_bar_fill_color(Color(0.12, 0.45, 0.95, 1.0))
	else:
		bar.max_value = max_hp
		_set_bar_value_smooth(clamp(current_hp, 0, max_hp))
		_set_bar_fill_color(Color(0.82, 0.12, 0.12, 1.0))

	_refresh_status_chips()


func _set_bar_value_smooth(target_value: float) -> void:
	if bar_tween != null:
		bar_tween.kill()
	bar_tween = create_tween()
	bar_tween.tween_property(bar, "value", target_value, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build() -> void:
	if bar != null:
		return

	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color(0.07, 0.07, 0.08, 0.88)
	outer_style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	outer_style.set_border_width_all(2)
	outer_style.set_content_margin_all(4)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", outer_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(bar_wrap)

	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.13, 0.13, 0.14, 1.0)))
	bar.add_theme_stylebox_override("fill", _make_bar_style(Color(0.82, 0.12, 0.12, 1.0)))
	bar_wrap.add_child(bar)

	var info_row := HBoxContainer.new()
	info_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 4)
	bar_wrap.add_child(info_row)

	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info_row.add_child(icon_rect)

	primary_label = Label.new()
	primary_label.add_theme_color_override("font_color", Color.WHITE)
	primary_label.add_theme_color_override("font_outline_color", Color.BLACK)
	primary_label.add_theme_constant_override("outline_size", 4)
	primary_label.add_theme_font_size_override("font_size", 13)
	info_row.add_child(primary_label)

	secondary_label = Label.new()
	secondary_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.86, 1.0))
	secondary_label.add_theme_color_override("font_outline_color", Color.BLACK)
	secondary_label.add_theme_constant_override("outline_size", 3)
	secondary_label.add_theme_font_size_override("font_size", 10)
	info_row.add_child(secondary_label)

	status_row = HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 3)
	vbox.add_child(status_row)

	popup = STATUS_EFFECT_POPUP_SCRIPT.new()
	add_child(popup)


func _refresh_status_chips() -> void:
	for child in status_row.get_children():
		child.queue_free()

	status_row.visible = not current_states.is_empty()
	if current_states.is_empty():
		popup.hide_popup()

	for state in current_states:
		var state_dict: Dictionary = state
		var chip := Button.new()
		chip.text = STATUS_EFFECT_INFO_SCRIPT.get_chip_text(state_dict)
		chip.custom_minimum_size = Vector2(34, 18)
		chip.add_theme_font_size_override("font_size", 9)
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.pressed.connect(func(): popup.show_status(state_dict, Vector2(0, -116)))
		status_row.add_child(chip)


func _set_bar_fill_color(color: Color) -> void:
	bar.add_theme_stylebox_override("fill", _make_bar_style(color))


func _make_bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(0)
	return style
