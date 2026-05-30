extends Control

const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")
const CARD_SCENE := preload("res://scenes/Card.tscn")
const SHOP_CARD_COUNT := 3
const SHOP_REROLL_COST := 25
const CARD_REMOVAL_BASE_COST := 50
const CARD_REMOVAL_COST_STEP := 25

# Usamos % para que Godot los encuentre pase lo que pase
@onready var estante_items: GridContainer = %EstanteItems
@onready var botonvolver: Button = %Botonvolver
@onready var plata_ui: Label = %PlataUI

var shop_cards_container: HBoxContainer
var remove_cards_container: GridContainer
var remove_cost_label: Label
var reroll_button: Button
var items_column: VBoxContainer
var cards_column: VBoxContainer
var shop_cards: Array[CardData] = []

# Lista de lo que vendemos (Nombre, Precio)
var inventario = [
	{"nombre": "Café", "precio": 30},
	{"nombre": "Apunte", "precio": 80},
	{"nombre": "Resumen VIP", "precio": 200}
]

func _ready():
	botonvolver.text = "Salir"
	_preparar_layout_tienda()
	# 1. Conectamos el botón de volver
	botonvolver.pressed.connect(_on_boton_salir_pressed)
	
	# 2. Mostramos la plata que tiene el jugador (del Autoload GameState)
	_actualizar_plata()
	
	# 3. Llenamos el estante con los ítems
	_generar_items()
	_generar_tienda_cartas()


func _preparar_layout_tienda() -> void:
	var root_container := estante_items.get_parent()

	for child in root_container.get_children():
		if child is HSeparator:
			child.visible = false

	root_container.remove_child(estante_items)
	root_container.remove_child(plata_ui)
	root_container.remove_child(botonvolver)

	plata_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_container.add_child(plata_ui)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 28)
	root_container.add_child(columns)

	items_column = VBoxContainer.new()
	items_column.custom_minimum_size = Vector2(220, 0)
	items_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_column.add_theme_constant_override("separation", 8)
	columns.add_child(items_column)

	var items_title := Label.new()
	items_title.text = "Items"
	items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_column.add_child(items_title)

	estante_items.columns = 1
	items_column.add_child(estante_items)

	var separator := VSeparator.new()
	columns.add_child(separator)

	cards_column = VBoxContainer.new()
	cards_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_column.add_theme_constant_override("separation", 6)
	columns.add_child(cards_column)

	botonvolver.custom_minimum_size = Vector2(160, 36)
	botonvolver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_container.add_child(botonvolver)

func _actualizar_plata():
	# ¡Cambiamos dinero_label por plata_ui!
	plata_ui.text = "Tu Plata: $" + str(GameState.dinero)
	if reroll_button != null:
		reroll_button.disabled = GameState.dinero < SHOP_REROLL_COST
	if remove_cost_label != null:
		remove_cost_label.text = "Costo de eliminacion: $%d" % _get_remove_card_cost()

func _generar_items():
	# ¡Cambiamos contenedor_items por estante_items!
	for hijo in estante_items.get_children():
		hijo.queue_free()
		
	# Creamos un botón por cada ítem
	for item in inventario:
		var nuevo_boton = Button.new()
		nuevo_boton.text = item.nombre + "\n$" + str(item.precio)
		nuevo_boton.custom_minimum_size = Vector2(170, 54)
		
		# Programamos qué pasa al comprar
		nuevo_boton.pressed.connect(func(): _comprar(item, nuevo_boton))
		
		# ¡Cambiamos contenedor_items por estante_items!
		estante_items.add_child(nuevo_boton)

func _comprar(item, boton):
	if GameState.dinero >= item.precio:
		GameState.dinero -= item.precio
		_actualizar_plata()
		_refresh_remove_cards()
		_refresh_shop_cards()
		boton.disabled = true
		boton.text = "COMPRADO"
		print("Compraste ", item.nombre)
	else:
		print("No te alcanza la plata, buscate una beca.")

func _generar_tienda_cartas() -> void:
	GameState.ensure_run_deck_initialized()

	var root_container := cards_column

	var title := Label.new()
	title.text = "Cartas en venta"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_container.add_child(title)

	shop_cards_container = HBoxContainer.new()
	shop_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_cards_container.add_theme_constant_override("separation", 6)
	root_container.add_child(shop_cards_container)

	reroll_button = Button.new()
	reroll_button.text = "Reroll tienda ($%d)" % SHOP_REROLL_COST
	reroll_button.custom_minimum_size = Vector2(180, 38)
	reroll_button.pressed.connect(_on_reroll_pressed)
	root_container.add_child(reroll_button)

	var remove_title := Label.new()
	remove_title.text = "Eliminar carta del mazo"
	remove_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remove_title.add_theme_color_override("font_color", Color.BLACK)
	root_container.add_child(remove_title)

	remove_cost_label = Label.new()
	remove_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remove_cost_label.add_theme_color_override("font_color", Color.BLACK)
	root_container.add_child(remove_cost_label)

	var remove_scroll := ScrollContainer.new()
	remove_scroll.custom_minimum_size = Vector2(0, 86)
	remove_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_container.add_child(remove_scroll)

	remove_cards_container = GridContainer.new()
	remove_cards_container.columns = 2
	remove_scroll.add_child(remove_cards_container)

	_roll_shop_cards(false)
	_refresh_remove_cards()
	_actualizar_plata()


