extends Node
class_name Enemy

const EnemyCardLoader := preload("res://scripts/EnemyCardLoader.gd")
const LETHAL_PRIORITY_BONUS := 9999
const FINISHER_LOW_HP_BONUS := 60
const FINISHER_VULNERABLE_BONUS := 25
const ENEMY_ID_EL_ONI := "el_oni"

@export var max_hp: int = 50
@export var max_energy: int = 5
@export var base_block: int = 0
@export var debug_enemy_ai := true

var current_hp: int
var current_energy: int
var block: int = 0
var attack_bonus: int = 0
var attack_bonus_turns: int = 0
var permanent_attack_bonus: int = 0
var professor_deck: Array[CardData] = []
var planned_card: CardData
var next_intent_card: CardData
var next_intent_type: String = ""
var next_intent_value: int = 0
var next_intent_text: String = ""
var turn_count: int = 0
var last_card_type: String = ""
var last_card_name: String = ""
var last_intent_was_strong_attack := false
var last_intent_was_control_or_debuff := false
var allowed_enemy_archetypes: Array[String] = []
var enemy_debug_name: String = ""
var enemy_debug_id: String = ""
var enemy_debug_archetypes: Array[String] = []
var enemy_debug_zone_index: int = 1
var enemy_debug_rarities: Array[String] = []

# AGREGADO: Variable para guardar los estados (como "vulnerable")
var estados: Array = []

func _ready() -> void:
	reset_for_new_battle()

func reset_for_new_battle() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = base_block
	attack_bonus = 0
	attack_bonus_turns = 0
	permanent_attack_bonus = 0
	planned_card = null
	next_intent_card = null
	next_intent_type = ""
	next_intent_value = 0
	next_intent_text = ""
	turn_count = 0
	last_card_type = ""
	last_card_name = ""
	last_intent_was_strong_attack = false
	last_intent_was_control_or_debuff = false
	# AGREGADO: Limpiamos los estados al iniciar una batalla
	estados.clear()


func set_professor_deck(
	cards: Array[CardData],
	enemy_archetypes: Array = [],
	debug_name: String = "",
	zone_index: int = 1,
	allowed_rarities: Array = [],
	enemy_id: String = ""
) -> void:
	professor_deck = cards.duplicate()
	enemy_debug_name = debug_name
	enemy_debug_id = enemy_id
	enemy_debug_zone_index = zone_index
	allowed_enemy_archetypes.clear()
	enemy_debug_archetypes.clear()
	enemy_debug_rarities.clear()
	for archetype in enemy_archetypes:
		var archetype_text := String(archetype)
		var normalized_archetype := EnemyCardLoader._normalize_text(String(archetype))
		if not normalized_archetype.is_empty() and not allowed_enemy_archetypes.has(normalized_archetype):
			allowed_enemy_archetypes.append(normalized_archetype)
			enemy_debug_archetypes.append(archetype_text)
	for rarity in allowed_rarities:
		enemy_debug_rarities.append(String(rarity))

	var names: Array[String] = []
	for card in professor_deck:
		names.append(card.card_name)
	_debug_ai("Pool final %d cartas | Rarezas: %s | Arquetipos: %s | Cartas: %s" % [
		professor_deck.size(),
		", ".join(enemy_debug_rarities),
		", ".join(enemy_debug_archetypes),
		", ".join(names),
	])


func start_turn() -> void:
	current_energy = max_energy


func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false

	current_energy -= amount
	return true

# MODIFICADO: Ahora calcula si está vulnerable antes de restar la vida
func take_damage(amount: int) -> void:
	var dano_final := amount
	
	# AGREGADO: Si tiene el estado vulnerable, el daño aumenta un 50%
	if tiene_estado("vulnerable"):
		dano_final = int(dano_final * 1.5)
		
	var remaining_damage := dano_final

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)

# La intención se decide por score y se ejecuta recién en el turno enemigo.
func choose_next_intent(player: Player, player_hand_size: int, player_cards_played_last_turn: int, zone_index: int = 1, group_context: Dictionary = {}) -> void:
	_choose_next_intent_by_score(player, player_hand_size, player_cards_played_last_turn, zone_index, group_context)

# AGREGADO: Función para calcular el daño que hace el enemigo (aplicando debilidad)
func calcular_dano_enemigo(dano_base: int) -> int:
	var dano_final := float(dano_base + attack_bonus + permanent_attack_bonus)

	dano_final -= get_estado_total_valor("ataque_menos")
	
	# Si el enemigo tiene el estado "debil", hace 25% menos de daño
	if tiene_estado("debil"):
		dano_final *= 0.75

	if tiene_estado("distraccion"):
		dano_final *= 0.8
		
	return max(int(dano_final), 0)


func get_playable_card_for_turn(player: Player, player_hand_size: int, player_cards_played_last_turn: int) -> CardData:
	if planned_card != null and planned_card.cost <= current_energy:
		return planned_card

	if planned_card != null:
		_debug_ai("Descartada por energia al ejecutar '%s'. Energia=%d coste=%d" % [
			planned_card.card_name,
			current_energy,
			planned_card.cost,
		])
	return null

