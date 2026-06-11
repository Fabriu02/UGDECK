extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/menu/MainMenu.tscn"

@export var map_node_scene: PackedScene = load("res://scenes/map/Boton.tscn")
@export var card_scene: PackedScene = load("res://scenes/Card.tscn")
@export var line_color: Color = Color.BLACK
@export var line_width: float = 1.0 # Líneas finas y elegantes
@onready var texto_vida = %TextoVida
@onready var texto_plata = %TextoPlata
@onready var contenedor_artilugios = %ContenedorArtilugios
@onready var ver_mazo_button: Button = %VerMazoButton
@onready var salir_menu_button: Button = %SalirMenuButton
@onready var exit_run_confirm_dialog: ConfirmationDialog = %ExitRunConfirmDialog
@onready var deck_viewer_panel: Panel = %DeckViewerPanel
@onready var deck_viewer_cards_container: GridContainer = %DeckViewerCardsContainer
@onready var close_deck_viewer_button: Button = %CloseDeckViewerButton
@export var x_spacing: float = 150.0
@export var y_spacing: float = 120.0
@export var map_offset: Vector2 = Vector2(100, 100)
const NORMAL_NODE_SIZE := Vector2(80, 80)
const FINAL_NODE_SIZE := Vector2(200, 200)
const ZONE_LABEL_SIZE := Vector2(180, 34)
const ZONE_LABEL_TOP_OFFSET := 52.0
const ZONE_SPRITE_BASE_PATH := "res://assets/backgrounds/sprites zonas"
const ZONE_ANIMATION_FRAME_DURATION := 0.12
const ZONE_ANIMATION_SIZE := Vector2(880, 495)
const ZONE_ANIMATION_TOP_OFFSET := 96.0

var map_data: Dictionary
var visual_nodes = {}
var zone_animation_rects: Array[TextureRect] = []
var zone_animation_frames: Array = []
var zone_animation_time: float = 0.0
var zone_animation_frame_index: int = 0

var nodo_actual_id: int = -1

# --- VARIABLES DE ZOOM ---
var zoom_actual: float = 1.0
var map_base_size: Vector2

func _ready():
	if not GameState.run_started or GameState.vida_actual <= 0:
		GameState.delete_saved_game()
		GameState.reset_run_progress()
		call_deferred("_return_to_main_menu")
		return

	# --- EL TRUCO MAGICO ---
	
	$ScrollContainer/contenidomapa.draw.connect(_on_contenidomapa_draw)
	ver_mazo_button.pressed.connect(_show_deck_viewer)
	salir_menu_button.pressed.connect(_on_salir_menu_pressed)
	exit_run_confirm_dialog.confirmed.connect(_on_exit_run_confirmed)
	close_deck_viewer_button.pressed.connect(_hide_deck_viewer)
	exit_run_confirm_dialog.get_ok_button().text = "Salir y perder progreso"
	exit_run_confirm_dialog.get_cancel_button().text = "Cancelar"

	# Le pedimos al Autoload que genere el mapa si no tiene uno
	var generator = generador_mapa.new()
	var current_nodes = GameState.map_data.get("nodes", [])
	var should_generate_map := GameState.map_data.is_empty()
	should_generate_map = should_generate_map or int(GameState.map_data.get("version", 0)) != generador_mapa.MAP_VERSION
	should_generate_map = should_generate_map or current_nodes.size() != generator.total_nodes
	should_generate_map = should_generate_map or _get_max_map_column(current_nodes) != generator.num_columns - 1
	if should_generate_map:
		GameState.map_data = generator.generate_map()
		GameState.nodo_actual_id = -1
		GameState.nodos_completados.clear()
		GameState.save_game()

	# Descargamos los datos guardados
	map_data = GameState.map_data
	nodo_actual_id = GameState.nodo_actual_id

	await get_tree().process_frame
	await _generate_and_visualize()
	await get_tree().process_frame
	_centrar_camara_en_nodo(GameState.nodo_actual_id)


func _process(delta: float) -> void:
	if zone_animation_rects.is_empty():
		return

	zone_animation_time += delta
	if zone_animation_time < ZONE_ANIMATION_FRAME_DURATION:
		return

	zone_animation_time = fmod(zone_animation_time, ZONE_ANIMATION_FRAME_DURATION)
	zone_animation_frame_index += 1

	for index in range(zone_animation_rects.size()):
		var frames: Array = zone_animation_frames[index]
		if frames.is_empty():
			continue

		zone_animation_rects[index].texture = frames[zone_animation_frame_index % frames.size()]

func _show_deck_viewer() -> void:
	for child in deck_viewer_cards_container.get_children():
		child.queue_free()

	var unique_cards := GameState.get_unique_run_deck_cards()
	print("Mostrando mazo desbloqueado: %d cartas unicas" % unique_cards.size())
	for card_data in unique_cards:
		var card_ui: CardUI = card_scene.instantiate()
		deck_viewer_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	deck_viewer_panel.visible = true


