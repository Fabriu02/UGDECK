extends Node
class_name CombatManager

const CARD_SCENE := preload("res://scenes/Card.tscn")
const EnemyCardLoader := preload("res://scripts/EnemyCardLoader.gd")
const MAP_SCENE_PATH := "res://scenes/map/vista_mapa.tscn"
const PLAYER_DRAW_PER_TURN := 3
const FIRST_ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const SECOND_ENEMY_IMAGE_PATH := "res://assets/characters/pepi enemigo 2.png"
const FIRST_ENEMY_MAX_HP := 50
const FIRST_ENEMY_BASE_BLOCK := 0
const SECOND_ENEMY_MAX_HP := 200
const SECOND_ENEMY_BASE_BLOCK := 15
const FIRST_ENEMY_NAME := "Tom Apostol"
const SECOND_ENEMY_NAME := "Pepi"

@onready var player: Player = $"../Player"
@onready var enemy: Enemy = $"../Enemy"
@onready var deck_manager: DeckManager = $"../DeckManager"

@onready var player_stats_label: Label = $"../UI/PlayerStatsLabel"
@onready var enemy_stats_label: Label = $"../UI/EnemyStatsLabel"
@onready var energy_label: Label = $"../UI/EnergyLabel"
@onready var enemy_intent_label: Label = $"../UI/EnemyIntentLabel"
@onready var hand_container: HBoxContainer = $"../UI/HandContainer"
@onready var end_turn_button: Button = $"../UI/EndTurnButton"
@onready var abandon_combat_button: Button = $"../UI/AbandonCombatButton"
@onready var battle_visuals: BattleVisuals = $"../Visuals"

var battle_has_ended := false
var skip_next_enemy_turn := false
var enemy_turn_finished_by_card := false

# AGREGADO: Variable para saber si el juego está esperando que descartes una carta
var waiting_for_discard := false 
var discard_selection_mode := ""
var discard_selection_remaining := 0
var discard_selection_requested_total := 0
var discard_selection_completed := 0
var discard_selection_penalty_damage := 0
var discard_selection_reward_block_per_card := 0
var player_cards_played_this_turn := 0
var player_cards_played_last_turn := 0
var player_played_skill_this_turn := false
var player_played_skill_last_turn := false
var skip_next_player_draw := false
var preserve_hand_for_next_turn := false
var player_attacked_this_turn := false
var temporary_card_cost_modifiers: Dictionary = {}
var current_enemy_name := FIRST_ENEMY_NAME
var returning_to_map := false


func _ready() -> void:
	randomize()
	end_turn_button.pressed.connect(end_player_turn)
	abandon_combat_button.pressed.connect(abandon_combat)
	start_battle()


func start_battle() -> void:
	battle_has_ended = false
	returning_to_map = false
	skip_next_enemy_turn = false
	_reset_discard_selection()
	end_turn_button.disabled = false
	player_cards_played_this_turn = 0
	player_cards_played_last_turn = 0
	player_played_skill_this_turn = false
	player_played_skill_last_turn = false
	skip_next_player_draw = false
	preserve_hand_for_next_turn = false
	player_attacked_this_turn = false
	temporary_card_cost_modifiers.clear()
	_configure_enemy_for_current_node()
	player.reset_for_new_battle()
	enemy.reset_for_new_battle()
	deck_manager.create_starting_deck()
	enemy.choose_next_intent(player, 0, player_cards_played_last_turn)
	start_player_turn()


func _configure_enemy_for_current_node() -> void:
	if _is_second_enemy_node():
		enemy.max_hp = SECOND_ENEMY_MAX_HP
		enemy.base_block = SECOND_ENEMY_BASE_BLOCK
		enemy.set_professor_deck(EnemyCardLoader.load_second_professor_cards())
		battle_visuals.set_enemy_image(SECOND_ENEMY_IMAGE_PATH)
		battle_visuals.set_enemy_display_name(SECOND_ENEMY_NAME)
		current_enemy_name = SECOND_ENEMY_NAME
	else:
		enemy.max_hp = FIRST_ENEMY_MAX_HP
		enemy.base_block = FIRST_ENEMY_BASE_BLOCK
		enemy.set_professor_deck(EnemyCardLoader.load_professor_cards())
		battle_visuals.set_enemy_image(FIRST_ENEMY_IMAGE_PATH)
		battle_visuals.set_enemy_display_name(FIRST_ENEMY_NAME)
		current_enemy_name = FIRST_ENEMY_NAME


