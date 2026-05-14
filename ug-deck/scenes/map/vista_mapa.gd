extends Control

@export var map_node_scene: PackedScene = load("res://scenes/map/Boton.tscn")
@export var line_color: Color = Color.BLACK
@export var line_width: float = 1.0 # Líneas finas y elegantes

@export var x_spacing: float = 150.0
@export var y_spacing: float = 120.0
@export var map_offset: Vector2 = Vector2(100, 100)

var map_data: Dictionary
var visual_nodes = {}

var nodo_actual_id: int = -1

# --- VARIABLES DE ZOOM ---
var zoom_actual: float = 1.0
var map_base_size: Vector2

func _ready():
	# --- EL TRUCO MAGICO ---
	$ScrollContainer/contenidomapa.draw.connect(_on_contenidomapa_draw)

	# Le pedimos al Autoload que genere el mapa si no tiene uno
	if GameState.map_data.is_empty():
		var generator = generador_mapa.new()
		GameState.map_data = generator.generate_map()

	# Descargamos los datos guardados
	map_data = GameState.map_data
	nodo_actual_id = GameState.nodo_actual_id

	_generate_and_visualize()

func _generate_and_visualize():
	# Solo creamos el generador para leer sus variables (num_columns),
	# ¡NO llamamos a generate_map() para no borrar el progreso!
	var generator = generador_mapa.new()

	for node_data in map_data.nodes:
		var visual_node = map_node_scene.instantiate()
		$ScrollContainer/contenidomapa.add_child(visual_node)

		var visual_pos = map_offset + Vector2(node_data.position.x * x_spacing, node_data.position.y * y_spacing)

		var nodes_in_col = 0
		for n in map_data.nodes:
			if n.position.x == node_data.position.x: nodes_in_col += 1

		visual_pos.y += (generator.max_nodes_per_column - nodes_in_col) * y_spacing / 2.0

		visual_node.position = visual_pos
		visual_node.setup(node_data)
		visual_node.node_clicked.connect(_on_node_clicked)

		# --- TRAMPA PARA DETECTAR EL ERROR ---
		if node_data.resource.icon == null:
			print(" ERROOOR La materia '", node_data.resource.node_name, "' no tiene ninguna imagen asignada en su archivo .tres , cargala boludo.")

		# --- FUERZA BRUTA: TAMAÑOS DINÁMICOS ---
		visual_node.ignore_texture_size = true
		visual_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Si es la última columna (el Jefe / Examen Final)
		if node_data.position.x == generator.num_columns - 1:
			visual_node.custom_minimum_size = Vector2(200, 200) # ¡MÁS GIGANTE!
			visual_node.size = Vector2(200, 200)

			# Corrección matemática para el centro
			visual_node.position -= Vector2(60, 60)

		else:
			# Materias normales
			visual_node.custom_minimum_size = Vector2(80, 80)
			visual_node.size = Vector2(80, 80)

		visual_nodes[node_data.id] = visual_node

	# Esperamos que los botones se acomoden y le pedimos al contenedor que pinte las líneas
	await get_tree().process_frame
	$ScrollContainer/contenidomapa.queue_redraw()

	# --- TAMAÑO AUTOMÁTICO Y BASE PARA EL ZOOM ---
	var ancho_total = map_offset.x + (generator.num_columns * x_spacing) + 200 # 200 de margen derecho
	var alto_total = map_offset.y + (generator.max_nodes_per_column * y_spacing) + 200 # Margen inferior

	# Guardamos el tamaño base para que la ruedita del ratón no lo rompa
	map_base_size = Vector2(ancho_total, alto_total)
	$ScrollContainer/contenidomapa.custom_minimum_size = map_base_size

	_actualizar_estado_visual()

# --- FUNCIÓN QUE DIBUJA LAS LÍNEAS ---
func _on_contenidomapa_draw():
	print("Intentando dibujar ", map_data.connections.size(), " líneas de conexión.")

	for conn in map_data.connections:
		if not visual_nodes.has(conn[0]) or not visual_nodes.has(conn[1]):
			continue

		var start_node = visual_nodes[conn[0]]
		var end_node = visual_nodes[conn[1]]

		# --- EL TRUCO PARA CENTRAR ---
		var offset_start = start_node.size / 2.0
		if offset_start == Vector2.ZERO:
			offset_start = start_node.custom_minimum_size / 2.0
			if offset_start == Vector2.ZERO:
				offset_start = Vector2(40, 40)

		var offset_end = end_node.size / 2.0
		if offset_end == Vector2.ZERO:
			offset_end = end_node.custom_minimum_size / 2.0
			if offset_end == Vector2.ZERO:
				offset_end = Vector2(40, 40)

		var start_pos = start_node.position + offset_start
		var end_pos = end_node.position + offset_end

		$ScrollContainer/contenidomapa.draw_line(start_pos, end_pos, line_color, line_width, true)

func _on_node_clicked(node_data):
	# Le preguntamos al Autoload si el movimiento es válido
	if GameState.is_node_unlocked(node_data.id):
		var resource: nodo_mapa = node_data.resource
		if resource.escena_nivel == null:
			print("⚠️ La materia '", resource.node_name, "' no tiene una escena asignada en su .tres")
			return

		# Guardamos en el Autoload que visitamos este nodo
		GameState.visitar_nodo(node_data.id)

		# Actualizamos nuestra variable local
		nodo_actual_id = GameState.nodo_actual_id

		print("✅ El jugador fue exitosamente a: ", resource.node_name, "!")
		_actualizar_estado_visual()

		# --- EL TELETRANSPORTE ---
		get_tree().change_scene_to_packed(resource.escena_nivel)
	else:
		print("❌ Movimiento inválido.")

func _actualizar_estado_visual():
	for id in visual_nodes:
		var boton = visual_nodes[id]
		var data_del_boton = boton.node_data

		boton.disabled = true

		if GameState.is_node_completed(data_del_boton.id):
			# Nodos ya completados (quedan oscuros)
			boton.modulate = Color(0.3, 0.3, 0.3, 1.0)
		elif data_del_boton.id == nodo_actual_id:
			# Nodo actual en el que estamos parados (brilla verde)
			boton.modulate = Color(0.8, 1.0, 0.8, 1.0)
		elif GameState.is_node_unlocked(data_del_boton.id):
			# Nodos a los que podemos viajar (color normal y clic habilitado)
			boton.disabled = false
			boton.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			# Nodos futuros bloqueados (grises y apagados)
			boton.modulate = Color(0.5, 0.5, 0.5, 1.0)

# --- SISTEMA DE ZOOM ---
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_aplicar_zoom(0.1) # Acercar (+10%)
			get_viewport().set_input_as_handled() # Evita scroll vertical accidental
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_aplicar_zoom(-0.1) # Alejar (-10%)
			get_viewport().set_input_as_handled()

func _aplicar_zoom(cambio: float):
	var viejo_zoom = zoom_actual
	zoom_actual = clamp(zoom_actual + cambio, 0.5, 1.5)

	if zoom_actual != viejo_zoom:
		$ScrollContainer/contenidomapa.scale = Vector2(zoom_actual, zoom_actual)
		$ScrollContainer/contenidomapa.custom_minimum_size = map_base_size * zoom_actual
