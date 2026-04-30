extends Node

const NODE_PRIMER_PARCIAL := "primer_parcial"
const NODE_TIENDA := "tienda"
const NODE_TRABAJO_PRACTICO := "trabajo_practico"
const NODE_SEGUNDO_PARCIAL := "segundo_parcial"
const NODE_FINAL := "final"

const ALL_NODE_IDS := [
	NODE_PRIMER_PARCIAL,
	NODE_TIENDA,
	NODE_TRABAJO_PRACTICO,
	NODE_SEGUNDO_PARCIAL,
	NODE_FINAL,
]

var unlocked_nodes: Dictionary = {}
var completed_nodes: Dictionary = {}


func _ready() -> void:
	reset_run_progress()


func reset_run_progress() -> void:
	unlocked_nodes.clear()
	completed_nodes.clear()

	for node_id in ALL_NODE_IDS:
		unlocked_nodes[node_id] = false
		completed_nodes[node_id] = false

	unlock_node(NODE_PRIMER_PARCIAL)


func unlock_node(node_id: String) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de desbloquear un nodo desconocido: %s" % node_id)
		return

	unlocked_nodes[node_id] = true


func lock_node(node_id: String) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de bloquear un nodo desconocido: %s" % node_id)
		return

	unlocked_nodes[node_id] = false


func complete_node(node_id: String) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de completar un nodo desconocido: %s" % node_id)
		return

	completed_nodes[node_id] = true


func is_node_unlocked(node_id: String) -> bool:
	return bool(unlocked_nodes.get(node_id, false))


func is_node_completed(node_id: String) -> bool:
	return bool(completed_nodes.get(node_id, false))


func _is_known_node(node_id: String) -> bool:
	return ALL_NODE_IDS.has(node_id)
