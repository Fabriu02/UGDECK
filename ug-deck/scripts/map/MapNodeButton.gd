extends Button
class_name MapNodeButton

signal node_selected(node_id: String, scene_path: String)
signal node_blocked(node_id: String, display_name: String)

@export var node_id := ""
@export var display_name := ""
@export_file("*.tscn") var scene_path := ""
@export var is_unlocked := false
@export var hover_scale := Vector2(1.05, 1.05)
@export var pressed_scale := Vector2(0.96, 0.96)
@export var unlocked_color := Color(1.0, 1.0, 1.0, 1.0)
@export var hover_color := Color(1.12, 1.12, 1.12, 1.0)
@export var locked_color := Color(0.5, 0.5, 0.5, 1.0)
@export var completed_color := Color(0.75, 1.0, 0.78, 1.0)
@export var debug_button_background := true

var _base_scale := Vector2.ONE
var _base_position := Vector2.ZERO
var _is_completed := false
var _tween: Tween
var _button_style := StyleBoxFlat.new()


func _ready() -> void:
	_base_scale = scale
	_base_position = position
	_update_pivot()
	_apply_transparent_button_style()

	resized.connect(_update_pivot)
	mouse_entered.connect(play_hover_animation)
	mouse_exited.connect(play_exit_animation)
	pressed.connect(_on_pressed)

	if display_name.is_empty():
		display_name = text
	else:
		text = display_name

	_update_visual_state()


func setup(p_node_id: String, p_display_name: String, p_scene_path: String, p_is_unlocked: bool) -> void:
	node_id = p_node_id
	display_name = p_display_name
	scene_path = p_scene_path
	is_unlocked = p_is_unlocked
	text = display_name
	_update_visual_state()


func set_layout_rect(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	custom_minimum_size = rect.size
	_base_position = position
	_base_scale = scale
	_update_pivot()


func set_debug_button_background(value: bool) -> void:
	debug_button_background = value
	_update_button_style()
	_update_visual_state()


func set_debug_visible(value: bool) -> void:
	set_debug_button_background(value)


func set_locked() -> void:
	is_unlocked = false
	_is_completed = false
	_update_visual_state()


func set_unlocked() -> void:
	is_unlocked = true
	_is_completed = false
	_update_visual_state()


func set_completed() -> void:
	is_unlocked = true
	_is_completed = true
	_update_visual_state()


func play_hover_animation() -> void:
	if not is_unlocked:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", _base_scale * hover_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", _get_hover_color(), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation_degrees", -1.5, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func play_exit_animation() -> void:
	if not is_unlocked:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", _get_rest_color(), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation_degrees", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func play_click_animation() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", _base_scale * pressed_scale, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", _base_scale * hover_scale, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_locked_feedback() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "position:x", _base_position.x - 8.0, 0.04)
	_tween.tween_property(self, "position:x", _base_position.x + 8.0, 0.04)
	_tween.tween_property(self, "position:x", _base_position.x - 5.0, 0.04)
	_tween.tween_property(self, "position:x", _base_position.x + 5.0, 0.04)
	_tween.tween_property(self, "position:x", _base_position.x, 0.05)


func _on_pressed() -> void:
	if not is_unlocked:
		play_locked_feedback()
		node_blocked.emit(node_id, display_name)
		return

	play_click_animation()
	node_selected.emit(node_id, scene_path)


func _update_visual_state() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	modulate = _get_rest_color()
	tooltip_text = display_name if is_unlocked else "%s - Bloqueado" % display_name


func _get_rest_color() -> Color:
	if _is_completed:
		return completed_color

	return unlocked_color if is_unlocked else locked_color


func _get_hover_color() -> Color:
	return hover_color


func _apply_transparent_button_style() -> void:
	_button_style.border_width_left = 2
	_button_style.border_width_top = 2
	_button_style.border_width_right = 2
	_button_style.border_width_bottom = 2
	_button_style.corner_radius_top_left = 6
	_button_style.corner_radius_top_right = 6
	_button_style.corner_radius_bottom_left = 6
	_button_style.corner_radius_bottom_right = 6

	add_theme_stylebox_override("normal", _button_style)
	add_theme_stylebox_override("hover", _button_style)
	add_theme_stylebox_override("pressed", _button_style)
	add_theme_stylebox_override("disabled", _button_style)
	add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_font_size_override("font_size", 18)
	_update_button_style()


func _update_button_style() -> void:
	_button_style.bg_color = Color(1.0, 1.0, 1.0, 0.26 if debug_button_background else 0.0)
	_button_style.border_color = Color(1.0, 1.0, 1.0, 0.35 if debug_button_background else 0.0)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _update_pivot() -> void:
	pivot_offset = size * 0.5
