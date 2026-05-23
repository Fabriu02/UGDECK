
extends Node
class_name CombatManager

const EnemyCardLoader := preload("res://scripts/EnemyCardLoader.gd")
const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")
const MAP_SCENE_PATH := "res://scenes/map/vista_mapa.tscn"
const PLAYER_DRAW_PER_TURN := 3
const FIRST_ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const SECOND_ENEMY_IMAGE_PATH := "res://assets/characters/pepo enemigo 2.png"
const INTEGRAL_MINIBOSS_IMAGE_PATH := "res://assets/characters/integral_maldita.png"
const CALCULUS_MINIBOSS_IMAGE_PATH := "res://assets/characters/calculus_libro_fondo_transparente.png"
const CALCULADORA_MINIBOSS_IMAGE_PATH := "res://assets/characters/calculadora_maldita_pixelart_transparente.png"
const GOBLIN_VOLTIMETRO_IMAGE_PATH := "res://assets/characters/goblin_voltimetro_fondo_transparente.png"
const GOBLIN_FISICA_2_IMAGE_PATH := "res://assets/characters/goblin_fisica2_fondo_transparente.png"
const GOBLIN_NOTEBOOK_FISICA_3_IMAGE_PATH := "res://assets/characters/goblin_notebook_fisica3_transparente.png"
const FIRST_ENEMY_MAX_HP := 50
const FIRST_ENEMY_BASE_BLOCK := 0
const SECOND_ENEMY_MAX_HP := 250
const SECOND_ENEMY_BASE_BLOCK := 15
const FIRST_ENEMY_NAME := "Tom Apostol"
const SECOND_ENEMY_NAME := "Pepo"
const MINIBOSS_INTEGRAL_TRIPLE := "integral_triple"
const MINIBOSS_CALCULUS := "calculus"
const MINIBOSS_CALCULADORA_VIEJA := "calculadora_vieja"
const ENEMY_GOBLIN_VOLTIMETRO := "goblin_voltimetro"
const ENEMY_GOBLIN_FISICA_2 := "goblin_fisica_2"
const ENEMY_GOBLIN_NOTEBOOK_FISICA_3 := "goblin_notebook_fisica_3"
const CALCULUS_MINIBOSS_SCALE := Vector2(0.18, 0.18)
const CALCULADORA_MINIBOSS_SCALE := Vector2(0.16, 0.16)
const GOBLIN_MINIBOSS_SCALE := Vector2(0.22, 0.22)

@export var card_scene: PackedScene = preload("res://scenes/Card.tscn")

@onready var player: Player = $"../Player"
@onready var enemy: Enemy = $"../Enemy"
@onready var deck_manager: DeckManager = $"../DeckManager"

@onready var player_stats_label: Label = $"../UI/PlayerStatsLabel"
@onready var enemy_stats_label: Label = $"../UI/EnemyStatsLabel"
@onready var energy_label: Label = $"../UI/EnergyLabel"
@onready var enemy_intent_label: Label = $"../UI/EnemyIntentLabel"
@onready var hand_container: HBoxContainer = $"../UI/HandContainer"
@onready var card_animation_layer: Control = $"../UI/CardAnimationLayer"
@onready var draw_pile_area: Control = $"../UI/DrawPileArea"
@onready var draw_pile_panel: Panel = $"../UI/DrawPileArea/PilePanel"
@onready var discard_pile_area: Control = $"../UI/DiscardPileArea"
@onready var discard_pile_panel: Panel = $"../UI/DiscardPileArea/PilePanel"
@onready var draw_pile_count_label: Label = $"../UI/DrawPileArea/CountLabel"
@onready var discard_pile_count_label: Label = $"../UI/DiscardPileArea/CountLabel"
@onready var deck_viewer_panel: Panel = $"../UI/DeckViewerPanel"
@onready var deck_viewer_title_label: Label = $"../UI/DeckViewerPanel/ViewerVBox/HeaderBox/DeckViewerTitleLabel"
@onready var deck_viewer_cards_container: GridContainer = $"../UI/DeckViewerPanel/ViewerVBox/DeckViewerScroll/DeckViewerCardsContainer"
@onready var close_deck_viewer_button: Button = $"../UI/DeckViewerPanel/ViewerVBox/HeaderBox/CloseDeckViewerButton"
@onready var reward_panel: Panel = $"../UI/RewardPanel"
@onready var reward_cards_container: HBoxContainer = $"../UI/RewardPanel/RewardVBox/RewardCardsContainer"
@onready var start_fight_banner: Control = $"../UI/StartFightBanner"
@onready var start_fight_banner_panel: Panel = $"../UI/StartFightBanner/Panel"
@onready var start_fight_banner_label: Label = $"../UI/StartFightBanner/Panel/Label"
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
var multi_enemy_hps: Array = []
var multi_enemy_names: Array = []
var multi_enemy_active := false