func _is_second_enemy_node() -> bool:
	if GameState.map_data.is_empty() or GameState.nodo_actual_id == -1:
		return false

	for node_data in GameState.map_data.nodes:
		if node_data.id == GameState.nodo_actual_id:
			return node_data.position.x > 0

	return false


func start_player_turn() -> void:
	if battle_has_ended:
		return

	end_turn_button.disabled = false
	player.reset_for_new_turn()
	player_cards_played_this_turn = 0
	player_attacked_this_turn = false
	player_played_skill_this_turn = false
	temporary_card_cost_modifiers.clear()

	if player.skip_next_player_turn:
		player.skip_next_player_turn = false
		_clear_hand_ui()
		player_cards_played_last_turn = 0
		update_ui()
		enemy_turn()
		return

	if skip_next_player_draw:
		skip_next_player_draw = false
		preserve_hand_for_next_turn = false
	else:
		preserve_hand_for_next_turn = false
		var draw_amount := player.get_draw_amount(PLAYER_DRAW_PER_TURN)
		deck_manager.draw_cards(draw_amount)

	_show_hand()
	update_ui()


func play_card(card_data: CardData, card_ui: CardUI) -> void:
	if battle_has_ended:
		return

	if not deck_manager.hand.has(card_data):
		return

	# AGREGADO: Lógica de interceptación. Si estamos esperando, descartamos en vez de jugar.
	if waiting_for_discard:
		_execute_discard_choice(card_data, card_ui)
		return

	if _is_attack_card(card_data) and player.tiene_estado("apagar_la_camara"):
		update_ui()
		return

	var effective_cost := player.get_effective_card_cost(card_data, player_cards_played_this_turn)
	effective_cost += _get_temporary_cost_modifier(card_data)
	effective_cost = max(effective_cost, 0)
	if not player.spend_energy(effective_cost):
		update_ui()
		return

	deck_manager.hand.erase(card_data)
	deck_manager.played_cards.append(card_data)
	card_ui.queue_free()
	player_cards_played_this_turn += 1
	if _is_attack_card(card_data):
		player_attacked_this_turn = true
	elif _is_skill_card(card_data):
		player_played_skill_this_turn = true

	_apply_card_effect(card_data)
	update_ui()
	check_combat_end()


func end_player_turn() -> void:
	if battle_has_ended:
		return

	if waiting_for_discard:
		return

	for card_data in deck_manager.hand:
		if card_data.effect_id == "sentarse_fondo":
			player.gain_block(5)

	# AGREGADO: Reducimos la duración de los estados del jugador al terminar su turno
	player.reducir_duracion_estados()

	player_cards_played_last_turn = player_cards_played_this_turn
	player_played_skill_last_turn = player_played_skill_this_turn
	end_turn_button.disabled = true
	enemy_turn()


func enemy_turn() -> void:
	enemy.start_turn()

	if skip_next_enemy_turn:
		skip_next_enemy_turn = false
	else:
		var card_to_play := enemy.get_playable_card_for_turn(player, deck_manager.hand.size(), player_cards_played_last_turn)
		if card_to_play != null:
			enemy_turn_finished_by_card = false
			_execute_enemy_card(card_to_play)
			if waiting_for_discard:
				return
			if enemy_turn_finished_by_card:
				return
		else:
			print("DEBUG Enemy: no encontró carta jugable, pasa el turno.")

	_finish_enemy_turn()


