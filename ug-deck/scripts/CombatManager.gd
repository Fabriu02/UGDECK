
extends Node
class_name CombatManager

const EnemyCardLoader := preload("res://scripts/EnemyCardLoader.gd")
const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")
const CombatAnimationController := preload("res://scripts/CombatAnimationController.gd")
const PLAYER_COMBAT_HUD_SCRIPT := preload("res://scripts/ui/PlayerCombatHUD.gd")
const STATUS_EFFECT_INFO_SCRIPT := preload("res://scripts/ui/StatusEffectInfo.gd")
const COMBAT_ANNOUNCEMENT_OVERLAY_SCENE := preload("res://scenes/ui/CombatAnnouncementOverlay.tscn")
const ZONE_BOSS_REWARD_SCREEN_SCENE := preload("res://scenes/ui/ZoneBossRewardScreen.tscn")
const GAME_OVER_OVERLAY_SCENE := preload("res://scenes/ui/GameOverOverlay.tscn")
const MAP_SCENE_PATH := "res://scenes/map/vista_mapa.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/menu/MainMenu.tscn"
const EXTRA_RARE_REWARD_RARITIES: Array[String] = ["Ingeniero"]
const BOSS_REWARD_ICON_BED := "res://assets/iconos/bed.png"
const BOSS_REWARD_ICON_LUNGS := "res://assets/iconos/lungs.png"
const BOSS_REWARD_ICON_COFFEE_POT := "res://assets/iconos/coffee-pot.png"
const BOSS_REWARD_ICON_COFFEE_CUP := "res://assets/iconos/coffee-cup.png"
const BOSS_REWARD_ICON_MEDITATION := "res://assets/iconos/meditation.png"
const BOSS_REWARD_ICON_CONFIRMED := "res://assets/iconos/confirmed.png"
const PLAYER_DRAW_PER_TURN := 3
const DRAW_PILE_ICON_PATH := "res://assets/iconos/card-draw.png"
const DISCARD_PILE_ICON_PATH := "res://assets/iconos/card-burn.png"
const FIRST_ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const SECOND_ENEMY_IMAGE_PATH := "res://assets/characters/pepo enemigo 2.png"
const INTEGRAL_MINIBOSS_IMAGE_PATH := "res://assets/characters/integral_maldita.png"
const CALCULUS_MINIBOSS_IMAGE_PATH := "res://assets/characters/calculus_libro_fondo_transparente.png"
const CALCULADORA_MINIBOSS_IMAGE_PATH := "res://assets/characters/calculadora_maldita_pixelart_transparente.png"
const GOBLIN_VOLTIMETRO_IMAGE_PATH := "res://assets/characters/goblin_voltimetro_fondo_transparente.png"
const GOBLIN_FISICA_2_IMAGE_PATH := "res://assets/characters/goblin_fisica2_fondo_transparente.png"
const GOBLIN_NOTEBOOK_FISICA_3_IMAGE_PATH := "res://assets/characters/goblin_notebook_fisica3_transparente.png"
const ROBOT_NO_PROMOCIONAR_IMAGE_PATH := "res://assets/characters/robot_no_guardar_promocion_transparente.png"
const PINGU_LINUX_IMAGE_PATH := "res://assets/characters/pingu_linux.png"
const TORRE_CHICA_IMAGE_PATH := "res://assets/characters/mini_torrecita_1_transparente.png"
const TORRE_MEDIA_IMAGE_PATH := "res://assets/characters/mini_torrecita_2_transparente.png"
const TORRE_GRANDE_IMAGE_PATH := "res://assets/characters/mini_torrecita_3_transparente.png"
const TOMAS_KHUM_IMAGE_PATH := "res://assets/characters/tomas_khum.png"
const CIGARRO_IMAGE_PATH := "res://assets/characters/cigarro_1.png"
const CIGARRO_ALT_2_IMAGE_PATH := "res://assets/characters/cigarro_2.png"
const CIGARRO_ALT_3_IMAGE_PATH := "res://assets/characters/cigarro_3.png"
const DFD_DIABOLICO_IMAGE_PATH := "res://assets/characters/dfd diabolico.png"
const PAUTAS_IMAGE_PATH := "res://assets/characters/pautas.png"
const EL_ONI_PHASE_1_IMAGE_PATH := "res://assets/characters/el_oni_fase_1.png"
const EL_ONI_PHASE_2_IMAGE_PATH := "res://assets/characters/el_oni_fase_2.png"
const EL_ONI_PHASE_3_IMAGE_PATH := "res://assets/characters/el_oni_fase_3.png"
const VISUAL_ID_TOM_APOSTOL := "tom_apostol"
const VISUAL_ID_PEPO := "pepo"
const VISUAL_ID_THOMAS_KUHN := "thomas_kuhn"
const VISUAL_ID_INTEGRAL := "integral"
const VISUAL_ID_CALCULUS := "calculus"
const VISUAL_ID_CALCULADORA := "calculadora"
const VISUAL_ID_GOBLIN_VOLTIMETRO := "goblin_voltimetro"
const VISUAL_ID_GOBLIN_FISICA_2 := "goblin_fisica_2"
const VISUAL_ID_GOBLIN_CLASE_VIRTUAL := "goblin_clase_virtual"
const VISUAL_ID_ROBOT_PROMOCION := "robot_promocion"
const VISUAL_ID_PINGUINO_LINUX := "pinguino_linux"
const VISUAL_ID_TORRE_HANOI_1 := "torre_de_hanoi_1"
const VISUAL_ID_TORRE_HANOI_2 := "torre_de_hanoi_2"
const VISUAL_ID_TORRE_HANOI_3 := "torre_de_hanoi_3"
const VISUAL_ID_CIGARRO_1 := "cigarro_1"
const VISUAL_ID_CIGARRO_2 := "cigarro_2"
const VISUAL_ID_CIGARRO_3 := "cigarro_3"
const VISUAL_ID_DFD := "dfd"
const VISUAL_ID_PAUTAS := "pautas"
const VISUAL_ID_ONI_PHASE_1 := "el_oni_fase_1"
const VISUAL_ID_ONI_PHASE_2 := "el_oni_fase_2"
const VISUAL_ID_ONI_PHASE_3 := "el_oni_fase_3"
const FIRST_ENEMY_MAX_HP := 50
const FIRST_ENEMY_BASE_BLOCK := 0
const SECOND_ENEMY_MAX_HP := 250
const SECOND_ENEMY_BASE_BLOCK := 15
const THIRD_ENEMY_MAX_HP := 320
const THIRD_ENEMY_BASE_BLOCK := 15
const FOURTH_ENEMY_MAX_HP := 420
const FOURTH_ENEMY_BASE_BLOCK := 20
const FIRST_ENEMY_NAME := "Tom Apostol"
const SECOND_ENEMY_NAME := "Pepo"
const THIRD_ENEMY_NAME := "Tomás Khum"
const FOURTH_ENEMY_NAME := "El Oni"
const MINIBOSS_INTEGRAL_TRIPLE := "integral_triple"
const MINIBOSS_CALCULUS := "calculus"
const MINIBOSS_CALCULADORA_VIEJA := "calculadora_vieja"
const ENEMY_GOBLIN_VOLTIMETRO := "goblin_voltimetro"
const ENEMY_GOBLIN_FISICA_2 := "goblin_fisica_2"
const ENEMY_GOBLIN_NOTEBOOK_FISICA_3 := "goblin_notebook_fisica_3"
const ENEMY_ROBOT_NO_PROMOCIONAR := "robot_no_promocionar"
const ENEMY_PINGU_LINUX := "pingu_linux"
const ENCOUNTER_TORRES_CHICA_MEDIA_CHICA := "torres_chica_media_chica"
const ENCOUNTER_TORRES_MEDIA_GRANDE := "torres_media_grande"
const ENCOUNTER_PINGU_TORRE_CHICA := "pingu_torre_chica"
const ENCOUNTER_ROBOT_TORRE_MEDIA := "robot_torre_media"
const ENEMY_CIGARRO := "cigarro"
const ENEMY_DFD_DIABOLICO := "dfd_diabolico"
const ENEMY_PAUTAS := "pautas"
const ENCOUNTER_CIGARRO_CIGARRO := "cigarro_cigarro"
const ENCOUNTER_CIGARRO_CIGARRO_CIGARRO := "cigarro_cigarro_cigarro"
const ENCOUNTER_DFD_DIABOLICO_CIGARRO := "dfd_diabolico_cigarro"
const BOSS_EL_ONI := "el_oni"
const ARCHETYPE_ENJAMBRE := "Enjambre"
const ARCHETYPE_DUELISTA_BASICO := "Duelista básico"
const ARCHETYPE_FRAGIL_MOLESTO := "Frágil molesto"
const ARCHETYPE_JEFE_INICIAL := "Jefe inicial"
const ARCHETYPE_MOLESTO_TECNICO := "Molesto técnico"
const ARCHETYPE_TANQUE_MEDIO := "Tanque medio"
const ARCHETYPE_ELITE_PESADO := "Elite pesado"
const ARCHETYPE_JEFE_TANQUE := "Jefe tanque"
const ARCHETYPE_JEFE_ZONA_3 := "Jefe zona 3"
const CALCULUS_MINIBOSS_SCALE := Vector2(0.11, 0.11)
const CALCULADORA_MINIBOSS_SCALE := Vector2(0.10, 0.10)
const GOBLIN_MINIBOSS_SCALE := Vector2(0.14, 0.14)
const ROBOT_ZONE_3_SCALE := Vector2(0.16, 0.16)
const PINGU_ZONE_3_SCALE := Vector2(0.14, 0.14)
const TORRE_CHICA_SCALE := Vector2(0.075, 0.075)
const TORRE_MEDIA_SCALE := Vector2(0.08, 0.08)
const TORRE_GRANDE_SCALE := Vector2(0.09, 0.09)
const TOMAS_KHUM_SCALE := Vector2(0.21, 0.21)
const CIGARRO_SCALE := Vector2(0.09, 0.09)
const DFD_DIABOLICO_SCALE := Vector2(0.14, 0.14)
const PAUTAS_SCALE := Vector2(0.16, 0.16)
const EL_ONI_SCALE := Vector2(0.24, 0.24)

@export var card_scene: PackedScene = preload("res://scenes/Card.tscn")

@onready var player: Player = $"../Player"
@onready var enemy: Enemy = $"../Enemy"
@onready var deck_manager: DeckManager = $"../DeckManager"

