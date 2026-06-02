extends RefCounted
class_name StatusEffectInfo

const HEART_ICON_PATH := "res://assets/iconos/hearts.png"
const HEART_ICON_FALLBACK_PATH := "res://assets/iconos/hearts (1).png"
const SHIELD_ICON_PATH := "res://assets/iconos/shield.png"
const SHIELD_ICON_FALLBACK_PATH := "res://assets/iconos/shield (1).png"
const COINS_ICON_PATH := "res://assets/iconos/two-coins.png"
const ENERGY_ICON_PATH := "res://assets/iconos/batteries.png"

const DESCRIPTIONS := {
	"estres": {
		"title": "Estres",
		"description": "Reduce el dano de tus ataques y aumenta el dano que recibis.",
	},
	"distraccion": {
		"title": "Distraccion",
		"description": "Roba menos cartas o reduce acciones defensivas, segun el efecto que lo aplico.",
	},
	"confusion": {
		"title": "Confusion",
		"description": "Reduce la cantidad de cartas que robas.",
	},
	"panico": {
		"title": "Panico",
		"description": "Aumenta el coste de la proxima primera carta del turno.",
	},
	"cansancio": {
		"title": "Cansancio",
		"description": "Reduce tu energia al inicio del turno y baja la curacion recibida.",
	},
	"debil": {
		"title": "Debil",
		"description": "Reduce el dano de los ataques.",
	},
	"vulnerable": {
		"title": "Vulnerable",
		"description": "Recibe mas dano de los ataques.",
	},
	"bibliografia_extra": {
		"title": "Bibliografia extra",
		"description": "Roba menos cartas y las habilidades cuestan mas energia.",
	},
	"trabajo_practico_obligatorio": {
		"title": "Trabajo practico",
		"description": "La primera carta del turno cuesta mas energia.",
	},
	"defensa_menos": {
		"title": "Defensa reducida",
		"description": "Las cartas defensivas otorgan menos escudo.",
	},
	"habilidad_mas": {
		"title": "Habilidades caras",
		"description": "Las habilidades cuestan mas energia.",
	},
	"final_promocionado": {
		"title": "Final promocionado",
		"description": "Tus cartas cuestan menos energia mientras dure el efecto.",
	},
	"bonus_defensa_temporal": {
		"title": "Bonus de defensa",
		"description": "Aumenta el escudo ganado por cartas defensivas.",
	},
	"ataque_bonus": {
		"title": "Ataque aumentado",
		"description": "Aumenta el dano de tus ataques temporalmente.",
	},
	"defensa_bonus": {
		"title": "Defensa aumentada",
		"description": "Aumenta el escudo ganado temporalmente.",
	},
	"aprobado_con_4": {
		"title": "Aprobado con 4",
		"description": "Evita caer derrotado y deja la vida en 4 si se activa.",
	},
	"inmunidad": {
		"title": "Inmunidad",
		"description": "Ignora el proximo ataque enemigo mientras dure el efecto.",
	},
	"ataque_menos": {
		"title": "Ataque reducido",
		"description": "Reduce el dano de los ataques.",
	},
	"ataque_permanente": {
		"title": "Ataque permanente",
		"description": "Aumenta el dano de los ataques durante todo el combate.",
	},
}


static func get_icon_path(kind: String) -> String:
	match kind:
		"heart":
			return _first_existing_path(HEART_ICON_PATH, HEART_ICON_FALLBACK_PATH)
		"shield":
			return _first_existing_path(SHIELD_ICON_PATH, SHIELD_ICON_FALLBACK_PATH)
		"coins":
			return COINS_ICON_PATH
		"energy":
			return ENERGY_ICON_PATH
		_:
			return ""


static func get_icon_texture(kind: String) -> Texture2D:
	var path := get_icon_path(kind)
	if path.is_empty():
		return null
	return load(path) as Texture2D


static func get_state_id(state: Dictionary) -> String:
	return String(state.get("nombre", state.get("id", "")))


static func get_title(state: Dictionary) -> String:
	var state_id := get_state_id(state)
	var info: Dictionary = DESCRIPTIONS.get(state_id, {})
	return String(info.get("title", _title_from_id(state_id)))


static func get_description(state: Dictionary) -> String:
	var state_id := get_state_id(state)
	var info: Dictionary = DESCRIPTIONS.get(state_id, {})
	return String(info.get("description", "Estado activo del combate."))


static func get_chip_text(state: Dictionary) -> String:
	var title := get_title(state)
	var value: int = int(state.get("valor", 0))
	var duration: int = int(state.get("duracion", 0))

	if value > 0:
		return "%s +%d" % [title, value]
	if value < 0:
		return "%s %d" % [title, value]
	if duration > 1:
		return "%s x%d" % [title, duration]
	return title


static func get_meta_text(state: Dictionary) -> String:
	var parts: Array[String] = []
	var value: int = int(state.get("valor", 0))
	var duration: int = int(state.get("duracion", 0))
	var stacks: int = int(state.get("stacks", 0))

	if value != 0:
		parts.append("Valor: %d" % value)
	if stacks > 0:
		parts.append("Acumulaciones: %d" % stacks)
	if duration > 0:
		parts.append("Duracion: %d turno%s" % [duration, "" if duration == 1 else "s"])

	return " | ".join(parts)


static func make_state(id: String, value: int = 0, duration: int = 0) -> Dictionary:
	return {
		"nombre": id,
		"valor": value,
		"duracion": duration,
	}


static func merge_states(states: Array) -> Array:
	var merged := {}
	var order: Array[String] = []

	for raw_state in states:
		if not (raw_state is Dictionary):
			continue
		var state := raw_state as Dictionary
		var state_id := get_state_id(state)
		if state_id.is_empty():
			continue

		if not merged.has(state_id):
			merged[state_id] = {
				"nombre": state_id,
				"valor": int(state.get("valor", 0)),
				"duracion": int(state.get("duracion", 0)),
				"stacks": 1,
			}
			order.append(state_id)
		else:
			merged[state_id]["valor"] = int(merged[state_id].get("valor", 0)) + int(state.get("valor", 0))
			merged[state_id]["duracion"] = max(int(merged[state_id].get("duracion", 0)), int(state.get("duracion", 0)))
			merged[state_id]["stacks"] = int(merged[state_id].get("stacks", 1)) + 1

	var result: Array = []
	for state_id in order:
		result.append(merged[state_id])
	return result


static func _first_existing_path(primary: String, fallback: String) -> String:
	if ResourceLoader.exists(primary) or FileAccess.file_exists(primary):
		return primary
	if ResourceLoader.exists(fallback) or FileAccess.file_exists(fallback):
		return fallback
	return primary


static func _title_from_id(state_id: String) -> String:
	var title := state_id.replace("_", " ")
	if title.is_empty():
		return "Estado"
	return title.capitalize()
