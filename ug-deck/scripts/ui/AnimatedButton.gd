extends Button
class_name AnimatedButton

@export var hover_scale := Vector2(1.06, 1.06)
@export var pressed_scale := Vector2(0.96, 0.96)
@export var normal_color := Color(1.0, 1.0, 1.0, 1.0)
@export var hover_color := Color(1.12, 1.12, 1.12, 1.0)
@export var disabled_color := Color(0.55, 0.55, 0.55, 0.8)
@export var hover_duration := 0.12
@export var click_duration := 0.08

var _base_scale := Vector2.ONE
var _tween: Tween


func _ready() -> void:
	_base_scale = scale
	modulate = normal_color
	_update_pivot()

	resized.connect(_update_pivot)
	mouse_entered.connect(play_hover_animation)
	mouse_exited.connect(play_exit_animation)
	button_down.connect(play_click_animation)


func play_hover_animation() -> void:
	if disabled:
		return

	_animate_to(_base_scale * hover_scale, hover_color, hover_duration)


func play_exit_animation() -> void:
	if disabled:
		return

	_animate_to(_base_scale, normal_color, hover_duration)


func play_click_animation() -> void:
	if disabled:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", _base_scale * pressed_scale, click_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", hover_color, click_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	_tween.tween_property(self, "scale", _base_scale * hover_scale, click_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_button_enabled(is_enabled: bool) -> void:
	disabled = not is_enabled
	modulate = normal_color if is_enabled else disabled_color


func _animate_to(target_scale: Vector2, target_color: Color, duration: float) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", target_color, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _update_pivot() -> void:
	pivot_offset = size * 0.5