func _finish_enemy_turn() -> void:
	if not preserve_hand_for_next_turn:
		deck_manager.discard_hand()
		_clear_hand_ui()

	deck_manager.discard_played_cards()

	# AGREGADO: Reducimos la duración de los estados del enemigo al terminar su turno
	enemy.reducir_duracion_estados()

	check_combat_end()

	if battle_has_ended:
		return

	enemy.choose_next_intent(player, deck_manager.hand.size(), player_cards_played_last_turn)
	start_player_turn()


func update_ui() -> void:
	player_stats_label.text = "Jugador - Vida: %d/%d | Escudo: %d" % [
		player.current_hp,
		player.max_hp,
		player.block
	]
	enemy_stats_label.text = "%s - Vida: %d/%d | Escudo: %d" % [
		current_enemy_name,
		enemy.current_hp,
		enemy.max_hp,
		enemy.block
	]
	energy_label.text = "Energia: %d/%d" % [player.current_energy, player.max_energy]
	
	# AGREGADO: Solo actualizamos el texto de intención si NO estamos en modo descarte
	if not waiting_for_discard:
		enemy_intent_label.text = enemy.get_intent_text(player, deck_manager.hand.size(), player_cards_played_last_turn)


func check_combat_end() -> void:
	if enemy.is_dead():
		battle_has_ended = true
		enemy_intent_label.text = "Victoria: aprobaste este combate."
		end_turn_button.disabled = true
		_clear_hand_ui()
		GameState.completar_nodo_actual()
		_return_to_map()
	elif player.is_dead():
		battle_has_ended = true
		enemy_intent_label.text = "Derrota: el cuatrimestre te supero."
		end_turn_button.disabled = true
		_clear_hand_ui()
		GameState.volver_al_primer_nodo()
		_return_to_map()


func complete_first_battle_and_return_to_map() -> void:
	GameState.completar_nodo_actual()
	_return_to_map()


func abandon_combat() -> void:
	battle_has_ended = true
	_return_to_map()


func _return_to_map() -> void:
	if returning_to_map:
		return

	returning_to_map = true
	call_deferred("_deferred_return_to_map")


func _deferred_return_to_map() -> void:
	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_file(MAP_SCENE_PATH)


func _show_hand() -> void:
	_clear_hand_ui()

	for card_data in deck_manager.hand:
		var card_ui: CardUI = CARD_SCENE.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_clicked.connect(play_card)


func _clear_hand_ui() -> void:
	for child in hand_container.get_children():
		child.queue_free()


