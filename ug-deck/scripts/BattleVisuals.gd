extends Node2D
class_name BattleVisuals

const PLAYER_IMAGE_PATH := "res://assets/characters/protagonista mejorado.png"
const ENEMY_IMAGE_PATH := "res://assets/characters/enemigo 1 mejorado.png"

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_placeholder: Label = $PlayerPlaceholder
@onready var enemy_placeholder: Label = $EnemyPlaceholder
@onready var player_anim_player: AnimationPlayer = $PlayerSprite/AnimationPlayer


func _ready() -> void:
	_try_load_texture(PLAYER_IMAGE_PATH, player_sprite, player_placeholder)
	_try_load_texture(ENEMY_IMAGE_PATH, enemy_sprite, enemy_placeholder)

	if player_anim_player.has_animation("idle"):
		player_anim_player.play("idle")


func set_enemy_image(path: String) -> void:
	_try_load_texture(path, enemy_sprite, enemy_placeholder)


func set_enemy_display_name(display_name: String) -> void:
	enemy_placeholder.text = display_name


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