# MODIFICADO: Texto para la interfaz (ahora muestra el daño reducido si está débil)
func get_intent_text(player: Player, player_hand_size: int, player_cards_played_last_turn: int, player_played_skill_last_turn: bool = false) -> String:
	if planned_card == null:
		return "Intencion: Esperar | Escudo 3"

	var preview := _get_card_preview(planned_card, player, player_hand_size, player_cards_played_last_turn, player_played_skill_last_turn)
	return "Intencion: %s - %s | %s" % [next_intent_type, planned_card.card_name, preview]


func get_intent_tooltip(player: Player, player_hand_size: int, player_cards_played_last_turn: int, player_played_skill_last_turn: bool = false) -> String:
	if planned_card == null:
		return "El enemigo esperara y ganara 3 de escudo."

	var preview := _get_card_preview(planned_card, player, player_hand_size, player_cards_played_last_turn, player_played_skill_last_turn)
	var state_preview := _get_effect_state_preview(planned_card)
	var state_description := _get_effect_state_description(planned_card)

	match planned_card.card_type:
		"ataque":
			if state_description.is_empty():
				return "El enemigo atacara: %s." % preview
			return "El enemigo atacara: %s. Tambien aplicara: %s." % [preview, state_description]
		"defensa":
			return "El enemigo ganara escudo o defensa: %s." % preview
		"buff propio":
			return "El enemigo se aplicara una mejora: %s." % preview
		"debuff enemigo", "estados negativos":
			if not state_description.is_empty():
				return "El enemigo aplicara %s: %s" % [state_preview, state_description]
			return "El enemigo aplicara un estado negativo."
		"descarte_control de mano":
			return "El enemigo alterara tu mano: %s." % preview
		"curacion":
			return "El enemigo se curara: %s." % preview
		_:
			if not state_description.is_empty():
				return "El enemigo usara %s y aplicara: %s." % [planned_card.card_name, state_description]
			return "El enemigo usara %s: %s." % [planned_card.card_name, preview]


func record_executed_intent(card: CardData, zone_index: int) -> void:
	last_card_type = card.card_type
	last_card_name = card.card_name
	last_intent_was_strong_attack = _is_strong_attack(card, zone_index)
	last_intent_was_control_or_debuff = _is_control_or_debuff_card(card)
	turn_count += 1

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


func _choose_next_intent_by_score(
	player: Player,
	player_hand_size: int,
	player_cards_played_last_turn: int,
	zone_index: int,
	group_context: Dictionary
) -> void:
	if professor_deck.is_empty():
		planned_card = null
		_set_wait_intent("pool de cartas vacio")
		return

	var candidates := _get_cards_with_cost_at_most(max_energy)
	_debug_discarded_by_energy(max_energy)
	candidates = _filter_cards_by_allowed_archetypes(candidates)
	if candidates.is_empty():
		planned_card = null
		_set_wait_intent("sin cartas candidatas despues de filtrar energia/arquetipo")
		return

	_debug_ai("Candidatas: %s" % _format_card_names(candidates))
	var lethal_card := _choose_lethal_card(candidates, player, player_hand_size, player_cards_played_last_turn, group_context)
	if lethal_card != null:
		planned_card = lethal_card
		_update_intent_metadata(planned_card, player, player_hand_size, player_cards_played_last_turn, zone_index)
		_debug_ai("Accion elegida por prioridad letal: %s" % planned_card.card_name)
		return

	var best_card: CardData = null
	var best_score := -999999
	for card in candidates:
		var base_score := _evaluate_card(card, player, player_hand_size, player_cards_played_last_turn, zone_index, group_context)
		var estimated_damage := 0
		var projected_hp := player.current_hp
		var lethal := false
		if card.card_type == "ataque":
			estimated_damage = _estimate_attack_damage_for_card(card, player, player_hand_size, player_cards_played_last_turn, group_context)
			var damage_preview := _get_player_damage_preview(player, estimated_damage, _get_card_ignored_block_ratio(card))
			estimated_damage = int(damage_preview.get("damage_after_modifiers", estimated_damage))
			projected_hp = int(damage_preview.get("resulting_hp", player.current_hp))
			lethal = bool(damage_preview.get("is_lethal", false))
		var random_score := randi_range(-5, 5)
		var score := base_score + random_score
		_debug_ai("Eval '%s' | tipo=%s | vida jugador=%d | escudo jugador=%d | dano estimado=%d | vida resultante=%d | letal=%s | score=%d | random=%d | final=%d" % [
			card.card_name,
			card.card_type,
			player.current_hp,
			player.block,
			estimated_damage,
			projected_hp,
			str(lethal),
			base_score,
			random_score,
			score,
		])
		if best_card == null or score > best_score:
			best_card = card
			best_score = score

	planned_card = best_card
	if planned_card == null:
		_set_wait_intent("ninguna carta obtuvo score valido")
		return

	_update_intent_metadata(planned_card, player, player_hand_size, player_cards_played_last_turn, zone_index)
	_debug_ai("Elegida '%s' (%s, coste %d, score %d). Mano jugador=%d, cartas turno anterior=%d, fase=%s" % [
		planned_card.card_name,
		planned_card.card_type,
		planned_card.cost,
		best_score,
		player_hand_size,
		player_cards_played_last_turn,
		_get_enemy_phase(),
	])