func _apply_card_effect(card_data: CardData) -> void:
	if card_data.effect_id == "basic_attack":
		_apply_player_attack(card_data.value)
	elif card_data.effect_id == "basic_block":
		_gain_player_block(card_data.value)
	elif card_data.effect_id == "mate_salvador":
		player.attack_bonus = card_data.value
		player.attack_bonus_turns = 2
	elif card_data.effect_id == "trasnochar":
		player.lose_hp(card_data.value)
		player.next_attack_multiplier = 2.0
	elif card_data.effect_id == "machetearse":
		_play_machetearse()
	elif card_data.effect_id == "aprobado_con_4":
		player.approved_with_4_turns = 2
	elif card_data.effect_id == "faltazo":
		player.skip_next_player_turn = true
		player.immune_to_enemy_attack_turns = 1
	elif card_data.effect_id == "sentarse_fondo":
		_gain_player_block(card_data.value)
	elif card_data.effect_id == "pasar_pizarron":
		player.increase_max_hp(card_data.value)
	elif card_data.effect_id == "corte_luz":
		skip_next_enemy_turn = true
		deck_manager.discard_hand()
		_show_hand()
	elif card_data.effect_id == "dormir_siesta":
		_begin_discard_selection("player_replace_one", 1, 0)
		
	# AGREGADO: Lógica de tu nueva carta (Vulnerable)
	elif card_data.effect_id == "pregunta_profesor":
		enemy.aplicar_estado("vulnerable", 0, 2)
		
	# AGREGADO: Lógica de la carta de aumentar energía
	elif card_data.effect_id == "cafe_doble":
		player.increase_max_energy(card_data.value)
		
	# --- AGREGADO: LÓGICAS DE PRUEBA ---
	elif card_data.effect_id == "curar_debug":
		player.curar(card_data.value)
	elif card_data.effect_id == "debil_debug":
		enemy.aplicar_estado("debil", 0, 2)
		update_ui() # Refrescamos para ver cómo baja el daño en la intención
	elif card_data.effect_id == "descarte_azar_debug":
		deck_manager.discard_random_cards(card_data.value)
		_show_hand() # Refrescamos la mano para ver qué carta desapareció

	# NUEVAS LÓGICAS DE PRUEBA PARA EL JUGADOR
	elif card_data.effect_id == "cansancio_debug":
		player.aplicar_estado("cansancio", 0, 2)
	elif card_data.effect_id == "debil_jugador_debug":
		player.aplicar_estado("debil", 0, 2)
	elif card_data.effect_id == "bonus_defensa_debug":
		player.bonus_defensa += card_data.value
	elif card_data.effect_id == "fotocopia_borrosa":
		var drawn_cards := deck_manager.draw_cards(2)
		print("DEBUG Player: Fotocopia borrosa robó %d cartas." % drawn_cards.size())
		_show_hand()
		if not deck_manager.hand.is_empty():
			_begin_discard_selection("player_replace_one", 1, 0)
	elif card_data.effect_id == "cara_de_entendido":
		var block_amount := 9
		if not player_attacked_this_turn:
			block_amount += 4
		_gain_player_block(block_amount)
	elif card_data.effect_id == "respuesta_incompleta":
		_apply_player_attack(8)
		if enemy.current_hp * 2 < enemy.max_hp:
			deck_manager.draw_cards(1)
			_show_hand()
	elif card_data.effect_id == "hacer_tiempo":
		_gain_player_block(6)
		enemy.aplicar_estado("ataque_menos", 3, 1)
	elif card_data.effect_id == "cafecito_del_kiosko":
		var heal_amount := 10
		if player.current_hp <= 30:
			heal_amount += 5
		player.curar(heal_amount)
	elif card_data.effect_id == "grupo_silenciado":
		if deck_manager.hand.is_empty():
			_gain_player_block(0)
		else:
			_begin_discard_selection("player_optional_block", min(2, deck_manager.hand.size()), 0, 5)
	elif card_data.effect_id == "estudiar_en_x2":
		player.attack_bonus += 3
		player.attack_bonus_turns = max(player.attack_bonus_turns, 2)
		deck_manager.draw_cards(1)
		_show_hand()
	elif card_data.effect_id == "releer_la_consigna":
		_recover_last_discard_to_hand()
	elif card_data.effect_id == "chamuyo_academico":
		enemy.aplicar_estado("ataque_menos", 4, 2)
	elif card_data.effect_id == "preguntar_al_grupo":
		var new_cards := deck_manager.draw_cards(3)
		_show_hand()
		for drawn_card in new_cards:
			if _is_attack_card(drawn_card):
				_set_temporary_cost_modifier(drawn_card, -1)
				break
	elif card_data.effect_id == "apunte_heredado":
		player.defense_card_bonus = 4
		player.defense_card_bonus_turns = max(player.defense_card_bonus_turns, 3)
	elif card_data.effect_id == "borrador_magico":
		_gain_player_block(13)
		player.remove_one_negative_state()
	elif card_data.effect_id == "parcial_sorpresa":
		var damage := 18
		if enemy.tiene_estado("debil") or enemy.tiene_estado("vulnerable") or enemy.tiene_estado("distraccion") or enemy.tiene_estado("ataque_menos"):
			damage += 6
		_apply_player_attack(damage)
	elif card_data.effect_id == "crisis_pre_parcial":
		player.lose_hp(5)
		deck_manager.draw_cards(2)
		player.attack_bonus += 4
		player.attack_bonus_turns = max(player.attack_bonus_turns, 1)
		_show_hand()
	elif card_data.effect_id == "tutoria_express":
		player.curar(14)
		deck_manager.draw_cards(1)
		_show_hand()
	elif card_data.effect_id == "mate_compartido":
		player.current_energy += 1
		player.queue_extra_energy_next_turn(1)
	elif card_data.effect_id == "nervios_de_acero":
		player.aplicar_estado("nervios_de_acero", 0, 2)
	elif card_data.effect_id == "tema_que_si_sabias":
		var damage := 14
		if deck_manager.hand.size() >= 3:
			damage += 4
		_apply_player_attack(damage)
	elif card_data.effect_id == "recreo_estrategico":
		player.curar(8)
		_gain_player_block(6)
		player.remove_one_negative_state()
	elif card_data.effect_id == "final_promocionado":
		player.aplicar_estado("final_promocionado", 1, 3)
	elif card_data.effect_id == "mirar_el_parcial_del_companero":
		var peek_cards := deck_manager.draw_cards(1)
		_show_hand()
		if not peek_cards.is_empty() and _is_attack_card(peek_cards[0]):
			enemy.take_damage(5)
	elif card_data.effect_id == "boligrafo_sin_tinta":
		_apply_player_attack(4)
		if not deck_manager.hand.is_empty():
			_begin_discard_selection("player_replace_zero", 1, 0)
	elif card_data.effect_id == "excusa_creible":
		var block_amount := 7
		if deck_manager.hand.size() < 3:
			block_amount += 5
		_gain_player_block(block_amount)
	elif card_data.effect_id == "quedarse_sin_hojas":
		if deck_manager.hand.is_empty():
			deck_manager.draw_cards(1)
			_show_hand()
		else:
			_begin_discard_selection("player_replace_one", 1, 0)
	elif card_data.effect_id == "agua_del_dispenser":
		player.curar(6)
		player.remove_state("estres")
	elif card_data.effect_id == "sentarse_adelante":
		player.attack_bonus += 2
		player.attack_bonus_turns = max(player.attack_bonus_turns, 2)
		player.bonus_defensa += 3
		player.aplicar_estado("bonus_defensa_temporal", 3, 2)
	elif card_data.effect_id == "pedir_que_repita":
		enemy.aplicar_estado("ataque_menos", 3, 1)
		deck_manager.draw_cards(1)
		_show_hand()
	elif card_data.effect_id == "subrayador_fluorescente":
		player.next_attack_flat_bonus += 6
	elif card_data.effect_id == "apagar_la_camara":
		_gain_player_block(10)
		player.aplicar_estado("apagar_la_camara", 0, 1)
	elif card_data.effect_id == "audio_de_7_minutos":
		enemy.aplicar_estado("distraccion", 20, 2)
	elif card_data.effect_id == "resumen_ajeno":
		var drawn_cards := deck_manager.draw_cards(2)
		_show_hand()
		if not drawn_cards.is_empty():
			_set_temporary_cost_modifier(drawn_cards[0], -1)
	elif card_data.effect_id == "estudiar_la_noche_anterior":
		player.attack_bonus += 6
		player.attack_bonus_turns = max(player.attack_bonus_turns, 1)
		player.aplicar_estado("distraccion", 0, 1)
	elif card_data.effect_id == "parcial_recuperatorio":
		var heal_amount := 12
		if player.current_hp < 20:
			heal_amount += 10
		player.curar(heal_amount)
	elif card_data.effect_id == "cambio_de_aula":
		var hand_count := deck_manager.hand.size()
		deck_manager.discard_hand()
		deck_manager.draw_cards(hand_count)
		_show_hand()
	elif card_data.effect_id == "profe_de_buen_humor":
		player.current_energy += 2
		_gain_player_block(6)
	elif card_data.effect_id == "bibliografia_obligatoria":
		var damage := 20
		if deck_manager.hand.size() >= 5:
			damage += 5
		_apply_player_attack(damage)
	elif card_data.effect_id == "exposicion_improvisada":
		_apply_player_attack(10)
		player.aplicar_estado("estres", 0, 1)
	elif card_data.effect_id == "consulta_salvadora":
		player.curar(8)
		deck_manager.draw_cards(1)
		player.remove_one_negative_state()
		_show_hand()
	elif card_data.effect_id == "semana_sin_parciales":
		player.aplicar_estado("semana_sin_parciales", 1, 2)
		player.queue_extra_energy_next_turn(1)
	elif card_data.effect_id == "saber_todo_el_programa":
		var enemy_hp_before := enemy.current_hp
		_apply_player_attack(32)
		if enemy_hp_before > 0 and enemy.is_dead():
			player.curar(15)


