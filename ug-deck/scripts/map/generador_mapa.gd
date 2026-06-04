class_name generador_mapa
extends Node

const GENERATED_ZONE_COUNT := 4
const TRANSITION_COLUMNS_BETWEEN_ZONES := 2
const BRANCH_COUNT := 4
const BRANCH_LENGTH := 4
const COLUMNS_PER_ZONE := BRANCH_LENGTH + 2
const CENTRAL_ROW := 1.5
const MAP_VERSION := 9

var num_columns: int = (GENERATED_ZONE_COUNT * COLUMNS_PER_ZONE) + ((GENERATED_ZONE_COUNT - 1) * TRANSITION_COLUMNS_BETWEEN_ZONES)
var total_nodes: int = (GENERATED_ZONE_COUNT * (2 + BRANCH_COUNT * BRANCH_LENGTH)) + ((GENERATED_ZONE_COUNT - 1) * TRANSITION_COLUMNS_BETWEEN_ZONES)
var min_nodes_per_column: int = 1
var max_nodes_per_column: int = BRANCH_COUNT
var nodes_per_column: Array[int] = []

const MINIBOSSES := [
	{"id": "integral_triple", "name": "Integral Triple"},
	{"id": "calculus", "name": "Calculus"},
	{"id": "calculadora_vieja", "name": "Calculadora vieja"},
]
const ZONE_2_ENEMIES := [
	{"id": "goblin_voltimetro", "name": "Goblin voltimetro"},
	{"id": "goblin_fisica_2", "name": "Goblin fisica 2"},
	{"id": "goblin_notebook_fisica_3", "name": "Goblin notebook fisica 3"},
]
const ZONE_3_ENCOUNTERS := [
	{"id": "robot_no_promocionar", "name": "Robot no promocionar"},
	{"id": "pingu_linux", "name": "Pingü Linux"},
	{"id": "torres_chica_media_chica", "name": "Torre chica / Torre media / Torre chica"},
	{"id": "torres_media_grande", "name": "Torre media / Torre grande"},
	{"id": "pingu_torre_chica", "name": "Pingü Linux / Torre chica"},
	{"id": "robot_torre_media", "name": "Robot no promocionar / Torre media"},
]
const ZONE_4_ENCOUNTERS := [
	{"id": "cigarro", "name": "Cigarro"},
	{"id": "dfd_diabolico", "name": "DFD Diabólico"},
	{"id": "pautas", "name": "Pautas"},
	{"id": "cigarro_cigarro", "name": "Cigarro / Cigarro"},
	{"id": "cigarro_cigarro_cigarro", "name": "Cigarro / Cigarro / Cigarro"},
	{"id": "dfd_diabolico_cigarro", "name": "DFD Diabólico / Cigarro"},
]
const INTERMEDIATE_RESOURCES := [
	"res://scripts/map/clase_interactiva.tres",
	"res://scripts/map/casilleros.tres",
	"res://scripts/map/kiosko.tres",
	"res://scripts/map/recreo.tres",
]
const COMBAT_RESOURCE_PATH := "res://scripts/map/clase_interactiva.tres"
const TRANSITION_RESOURCES := [
	"res://scripts/map/kiosko.tres",
	"res://scripts/map/recreo.tres",
]

@export var forced_miniboss_id := ""

var generated_nodes: Array = []
var connections: Array = []


func _init() -> void:
	for zone_index in range(GENERATED_ZONE_COUNT):
		nodes_per_column.append(1)
		for step_index in range(BRANCH_LENGTH):
			nodes_per_column.append(BRANCH_COUNT)
		nodes_per_column.append(1)
		if zone_index < GENERATED_ZONE_COUNT - 1:
			nodes_per_column.append_array([1, 1])


