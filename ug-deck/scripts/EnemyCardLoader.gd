extends RefCounted
class_name EnemyCardLoader

const CSV_FILE_NAME := "Cartas iniciales.xlsx - CARTAS PROFES.csv"
const PROFESSOR_CARD_COUNT := 20
const REQUIRED_COLUMNS := [
	"nombre de la carta",
	"tipo",
	"coste energia",
	"efecto",
	"descripcion",
	"rareza",
]


static func load_professor_cards() -> Array[CardData]:
	return load_cards_from_csv(CSV_FILE_NAME, 0, PROFESSOR_CARD_COUNT)


static func load_second_professor_cards() -> Array[CardData]:
	return load_cards_from_csv(CSV_FILE_NAME, PROFESSOR_CARD_COUNT, PROFESSOR_CARD_COUNT)


static func load_professor_cards_by_rarity(rarity: String) -> Array[CardData]:
	var matching_cards: Array[CardData] = []
	for card in load_cards_from_csv(CSV_FILE_NAME):
		if card.rareza == rarity:
			matching_cards.append(card)

	print("DEBUG EnemyCardLoader: cartas de profesor rareza %s: %d" % [rarity, matching_cards.size()])
	return matching_cards


static func load_professor_cards_by_rarity_and_archetype(rarity: String, enemy_archetype: String) -> Array[CardData]:
	return load_professor_cards_by_rarity_and_archetypes(rarity, [enemy_archetype])


static func load_professor_cards_by_rarity_and_archetypes(rarity: String, enemy_archetypes: Array) -> Array[CardData]:
	return _filter_cards_by_enemy_archetypes(load_professor_cards_by_rarity(rarity), enemy_archetypes)


static func load_professor_cards_by_rarities(rarities: Array) -> Array[CardData]:
	var matching_cards: Array[CardData] = []
	for card in load_cards_from_csv(CSV_FILE_NAME):
		if rarities.has(card.rareza):
			matching_cards.append(card)

	print("DEBUG EnemyCardLoader: cartas de profesor rarezas %s: %d" % [", ".join(rarities), matching_cards.size()])
	return matching_cards


static func load_professor_cards_by_rarities_and_archetype(rarities: Array, enemy_archetype: String) -> Array[CardData]:
	return load_professor_cards_by_rarities_and_archetypes(rarities, [enemy_archetype])


static func load_professor_cards_by_rarities_and_archetypes(rarities: Array, enemy_archetypes: Array) -> Array[CardData]:
	return _filter_cards_by_enemy_archetypes(load_professor_cards_by_rarities(rarities), enemy_archetypes)


static func load_cards_from_csv(csv_file_name: String, start_index: int = 0, max_cards: int = -1) -> Array[CardData]:
	var csv_path := _resolve_csv_path(csv_file_name)
	var cards: Array[CardData] = []
	var parsed_cards := 0

	if csv_path.is_empty():
		print("WARNING EnemyCardLoader: no se pudo resolver la ruta del CSV de cartas.")
		return cards

	if not FileAccess.file_exists(csv_path):
		print("WARNING EnemyCardLoader: no existe el CSV de cartas en %s" % csv_path)
		return cards

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		print("WARNING EnemyCardLoader: no se pudo abrir el CSV de cartas.")
		return cards

	var headers: Dictionary = {}
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue

		if headers.is_empty():
			if _is_header_row(row):
				headers = _build_header_map(row)
			continue

		var card := _parse_row(row, headers)
		if card != null:
			if parsed_cards >= start_index and (max_cards < 0 or cards.size() < max_cards):
				cards.append(card)
			parsed_cards += 1

	print("DEBUG EnemyCardLoader: cargadas %d cartas desde %s" % [cards.size(), csv_path])
	return cards