func _play_machetearse() -> void:
	if randf() < 0.35:
		player.current_hp = 0
		return

	var damage := int(ceil(enemy.current_hp * 0.8))
	enemy.take_damage(player.get_attack_damage(damage))


# MODIFICADO: Ahora activa el modo selección si tienes cartas
func _discard_one_card_and_draw() -> void:
	if deck_manager.hand.is_empty():
		deck_manager.draw_cards(1)
		_show_hand()
	else:
		_begin_discard_selection("player_replace_one", 1, 0)

# AGREGADO: Nueva función que procesa la carta que el jugador decidió tirar
func _execute_discard_choice(card_data: CardData, card_ui: CardUI) -> void:
	if not deck_manager.discard_specific_card(card_data):
		return

	card_ui.queue_free()
	discard_selection_remaining -= 1
	discard_selection_completed += 1
	_show_hand()

	match discard_selection_mode:
		"player_replace_one":
			deck_manager.draw_cards(1)
			_reset_discard_selection()
			end_turn_button.disabled = false
			_show_hand()
			update_ui()
		"player_replace_zero":
			_reset_discard_selection()
			end_turn_button.disabled = false
			update_ui()
		"player_optional_block":
			if discard_selection_remaining <= 0 or deck_manager.hand.is_empty():
				var gained_block := discard_selection_completed * discard_selection_reward_block_per_card
				_gain_player_block(gained_block)
				_reset_discard_selection()
				end_turn_button.disabled = false
				update_ui()
			else:
				enemy_intent_label.text = "Descarta hasta %d carta(s) más" % discard_selection_remaining
				update_ui()
		"enemy_forced":
			if discard_selection_remaining <= 0 or deck_manager.hand.is_empty():
				_finish_enemy_forced_discard()
			else:
				enemy_intent_label.text = "Descarta %d carta(s) más" % discard_selection_remaining
				update_ui()
		_:
			_reset_discard_selection()
			update_ui()


