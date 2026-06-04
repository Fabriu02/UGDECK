extends Control

const ArtifactLoader := preload("res://scripts/ArtifactLoader.gd")

# --- TUS REFERENCIAS A LOS NODOS ---
@onready var casillero_img = %TextureRect
@onready var panel_premio = %PanelRecompensa
@onready var icono_item = %IconoItem
@onready var label_nombre_item = %"Artilugio nombre"
@onready var boton_equipar = %Equipar


# --- CATÁLOGO DE ARTILUGIOS DE ESTA SALA ---
var posibles_artilugios = [
	{
		"nombre": "Calculadora Científica", 
		"plata": 50, 
		"icono": preload("res://assets/iconos/Calculadora cientifica.png") # <-- ¡Cambia estas rutas por las de tus imágenes!
	},
	{
		"nombre": "Termo de Mate Supremo", 
		"plata": 25, 
		"icono": preload("res://assets/iconos/Termo_supremo.png")
	},
	{
		"nombre": "Apuntes de Años Anteriores", 
		"plata": 100, 
		"icono": preload("res://icon.svg")
	}
]

# Aquí se guardará el ganador del sorteo
var botin_elegido: ArtifactData = null
var label_descripcion_item: Label
var label_efecto_item: Label

func _ready():
	# 1. EL SORTEO
	botin_elegido = ArtifactLoader.load_locker_reward(GameState.artilugios)
	_setup_reward_detail_labels()
	
	# 2. PREPARAR LA UI
	panel_premio.hide()
	panel_premio.scale = Vector2.ZERO
	casillero_img.pivot_offset = casillero_img.size / 2
	panel_premio.pivot_offset = panel_premio.size / 2
	
	# 3. CONECTAR BOTONES
	boton_equipar.pressed.connect(_on_equipar_pressed)

	
	# 4. INICIAR ANIMACIÓN
	_secuencia_apertura()

func _setup_reward_detail_labels() -> void:
	var parent_box := label_nombre_item.get_parent()
	if parent_box == null:
		return

	label_descripcion_item = Label.new()
	label_descripcion_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_descripcion_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_descripcion_item.add_theme_color_override("font_color", Color.BLACK)
	label_descripcion_item.add_theme_font_size_override("font_size", 15)
	parent_box.add_child(label_descripcion_item)
	parent_box.move_child(label_descripcion_item, label_nombre_item.get_index() + 1)

	label_efecto_item = Label.new()
	label_efecto_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_efecto_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_efecto_item.add_theme_color_override("font_color", Color(0.08, 0.18, 0.28))
	label_efecto_item.add_theme_font_size_override("font_size", 14)
	parent_box.add_child(label_efecto_item)
	parent_box.move_child(label_efecto_item, label_descripcion_item.get_index() + 1)

func _secuencia_apertura():
	var tween = create_tween()
	tween.tween_property(casillero_img, "scale", Vector2(1.4, 1.4), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_mostrar_premio)

func _mostrar_premio_legacy():
	AudioManager.play_sfx("abrir_casillero")
	# Usamos los datos de botin_elegido para llenar el cartel
	label_nombre_item.text = botin_elegido.artifact_name + "\n+$" + str(botin_elegido.locker_gold)
	icono_item.texture = load(botin_elegido.icon_path)
	
	panel_premio.show()
	var tween = create_tween()
	tween.tween_property(panel_premio, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_equipar_pressed_legacy():
	# 1. Guardar en Autoload
	GameState.dinero += botin_elegido.locker_gold
	GameState.add_artifact_to_run(botin_elegido.artifact_name)
	
	print("Botin obtenido: ", botin_elegido.artifact_name, "! Plata total: ", GameState.dinero)
	
	# 2. Revisar si tiene efectos inmediatos
	if GameState.INFO_ARTILUGIOS.has(botin_elegido.artifact_name):
		var info_item = GameState.INFO_ARTILUGIOS[botin_elegido.artifact_name]
		if info_item.tipo == "inmediato":
			_aplicar_efecto_inmediato_legacy(info_item.efecto, info_item.valor)
	
	# 3. Bloquear el botón para no duplicar el premio
	boton_equipar.text = "¡RECLAMADO!"
	boton_equipar.disabled = true
	boton_equipar.modulate = Color(0.5, 1.0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	GameState.completar_nodo_actual()
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")


func _mostrar_premio() -> void:
	AudioManager.play_sfx("abrir_casillero")
	if botin_elegido == null:
		label_nombre_item.text = "Casillero vacio"
		boton_equipar.disabled = true
		panel_premio.show()
		return

	label_nombre_item.text = botin_elegido.artifact_name + "\n+$" + str(botin_elegido.locker_gold)
	icono_item.texture = load(botin_elegido.icon_path)
	if label_descripcion_item != null:
		label_descripcion_item.text = botin_elegido.description
	if label_efecto_item != null:
		label_efecto_item.text = "Efecto: %s" % botin_elegido.effect_id.replace("_", " ").capitalize()

	panel_premio.show()
	var tween := create_tween()
	tween.tween_property(panel_premio, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_equipar_pressed() -> void:
	if botin_elegido == null:
		return

	GameState.dinero += botin_elegido.locker_gold
	GameState.add_artifact_to_run(botin_elegido.artifact_name)
	print("Botin obtenido: ", botin_elegido.artifact_name, "! Plata total: ", GameState.dinero)

	boton_equipar.text = "RECLAMADO"
	boton_equipar.disabled = true
	boton_equipar.modulate = Color(0.5, 1.0, 0.5)
	GameState.save_game()

	await get_tree().create_timer(1.0).timeout
	GameState.completar_nodo_actual()
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")


func _aplicar_efecto_inmediato_legacy(efecto: String, valor: int):
	match efecto:
		"energia_max":
			if "energia_maxima" in GameState:
				GameState.energia_maxima += valor
				print(" EFECTO INMEDIATO: Tu energía máxima aumentó a ", GameState.energia_maxima)
		"vida_max":
			if "vida_maxima" in GameState:
				GameState.increase_max_hp(valor, false)
				print(" EFECTO INMEDIATO: Tu vida máxima aumentó a ", GameState.vida_maxima)
