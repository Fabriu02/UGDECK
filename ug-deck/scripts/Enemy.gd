extends Node
class_name Enemy

@export var max_hp: int = 50
@export var max_energy: int = 5

var current_hp: int
var current_energy: int
var block: int = 0
var attack_bonus: int = 0
var attack_bonus_turns: int = 0
var permanent_attack_bonus: int = 0
var professor_deck: Array[CardData] = []
var planned_card: CardData

# AGREGADO: Variable para guardar los estados (como "vulnerable")
var estados: Array = []

func _ready() -> void:
	reset_for_new_battle()

func reset_for_new_battle() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = 0
	attack_bonus = 0
	attack_bonus_turns = 0
	permanent_attack_bonus = 0
	planned_card = null
	# AGREGADO: Limpiamos los estados al iniciar una batalla
	estados.clear()


func set_professor_deck(cards: Array[CardData]) -> void:
	professor_deck = cards.duplicate()


func start_turn() -> void:
	current_energy = max_energy


func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false

	current_energy -= amount
	return true

# MODIFICADO: Ahora calcula si está vulnerable antes de restar la vida
func take_damage(amount: int) -> void:
	var daño_final := amount
	
	# AGREGADO: Si tiene el estado vulnerable, el daño aumenta un 50%
	if tiene_estado("vulnerable"):
		daño_final = int(daño_final * 1.5)
		
	var remaining_damage := daño_final

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)

# MODIFICADO: Agregada una 4ta opción al "dado" del enemigo
func choose_next_intent(player: Player, player_hand_size: int, player_cards_played_last_turn: int) -> void:
	if professor_deck.is_empty():
		planned_card = null
		return

	var candidates := _get_cards_with_cost_at_most(max_energy)
	if candidates.is_empty():
		candidates = professor_deck

	planned_card = candidates[randi() % candidates.size()]
	print("DEBUG Enemy: próxima intención '%s' (%s, coste %d). Mano jugador=%d, cartas turno anterior=%d" % [
		planned_card.card_name,
		planned_card.card_type,
		planned_card.cost,
		player_hand_size,
		player_cards_played_last_turn,
	])

# AGREGADO: Función para calcular el daño que hace el enemigo (aplicando debilidad)
func calcular_daño_enemigo(daño_base: int) -> int:
	var daño_final := float(daño_base + attack_bonus + permanent_attack_bonus)

	daño_final -= get_estado_total_valor("ataque_menos")
	
	# Si el enemigo tiene el estado "debil", hace 25% menos de daño
	if tiene_estado("debil"):
		daño_final *= 0.75

	if tiene_estado("distraccion"):
		daño_final *= 0.8
		
	return max(int(daño_final), 0)


func get_playable_card_for_turn(player: Player, player_hand_size: int, player_cards_played_last_turn: int) -> CardData:
	if planned_card != null and planned_card.cost <= current_energy:
		return planned_card

	var candidates := _get_cards_with_cost_at_most(current_energy)
	if candidates.is_empty():
		return null

	planned_card = candidates[randi() % candidates.size()]
	print("DEBUG Enemy: cambió intención a '%s' por energía insuficiente." % planned_card.card_name)
	return planned_card

# MODIFICADO: Texto para la interfaz (ahora muestra el daño reducido si está débil)
func get_intent_text(player: Player, player_hand_size: int, player_cards_played_last_turn: int) -> String:
	if planned_card == null:
		return "Intencion: Sin carta"

	var preview := _get_card_preview(planned_card, player, player_hand_size, player_cards_played_last_turn)
	return "Intencion: %s | %s" % [planned_card.card_name, preview]

func is_dead() -> bool:
	return current_hp <= 0


func gain_block(amount: int) -> void:
	block += amount


func gain_attack_bonus(amount: int, turns: int) -> void:
	attack_bonus += amount
	attack_bonus_turns = max(attack_bonus_turns, turns)


func gain_permanent_attack_bonus(amount: int) -> void:
	permanent_attack_bonus += amount


func remove_one_negative_state() -> bool:
	for index in range(estados.size()):
		var state_name: String = estados[index].nombre
		if state_name == "debil" or state_name == "vulnerable":
			estados.remove_at(index)
			return true
	return false

# NUEVAS FUNCIONES BÁSICAS: Para aplicar y consultar estados
func aplicar_estado(nombre: String, valor: int, duracion: int) -> void:
	estados.append({
		"nombre": nombre,
		"valor": valor,
		"duracion": duracion
	})

func tiene_estado(nombre: String) -> bool:
	for estado in estados:
		if estado.nombre == nombre:
			return true
	return false


func get_estado_total_valor(nombre: String) -> int:
	var total := 0
	for estado in estados:
		if estado.nombre == nombre:
			total += int(estado.valor)
	return total

func reducir_duracion_estados() -> void:
	if attack_bonus_turns > 0:
		attack_bonus_turns -= 1
		if attack_bonus_turns == 0:
			attack_bonus = 0

	for estado in estados:
		estado.duracion -= 1
		
	# Filtramos para quedarnos solo con los estados que aún tienen duración
	estados = estados.filter(func(estado): return estado.duracion > 0)


func _get_cards_with_cost_at_most(max_cost: int) -> Array[CardData]:
	var candidates: Array[CardData] = []
	for card in professor_deck:
		if card.cost <= max_cost:
			candidates.append(card)
	return candidates


func _get_card_preview(card: CardData, player: Player, player_hand_size: int, player_cards_played_last_turn: int) -> String:
	match card.effect_id:
		"pregunta_al_azar":
			var damage := 8
			if player_hand_size >= 3:
				damage += 4
			return "Ataque %d" % calcular_daño_enemigo(damage)
		"mirada_evaluadora":
			return "Aplica Estrés 1"
		"borrar_el_pizarron":
			return "Descarta 1 aleatoria"
		"eso_ya_lo_vimos":
			var damage := 10
			if player.block <= 0:
				damage += 3
			return "Ataque %d" % calcular_daño_enemigo(damage)
		"toma_asistencia":
			var shield := 8
			if player_cards_played_last_turn >= 3:
				shield += 5
			return "Escudo %d" % shield
		"cambiar_el_tema":
			return "Aplica Distracción 2"
		"parcialito_sorpresa":
			var damage := 14
			if player.has_negative_state():
				damage += 6
			return "Ataque %d" % calcular_daño_enemigo(damage)
		"criterio_estricto":
			return "Gana +4 ataque x2"
		"trabajo_practico_obligatorio":
			return "Primera carta +1 energía x2"
		"explicacion_confusa":
			return "Aplica Confusión 2"
		"unidad_acumulativa":
			return "Gana +2 ataque permanente"
		"parcial_integrador":
			var damage := 18
			if player_hand_size < 3:
				damage += 6
			return "Ataque %d" % calcular_daño_enemigo(damage)
		"correccion_en_rojo":
			return "Ataque %d + Estrés" % calcular_daño_enemigo(12)
		"recuperatorio_anunciado":
			return "Escudo 15 y limpia 1 debuff"
		"pregunta_capciosa":
			return "Descarta 2 o recibe 8"
		"bibliografia_extra":
			return "Roba -1 y skills +1 x2"
		"oral_individual":
			return "Ataque %d (ignora 50%% escudo)" % calcular_daño_enemigo(24)
		"cambio_de_consigna":
			return "Descarta mano y roba 3"
		"clase_de_repaso_mortal":
			return "+5 ataque y 10 escudo"
		"final_con_tribunal":
			return "Ataque %d + Estrés + Distracción" % calcular_daño_enemigo(30)
		_:
			return card.card_type
