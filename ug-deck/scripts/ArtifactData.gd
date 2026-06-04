extends Resource
class_name ArtifactData

@export var artifact_name: String = ""
@export var artifact_type: String = ""
@export var effect_id: String = ""
@export var price: int = 0
@export var effect_value: int = 0
@export var locker_gold: int = 0
@export var description: String = ""
@export var icon_path: String = ""


func setup(
	new_name: String,
	new_type: String,
	new_effect_id: String,
	new_price: int,
	new_effect_value: int,
	new_locker_gold: int,
	new_description: String,
	new_icon_path: String
) -> ArtifactData:
	artifact_name = new_name
	artifact_type = new_type
	effect_id = new_effect_id
	price = new_price
	effect_value = new_effect_value
	locker_gold = new_locker_gold
	description = new_description
	icon_path = new_icon_path
	return self


func to_info_dictionary() -> Dictionary:
	return {
		"tipo": artifact_type,
		"efecto": effect_id,
		"valor": effect_value,
		"precio": price,
		"plata_casillero": locker_gold,
		"descripcion": description,
		"icono": icon_path,
	}
