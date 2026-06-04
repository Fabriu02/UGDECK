extends Node2D
class_name BattleVisuals

const PLAYER_IMAGE_PATH := "res://assets/characters/protagonista mejorado.png"
const ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const DEFAULT_ENEMY_SCALE := Vector2(0.44, 0.44)
const CHARACTER_STATUS_BAR_SCRIPT := preload("res://scripts/ui/CharacterStatusBar.gd")
const COMBAT_CHARACTER_ANIMATOR_SCRIPT := preload("res://scripts/CombatCharacterAnimator.gd")
const ANIMATION_REFERENCE_VISUAL_ID := "tom_apostol"
const ANIMATION_REFERENCE_SCALE := DEFAULT_ENEMY_SCALE
const ANIMATION_FRAME_COLUMNS := 5

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_placeholder: Label = $PlayerPlaceholder
@onready var enemy_placeholder: Label = $EnemyPlaceholder
@onready var player_anim_player: AnimationPlayer = $PlayerSprite/AnimationPlayer

var multi_enemy_labels: Array[Label] = []
var multi_enemy_sprites: Array = []
var multi_enemy_animators: Array = []
var multi_enemy_status_bars: Array[CharacterStatusBar] = []
var multi_enemy_max_hps: Array[int] = []
var player_animator: CombatCharacterAnimator
var enemy_animator: CombatCharacterAnimator
var player_status_bar: CharacterStatusBar
var enemy_status_bar: CharacterStatusBar
var player_speech_panel: PanelContainer
var player_speech_label: Label
var player_speech_tween: Tween
var animation_reference_frame_size := Vector2.ZERO
var animation_reference_render_size := Vector2.ZERO
var enemy_visual_scale_multiplier := 1.0


func _ready() -> void:
	_setup_character_animators()
	_try_load_texture(PLAYER_IMAGE_PATH, player_sprite, player_placeholder)
	_try_load_texture(ENEMY_IMAGE_PATH, enemy_sprite, enemy_placeholder)
	set_player_visual("protagonista")
	_setup_single_status_bars()

	if player_anim_player.has_animation("idle"):
		player_anim_player.play("idle")


func set_player_visual(visual_id: String, sprite_scale: Vector2 = Vector2(0.11, 0.11), sprite_offset: Vector2 = Vector2(0, 0)) -> void:
	if player_animator == null:
		_setup_character_animators()

	player_animator.position = player_sprite.position + sprite_offset
	player_animator.scale = sprite_scale
	player_animator.z_index = player_sprite.z_index

	if player_animator.configure(visual_id):
		_apply_tom_apostol_reference_scale(player_animator)
		player_sprite.visible = false
		player_placeholder.visible = false
		if player_anim_player != null:
			player_anim_player.stop()
	else:
		player_animator.visible = false
		if player_sprite.texture != null:
			player_sprite.visible = true


func set_enemy_image(path: String, sprite_scale: Vector2 = DEFAULT_ENEMY_SCALE, visual_id: String = "", visual_scale_multiplier: float = 1.0) -> void:
	clear_multi_enemy_visuals()
	if enemy_status_bar != null:
		enemy_status_bar.visible = true
	enemy_visual_scale_multiplier = maxf(visual_scale_multiplier, 0.1)
	enemy_sprite.scale = sprite_scale
	_try_load_texture(path, enemy_sprite, enemy_placeholder)
	_set_enemy_visual(visual_id)


func set_enemy_display_name(display_name: String) -> void:
	enemy_placeholder.text = display_name


