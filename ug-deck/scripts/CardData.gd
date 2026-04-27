extends Resource
class_name CardData

@export var card_name: String = ""
@export var cost: int = 0
@export var card_type: String = ""
@export var value: int = 0
@export_multiline var description: String = ""
@export var effect_id: String = ""


func setup(
	new_name: String,
	new_cost: int,
	new_type: String,
	new_value: int,
	new_description: String,
	new_effect_id: String = ""
) -> CardData:
	card_name = new_name
	cost = new_cost
	card_type = new_type
	value = new_value
	description = new_description
	effect_id = new_effect_id
	return self