# AGREGADO: Variable para el artilugio "Calculadora Científica"
var primera_carta_combate_gratis := false


func _ready() -> void:
	randomize()
	deck_manager.deck_counts_changed.connect(_update_deck_zone_ui)
	draw_pile_area.mouse_filter = Control.MOUSE_FILTER_STOP
	discard_pile_area.mouse_filter = Control.MOUSE_FILTER_STOP
	draw_pile_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	discard_pile_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ignore_mouse_on_children(draw_pile_area)
	_ignore_mouse_on_children(discard_pile_area)
	draw_pile_area.gui_input.connect(_on_draw_pile_area_gui_input)
	discard_pile_area.gui_input.connect(_on_discard_pile_area_gui_input)
	draw_pile_area.mouse_entered.connect(_on_draw_pile_area_mouse_entered)
	draw_pile_area.mouse_exited.connect(_on_draw_pile_area_mouse_exited)
	discard_pile_area.mouse_entered.connect(_on_discard_pile_area_mouse_entered)
	discard_pile_area.mouse_exited.connect(_on_discard_pile_area_mouse_exited)
	close_deck_viewer_button.pressed.connect(_hide_deck_viewer)
	end_turn_button.pressed.connect(end_player_turn)
	abandon_combat_button.pressed.connect(abandon_combat)
	await start_battle()


func _ignore_mouse_on_children(control: Control) -> void:
	for child in control.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			_ignore_mouse_on_children(child as Control)


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
	multi_enemy_active = false
	multi_enemy_hps.clear()
	multi_enemy_names.clear()
	temporary_card_cost_modifiers.clear()
	_configure_enemy_for_current_node()
	player.reset_for_new_battle()
	enemy.reset_for_new_battle()
	
	# --- AGREGADO: REVISAMOS LA MOCHILA AL EMPEZAR ---
	_aplicar_artilugios_inicio_combate()
	# -------------------------------------------------
	
	deck_manager.create_starting_deck()
	enemy.choose_next_intent(player, 0, player_cards_played_last_turn)
	await _show_start_fight_banner()
	await start_player_turn()

# --- AGREGADO: LÓGICA DE ARTILUGIOS ---
func _aplicar_artilugios_inicio_combate() -> void:
	primera_carta_combate_gratis = false
	
	for nombre_artilugio in GameState.artilugios:
		if GameState.INFO_ARTILUGIOS.has(nombre_artilugio):
			var info = GameState.INFO_ARTILUGIOS[nombre_artilugio]
			
			# Efectos que pasan ni bien entras a la pelea
			if info.tipo == "inicio_combate":
				if info.efecto == "escudo_inicial":
					_gain_player_block(info.valor)
					print("🛡️ ARTILUGIO: Apuntes te dieron ", info.valor, " de escudo.")
			
			# Efectos que se quedan "escuchando" en la pelea
			elif info.tipo == "pasivo_combate":
				if info.efecto == "costo_cero":
					primera_carta_combate_gratis = true
					print("⚡ ARTILUGIO: Calculadora lista. Tu primera carta costará 0.")
# ---------------------------------------


func _configure_enemy_for_current_node() -> void:
	var combat_kind := GameState.get_current_combat_kind()
	if combat_kind == "miniboss":
		_configure_miniboss(GameState.get_current_miniboss_id())
	elif combat_kind == "intermediate":
		_configure_miniboss(GameState.get_current_miniboss_id())
	elif combat_kind == "boss":
		battle_visuals.clear_multi_enemy_visuals()
		_configure_zone_boss()
	else:
		battle_visuals.clear_multi_enemy_visuals()
		enemy.max_hp = FIRST_ENEMY_MAX_HP
		enemy.base_block = FIRST_ENEMY_BASE_BLOCK
		enemy.max_energy = 5
		enemy.set_professor_deck(_load_current_zone_enemy_deck())
		battle_visuals.set_enemy_image(FIRST_ENEMY_IMAGE_PATH)
		battle_visuals.set_enemy_display_name(FIRST_ENEMY_NAME)
		current_enemy_name = FIRST_ENEMY_NAME