@onready var player_stats_label: Label = $"../UI/PlayerStatsLabel"
@onready var enemy_stats_label: Label = $"../UI/EnemyStatsLabel"
@onready var energy_label: Label = $"../UI/EnergyLabel"
@onready var enemy_intent_label: Label = $"../UI/EnemyIntentLabel"
@onready var ui_layer: CanvasLayer = $"../UI"
@onready var hand_container: HBoxContainer = $"../UI/HandContainer"
@onready var card_animation_layer: Control = $"../UI/CardAnimationLayer"
@onready var draw_pile_area: Control = $"../UI/DrawPileArea"
@onready var draw_pile_panel: Panel = $"../UI/DrawPileArea/PilePanel"
@onready var draw_pile_back_label: Label = $"../UI/DrawPileArea/PilePanel/BackLabel"
@onready var discard_pile_area: Control = $"../UI/DiscardPileArea"
@onready var discard_pile_panel: Panel = $"../UI/DiscardPileArea/PilePanel"
@onready var discard_pile_back_label: Label = $"../UI/DiscardPileArea/PilePanel/BackLabel"
@onready var draw_pile_count_label: Label = $"../UI/DrawPileArea/CountLabel"
@onready var discard_pile_count_label: Label = $"../UI/DiscardPileArea/CountLabel"
@onready var deck_viewer_panel: Panel = $"../UI/DeckViewerPanel"
@onready var deck_viewer_title_label: Label = $"../UI/DeckViewerPanel/ViewerVBox/HeaderBox/DeckViewerTitleLabel"
@onready var deck_viewer_cards_container: GridContainer = $"../UI/DeckViewerPanel/ViewerVBox/DeckViewerScroll/DeckViewerCardsContainer"
@onready var close_deck_viewer_button: Button = $"../UI/DeckViewerPanel/ViewerVBox/HeaderBox/CloseDeckViewerButton"
@onready var reward_panel: Panel = $"../UI/RewardPanel"
@onready var reward_cards_container: HBoxContainer = $"../UI/RewardPanel/RewardVBox/RewardCardsContainer"
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
var player_combat_hud: PlayerCombatHUD
var combat_animation_controller: CombatAnimationController
var announcement_overlay: CombatAnnouncementOverlay
var zone_boss_reward_screen: ZoneBossRewardScreen
var game_over_overlay: GameOverOverlay
var combat_input_locked := false
var multi_enemy_hps: Array = []
var multi_enemy_max_hps: Array = []
var multi_enemy_names: Array = []
var multi_enemy_active := false
var current_oni_visual_phase := 0
var combat_turn_number := 0
var clear_mind_blocks_debuff_this_combat := false
var game_over_in_progress := false

# AGREGADO: Variable para el artilugio "Calculadora Científica"
var primera_carta_combate_gratis := false
var artifact_block_per_draw := 0
var artifact_draw_on_block := false
var artifact_first_turn_extra_draw := 0
var artifact_first_turn_extra_energy := 0
var artifact_first_turn_damage := 0
var artifact_immunity_states: Array[String] = []
var artifact_debuff_cleanse_interval := 0
var artifact_heal_after_combat := 0
var artifact_gold_bonus_after_combat := 0
var artifact_attack_damage_bonus := 0
var artifact_copy_card_available := false


func _ready() -> void:
	randomize()
	_setup_combat_status_ui()
	_setup_combat_animation_controller()
	_setup_announcement_overlay()
	_setup_zone_boss_reward_screen()
	_setup_game_over_overlay()
	deck_manager.deck_counts_changed.connect(_update_deck_zone_ui)
	draw_pile_area.mouse_filter = Control.MOUSE_FILTER_STOP
	discard_pile_area.mouse_filter = Control.MOUSE_FILTER_STOP
	draw_pile_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	discard_pile_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_pile_icons()
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


func _setup_combat_status_ui() -> void:
	player_stats_label.visible = false
	enemy_stats_label.visible = false
	energy_label.visible = false

	player_combat_hud = PLAYER_COMBAT_HUD_SCRIPT.new()
	ui_layer.add_child(player_combat_hud)
	ui_layer.move_child(player_combat_hud, 0)


func _setup_combat_animation_controller() -> void:
	combat_animation_controller = CombatAnimationController.new()
	add_child(combat_animation_controller)
	combat_animation_controller.setup(
		battle_visuals,
		card_animation_layer,
		draw_pile_area,
		discard_pile_area,
		hand_container,
		card_scene
	)


func _setup_announcement_overlay() -> void:
	announcement_overlay = COMBAT_ANNOUNCEMENT_OVERLAY_SCENE.instantiate() as CombatAnnouncementOverlay
	add_child(announcement_overlay)


func _setup_zone_boss_reward_screen() -> void:
	zone_boss_reward_screen = ZONE_BOSS_REWARD_SCREEN_SCENE.instantiate() as ZoneBossRewardScreen
	add_child(zone_boss_reward_screen)
	zone_boss_reward_screen.reward_selected.connect(_on_zone_boss_reward_selected)


func _setup_game_over_overlay() -> void:
	game_over_overlay = GAME_OVER_OVERLAY_SCENE.instantiate() as GameOverOverlay
	add_child(game_over_overlay)


func _set_combat_input_locked(locked: bool) -> void:
	combat_input_locked = locked
	var combat_finished: bool = battle_has_ended or game_over_in_progress
	var hand_should_disable: bool = locked or combat_finished
	var controls_should_disable: bool = locked or waiting_for_discard or combat_finished
	end_turn_button.disabled = controls_should_disable
	abandon_combat_button.disabled = controls_should_disable
	_set_hand_cards_disabled(hand_should_disable)


func _set_hand_cards_disabled(disabled: bool) -> void:
	for child in hand_container.get_children():
		if child is BaseButton:
			(child as BaseButton).disabled = disabled

func _setup_pile_icons() -> void:
	_setup_pile_icon(draw_pile_panel, draw_pile_back_label, DRAW_PILE_ICON_PATH)
	_setup_pile_icon(discard_pile_panel, discard_pile_back_label, DISCARD_PILE_ICON_PATH)


func _setup_pile_icon(panel: Panel, old_label: Label, icon_path: String) -> void:
	old_label.visible = false

	var icon_texture: Texture2D = load(icon_path) as Texture2D
	if icon_texture == null:
		old_label.visible = true
		return

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon_texture
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 8
	icon_rect.offset_top = 8
	icon_rect.offset_right = -8
	icon_rect.offset_bottom = -8
	panel.add_child(icon_rect)


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
	combat_turn_number = 0
	clear_mind_blocks_debuff_this_combat = false
	skip_next_player_draw = false
	preserve_hand_for_next_turn = false
	player_attacked_this_turn = false
	multi_enemy_active = false
	multi_enemy_hps.clear()
	multi_enemy_max_hps.clear()
	multi_enemy_names.clear()
	current_oni_visual_phase = 0
	temporary_card_cost_modifiers.clear()
	_reset_artifact_combat_effects()
	_configure_enemy_for_current_node()
	player.load_hp_from_run_state()
	player.max_energy = GameState.energia_maxima
	var has_temporary_energy_bonus: bool = GameState.consume_temporary_energy_bonus_for_combat()
	if has_temporary_energy_bonus:
		player.max_energy += 1
	player.reset_for_new_combat()
	if has_temporary_energy_bonus:
		print("[ZONE REWARD] Café antes del final activo. Energía máxima de este combate:", player.max_energy)
	enemy.reset_for_new_battle()
	print("[COMBAT START] HP cargada desde RunState:", GameState.vida_actual, "/", GameState.vida_maxima)
	print("[NEXT COMBAT] HP cargada:", player.current_hp, "/", player.max_hp)
	
	# Poner música de combate
	AudioManager.play_music("pencils_down", -8.0)
	deck_manager.create_starting_deck()
	
	# --- AGREGADO: REVISAMOS LA MOCHILA AL EMPEZAR ---
	_aplicar_artilugios_inicio_combate()
	# -------------------------------------------------
	_apply_clear_mind_if_pending()
	
<<<<<<< Updated upstream
	deck_manager.create_starting_deck()
	
	if current_enemy_name == FOURTH_ENEMY_NAME:
		var presentation_scene = load("res://scripts/ui/BossPresentationOverlay.gd").new()
		add_child(presentation_scene)
		presentation_scene.play_presentation()
		await presentation_scene.presentation_finished
		
=======
>>>>>>> Stashed changes
	_set_combat_input_locked(true)
	await _play_combat_announcement("COMIENZA EL COMBATE")
	await start_player_turn()

# --- AGREGADO: LÓGICA DE ARTILUGIOS ---
func _aplicar_artilugios_inicio_combate_legacy() -> void:
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


func _reset_artifact_combat_effects() -> void:
	primera_carta_combate_gratis = false
	artifact_block_per_draw = 0
	artifact_draw_on_block = false
	artifact_first_turn_extra_draw = 0
	artifact_first_turn_extra_energy = 0
	artifact_first_turn_damage = 0
	artifact_immunity_states.clear()
	artifact_debuff_cleanse_interval = 0
	artifact_heal_after_combat = 0
	artifact_gold_bonus_after_combat = 0
	artifact_attack_damage_bonus = 0
	artifact_copy_card_available = false


func _aplicar_artilugios_inicio_combate() -> void:
	for nombre_artilugio: String in GameState.artilugios:
		if not GameState.INFO_ARTILUGIOS.has(nombre_artilugio):
			continue

		var info: Dictionary = GameState.INFO_ARTILUGIOS[nombre_artilugio]
		var artifact_type: String = String(info.get("tipo", ""))
		var effect_id: String = String(info.get("efecto", ""))
		var value: int = int(info.get("valor", 0))

		match artifact_type:
			"inicio_combate":
				_apply_artifact_start_effect(effect_id, value)
			"pasivo_combate":
				_apply_artifact_passive_setup(effect_id, value)
			"fin_combate":
				_apply_artifact_end_setup(effect_id, value)


func _apply_artifact_start_effect(effect_id: String, value: int) -> void:
	match effect_id:
		"escudo_inicial":
			_gain_player_block(value)
		"inmunidad_cansancio":
			_add_artifact_immunity("cansancio")
		"aplicar_buff":
			player.aplicar_estado("nervios_de_acero", 0, 2)
			player.aplicar_estado("panico", 0, 2)
		"robar_extra":
			artifact_first_turn_extra_draw += value
		"energia_extra":
			artifact_first_turn_extra_energy += value
			artifact_first_turn_damage += 3


