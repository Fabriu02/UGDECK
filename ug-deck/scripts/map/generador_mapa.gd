class_name generador_mapa
extends Node

# Configuración de la cuadrícula
var num_columns: int = 6
var total_nodes: int = 11
var min_nodes_per_column: int = 1
var max_nodes_per_column: int = 3
var nodes_per_column: Array[int] = [1, 2, 3, 2, 2, 1]

# Datos del mapa generado
var generated_nodes = [] # Lista de diccionarios {id, position, resource, connections}
var connections = [] # Lista de pares de IDs [id1, id2]

func generate_map():
	generated_nodes.clear()
	connections.clear()

	var node_id_counter = 0

	# PASO 1: Generar TODOS los nodos primero
	for col in range(num_columns):
		var num_nodes = nodes_per_column[col]

		for row in range(num_nodes):
			var node_data = {
				"id": node_id_counter,
				"position": Vector2(col, row), # Posición lógica
				"resource": _get_random_resource_for_column(col),
				"connections": []
			}
			generated_nodes.append(node_data)
			node_id_counter += 1

	# PASO 2: Conectarlos ahora que TODOS existen
	for col in range(num_columns - 1):
		_connect_columns(col)

	print("Mapa generado con ", generated_nodes.size(), " nodos y ", connections.size(), " conexiones.")
	return {"nodes": generated_nodes, "connections": connections}

# --- Funciones auxiliares de generación ---

func _connect_columns(col_index):
	var current_col_nodes = []
	var next_col_nodes = []

	# Agrupamos qué nodos están en la columna actual y cuáles en la siguiente
	for n in generated_nodes:
		if n.position.x == col_index:
			current_col_nodes.append(n)
		elif n.position.x == col_index + 1:
			next_col_nodes.append(n)

	# ALGORITMO SLAY THE SPIRE: Ordenar por "Y" (fila) para evitar líneas cruzadas
	current_col_nodes.sort_custom(func(a, b): return a.position.y < b.position.y)
	next_col_nodes.sort_custom(func(a, b): return a.position.y < b.position.y)

	var size_curr = current_col_nodes.size()
	var size_next = next_col_nodes.size()

	# Regla 1: Todo nodo de la columna actual DEBE conectarse hacia adelante
	for i in range(size_curr):
		var node_curr = current_col_nodes[i]

		# Calcular el nodo más "recto" hacia adelante
		var target_idx = 0
		if size_curr > 1 and size_next > 1:
			target_idx = int(round(float(i) / (size_curr - 1) * (size_next - 1)))
		elif size_next > 1:
			target_idx = randi() % size_next

		var target_node = next_col_nodes[target_idx]
		_add_connection(node_curr.id, target_node.id)

		# 30% de probabilidad de bifurcación (abrir un segundo camino)
		if randf() < 0.3 and size_next > 1:
			var offset = 1 if randf() > 0.5 else -1
			var alt_idx = clamp(target_idx + offset, 0, size_next - 1)
			if alt_idx != target_idx:
				_add_connection(node_curr.id, next_col_nodes[alt_idx].id)

	# Regla 2: Ningún nodo de la próxima columna puede quedar huérfano (sin conexión de entrada)
	for j in range(size_next):
		var target_node = next_col_nodes[j]
		if not _has_incoming_connection(target_node.id):
			# Si está huérfano, le tiramos un puente desde el nodo actual más cercano
			var closest_idx = 0
			if size_next > 1 and size_curr > 1:
				closest_idx = int(round(float(j) / (size_next - 1) * (size_curr - 1)))
			_add_connection(current_col_nodes[closest_idx].id, target_node.id)

# Función para añadir puentes y evitar duplicados
func _add_connection(from_id, to_id):
	for conn in connections:
		if conn[0] == from_id and conn[1] == to_id:
			return # Ya estaban conectados

	connections.append([from_id, to_id])
	for n in generated_nodes:
		if n.id == from_id:
			n.connections.append(to_id)

func _has_incoming_connection(target_id):
	for conn in connections:
		if conn[1] == target_id:
			return true
	return false

func _get_random_resource_for_column(col_index):
	# Columna 5 (Última): El Jefe final siempre va al final
	if col_index == num_columns - 1:
		return load("res://scripts/map/examen_final.tres")

	# Columnas 0 y 2: Siempre Combates (Clases Interactivas)
	if col_index == 0 or col_index == 2:
		return load("res://scripts/map/clase_interactiva.tres")

	# Columna 4: Siempre Recreo (La fogata obligatoria para curarse justo antes del Examen Final)
	if col_index == 4:
		return load("res://scripts/map/recreo.tres")

	# Columnas 1 y 3 (Las del medio): Sorteo entre Casillero, Kiosko o Recreo
	if col_index == 1 or col_index == 3:
		var r = randf()
		if r < 0.35:
			# ¡RUTA CORREGIDA AQUÍ!
			return load("res://scripts/map/casilleros.tres") # Casillero de Botín
		elif r < 0.70:
			return load("res://scripts/map/kiosko.tres")        # Tienda
		else:
			return load("res://scripts/map/recreo.tres")        # Recreo extra

	# Fallback por seguridad (si pasa algo raro, tira un combate)
	return load("res://scripts/map/clase_interactiva.tres")
