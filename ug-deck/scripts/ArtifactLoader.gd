extends RefCounted
class_name ArtifactLoader

const ArtifactDataScript := preload("res://scripts/ArtifactData.gd")
const CSV_FILE_NAME := "Cartas iniciales.xlsx -  Artilugios (1).csv"
const ICONS_DIR := "res://assets/iconos"
const FALLBACK_ICON_PATH := "res://assets/iconos/Sorpresa.png"
const SHOP_ARTIFACT_COUNT := 3


static func load_artifacts() -> Array[ArtifactData]:
	var csv_path: String = _resolve_csv_path()
	var artifacts: Array[ArtifactData] = []

	if csv_path.is_empty() or not FileAccess.file_exists(csv_path):
		push_warning("ArtifactLoader: no existe el CSV de artilugios en %s" % csv_path)
		return artifacts

	var file: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_warning("ArtifactLoader: no se pudo abrir el CSV de artilugios.")
		return artifacts

	var headers: Dictionary = {}
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue

		if headers.is_empty():
			if _is_header_row(row):
				headers = _build_header_map(row)
			continue

		if _is_stop_row(row, headers):
			break

		var artifact: ArtifactData = _parse_row(row, headers)
		if artifact != null:
			artifacts.append(artifact)

	print("DEBUG ArtifactLoader: cargados %d artilugios desde %s" % [artifacts.size(), csv_path])
	return artifacts


static func load_info_artilugios() -> Dictionary:
	var info: Dictionary = {}
	for artifact: ArtifactData in load_artifacts():
		info[artifact.artifact_name] = artifact.to_info_dictionary()
	return info


static func load_shop_options(amount: int = SHOP_ARTIFACT_COUNT, owned_artifacts: Array[String] = []) -> Array[ArtifactData]:
	var candidates: Array[ArtifactData] = []
	for artifact: ArtifactData in load_artifacts():
		if artifact.price <= 0:
			continue
		if owned_artifacts.has(artifact.artifact_name):
			continue
		candidates.append(artifact)

	if candidates.is_empty():
		for artifact: ArtifactData in load_artifacts():
			if artifact.price > 0:
				candidates.append(artifact)

	candidates.shuffle()
	var selected: Array[ArtifactData] = []
	for artifact: ArtifactData in candidates:
		if selected.size() >= amount:
			break
		selected.append(artifact)
	return selected


static func load_locker_reward(owned_artifacts: Array[String] = []) -> ArtifactData:
	var candidates: Array[ArtifactData] = []
	for artifact: ArtifactData in load_artifacts():
		if owned_artifacts.has(artifact.artifact_name):
			continue
		candidates.append(artifact)

	if candidates.is_empty():
		candidates = load_artifacts()

	if candidates.is_empty():
		return null

	return candidates.pick_random()


static func _resolve_csv_path() -> String:
	return "res://data/".path_join(CSV_FILE_NAME)


static func _is_header_row(row: PackedStringArray) -> bool:
	var normalized_cells: Array[String] = []
	for cell: String in row:
		normalized_cells.append(_normalize_text(cell))
	return normalized_cells.has("nombre") and normalized_cells.has("tipo") and normalized_cells.has("efecto")


static func _build_header_map(row: PackedStringArray) -> Dictionary:
	var headers: Dictionary = {}
	for index: int in range(row.size()):
		var header: String = _normalize_text(row[index])
		if not header.is_empty():
			headers[header] = index
	return headers


static func _parse_row(row: PackedStringArray, headers: Dictionary) -> ArtifactData:
	var raw_name: String = _get_cell(row, headers, "nombre")
	if raw_name.is_empty():
		return null

	var artifact_type: String = _normalize_effect_id(_get_cell(row, headers, "tipo"))
	var effect_id: String = _normalize_effect_id(_get_cell(row, headers, "efecto"))
	var raw_value: int = _parse_int(_get_cell(row, headers, "valor"), 0)
	var description: String = _get_cell(row, headers, "descripcion")
	var icon_name: String = _get_cell(row, headers, "nombre_icono_png")
	var effect_value: int = _get_effect_value(effect_id, description, raw_value)
	var price: int = _get_price(effect_id, raw_value, effect_value)

	if artifact_type.is_empty() or effect_id.is_empty() or description.is_empty():
		return null

	return ArtifactDataScript.new().setup(
		raw_name.strip_edges(),
		artifact_type,
		effect_id,
		price,
		effect_value,
		_get_locker_gold(price),
		description,
		_resolve_icon_path(icon_name)
	)


static func _is_stop_row(row: PackedStringArray, headers: Dictionary) -> bool:
	return _normalize_text(_get_cell(row, headers, "nombre")) == "ya estan"