func _configure_zone_boss() -> void:
	var node_data := GameState.get_current_node_data()
	var boss_name := String(node_data.get("encounter_name", FIRST_ENEMY_NAME))

	if boss_name == SECOND_ENEMY_NAME:
		enemy.max_hp = SECOND_ENEMY_MAX_HP
		enemy.base_block = SECOND_ENEMY_BASE_BLOCK
		enemy.max_energy = 5
		enemy.set_professor_deck(EnemyCardLoader.load_professor_cards_by_rarities(["Desertor", "Ingresante"]))
		battle_visuals.set_enemy_image(SECOND_ENEMY_IMAGE_PATH)
		battle_visuals.set_enemy_display_name(SECOND_ENEMY_NAME)
		current_enemy_name = SECOND_ENEMY_NAME
	else:
		enemy.max_hp = FIRST_ENEMY_MAX_HP
		enemy.base_block = FIRST_ENEMY_BASE_BLOCK
		enemy.max_energy = 5
		enemy.set_professor_deck(EnemyCardLoader.load_professor_cards_by_rarity("Desertor"))
		battle_visuals.set_enemy_image(FIRST_ENEMY_IMAGE_PATH)
		battle_visuals.set_enemy_display_name(FIRST_ENEMY_NAME)
		current_enemy_name = FIRST_ENEMY_NAME


