extends Control

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
var botin_elegido = {}

func _ready():
	# 1. EL SORTEO
	botin_elegido = posibles_artilugios.pick_random()
	
	# 2. PREPARAR LA UI
	panel_premio.hide()
	panel_premio.scale = Vector2.ZERO
	casillero_img.pivot_offset = casillero_img.size / 2
	panel_premio.pivot_offset = panel_premio.size / 2
	
	# 3. CONECTAR BOTONES
	boton_equipar.pressed.connect(_on_equipar_pressed)

	
	# 4. INICIAR ANIMACIÓN
	_secuencia_apertura()

func _secuencia_apertura():
	var tween = create_tween()
	tween.tween_property(casillero_img, "scale", Vector2(1.4, 1.4), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_mostrar_premio)

func _mostrar_premio():
	# Usamos los datos de botin_elegido para llenar el cartel
	label_nombre_item.text = botin_elegido.nombre + "\n+$" + str(botin_elegido.plata)
	icono_item.texture = botin_elegido.icono
	
	panel_premio.show()
	var tween = create_tween()
	tween.tween_property(panel_premio, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_equipar_pressed():
	# 1. Guardar en Autoload
	GameState.dinero += botin_elegido.plata
	GameState.artilugios.append(botin_elegido.nombre)
	
	print("¡Botín obtenido: ", botin_elegido.nombre, "! Plata total: ", GameState.dinero)
	
	# 2. Revisar si tiene efectos inmediatos
	if GameState.INFO_ARTILUGIOS.has(botin_elegido.nombre):
		var info_item = GameState.INFO_ARTILUGIOS[botin_elegido.nombre]
		if info_item.tipo == "inmediato":
			_aplicar_efecto_inmediato(info_item.efecto, info_item.valor)
	
	# 3. Bloquear el botón para no duplicar el premio
	boton_equipar.text = "¡RECLAMADO!"
	boton_equipar.disabled = true
	boton_equipar.modulate = Color(0.5, 1.0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	GameState.completar_nodo_actual()
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")


func _aplicar_efecto_inmediato(efecto: String, valor: int):
	match efecto:
		"energia_max":
			if "energia_maxima" in GameState:
				GameState.energia_maxima += valor
				print(" EFECTO INMEDIATO: Tu energía máxima aumentó a ", GameState.energia_maxima)
		"vida_max":
			if "vida_maxima" in GameState:
				GameState.vida_maxima += valor
				print(" EFECTO INMEDIATO: Tu vida máxima aumentó a ", GameState.vida_maxima)