func generate_map() -> Dictionary:
	generated_nodes.clear()
	connections.clear()

	var previous_zone_exit_id: int = -1
	for zone_number in range(1, GENERATED_ZONE_COUNT + 1):
		var zone_start_column: int = get_zone_start_column(zone_number - 1)
		var zone_ids: Dictionary = generate_zone(zone_number, zone_start_column)

		if previous_zone_exit_id != -1:
			_add_connection(previous_zone_exit_id, int(zone_ids["miniboss_id"]))

		if zone_number < GENERATED_ZONE_COUNT:
			var transition_start_column: int = zone_start_column + COLUMNS_PER_ZONE
			previous_zone_exit_id = _add_zone_transition_nodes(int(zone_ids["boss_id"]), zone_number + 1, transition_start_column)
		else:
			previous_zone_exit_id = int(zone_ids["boss_id"])

	print("Mapa generado con ", generated_nodes.size(), " nodos y ", connections.size(), " conexiones.")
	return {"nodes": generated_nodes, "connections": connections, "version": MAP_VERSION}


func generate_zone(zone_index: int, start_column: int = 0) -> Dictionary:
	print("Generando zona %d" % zone_index)

	var selected_miniboss: Dictionary = _select_miniboss(zone_index)
	var main_row: float = _get_main_row()
	var selected_miniboss_name: String = String(selected_miniboss["name"])
	var selected_miniboss_id: String = String(selected_miniboss["id"])
	var miniboss_id: int = _add_node(start_column, main_row, load("res://scripts/map/examen_parcial.tres"), "miniboss", selected_miniboss_name, selected_miniboss_id, zone_index)
	print("Zona %d - Nodo inicial: Minijefe - %s" % [zone_index, selected_miniboss_name])

	var branch_end_ids: Array[int] = []
	for branch_index in range(BRANCH_COUNT):
		var previous_id := miniboss_id
		var forced_combat_step: int = randi() % BRANCH_LENGTH
		for step_index in range(BRANCH_LENGTH):
			var column: int = start_column + 1 + step_index
			var resource: nodo_mapa = _get_intermediate_resource_for_step(step_index, forced_combat_step)
			var combat_kind: String = "event"
			var encounter_name: String = resource.node_name
			var intermediate_enemy_id: String = ""
			if resource.type == nodo_mapa.NodeType.CLASE_INTERACTIVA:
				var enemy_data: Dictionary = _select_intermediate_enemy(zone_index)
				combat_kind = "intermediate"
				encounter_name = String(enemy_data["name"])
				intermediate_enemy_id = String(enemy_data["id"])

			var node_id: int = _add_node(column, branch_index, resource, combat_kind, encounter_name, intermediate_enemy_id, zone_index)
			_add_connection(previous_id, node_id)
			previous_id = node_id
			print("Zona %d - Rama %d Nodo %d: %s" % [
				zone_index,
				branch_index + 1,
				step_index + 1,
				_get_debug_node_label(generated_nodes[node_id]),
			])
		branch_end_ids.append(previous_id)

	var boss_name: String = _get_boss_name_for_zone(zone_index)
	var boss_id: int = _add_node(start_column + COLUMNS_PER_ZONE - 1, main_row, load("res://scripts/map/examen_final.tres"), "boss", boss_name, "", zone_index)
	for branch_end_id in branch_end_ids:
		_add_connection(branch_end_id, boss_id)

	print("Zona %d - Jefe de zona: %s" % [zone_index, boss_name])
	return {"miniboss_id": miniboss_id, "boss_id": boss_id}


static func get_zone_start_column(zone_zero_based_index: int) -> int:
	return zone_zero_based_index * (COLUMNS_PER_ZONE + TRANSITION_COLUMNS_BETWEEN_ZONES)


func _get_main_row() -> float:
	return CENTRAL_ROW


