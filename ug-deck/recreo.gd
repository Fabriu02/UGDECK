extends Control

@onready var boton_descansar = %BotonDescansar
@onready var boton_repasar = %BotonRepasar
@onready var boton_volver = $Vuelta # Ya no lo necesitamos pulsar, pero lo dejamos por si las dudas

func _ready():
	# Nos aseguramos de ocultar el botón de vuelta físico si es que sigue existiendo
	if boton_volver:
		boton_volver.hide()
	
	# Conectamos las funciones a los TextureButtons
	boton_descansar.pressed.connect(_on_descansar_pressed)
	boton_repasar.pressed.connect(_on_repasar_pressed)

func _on_descansar_pressed():
	# 1. Calculamos el 30% de la vida máxima
	var curacion = int(GameState.vida_maxima * 0.3)
	GameState.vida_actual += curacion
	
	# 2. Nos aseguramos de no pasarnos del máximo de vida
	if GameState.vida_actual > GameState.vida_maxima:
		GameState.vida_actual = GameState.vida_maxima
		
	# LOG DE VERIFICACIÓN: Verás en la consola abajo cómo cambiaron tus estadísticas reales
	print("❤️ RECREO: ¡Descansaste! Vida guardada en GameState: ", GameState.vida_actual, "/", GameState.vida_maxima)
	
	# Efecto visual: Oscurecemos la opción que NO se eligió
	boton_repasar.modulate = Color(0.4, 0.4, 0.4, 1.0) 
	_terminar_recreo()

func _on_repasar_pressed():
	# 1. Aumentamos la estadística (Vida máxima +5 y le curamos esos 5 puntos extra)
	GameState.vida_maxima += 5
	GameState.vida_actual += 5 
	
	# LOG DE VERIFICACIÓN: Verás el cambio reflejado inmediatamente
	print("📚 RECREO: ¡Repasaste! Vida Máxima en GameState ahora es: ", GameState.vida_actual, "/", GameState.vida_maxima)
	
	# Efecto visual: Oscurecemos la opción que NO se eligió
	boton_descansar.modulate = Color(0.4, 0.4, 0.4, 1.0) 
	_terminar_recreo()

func _terminar_recreo():
	# Desactivamos ambos botones al instante para evitar que el jugador cliquee rápido y haga trampa
	boton_descansar.disabled = true
	boton_repasar.disabled = true
	
	# --- MAGIA AUTOMÁTICA ---
	print("⏳ Esperando un ratito antes de volver al mapa...")
	
	# Esperamos exactamente 1.5 segundos para que el jugador vea el cambio visual
	await get_tree().create_timer(1.5).timeout
	
	# Volvemos de forma automatizada
	GameState.completar_nodo_actual()
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
