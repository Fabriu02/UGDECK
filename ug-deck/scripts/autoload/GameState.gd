extends Node

# --- DATOS DEL MAPA PROCEDURAL ---
var map_data: Dictionary = {}
var nodo_actual_id: int = -1
var nodos_completados: Array[int] = []
var dinero: int = 150
var artilugios: Array[String] = []
var vida_actual: int = 50
var vida_maxima: int = 50


const INFO_ARTILUGIOS = {
	"Termo de Mate Supremo": {
		"tipo": "inmediato", 
		"efecto": "energia_max", 
		"valor": 2,
		"descripcion": "+2 de Energía Máxima permanentemente.",
		"icono": "res://assets/iconos/Termo_supremo.png"
		
	},
	"Apuntes de Años Anteriores": {
		"tipo": "inicio_combate", 
		"efecto": "escudo_inicial", 
		"valor": 15,
		"descripcion": "Empiezas cada examen (combate) con 15 de Escudo."
	},
	"Calculadora Científica": {
		"tipo": "pasivo_combate",
		"efecto": "costo_cero",
		"valor": 1,
		"descripcion": "La primera carta que juegas en cada combate cuesta 0.",
		"icono": "res://assets/iconos/Calculadora cientifica.png" #
	}
}
func _ready() -> void:
	reset_run_progress()
	
func reset_run_progress() -> void:
	map_data.clear()
	nodo_actual_id = -1
	nodos_completados.clear()

func visitar_nodo(node_id: int) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de visitar un nodo desconocido: %s" % node_id)
		return

	nodo_actual_id = node_id

func completar_nodo_actual() -> void:
	if nodo_actual_id == -1:
		return

	if not nodos_completados.has(nodo_actual_id):
		nodos_completados.append(nodo_actual_id)

func volver_al_primer_nodo() -> void:
	nodos_completados.clear()
	nodo_actual_id = _get_first_node_id()

func is_node_unlocked(node_id: int) -> bool:
	if map_data.is_empty():
		return false

	if nodo_actual_id == -1:
		for n in map_data.nodes:
			if n.id == node_id and n.position.x == 0:
				return true
		return false

	if node_id == nodo_actual_id and not is_node_completed(node_id):
		return true

	if not is_node_completed(nodo_actual_id):
		return false

	for conn in map_data.connections:
		if conn[0] == nodo_actual_id and conn[1] == node_id:
			return true

	return false

func is_node_completed(node_id: int) -> bool:
	return nodos_completados.has(node_id)

func _is_known_node(node_id: int) -> bool:
	if map_data.is_empty():
		return false

	for n in map_data.nodes:
		if n.id == node_id:
			return true

	return false

func _get_first_node_id() -> int:
	if map_data.is_empty():
		return -1

	var first_node_id := -1
	var first_column := INF
	for n in map_data.nodes:
		if n.position.x < first_column:
			first_column = n.position.x
			first_node_id = n.id

	return first_node_id
	
	
# --- MODO DESARROLLADOR: GANAR Y SALTAR NIVEL ---
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		var escena_actual = get_tree().current_scene.name
		if escena_actual != "VistaMapa" and escena_actual != "vista_mapa":
			print("⏭️ ¡Nivel saltado y GANADO por el desarrollador!")
			
			# 1. LE DECIMOS AL JUEGO QUE GANAMOS:
			# Si estamos en un nodo válido, lo metemos en la lista de completados
			if nodo_actual_id != -1:
				if not nodos_completados.has(nodo_actual_id):
					nodos_completados.append(nodo_actual_id)
			
			# 2. Volvemos al mapa
			get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