func _apply_artifact_passive_setup(effect_id: String, value: int) -> void:
	match effect_id:
		"costo_cero":
			primera_carta_combate_gratis = true
		"escudo_por_robo":
			artifact_block_per_draw += value
		"inmunidad_distraccion":
			_add_artifact_immunity("distraccion")
		"inmunidad_panico":
			_add_artifact_immunity("panico")
		"robar_al_defender":
			artifact_draw_on_block = true
		"limpiar_debuff":
			artifact_debuff_cleanse_interval = maxi(value, 1)
		"plata_extra":
			artifact_gold_bonus_after_combat += value
		"dano_extra":
			artifact_attack_damage_bonus += value
		"copiar_carta":
			artifact_copy_card_available = true


func _apply_artifact_end_setup(effect_id: String, value: int) -> void:
	match effect_id:
		"curacion_fija":
			artifact_heal_after_combat += value
		"plata_extra":
			artifact_gold_bonus_after_combat += value


func _add_artifact_immunity(state_name: String) -> void:
	if not artifact_immunity_states.has(state_name):
		artifact_immunity_states.append(state_name)


func _apply_clear_mind_if_pending() -> void:
	if not GameState.consume_clear_mind_for_combat():
		return

	clear_mind_blocks_debuff_this_combat = true
	_gain_player_block(12)
	print("[ZONE REWARD] Mente despejada activa: +12 escudo y bloqueo del primer debuff enemigo.")


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
		_set_enemy_deck_for_current_zone([], FIRST_ENEMY_NAME)
		battle_visuals.set_enemy_image(FIRST_ENEMY_IMAGE_PATH, BattleVisuals.DEFAULT_ENEMY_SCALE, VISUAL_ID_TOM_APOSTOL)
		battle_visuals.set_enemy_display_name(FIRST_ENEMY_NAME)
		current_enemy_name = FIRST_ENEMY_NAME


func _configure_zone_boss() -> void:
	var node_data := GameState.get_current_node_data()
	var boss_name := String(node_data.get("encounter_name", FIRST_ENEMY_NAME))

	match boss_name:
		SECOND_ENEMY_NAME:
			enemy.max_hp = SECOND_ENEMY_MAX_HP
			enemy.base_block = SECOND_ENEMY_BASE_BLOCK
			enemy.max_energy = 5
			var pepo_archetypes := _get_zone_boss_archetypes(2)
			_set_enemy_deck_for_current_zone(pepo_archetypes, SECOND_ENEMY_NAME)
			battle_visuals.set_enemy_image(SECOND_ENEMY_IMAGE_PATH, BattleVisuals.DEFAULT_ENEMY_SCALE, VISUAL_ID_PEPO)
			battle_visuals.set_enemy_display_name(SECOND_ENEMY_NAME)
			current_enemy_name = SECOND_ENEMY_NAME
		THIRD_ENEMY_NAME:
			enemy.max_hp = THIRD_ENEMY_MAX_HP
			enemy.base_block = THIRD_ENEMY_BASE_BLOCK
			enemy.max_energy = 5
			_set_zone_3_boss_deck()
			battle_visuals.set_enemy_image(TOMAS_KHUM_IMAGE_PATH, TOMAS_KHUM_SCALE, VISUAL_ID_THOMAS_KUHN)
			battle_visuals.set_enemy_display_name(THIRD_ENEMY_NAME)
			current_enemy_name = THIRD_ENEMY_NAME
		FOURTH_ENEMY_NAME:
			enemy.max_hp = FOURTH_ENEMY_MAX_HP
			enemy.base_block = FOURTH_ENEMY_BASE_BLOCK
			enemy.max_energy = 6
			_set_oni_boss_deck()
			battle_visuals.set_enemy_display_name(FOURTH_ENEMY_NAME)
			current_enemy_name = FOURTH_ENEMY_NAME
			_update_oni_phase_visual(true)
		_:
			enemy.max_hp = FIRST_ENEMY_MAX_HP
			enemy.base_block = FIRST_ENEMY_BASE_BLOCK
			enemy.max_energy = 5
			var tom_archetypes := _get_zone_boss_archetypes(1)
			_set_enemy_deck_for_current_zone(tom_archetypes, FIRST_ENEMY_NAME)
			battle_visuals.set_enemy_image(FIRST_ENEMY_IMAGE_PATH, BattleVisuals.DEFAULT_ENEMY_SCALE, VISUAL_ID_TOM_APOSTOL)
			battle_visuals.set_enemy_display_name(FIRST_ENEMY_NAME)
			current_enemy_name = FIRST_ENEMY_NAME


func _configure_miniboss(miniboss_id: String) -> void:
	enemy.base_block = 0
	enemy.max_energy = 3
	var enemy_archetypes := _get_enemy_archetypes(miniboss_id)

	match miniboss_id:
		MINIBOSS_INTEGRAL_TRIPLE:
			multi_enemy_active = true
			multi_enemy_names = ["Integral 1", "Integral 2", "Integral 3"]
			multi_enemy_hps = [15, 15, 15]
			multi_enemy_max_hps = [15, 15, 15]
			enemy.max_hp = 45
			enemy.current_hp = 45
			current_enemy_name = "Integral Triple"
			battle_visuals.set_enemy_display_name(current_enemy_name)
			battle_visuals.show_multi_enemy_group(INTEGRAL_MINIBOSS_IMAGE_PATH, multi_enemy_names, multi_enemy_hps, multi_enemy_max_hps, [], [VISUAL_ID_INTEGRAL, VISUAL_ID_INTEGRAL, VISUAL_ID_INTEGRAL])
			for index in range(multi_enemy_hps.size()):
				print("%s vida: %d" % [multi_enemy_names[index], multi_enemy_hps[index]])
		MINIBOSS_CALCULUS:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 40
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Calculus"
			battle_visuals.set_enemy_image(CALCULUS_MINIBOSS_IMAGE_PATH, CALCULUS_MINIBOSS_SCALE, VISUAL_ID_CALCULUS)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		MINIBOSS_CALCULADORA_VIEJA:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 25
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Calculadora vieja"
			battle_visuals.set_enemy_image(CALCULADORA_MINIBOSS_IMAGE_PATH, CALCULADORA_MINIBOSS_SCALE, VISUAL_ID_CALCULADORA)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_VOLTIMETRO:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 60
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Goblin voltimetro"
			battle_visuals.set_enemy_image(GOBLIN_VOLTIMETRO_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE, VISUAL_ID_GOBLIN_VOLTIMETRO)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_FISICA_2:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 85
			enemy.max_energy = 3
			enemy.base_block = 0
			current_enemy_name = "Goblin fisica 2"
			battle_visuals.set_enemy_image(GOBLIN_FISICA_2_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE, VISUAL_ID_GOBLIN_FISICA_2)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_GOBLIN_NOTEBOOK_FISICA_3:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 110
			enemy.max_energy = 4
			enemy.base_block = 0
			current_enemy_name = "Goblin notebook fisica 3"
			battle_visuals.set_enemy_image(GOBLIN_NOTEBOOK_FISICA_3_IMAGE_PATH, GOBLIN_MINIBOSS_SCALE, VISUAL_ID_GOBLIN_CLASE_VIRTUAL)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_ROBOT_NO_PROMOCIONAR:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 130
			enemy.max_energy = 4
			enemy.base_block = 10
			current_enemy_name = "Robot no promocionar"
			battle_visuals.set_enemy_image(ROBOT_NO_PROMOCIONAR_IMAGE_PATH, ROBOT_ZONE_3_SCALE, VISUAL_ID_ROBOT_PROMOCION)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_PINGU_LINUX:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 95
			enemy.max_energy = 4
			enemy.base_block = 0
			current_enemy_name = "Pingü Linux"
			battle_visuals.set_enemy_image(PINGU_LINUX_IMAGE_PATH, PINGU_ZONE_3_SCALE, VISUAL_ID_PINGUINO_LINUX)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENCOUNTER_TORRES_CHICA_MEDIA_CHICA:
			_configure_multi_enemy_encounter(
				"Torres",
				["Torre chica", "Torre media", "Torre chica"],
				[35, 45, 35],
				[TORRE_CHICA_IMAGE_PATH, TORRE_MEDIA_IMAGE_PATH, TORRE_CHICA_IMAGE_PATH],
				[TORRE_CHICA_SCALE, TORRE_MEDIA_SCALE, TORRE_CHICA_SCALE],
				[VISUAL_ID_TORRE_HANOI_1, VISUAL_ID_TORRE_HANOI_2, VISUAL_ID_TORRE_HANOI_1],
				3,
				0
			)
		ENCOUNTER_TORRES_MEDIA_GRANDE:
			_configure_multi_enemy_encounter(
				"Torres",
				["Torre media", "Torre grande"],
				[45, 55],
				[TORRE_MEDIA_IMAGE_PATH, TORRE_GRANDE_IMAGE_PATH],
				[TORRE_MEDIA_SCALE, TORRE_GRANDE_SCALE],
				[VISUAL_ID_TORRE_HANOI_2, VISUAL_ID_TORRE_HANOI_3],
				3,
				5
			)
		ENCOUNTER_PINGU_TORRE_CHICA:
			_configure_multi_enemy_encounter(
				"Pingü Linux / Torre chica",
				["Pingü Linux", "Torre chica"],
				[95, 35],
				[PINGU_LINUX_IMAGE_PATH, TORRE_CHICA_IMAGE_PATH],
				[PINGU_ZONE_3_SCALE, TORRE_CHICA_SCALE],
				[VISUAL_ID_PINGUINO_LINUX, VISUAL_ID_TORRE_HANOI_1],
				4,
				0
			)
		ENCOUNTER_ROBOT_TORRE_MEDIA:
			_configure_multi_enemy_encounter(
				"Robot no promocionar / Torre media",
				["Robot no promocionar", "Torre media"],
				[130, 45],
				[ROBOT_NO_PROMOCIONAR_IMAGE_PATH, TORRE_MEDIA_IMAGE_PATH],
				[ROBOT_ZONE_3_SCALE, TORRE_MEDIA_SCALE],
				[VISUAL_ID_ROBOT_PROMOCION, VISUAL_ID_TORRE_HANOI_2],
				4,
				10
			)
		ENEMY_CIGARRO:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 120
			enemy.max_energy = 4
			enemy.base_block = 0
			current_enemy_name = "Cigarro"
			battle_visuals.set_enemy_image(CIGARRO_IMAGE_PATH, CIGARRO_SCALE, VISUAL_ID_CIGARRO_1)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_DFD_DIABOLICO:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 155
			enemy.max_energy = 4
			enemy.base_block = 5
			current_enemy_name = "DFD Diabólico"
			battle_visuals.set_enemy_image(DFD_DIABOLICO_IMAGE_PATH, DFD_DIABOLICO_SCALE, VISUAL_ID_DFD)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENEMY_PAUTAS:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 225
			enemy.max_energy = 5
			enemy.base_block = 12
			current_enemy_name = "Pautas"
			battle_visuals.set_enemy_image(PAUTAS_IMAGE_PATH, PAUTAS_SCALE, VISUAL_ID_PAUTAS)
			battle_visuals.set_enemy_display_name(current_enemy_name)
		ENCOUNTER_CIGARRO_CIGARRO:
			_configure_multi_enemy_encounter(
				"Cigarro / Cigarro",
				["Cigarro", "Cigarro"],
				[120, 120],
				[CIGARRO_IMAGE_PATH, CIGARRO_ALT_2_IMAGE_PATH],
				[CIGARRO_SCALE, CIGARRO_SCALE],
				[VISUAL_ID_CIGARRO_1, VISUAL_ID_CIGARRO_2],
				4,
				0
			)
		ENCOUNTER_CIGARRO_CIGARRO_CIGARRO:
			_configure_multi_enemy_encounter(
				"Cigarro / Cigarro / Cigarro",
				["Cigarro", "Cigarro", "Cigarro"],
				[120, 120, 120],
				[CIGARRO_IMAGE_PATH, CIGARRO_ALT_2_IMAGE_PATH, CIGARRO_ALT_3_IMAGE_PATH],
				[CIGARRO_SCALE, CIGARRO_SCALE, CIGARRO_SCALE],
				[VISUAL_ID_CIGARRO_1, VISUAL_ID_CIGARRO_2, VISUAL_ID_CIGARRO_3],
				4,
				0
			)
		ENCOUNTER_DFD_DIABOLICO_CIGARRO:
			_configure_multi_enemy_encounter(
				"DFD Diabólico / Cigarro",
				["DFD Diabólico", "Cigarro"],
				[155, 120],
				[DFD_DIABOLICO_IMAGE_PATH, CIGARRO_IMAGE_PATH],
				[DFD_DIABOLICO_SCALE, CIGARRO_SCALE],
				[VISUAL_ID_DFD, VISUAL_ID_CIGARRO_1],
				4,
				5
			)
		_:
			battle_visuals.clear_multi_enemy_visuals()
			enemy.max_hp = 40
			enemy.max_energy = 3
			current_enemy_name = "Calculus"
			battle_visuals.set_enemy_image(CALCULUS_MINIBOSS_IMAGE_PATH, CALCULUS_MINIBOSS_SCALE, VISUAL_ID_CALCULUS)
			battle_visuals.set_enemy_display_name(current_enemy_name)

	_set_enemy_deck_for_current_zone(enemy_archetypes, current_enemy_name, miniboss_id)


