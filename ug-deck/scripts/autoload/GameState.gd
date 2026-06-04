extends Node


const SAVE_FILE_PATH := "user://savegame.save"
const BASE_PLAYER_HP := 80
const BASE_PLAYER_ENERGY := 4

const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")
const ArtifactLoader := preload("res://scripts/ArtifactLoader.gd")

# --- DATOS DEL MAPA PROCEDURAL ---
var map_data: Dictionary = {}
var nodo_actual_id: int = -1
var nodos_completados: Array[int] = []
var dinero: int = 150
var artilugios: Array[String] = []
var vida_actual: int = BASE_PLAYER_HP
var vida_maxima: int = BASE_PLAYER_HP
var energia_maxima: int = BASE_PLAYER_ENERGY
var revive_artifact_used := false
var run_started: bool = false
var zona_actual: int = 1
var rareza_recompensa_actual: String = "Ingresante"
var jefe_zona_actual: String = "Tom Apostol"
var debug_forced_miniboss_id: String = ""
var run_deck: Array[CardData] = []
var run_deck_initialized := false
var shop_removal_count := 0
var temporary_energy_battles_remaining := 0
var clear_mind_pending := false
var INFO_ARTILUGIOS: Dictionary = ArtifactLoader.load_info_artilugios()


const INFO_ARTILUGIOS_LEGACY = {
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

func _load_artifact_info_catalog() -> Dictionary:
	var catalog: Dictionary = ArtifactLoader.load_info_artilugios()
	for artifact_name_variant in INFO_ARTILUGIOS_LEGACY.keys():
		var artifact_name: String = String(artifact_name_variant)
		if not catalog.has(artifact_name):
			catalog[artifact_name] = INFO_ARTILUGIOS_LEGACY[artifact_name]
	return catalog
	
func reset_run_progress() -> void:
	INFO_ARTILUGIOS = _load_artifact_info_catalog()
	map_data.clear()
	nodo_actual_id = -1
	nodos_completados.clear()
	dinero = 150
	artilugios.clear()
	vida_maxima = BASE_PLAYER_HP
	vida_actual = vida_maxima
	energia_maxima = BASE_PLAYER_ENERGY
	revive_artifact_used = false
	run_started = false
	zona_actual = 1
	rareza_recompensa_actual = "Ingresante"
	jefe_zona_actual = "Tom Apostol"
	debug_forced_miniboss_id = ""
	run_deck.clear()
	run_deck_initialized = false
	shop_removal_count = 0
	temporary_energy_battles_remaining = 0
	clear_mind_pending = false

func start_new_run() -> void:
	reset_run_progress()
	run_started = true
	ensure_run_deck_initialized()
	print("[RUN] Nueva run iniciada HP:", vida_actual, "/", vida_maxima)
	save_game()

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

func increase_max_energy(amount: int) -> void:
	energia_maxima = maxi(energia_maxima + amount, 1)

func add_artifact_to_run(artifact_name: String) -> bool:
	var clean_name: String = artifact_name.strip_edges()
	if clean_name.is_empty():
		return false

	if not artilugios.has(clean_name):
		artilugios.append(clean_name)

	if INFO_ARTILUGIOS.has(clean_name):
		var info: Dictionary = INFO_ARTILUGIOS[clean_name]
		if String(info.get("efecto", "")) == "revivir":
			revive_artifact_used = false
		if String(info.get("tipo", "")) == "inmediato":
			_apply_artifact_immediate_effect(clean_name, info)

	return true

func consume_artifact_revival() -> int:
	if revive_artifact_used:
		return 0

	for artifact_name: String in artilugios:
		if not INFO_ARTILUGIOS.has(artifact_name):
			continue

		var info: Dictionary = INFO_ARTILUGIOS[artifact_name]
		if String(info.get("efecto", "")) != "revivir":
			continue

		revive_artifact_used = true
		artilugios.erase(artifact_name)
		save_game()
		return int(info.get("valor", 10))

	return 0

func _apply_artifact_immediate_effect(artifact_name: String, info: Dictionary) -> void:
	var effect_id: String = String(info.get("efecto", ""))
	var value: int = int(info.get("valor", 0))
	match effect_id:
		"energia_max":
			increase_max_energy(value)
			if artifact_name == "Silla Rota del Aula":
				increase_max_hp(-5, false)
		"hp_max", "vida_max":
			increase_max_hp(value, true)
		"oro_inicial":
			dinero += value
		_:
			pass

func add_temporary_energy_battles(amount: int) -> void:
	temporary_energy_battles_remaining += maxi(amount, 0)
	save_game()

func consume_temporary_energy_bonus_for_combat() -> bool:
	if temporary_energy_battles_remaining <= 0:
		return false

	temporary_energy_battles_remaining -= 1
	save_game()
	return true

func activate_clear_mind_next_combat() -> void:
	clear_mind_pending = true
	save_game()

func consume_clear_mind_for_combat() -> bool:
	if not clear_mind_pending:
		return false

	clear_mind_pending = false
	save_game()
	return true

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
		
	save_game()

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

# --- LÓGICA DE GUARDADO ---
func save_game() -> void:
	if not run_started:
		return

	var saved_deck := []
	for card in run_deck:
		saved_deck.append(card.card_name)

	var data := {
		"map_data": map_data,
		"nodo_actual_id": nodo_actual_id,
		"nodos_completados": nodos_completados,
		"dinero": dinero,
		"artilugios": artilugios,
		"vida_actual": vida_actual,
		"vida_maxima": vida_maxima,
		"energia_maxima": energia_maxima,
		"revive_artifact_used": revive_artifact_used,
		"run_started": run_started,
		"zona_actual": zona_actual,
		"rareza_recompensa_actual": rareza_recompensa_actual,
		"jefe_zona_actual": jefe_zona_actual,
		"shop_removal_count": shop_removal_count,
		"temporary_energy_battles_remaining": temporary_energy_battles_remaining,
		"clear_mind_pending": clear_mind_pending,
		"run_deck": saved_deck
	}

	var save_string := var_to_str(data)
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(save_string)
		file.close()
		print("[SAVE] Partida guardada con éxito.")
	else:
		push_warning("[SAVE] No se pudo abrir el archivo para guardar.")


func load_game() -> bool:
	if not has_saved_game():
		return false

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var save_string := file.get_as_text()
	file.close()

	var data = str_to_var(save_string)
	if typeof(data) != TYPE_DICTIONARY:
		return false

	map_data = data.get("map_data", {})
	nodo_actual_id = int(data.get("nodo_actual_id", -1))
	
	# Convertir a Array[int]
	nodos_completados.clear()
	var saved_nodes = data.get("nodos_completados", [])
	for n in saved_nodes:
		nodos_completados.append(int(n))

	dinero = int(data.get("dinero", 0))
	
	# Convertir a Array[String]
	artilugios.clear()
	var saved_artilugios = data.get("artilugios", [])
	for a in saved_artilugios:
		artilugios.append(String(a))

	vida_actual = int(data.get("vida_actual", BASE_PLAYER_HP))
	vida_maxima = int(data.get("vida_maxima", BASE_PLAYER_HP))
	energia_maxima = int(data.get("energia_maxima", BASE_PLAYER_ENERGY))
	revive_artifact_used = bool(data.get("revive_artifact_used", false))
	run_started = bool(data.get("run_started", false))
	zona_actual = int(data.get("zona_actual", 1))
	rareza_recompensa_actual = String(data.get("rareza_recompensa_actual", "Ingresante"))
	jefe_zona_actual = String(data.get("jefe_zona_actual", ""))
	shop_removal_count = int(data.get("shop_removal_count", 0))
	temporary_energy_battles_remaining = int(data.get("temporary_energy_battles_remaining", 0))
	clear_mind_pending = bool(data.get("clear_mind_pending", false))

	# Reconstruir el mazo
	run_deck.clear()
	var saved_deck_names = data.get("run_deck", [])
	var all_cards = PlayerCardLoader.load_player_cards()
	
	for saved_name in saved_deck_names:
		for template in all_cards:
			if template.card_name == saved_name:
				run_deck.append(_copy_card(template))
				break
				
	run_deck_initialized = true

	print("[SAVE] Partida cargada con éxito. HP:", vida_actual, "/", vida_maxima)
	return true


func has_saved_game() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


func delete_saved_game() -> void:
	if has_saved_game():
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove("savegame.save")
			dir.remove("savegame.json") # Limpiar el archivo viejo por si acaso
			print("[SAVE] Archivo de guardado eliminado.")
