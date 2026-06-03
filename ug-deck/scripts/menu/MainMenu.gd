extends Control

const MAP_SCENE_PATH := "res://scenes/map/vista_mapa.tscn"
# AGREGADO: Constante con la ruta a tu nueva escena de opciones.
# IMPORTANTE: Asegurate de que esta ruta sea exactamente donde guardaste tu OptionsMenu.tscn
const OPTIONS_SCENE_PATH := "res://scenes/menu/OptionsMenu.tscn"

@onready var continuar_button: Button = %ContinuarButton
@onready var jugar_button: Button = %JugarButton
@onready var opciones_button: Button = %OpcionesButton
@onready var salir_button: Button = %SalirButton
@onready var feedback_label: Label = %FeedbackLabel

var _feedback_tween: Tween


func _ready() -> void:
	continuar_button.pressed.connect(_on_continuar_pressed)
	jugar_button.pressed.connect(_on_jugar_pressed)
	opciones_button.pressed.connect(_on_opciones_pressed)
	salir_button.pressed.connect(_on_salir_pressed)

	feedback_label.modulate.a = 0.0
	
	if GameState.has_saved_game():
		continuar_button.show()
	else:
		continuar_button.hide()


func _on_continuar_pressed() -> void:
	if GameState.load_game():
		await get_tree().create_timer(0.08).timeout
		get_tree().change_scene_to_file(MAP_SCENE_PATH)
	else:
		_show_feedback("Error cargando partida")


func _on_jugar_pressed() -> void:
	GameState.delete_saved_game()
	GameState.start_new_run()
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _on_opciones_pressed() -> void:
	# MODIFICADO: Quitamos los prints y el feedback, y agregamos el cambio de escena
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)


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