func _execute_enemy_card(card_data: CardData) -> void:
	var player_hp_before := player.current_hp
	var player_block_before := player.block
	var enemy_hp_before := enemy.current_hp
	var enemy_block_before := enemy.block

	if not enemy.spend_energy(card_data.cost):
		print("DEBUG Enemy: no pudo pagar '%s'. Energía=%d coste=%d" % [card_data.card_name, enemy.current_energy, card_data.cost])
		return

	print("DEBUG Enemy: juega '%s' | energía antes/después %d/%d | efecto=%s" % [
		card_data.card_name,
		enemy.current_energy + card_data.cost,
		enemy.current_energy,
		card_data.raw_effect_text,
	])

	match card_data.effect_id:
		"pregunta_al_azar":
			var damage := 8
			if deck_manager.hand.size() >= 3:
				damage += 4
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"mirada_evaluadora":
			player.aplicar_estado("estres", 0, 1)
		"borrar_el_pizarron":
			deck_manager.discard_random_cards(1)
			_show_hand()
		"eso_ya_lo_vimos":
			var damage := 10
			if player.block <= 0:
				damage += 3
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"toma_asistencia":
			var block_gain := 8
			if player_cards_played_last_turn >= 3:
				block_gain += 5
			enemy.gain_block(block_gain)
		"cambiar_el_tema":
			player.aplicar_estado("distraccion", 0, 2)
		"parcialito_sorpresa":
			var damage := 14
			if player.has_negative_state():
				damage += 6
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"criterio_estricto":
			enemy.gain_attack_bonus(4, 2)
		"trabajo_practico_obligatorio":
			player.aplicar_estado("trabajo_practico_obligatorio", 1, 2)
		"explicacion_confusa":
			player.aplicar_estado("confusion", 0, 2)
		"unidad_acumulativa":
			enemy.gain_permanent_attack_bonus(2)
		"parcial_integrador":
			var damage := 18
			if deck_manager.hand.size() < 3:
				damage += 6
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"correccion_en_rojo":
			player.take_damage(enemy.calcular_dano_enemigo(12))
			player.aplicar_estado("estres", 0, 1)
		"recuperatorio_anunciado":
			enemy.gain_block(15)
			enemy.remove_one_negative_state()
		"pregunta_capciosa":
			if not _begin_enemy_forced_discard(2, 8):
				if not battle_has_ended:
					_finish_enemy_turn()
				enemy_turn_finished_by_card = true
				return
		"bibliografia_extra":
			player.aplicar_estado("bibliografia_extra", 1, 2)
		"oral_individual":
			player.take_damage_ignoring_block(enemy.calcular_dano_enemigo(24), 0.5)
		"cambio_de_consigna":
			deck_manager.discard_hand()
			deck_manager.draw_cards(3)
			skip_next_player_draw = true
			preserve_hand_for_next_turn = true
			_show_hand()
		"clase_de_repaso_mortal":
			enemy.gain_permanent_attack_bonus(5)
			enemy.gain_block(10)
		"final_con_tribunal":
			player.take_damage(enemy.calcular_dano_enemigo(30))
			player.aplicar_estado("estres", 0, 1)
			player.aplicar_estado("distraccion", 0, 1)
		"silencio_incomodo":
			player.aplicar_estado("estres", 0, 1)
			if deck_manager.hand.size() >= 4:
				deck_manager.discard_random_cards(1)
				_show_hand()
		"pregunta_de_repaso":
			var damage := 7
			if player_played_skill_last_turn:
				damage += 5
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"quien_quiere_pasar":
			player.aplicar_estado("panico", 0, 1)
		"lista_incompleta":
			_begin_enemy_forced_discard(1, 6)
		"dictado_acelerado":
			player.aplicar_estado("distraccion", 0, 1)
			player.aplicar_estado("defensa_menos", 0, 1)
		"ejemplo_sin_resolver":
			var damage := 13
			if player.tiene_estado("confusion"):
				damage += 5
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"carpeta_prolija":
			var block_gain := 9
			if enemy.attack_bonus > 0 or enemy.permanent_attack_bonus > 0:
				block_gain += 4
			enemy.gain_block(block_gain)
		"tema_que_entra_seguro":
			enemy.gain_attack_bonus(3, 2)
		"respuesta_incompleta":
			player.take_damage(enemy.calcular_dano_enemigo(12))
			player.block = max(player.block - 4, 0)
		"correccion_oral":
			player.aplicar_estado("estres", 0, 2)
		"consigna_ambigua":
			player.aplicar_estado("confusion", 0, 2)
		"teoria_acumulada":
			enemy.gain_permanent_attack_bonus(2)
			enemy.gain_block(6)
		"parcial_con_inciso_sorpresa":
			var damage := 17
			if deck_manager.hand.size() < 2:
				damage += 7
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"revision_severa":
			if not deck_manager.hand.is_empty():
				deck_manager.discard_random_cards(1)
				_show_hand()
			player.take_damage(enemy.calcular_dano_enemigo(_count_attack_cards_in_hand() * 4))
		"esto_es_basico":
			player.aplicar_estado("habilidad_mas", 0, 2)
		"bibliografia_obligatoria":
			player.aplicar_estado("distraccion", 0, 2)
		"mesa_examinadora":
			var damage := enemy.calcular_dano_enemigo(22)
			if enemy.block > 0:
				player.take_damage_ignoring_block(damage, 0.4)
			else:
				player.take_damage(damage)
		"criterio_invisible":
			enemy.gain_attack_bonus(4, 2)
			enemy.remove_one_negative_state()
		"cambio_de_fecha":
			deck_manager.discard_random_cards(2)
			deck_manager.draw_cards(1)
			_show_hand()
		"final_definitivo":
			var damage := 28
			if player.tiene_estado("estres") or player.tiene_estado("distraccion"):
				damage += 8
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		_:
			print("DEBUG Enemy: carta sin implementación específica '%s'." % card_data.card_name)

	print("DEBUG Enemy: resultado '%s' | jugador HP %d->%d | jugador escudo %d->%d | enemigo HP %d->%d | enemigo escudo %d->%d" % [
		card_data.card_name,
		player_hp_before,
		player.current_hp,
		player_block_before,
		player.block,
		enemy_hp_before,
		enemy.current_hp,
		enemy_block_before,
		enemy.block,
	])

	update_ui()
	check_combat_end()