func _configure_multi_enemy_encounter(
	display_name: String,
	names: Array,
	hps: Array,
	image_paths: Array,
	sprite_scales: Array,
	visual_ids: Array,
	max_energy: int,
	base_block: int
) -> void:
	multi_enemy_active = true
	multi_enemy_names = names.duplicate()
	multi_enemy_hps = hps.duplicate()
	multi_enemy_max_hps = hps.duplicate()
	enemy.max_hp = _get_multi_enemy_total_hp()
	enemy.current_hp = enemy.max_hp
	enemy.max_energy = max_energy
	enemy.base_block = base_block
	current_enemy_name = display_name
	battle_visuals.set_enemy_display_name(current_enemy_name)
	battle_visuals.show_multi_enemy_group(image_paths, multi_enemy_names, multi_enemy_hps, multi_enemy_max_hps, sprite_scales, visual_ids)


func _set_enemy_deck_for_current_zone(enemy_archetypes: Array = [], debug_name: String = "", encounter_id: String = "") -> void:
	var zone_index := _get_current_zone_index()
	var rarities := _get_enemy_rarities_for_encounter(encounter_id, zone_index)
	var cards := _load_current_zone_enemy_deck(enemy_archetypes, rarities)
	enemy.set_professor_deck(cards, enemy_archetypes, debug_name, zone_index, rarities, encounter_id)


func _set_zone_3_boss_deck() -> void:
	var zone_index := 3
	var rarities := _get_enemy_rarities_for_zone(zone_index)
	var base_cards := EnemyCardLoader.load_professor_cards_by_rarities(rarities)
	var primary_archetypes := [ARCHETYPE_JEFE_ZONA_3]
	var primary_cards := _filter_cards_by_archetypes_strict(base_cards, primary_archetypes)

	if not primary_cards.is_empty():
		print("DEBUG CombatManager: Tomás Khum usa arquetipo Jefe zona 3: %d/%d cartas" % [primary_cards.size(), base_cards.size()])
		enemy.set_professor_deck(primary_cards, primary_archetypes, THIRD_ENEMY_NAME, zone_index, rarities)
		return

	var fallback_archetypes := primary_archetypes.duplicate()
	fallback_archetypes.append_array(_get_zone_boss_archetypes(zone_index))
	var fallback_cards := _filter_cards_by_archetypes_strict(base_cards, fallback_archetypes)
	if fallback_cards.is_empty():
		push_warning("CombatManager: Tomás Khum no encontro cartas por arquetipo. Usa fallback por rareza/zona.")
		enemy.set_professor_deck(base_cards, primary_archetypes, THIRD_ENEMY_NAME, zone_index, rarities)
		return

	print("DEBUG CombatManager: Tomás Khum usa fallback de arquetipos jefe zona 3: %d/%d cartas" % [fallback_cards.size(), base_cards.size()])
	enemy.set_professor_deck(fallback_cards, fallback_archetypes, THIRD_ENEMY_NAME, zone_index, rarities)


func _set_oni_boss_deck() -> void:
	var zone_index := 4
	var rarities := _get_enemy_rarities_for_zone(zone_index)
	var cards := EnemyCardLoader.load_professor_cards_by_rarities_and_archetype(rarities, ARCHETYPE_JEFE_TANQUE)
	enemy.set_professor_deck(cards, [ARCHETYPE_JEFE_TANQUE], FOURTH_ENEMY_NAME, zone_index, rarities, BOSS_EL_ONI)


func _load_current_zone_enemy_deck(enemy_archetypes: Array = [], forced_rarities: Array = []) -> Array[CardData]:
	var zone_index := _get_current_zone_index()
	var rarities := forced_rarities if not forced_rarities.is_empty() else _get_enemy_rarities_for_zone(zone_index)
	print("DEBUG CombatManager: Zona %d rarezas enemigas permitidas: %s | arquetipos: %s" % [
		zone_index,
		", ".join(rarities),
		", ".join(enemy_archetypes),
	])
	return EnemyCardLoader.load_professor_cards_by_rarities_and_archetypes(rarities, enemy_archetypes)


func _get_enemy_rarities_for_encounter(encounter_id: String, zone_index: int) -> Array:
	if zone_index == 3 and encounter_id == ENCOUNTER_TORRES_CHICA_MEDIA_CHICA:
		return ["Desertor", "Ingresante"]
	return _get_enemy_rarities_for_zone(zone_index)


func _get_enemy_rarities_for_zone(zone_index: int) -> Array:
	match zone_index:
		1:
			return ["Desertor"]
		2:
			return ["Desertor", "Ingresante"]
		3:
			return ["Desertor", "Ingresante", "Recursante"]
		4:
			return ["Desertor", "Ingresante", "Recursante", "Ayudante de cátedra"]
		_:
			return ["Desertor", "Ingresante", "Recursante", "Ayudante de cátedra"]


func _get_zone_boss_archetypes(zone_index: int) -> Array[String]:
	if zone_index >= 3:
		return [
			ARCHETYPE_JEFE_TANQUE,
			ARCHETYPE_ELITE_PESADO,
			ARCHETYPE_MOLESTO_TECNICO,
			ARCHETYPE_TANQUE_MEDIO,
			ARCHETYPE_JEFE_INICIAL,
		]
	if zone_index == 2:
		return [
			ARCHETYPE_JEFE_TANQUE,
			ARCHETYPE_MOLESTO_TECNICO,
			ARCHETYPE_TANQUE_MEDIO,
			ARCHETYPE_ELITE_PESADO,
		]

	return [
		ARCHETYPE_JEFE_INICIAL,
		ARCHETYPE_ENJAMBRE,
		ARCHETYPE_DUELISTA_BASICO,
		ARCHETYPE_FRAGIL_MOLESTO,
	]


func _filter_cards_by_archetypes_strict(cards: Array[CardData], enemy_archetypes: Array) -> Array[CardData]:
	var filtered_cards: Array[CardData] = []
	for card in cards:
		for archetype in enemy_archetypes:
			if EnemyCardLoader.card_matches_enemy_archetype(card, String(archetype)):
				filtered_cards.append(card)
				break
	return filtered_cards


func _get_enemy_archetypes(enemy_id: String) -> Array:
	match enemy_id:
		MINIBOSS_INTEGRAL_TRIPLE, ENCOUNTER_TORRES_CHICA_MEDIA_CHICA, ENCOUNTER_TORRES_MEDIA_GRANDE:
			return [ARCHETYPE_ENJAMBRE]
		MINIBOSS_CALCULUS:
			return [ARCHETYPE_DUELISTA_BASICO]
		MINIBOSS_CALCULADORA_VIEJA:
			return [ARCHETYPE_FRAGIL_MOLESTO]
		ENEMY_GOBLIN_VOLTIMETRO, ENEMY_PINGU_LINUX:
			return [ARCHETYPE_MOLESTO_TECNICO]
		ENEMY_GOBLIN_FISICA_2, ENEMY_ROBOT_NO_PROMOCIONAR:
			return [ARCHETYPE_TANQUE_MEDIO]
		ENEMY_GOBLIN_NOTEBOOK_FISICA_3:
			return [ARCHETYPE_ELITE_PESADO]
		ENCOUNTER_PINGU_TORRE_CHICA:
			return [ARCHETYPE_MOLESTO_TECNICO, ARCHETYPE_ENJAMBRE]
		ENCOUNTER_ROBOT_TORRE_MEDIA:
			return [ARCHETYPE_TANQUE_MEDIO, ARCHETYPE_ENJAMBRE]
		ENEMY_CIGARRO, ENCOUNTER_CIGARRO_CIGARRO, ENCOUNTER_CIGARRO_CIGARRO_CIGARRO:
			return [ARCHETYPE_ENJAMBRE]
		ENEMY_DFD_DIABOLICO:
			return [ARCHETYPE_MOLESTO_TECNICO]
		ENEMY_PAUTAS:
			return [ARCHETYPE_ELITE_PESADO]
		ENCOUNTER_DFD_DIABOLICO_CIGARRO:
			return [ARCHETYPE_MOLESTO_TECNICO, ARCHETYPE_ENJAMBRE]
		_:
			return []


