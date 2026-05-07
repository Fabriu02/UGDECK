extends Control

const MAP_SCENE_PATH := "res://scenes/map/vista_mapa.tscn"

@onready var jugar_button: Button = %JugarButton
@onready var opciones_button: Button = %OpcionesButton
@onready var salir_button: Button = %SalirButton
@onready var feedback_label: Label = %FeedbackLabel

var _feedback_tween: Tween


func _ready() -> void:
	jugar_button.pressed.connect(_on_jugar_pressed)
	opciones_button.pressed.connect(_on_opciones_pressed)
	salir_button.pressed.connect(_on_salir_pressed)

	feedback_label.modulate.a = 0.0


func _on_jugar_pressed() -> void:
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _on_opciones_pressed() -> void:
	print_debug("Opciones proximamente.")
	_show_feedback("Opciones proximamente")


func _on_salir_pressed() -> void:
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()


func _show_feedback(message: String) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	feedback_label.text = message
	feedback_label.modulate.a = 1.0

	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(1.2)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.35)
