extends Node
class_name CombatManager

const CARD_SCENE := preload("res://scenes/Card.tscn")

@onready var player: Player = $"../Player"
@onready var enemy: Enemy = $"../Enemy"
@onready var deck_manager: DeckManager = $"../DeckManager"

@onready var player_stats_label: Label = $"../UI/PlayerStatsLabel"
@onready var enemy_stats_label: Label = $"../UI/EnemyStatsLabel"
@onready var energy_label: Label = $"../UI/EnergyLabel"
@onready var enemy_intent_label: Label = $"../UI/EnemyIntentLabel"
@onready var hand_container: HBoxContainer = $"../UI/HandContainer"
@onready var end_turn_button: Button = $"../UI/EndTurnButton"

var battle_has_ended := false
var skip_next_enemy_turn := false


func _ready() -> void:
	randomize()
	end_turn_button.pressed.connect(end_player_turn)
	start_battle()


func start_battle() -> void:
	battle_has_ended = false
	skip_next_enemy_turn = false
	end_turn_button.disabled = false
	player.reset_for_new_battle()
	enemy.reset_for_new_battle()
	deck_manager.create_starting_deck()
	enemy.choose_next_intent()
	start_player_turn()


func start_player_turn() -> void:
	if battle_has_ended:
		return

	player.reset_for_new_turn()

	if player.skip_next_player_turn:
		player.skip_next_player_turn = false
		_clear_hand_ui()
		update_ui()
		enemy_turn()
		return

	deck_manager.draw_cards(3)
	_show_hand()
	update_ui()


func play_card(card_data: CardData, card_ui: CardUI) -> void:
	if battle_has_ended:
		return

	if not deck_manager.hand.has(card_data):
		return

	if not player.spend_energy(card_data.cost):
		update_ui()
		return

	deck_manager.hand.erase(card_data)
	deck_manager.played_cards.append(card_data)
	card_ui.queue_free()

	_apply_card_effect(card_data)
	update_ui()
	check_combat_end()


func end_player_turn() -> void:
	if battle_has_ended:
		return

	for card_data in deck_manager.hand:
		if card_data.effect_id == "sentarse_fondo":
			player.gain_block(5)

	deck_manager.discard_hand()
	deck_manager.discard_played_cards()
	_clear_hand_ui()
	enemy_turn()


func enemy_turn() -> void:
	if skip_next_enemy_turn:
		skip_next_enemy_turn = false
	else:
		enemy.execute_intent(player)

	check_combat_end()

	if battle_has_ended:
		return

	enemy.choose_next_intent()
	start_player_turn()


func update_ui() -> void:
	player_stats_label.text = "Jugador - Vida: %d/%d | Escudo: %d" % [
		player.current_hp,
		player.max_hp,
		player.block
	]
	enemy_stats_label.text = "Tom Apostol - Vida: %d/%d | Escudo: %d" % [
		enemy.current_hp,
		enemy.max_hp,
		enemy.block
	]
	energy_label.text = "Energia: %d/%d" % [player.current_energy, player.max_energy]
	enemy_intent_label.text = enemy.get_intent_text()


func check_combat_end() -> void:
	if enemy.is_dead():
		battle_has_ended = true
		enemy_intent_label.text = "Victoria: aprobaste este combate."
		end_turn_button.disabled = true
		_clear_hand_ui()
	elif player.is_dead():
		battle_has_ended = true
		enemy_intent_label.text = "Derrota: el cuatrimestre te supero."
		end_turn_button.disabled = true
		_clear_hand_ui()


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
		enemy.take_damage(player.get_attack_damage(card_data.value))
	elif card_data.effect_id == "basic_block":
		player.gain_block(card_data.value)
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
		player.gain_block(card_data.value)
	elif card_data.effect_id == "pasar_pizarron":
		player.increase_max_hp(card_data.value)
	elif card_data.effect_id == "corte_luz":
		skip_next_enemy_turn = true
		deck_manager.discard_hand()
		_show_hand()
	elif card_data.effect_id == "dormir_siesta":
		_discard_one_card_and_draw()


func _play_machetearse() -> void:
	if randf() < 0.35:
		player.current_hp = 0
		return

	var damage := int(ceil(enemy.current_hp * 0.8))
	enemy.take_damage(player.get_attack_damage(damage))


func _discard_one_card_and_draw() -> void:
	if not deck_manager.hand.is_empty():
		var discarded_card: CardData = deck_manager.hand.pop_front()
		deck_manager.discard_pile.append(discarded_card)

	deck_manager.draw_cards(1)
	_show_hand()