func _get_current_zone_index() -> int:
	var node_data := GameState.get_current_node_data()
	return int(node_data.get("zone_index", 1))


func _prepare_enemy_intent_for_player_turn() -> void:
	enemy.choose_next_intent(player, deck_manager.hand.size(), player_cards_played_last_turn, _get_current_zone_index(), _get_enemy_intent_group_context())


func _get_enemy_intent_group_context() -> Dictionary:
	return {
		"control_debuff_count": 0,
		"strong_attack_count": 0,
		"announced_damage": 0,
		"player_played_skill_last_turn": player_played_skill_last_turn,
	}


func start_player_turn() -> void:
	if battle_has_ended:
		return

	_set_combat_input_locked(true)
	combat_turn_number += 1
	player.reset_for_new_turn()
	if combat_turn_number == 1:
		player.current_energy += artifact_first_turn_extra_energy
		if artifact_first_turn_damage > 0:
			player.take_damage(artifact_first_turn_damage)
	if artifact_debuff_cleanse_interval > 0 and combat_turn_number % artifact_debuff_cleanse_interval == 0:
		player.remove_one_negative_state()
	player_cards_played_this_turn = 0
	player_attacked_this_turn = false
	player_played_skill_this_turn = false
	temporary_card_cost_modifiers.clear()

	if player.skip_next_player_turn:
		player.skip_next_player_turn = false
		_clear_hand_ui()
		player_cards_played_last_turn = 0
		_prepare_enemy_intent_for_player_turn()
		update_ui()
		await enemy_turn()
		return

	if skip_next_player_draw:
		skip_next_player_draw = false
		preserve_hand_for_next_turn = false
		_show_hand()
	else:
		preserve_hand_for_next_turn = false
		var draw_amount := player.get_draw_amount(PLAYER_DRAW_PER_TURN)
		if combat_turn_number == 1:
			draw_amount += artifact_first_turn_extra_draw
		var drawn_cards := deck_manager.draw_cards(draw_amount)
		_apply_artifact_draw_bonus(drawn_cards.size())
		if combat_turn_number == 1:
			_apply_artifact_copy_card_once()
		await _animate_drawn_cards(drawn_cards)

	_prepare_enemy_intent_for_player_turn()
	update_ui()
	await _play_combat_announcement("TURNO DEL JUGADOR", _get_turn_subtitle())
	if not battle_has_ended and not waiting_for_discard:
		_set_combat_input_locked(false)


func play_card(card_data: CardData, card_ui: CardUI) -> void:
	if battle_has_ended or combat_input_locked or game_over_in_progress:
		return

	if not deck_manager.hand.has(card_data):
		return

	# AGREGADO: Logica de interceptacion. Si estamos esperando, descartamos en vez de jugar.
	if waiting_for_discard:
		await _execute_discard_choice(card_data, card_ui)
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
		print("ARTILUGIO: Tu carta costo 0 energia!")
	# ---------------------------------------

	if not player.spend_energy(effective_cost):
		battle_visuals.show_player_speech("no tengo suficiente ENERGIA")
		update_ui()
		return

	_set_combat_input_locked(true)
	var played_card_position := card_ui.global_position
	deck_manager.hand.erase(card_data)
	deck_manager.played_cards.append(card_data)
	deck_manager.print_deck_debug_counts()
	card_ui.queue_free()
	player_cards_played_this_turn += 1
	if _is_attack_card(card_data):
		player_attacked_this_turn = true
	elif _is_skill_card(card_data):
		player_played_skill_this_turn = true

	var before_state := _capture_visual_state()
	_apply_card_effect(card_data)
	var visual_events := _build_visual_events_from_state_delta(before_state, _capture_visual_state(), "player", "enemy")
	visual_events.push_front({
		"type": "played_card",
		"card_data": card_data,
		"from_position": played_card_position,
	})
	update_ui()
	await _play_visual_events(visual_events)
	check_combat_end()
	if not battle_has_ended:
		_set_combat_input_locked(false)

func end_player_turn() -> void:
	if battle_has_ended or combat_input_locked or game_over_in_progress:
		return

	if waiting_for_discard:
		return

	_set_combat_input_locked(true)
	for card_data in deck_manager.hand:
		if card_data.effect_id == "sentarse_fondo":
			player.gain_block(5)

	# AGREGADO: Reducimos la duración de los estados del jugador al terminar su turno
	player.reducir_duracion_estados()

	player_cards_played_last_turn = player_cards_played_this_turn
	player_played_skill_last_turn = player_played_skill_this_turn
	await enemy_turn()


func enemy_turn() -> void:
	if battle_has_ended or game_over_in_progress:
		return

	_set_combat_input_locked(true)
	await _play_combat_announcement("TURNO ENEMIGO", _get_turn_subtitle())
	if battle_has_ended:
		return

	enemy.start_turn()

	if skip_next_enemy_turn:
		skip_next_enemy_turn = false
	else:
		var card_to_play := enemy.get_playable_card_for_turn(player, deck_manager.hand.size(), player_cards_played_last_turn)
		if card_to_play != null:
			enemy_turn_finished_by_card = false
			await _execute_enemy_card(card_to_play)
			if battle_has_ended or game_over_in_progress:
				return
			if waiting_for_discard:
				_set_combat_input_locked(false)
				return
			if enemy_turn_finished_by_card:
				return
		else:
			enemy.gain_block(3)
			print("DEBUG Enemy: no encontro carta jugable, espera y gana 3 de escudo.")

	_finish_enemy_turn()


func _finish_enemy_turn() -> void:
	if battle_has_ended or game_over_in_progress:
		return

	if not preserve_hand_for_next_turn:
		deck_manager.discard_hand()
		_clear_hand_ui()

	deck_manager.discard_played_cards()

	# AGREGADO: Reducimos la duración de los estados del enemigo al terminar su turno
	enemy.reducir_duracion_estados()

	check_combat_end()

	if battle_has_ended:
		return

	await start_player_turn()


func update_ui() -> void:
	_update_oni_phase_visual()
	var player_states := _get_player_statuses_for_ui()
	var enemy_states := _get_enemy_statuses_for_ui()

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
	_update_combat_status_ui(player_states, enemy_states)
	
	# AGREGADO: Solo actualizamos el texto de intención si NO estamos en modo descarte
	if not waiting_for_discard:
		enemy_intent_label.text = enemy.get_intent_text(player, deck_manager.hand.size(), player_cards_played_last_turn, player_played_skill_last_turn)
		enemy_intent_label.tooltip_text = enemy.get_intent_tooltip(player, deck_manager.hand.size(), player_cards_played_last_turn, player_played_skill_last_turn)


func _update_combat_status_ui(player_states: Array, enemy_states: Array) -> void:
	if player_combat_hud != null:
		player_combat_hud.update_values(
			player.current_hp,
			player.max_hp,
			player.current_energy,
			player.max_energy,
			player.block,
			GameState.dinero,
			player_states
		)

	battle_visuals.update_player_status_bar(player.current_hp, player.max_hp, player.block, player_states)

	if multi_enemy_active:
		battle_visuals.update_multi_enemy_status_bars(
			multi_enemy_names,
			multi_enemy_hps,
			multi_enemy_max_hps,
			enemy.block,
			enemy_states,
			_get_first_alive_multi_enemy_index()
		)
	else:
		battle_visuals.update_enemy_status_bar(current_enemy_name, enemy.current_hp, enemy.max_hp, enemy.block, enemy_states)


func _get_player_statuses_for_ui() -> Array:
	var states: Array = []
	states.append_array(player.estados)

	if player.attack_bonus != 0 and player.attack_bonus_turns > 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("ataque_bonus", player.attack_bonus, player.attack_bonus_turns))
	if player.defense_card_bonus != 0 and player.defense_card_bonus_turns > 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("defensa_bonus", player.defense_card_bonus, player.defense_card_bonus_turns))
	if player.approved_with_4_turns > 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("aprobado_con_4", 0, player.approved_with_4_turns))
	if player.immune_to_enemy_attack_turns > 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("inmunidad", 0, player.immune_to_enemy_attack_turns))

	return states


func _get_enemy_statuses_for_ui() -> Array:
	var states: Array = []
	states.append_array(enemy.estados)

	if enemy.attack_bonus != 0 and enemy.attack_bonus_turns > 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("ataque_bonus", enemy.attack_bonus, enemy.attack_bonus_turns))
	if enemy.permanent_attack_bonus != 0:
		states.append(STATUS_EFFECT_INFO_SCRIPT.make_state("ataque_permanente", enemy.permanent_attack_bonus, 0))

	return states


func _update_oni_phase_visual(force: bool = false) -> void:
	if current_enemy_name != FOURTH_ENEMY_NAME or multi_enemy_active:
		return

	var phase := _get_oni_visual_phase()
	if not force and phase == current_oni_visual_phase:
		return

	current_oni_visual_phase = phase
	battle_visuals.set_enemy_image(_get_oni_phase_image_path(phase), EL_ONI_SCALE, _get_oni_phase_visual_id(phase))
	battle_visuals.set_enemy_display_name(FOURTH_ENEMY_NAME)
	print("[DEBUG] El Oni cambia a fase visual %d." % phase)


func _get_oni_visual_phase() -> int:
	if enemy.current_hp <= 140:
		return 3
	if enemy.current_hp <= 280:
		return 2
	return 1