func _begin_discard_selection(mode: String, amount: int, penalty_damage: int, reward_block_per_card: int = 0) -> void:
	waiting_for_discard = true
	discard_selection_mode = mode
	discard_selection_remaining = amount
	discard_selection_requested_total = amount
	discard_selection_completed = 0
	discard_selection_penalty_damage = penalty_damage
	discard_selection_reward_block_per_card = reward_block_per_card
	end_turn_button.disabled = true

	if mode == "enemy_forced":
		enemy_intent_label.text = "Descarta %d carta(s) de tu mano" % amount
	elif mode == "player_optional_block":
		enemy_intent_label.text = "Descarta hasta %d carta(s)" % amount
	else:
		enemy_intent_label.text = "Elige una carta para descartar"


func _begin_enemy_forced_discard(amount: int, penalty_damage: int) -> bool:
	var available_cards := deck_manager.hand.size()
	if available_cards <= 0:
		player.take_damage(penalty_damage)
		update_ui()
		check_combat_end()
		return false

	_begin_discard_selection("enemy_forced", min(amount, available_cards), penalty_damage)
	discard_selection_requested_total = amount
	return true


func _finish_enemy_forced_discard() -> void:
	var penalty_damage := discard_selection_penalty_damage
	var failed_discards := discard_selection_completed < discard_selection_requested_total

	_reset_discard_selection()

	if failed_discards:
		player.take_damage(penalty_damage)

	update_ui()
	check_combat_end()
	if not battle_has_ended:
		_finish_enemy_turn()