func _choose_lethal_card(cards: Array[CardData], player: Player, player_hand_size: int, player_cards_played_last_turn: int, group_context: Dictionary) -> CardData:
	_debug_ai("=== IA ENEMIGA DEBUG ===")
	_debug_ai("HP jugador: %d" % player.current_hp)
	_debug_ai("Escudo jugador: %d" % player.block)

	var lethal_cards: Array[Dictionary] = []
	for card in cards:
		var damage_eval := _get_damage_eval(card, player, player_hand_size, player_cards_played_last_turn, group_context)
		var is_damage_action := bool(damage_eval.get("is_damage_action", false))
		var estimated_damage := int(damage_eval.get("estimated_damage", 0))
		var effective_damage := int(damage_eval.get("effective_damage", 0))
		var resulting_hp := int(damage_eval.get("resulting_hp", player.current_hp))
		var is_lethal := bool(damage_eval.get("is_lethal", false))

		_debug_ai("Accion evaluada: %s | Tipo: %s | Dano estimado: %d | Dano efectivo: %d | Es dano: %s | Es letal: %s | Score: fase letal previa" % [
			card.card_name,
			card.card_type,
			estimated_damage,
			effective_damage,
			str(is_damage_action),
			str(is_lethal),
		])

		if is_damage_action and is_lethal:
			lethal_cards.append({
				"card": card,
				"effective_damage": effective_damage,
				"estimated_damage": estimated_damage,
				"resulting_hp": resulting_hp,
			})

	if lethal_cards.is_empty():
		return null

	lethal_cards.sort_custom(func(a, b): return int(a.get("effective_damage", 0)) > int(b.get("effective_damage", 0)))
	var chosen_card: CardData = lethal_cards[0]["card"]
	_debug_ai("Accion letal elegida: %s | Dano efectivo: %d | Vida resultante: %d" % [
		chosen_card.card_name,
		int(lethal_cards[0].get("effective_damage", 0)),
		int(lethal_cards[0].get("resulting_hp", player.current_hp)),
	])
	return chosen_card


func _evaluate_card(
	card: CardData,
	player: Player,
	player_hand_size: int,
	player_cards_played_last_turn: int,
	zone_index: int,
	group_context: Dictionary
) -> int:
	var score := _get_card_type_base_score(card.card_type)
	var hp_ratio := _get_hp_ratio()
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	var phase := _get_enemy_phase()
	var current_is_strong_attack := _is_strong_attack(card, zone_index)
	var is_elite_or_boss := _is_elite_or_boss()
	var estimated_damage := 0
	var ignored_block_ratio := 0.0
	var damage_preview: Dictionary = {}
	var is_lethal := false
	var resulting_hp := player.current_hp

	if card.card_type == "ataque":
		estimated_damage = _estimate_attack_damage_for_card(card, player, player_hand_size, player_cards_played_last_turn, group_context)
		ignored_block_ratio = _get_card_ignored_block_ratio(card)
		damage_preview = _get_player_damage_preview(player, estimated_damage, ignored_block_ratio)
		estimated_damage = int(damage_preview.get("damage_after_modifiers", estimated_damage))
		is_lethal = bool(damage_preview.get("is_lethal", false))
		resulting_hp = int(damage_preview.get("resulting_hp", player.current_hp))

	if last_card_name == card.card_name:
		score -= 12
	if last_card_type == "ataque" and card.card_type == "ataque":
		if last_intent_was_strong_attack and current_is_strong_attack:
			score -= 85
		elif not current_is_strong_attack and not is_elite_or_boss:
			score -= 3
		elif current_is_strong_attack and not is_elite_or_boss:
			score -= 8

	match card.card_type:
		"ataque":
			if player.block <= 0:
				score += 20
			elif player.block >= 8:
				score -= 10
			if player.current_hp <= int(ceil(player.max_hp * 0.3)):
				score += 20
			if player.tiene_estado("vulnerable"):
				score += FINISHER_VULNERABLE_BONUS
			if effect_text.contains("reduce el escudo") and player.block <= 0:
				score -= 15
			if phase == "agresivo":
				score += 10
			elif phase == "desesperado":
				score += 20
			if player.block > 0 and (effect_text.contains("ignora") or effect_text.contains("reduce el escudo")):
				score += 15
			if not is_lethal and resulting_hp <= int(ceil(player.max_hp * 0.2)):
				score += FINISHER_LOW_HP_BONUS
			elif not is_lethal and resulting_hp <= int(ceil(player.max_hp * 0.35)):
				score += 30
		"defensa":
			if hp_ratio <= 0.5:
				score += 15
			if hp_ratio <= 0.3:
				score += 25
			if phase == "desesperado":
				score += 10
			if block >= max(10, int(max_hp * 0.2)):
				score -= 15
		"buff propio":
			if turn_count <= 2:
				score += 15
			if hp_ratio > 0.5:
				score += 10
			if effect_text.contains("ataque") and (attack_bonus > 0 or permanent_attack_bonus > 0):
				score -= 15
		"debuff enemigo", "estados negativos":
			var state_name := _get_primary_player_state_from_card(card)
			if state_name.is_empty() or not player.tiene_estado(state_name):
				score += 15
			else:
				score -= 15
			if player_hand_size >= 4:
				score += 10
			if last_intent_was_control_or_debuff:
				if zone_index <= 1:
					score -= 65
				else:
					score -= 45
		"descarte_control de mano":
			if player_hand_size >= 4:
				score += 20
			elif player_hand_size <= 2:
				score -= 25
			if last_intent_was_control_or_debuff:
				if zone_index <= 1:
					score -= 65
				else:
					score -= 45
		"curacion":
			if hp_ratio <= 0.4:
				score += 35
			elif hp_ratio > 0.7:
				score -= 25
		"energia", "robo":
			score -= 10
		"habilidad":
			if turn_count <= 2:
				score += 5

	score = _apply_archetype_score_modifiers(score, card, hp_ratio, current_is_strong_attack)
	score = _apply_enemy_specific_score_modifiers(score, card, player, current_is_strong_attack)

	if is_lethal:
		score += LETHAL_PRIORITY_BONUS
		_debug_ai("Lethal detectado en '%s': dano=%d, escudo=%d, vida resultante=%d, bonus=%d" % [
			card.card_name,
			estimated_damage,
			player.block,
			resulting_hp,
			LETHAL_PRIORITY_BONUS,
		])

	if not is_lethal and int(group_context.get("control_debuff_count", 0)) > 0 and _is_control_or_debuff_card(card):
		score -= 50
	if not is_lethal and int(group_context.get("strong_attack_count", 0)) >= 2 and current_is_strong_attack:
		score -= 40
	if not is_lethal and int(group_context.get("announced_damage", 0)) >= _get_zone_damage_soft_cap(zone_index) and card.card_type == "ataque":
		score -= 30

	return score


