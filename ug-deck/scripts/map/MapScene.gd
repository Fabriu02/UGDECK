extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/menu/MainMenu.tscn"

const NODE_PRIMER_PARCIAL := "primer_parcial"
const NODE_TIENDA := "tienda"
const NODE_TRABAJO_PRACTICO := "trabajo_practico"
const NODE_SEGUNDO_PARCIAL := "segundo_parcial"
const NODE_FINAL := "final"
const BASE_RESOLUTION := Vector2(1152.0, 648.0)

@export_file("*.tscn") var first_battle_scene_path := "res://scenes/BattleScene.tscn"
@export var debug_button_background := true

@onready var primer_parcial_button: MapNodeButton = %PrimerParcialButton
@onready var tienda_button: MapNodeButton = %TiendaButton
@onready var trabajo_practico_button: MapNodeButton = %TrabajoPracticoButton
@onready var segundo_parcial_button: MapNodeButton = %SegundoParcialButton
@onready var final_button: MapNodeButton = %FinalButton
@onready var salir_button: Button = %SalirButton
@onready var feedback_label: Label = %FeedbackLabel

var _feedback_tween: Tween
var _node_buttons: Dictionary = {}
var map_button_rects := {
	NODE_PRIMER_PARCIAL: Rect2(Vector2(230.0, 145.0), Vector2(210.0, 85.0)),
	NODE_TRABAJO_PRACTICO: Rect2(Vector2(485.0, 145.0), Vector2(230.0, 85.0)),
	NODE_TIENDA: Rect2(Vector2(230.0, 395.0), Vector2(210.0, 85.0)),
	NODE_SEGUNDO_PARCIAL: Rect2(Vector2(455.0, 395.0), Vector2(240.0, 85.0)),
	NODE_FINAL: Rect2(Vector2(780.0, 395.0), Vector2(210.0, 85.0)),
	"volver": Rect2(Vector2(35.0, 585.0), Vector2(150.0, 45.0)),
	"feedback": Rect2(Vector2(376.0, 582.0), Vector2(400.0, 48.0)),
}


func _ready() -> void:
	resized.connect(apply_map_button_layout)

	_node_buttons = {
		NODE_PRIMER_PARCIAL: primer_parcial_button,
		NODE_TIENDA: tienda_button,
		NODE_TRABAJO_PRACTICO: trabajo_practico_button,
		NODE_SEGUNDO_PARCIAL: segundo_parcial_button,
		NODE_FINAL: final_button,
	}

	_setup_map_buttons()
	_refresh_map_state()
	apply_map_button_layout()

	salir_button.pressed.connect(_on_salir_pressed)
	feedback_label.modulate.a = 0.0


func _setup_map_buttons() -> void:
	primer_parcial_button.setup(NODE_PRIMER_PARCIAL, "Primer parcial", first_battle_scene_path, GameState.is_node_unlocked(NODE_PRIMER_PARCIAL))
	tienda_button.setup(NODE_TIENDA, "Tienda", "", GameState.is_node_unlocked(NODE_TIENDA))
	trabajo_practico_button.setup(NODE_TRABAJO_PRACTICO, "Trabajo practico", "", GameState.is_node_unlocked(NODE_TRABAJO_PRACTICO))
	segundo_parcial_button.setup(NODE_SEGUNDO_PARCIAL, "Segundo parcial", "", GameState.is_node_unlocked(NODE_SEGUNDO_PARCIAL))
	final_button.setup(NODE_FINAL, "Final", "", GameState.is_node_unlocked(NODE_FINAL))

	for button: MapNodeButton in _node_buttons.values():
		button.set_debug_button_background(debug_button_background)
		button.node_selected.connect(_on_node_selected)
		button.node_blocked.connect(_on_node_blocked)


func apply_map_button_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_x := viewport_size.x / BASE_RESOLUTION.x
	var scale_y := viewport_size.y / BASE_RESOLUTION.y

	_apply_button_rect(primer_parcial_button, map_button_rects[NODE_PRIMER_PARCIAL], scale_x, scale_y)
	_apply_button_rect(trabajo_practico_button, map_button_rects[NODE_TRABAJO_PRACTICO], scale_x, scale_y)
	_apply_button_rect(tienda_button, map_button_rects[NODE_TIENDA], scale_x, scale_y)
	_apply_button_rect(segundo_parcial_button, map_button_rects[NODE_SEGUNDO_PARCIAL], scale_x, scale_y)
	_apply_button_rect(final_button, map_button_rects[NODE_FINAL], scale_x, scale_y)
	_apply_button_rect(salir_button, map_button_rects["volver"], scale_x, scale_y)
	_apply_button_rect(feedback_label, map_button_rects["feedback"], scale_x, scale_y)

	for button: MapNodeButton in _node_buttons.values():
		button.set_debug_button_background(debug_button_background)


func _refresh_map_state() -> void:
	for node_id: String in _node_buttons.keys():
		var button: MapNodeButton = _node_buttons[node_id]

		if GameState.is_node_completed(node_id):
			button.set_completed()
		elif GameState.is_node_unlocked(node_id):
			button.set_unlocked()
		else:
			button.set_locked()


func _on_node_selected(node_id: String, scene_path: String) -> void:
	if not GameState.is_node_unlocked(node_id):
		_show_feedback("Bloqueado")
		return

	if scene_path.is_empty():
		_show_feedback("Todavia no disponible")
		return

	_show_feedback("%s seleccionado" % _get_node_display_name(node_id))
	await get_tree().create_timer(0.12).timeout
	get_tree().change_scene_to_file(scene_path)


func _on_node_blocked(_node_id: String, _display_name: String) -> void:
	_show_feedback("Bloqueado")


func _on_salir_pressed() -> void:
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _show_feedback(message: String) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	feedback_label.text = message
	feedback_label.modulate.a = 1.0

	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(1.25)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.35)


func _get_node_display_name(node_id: String) -> String:
	match node_id:
		NODE_PRIMER_PARCIAL:
			return "Primer parcial"
		NODE_TIENDA:
			return "Tienda"
		NODE_TRABAJO_PRACTICO:
			return "Trabajo practico"
		NODE_SEGUNDO_PARCIAL:
			return "Segundo parcial"
		NODE_FINAL:
			return "Final"
		_:
			return node_id


func _apply_button_rect(control: Control, rect: Rect2, scale_x: float, scale_y: float) -> void:
	var scaled_position := Vector2(rect.position.x * scale_x, rect.position.y * scale_y)
	var scaled_size := Vector2(rect.size.x * scale_x, rect.size.y * scale_y)

	if control is MapNodeButton:
		(control as MapNodeButton).set_layout_rect(Rect2(scaled_position, scaled_size))
		return

	control.position = scaled_position
	control.size = scaled_size
	control.custom_minimum_size = scaled_size
	control.pivot_offset = scaled_size * 0.5
