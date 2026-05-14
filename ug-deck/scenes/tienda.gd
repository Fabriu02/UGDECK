extends Control

# Usamos % para que Godot los encuentre pase lo que pase
@onready var estante_items: GridContainer = %EstanteItems
@onready var botonvolver: Button = %Botonvolver
@onready var plata_ui: Label = %PlataUI


# Lista de lo que vendemos (Nombre, Precio)
var inventario = [
	{"nombre": "Café", "precio": 30},
	{"nombre": "Apunte", "precio": 80},
	{"nombre": "Resumen VIP", "precio": 200}
]

func _ready():
	# 1. Conectamos el botón de volver
	botonvolver.pressed.connect(_on_boton_salir_pressed)
	
	# 2. Mostramos la plata que tiene el jugador (del Autoload GameState)
	_actualizar_plata()
	
	# 3. Llenamos el estante con los ítems
	_generar_items()

func _actualizar_plata():
	# ¡Cambiamos dinero_label por plata_ui!
	plata_ui.text = "Tu Plata: $" + str(GameState.dinero)

func _generar_items():
	# ¡Cambiamos contenedor_items por estante_items!
	for hijo in estante_items.get_children():
		hijo.queue_free()
		
	# Creamos un botón por cada ítem
	for item in inventario:
		var nuevo_boton = Button.new()
		nuevo_boton.text = item.nombre + "\n$" + str(item.precio)
		nuevo_boton.custom_minimum_size = Vector2(150, 80)
		
		# Programamos qué pasa al comprar
		nuevo_boton.pressed.connect(func(): _comprar(item, nuevo_boton))
		
		# ¡Cambiamos contenedor_items por estante_items!
		estante_items.add_child(nuevo_boton)

func _comprar(item, boton):
	if GameState.dinero >= item.precio:
		GameState.dinero -= item.precio
		_actualizar_plata()
		boton.disabled = true
		boton.text = "COMPRADO"
		print("Compraste ", item.nombre)
	else:
		print("No te alcanza la plata, buscate una beca.")

func _on_boton_salir_pressed():
	# Volvemos al mapa
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