func _hide_deck_viewer() -> void:
	deck_viewer_panel.visible = false


func _on_salir_menu_pressed() -> void:
	exit_run_confirm_dialog.popup_centered()


func _on_exit_run_confirmed() -> void:
	GameState.delete_saved_game()
	GameState.reset_run_progress()
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _get_max_map_column(nodes: Array) -> int:
	var max_column = -1
	for node_data in nodes:
		max_column = max(max_column, int(node_data.position.x))
	return max_column

func _generate_and_visualize():
	# Solo creamos el generador para leer sus variables (num_columns),
	# ¡NO llamamos a generate_map() para no borrar el progreso!
	var generator = generador_mapa.new()
	map_offset = _get_centered_map_offset(generator)

	_add_zone_animations()
	_add_zone_labels()

	for node_data in map_data.nodes:
		var visual_node = map_node_scene.instantiate()
		$ScrollContainer/contenidomapa.add_child(visual_node)
		visual_node.set_anchors_preset(Control.PRESET_TOP_LEFT)

		var visual_pos = map_offset + Vector2(node_data.position.x * x_spacing, node_data.position.y * y_spacing)

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
			visual_node.custom_minimum_size = FINAL_NODE_SIZE
			visual_node.size = FINAL_NODE_SIZE

			# Corrección matemática para el centro
			visual_node.position -= Vector2(60, 60)

		else:
			# Materias normales
			visual_node.custom_minimum_size = NORMAL_NODE_SIZE
			visual_node.size = NORMAL_NODE_SIZE

		visual_nodes[node_data.id] = visual_node

	# Esperamos que los botones se acomoden y le pedimos al contenedor que pinte las líneas
	await get_tree().process_frame
	$ScrollContainer/contenidomapa.queue_redraw()

	# --- TAMAÑO AUTOMÁTICO Y BASE PARA EL ZOOM ---
	var viewport_size = $ScrollContainer.size
	var ancho_total = max(viewport_size.x, map_offset.x + ((generator.num_columns - 1) * x_spacing) + FINAL_NODE_SIZE.x)
	var alto_total = max(viewport_size.y, map_offset.y + ((generator.max_nodes_per_column - 1) * y_spacing) + FINAL_NODE_SIZE.y)

	# Guardamos el tamaño base para que la ruedita del ratón no lo rompa
	map_base_size = Vector2(ancho_total, alto_total)
	$ScrollContainer/contenidomapa.custom_minimum_size = map_base_size
	
	_actualizar_estado_visual()
	_actualizar_hud()
	

func _add_zone_animations() -> void:
	_clear_zone_animations()

	for zone_index in range(generador_mapa.GENERATED_ZONE_COUNT):
		var zone_number: int = zone_index + 1
		var frames: Array[Texture2D] = _load_zone_animation_frames(zone_number)
		if frames.is_empty():
			continue

		var start_column: int = generador_mapa.get_zone_start_column(zone_index)
		var end_column: int = start_column + generador_mapa.COLUMNS_PER_ZONE - 1
		var zone_center_x: float = map_offset.x + ((start_column + end_column) * 0.5 * x_spacing)
		var animation_rect: TextureRect = TextureRect.new()
		animation_rect.name = "Zone%dAnimation" % zone_number
		animation_rect.texture = frames[0]
		animation_rect.custom_minimum_size = ZONE_ANIMATION_SIZE
		animation_rect.size = ZONE_ANIMATION_SIZE
		animation_rect.position = Vector2(zone_center_x - (ZONE_ANIMATION_SIZE.x * 0.5), map_offset.y - ZONE_ANIMATION_TOP_OFFSET)
		animation_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		animation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		animation_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animation_rect.modulate = Color(1.0, 1.0, 1.0, 0.82)
		animation_rect.show_behind_parent = true
		animation_rect.z_index = -10
		$ScrollContainer/contenidomapa.add_child(animation_rect)
		zone_animation_rects.append(animation_rect)
		zone_animation_frames.append(frames)

	set_process(not zone_animation_rects.is_empty())


func _clear_zone_animations() -> void:
	for animation_rect in zone_animation_rects:
		if is_instance_valid(animation_rect):
			animation_rect.queue_free()

	zone_animation_rects.clear()
	zone_animation_frames.clear()
	zone_animation_time = 0.0
	zone_animation_frame_index = 0
	set_process(false)