func show_multi_enemy_group(image_paths: Variant, names: Array, hps: Array, max_hps: Array = [], sprite_scales: Array = [], visual_ids: Array = []) -> void:
	clear_multi_enemy_visuals()
	enemy_sprite.visible = false
	if enemy_animator != null:
		enemy_animator.visible = false
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
			sprite.position = Vector2(735 + index * 105, 303)
			sprite.scale = _get_multi_enemy_sprite_scale(sprite_scales, index)
			add_child(sprite)
			multi_enemy_sprites.append(sprite)

			var visual_id := _get_multi_enemy_visual_id(visual_ids, index)
			var animator := _create_animator_from_sprite(sprite, visual_id)
			multi_enemy_animators.append(animator)
		else:
			multi_enemy_sprites.append(null)
			multi_enemy_animators.append(null)

		var status_bar: CharacterStatusBar = CHARACTER_STATUS_BAR_SCRIPT.new()
		status_bar.position = Vector2(680 + index * 105, 368)
		status_bar.custom_minimum_size = Vector2(118, 50)
		status_bar.size = status_bar.custom_minimum_size
		add_child(status_bar)
		multi_enemy_status_bars.append(status_bar)

		var label := Label.new()
		label.text = "%s\n%d/%d" % [names[index], hps[index], max_hp]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(680 + index * 105, 173)
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
			var static_sprite: Sprite2D = multi_enemy_sprites[index]
			if static_sprite != null:
				static_sprite.modulate = Color(0.35, 0.35, 0.35, 0.7) if hps[index] <= 0 else Color.WHITE
		if index < multi_enemy_animators.size():
			var animator: CombatCharacterAnimator = multi_enemy_animators[index]
			if animator != null and animator.loaded:
				animator.modulate = Color(0.35, 0.35, 0.35, 0.7) if hps[index] <= 0 else Color.WHITE


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

	for animator in multi_enemy_animators:
		if is_instance_valid(animator):
			animator.queue_free()
	multi_enemy_animators.clear()

	for status_bar in multi_enemy_status_bars:
		if is_instance_valid(status_bar):
			status_bar.queue_free()
	multi_enemy_status_bars.clear()

	multi_enemy_max_hps.clear()
	enemy_sprite.visible = true
	if enemy_animator != null and enemy_animator.loaded:
		enemy_animator.visible = false
	if enemy_status_bar != null:
		enemy_status_bar.visible = true


func play_character_animation(actor: String, animation_name: String, index: int = -1) -> void:
	var animator := _get_animator(actor, index)
	if animator == null or not animator.loaded:
		return

	animator.play_animation_safe(animation_name)


func play_character_death(actor: String, index: int = -1) -> void:
	var animator := _get_animator(actor, index)
	if animator == null or not animator.loaded:
		return

	await animator.play_death_and_wait()


func get_actor_visual_node(actor: String, index: int = -1) -> Node2D:
	if actor == "enemy":
		if not multi_enemy_sprites.is_empty():
			var multi_animator := _get_animator("enemy", index)
			if multi_animator != null and multi_animator.loaded and multi_animator.visible:
				return multi_animator
			var multi_sprite := _get_multi_enemy_static_sprite(index)
			if multi_sprite != null:
				return multi_sprite
		if enemy_animator != null and enemy_animator.loaded and enemy_animator.visible:
			return enemy_animator
		return enemy_sprite

	if player_animator != null and player_animator.loaded and player_animator.visible:
		return player_animator
	return player_sprite


func _get_multi_enemy_image_path(image_paths: Variant, index: int) -> String:
	if image_paths is Array:
		var paths := image_paths as Array
		if index < paths.size():
			return String(paths[index])
	return String(image_paths)


func _get_multi_enemy_sprite_scale(sprite_scales: Array, index: int) -> Vector2:
	if index < sprite_scales.size() and typeof(sprite_scales[index]) == TYPE_VECTOR2:
		return sprite_scales[index]
	return Vector2(0.11, 0.11)


func _get_multi_enemy_visual_id(visual_ids: Array, index: int) -> String:
	if index < visual_ids.size():
		return String(visual_ids[index])
	return ""


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


func _setup_character_animators() -> void:
	if player_animator == null:
		player_animator = COMBAT_CHARACTER_ANIMATOR_SCRIPT.new()
		player_animator.name = "PlayerAnimator"
		player_animator.centered = player_sprite.centered
		player_animator.position = player_sprite.position
		player_animator.scale = player_sprite.scale
		add_child(player_animator)

	if enemy_animator == null:
		enemy_animator = COMBAT_CHARACTER_ANIMATOR_SCRIPT.new()
		enemy_animator.name = "EnemyAnimator"
		enemy_animator.centered = enemy_sprite.centered
		enemy_animator.position = enemy_sprite.position
		enemy_animator.scale = enemy_sprite.scale
		add_child(enemy_animator)


