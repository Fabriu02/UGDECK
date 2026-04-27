extends Node2D
class_name BattleVisuals

const PLAYER_IMAGE_PATH := "res://assets/characters/player-1.png"
const ENEMY_IMAGE_PATH := "res://assets/characters/enemy-manzur.png"

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_placeholder: Label = $PlayerPlaceholder
@onready var enemy_placeholder: Label = $EnemyPlaceholder


func _ready() -> void:
	_try_load_texture(PLAYER_IMAGE_PATH, player_sprite, player_placeholder)
	_try_load_texture(ENEMY_IMAGE_PATH, enemy_sprite, enemy_placeholder)


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
