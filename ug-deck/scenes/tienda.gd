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
var services_column: VBoxContainer
var remove_button: Button
var remove_panel: Panel
var panel_cards_container: GridContainer
var shop_cards: Array[CardData] = []

# Lista de lo que vendemos (Nombre, Precio)
var inventario = [
	{"nombre": "Termo de Mate Supremo", "precio": 120},
	{"nombre": "Apuntes de Años Anteriores", "precio": 150},
	{"nombre": "Calculadora Científica", "precio": 200}
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
	# Expandir el fondo para que haya más espacio y nada quede encimado
	var bg_rect = get_node("Fondo/NinePatchRect")
	if bg_rect:
		bg_rect.offset_top = -310
		bg_rect.offset_bottom = 350
		bg_rect.offset_left = -500
		bg_rect.offset_right = 500
		
	var margin_c = get_node("Fondo/NinePatchRect/MarginContainer")
	if margin_c:
		margin_c.add_theme_constant_override("margin_top", 170) # Aumentado para que "Cartas en venta" no se vaya tan arriba
		margin_c.add_theme_constant_override("margin_bottom", 20)
		margin_c.add_theme_constant_override("margin_left", 30)
		margin_c.add_theme_constant_override("margin_right", 30)

	var root_container := estante_items.get_parent()

	for child in root_container.get_children():
		if child is HSeparator:
			child.visible = false

	root_container.remove_child(estante_items)
	root_container.remove_child(plata_ui)
	root_container.remove_child(botonvolver)

	# --- TOP BAR GLOBAL (AFUERA DEL CUADRO) ---
	var margin_top = MarginContainer.new()
	margin_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin_top.add_theme_constant_override("margin_left", 40)
	margin_top.add_theme_constant_override("margin_top", 25)
	margin_top.add_theme_constant_override("margin_right", 40)
	self.add_child(margin_top)
	
	var global_top_bar = HBoxContainer.new()
	margin_top.add_child(global_top_bar)
	
	plata_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	plata_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plata_ui.add_theme_font_size_override("font_size", 32)
	plata_ui.add_theme_color_override("font_color", Color.WHITE)
	plata_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	plata_ui.add_theme_constant_override("outline_size", 8)
	global_top_bar.add_child(plata_ui)
	
	botonvolver.custom_minimum_size = Vector2(160, 50)
	botonvolver.size_flags_horizontal = Control.SIZE_SHRINK_END
	global_top_bar.add_child(botonvolver)

	# --- CARDS ROW (MIDDLE) ---
	cards_column = VBoxContainer.new()
	cards_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_column.add_theme_constant_override("separation", 10)
	root_container.add_child(cards_column)
	
	var sep2 = HSeparator.new()
	sep2.add_theme_constant_override("separation", 15)
	root_container.add_child(sep2)

	# --- BOTTOM ROW (ITEMS AND SERVICES) ---
	var bottom_row = HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 30)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root_container.add_child(bottom_row)

	items_column = VBoxContainer.new()
	items_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_column.add_theme_constant_override("separation", 5)
	bottom_row.add_child(items_column)

	var items_title := Label.new()
	items_title.text = "Items"
	items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_title.add_theme_color_override("font_color", Color.BLACK)
	items_column.add_child(items_title)

	estante_items.columns = 3 # 3 items en horizontal
	items_column.add_child(estante_items)

	var bottom_sep = VSeparator.new()
	bottom_row.add_child(bottom_sep)

	services_column = VBoxContainer.new()
	services_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	services_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	services_column.add_theme_constant_override("separation", 5)
	bottom_row.add_child(services_column)

func _actualizar_plata():
	# ¡Cambiamos dinero_label por plata_ui!
	plata_ui.text = "Tu Plata: $" + str(GameState.dinero)
	if reroll_button != null:
		reroll_button.disabled = GameState.dinero < SHOP_REROLL_COST
	_refresh_remove_button()

func _generar_items():
	for hijo in estante_items.get_children():
		hijo.queue_free()
		
	# Creamos un botón e imagen por cada ítem
	for item in inventario:
		var item_box = VBoxContainer.new()
		item_box.alignment = BoxContainer.ALIGNMENT_CENTER
		item_box.add_theme_constant_override("separation", 2)
		
		var tex_rect = TextureRect.new()
		var icon_path = "res://icon.svg"
		if GameState.INFO_ARTILUGIOS.has(item.nombre) and GameState.INFO_ARTILUGIOS[item.nombre].has("icono"):
			icon_path = GameState.INFO_ARTILUGIOS[item.nombre]["icono"]
			
		tex_rect.texture = load(icon_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(50, 50)
		item_box.add_child(tex_rect)
		
		var btn = Button.new()
		btn.text = "%s\n$%d" % [item.nombre, item.precio]
		btn.custom_minimum_size = Vector2(130, 60)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 11)
		
		btn.pressed.connect(func(): _comprar(item, btn, tex_rect))
		item_box.add_child(btn)
		
		estante_items.add_child(item_box)

func _comprar(item, boton, tex_rect):
	if GameState.dinero >= item.precio:
		AudioManager.play_sfx("comprar_item")
		GameState.dinero -= item.precio
		GameState.artilugios.append(item.nombre)
		
		if GameState.INFO_ARTILUGIOS.has(item.nombre):
			var info_item = GameState.INFO_ARTILUGIOS[item.nombre]
			if info_item.tipo == "inmediato":
				_aplicar_efecto_inmediato(info_item.efecto, info_item.valor)
				
		_actualizar_plata()
		_refresh_remove_button()
		_refresh_shop_cards()
		boton.disabled = true
		boton.text = "COMPRADO"
		tex_rect.modulate = Color(0.5, 0.5, 0.5)
		print("Compraste ", item.nombre)
		GameState.save_game()
	else:
		print("No te alcanza la plata, buscate una beca.")