func _add_zone_transition_nodes(from_boss_id: int, next_zone_index: int, start_column: int) -> int:
	var previous_id: int = from_boss_id
	var transition_row: float = _get_main_row()
	for transition_index in range(TRANSITION_COLUMNS_BETWEEN_ZONES):
		var resource: nodo_mapa = _get_random_transition_resource()
		var node_id: int = _add_node(
			start_column + transition_index,
			transition_row,
			resource,
			"event",
			resource.node_name,
			"",
			next_zone_index
		)
		_add_connection(previous_id, node_id)
		previous_id = node_id
		print("Transicion hacia zona %d nodo %d: %s" % [next_zone_index, transition_index + 1, resource.node_name])

	return previous_id


func _add_node(column: int, row: float, resource: nodo_mapa, combat_kind: String, encounter_name: String = "", miniboss_id: String = "", zone_index: int = 1) -> int:
	var node_id := generated_nodes.size()
	generated_nodes.append({
		"id": node_id,
		"position": Vector2(column, row),
		"resource": resource,
		"connections": [],
		"combat_kind": combat_kind,
		"encounter_name": encounter_name,
		"miniboss_id": miniboss_id,
		"zone_index": zone_index,
	})
	return node_id


func _select_miniboss(zone_index: int) -> Dictionary:
	var enemy_pool := _get_enemy_pool_for_zone(zone_index)
	if not GameState.debug_forced_miniboss_id.is_empty():
		for miniboss in enemy_pool:
			if GameState.debug_forced_miniboss_id == miniboss["id"]:
				print("Minijefe seleccionado: %s" % miniboss["name"])
				return miniboss

	for miniboss in enemy_pool:
		if forced_miniboss_id == miniboss["id"]:
			print("Minijefe seleccionado: %s" % miniboss["name"])
			return miniboss

	var selected: Dictionary = enemy_pool[randi() % enemy_pool.size()]
	print("Minijefe seleccionado: %s" % selected["name"])
	return selected


func _select_intermediate_enemy(zone_index: int) -> Dictionary:
	var enemy_pool := _get_enemy_pool_for_zone(zone_index)
	return enemy_pool[randi() % enemy_pool.size()]


func _get_enemy_pool_for_zone(zone_index: int) -> Array:
	match zone_index:
		2:
			return ZONE_2_ENEMIES
		3:
			return ZONE_3_ENCOUNTERS
		4:
			return ZONE_4_ENCOUNTERS
		_:
			return MINIBOSSES


func _get_boss_name_for_zone(zone_index: int) -> String:
	match zone_index:
		2:
			return "Pepo"
		3:
			return "Tomás Khum"
		4:
			return "El Oni"
		_:
			return "Tom Apostol"


func _get_random_intermediate_resource() -> nodo_mapa:
	var resource_path: String = INTERMEDIATE_RESOURCES[randi() % INTERMEDIATE_RESOURCES.size()]
	return load(resource_path)


func _get_intermediate_resource_for_step(step_index: int, forced_combat_step: int) -> nodo_mapa:
	if step_index == forced_combat_step:
		return load(COMBAT_RESOURCE_PATH)
	return _get_random_intermediate_resource()


func _get_random_transition_resource() -> nodo_mapa:
	var resource_path: String = TRANSITION_RESOURCES[randi() % TRANSITION_RESOURCES.size()]
	return load(resource_path)


func _add_connection(from_id: int, to_id: int) -> void:
	connections.append([from_id, to_id])
	for node_data in generated_nodes:
		if node_data.id == from_id:
			node_data.connections.append(to_id)
			return


func _get_debug_node_label(node_data: Dictionary) -> String:
	match String(node_data.get("combat_kind", "")):
		"miniboss":
			return "Minijefe - %s" % node_data.get("encounter_name", "")
		"intermediate":
			return "Intermedio - %s" % node_data.get("encounter_name", "")
		"event":
			return "Nodo intermedio - %s" % node_data.get("encounter_name", "")
		"boss":
			return "Jefe de zona - %s" % node_data.get("encounter_name", "")
		_:
			var resource: nodo_mapa = node_data.resource
			return resource.node_name if resource != null else "Nodo intermedio"