func _get_oni_phase_image_path(phase: int) -> String:
	match phase:
		2:
			return EL_ONI_PHASE_2_IMAGE_PATH
		3:
			return EL_ONI_PHASE_3_IMAGE_PATH
		_:
			return EL_ONI_PHASE_1_IMAGE_PATH


func _get_oni_phase_visual_id(phase: int) -> String:
	match phase:
		2:
			return VISUAL_ID_ONI_PHASE_2
		3:
			return VISUAL_ID_ONI_PHASE_3
		_:
			return VISUAL_ID_ONI_PHASE_1


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
		var max_hp := int(multi_enemy_max_hps[index]) if index < multi_enemy_max_hps.size() else int(multi_enemy_hps[index])
		parts.append("%s: %d/%d" % [multi_enemy_names[index], multi_enemy_hps[index], max_hp])
	return " | ".join(parts)


func check_combat_end() -> void:
	if _is_current_encounter_defeated():
		battle_has_ended = true
		_save_player_hp_at_combat_end()
		_apply_artifact_end_of_combat_rewards()
		var gold_reward: int = _grant_combat_gold_reward()
		if GameState.get_current_combat_kind() == "miniboss":
			print("Minijefe derrotado")
		enemy_intent_label.text = "Victoria: aprobaste este combate. +$%d" % gold_reward
		end_turn_button.disabled = true
		_clear_hand_ui()
		if _should_show_zone_boss_reward():
			_show_zone_boss_reward()
		else:
			_show_card_reward()
	elif player.is_dead():
		if _try_artifact_revival():
			return
		trigger_game_over()


func trigger_game_over() -> void:
	if game_over_in_progress:
		return

	game_over_in_progress = true
	battle_has_ended = true
	waiting_for_discard = false
	_reset_discard_selection()
	_set_combat_input_locked(true)
	_clear_hand_ui()
	reward_panel.visible = false
	deck_viewer_panel.visible = false
	enemy_intent_label.text = "Derrota: el cuatrimestre te supero."

	if game_over_overlay != null:
		await game_over_overlay.play_and_wait()

	_complete_game_over_return_to_menu()


func _try_artifact_revival() -> bool:
	var revived_hp: int = GameState.consume_artifact_revival()
	if revived_hp <= 0:
		return false

	player.set_current_hp(revived_hp)
	battle_has_ended = false
	game_over_in_progress = false
	_set_combat_input_locked(false)
	update_ui()
	print("[ARTIFACT] Examen Recuperatorio activo: revive con %d HP" % revived_hp)
	return true


func _complete_game_over_return_to_menu() -> void:
	GameState.delete_saved_game()
	GameState.reset_run_progress()
	_return_to_main_menu()


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
	_save_player_hp_at_combat_end()
	GameState.completar_nodo_actual()
	_return_to_map()


func _apply_artifact_end_of_combat_rewards() -> void:
	if artifact_heal_after_combat > 0:
		GameState.heal_player(artifact_heal_after_combat)
		player.load_hp_from_run_state()
		print("[ARTIFACT REWARD] Cura fin de combate +%d HP" % artifact_heal_after_combat)


func _grant_combat_gold_reward() -> int:
	var reward_amount: int = _get_combat_gold_reward_amount() + artifact_gold_bonus_after_combat
	GameState.dinero += reward_amount
	GameState.save_game()
	update_ui()
	print("[COMBAT REWARD] +$%d | Plata total: $%d" % [reward_amount, GameState.dinero])
	return reward_amount


func _get_combat_gold_reward_amount() -> int:
	var zone_index: int = maxi(GameState.get_current_zone_index(), 1)
	match GameState.get_current_combat_kind():
		"boss":
			return 70 + zone_index * 15
		"miniboss":
			return 40 + zone_index * 10
		"intermediate":
			return 22 + zone_index * 6
		_:
			return 25 + zone_index * 5


func _should_show_zone_boss_reward() -> bool:
	return GameState.get_current_combat_kind() == "boss"


func _show_zone_boss_reward() -> void:
	if zone_boss_reward_screen == null:
		_show_card_reward()
		return

	zone_boss_reward_screen.show_rewards(_get_random_zone_boss_rewards())


func _show_card_reward(rarities: Array[String] = [], reward_mode: String = "normal") -> void:
	print("Combate ganado, generando recompensa")
	var reward_rarities: Array[String] = rarities
	if reward_rarities.is_empty():
		reward_rarities = _get_current_reward_rarities()
	print("Rareza de recompensa actual: %s" % ", ".join(reward_rarities))

	for child in reward_cards_container.get_children():
		child.queue_free()

	var reward_options: Array[CardData] = PlayerCardLoader.load_reward_options_by_rarities(reward_rarities, 3)
	if reward_options.is_empty():
		push_warning("CombatManager: no hay cartas disponibles para rarezas '%s'." % ", ".join(reward_rarities))
		reward_panel.visible = false
		if reward_mode == "extra_rare":
			_show_card_reward()
		else:
			GameState.completar_nodo_actual()
			_return_to_map()
		return

	var option_names: Array[String] = []
	for card_data in reward_options:
		option_names.append(card_data.card_name)

	print("Opciones de recompensa: %s" % ", ".join(option_names))

	reward_panel.visible = true
	for card_data in reward_options:
		var card_ui: CardUI = card_scene.instantiate()
		reward_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_clicked.connect(_on_reward_card_selected.bind(reward_mode))


func _get_current_reward_rarities() -> Array[String]:
	if _get_current_zone_index() >= 2:
		return ["Ingresante", "Recursante"]
	return [GameState.rareza_recompensa_actual]


func _get_random_zone_boss_rewards() -> Array[Dictionary]:
	var pool: Array[Dictionary] = _get_zone_boss_reward_pool()
	pool.shuffle()

	var selected: Array[Dictionary] = []
	var option_count: int = mini(3, pool.size())
	for index in range(option_count):
		selected.append(_with_zone_reward_preview(pool[index]))
	return selected


func _get_zone_boss_reward_pool() -> Array[Dictionary]:
	return [
		{
			"id": "heal_big",
			"title": "Dormir todo el fin de semana",
			"description": "Recuperá el 40% de tu vida máxima.",
			"icon_path": BOSS_REWARD_ICON_BED,
		},
		{
			"id": "max_hp_big",
			"title": "Curtirse con el parcial",
			"description": "Aumentá tu vida máxima en 8 y recuperá 8 HP.",
			"icon_path": BOSS_REWARD_ICON_COFFEE_POT,
		},
		{
			"id": "max_hp_and_heal",
			"title": "Tomarse un respiro",
			"description": "Aumentá tu vida máxima en 4 y recuperá el 20% de tu vida máxima.",
			"icon_path": BOSS_REWARD_ICON_LUNGS,
		},
		{
			"id": "temporary_energy",
			"title": "Café antes del final",
			"description": "Obtené +1 de energía máxima durante los próximos 3 combates.",
			"icon_path": BOSS_REWARD_ICON_COFFEE_CUP,
		},
		{
			"id": "clear_mind",
			"title": "Mente despejada",
			"description": "El próximo combate comienza con 12 de escudo y anulás el primer debuff recibido.",
			"icon_path": BOSS_REWARD_ICON_MEDITATION,
		},
		{
			"id": "extra_rare_card",
			"title": "Promoción directa",
			"description": "Elegí una carta rara adicional.",
			"icon_path": BOSS_REWARD_ICON_CONFIRMED,
		},
	]


func _with_zone_reward_preview(reward_data: Dictionary) -> Dictionary:
	var result: Dictionary = reward_data.duplicate(true)
	var current_hp: int = GameState.vida_actual
	var max_hp: int = GameState.vida_maxima
	var reward_id: String = String(result.get("id", ""))

	match reward_id:
		"heal_big":
			var heal_amount: int = int(ceil(float(max_hp) * 0.40))
			var missing_hp: int = maxi(max_hp - current_hp, 0)
			var effective_heal: int = mini(heal_amount, missing_hp)
			result["preview"] = "Recuperarás %d HP" % effective_heal
		"max_hp_big":
			var hp_after_increase: int = mini(current_hp + 8, max_hp + 8)
			result["preview"] = "Vida máxima: %d -> %d | Vida: %d -> %d" % [
				max_hp,
				max_hp + 8,
				current_hp,
				hp_after_increase,
			]
		"max_hp_and_heal":
			var heal_amount: int = int(ceil(float(max_hp) * 0.20))
			result["preview"] = "Vida máxima: %d -> %d | Recuperarás %d HP" % [max_hp, max_hp + 4, heal_amount]
		"temporary_energy":
			result["preview"] = "+1 energía durante 3 combates"
		"clear_mind":
			result["preview"] = "Próximo combate: +12 escudo y 1 bloqueo de debuff"
		"extra_rare_card":
			result["preview"] = "1 carta Ingeniero adicional"
		_:
			result["preview"] = ""

	return result


func _on_zone_boss_reward_selected(reward_data: Dictionary) -> void:
	if zone_boss_reward_screen != null:
		zone_boss_reward_screen.hide_rewards()

	_apply_zone_boss_reward(reward_data)

	if String(reward_data.get("id", "")) == "extra_rare_card":
		_show_card_reward(EXTRA_RARE_REWARD_RARITIES, "extra_rare")
	else:
		_show_card_reward()


func _apply_zone_boss_reward(reward_data: Dictionary) -> void:
	var reward_id: String = String(reward_data.get("id", ""))
	match reward_id:
		"heal_big":
			var heal_amount: int = int(ceil(float(GameState.vida_maxima) * 0.40))
			GameState.heal_player(heal_amount)
		"max_hp_big":
			GameState.increase_max_hp(8, true)
		"max_hp_and_heal":
			var previous_max_hp: int = GameState.vida_maxima
			GameState.increase_max_hp(4, false)
			GameState.heal_player(int(ceil(float(previous_max_hp) * 0.20)))
		"temporary_energy":
			GameState.add_temporary_energy_battles(3)
		"clear_mind":
			GameState.activate_clear_mind_next_combat()
		"extra_rare_card":
			pass
		_:
			push_warning("CombatManager: recompensa de jefe desconocida '%s'." % reward_id)

	player.load_hp_from_run_state()
	update_ui()
	GameState.save_game()


func _on_reward_card_selected(card_data: CardData, _card_ui: CardUI, reward_mode: String = "normal") -> void:
	print("Carta elegida: %s" % card_data.card_name)
	GameState.add_card_to_run_deck(card_data)
	reward_panel.visible = false
	if reward_mode == "extra_rare":
		_show_card_reward()
		return

	GameState.completar_nodo_actual()
	_return_to_map()