static func load_professor_cards_legacy() -> Array[CardData]:
	var csv_path := _resolve_csv_path()
	var cards: Array[CardData] = []

	if csv_path.is_empty():
		print("WARNING EnemyCardLoader: no se pudo resolver la ruta del CSV de profesores.")
		return cards

	if not FileAccess.file_exists(csv_path):
		print("WARNING EnemyCardLoader: no existe el CSV de profesores en %s" % csv_path)
		return cards

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		print("WARNING EnemyCardLoader: no se pudo abrir el CSV de profesores.")
		return cards

	var headers: Dictionary = {}
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue

		if headers.is_empty():
			if _is_header_row(row):
				headers = _build_header_map(row)
			continue

		var card := _parse_row(row, headers)
		if card != null:
			cards.append(card)

	print("DEBUG EnemyCardLoader: cargadas %d cartas de profesores desde %s" % [cards.size(), csv_path])
	return cards


static func _resolve_csv_path(csv_file_name: String = CSV_FILE_NAME) -> String:
	var project_root := ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	return project_root.path_join("scripts").path_join(csv_file_name)


static func _is_header_row(row: PackedStringArray) -> bool:
	var normalized_cells: Array[String] = []
	for cell in row:
		normalized_cells.append(_normalize_text(cell))

	return normalized_cells.has("nombre de la carta") and normalized_cells.has("tipo")


static func _build_header_map(row: PackedStringArray) -> Dictionary:
	var headers := {}
	for index in range(row.size()):
		headers[_normalize_text(row[index])] = index
	return headers


static func _parse_row(row: PackedStringArray, headers: Dictionary) -> CardData:
	for required_column in REQUIRED_COLUMNS:
		if not headers.has(required_column):
			print("WARNING EnemyCardLoader: falta la columna requerida '%s' en el CSV." % required_column)
			return null

	var card_name := _get_cell(row, headers, "nombre de la carta")
	if card_name.is_empty():
		return null

	var card_type := _get_cell(row, headers, "tipo")
	var effect_text := _get_cell(row, headers, "efecto")
	var description := _get_cell(row, headers, "descripcion")
	var rareza := _get_cell(row, headers, "rareza")
	var enemy_archetypes := _parse_enemy_archetypes(_get_cell(row, headers, "arquetipo enemigo"))
	var image_path := _get_card_image_path(row, headers)
	var cost := _parse_int(_get_cell(row, headers, "coste energia"), 0)
	var normalized_type := _normalize_card_type(card_type)

	if card_type.is_empty() and effect_text.is_empty():
		return null

	return CardData.new().setup(
		card_name,
		cost,
		normalized_type,
		_extract_primary_value(normalized_type, effect_text),
		description,
		_build_effect_id(card_name),
		rareza,
		effect_text,
		image_path,
		enemy_archetypes
	)


static func _get_card_image_path(row: PackedStringArray, headers: Dictionary) -> String:
	var image_path := _get_cell(row, headers, "imagen")
	if image_path.is_empty():
		image_path = _get_cell(row, headers, "sprite")
	return image_path


static func _get_cell(row: PackedStringArray, headers: Dictionary, header_name: String) -> String:
	if not headers.has(header_name):
		return ""

	var index: int = headers[header_name]
	if index < 0 or index >= row.size():
		return ""

	return row[index].strip_edges()


static func _parse_enemy_archetypes(value: String) -> Array[String]:
	var parsed_archetypes: Array[String] = []
	for archetype in value.split("/"):
		var normalized_archetype := _normalize_text(archetype)
		if not normalized_archetype.is_empty():
			parsed_archetypes.append(normalized_archetype)
	return parsed_archetypes


static func card_matches_enemy_archetype(card: CardData, enemy_archetype: String) -> bool:
	var normalized_archetype := _normalize_text(enemy_archetype)
	if normalized_archetype.is_empty():
		return true
	if card.enemy_archetypes.is_empty():
		return false

	return card.enemy_archetypes.has(normalized_archetype)


static func _filter_cards_by_enemy_archetype(cards: Array[CardData], enemy_archetype: String) -> Array[CardData]:
	return _filter_cards_by_enemy_archetypes(cards, [enemy_archetype])