func _configure_miniboss(miniboss_id: String) -> void:
	enemy.base_block = 0
	enemy.max_energy = 3
	enemy.set_professor_deck(_load_current_zone_enemy_deck())

	match miniboss_id:
		MINIBOSS_INTEGRAL_TRIPLE:
			multi_enemy_active = true
			multi_enemy_names = ["Integral 1", "Integral 2", "Integral 3"]
			multi_enemy_hps = [15, 15, 15]
			enemy.max_hp = 45
			enemy.current_hp = 45
			current_enemy_name = "Integral Triple"
			battle_visuals.set_enemy_display_name(current_enemy_name)
			battle_visuals.show_multi_enemy_group(INTEGRAL_MINIBOSS_IMAGE_PATH, multi_enemy_names, multi_enemy_hps)
			for index in range(multi_enemy_hps.size()):
				print("%s vida: %d" % [multi_enemy_names[index], multi_enemy_hps[index]])
		MINIBOSS_CALCULUS:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 40
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Calculus"
			battle_visuals.set_enemy_image(CALCULUS_MINIBOSS_IMAGE_PATH, CALCULUS_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		MINIBOSS_CALCULADORA_VIEJA:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 25
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Calculadora vieja"
			battle_visuals.set_enemy_image(CALCULADORA_MINIBOSS_IMAGE_PATH, CALCULADORA_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_VOLTIMETRO:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 60
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Goblin voltimetro"
			battle_visuals.set_enemy_image(GOBLIN_VOLTIMETRO_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_FISICA_2:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 85
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Goblin fisica 2"
			battle_visuals.set_enemy_image(GOBLIN_FISICA_2_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_NOTEBOOK_FISICA_3:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 110
			enemy.max_energy = 4
			enemy.base_block = 0
			current_enemy_name = "Goblin notebook fisica 3"
			battle_visuals.set_enemy_image(GOBLIN_NOTEBOOK_FISICA_3_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		_:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 40
			enemy.max_energy = 3
			current_enemy_name = "Calculus"
			battle_visuals.set_enemy_image(CALCULUS_MINIBOSS_IMAGE_PATH, CALCULUS_MINIBOSS_SCALE)
			battle_visuals.set_enemy_display_name(current_enemy_name)


func _load_current_zone_enemy_deck() -> Array[CardData]:
	var zone_index := _get_current_zone_index()
	if zone_index >= 2:
		return EnemyCardLoader.load_professor_cards_by_rarities(["Desertor", "Ingresante"])
	return EnemyCardLoader.load_professor_cards_by_rarity("Desertor")


func _get_current_zone_index() -> int:
	var node_data := GameState.get_current_node_data()
	return int(node_data.get("zone_index", 1))


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
		_show_hand()
	else:
		preserve_hand_for_next_turn = false
		var draw_amount := player.get_draw_amount(PLAYER_DRAW_PER_TURN)
		var drawn_cards := deck_manager.draw_cards(draw_amount)
		await _animate_drawn_cards(drawn_cards)

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
	
	# --- AGREGADO: ARTILUGIO CALCULADORA ---
	if primera_carta_combate_gratis:
		effective_cost = 0
		primera_carta_combate_gratis = false # Se desactiva para el resto del combate
		print("⚡ ARTILUGIO: ¡Tu carta costó 0 energía!")
	# ---------------------------------------

	if not player.spend_energy(effective_cost):
		update_ui()
		return

	deck_manager.hand.erase(card_data)
	deck_manager.played_cards.append(card_data)
	deck_manager.print_deck_debug_counts()
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
	if multi_enemy_active:
		enemy_stats_label.text = "%s | %s | Escudo: %d" % [
			current_enemy_name,
			_get_multi_enemy_status_text(),
			enemy.block
		]
	energy_label.text = "Energia: %d/%d" % [player.current_energy, player.max_energy]
	_update_deck_zone_ui()
	
	# AGREGADO: Solo actualizamos el texto de intención si NO estamos en modo descarte
	if not waiting_for_discard:
		enemy_intent_label.text = enemy.get_intent_text(player, deck_manager.hand.size(), player_cards_played_last_turn)


func _update_deck_zone_ui() -> void:
	draw_pile_count_label.text = "%d cartas" % _get_available_deck_cards().size()
	discard_pile_count_label.text = "%d cartas" % deck_manager.discard_pile.size()


func _on_draw_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_pile_viewer("Mazo disponible", _get_available_deck_cards())


func _on_discard_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_pile_viewer("Mazo de descarte", deck_manager.discard_pile)


func _on_draw_pile_area_mouse_entered() -> void:
	_set_pile_hover(draw_pile_panel, true)


func _on_draw_pile_area_mouse_exited() -> void:
	_set_pile_hover(draw_pile_panel, false)


func _on_discard_pile_area_mouse_entered() -> void:
	_set_pile_hover(discard_pile_panel, true)


func _on_discard_pile_area_mouse_exited() -> void:
	_set_pile_hover(discard_pile_panel, false)


func _set_pile_hover(panel: Panel, is_hovered: bool) -> void:
	panel.modulate = Color(1.18, 1.18, 1.18, 1.0) if is_hovered else Color.WHITE


func _get_available_deck_cards() -> Array[CardData]:
	var available_cards: Array[CardData] = []
	available_cards.append_array(deck_manager.draw_pile)
	available_cards.append_array(deck_manager.hand)
	return available_cards


func _show_pile_viewer(title: String, cards: Array) -> void:
	for child in deck_viewer_cards_container.get_children():
		child.queue_free()

	var grouped_cards := _group_cards_by_current_copies(cards)
	var unique_cards: Array = grouped_cards["cards"]
	var copy_counts: Dictionary = grouped_cards["counts"]

	deck_viewer_title_label.text = title
	print("%s: %d cartas totales, %d cartas unicas" % [title, cards.size(), unique_cards.size()])
	for card_data in unique_cards:
		var card_key := _get_card_group_key(card_data)
		var copy_count := int(copy_counts.get(card_key, 1))

		var card_ui: CardUI = card_scene.instantiate()
		deck_viewer_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.name_label.text = "%s x%d" % [card_data.card_name, copy_count]
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	deck_viewer_panel.visible = true


func _group_cards_by_current_copies(cards: Array) -> Dictionary:
	var unique_cards: Array = []
	var copy_counts: Dictionary = {}
	var seen_keys := {}

	for card_data in cards:
		var card_key := _get_card_group_key(card_data)
		copy_counts[card_key] = int(copy_counts.get(card_key, 0)) + 1
		if not seen_keys.has(card_key):
			seen_keys[card_key] = true
			unique_cards.append(card_data)

	return {
		"cards": unique_cards,
		"counts": copy_counts,
	}


func _get_card_group_key(card_data: CardData) -> String:
	if not card_data.effect_id.is_empty():
		return card_data.effect_id
	return card_data.card_name


func _hide_deck_viewer() -> void:
	deck_viewer_panel.visible = false


func _get_multi_enemy_status_text() -> String:
	var parts: Array[String] = []
	for index in range(multi_enemy_hps.size()):
		parts.append("%s: %d/15" % [multi_enemy_names[index], multi_enemy_hps[index]])
	return " | ".join(parts)


func check_combat_end() -> void:
	if _is_current_encounter_defeated():
		battle_has_ended = true
		if GameState.get_current_combat_kind() == "miniboss":
			print("Minijefe derrotado")
		enemy_intent_label.text = "Victoria: aprobaste este combate."
		end_turn_button.disabled = true
		_clear_hand_ui()
		_show_card_reward()
	elif player.is_dead():
		battle_has_ended = true
		enemy_intent_label.text = "Derrota: el cuatrimestre te supero."
		end_turn_button.disabled = true
		_clear_hand_ui()
		GameState.volver_al_primer_nodo()
		_return_to_map()


func _is_current_encounter_defeated() -> bool:
	if multi_enemy_active:
		for hp in multi_enemy_hps:
			if hp > 0:
				return false
		return true

	return enemy.is_dead()


func _get_current_encounter_hp() -> int:
	if multi_enemy_active:
		return _get_multi_enemy_total_hp()
	return enemy.current_hp


func complete_first_battle_and_return_to_map() -> void:
	GameState.completar_nodo_actual()
	_return_to_map()


func _show_card_reward() -> void:
	print("Combate ganado, generando recompensa")
	var reward_rarities := _get_current_reward_rarities()
	print("Rareza de recompensa actual: %s" % ", ".join(reward_rarities))

	for child in reward_cards_container.get_children():
		child.queue_free()

	var reward_options := PlayerCardLoader.load_reward_options_by_rarities(reward_rarities, 3)
	var option_names: Array[String] = []
	for card_data in reward_options:
		option_names.append(card_data.card_name)

	print("Opciones de recompensa: %s" % ", ".join(option_names))

	reward_panel.visible = true
	for card_data in reward_options:
		var card_ui: CardUI = card_scene.instantiate()
		reward_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_clicked.connect(_on_reward_card_selected)


func _get_current_reward_rarities() -> Array[String]:
	if _get_current_zone_index() >= 2:
		return ["Ingresante", "Recursante"]
	return [GameState.rareza_recompensa_actual]


func _on_reward_card_selected(card_data: CardData, _card_ui: CardUI) -> void:
	print("Carta elegida: %s" % card_data.card_name)
	GameState.add_card_to_run_deck(card_data)
	reward_panel.visible = false
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
		var card_ui: CardUI = card_scene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_clicked.connect(play_card)


func _show_start_fight_banner() -> void:
	start_fight_banner_label.text = "COMIENZA EL COMBATE"
	start_fight_banner.visible = true
	start_fight_banner.modulate.a = 0.0
	await get_tree().process_frame
	start_fight_banner_panel.scale = Vector2(0.82, 0.82)
	start_fight_banner_panel.pivot_offset = start_fight_banner_panel.size / 2.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		start_fight_banner,
		"modulate:a",
		1.0,
		0.22
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		start_fight_banner_panel,
		"scale",
		Vector2.ONE,
		0.32
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished
	await get_tree().create_timer(0.65).timeout

	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(
		start_fight_banner,
		"modulate:a",
		0.0,
		0.28
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await fade_tween.finished
	start_fight_banner.visible = false
	start_fight_banner.modulate.a = 1.0
	start_fight_banner_panel.scale = Vector2.ONE


func animate_card_draw(card_data: CardData) -> void:
	var drawn_cards: Array[CardData] = [card_data]
	await _animate_drawn_cards(drawn_cards)


func _animate_drawn_cards(drawn_cards: Array[CardData]) -> void:
	_clear_hand_ui()

	var remaining_drawn_cards: Array[CardData] = drawn_cards.duplicate()
	for card_data in deck_manager.hand:
		if remaining_drawn_cards.has(card_data):
			remaining_drawn_cards.erase(card_data)
		else:
			var card_ui: CardUI = card_scene.instantiate()
			hand_container.add_child(card_ui)
			card_ui.setup(card_data)
			card_ui.card_clicked.connect(play_card)

	if drawn_cards.is_empty():
		return

	await get_tree().process_frame

	var existing_card_count: int = hand_container.get_child_count()
	var final_card_count: int = existing_card_count + drawn_cards.size()
	var animated_cards: Array[CardUI] = []

	for index in range(drawn_cards.size()):
		var card_data: CardData = drawn_cards[index]
		var card_ui: CardUI = card_scene.instantiate()
		card_animation_layer.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.disabled = true
		card_ui.global_position = _get_card_draw_start_position(card_ui, index, drawn_cards.size())
		card_ui.scale = Vector2(0.2, 0.2)
		card_ui.modulate.a = 0.0
		animated_cards.append(card_ui)

	await get_tree().process_frame

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	for index in range(animated_cards.size()):
		var card_ui: CardUI = animated_cards[index]
		var delay: float = index * 0.08
		var final_position: Vector2 = _get_hand_card_position(existing_card_count + index, final_card_count)

		tween.tween_property(
			card_ui,
			"global_position",
			final_position,
			0.35
		).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			card_ui,
			"scale",
			Vector2.ONE,
			0.35
		).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			card_ui,
			"modulate:a",
			1.0,
			0.20
		).set_delay(delay)

	await tween.finished

	for card_ui in animated_cards:
		card_animation_layer.remove_child(card_ui)
		hand_container.add_child(card_ui)
		card_ui.scale = Vector2.ONE
		card_ui.modulate.a = 1.0
		card_ui.disabled = false
		card_ui.card_clicked.connect(play_card)


func _get_card_draw_start_position(card_ui: CardUI, card_index: int = 0, card_count: int = 1) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var card_width: float = maxf(card_ui.size.x, card_ui.custom_minimum_size.x)
	var spacing: float = 24.0
	var total_width: float = card_width * card_count + spacing * maxi(card_count - 1, 0)
	var x: float = viewport_size.x / 2.0 - total_width / 2.0 + (card_width + spacing) * card_index
	var y: float = viewport_size.y + 40.0
	return Vector2(x, y)


func _get_next_hand_card_position() -> Vector2:
	var card_count: int = hand_container.get_child_count()
	return _get_hand_card_position(card_count, card_count + 1)


func _get_hand_card_position(card_index: int, card_count: int) -> Vector2:
	var card_width: float = 170.0
	var spacing: float = 10.0
	var total_width: float = card_width * card_count + spacing * maxi(card_count - 1, 0)
	var hand_width: float = hand_container.size.x
	var hand_left: float = hand_container.global_position.x
	var x: float = hand_left + hand_width / 2.0 - total_width / 2.0 + (card_width + spacing) * card_index
	var y: float = hand_container.global_position.y

	return Vector2(x, y)


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
			_apply_damage_to_current_enemy(5)
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
		var enemy_hp_before := _get_current_encounter_hp()
		_apply_player_attack(32)
		if enemy_hp_before > 0 and _is_current_encounter_defeated():
			player.curar(15)
	else:
		_apply_generic_player_card_effect(card_data)


func _play_machetearse() -> void:
	if randf() < 0.35:
		player.current_hp = 0
		return

	var damage := int(ceil(_get_current_encounter_hp() * 0.8))
	_apply_damage_to_current_enemy(player.get_attack_damage(damage))


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

	print("DEBUG Enemy: juega '%s' [%s] | energía antes/después %d/%d | efecto=%s" % [
		card_data.card_name,
		card_data.rareza,
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
			_apply_generic_enemy_card_effect(card_data)
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
	_apply_damage_to_current_enemy(player.get_attack_damage(base_damage))


func _apply_damage_to_current_enemy(amount: int) -> void:
	if not multi_enemy_active:
		enemy.take_damage(amount)
		return

	var target_index := _get_first_alive_multi_enemy_index()
	if target_index == -1:
		return

	var remaining_damage := amount
	if enemy.block > 0:
		var blocked_damage = min(enemy.block, remaining_damage)
		enemy.block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage <= 0:
		return

	multi_enemy_hps[target_index] = max(multi_enemy_hps[target_index] - remaining_damage, 0)
	enemy.current_hp = _get_multi_enemy_total_hp()
	battle_visuals.update_multi_enemy_labels(multi_enemy_hps)
	print("%s vida: %d" % [multi_enemy_names[target_index], multi_enemy_hps[target_index]])


func _get_first_alive_multi_enemy_index() -> int:
	for index in range(multi_enemy_hps.size()):
		if multi_enemy_hps[index] > 0:
			return index
	return -1


func _get_multi_enemy_total_hp() -> int:
	var total := 0
	for hp in multi_enemy_hps:
		total += hp
	return total


func _apply_generic_player_card_effect(card_data: CardData) -> void:
	var effect_text := EnemyCardLoader._normalize_text(card_data.raw_effect_text)
	var amount := _get_card_amount(card_data)

	match card_data.card_type:
		"ataque":
			if amount > 0:
				_apply_player_attack(amount)
		"defensa":
			if amount > 0:
				_gain_player_block(amount)
			_apply_generic_state_effects_to_enemy(effect_text)
		"curacion":
			if amount > 0:
				player.curar(amount)
			if effect_text.contains("elimina") or effect_text.contains("descarta 1 estado"):
				player.remove_one_negative_state()
		"robo":
			if amount > 0:
				deck_manager.draw_cards(amount)
				_show_hand()
		"energia":
			if amount > 0:
				player.current_energy += amount
		"debuff enemigo":
			_apply_generic_state_effects_to_enemy(effect_text)
			_draw_from_effect_text(effect_text)
		"buff propio":
			_apply_generic_player_buff_effect(effect_text)
			_draw_from_effect_text(effect_text)
		"estados negativos", "estado(debuff)":
			_apply_generic_player_negative_effect(effect_text)
		"descarte_control de mano":
			_apply_generic_player_discard_effect(effect_text, amount)
		"habilidad", "estado(buff)":
			_apply_generic_player_buff_effect(effect_text)
			_draw_from_effect_text(effect_text)
		_:
			print("DEBUG Player: carta sin implementacion generica '%s' tipo=%s efecto=%s" % [
				card_data.card_name,
				card_data.card_type,
				card_data.raw_effect_text,
			])


func _apply_generic_enemy_card_effect(card_data: CardData) -> void:
	var effect_text := EnemyCardLoader._normalize_text(card_data.raw_effect_text)
	var amount := _get_card_amount(card_data)

	match card_data.card_type:
		"ataque":
			if amount > 0:
				var damage := enemy.calcular_dano_enemigo(amount)
				var ignored_block_ratio := _extract_percent(effect_text) / 100.0
				if ignored_block_ratio > 0.0:
					player.take_damage_ignoring_block(damage, ignored_block_ratio)
				else:
					player.take_damage(damage)
			_apply_generic_state_effects_to_player(effect_text)
		"defensa":
			if amount > 0:
				enemy.gain_block(amount)
			if effect_text.contains("elimina"):
				enemy.remove_one_negative_state()
		"buff propio":
			_apply_generic_enemy_buff_effect(effect_text)
		"debuff enemigo", "estados negativos":
			_apply_generic_state_effects_to_player(effect_text)
		"descarte_control de mano":
			_apply_generic_enemy_discard_effect(effect_text, amount)


func _apply_generic_player_buff_effect(effect_text: String) -> void:
	var duration := _extract_duration(effect_text, 1)
	var amount := _extract_signed_amount(effect_text)

	if effect_text.contains("ataque") and amount != 0:
		player.attack_bonus += amount
		player.attack_bonus_turns = max(player.attack_bonus_turns, duration)

	if effect_text.contains("escudo"):
		var block_bonus := _extract_number_before(effect_text, "escudo")
		if block_bonus <= 0:
			block_bonus = amount
		if block_bonus > 0:
			player.bonus_defensa += block_bonus
			player.aplicar_estado("bonus_defensa_temporal", block_bonus, duration)

	if effect_text.contains("cuestan 1 energia menos") or effect_text.contains("cuesta 1 energia menos"):
		player.aplicar_estado("final_promocionado", 1, duration)


func _apply_generic_player_negative_effect(effect_text: String) -> void:
	var damage := _extract_number_after_any(effect_text, ["pierdes", "perdes", "pierde"])
	if damage > 0 and effect_text.contains("vida"):
		player.lose_hp(damage)

	_draw_from_effect_text(effect_text)
	_apply_generic_state_effects_to_player(effect_text)

	var attack_bonus := _extract_signed_amount(effect_text)
	if attack_bonus > 0 and effect_text.contains("ataque"):
		player.attack_bonus += attack_bonus
		player.attack_bonus_turns = max(player.attack_bonus_turns, _extract_duration(effect_text, 1))


func _apply_generic_player_discard_effect(effect_text: String, amount: int) -> void:
	if effect_text.contains("toda tu mano"):
		var hand_count := deck_manager.hand.size()
		deck_manager.discard_hand()
		if effect_text.contains("roba"):
			deck_manager.draw_cards(hand_count)
		_show_hand()
		return

	if amount <= 0:
		return

	var discard_amount = min(amount, deck_manager.hand.size())
	if discard_amount <= 0:
		return

	if effect_text.contains("roba"):
		_begin_discard_selection("player_replace_one", discard_amount, 0)
	else:
		_begin_discard_selection("player_replace_zero", discard_amount, 0)


func _apply_generic_enemy_buff_effect(effect_text: String) -> void:
	var amount := _extract_signed_amount(effect_text)
	var duration := _extract_duration(effect_text, 1)

	if effect_text.contains("ataque permanente") and amount > 0:
		enemy.gain_permanent_attack_bonus(amount)
	elif effect_text.contains("ataque") and amount > 0:
		enemy.gain_attack_bonus(amount, duration)

	var block_amount := _extract_number_after_any(effect_text, ["escudo"])
	if block_amount <= 0:
		block_amount = _extract_number_before(effect_text, "escudo")
	if block_amount > 0:
		enemy.gain_block(block_amount)

	if effect_text.contains("elimina"):
		enemy.remove_one_negative_state()


func _apply_generic_enemy_discard_effect(effect_text: String, amount: int) -> void:
	if effect_text.contains("toda su mano") or effect_text.contains("toda tu mano"):
		deck_manager.discard_hand()
		_draw_from_effect_text(effect_text)
		_show_hand()
		return

	if amount <= 0:
		return

	if effect_text.contains("elige") or effect_text.contains("descarta menos"):
		_begin_enemy_forced_discard(amount, _extract_number_after_any(effect_text, ["recibe"]))
	else:
		deck_manager.discard_random_cards(amount)
		_draw_from_effect_text(effect_text)
		_show_hand()


func _apply_generic_state_effects_to_enemy(effect_text: String) -> void:
	var duration := _extract_duration(effect_text, 1)

	if effect_text.contains("vulnerable"):
		enemy.aplicar_estado("vulnerable", 0, duration)
	if effect_text.contains("debil"):
		enemy.aplicar_estado("debil", 0, duration)
	if effect_text.contains("distraccion"):
		enemy.aplicar_estado("distraccion", 0, duration)
	if effect_text.contains("pierde") and effect_text.contains("ataque"):
		var amount := _extract_number_after_any(effect_text, ["pierde"])
		if amount > 0:
			enemy.aplicar_estado("ataque_menos", amount, duration)


func _apply_generic_state_effects_to_player(effect_text: String) -> void:
	var duration := _extract_duration(effect_text, 1)

	if effect_text.contains("estres"):
		player.aplicar_estado("estres", 0, duration)
	if effect_text.contains("distraccion"):
		player.aplicar_estado("distraccion", 0, duration)
	if effect_text.contains("confusion"):
		player.aplicar_estado("confusion", 0, duration)
	if effect_text.contains("panico"):
		player.aplicar_estado("panico", 0, duration)
	if effect_text.contains("cansancio"):
		player.aplicar_estado("cansancio", 0, duration)
	if effect_text.contains("defensa") and (effect_text.contains("menos") or effect_text.contains("25% menos")):
		player.aplicar_estado("defensa_menos", 0, duration)
	if effect_text.contains("habilidad") and (effect_text.contains("cuestan 1") or effect_text.contains("cuesta 1")):
		player.aplicar_estado("habilidad_mas", 0, duration)
	if effect_text.contains("roba 1 carta menos"):
		player.aplicar_estado("distraccion", 0, duration)


func _draw_from_effect_text(effect_text: String) -> void:
	var amount := _extract_number_after_any(effect_text, ["roba", "robas"])
	if amount <= 0:
		return

	deck_manager.draw_cards(amount)
	_show_hand()


func _get_card_amount(card_data: CardData) -> int:
	if card_data.value > 0:
		return card_data.value

	return _extract_first_number(EnemyCardLoader._normalize_text(card_data.raw_effect_text))


func _extract_duration(effect_text: String, fallback: int) -> int:
	var duration := _extract_number_before_any(effect_text, ["turno", "turnos"])
	if duration > 0:
		return duration
	return fallback


func _extract_signed_amount(effect_text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("[+-]\\d+") != OK:
		return 0

	var result := regex.search(effect_text)
	if result == null:
		return 0

	return result.get_string().to_int()


func _extract_percent(effect_text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+%") != OK:
		return 0

	var result := regex.search(effect_text)
	if result == null:
		return 0

	return result.get_string().replace("%", "").to_int()


func _extract_number_after_any(text: String, keywords: Array[String]) -> int:
	for keyword in keywords:
		var number := _extract_number_after(text, keyword)
		if number > 0:
			return number
	return 0


func _extract_number_after(text: String, keyword: String) -> int:
	var keyword_index := text.find(keyword)
	if keyword_index == -1:
		return 0

	return _extract_first_number(text.substr(keyword_index + keyword.length()))


func _extract_number_before_any(text: String, keywords: Array[String]) -> int:
	for keyword in keywords:
		var number := _extract_number_before(text, keyword)
		if number > 0:
			return number
	return 0


func _extract_number_before(text: String, keyword: String) -> int:
	var keyword_index := text.find(keyword)
	if keyword_index == -1:
		return 0

	var before_keyword := text.substr(0, keyword_index)
	var regex := RegEx.new()
	if regex.compile("\\d+") != OK:
		return 0

	var matches := regex.search_all(before_keyword)
	if matches.is_empty():
		return 0

	return matches[matches.size() - 1].get_string().to_int()


func _extract_first_number(text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+") != OK:
		return 0

	var result := regex.search(text)
	if result == null:
		return 0

	return result.get_string().to_int()


func _is_attack_card(card_data: CardData) -> bool:
	return card_data.card_type == "ataque" or card_data.effect_id == "basic_attack" or card_data.effect_id == "machetearse"


func _is_skill_card(card_data: CardData) -> bool:
	var skill_types := [
		"habilidad",
		"defensa",
		"robo",
		"curacion",
		"energia",
		"descarte_control de mano",
		"buff propio",
		"debuff enemigo",
		"estados negativos",
		"estado(buff)",
		"estado(debuff)",
	]
	return skill_types.has(card_data.card_type)


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
	deck_manager.print_deck_debug_counts()
	_show_hand()