func _apply_enemy_specific_score_modifiers(score: int, card: CardData, player: Player, current_is_strong_attack: bool) -> int:
	if enemy_debug_id != ENEMY_ID_EL_ONI:
		return score

	match _get_oni_phase():
		"mascara_intacta":
			match card.card_type:
				"defensa":
					score += 18
				"buff propio":
					score += 12
				"debuff enemigo", "estados negativos":
					score += 10
				"descarte_control de mano":
					score += 4
				"ataque":
					if current_is_strong_attack:
						score -= 8
		"mascara_quebrada":
			match card.card_type:
				"ataque":
					score += 18
					if current_is_strong_attack:
						score += 8
					if player.has_negative_state():
						score += 12
				"defensa":
					score -= 10
				"buff propio", "debuff enemigo", "estados negativos":
					score += 5
		"ira_del_oni":
			match card.card_type:
				"ataque":
					score += 35
					if current_is_strong_attack:
						score += 15
				"defensa":
					score -= 25
				"buff propio":
					score += 5
				"debuff enemigo", "estados negativos", "descarte_control de mano":
					score -= 5
			if _is_high_impact_oni_card(card, current_is_strong_attack):
				score += 10

	return score


func _get_oni_phase() -> String:
	if current_hp <= 140:
		return "ira_del_oni"
	if current_hp <= 280:
		return "mascara_quebrada"
	return "mascara_intacta"


func _is_high_impact_oni_card(card: CardData, current_is_strong_attack: bool) -> bool:
	if current_is_strong_attack:
		return true
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	return card.cost >= 3 or effect_text.contains("ignora") or effect_text.contains("permanente") or effect_text.contains("descarta toda")


func _get_card_type_base_score(card_type: String) -> int:
	match card_type:
		"ataque":
			return 50
		"defensa":
			return 35
		"buff propio":
			return 30
		"debuff enemigo", "estados negativos":
			return 35
		"descarte_control de mano":
			return 30
		"curacion":
			return 25
		"robo":
			return 20
		"energia":
			return 25
		"habilidad":
			return 25
		_:
			return 20


func _apply_archetype_score_modifiers(score: int, card: CardData, hp_ratio: float, current_is_strong_attack: bool) -> int:
	if _has_enemy_archetype("Tanque medio"):
		match card.card_type:
			"defensa":
				score += 15
			"buff propio":
				score += 10
			"debuff enemigo", "estados negativos", "descarte_control de mano":
				score -= 10

	if _has_enemy_archetype("Molesto tecnico"):
		match card.card_type:
			"debuff enemigo", "estados negativos", "descarte_control de mano":
				score += 15
			"ataque", "defensa":
				score -= 5

	if _has_enemy_archetype("Enjambre"):
		match card.card_type:
			"ataque":
				score += 15
			"defensa":
				score -= 5
			"debuff enemigo", "estados negativos", "descarte_control de mano":
				score -= 20
		if current_is_strong_attack:
			score -= 10

	if _has_enemy_archetype("Jefe zona 3"):
		match card.card_type:
			"ataque", "defensa", "buff propio":
				score += 10
			"debuff enemigo", "estados negativos":
				score += 5

		if hp_ratio <= 0.35:
			if card.card_type == "ataque":
				score += 15
				if current_is_strong_attack:
					score += 10
			elif card.card_type == "defensa":
				score += 15
			elif card.card_type == "descarte_control de mano":
				score -= 10
		elif hp_ratio <= 0.65:
			if card.card_type == "buff propio":
				score += 10
			elif card.card_type == "debuff enemigo" or card.card_type == "estados negativos":
				score += 10
			elif current_is_strong_attack:
				score += 8
		else:
			if card.card_type == "defensa" or card.card_type == "buff propio":
				score += 5

	return score