func _load_zone_animation_frames(zone_number: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var zone_path: String = "%s/zona %d" % [ZONE_SPRITE_BASE_PATH, zone_number]
	var dir: DirAccess = DirAccess.open(zone_path)
	if dir == null:
		push_warning("No se encontro la carpeta de sprites para zona %d: %s" % [zone_number, zone_path])
		return frames

	var frame_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			frame_paths.append(zone_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	frame_paths.sort_custom(_compare_zone_sprite_paths)
	for frame_path in frame_paths:
		var texture_resource: Resource = load(frame_path)
		if texture_resource is Texture2D:
			frames.append(texture_resource as Texture2D)

	return frames


func _compare_zone_sprite_paths(a: String, b: String) -> bool:
	return _get_zone_sprite_number(a) < _get_zone_sprite_number(b)


func _get_zone_sprite_number(path: String) -> int:
	var base_name: String = path.get_file().get_basename()
	var sprite_marker_position: int = base_name.find("sprite")
	if sprite_marker_position == -1:
		return 0

	var number_text: String = base_name.substr(sprite_marker_position + "sprite".length()).strip_edges()
	return number_text.to_int()

func _add_zone_labels() -> void:
	for zone_index in range(generador_mapa.GENERATED_ZONE_COUNT):
		var label := Label.new()
		var start_column := generador_mapa.get_zone_start_column(zone_index)
		var end_column := start_column + generador_mapa.COLUMNS_PER_ZONE - 1
		var zone_center_x := map_offset.x + ((start_column + end_column) * 0.5 * x_spacing)

		label.text = "Zona %d" % (zone_index + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = ZONE_LABEL_SIZE
		label.size = ZONE_LABEL_SIZE
		label.position = Vector2(zone_center_x - (ZONE_LABEL_SIZE.x * 0.5), map_offset.y - ZONE_LABEL_TOP_OFFSET)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$ScrollContainer/contenidomapa.add_child(label)

	
func _actualizar_hud():
	# 1. Actualizamos los textos
	texto_vida.text = "Vida: " + str(GameState.vida_actual) + "/" + str(GameState.vida_maxima)
	texto_plata.text = "Plata: $" + str(GameState.dinero)
	
	# 2. Limpiamos los artilugios viejos por si volvemos de una pelea
	for hijo in contenedor_artilugios.get_children():
		hijo.queue_free()
		
	# 3. Creamos los iconos de los artilugios que tenemos en la mochila
	for nombre_artilugio in GameState.artilugios:
		if GameState.INFO_ARTILUGIOS.has(nombre_artilugio):
			var info = GameState.INFO_ARTILUGIOS[nombre_artilugio]
			
			if info.has("icono"):
				# Creamos un cuadradito de imagen por código
				var icono_rect = TextureRect.new()
				icono_rect.texture = load(info.icono) # Cargamos la imagen desde la ruta
				
				# Le damos tamaño fijo de 40x40 para que queden prolijos
				icono_rect.custom_minimum_size = Vector2(40, 40)
				icono_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icono_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				# Lo metemos en la barra
				contenedor_artilugios.add_child(icono_rect)
				

func _get_centered_map_offset(generator: generador_mapa) -> Vector2:
	var viewport_size = $ScrollContainer.size
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size

	var max_column := _get_max_map_column(map_data.nodes)
	var map_width = (max_column * x_spacing) + FINAL_NODE_SIZE.x - 60.0
	var map_height = ((generator.max_nodes_per_column - 1) * y_spacing) + FINAL_NODE_SIZE.y
	var x = max((viewport_size.x - map_width) / 2.0, 0.0)
	var y = max((viewport_size.y - map_height) / 2.0, 0.0) + 60.0

	return Vector2(x, y)

# --- FUNCIÓN QUE DIBUJA LAS LÍNEAS ---
func _on_contenidomapa_draw():
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
			print(" La materia '", resource.node_name, "' no tiene una escena asignada en su .tres")
			return

		# Guardamos en el Autoload que visitamos este nodo
		GameState.visitar_nodo(node_data.id)
		GameState.save_game()

		# Actualizamos nuestra variable local
		nodo_actual_id = GameState.nodo_actual_id

		print("El jugador fue exitosamente a: ", resource.node_name, "!")
		_actualizar_estado_visual()

		# --- EL TELETRANSPORTE ---
		get_tree().change_scene_to_packed(resource.escena_nivel)
	else:
		print(" Movimiento inválido.")

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
			boton.disabled = false
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

func _centrar_camara_en_nodo(node_id: int) -> void:
	var target_node_id = node_id
	
	# Si no hay nodo actual (-1), enfocamos al comienzo del mapa
	if target_node_id == -1 and not map_data.get("nodes", []).is_empty():
		for node in map_data.nodes:
			if node.position.x == 0:
				target_node_id = node.id
				break

	if not visual_nodes.has(target_node_id):
		return
		
	var boton = visual_nodes[target_node_id]
	var center_pos = boton.position + (boton.size / 2.0)
	var scroll = $ScrollContainer
	var half_screen = scroll.size / 2.0
	
	var target_scroll = (center_pos * zoom_actual) - half_screen
	
	scroll.scroll_horizontal = int(target_scroll.x)
	scroll.scroll_vertical = int(target_scroll.y)