static func _filter_cards_by_enemy_archetypes(cards: Array[CardData], enemy_archetypes: Array) -> Array[CardData]:
	var normalized_archetypes: Array[String] = []
	for enemy_archetype in enemy_archetypes:
		var normalized_archetype := _normalize_text(String(enemy_archetype))
		if not normalized_archetype.is_empty() and not normalized_archetypes.has(normalized_archetype):
			normalized_archetypes.append(normalized_archetype)

	if normalized_archetypes.is_empty():
		return cards

	var matching_cards: Array[CardData] = []
	for card in cards:
		for normalized_archetype in normalized_archetypes:
			if card_matches_enemy_archetype(card, normalized_archetype):
				matching_cards.append(card)
				break

	if matching_cards.is_empty():
		push_warning("EnemyCardLoader: no se encontraron cartas para los arquetipos enemigos '%s'. Se usa fallback por rareza/zona." % ", ".join(normalized_archetypes))
		return cards

	print("DEBUG EnemyCardLoader: cartas para arquetipos %s: %d/%d" % [", ".join(normalized_archetypes), matching_cards.size(), cards.size()])
	return matching_cards

static func _parse_int(value: String, fallback: int) -> int:
	var cleaned := value.strip_edges()
	if cleaned.is_valid_int():
		return cleaned.to_int()
	return fallback


static func _normalize_card_type(value: String) -> String:
	return _normalize_text(value).replace("/", "_")


static func _extract_primary_value(card_type: String, effect_text: String) -> int:
	var normalized_effect := _normalize_text(effect_text)

	if card_type == "ataque":
		return _extract_number_after_any(normalized_effect, ["inflige", "inflinge"])
	if card_type == "defensa":
		return _extract_number_after_any(normalized_effect, ["gana", "ganas", "otorga"])
	if card_type == "curacion":
		return _extract_number_after_any(normalized_effect, ["recupera", "recuperas"])
	if card_type == "energia":
		return _extract_number_after_any(normalized_effect, ["gana", "ganas"])
	if card_type == "robo":
		return _extract_number_after_any(normalized_effect, ["roba", "robas"])
	if card_type == "descarte_control de mano":
		return _extract_number_after_any(normalized_effect, ["descarta", "descartas"])

	return _extract_first_number(normalized_effect)


static func _extract_number_after_any(text: String, keywords: Array[String]) -> int:
	for keyword in keywords:
		var number := _extract_number_after(text, keyword)
		if number > 0:
			return number
	return 0


static func _extract_number_after(text: String, keyword: String) -> int:
	var keyword_index := text.find(keyword)
	if keyword_index == -1:
		return 0

	return _extract_first_number(text.substr(keyword_index + keyword.length()))


static func _extract_first_number(text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+") != OK:
		return 0

	var result := regex.search(text)
	if result == null:
		return 0

	return result.get_string().to_int()


static func _build_effect_id(card_name: String) -> String:
	var normalized := _normalize_text(card_name)
	var sanitized := ""
	var allowed_characters := "abcdefghijklmnopqrstuvwxyz0123456789"

	for character in normalized:
		if allowed_characters.contains(character):
			sanitized += character
		elif character == " " or character == "-" or character == "/":
			sanitized += "_"

	while sanitized.find("__") != -1:
		sanitized = sanitized.replace("__", "_")

	sanitized = sanitized.strip_edges()
	while sanitized.begins_with("_"):
		sanitized = sanitized.substr(1)
	while sanitized.ends_with("_"):
		sanitized = sanitized.substr(0, sanitized.length() - 1)
	return sanitized


static func _normalize_text(value: String) -> String:
	var normalized := value.to_lower().strip_edges()
	var replacements := {
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ä": "a",
		"ë": "e",
		"ï": "i",
		"ö": "o",
		"ü": "u",
		"à": "a",
		"è": "e",
		"ì": "i",
		"ò": "o",
		"ù": "u",
		"ñ": "n",
		"Ã±": "n",
		"“": "",
		"â€œ": "",
		"”": "",
		"â€": "",
		"\"": "",
	}

	for key in replacements.keys():
		normalized = normalized.replace(key, replacements[key])

	return normalized