func _update_intent_metadata(card: CardData, player: Player, player_hand_size: int, player_cards_played_last_turn: int, zone_index: int) -> void:
	next_intent_card = card
	next_intent_type = _get_intent_type_from_card(card)
	next_intent_value = _estimate_intent_value(card, zone_index)
	next_intent_text = _get_card_preview(card, player, player_hand_size, player_cards_played_last_turn)


func _set_wait_intent(reason: String = "") -> void:
	next_intent_card = null
	next_intent_type = "Esperar"
	next_intent_value = 3
	next_intent_text = "Escudo 3"
	if not reason.is_empty():
		_debug_ai("Fallback a Esperar: %s" % reason)


func _choose_lowest_cost_card(cards: Array[CardData]) -> CardData:
	var chosen: CardData = null
	for card in cards:
		if chosen == null or card.cost < chosen.cost:
			chosen = card
	return chosen


func _filter_cards_by_allowed_archetypes(cards: Array[CardData]) -> Array[CardData]:
	if allowed_enemy_archetypes.is_empty():
		return cards

	var filtered_cards: Array[CardData] = []
	var has_cards_with_archetypes := false
	for card in cards:
		if not card.enemy_archetypes.is_empty():
			has_cards_with_archetypes = true
		if _card_matches_allowed_archetypes(card):
			filtered_cards.append(card)
		else:
			_debug_ai("Descartada por arquetipo. Carta=%s | Arquetipos carta=%s | Permitidos=%s" % [
				card.card_name,
				", ".join(card.enemy_archetypes),
				", ".join(allowed_enemy_archetypes),
			])

	if filtered_cards.is_empty():
		if not has_cards_with_archetypes:
			push_warning("Enemy: el pool no tiene arquetipos cargados. Se usa el pool recibido.")
			return cards
		push_warning("Enemy: ninguna carta coincide con los arquetipos permitidos %s. Se usa fallback por rareza/zona." % ", ".join(allowed_enemy_archetypes))
		return cards

	_debug_ai("Filtro por arquetipo: %d/%d cartas" % [filtered_cards.size(), cards.size()])
	return filtered_cards


func _card_matches_allowed_archetypes(card: CardData) -> bool:
	for archetype in allowed_enemy_archetypes:
		if EnemyCardLoader.card_matches_enemy_archetype(card, archetype):
			return true
	return false


func _debug_discarded_by_energy(max_cost: int) -> void:
	if not debug_enemy_ai:
		return

	for card in professor_deck:
		if card.cost > max_cost:
			_debug_ai("Descartada por energia '%s'. Coste=%d energia maxima=%d" % [
				card.card_name,
				card.cost,
				max_cost,
			])


func _format_card_names(cards: Array[CardData]) -> String:
	var names: Array[String] = []
	for card in cards:
		names.append("%s(%s,c%d)" % [card.card_name, card.card_type, card.cost])
	return ", ".join(names)


func _debug_ai(message: String) -> void:
	if not debug_enemy_ai:
		return

	var display_name := enemy_debug_name
	if display_name.is_empty():
		display_name = name

	var archetype_text := ", ".join(enemy_debug_archetypes)
	if archetype_text.is_empty():
		archetype_text = "sin arquetipo"

	var rarity_text := ", ".join(enemy_debug_rarities)
	if rarity_text.is_empty():
		rarity_text = "sin rarezas"

	print("DEBUG Enemy AI [%s | Zona %d | %s | %s]: %s" % [
		display_name,
		enemy_debug_zone_index,
		archetype_text,
		rarity_text,
		message,
	])


func _has_enemy_archetype(archetype: String) -> bool:
	return allowed_enemy_archetypes.has(EnemyCardLoader._normalize_text(archetype))


func _is_elite_or_boss() -> bool:
	return (
		allowed_enemy_archetypes.has(EnemyCardLoader._normalize_text("Elite pesado"))
		or allowed_enemy_archetypes.has(EnemyCardLoader._normalize_text("Jefe inicial"))
		or allowed_enemy_archetypes.has(EnemyCardLoader._normalize_text("Jefe tanque"))
		or allowed_enemy_archetypes.has(EnemyCardLoader._normalize_text("Jefe zona 3"))
	)


func _get_enemy_phase() -> String:
	var hp_ratio := _get_hp_ratio()
	if hp_ratio <= 0.25:
		return "desesperado"
	if hp_ratio <= 0.5:
		return "agresivo"
	return "normal"


func _get_hp_ratio() -> float:
	if max_hp <= 0:
		return 1.0
	return float(current_hp) / float(max_hp)