func abandon_combat() -> void:
	if game_over_in_progress:
		return

	battle_has_ended = true
	_save_player_hp_at_combat_end()
	_return_to_map()


func _save_player_hp_at_combat_end() -> void:
	player.sync_hp_to_run_state()
	print("[COMBAT END] Guardando HP:", player.current_hp, "/", player.max_hp)


func _return_to_map() -> void:
	if returning_to_map or game_over_in_progress:
		return

	returning_to_map = true
	AudioManager.stop_music()
	call_deferred("_deferred_return_to_map")


func _return_to_main_menu() -> void:
	if returning_to_map:
		return

	returning_to_map = true
	AudioManager.stop_music()
	call_deferred("_deferred_return_to_main_menu")


func _deferred_return_to_map() -> void:
	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_file(MAP_SCENE_PATH)


func _deferred_return_to_main_menu() -> void:
	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _show_hand() -> void:
	_clear_hand_ui()

	for card_data in deck_manager.hand:
		var card_ui: CardUI = card_scene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_clicked.connect(play_card)


func _play_combat_announcement(title: String, subtitle: String = "") -> void:
	if announcement_overlay == null or battle_has_ended or returning_to_map:
		return

	await announcement_overlay.play_announcement(title, subtitle)


func _get_turn_subtitle() -> String:
	return "Turno %d" % max(combat_turn_number, 1)


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


func _play_visual_events(events: Array) -> void:
	if combat_animation_controller == null or events.is_empty() or game_over_in_progress:
		return
	await combat_animation_controller.play_sequence(events)


func _capture_visual_state() -> Dictionary:
	return {
		"player_hp": player.current_hp,
		"player_max_hp": player.max_hp,
		"player_block": player.block,
		"player_energy": player.current_energy,
		"player_states": _copy_state_names(player.estados),
		"player_attack_bonus": player.attack_bonus,
		"player_defense_bonus": player.defense_card_bonus,
		"enemy_hp": enemy.current_hp,
		"enemy_max_hp": enemy.max_hp,
		"enemy_block": enemy.block,
		"enemy_states": _copy_state_names(enemy.estados),
		"enemy_attack_bonus": enemy.attack_bonus,
		"enemy_permanent_attack_bonus": enemy.permanent_attack_bonus,
		"multi_enemy_hps": multi_enemy_hps.duplicate(),
		"hand_count": deck_manager.hand.size(),
		"draw_count": deck_manager.draw_pile.size(),
		"discard_count": deck_manager.discard_pile.size(),
	}


func _copy_state_names(states: Array) -> Array[String]:
	var result: Array[String] = []
	for state in states:
		if state is Dictionary and state.has("nombre"):
			result.append(String(state.nombre))
	return result


