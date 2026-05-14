extends Node

# --- DATOS DEL MAPA PROCEDURAL ---
var map_data: Dictionary = {}
var nodo_actual_id: int = -1
var nodos_completados: Array[int] = [] # Historial del camino que tomó el jugador

func _ready() -> void:
	reset_run_progress()

func reset_run_progress() -> void:
	# Limpiamos todo al morir o empezar una nueva partida
	map_data.clear()
	nodo_actual_id = -1
	nodos_completados.clear()

# Llama a esta función cuando el jugador viaja a un nuevo nodo
func visitar_nodo(node_id: int) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de visitar un nodo desconocido: %s" % node_id)
		return

	# Si ya estábamos en un nodo, lo marcamos como completado antes de movernos
	if nodo_actual_id != -1 and not nodos_completados.has(nodo_actual_id):
		nodos_completados.append(nodo_actual_id)

	nodo_actual_id = node_id

# El mapa ahora decide qué está desbloqueado leyendo las conexiones
func is_node_unlocked(node_id: int) -> bool:
	if map_data.is_empty():
		return false

	# Si no hemos empezado, todos los nodos de la primera columna están desbloqueados
	if nodo_actual_id == -1:
		for n in map_data.nodes:
			if n.id == node_id and n.position.x == 0:
				return true
		return false

	# Si ya estamos en el mapa, vemos si hay una línea directa desde donde estamos
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
