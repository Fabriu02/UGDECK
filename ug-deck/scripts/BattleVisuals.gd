extends Node2D
class_name BattleVisuals

const PLAYER_IMAGE_PATH := "res://assets/characters/protagonista mejorado.png"
const ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const DEFAULT_ENEMY_SCALE := Vector2(0.7, 0.7)
const CHARACTER_STATUS_BAR_SCRIPT := preload("res://scripts/ui/CharacterStatusBar.gd")

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_placeholder: Label = $PlayerPlaceholder
@onready var enemy_placeholder: Label = $EnemyPlaceholder
@onready var player_anim_player: AnimationPlayer = $PlayerSprite/AnimationPlayer

var multi_enemy_labels: Array[Label] = []
var multi_enemy_sprites: Array[Sprite2D] = []
var multi_enemy_status_bars: Array[CharacterStatusBar] = []
var multi_enemy_max_hps: Array[int] = []
var player_status_bar: CharacterStatusBar
var enemy_status_bar: CharacterStatusBar
var player_speech_panel: PanelContainer
var player_speech_label: Label
var player_speech_tween: Tween


func _ready() -> void:
	_try_load_texture(PLAYER_IMAGE_PATH, player_sprite, player_placeholder)
	_try_load_texture(ENEMY_IMAGE_PATH, enemy_sprite, enemy_placeholder)
	_setup_single_status_bars()

	if player_anim_player.has_animation("idle"):
		player_anim_player.play("idle")


func set_enemy_image(path: String, sprite_scale: Vector2 = DEFAULT_ENEMY_SCALE) -> void:
	clear_multi_enemy_visuals()
	if enemy_status_bar != null:
		enemy_status_bar.visible = true
	enemy_sprite.scale = sprite_scale
	_try_load_texture(path, enemy_sprite, enemy_placeholder)


func set_enemy_display_name(display_name: String) -> void:
	enemy_placeholder.text = display_name


func show_multi_enemy_group(image_paths: Variant, names: Array, hps: Array, max_hps: Array = [], sprite_scales: Array = []) -> void:
	clear_multi_enemy_visuals()
	enemy_sprite.visible = false
	enemy_placeholder.visible = false
	if enemy_status_bar != null:
		enemy_status_bar.visible = false

	multi_enemy_max_hps.clear()
	for index in range(names.size()):
		var image_path := _get_multi_enemy_image_path(image_paths, index)
		var texture := load(image_path) as Texture2D
		var max_hp: int = int(max_hps[index]) if index < max_hps.size() else int(hps[index])
		multi_enemy_max_hps.append(max_hp)

		if texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(735 + index * 105, 245)
			sprite.scale = _get_multi_enemy_sprite_scale(sprite_scales, index)
			add_child(sprite)
			multi_enemy_sprites.append(sprite)

		var status_bar: CharacterStatusBar = CHARACTER_STATUS_BAR_SCRIPT.new()
		status_bar.position = Vector2(680 + index * 105, 310)
		status_bar.custom_minimum_size = Vector2(118, 50)
		status_bar.size = status_bar.custom_minimum_size
		add_child(status_bar)
		multi_enemy_status_bars.append(status_bar)

		var label := Label.new()
		label.text = "%s\n%d/%d" % [names[index], hps[index], max_hp]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(680 + index * 105, 115)
		label.size = Vector2(110, 52)
		add_child(label)
		multi_enemy_labels.append(label)


func update_multi_enemy_labels(hps: Array, max_hps: Array = []) -> void:
	for index in range(min(multi_enemy_labels.size(), hps.size())):
		var label: Label = multi_enemy_labels[index]
		var current_name: String = String(label.text.split("\n")[0])
		var max_hp: int = _get_multi_enemy_max_hp(index, hps, max_hps)
		label.text = "%s\n%d/%d" % [current_name, hps[index], max_hp]
		label.modulate = Color(0.45, 0.45, 0.45, 1.0) if hps[index] <= 0 else Color.WHITE
		if index < multi_enemy_sprites.size():
			multi_enemy_sprites[index].modulate = Color(0.35, 0.35, 0.35, 0.7) if hps[index] <= 0 else Color.WHITE


func update_player_status_bar(hp: int, max_hp: int, block: int, states: Array) -> void:
	if player_status_bar == null:
		_setup_single_status_bars()
	player_status_bar.update_values("Jugador", hp, max_hp, block, states)