func _get_intent_type_from_card(card: CardData) -> String:
	match card.card_type:
		"ataque":
			return "Ataque"
		"defensa":
			return "Defensa"
		"buff propio":
			return "Buff"
		"debuff enemigo", "estados negativos":
			return "Debuff"
		"descarte_control de mano":
			return "Control"
		"curacion":
			return "Curacion"
		"energia":
			return "Energia"
		"habilidad":
			return "Habilidad"
		_:
			return "Desconocido"


func _estimate_intent_value(card: CardData, zone_index: int) -> int:
	if card.card_type == "ataque":
		return _estimate_attack_damage(card)
	if card.card_type == "defensa":
		return _estimate_card_amount(card)
	return 0


func _estimate_attack_damage(card: CardData) -> int:
	return calcular_dano_enemigo(_estimate_card_amount(card))


func _is_damage_action(card: CardData, estimated_damage: int = -1) -> bool:
	if card.card_type == "ataque":
		return true

	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	var has_damage_text := (
		effect_text.contains("inflige")
		or effect_text.contains("pierde vida")
		or effect_text.contains("pierdes vida")
		or (effect_text.contains("recibe") and effect_text.contains("dano"))
	)
	if estimated_damage < 0:
		estimated_damage = _estimate_attack_damage(card)
	return has_damage_text and estimated_damage > 0


func _get_damage_eval(card: CardData, player: Player, player_hand_size: int, player_cards_played_last_turn: int, group_context: Dictionary = {}) -> Dictionary:
	var estimated_damage := 0
	if _is_damage_action(card):
		estimated_damage = _estimate_attack_damage_for_card(card, player, player_hand_size, player_cards_played_last_turn, group_context)

	var damage_preview := _get_player_damage_preview(player, estimated_damage, _get_card_ignored_block_ratio(card))
	var effective_damage := int(damage_preview.get("remaining_damage", 0))
	var resulting_hp := int(damage_preview.get("resulting_hp", player.current_hp))
	var is_damage_action := _is_damage_action(card, estimated_damage)

	return {
		"is_damage_action": is_damage_action,
		"estimated_damage": int(damage_preview.get("damage_after_modifiers", estimated_damage)),
		"effective_damage": effective_damage,
		"resulting_hp": resulting_hp,
		"is_lethal": is_damage_action and resulting_hp <= 0,
	}


func _estimate_attack_damage_for_card(card: CardData, player: Player, player_hand_size: int, player_cards_played_last_turn: int, group_context: Dictionary = {}) -> int:
	match card.effect_id:
		"pregunta_al_azar":
			var pregunta_al_azar_damage := 8
			if player_hand_size >= 3:
				pregunta_al_azar_damage += 4
			return calcular_dano_enemigo(pregunta_al_azar_damage)
		"eso_ya_lo_vimos":
			var eso_ya_lo_vimos_damage := 10
			if player.block <= 0:
				eso_ya_lo_vimos_damage += 3
			return calcular_dano_enemigo(eso_ya_lo_vimos_damage)
		"parcialito_sorpresa":
			var parcialito_sorpresa_damage := 14
			if player.has_negative_state():
				parcialito_sorpresa_damage += 6
			return calcular_dano_enemigo(parcialito_sorpresa_damage)
		"parcial_integrador":
			var parcial_integrador_damage := 18
			if player_hand_size < 3:
				parcial_integrador_damage += 6
			return calcular_dano_enemigo(parcial_integrador_damage)
		"correccion_en_rojo":
			return calcular_dano_enemigo(12)
		"oral_individual":
			return calcular_dano_enemigo(24)
		"final_con_tribunal":
			return calcular_dano_enemigo(30)
		"pregunta_de_repaso":
			var pregunta_de_repaso_damage := 7
			if bool(group_context.get("player_played_skill_last_turn", false)):
				pregunta_de_repaso_damage += 5
			return calcular_dano_enemigo(pregunta_de_repaso_damage)
		"ejemplo_sin_resolver":
			var ejemplo_sin_resolver_damage := 13
			if player.tiene_estado("confusion"):
				ejemplo_sin_resolver_damage += 5
			return calcular_dano_enemigo(ejemplo_sin_resolver_damage)
		"respuesta_incompleta":
			return calcular_dano_enemigo(12)
		"parcial_con_inciso_sorpresa":
			var parcial_con_inciso_sorpresa_damage := 17
			if player_hand_size < 2:
				parcial_con_inciso_sorpresa_damage += 7
			return calcular_dano_enemigo(parcial_con_inciso_sorpresa_damage)
		"revision_severa":
			return calcular_dano_enemigo(player_hand_size * 4)
		"mesa_examinadora":
			return calcular_dano_enemigo(22)
		"final_definitivo":
			var final_definitivo_damage := 28
			if player.tiene_estado("estres") or player.tiene_estado("distraccion"):
				final_definitivo_damage += 8
			return calcular_dano_enemigo(final_definitivo_damage)
		_:
			return _estimate_attack_damage(card)


func _estimate_card_amount(card: CardData) -> int:
	if card.value > 0:
		return card.value
	return _extract_first_number(EnemyCardLoader._normalize_text(card.raw_effect_text))


