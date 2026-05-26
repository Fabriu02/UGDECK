extends Node

const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")

# --- DATOS DEL MAPA PROCEDURAL ---
var map_data: Dictionary = {}
var nodo_actual_id: int = -1
var nodos_completados: Array[int] = []
var dinero: int = 150
var artilugios: Array[String] = []
var vida_actual: int = 50
var vida_maxima: int = 50
var run_started: bool = false
var zona_actual: int = 1
var rareza_recompensa_actual: String = "Ingresante"
var jefe_zona_actual: String = "Tom Apostol"
var debug_forced_miniboss_id: String = ""
var run_deck: Array[CardData] = []
var run_deck_initialized := false
var shop_removal_count := 0


const INFO_ARTILUGIOS = {
	"Termo de Mate Supremo": {
		"tipo": "inmediato", 
		"efecto": "energia_max", 
		"valor": 2,
		"descripcion": "+2 de Energía Máxima permanentemente.",
		"icono": "res://assets/iconos/Termo_supremo.png"
		
	},
	"Apuntes de Años Anteriores": {
		"tipo": "inicio_combate", 
		"efecto": "escudo_inicial", 
		"valor": 15,
		"descripcion": "Empiezas cada examen (combate) con 15 de Escudo."
	},
	"Calculadora Científica": {
		"tipo": "pasivo_combate",
		"efecto": "costo_cero",
		"valor": 1,
		"descripcion": "La primera carta que juegas en cada combate cuesta 0.",
		"icono": "res://assets/iconos/Calculadora cientifica.png" #
	}
}
func _ready() -> void:
	reset_run_progress()
	
func reset_run_progress() -> void:
	map_data.clear()
	nodo_actual_id = -1
	nodos_completados.clear()
	dinero = 150
	artilugios.clear()
	vida_maxima = 50
	vida_actual = vida_maxima
	run_started = false
	zona_actual = 1
	rareza_recompensa_actual = "Ingresante"
	jefe_zona_actual = "Tom Apostol"
	debug_forced_miniboss_id = ""
	run_deck.clear()
	run_deck_initialized = false
	shop_removal_count = 0

func start_new_run() -> void:
	reset_run_progress()
	run_started = true
	print("[RUN] Nueva run iniciada HP:", vida_actual, "/", vida_maxima)

func set_player_hp(value: int) -> void:
	vida_actual = clamp(value, 0, vida_maxima)

func sync_player_hp(current_hp: int, max_hp: int) -> void:
	vida_maxima = max(max_hp, 1)
	set_player_hp(current_hp)

func damage_player(amount: int) -> void:
	set_player_hp(vida_actual - max(amount, 0))

func heal_player(amount: int) -> void:
	set_player_hp(vida_actual + max(amount, 0))

func increase_max_hp(amount: int, heal_too: bool = false) -> void:
	vida_maxima = max(vida_maxima + amount, 1)
	if heal_too:
		heal_player(amount)
	else:
		set_player_hp(vida_actual)

func ensure_run_deck_initialized() -> void:
	if run_deck_initialized:
		return

	run_deck = PlayerCardLoader.load_starting_run_cards()
	run_deck_initialized = true
	print("Mazo persistente de la run inicializado: %d cartas" % run_deck.size())

func get_run_deck_copies() -> Array[CardData]:
	ensure_run_deck_initialized()

	var cards: Array[CardData] = []
	for card in run_deck:
		cards.append(_copy_card(card))
	return cards

func get_unique_run_deck_cards() -> Array[CardData]:
	ensure_run_deck_initialized()

	var seen_cards := {}
	var unique_cards: Array[CardData] = []
	for card in run_deck:
		var card_key := card.effect_id
		if card_key.is_empty():
			card_key = card.card_name

		if seen_cards.has(card_key):
			continue

		seen_cards[card_key] = true
		unique_cards.append(_copy_card(card))

	return unique_cards

func get_run_deck_copy_counts() -> Dictionary:
	ensure_run_deck_initialized()

	var counts := {}
	for card in run_deck:
		var card_key := get_card_key(card)
		counts[card_key] = int(counts.get(card_key, 0)) + 1

	return counts