func _set_enemy_visual(visual_id: String, sprite_offset: Vector2 = Vector2.ZERO) -> void:
	if enemy_animator == null:
		_setup_character_animators()

	enemy_animator.position = enemy_sprite.position + sprite_offset
	enemy_animator.scale = enemy_sprite.scale
	enemy_animator.z_index = enemy_sprite.z_index

	if visual_id.is_empty():
		enemy_animator.visible = false
		return

	if enemy_animator.configure(visual_id):
		_apply_tom_apostol_reference_scale(enemy_animator)
		enemy_animator.scale *= enemy_visual_scale_multiplier
		enemy_sprite.visible = false
		enemy_placeholder.visible = false
	else:
		enemy_animator.visible = false
		if enemy_sprite.texture != null:
			enemy_sprite.visible = true


func _create_animator_from_sprite(sprite: Sprite2D, visual_id: String) -> CombatCharacterAnimator:
	if sprite == null or visual_id.is_empty():
		return null

	var animator: CombatCharacterAnimator = COMBAT_CHARACTER_ANIMATOR_SCRIPT.new()
	animator.name = "Animator_%s" % visual_id
	animator.centered = sprite.centered
	animator.position = sprite.position
	animator.scale = sprite.scale
	animator.z_index = sprite.z_index
	add_child(animator)

	if animator.configure(visual_id):
		_apply_tom_apostol_reference_scale(animator)
		sprite.visible = false
		return animator

	animator.queue_free()
	return null


func _get_animator(actor: String, index: int = -1) -> CombatCharacterAnimator:
	if actor == "enemy":
		if not multi_enemy_animators.is_empty():
			var resolved_index := index
			if resolved_index < 0:
				resolved_index = 0
			if resolved_index >= 0 and resolved_index < multi_enemy_animators.size():
				return multi_enemy_animators[resolved_index]
			return null
		return enemy_animator
	return player_animator


func _get_multi_enemy_static_sprite(index: int) -> Sprite2D:
	var resolved_index := index
	if resolved_index < 0:
		resolved_index = 0
	if resolved_index >= 0 and resolved_index < multi_enemy_sprites.size():
		return multi_enemy_sprites[resolved_index]
	return null


func _apply_tom_apostol_reference_scale(animator: CombatCharacterAnimator) -> void:
	if animator == null or not animator.loaded:
		return

	var reference_render_size := _get_animation_reference_render_size()
	if reference_render_size == Vector2.ZERO:
		return

	var frame_size := animator.get_animation_frame_size("idle")
	if frame_size == Vector2.ZERO:
		return

	var reference_max_size: float = maxf(reference_render_size.x, reference_render_size.y)
	var frame_max_size: float = maxf(frame_size.x, frame_size.y)
	if frame_max_size <= 0.0:
		return

	var uniform_scale: float = reference_max_size / frame_max_size
	animator.scale = Vector2(uniform_scale, uniform_scale)


func _get_animation_reference_render_size() -> Vector2:
	if animation_reference_render_size != Vector2.ZERO:
		return animation_reference_render_size

	animation_reference_frame_size = _load_visual_idle_frame_size(ANIMATION_REFERENCE_VISUAL_ID)
	if animation_reference_frame_size == Vector2.ZERO:
		push_warning("BattleVisuals: no se pudo calcular el tamano de referencia de tom_apostol.")
		return Vector2.ZERO

	animation_reference_render_size = Vector2(
		animation_reference_frame_size.x * ANIMATION_REFERENCE_SCALE.x,
		animation_reference_frame_size.y * ANIMATION_REFERENCE_SCALE.y
	)
	return animation_reference_render_size


func _load_visual_idle_frame_size(visual_id: String) -> Vector2:
	var path := "res://assets/sprites_personajes/%s/idle_%s.png" % [visual_id, visual_id]
	if not FileAccess.file_exists(path):
		return Vector2.ZERO

	var texture := load(path) as Texture2D
	if texture == null:
		return Vector2.ZERO

	var frame_width := int(floor(float(texture.get_width()) / float(ANIMATION_FRAME_COLUMNS)))
	if frame_width <= 0:
		return Vector2.ZERO
	return Vector2(frame_width, texture.get_height())


func _setup_single_status_bars() -> void:
	if player_status_bar == null:
		player_status_bar = CHARACTER_STATUS_BAR_SCRIPT.new()
		player_status_bar.position = player_sprite.position + Vector2(-88, 80)
		add_child(player_status_bar)

	if enemy_status_bar == null:
		enemy_status_bar = CHARACTER_STATUS_BAR_SCRIPT.new()
		enemy_status_bar.position = enemy_sprite.position + Vector2(-88, 80)
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
