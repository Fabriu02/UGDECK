extends Control

# Referencias a tus nodos (asegúrate de que tengan el %)
@onready var casillero_img = %TextureRect
@onready var panel_premio = %PanelRecompensa
@onready var label_nombre_item = %"Artilugio nombre"
@onready var boton_equipar = %Equipar

# Configuración del botín
var item_aleatorio = "Calculadora Científica"
var plata_extra = 75

func _ready():
	# 1. Estado inicial: Ocultamos el premio y lo achicamos para el efecto "Pop"
	panel_premio.hide()
	panel_premio.scale = Vector2.ZERO
	
	# Centramos el punto de crecimiento (Pivot) para que el zoom sea desde el centro
	casillero_img.pivot_offset = casillero_img.size / 2
	panel_premio.pivot_offset = panel_premio.size / 2
	
	# Conectamos el botón
	boton_equipar.pressed.connect(_on_equipar_pressed)
	
	# 2. Iniciamos la secuencia cinematográfica
	_secuencia_apertura()

func _secuencia_apertura():
	# Creamos el animador (Tween)
	var tween = create_tween()
	
	# EFECTO 1: Zoom al casillero (se acerca a la cámara)
	# Lo agrandamos a 1.4 veces su tamaño en 1.2 segundos
	tween.tween_property(casillero_img, "scale", Vector2(1.4, 1.4), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# EFECTO 2: Cuando termina el zoom, aparece el cuadro de premio
	tween.tween_callback(_aparecer_cuadro_premio)

func _aparecer_cuadro_premio():
	# Seteamos los textos
	label_nombre_item.text = item_aleatorio
	panel_premio.show()
	
	# Animación de "Pop" con rebote
	var tween = create_tween()
	tween.tween_property(panel_premio, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_equipar_pressed():
	# Guardamos en el Autoload (GameState)
	GameState.dinero += plata_extra
	GameState.artilugios.append(item_aleatorio)
	
	print("¡Botín obtenido! Plata: ", GameState.dinero)
	
	# Volvemos al mapa
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