func _extract_first_number(text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+") != OK:
		return 0
	var result := regex.search(text)
	if result == null:
		return 0
	return result.get_string().to_int()


func _is_control_or_debuff_card(card: CardData) -> bool:
	return card.card_type == "descarte_control de mano" or card.card_type == "debuff enemigo" or card.card_type == "estados negativos"


func _get_card_ignored_block_ratio(card: CardData) -> float:
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	if not effect_text.contains("ignora"):
		return 0.0
	return float(_extract_percent(effect_text)) / 100.0


func _extract_percent(text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+%") != OK:
		return 0

	var result := regex.search(text)
	if result == null:
		return 0

	return result.get_string().replace("%", "").to_int()


func _get_player_damage_preview(player: Player, estimated_damage: int, ignored_block_ratio: float = 0.0) -> Dictionary:
	if player.immune_to_enemy_attack_turns > 0:
		return {
			"damage_after_modifiers": 0,
			"remaining_damage": 0,
			"resulting_hp": player.current_hp,
			"resulting_block": player.block,
			"is_lethal": false,
		}

	var adjusted_damage: int = estimated_damage
	if player.tiene_estado("estres"):
		adjusted_damage = int(adjusted_damage * 1.25)
	if player.tiene_estado("nervios_de_acero"):
		adjusted_damage = int(adjusted_damage * 0.75)

	var effective_block: int = player.block
	if ignored_block_ratio > 0.0:
		var ignored_block := int(floor(player.block * ignored_block_ratio))
		effective_block = int(max(player.block - ignored_block, 0))

	var remaining_damage: int = int(max(adjusted_damage - effective_block, 0))
	var resulting_hp: int = player.current_hp - remaining_damage
	var blocked_damage: int = int(min(effective_block, adjusted_damage))
	var resulting_block: int = int(max(player.block - blocked_damage, 0))

	return {
		"damage_after_modifiers": adjusted_damage,
		"remaining_damage": remaining_damage,
		"resulting_hp": resulting_hp,
		"resulting_block": resulting_block,
		"is_lethal": resulting_hp <= 0,
	}


func _is_strong_attack(card: CardData, zone_index: int) -> bool:
	if card.card_type != "ataque":
		return false

	var estimated_damage := _estimate_attack_damage(card)
	if estimated_damage <= 0 and card.cost >= 3:
		return true
	if EnemyCardLoader._normalize_text(card.raw_effect_text).contains("reduce el escudo"):
		return estimated_damage >= max(_get_strong_attack_threshold(zone_index) - 1, 1)

	return estimated_damage >= _get_strong_attack_threshold(zone_index)


func _get_strong_attack_threshold(zone_index: int) -> int:
	match zone_index:
		1:
			return 9
		2:
			return 13
		3:
			return 18
		_:
			return 24


func _get_zone_damage_soft_cap(zone_index: int) -> int:
	match zone_index:
		1:
			return 16
		2:
			return 24
		3:
			return 28
		_:
			return 34


func _get_primary_player_state_from_card(card: CardData) -> String:
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	if effect_text.contains("estres"):
		return "estres"
	if effect_text.contains("distraccion") or effect_text.contains("roba 1 carta menos"):
		return "distraccion"
	if effect_text.contains("confusion"):
		return "confusion"
	if effect_text.contains("panico"):
		return "panico"
	if effect_text.contains("habilidad") and (effect_text.contains("cuestan 1") or effect_text.contains("cuesta 1")):
		return "habilidad_mas"
	if effect_text.contains("defensa") and effect_text.contains("menos"):
		return "defensa_menos"
	return ""


func _get_cards_with_cost_at_most(max_cost: int) -> Array[CardData]:
	var candidates: Array[CardData] = []
	for card in professor_deck:
		if card.cost <= max_cost:
			candidates.append(card)
	return candidates


func _get_card_preview(card: CardData, player: Player, player_hand_size: int, player_cards_played_last_turn: int, player_played_skill_last_turn: bool = false) -> String:
	match card.effect_id:
		"pregunta_al_azar":
			var damage := 8
			if player_hand_size >= 3:
				damage += 4
			return "Ataque %d" % calcular_dano_enemigo(damage)
		"mirada_evaluadora":
			return "Aplica Estrés 1"
		"borrar_el_pizarron":
			return "Descarta 1 aleatoria"
		"eso_ya_lo_vimos":
			var damage := 10
			if player.block <= 0:
				damage += 3
			return "Ataque %d" % calcular_dano_enemigo(damage)
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
			return "Ataque %d" % calcular_dano_enemigo(damage)
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
			return "Ataque %d" % calcular_dano_enemigo(damage)
		"correccion_en_rojo":
			return "Ataque %d + Estrés" % calcular_dano_enemigo(12)
		"recuperatorio_anunciado":
			return "Escudo 15 y limpia 1 debuff"
		"pregunta_capciosa":
			return "Descarta 2 o recibe 8"
		"bibliografia_extra":
			return "Roba -1 y skills +1 x2"
		"oral_individual":
			return "Ataque %d (ignora 50%% escudo)" % calcular_dano_enemigo(24)
		"cambio_de_consigna":
			return "Descarta mano y roba 3"
		"clase_de_repaso_mortal":
			return "+5 ataque y 10 escudo"
		"final_con_tribunal":
			return "Ataque %d + Estrés + Distracción" % calcular_dano_enemigo(30)
		"silencio_incomodo":
			return "Estres 1 y descarte si tenes 4+ cartas"
		"pregunta_de_repaso":
			var damage := 7
			if player_played_skill_last_turn:
				damage += 5
			return "Ataque %d" % calcular_dano_enemigo(damage)
		"quien_quiere_pasar":
			return "Panico: proxima primera carta +1"
		"lista_incompleta":
			return "Descarta 1 o recibe 6"
		"dictado_acelerado":
			return "Roba -1 y defensas -25%"
		"ejemplo_sin_resolver":
			var damage := 13
			if player.tiene_estado("confusion"):
				damage += 5
			return "Ataque %d" % calcular_dano_enemigo(damage)
		"carpeta_prolija":
			var shield := 9
			if attack_bonus > 0 or permanent_attack_bonus > 0:
				shield += 4
			return "Escudo %d" % shield
		"tema_que_entra_seguro":
			return "Gana +3 ataque x2"
		"respuesta_incompleta":
			return "Ataque %d y -4 escudo" % calcular_dano_enemigo(12)
		"correccion_oral":
			return "Estres 2"
		"consigna_ambigua":
			return "Confusion 2"
		"teoria_acumulada":
			return "+2 ataque permanente y 6 escudo"
		"parcial_con_inciso_sorpresa":
			var damage := 17
			if player_hand_size < 2:
				damage += 7
			return "Ataque %d" % calcular_dano_enemigo(damage)
		"revision_severa":
			return "Descarta 1 y castiga ataques en mano"
		"esto_es_basico":
			return "Habilidades +1 energia x2"
		"bibliografia_obligatoria":
			return "Distraccion 2"
		"mesa_examinadora":
			return "Ataque %d (ignora 40%% escudo si tiene escudo)" % calcular_dano_enemigo(22)
		"criterio_invisible":
			return "+4 ataque x2 y limpia 1 debuff"
		"cambio_de_fecha":
			return "Descarta 2 aleatorias y roba 1"
		"final_definitivo":
			var damage := 28
			if player.tiene_estado("estres") or player.tiene_estado("distraccion"):
				damage += 8
			return "Ataque %d" % calcular_dano_enemigo(damage)
		_:
			return _get_generic_card_preview(card)


func _get_generic_card_preview(card: CardData) -> String:
	var state_preview := _get_effect_state_preview(card)
	match card.card_type:
		"ataque":
			if card.value > 0:
				var attack_preview := "Ataque %d" % calcular_dano_enemigo(card.value)
				if not state_preview.is_empty():
					attack_preview += " + %s" % state_preview
				return attack_preview
			return "Ataque"
		"defensa":
			if card.value > 0:
				return "Escudo %d" % card.value
			return "Defensa"
		"descarte_control de mano":
			if card.value > 0:
				return "Descarta %d" % card.value
			return "Descarte"
		"debuff enemigo", "estados negativos":
			if not state_preview.is_empty():
				return "Aplica %s" % state_preview
			return "Aplica estado"
		"buff propio":
			return "Gana mejora"
		_:
			return card.card_type


func _get_effect_state_preview(card: CardData) -> String:
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	var states: Array[String] = []

	if effect_text.contains("estres"):
		states.append("Estres")
	if effect_text.contains("distraccion") or effect_text.contains("roba 1 carta menos"):
		states.append("Distraccion")
	if effect_text.contains("confusion"):
		states.append("Confusion")
	if effect_text.contains("panico"):
		states.append("Panico")
	if effect_text.contains("vulnerable"):
		states.append("Vulnerable")
	if effect_text.contains("debil"):
		states.append("Debil")
	if effect_text.contains("habilidad") and (effect_text.contains("cuestan 1") or effect_text.contains("cuesta 1")):
		states.append("Habilidad +1")
	if effect_text.contains("defensa") and effect_text.contains("menos"):
		states.append("Defensa -25%")

	return " + ".join(states)


func _get_effect_state_description(card: CardData) -> String:
	var effect_text := EnemyCardLoader._normalize_text(card.raw_effect_text)
	var descriptions: Array[String] = []

	if effect_text.contains("estres"):
		descriptions.append("Estres reduce el dano de ataques del jugador y hace que reciba mas dano.")
	if effect_text.contains("distraccion") or effect_text.contains("roba 1 carta menos"):
		descriptions.append("Distraccion reduce el robo de cartas del jugador.")
	if effect_text.contains("confusion"):
		descriptions.append("Confusion reduce el robo de cartas.")
	if effect_text.contains("panico"):
		descriptions.append("Panico aumenta en 1 el coste de la proxima primera carta.")
	if effect_text.contains("vulnerable"):
		descriptions.append("Vulnerable hace que el objetivo reciba mas dano.")
	if effect_text.contains("debil"):
		descriptions.append("Debil reduce el dano de los ataques.")
	if effect_text.contains("habilidad") and (effect_text.contains("cuestan 1") or effect_text.contains("cuesta 1")):
		descriptions.append("Las habilidades cuestan 1 energia mas.")
	if effect_text.contains("defensa") and effect_text.contains("menos"):
		descriptions.append("Las defensas otorgan menos escudo.")

	return " ".join(descriptions)