func _roll_shop_cards(charge_cost: bool) -> void:
	if charge_cost:
		if GameState.dinero < SHOP_REROLL_COST:
			print("No alcanza para rerollear la tienda.")
			return
		GameState.dinero -= SHOP_REROLL_COST
		print("Reroll tienda: -$%d" % SHOP_REROLL_COST)

	shop_cards = PlayerCardLoader.load_reward_options_by_rarities(_get_shop_rarities(), SHOP_CARD_COUNT)
	print("Cartas de tienda: %s" % _get_card_names(shop_cards))
	_refresh_shop_cards()
	_actualizar_plata()


func _refresh_shop_cards() -> void:
	for child in shop_cards_container.get_children():
		child.queue_free()

	for card_data in shop_cards:
		var card_ui: CardUI = CARD_SCENE.instantiate()
		shop_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		var price := _get_card_price(card_data)

		if not card_data.image_path.is_empty() and ResourceLoader.exists(card_data.image_path):
			# Con imagen: la carta se muestra como PNG, agregar etiqueta de precio encima
			card_ui.custom_minimum_size = Vector2(130, 130)
			card_ui.size = Vector2(130, 130)
			var price_label := Label.new()
			price_label.text = "$%d" % price
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			price_label.add_theme_font_size_override("font_size", 13)
			price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
			price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
			price_label.add_theme_constant_override("shadow_offset_x", 2)
			price_label.add_theme_constant_override("shadow_offset_y", 2)
			price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			price_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			price_label.offset_top = -28
			card_ui.add_child(price_label)
		else:
			# Sin imagen: layout de texto con nombre y precio
			card_ui.custom_minimum_size = Vector2(108, 156)
			card_ui.size = Vector2(108, 156)
			card_ui.name_label.add_theme_font_size_override("font_size", 9)
			card_ui.cost_label.add_theme_font_size_override("font_size", 8)
			card_ui.description_label.add_theme_font_size_override("font_size", 7)
			card_ui.get_node("MarginContainer/VBoxContainer/ArtFrame").custom_minimum_size = Vector2(0, 30)
			card_ui.name_label.text = "%s\n$%d" % [card_data.card_name, price]

		card_ui.disabled = GameState.dinero < price
		card_ui.card_clicked.connect(_on_shop_card_selected)


func _refresh_remove_cards() -> void:
	for child in remove_cards_container.get_children():
		child.queue_free()

	var unique_cards := GameState.get_unique_run_deck_cards()
	var copy_counts := GameState.get_run_deck_copy_counts()
	for card_data in unique_cards:
		var card_key := GameState.get_card_key(card_data)
		var button := Button.new()
		button.text = "%s x%d" % [card_data.card_name, int(copy_counts.get(card_key, 1))]
		button.custom_minimum_size = Vector2(150, 32)
		button.disabled = GameState.dinero < _get_remove_card_cost()
		button.pressed.connect(func(): _on_remove_card_selected(card_key))
		remove_cards_container.add_child(button)


func _on_shop_card_selected(card_data: CardData, card_ui: CardUI) -> void:
	var price := _get_card_price(card_data)
	if GameState.dinero < price:
		print("No alcanza para comprar carta: %s" % card_data.card_name)
		return

	GameState.dinero -= price
	GameState.add_card_to_run_deck(card_data)
	shop_cards.erase(card_data)
	print("Carta comprada en tienda: %s por $%d" % [card_data.card_name, price])
	card_ui.queue_free()
	_refresh_remove_cards()
	_refresh_shop_cards()
	_actualizar_plata()


func _on_remove_card_selected(card_key: String) -> void:
	var cost := _get_remove_card_cost()
	if GameState.dinero < cost:
		print("No alcanza para eliminar carta.")
		return

	if GameState.remove_card_from_run_deck(card_key):
		GameState.dinero -= cost
		GameState.shop_removal_count += 1
		print("Eliminacion de carta: -$%d" % cost)
	_refresh_remove_cards()
	_refresh_shop_cards()
	_actualizar_plata()


func _on_reroll_pressed() -> void:
	_roll_shop_cards(true)


func _get_shop_rarities() -> Array:
	var zone_index := GameState.get_current_zone_index()
	if zone_index >= 2:
		return ["Ingresante", "Recursante"]
	return ["Ingresante"]


func _get_remove_card_cost() -> int:
	return CARD_REMOVAL_BASE_COST + (GameState.shop_removal_count * CARD_REMOVAL_COST_STEP)


func _get_card_price(card_data: CardData) -> int:
	match card_data.rareza:
		"Recursante":
			return 85
		"Ingeniero":
			return 120
		_:
			return 60


func _get_card_names(cards: Array) -> String:
	var names: Array[String] = []
	for card_data in cards:
		names.append("%s (%s)" % [card_data.card_name, card_data.rareza])
	return ", ".join(names)

func _on_boton_salir_pressed():
	# Volvemos al mapa
	GameState.completar_nodo_actual()
	get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