static func _get_cell(row: PackedStringArray, headers: Dictionary, header_name: String) -> String:
	if not headers.has(header_name):
		return ""

	var index: int = int(headers[header_name])
	if index < 0 or index >= row.size():
		return ""

	return row[index].strip_edges()


static func _get_effect_value(effect_id: String, description: String, fallback_value: int) -> int:
	var normalized_description: String = _normalize_text(description)
	match effect_id:
		"inmunidad_cansancio":
			return maxi(_extract_first_number(normalized_description), 3)
		"escudo_por_robo":
			return maxi(_extract_first_number(normalized_description), 2)
		"hp_max":
			return maxi(_extract_first_number(normalized_description), 10)
		"costo_cero":
			return 1
		"curacion_fija":
			return maxi(_extract_first_number(normalized_description), 3)
		"aplicar_buff":
			return 2
		"inmunidad_distraccion":
			return 1
		"robar_extra":
			return maxi(_extract_first_number(normalized_description), 2)
		"energia_max":
			return maxi(_extract_first_number(normalized_description), 1)
		"energia_extra":
			return maxi(_extract_first_number(normalized_description), 2)
		"inmunidad_panico":
			return 1
		"robar_al_defender":
			return maxi(_extract_first_number(normalized_description), 1)
		"revivir":
			return maxi(_extract_first_number(normalized_description), 10)
		"limpiar_debuff":
			return maxi(_extract_first_number(normalized_description), 3)
		"plata_extra":
			return maxi(_extract_first_number(normalized_description), 10)
		"oro_inicial":
			return 80
		"copiar_carta":
			return 1
		"dano_extra":
			return maxi(_extract_first_number(normalized_description), 2)
		"escudo_inicial":
			return maxi(_extract_first_number(normalized_description), fallback_value)
		_:
			return maxi(_extract_first_number(normalized_description), fallback_value)


static func _get_price(effect_id: String, raw_value: int, effect_value: int) -> int:
	if raw_value > 20:
		return raw_value

	match effect_id:
		"dano_extra":
			return 190
		"escudo_inicial":
			return 70 + effect_value * 3
		"copiar_carta":
			return 200
		"costo_cero":
			return 200
		"energia_max":
			return 130
		"hp_max":
			return 100
		_:
			return max(raw_value, 60)


static func _get_locker_gold(price: int) -> int:
	return clampi(int(round(float(price) * 0.25)), 15, 75)


static func _resolve_icon_path(icon_name: String) -> String:
	var normalized_icon: String = _normalize_icon_name(icon_name)
	if normalized_icon.is_empty():
		return FALLBACK_ICON_PATH

	var aliases: Dictionary = {
		"coffe_mug": "coffee-mug",
		"coffe-mug": "coffee-mug",
		"thermometer": "thermometer-cold",
	}
	if aliases.has(normalized_icon):
		normalized_icon = String(aliases[normalized_icon])

	var candidates: Array[String] = [
		normalized_icon,
		normalized_icon.replace("_", "-"),
		normalized_icon.replace("-", "_"),
	]

	for candidate: String in candidates:
		var path: String = ICONS_DIR.path_join("%s.png" % candidate)
		if ResourceLoader.exists(path):
			return path

	return FALLBACK_ICON_PATH


static func _normalize_icon_name(value: String) -> String:
	var normalized: String = _normalize_text(value)
	normalized = normalized.replace(" ", "_")
	while normalized.contains("__"):
		normalized = normalized.replace("__", "_")
	return normalized.strip_edges()


static func _normalize_effect_id(value: String) -> String:
	return _normalize_text(value).replace(" ", "_").replace("-", "_")


static func _parse_int(value: String, fallback: int) -> int:
	var cleaned: String = value.strip_edges()
	if cleaned.is_valid_int():
		return cleaned.to_int()
	return fallback


static func _extract_first_number(text: String) -> int:
	var regex := RegEx.new()
	if regex.compile("\\d+") != OK:
		return 0

	var result: RegExMatch = regex.search(text)
	if result == null:
		return 0

	return result.get_string().to_int()


static func _normalize_text(value: String) -> String:
	var normalized: String = value.to_lower().strip_edges()
	var replacements: Dictionary = {
		"Ã¡": "a",
		"Ã©": "e",
		"Ã­": "i",
		"Ã³": "o",
		"Ãº": "u",
		"Ã±": "n",
		"Ã‘": "n",
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ñ": "n",
		"\"": "",
	}

	for key: String in replacements.keys():
		normalized = normalized.replace(key, String(replacements[key]))

	return normalized
