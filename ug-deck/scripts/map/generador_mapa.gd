class_name generador_mapa
extends Node

const GENERATED_ZONE_COUNT := 2
const COLUMNS_PER_ZONE := 5
const BRANCH_COUNT := 3
const BRANCH_LENGTH := 3
const MAP_VERSION := 4

var num_columns: int = GENERATED_ZONE_COUNT * COLUMNS_PER_ZONE
var total_nodes: int = GENERATED_ZONE_COUNT * (2 + BRANCH_COUNT * BRANCH_LENGTH)
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
const INTERMEDIATE_RESOURCES := [
	"res://scripts/map/clase_interactiva.tres",
	"res://scripts/map/casilleros.tres",
	"res://scripts/map/kiosko.tres",
	"res://scripts/map/recreo.tres",
]

@export var forced_miniboss_id := ""

var generated_nodes: Array = []
var connections: Array = []


func _init() -> void:
	for zone_index in range(GENERATED_ZONE_COUNT):
		nodes_per_column.append_array([1, 3, 3, 3, 1])


func generate_map() -> Dictionary:
	generated_nodes.clear()
	connections.clear()

	var previous_zone_boss_id := -1
	for zone_number in range(1, GENERATED_ZONE_COUNT + 1):
		var zone_start_column := (zone_number - 1) * COLUMNS_PER_ZONE
		var zone_ids := generate_zone(zone_number, zone_start_column)

		if previous_zone_boss_id != -1:
			_add_connection(previous_zone_boss_id, zone_ids["miniboss_id"])

		previous_zone_boss_id = zone_ids["boss_id"]

	print("Mapa generado con ", generated_nodes.size(), " nodos y ", connections.size(), " conexiones.")
	return {"nodes": generated_nodes, "connections": connections, "version": MAP_VERSION}


func generate_zone(zone_index: int, start_column: int = 0) -> Dictionary:
	print("Generando zona %d" % zone_index)

	var selected_miniboss := _select_miniboss(zone_index)
	var miniboss_id := _add_node(start_column, 1, load("res://scripts/map/examen_parcial.tres"), "miniboss", selected_miniboss["name"], selected_miniboss["id"], zone_index)
	print("Zona %d - Nodo inicial: Minijefe - %s" % [zone_index, selected_miniboss["name"]])

	var branch_end_ids: Array[int] = []
	for branch_index in range(BRANCH_COUNT):
		var previous_id := miniboss_id
		for step_index in range(BRANCH_LENGTH):
			var column := start_column + 1 + step_index
			var resource := _get_random_intermediate_resource()
			var combat_kind := "event"
			var encounter_name := resource.node_name
			var intermediate_enemy_id := ""
			if resource.type == nodo_mapa.NodeType.CLASE_INTERACTIVA:
				var enemy_data := _select_intermediate_enemy(zone_index)
				combat_kind = "intermediate"
				encounter_name = enemy_data["name"]
				intermediate_enemy_id = enemy_data["id"]

			var node_id := _add_node(column, branch_index, resource, combat_kind, encounter_name, intermediate_enemy_id, zone_index)
			_add_connection(previous_id, node_id)
			previous_id = node_id
			print("Zona %d - Rama %d Nodo %d: %s" % [
				zone_index,
				branch_index + 1,
				step_index + 1,
				_get_debug_node_label(generated_nodes[node_id]),
			])
		branch_end_ids.append(previous_id)

	var boss_name := "Tom Apostol" if zone_index == 1 else "Pepo"
	var boss_id := _add_node(start_column + COLUMNS_PER_ZONE - 1, 1, load("res://scripts/map/examen_final.tres"), "boss", boss_name, "", zone_index)
	for branch_end_id in branch_end_ids:
		_add_connection(branch_end_id, boss_id)

	print("Zona %d - Jefe de zona: %s" % [zone_index, boss_name])
	return {"miniboss_id": miniboss_id, "boss_id": boss_id}


func _add_node(column: int, row: int, resource: nodo_mapa, combat_kind: String, encounter_name: String = "", miniboss_id: String = "", zone_index: int = 1) -> int:
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
	return ZONE_2_ENEMIES if zone_index == 2 else MINIBOSSES


func _get_random_intermediate_resource() -> nodo_mapa:
	var resource_path: String = INTERMEDIATE_RESOURCES[randi() % INTERMEDIATE_RESOURCES.size()]
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
