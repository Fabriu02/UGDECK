extends Resource
class_name CardData

@export var card_name: String = ""
@export var cost: int = 0
@export var card_type: String = ""
@export var value: int = 0
@export_multiline var description: String = ""
@export var effect_id: String = ""
@export var rareza: String = ""
@export var image_path: String = ""
@export_multiline var raw_effect_text: String = ""
@export var enemy_archetypes: Array[String] = []


func setup(
	new_name: String,
	new_cost: int,
	new_type: String,
	new_value: int,
	new_description: String,
	new_effect_id: String = "",
	new_rareza: String = "",
	new_raw_effect_text: String = "",
	new_image_path: String = "",
	new_enemy_archetypes: Array[String] = []
) -> CardData:
	card_name = new_name
	cost = new_cost
	card_type = new_type
	value = new_value
	description = new_description
	effect_id = new_effect_id
	rareza = new_rareza
	raw_effect_text = new_raw_effect_text
	image_path = new_image_path
	enemy_archetypes = new_enemy_archetypes.duplicate()
	return self
