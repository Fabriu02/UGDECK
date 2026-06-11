extends Control

# MODIFICADO: Ajustamos las rutas para que coincidan EXACTAMENTE con tu foto
@onready var volver_button: Button = $VolverButton
@onready var pantalla_button: CheckButton = $TextureRect2/CenterContainer/VBoxContainer/PantallaButton
@onready var volumen_slider: HSlider = $TextureRect2/CenterContainer/VBoxContainer/VolumenLabel/VolumenSlider

func _ready() -> void:
	# Conectamos las señales (cuando hacemos clic o movemos cosas)
	volver_button.pressed.connect(_on_volver_pressed)
	pantalla_button.toggled.connect(_on_pantalla_toggled)
	volumen_slider.value_changed.connect(_on_volumen_changed)
	
	# Chequear si el juego ya está en pantalla completa al abrir el menú
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	pantalla_button.button_pressed = is_fullscreen

	# AGREGADO: Chequear el volumen actual y actualizar la barrita
	var bus_index = AudioServer.get_bus_index("Master")
	var current_vol_db = AudioServer.get_bus_volume_db(bus_index)
	# set_value_no_signal cambia la barrita sin disparar el sonido de nuevo
	volumen_slider.set_value_no_signal(db_to_linear(current_vol_db))

func _on_volver_pressed() -> void:
	# Volvemos al menú principal
	SceneTransition.change_scene("res://scenes/menu/MainMenu.tscn")

func _on_pantalla_toggled(toggled_on: bool) -> void:
	# Cambia entre pantalla completa y modo ventana
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		# AGREGADO: Recuperamos la resolución original del proyecto
		var base_width = ProjectSettings.get_setting("display/window/size/viewport_width")
		var base_height = ProjectSettings.get_setting("display/window/size/viewport_height")
		var window_size = Vector2i(base_width, base_height)
		
		# Forzamos a la ventana a tomar ese tamaño exacto (chau barras grises)
		DisplayServer.window_set_size(window_size)
		
		# Centramos la ventana en el monitor
		var screen_id = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen_id)
		DisplayServer.window_set_position((screen_size - window_size) / 2)

func _on_volumen_changed(value: float) -> void:
	# Convierte el valor del slider (0.001 a 1.0) a decibelios para el motor de audio
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
