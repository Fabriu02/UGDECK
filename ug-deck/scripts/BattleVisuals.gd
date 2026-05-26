extends Node2D
class_name BattleVisuals

const PLAYER_IMAGE_PATH := "res://assets/characters/protagonista mejorado.png"
const ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"
const DEFAULT_ENEMY_SCALE := Vector2(0.7, 0.7)

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_placeholder: Label = $PlayerPlaceholder
@onready var enemy_placeholder: Label = $EnemyPlaceholder
@onready var player_anim_player: AnimationPlayer = $PlayerSprite/AnimationPlayer

var multi_enemy_labels: Array[Label] = []
var multi_enemy_sprites: Array[Sprite2D] = []
var multi_enemy_max_hps: Array[int] = []


func _ready() -> void:
	_try_load_texture(PLAYER_IMAGE_PATH, player_sprite, player_placeholder)
	_try_load_texture(ENEMY_IMAGE_PATH, enemy_sprite, enemy_placeholder)

	if player_anim_player.has_animation("idle"):
		player_anim_player.play("idle")


func set_enemy_image(path: String, sprite_scale: Vector2 = DEFAULT_ENEMY_SCALE) -> void:
	clear_multi_enemy_visuals()
	enemy_sprite.scale = sprite_scale
	_try_load_texture(path, enemy_sprite, enemy_placeholder)


func set_enemy_display_name(display_name: String) -> void:
	enemy_placeholder.text = display_name


func show_multi_enemy_group(image_paths: Variant, names: Array, hps: Array, max_hps: Array = [], sprite_scales: Array = []) -> void:
	clear_multi_enemy_visuals()
	enemy_sprite.visible = false
	enemy_placeholder.visible = false

	multi_enemy_max_hps.clear()
	for index in range(names.size()):
		var image_path := _get_multi_enemy_image_path(image_paths, index)
		var texture := load(image_path) as Texture2D
		var max_hp := int(max_hps[index]) if index < max_hps.size() else int(hps[index])
		multi_enemy_max_hps.append(max_hp)

		if texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(735 + index * 105, 245)
			sprite.scale = _get_multi_enemy_sprite_scale(sprite_scales, index)
			add_child(sprite)
			multi_enemy_sprites.append(sprite)

		var label := Label.new()
		label.text = "%s\n%d/%d" % [names[index], hps[index], max_hp]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(680 + index * 105, 115)
		label.size = Vector2(110, 52)
		add_child(label)
		multi_enemy_labels.append(label)


func update_multi_enemy_labels(hps: Array, max_hps: Array = []) -> void:
	for index in range(min(multi_enemy_labels.size(), hps.size())):
		var label := multi_enemy_labels[index]
		var current_name := label.text.split("\n")[0]
		var max_hp := _get_multi_enemy_max_hp(index, hps, max_hps)
		label.text = "%s\n%d/%d" % [current_name, hps[index], max_hp]
		label.modulate = Color(0.45, 0.45, 0.45, 1.0) if hps[index] <= 0 else Color.WHITE
		if index < multi_enemy_sprites.size():
			multi_enemy_sprites[index].modulate = Color(0.35, 0.35, 0.35, 0.7) if hps[index] <= 0 else Color.WHITE


func clear_multi_enemy_visuals() -> void:
	for label in multi_enemy_labels:
		if is_instance_valid(label):
			label.queue_free()
	multi_enemy_labels.clear()

	for sprite in multi_enemy_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	multi_enemy_sprites.clear()
	multi_enemy_max_hps.clear()


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