func _build_visual_events_from_state_delta(before_state: Dictionary, after_state: Dictionary, source_actor: String, target_actor: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	_append_damage_event(events, before_state, after_state, source_actor, target_actor)
	_append_self_damage_event(events, before_state, after_state, source_actor)
	if _state_delta_killed_player(before_state, after_state):
		events.append({"type": "death", "target": "player"})
		return events

	_append_shield_event(events, before_state, after_state, source_actor)
	_append_heal_event(events, before_state, after_state, source_actor)
	_append_card_count_events(events, before_state, after_state)
	_append_energy_event(events, before_state, after_state, source_actor)
	_append_status_events(events, before_state, after_state, source_actor, target_actor)
	_append_buff_events(events, before_state, after_state, source_actor)
	_append_death_events(events, before_state, after_state)
	_apply_multi_enemy_event_indices(events, before_state, after_state)
	return events


func _state_delta_killed_player(before_state: Dictionary, after_state: Dictionary) -> bool:
	return int(before_state.get("player_hp", 0)) > 0 and int(after_state.get("player_hp", 0)) <= 0


func _append_damage_event(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, source_actor: String, target_actor: String) -> void:
	var hp_key := "%s_hp" % target_actor
	var block_key := "%s_block" % target_actor
	var hp_loss := int(before_state.get(hp_key, 0)) - int(after_state.get(hp_key, 0))
	var block_loss := int(before_state.get(block_key, 0)) - int(after_state.get(block_key, 0))
	var total_loss := hp_loss + maxi(block_loss, 0)
	if total_loss <= 0:
		return
	events.append({
		"type": "damage",
		"value": total_loss,
		"source": source_actor,
		"target": target_actor,
	})


func _append_self_damage_event(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, source_actor: String) -> void:
	var hp_key := "%s_hp" % source_actor
	var hp_loss := int(before_state.get(hp_key, 0)) - int(after_state.get(hp_key, 0))
	if hp_loss <= 0:
		return
	events.append({
		"type": "damage",
		"value": hp_loss,
		"source": source_actor,
		"target": source_actor,
	})


func _append_shield_event(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, actor: String) -> void:
	var block_key := "%s_block" % actor
	var gained := int(after_state.get(block_key, 0)) - int(before_state.get(block_key, 0))
	if gained <= 0:
		return
	events.append({"type": "shield", "value": gained, "source": actor, "target": actor})


func _append_heal_event(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, actor: String) -> void:
	var hp_key := "%s_hp" % actor
	var healed := int(after_state.get(hp_key, 0)) - int(before_state.get(hp_key, 0))
	if healed <= 0:
		return
	events.append({"type": "heal", "value": healed, "source": actor, "target": actor})


func _append_card_count_events(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary) -> void:
	var hand_delta := int(after_state.get("hand_count", 0)) - int(before_state.get("hand_count", 0))
	var discard_delta := int(after_state.get("discard_count", 0)) - int(before_state.get("discard_count", 0))
	if discard_delta > 0:
		events.append({"type": "discard", "value": discard_delta, "source": "player"})
	if hand_delta > 0:
		events.append({"type": "draw", "value": hand_delta, "source": "player"})


func _append_energy_event(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, actor: String) -> void:
	if actor != "player":
		return
	var gained := int(after_state.get("player_energy", 0)) - int(before_state.get("player_energy", 0))
	if gained <= 0:
		return
	events.append({"type": "energy", "value": gained, "source": "player", "target": "player"})


func _append_status_events(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, source_actor: String, target_actor: String) -> void:
	_append_new_states_for_actor(events, before_state, after_state, source_actor, target_actor)
	_append_new_states_for_actor(events, before_state, after_state, source_actor, source_actor)


func _append_new_states_for_actor(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, source_actor: String, actor: String) -> void:
	var before_states: Array = before_state.get("%s_states" % actor, [])
	var after_states: Array = after_state.get("%s_states" % actor, [])
	for state_name in after_states:
		if before_states.has(state_name):
			continue
		var event_type := "status" if actor != source_actor else "buff"
		events.append({
			"type": event_type,
			"label": _format_status_label(String(state_name)),
			"source": source_actor,
			"target": actor,
		})


func _append_buff_events(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary, actor: String) -> void:
	var keys := []
	if actor == "player":
		keys = ["player_attack_bonus", "player_defense_bonus"]
	else:
		keys = ["enemy_attack_bonus", "enemy_permanent_attack_bonus"]
	for key in keys:
		var gained := int(after_state.get(key, 0)) - int(before_state.get(key, 0))
		if gained > 0:
			events.append({"type": "buff", "label": "+%d" % gained, "source": actor, "target": actor})


func _append_death_events(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary) -> void:
	var player_hp_before := int(before_state.get("player_hp", 0))
	var player_hp_after := int(after_state.get("player_hp", 0))
	if player_hp_before > 0 and player_hp_after <= 0:
		events.append({"type": "death", "target": "player"})

	if multi_enemy_active:
		var before_hps: Array = before_state.get("multi_enemy_hps", [])
		var after_hps: Array = after_state.get("multi_enemy_hps", [])
		for index in range(min(before_hps.size(), after_hps.size())):
			if int(before_hps[index]) > 0 and int(after_hps[index]) <= 0:
				events.append({"type": "death", "target": "enemy", "target_index": index})
		return

	var enemy_hp_before := int(before_state.get("enemy_hp", 0))
	var enemy_hp_after := int(after_state.get("enemy_hp", 0))
	if enemy_hp_before > 0 and enemy_hp_after <= 0:
		events.append({"type": "death", "target": "enemy"})


func _apply_multi_enemy_event_indices(events: Array[Dictionary], before_state: Dictionary, after_state: Dictionary) -> void:
	if not multi_enemy_active:
		return

	var active_index := _get_first_alive_multi_enemy_index()
	var damaged_index := _find_multi_enemy_damaged_index(before_state, after_state)

	for event in events:
		if not event is Dictionary:
			continue
		if String(event.get("source", "")) == "enemy" and not event.has("source_index") and active_index >= 0:
			event["source_index"] = active_index
		if String(event.get("target", "")) == "enemy" and not event.has("target_index"):
			if damaged_index >= 0 and String(event.get("type", "")) == "damage":
				event["target_index"] = damaged_index
			elif active_index >= 0:
				event["target_index"] = active_index


func _find_multi_enemy_damaged_index(before_state: Dictionary, after_state: Dictionary) -> int:
	var before_hps: Array = before_state.get("multi_enemy_hps", [])
	var after_hps: Array = after_state.get("multi_enemy_hps", [])
	for index in range(min(before_hps.size(), after_hps.size())):
		if int(after_hps[index]) < int(before_hps[index]):
			return index
	return -1


func _format_status_label(state_name: String) -> String:
	return state_name.replace("_", " ").capitalize()

func _apply_card_effect(card_data: CardData) -> void:
	if card_data.effect_id == "basic_attack":
		_apply_player_attack(card_data.value)
	elif card_data.effect_id == "basic_block":
		_gain_player_block(card_data.value)
	elif card_data.effect_id == "mate_salvador":
		AudioManager.play_sfx("buff_jugador")
		player.attack_bonus = card_data.value
		player.attack_bonus_turns = 2
	elif card_data.effect_id == "trasnochar":
		AudioManager.play_sfx("buff_jugador")
		player.lose_hp(card_data.value)
		player.next_attack_multiplier = 2.0
	elif card_data.effect_id == "machetearse":
		_play_machetearse()
	elif card_data.effect_id == "aprobado_con_4":
		AudioManager.play_sfx("buff_jugador")
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
		AudioManager.play_sfx("buff_jugador")
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
		AudioManager.play_sfx("buff_jugador")
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
		player.set_current_hp(0)
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
	if combat_input_locked:
		return

	_set_combat_input_locked(true)
	var discard_from_position := card_ui.global_position
	var visual_events: Array[Dictionary] = [{
		"type": "discard",
		"value": 1,
		"source": "player",
		"from_position": discard_from_position,
	}]

	if not deck_manager.discard_specific_card(card_data):
		_set_combat_input_locked(false)
		if deck_manager.hand.is_empty():
			_finish_discard_selection_without_cards()
		return

	card_ui.queue_free()
	discard_selection_remaining -= 1
	discard_selection_completed += 1
	_show_hand()

	match discard_selection_mode:
		"player_replace_one":
			var drawn_cards := deck_manager.draw_cards(1)
			if not drawn_cards.is_empty():
				visual_events.append({"type": "draw", "value": drawn_cards.size(), "source": "player"})
			_reset_discard_selection()
			_show_hand()
			update_ui()
			await _play_visual_events(visual_events)
		"player_replace_zero":
			_reset_discard_selection()
			update_ui()
			await _play_visual_events(visual_events)
		"player_optional_block":
			if discard_selection_remaining <= 0 or deck_manager.hand.is_empty():
				var before_state := _capture_visual_state()
				var gained_block := discard_selection_completed * discard_selection_reward_block_per_card
				_gain_player_block(gained_block)
				visual_events.append_array(_build_visual_events_from_state_delta(before_state, _capture_visual_state(), "player", "enemy"))
				_reset_discard_selection()
				update_ui()
				await _play_visual_events(visual_events)
			else:
				enemy_intent_label.text = "Descarta hasta %d carta(s) mas" % discard_selection_remaining
				update_ui()
				await _play_visual_events(visual_events)
		"enemy_forced":
			if discard_selection_remaining <= 0 or deck_manager.hand.is_empty():
				await _play_visual_events(visual_events)
				_set_combat_input_locked(false)
				_finish_enemy_forced_discard()
				return
			else:
				enemy_intent_label.text = "Descarta %d carta(s) mas" % discard_selection_remaining
				update_ui()
				await _play_visual_events(visual_events)
		_:
			_reset_discard_selection()
			update_ui()
			await _play_visual_events(visual_events)

	_set_combat_input_locked(false)

func _execute_enemy_card(card_data: CardData) -> void:
	var player_hp_before := player.current_hp
	var player_block_before := player.block
	var enemy_hp_before := enemy.current_hp
	var enemy_block_before := enemy.block

	if not enemy.spend_energy(card_data.cost):
		print("DEBUG Enemy: no pudo pagar '%s'. Energía=%d coste=%d" % [card_data.card_name, enemy.current_energy, card_data.cost])
		return

	enemy.record_executed_intent(card_data, _get_current_zone_index())
	var before_visual_state := _capture_visual_state()
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
			_apply_enemy_state_to_player("estres", 0, 1)
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
			_apply_enemy_state_to_player("distraccion", 0, 2)
		"parcialito_sorpresa":
			var damage := 14
			if player.has_negative_state():
				damage += 6
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"criterio_estricto":
			enemy.gain_attack_bonus(4, 2)
		"trabajo_practico_obligatorio":
			_apply_enemy_state_to_player("trabajo_practico_obligatorio", 1, 2)
		"explicacion_confusa":
			_apply_enemy_state_to_player("confusion", 0, 2)
		"unidad_acumulativa":
			enemy.gain_permanent_attack_bonus(2)
		"parcial_integrador":
			var damage := 18
			if deck_manager.hand.size() < 3:
				damage += 6
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"correccion_en_rojo":
			player.take_damage(enemy.calcular_dano_enemigo(12))
			_apply_enemy_state_to_player("estres", 0, 1)
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
			_apply_enemy_state_to_player("bibliografia_extra", 1, 2)
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
			_apply_enemy_state_to_player("estres", 0, 1)
			_apply_enemy_state_to_player("distraccion", 0, 1)
		"silencio_incomodo":
			_apply_enemy_state_to_player("estres", 0, 1)
			if deck_manager.hand.size() >= 4:
				deck_manager.discard_random_cards(1)
				_show_hand()
		"pregunta_de_repaso":
			var damage := 7
			if player_played_skill_last_turn:
				damage += 5
			player.take_damage(enemy.calcular_dano_enemigo(damage))
		"quien_quiere_pasar":
			_apply_enemy_state_to_player("panico", 0, 1)
		"lista_incompleta":
			_begin_enemy_forced_discard(1, 6)
		"dictado_acelerado":
			_apply_enemy_state_to_player("distraccion", 0, 1)
			_apply_enemy_state_to_player("defensa_menos", 0, 1)
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
			_apply_enemy_state_to_player("estres", 0, 2)
		"consigna_ambigua":
			_apply_enemy_state_to_player("confusion", 0, 2)
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
			_apply_enemy_state_to_player("habilidad_mas", 0, 2)
		"bibliografia_obligatoria":
			_apply_enemy_state_to_player("distraccion", 0, 2)
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

	var took_hit := (player.current_hp < player_hp_before) or (player.block < player_block_before)
	if took_hit:
		if current_enemy_name == FIRST_ENEMY_NAME:
			AudioManager.play_sfx("hit_tom_apostol")
		elif current_enemy_name.contains("Integral"):
			AudioManager.play_sfx("hit_integral")
			
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

	var visual_events := _build_visual_events_from_state_delta(before_visual_state, _capture_visual_state(), "enemy", "player")
	update_ui()
	await _play_visual_events(visual_events)
	check_combat_end()


func _begin_discard_selection(mode: String, amount: int, penalty_damage: int, reward_block_per_card: int = 0) -> void:
	if amount <= 0 or deck_manager.hand.is_empty():
		_finish_discard_selection_without_cards(mode, penalty_damage)
		return

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
		_reset_discard_selection()
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


func _finish_discard_selection_without_cards(mode: String = "", penalty_damage: int = 0) -> void:
	var resolved_mode := mode
	if resolved_mode.is_empty():
		resolved_mode = discard_selection_mode
	var resolved_penalty_damage := penalty_damage
	if resolved_penalty_damage <= 0:
		resolved_penalty_damage = discard_selection_penalty_damage

	_reset_discard_selection()

	match resolved_mode:
		"player_replace_one":
			deck_manager.draw_cards(1)
			_show_hand()
		"enemy_forced":
			if resolved_penalty_damage > 0:
				player.take_damage(resolved_penalty_damage)
		_:
			pass

	end_turn_button.disabled = false
	update_ui()
	check_combat_end()


func _gain_player_block(amount: int) -> void:
	player.gain_block(amount)
	if amount > 0 and artifact_draw_on_block:
		var drawn_cards := deck_manager.draw_cards(1)
		if not drawn_cards.is_empty():
			_show_hand()


func _apply_artifact_draw_bonus(drawn_count: int) -> void:
	if artifact_block_per_draw <= 0 or drawn_count <= 0:
		return

	player.gain_block(artifact_block_per_draw * drawn_count)


func _apply_artifact_copy_card_once() -> void:
	if not artifact_copy_card_available or deck_manager.hand.is_empty():
		return

	artifact_copy_card_available = false
	var source_card: CardData = deck_manager.hand.pick_random()
	deck_manager.hand.append(_copy_combat_card(source_card))
	deck_manager.print_deck_debug_counts()
	_show_hand()


func _copy_combat_card(card: CardData) -> CardData:
	return CardData.new().setup(
		card.card_name,
		card.cost,
		card.card_type,
		card.value,
		card.description,
		card.effect_id,
		card.rareza,
		card.raw_effect_text,
		card.image_path,
		card.enemy_archetypes
	)


func _apply_player_attack(base_damage: int) -> void:
	_apply_damage_to_current_enemy(player.get_attack_damage(base_damage + artifact_attack_damage_bonus))


func _apply_damage_to_current_enemy(amount: int) -> void:
	if amount > 0:
		AudioManager.play_sfx("hit_jugador")
		
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
	battle_visuals.update_multi_enemy_labels(multi_enemy_hps, multi_enemy_max_hps)
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


func _apply_enemy_state_to_player(state_name: String, value: int, duration: int) -> void:
	if artifact_immunity_states.has(state_name):
		var blocked_state_label: String = state_name.replace("_", " ").capitalize()
		battle_visuals.show_player_speech("Inmune a %s" % blocked_state_label)
		print("[ARTIFACT] Inmunidad bloqueó el estado:", state_name)
		return

	if clear_mind_blocks_debuff_this_combat:
		clear_mind_blocks_debuff_this_combat = false
		var state_label: String = state_name.replace("_", " ").capitalize()
		battle_visuals.show_player_speech("Mente despejada bloqueó %s" % state_label)
		print("[ZONE REWARD] Mente despejada bloqueó el estado enemigo:", state_name)
		return

	player.aplicar_estado(state_name, value, duration)


func _apply_generic_state_effects_to_player(effect_text: String) -> void:
	var duration := _extract_duration(effect_text, 1)

	if effect_text.contains("estres"):
		_apply_enemy_state_to_player("estres", 0, duration)
	if effect_text.contains("distraccion"):
		_apply_enemy_state_to_player("distraccion", 0, duration)
	if effect_text.contains("confusion"):
		_apply_enemy_state_to_player("confusion", 0, duration)
	if effect_text.contains("panico"):
		_apply_enemy_state_to_player("panico", 0, duration)
	if effect_text.contains("cansancio"):
		_apply_enemy_state_to_player("cansancio", 0, duration)
	if effect_text.contains("defensa") and (effect_text.contains("menos") or effect_text.contains("25% menos")):
		_apply_enemy_state_to_player("defensa_menos", 0, duration)
	if effect_text.contains("habilidad") and (effect_text.contains("cuestan 1") or effect_text.contains("cuesta 1")):
		_apply_enemy_state_to_player("habilidad_mas", 0, duration)
	if effect_text.contains("roba 1 carta menos"):
		_apply_enemy_state_to_player("distraccion", 0, duration)


func _draw_from_effect_text(effect_text: String) -> void:
	var amount := _extract_number_after_any(effect_text, ["roba", "robas"])
	if amount <= 0:
		return

	var drawn_cards := deck_manager.draw_cards(amount)
	_apply_artifact_draw_bonus(drawn_cards.size())
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