func _aplicar_efecto_inmediato(efecto: String, valor: int):
	match efecto:
		"energia_max":
			if "energia_maxima" in GameState:
				GameState.energia_maxima += valor
				print("EFECTO INMEDIATO: Tu energía máxima aumentó a ", GameState.energia_maxima)
		"vida_max":
			if "vida_maxima" in GameState:
				GameState.increase_max_hp(valor, false)
				print("EFECTO INMEDIATO: Tu vida máxima aumentó a ", GameState.vida_maxima)

func _generar_tienda_cartas() -> void:
	GameState.ensure_run_deck_initialized()

	var root_container := cards_column

	var title := Label.new()
	title.text = "Cartas en venta"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.BLACK)
	root_container.add_child(title)

	shop_cards_container = HBoxContainer.new()
	shop_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_cards_container.add_theme_constant_override("separation", 15)
	root_container.add_child(shop_cards_container)

	# --- SERVICIOS ---
	var services_title := Label.new()
	services_title.text = "Servicios"
	services_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	services_title.add_theme_color_override("font_color", Color.BLACK)
	services_column.add_child(services_title)

	var services_hbox = HBoxContainer.new()
	services_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	services_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	services_hbox.add_theme_constant_override("separation", 20)
	services_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	services_column.add_child(services_hbox)

	var remove_col = VBoxContainer.new()
	remove_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_col.add_theme_constant_override("separation", 5)
	remove_col.alignment = BoxContainer.ALIGNMENT_CENTER
	services_hbox.add_child(remove_col)

	remove_button = Button.new()
	remove_button.custom_minimum_size = Vector2(120, 45)
	remove_button.pressed.connect(_show_remove_panel)
	remove_col.add_child(remove_button)

	reroll_button = Button.new()
	reroll_button.text = "Reroll\n($%d)" % SHOP_REROLL_COST
	reroll_button.custom_minimum_size = Vector2(100, 50)
	reroll_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	services_hbox.add_child(reroll_button)

	reroll_button.pressed.connect(_on_reroll_pressed)

	_build_remove_panel()
	_roll_shop_cards(false)
	_refresh_remove_button()
	_actualizar_plata()

func _build_remove_panel():
	remove_panel = Panel.new()
	remove_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	remove_panel.add_theme_stylebox_override("panel", style)
	remove_panel.visible = false
	self.add_child(remove_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	remove_panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Selecciona la carta que quieres eliminar"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(label)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 400)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(scroll)
	
	panel_cards_container = GridContainer.new()
	panel_cards_container.columns = 6
	panel_cards_container.add_theme_constant_override("h_separation", 15)
	panel_cards_container.add_theme_constant_override("v_separation", 15)
	scroll.add_child(panel_cards_container)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(200, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.pressed.connect(func(): remove_panel.visible = false)
	vbox.add_child(cancel_btn)

func _show_remove_panel():
	var cost := _get_remove_card_cost()
	if GameState.dinero < cost:
		return
		
	for child in panel_cards_container.get_children():
		child.queue_free()
		
	var deck_cards := GameState.get_run_deck_copies()
	for card_data in deck_cards:
		var card_ui: CardUI = CARD_SCENE.instantiate()
		card_ui.custom_minimum_size = Vector2(120, 168)
		panel_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.size = Vector2(120, 168)
		card_ui.card_clicked.connect(func(c_data, c_ui): _on_remove_card_selected(c_data))
		
	remove_panel.visible = true


func _roll_shop_cards(charge_cost: bool) -> void:
	if charge_cost:
		if GameState.dinero < SHOP_REROLL_COST:
			print("No alcanza para rerollear la tienda.")
			return
		AudioManager.play_sfx("comprar_item")
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


func _refresh_remove_button() -> void:
	if remove_button != null:
		var cost = _get_remove_card_cost()
		remove_button.text = "Eliminar Carta\n($%d)" % cost
		remove_button.disabled = GameState.dinero < cost

func _on_shop_card_selected(card_data: CardData, card_ui: CardUI) -> void:
	var price := _get_card_price(card_data)
	if GameState.dinero < price:
		print("No alcanza para comprar carta: %s" % card_data.card_name)
		return

	AudioManager.play_sfx("comprar_item")
	GameState.dinero -= price
	GameState.add_card_to_run_deck(card_data)
	shop_cards.erase(card_data)
	print("Carta comprada en tienda: %s por $%d" % [card_data.card_name, price])
	card_ui.queue_free()
	_refresh_remove_button()
	_refresh_shop_cards()
	_actualizar_plata()
	GameState.save_game()


func _on_remove_card_selected(card_data: CardData) -> void:
	var cost := _get_remove_card_cost()
	if GameState.dinero < cost:
		print("No alcanza para eliminar carta.")
		return

	var card_key = GameState.get_card_key(card_data)
	if GameState.remove_card_from_run_deck(card_key):
		AudioManager.play_sfx("comprar_item")
		GameState.dinero -= cost
		GameState.shop_removal_count += 1
		print("Eliminacion de carta: -$%d" % cost)
		
	if remove_panel != null:
		remove_panel.visible = false
		
	_refresh_remove_button()
	_refresh_shop_cards()
	_actualizar_plata()
	GameState.save_game()


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
