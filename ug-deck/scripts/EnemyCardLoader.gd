extends RefCounted
class_name EnemyCardLoader

const CSV_FILE_NAME := "Cartas iniciales.xlsx - CARTAS PROFES.csv"
const REQUIRED_COLUMNS := [
	"nombre de la carta",
	"tipo",
	"coste energia",
	"efecto",
	"descripcion",
	"rareza",
]


static func load_professor_cards() -> Array[CardData]:
	return load_cards_from_csv(CSV_FILE_NAME)


static func load_cards_from_csv(csv_file_name: String) -> Array[CardData]:
	var csv_path := _resolve_csv_path(csv_file_name)
	var cards: Array[CardData] = []

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
			cards.append(card)

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
	var cost := _parse_int(_get_cell(row, headers, "coste energia"), 0)

	if card_type.is_empty() and effect_text.is_empty():
		return null

	return CardData.new().setup(
		card_name,
		cost,
		_normalize_card_type(card_type),
		0,
		description,
		_build_effect_id(card_name),
		rareza,
		effect_text
	)


static func _get_cell(row: PackedStringArray, headers: Dictionary, header_name: String) -> String:
	if not headers.has(header_name):
		return ""

	var index: int = headers[header_name]
	if index < 0 or index >= row.size():
		return ""

	return row[index].strip_edges()


static func _parse_int(value: String, fallback: int) -> int:
	var cleaned := value.strip_edges()
	if cleaned.is_valid_int():
		return cleaned.to_int()
	return fallback


static func _normalize_card_type(value: String) -> String:
	return _normalize_text(value).replace("/", "_")


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
		"Ã¡": "a",
		"é": "e",
		"Ã©": "e",
		"í": "i",
		"Ã­": "i",
		"ó": "o",
		"Ã³": "o",
		"ú": "u",
		"Ãº": "u",
		"ä": "a",
		"Ã¤": "a",
		"ë": "e",
		"Ã«": "e",
		"ï": "i",
		"Ã¯": "i",
		"ö": "o",
		"Ã¶": "o",
		"ü": "u",
		"Ã¼": "u",
		"à": "a",
		"Ã ": "a",
		"è": "e",
		"Ã¨": "e",
		"ì": "i",
		"Ã¬": "i",
		"ò": "o",
		"Ã²": "o",
		"ù": "u",
		"Ã¹": "u",
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