func get_card_key(card: CardData) -> String:
	if not card.effect_id.is_empty():
		return card.effect_id
	return card.card_name

func add_card_to_run_deck(card: CardData) -> void:
	ensure_run_deck_initialized()
	run_deck.append(_copy_card(card))
	print("Carta agregada al mazo de la run")
	print("Tamaño actual del mazo de la run: %d" % run_deck.size())

func remove_card_from_run_deck(card_key: String) -> bool:
	ensure_run_deck_initialized()

	for index in range(run_deck.size()):
		if get_card_key(run_deck[index]) == card_key:
			print("Carta eliminada del mazo de la run: %s" % run_deck[index].card_name)
			run_deck.remove_at(index)
			print("Tamaño actual del mazo de la run: %d" % run_deck.size())
			return true

	return false

func visitar_nodo(node_id: int) -> void:
	if not _is_known_node(node_id):
		push_warning("Intento de visitar un nodo desconocido: %s" % node_id)
		return

	nodo_actual_id = node_id

func completar_nodo_actual() -> void:
	if nodo_actual_id == -1:
		return

	if not nodos_completados.has(nodo_actual_id):
		nodos_completados.append(nodo_actual_id)

func get_current_node_data() -> Dictionary:
	return get_node_data(nodo_actual_id)

func get_node_data(node_id: int) -> Dictionary:
	if map_data.is_empty():
		return {}

	for n in map_data.nodes:
		if n.id == node_id:
			return n

	return {}

func get_current_miniboss_id() -> String:
	var node_data := get_current_node_data()
	return String(node_data.get("miniboss_id", ""))

func get_current_combat_kind() -> String:
	var node_data := get_current_node_data()
	return String(node_data.get("combat_kind", "normal"))

func get_current_zone_index() -> int:
	var node_data := get_current_node_data()
	return int(node_data.get("zone_index", zona_actual))

func volver_al_primer_nodo() -> void:
	nodos_completados.clear()
	nodo_actual_id = _get_first_node_id()

func is_node_unlocked(node_id: int) -> bool:
	if map_data.is_empty():
		return false

	if nodo_actual_id == -1:
		for n in map_data.nodes:
			if n.id == node_id and n.position.x == 0:
				return true
		return false

	if node_id == nodo_actual_id and not is_node_completed(node_id):
		return true

	if not is_node_completed(nodo_actual_id):
		return false

	for conn in map_data.connections:
		if conn[0] == nodo_actual_id and conn[1] == node_id:
			return true

	return false

func is_node_completed(node_id: int) -> bool:
	return nodos_completados.has(node_id)

func _is_known_node(node_id: int) -> bool:
	if map_data.is_empty():
		return false

	for n in map_data.nodes:
		if n.id == node_id:
			return true

	return false

func _get_first_node_id() -> int:
	if map_data.is_empty():
		return -1

	var first_node_id := -1
	var first_column := INF
	for n in map_data.nodes:
		if n.position.x < first_column:
			first_column = n.position.x
			first_node_id = n.id

	return first_node_id

func _copy_card(card: CardData) -> CardData:
	return CardData.new().setup(
		card.card_name,
		card.cost,
		card.card_type,
		card.value,
		card.description,
		card.effect_id,
		card.rareza,
		card.raw_effect_text,
		card.image_path
	)
	
	
# --- MODO DESARROLLADOR: GANAR Y SALTAR NIVEL ---
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		var escena_actual = get_tree().current_scene.name
		if escena_actual != "VistaMapa" and escena_actual != "vista_mapa":
			print("⏭️ ¡Nivel saltado y GANADO por el desarrollador!")
			
			# 1. LE DECIMOS AL JUEGO QUE GANAMOS:
			# Si estamos en un nodo válido, lo metemos en la lista de completados
			if nodo_actual_id != -1:
				if not nodos_completados.has(nodo_actual_id):
					nodos_completados.append(nodo_actual_id)
			
			# 2. Volvemos al mapa
			get_tree().change_scene_to_file("res://scenes/map/vista_mapa.tscn")