func _reset_discard_selection() -> void:
	waiting_for_discard = false
	discard_selection_mode = ""
	discard_selection_remaining = 0
	discard_selection_requested_total = 0
	discard_selection_completed = 0
	discard_selection_penalty_damage = 0
	discard_selection_reward_block_per_card = 0


func _gain_player_block(amount: int) -> void:
	player.gain_block(amount)


func _apply_player_attack(base_damage: int) -> void:
	enemy.take_damage(player.get_attack_damage(base_damage))


func _is_attack_card(card_data: CardData) -> bool:
	return card_data.card_type == "ataque" or card_data.effect_id == "basic_attack" or card_data.effect_id == "machetearse"


func _is_skill_card(card_data: CardData) -> bool:
	return card_data.card_type == "habilidad" or card_data.card_type == "defensa" or card_data.card_type == "robo" or card_data.card_type == "curacion" or card_data.card_type == "energia"


func _count_attack_cards_in_hand() -> int:
	var total := 0
	for card_data in deck_manager.hand:
		if _is_attack_card(card_data):
			total += 1
	return total


func _set_temporary_cost_modifier(card_data: CardData, modifier: int) -> void:
	temporary_card_cost_modifiers[card_data.get_instance_id()] = modifier


func _get_temporary_cost_modifier(card_data: CardData) -> int:
	var instance_id := card_data.get_instance_id()
	if not temporary_card_cost_modifiers.has(instance_id):
		return 0
	return int(temporary_card_cost_modifiers[instance_id])


func _recover_last_discard_to_hand() -> void:
	if deck_manager.discard_pile.is_empty():
		return
	var recovered_card: CardData = deck_manager.discard_pile.pop_back()
	deck_manager.hand.append(recovered_card)
	_show_hand()