func update_enemy_status_bar(display_name: String, hp: int, max_hp: int, block: int, states: Array) -> void:
	if enemy_status_bar == null:
		_setup_single_status_bars()
	enemy_status_bar.update_values(display_name, hp, max_hp, block, states)


func update_multi_enemy_status_bars(names: Array, hps: Array, max_hps: Array, shared_block: int, shared_states: Array, active_index: int) -> void:
	for index in range(min(multi_enemy_status_bars.size(), hps.size())):
		var max_hp: int = _get_multi_enemy_max_hp(index, hps, max_hps)
		var block: int = shared_block if index == active_index else 0
		var states: Array = shared_states if index == active_index else []
		multi_enemy_status_bars[index].update_values(String(names[index]), int(hps[index]), max_hp, block, states)


func show_player_speech(text: String) -> void:
	_setup_player_speech_bubble()

	if player_speech_tween != null:
		player_speech_tween.kill()

	player_speech_label.text = text
	player_speech_panel.modulate = Color.WHITE
	player_speech_panel.visible = true

	player_speech_tween = create_tween()
	player_speech_tween.tween_interval(1.35)
	player_speech_tween.tween_property(player_speech_panel, "modulate:a", 0.0, 0.25)
	player_speech_tween.tween_callback(func(): player_speech_panel.visible = false)


func clear_multi_enemy_visuals() -> void:
	for label in multi_enemy_labels:
		if is_instance_valid(label):
			label.queue_free()
	multi_enemy_labels.clear()

	for sprite in multi_enemy_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	multi_enemy_sprites.clear()

	for status_bar in multi_enemy_status_bars:
		if is_instance_valid(status_bar):
			status_bar.queue_free()
	multi_enemy_status_bars.clear()

	multi_enemy_max_hps.clear()
	enemy_sprite.visible = true
	if enemy_status_bar != null:
		enemy_status_bar.visible = true


func _get_multi_enemy_image_path(image_paths: Variant, index: int) -> String:
	if image_paths is Array:
		var paths := image_paths as Array
		if index < paths.size():
			return String(paths[index])
	return String(image_paths)


func _get_multi_enemy_sprite_scale(sprite_scales: Array, index: int) -> Vector2:
	if index < sprite_scales.size() and typeof(sprite_scales[index]) == TYPE_VECTOR2:
		return sprite_scales[index]
	return Vector2(0.18, 0.18)


func _get_multi_enemy_max_hp(index: int, hps: Array, max_hps: Array) -> int:
	if index < max_hps.size():
		return int(max_hps[index])
	if index < multi_enemy_max_hps.size():
		return multi_enemy_max_hps[index]
	return int(hps[index])


func _try_load_texture(path: String, sprite: Sprite2D, placeholder: Label) -> void:
	if not FileAccess.file_exists(path):
		sprite.visible = false
		placeholder.visible = true
		return

	var texture := load(path) as Texture2D
	if texture == null:
		sprite.visible = false
		placeholder.visible = true
		return

	sprite.texture = texture
	sprite.visible = true
	placeholder.visible = false


func _setup_single_status_bars() -> void:
	if player_status_bar == null:
		player_status_bar = CHARACTER_STATUS_BAR_SCRIPT.new()
		player_status_bar.position = player_sprite.position + Vector2(-88, 82)
		add_child(player_status_bar)

	if enemy_status_bar == null:
		enemy_status_bar = CHARACTER_STATUS_BAR_SCRIPT.new()
		enemy_status_bar.position = enemy_sprite.position + Vector2(-88, 96)
		add_child(enemy_status_bar)


func _setup_player_speech_bubble() -> void:
	if player_speech_panel != null:
		return

	player_speech_panel = PanelContainer.new()
	player_speech_panel.position = player_sprite.position + Vector2(-98, -118)
	player_speech_panel.custom_minimum_size = Vector2(210, 44)
	player_speech_panel.visible = false
	player_speech_panel.z_index = 140

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.96, 0.88, 0.96)
	style.border_color = Color(0.08, 0.08, 0.08, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	player_speech_panel.add_theme_stylebox_override("panel", style)
	add_child(player_speech_panel)

	player_speech_label = Label.new()
	player_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_speech_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_speech_label.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	player_speech_label.add_theme_font_size_override("font_size", 13)
	player_speech_panel.add_child(player_speech_label)
