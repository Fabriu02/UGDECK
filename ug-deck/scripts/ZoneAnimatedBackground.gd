extends Sprite2D
class_name ZoneAnimatedBackground

const ZONE_SPRITE_BASE_PATH := "res://assets/backgrounds/sprites zonas"

@export var frame_duration: float = 0.12
@export var min_zone_number: int = 1
@export var max_zone_number: int = 4

var frames: Array[Texture2D] = []
var frame_time: float = 0.0
var frame_index: int = 0


func _ready() -> void:
	centered = false
	position = Vector2.ZERO
	_load_current_zone_frames()
	set_process(not frames.is_empty())


func _process(delta: float) -> void:
	if frames.is_empty():
		return

	frame_time += delta
	if frame_time < frame_duration:
		return

	frame_time = fmod(frame_time, frame_duration)
	frame_index = (frame_index + 1) % frames.size()
	_apply_frame(frame_index)


func _load_current_zone_frames() -> void:
	var zone_number: int = clampi(GameState.get_current_zone_index(), min_zone_number, max_zone_number)
	frames = _load_zone_animation_frames(zone_number)
	frame_index = 0
	frame_time = 0.0

	if frames.is_empty():
		return

	_apply_frame(frame_index)


func _apply_frame(index: int) -> void:
	texture = frames[index]
	_fit_to_viewport()


func _fit_to_viewport() -> void:
	if texture == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var texture_size: Vector2 = texture.get_size()
	if viewport_size == Vector2.ZERO or texture_size == Vector2.ZERO:
		return

	var fit_scale: float = maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	scale = Vector2(fit_scale, fit_scale)
	position = Vector2.ZERO


func _load_zone_animation_frames(zone_number: int) -> Array[Texture2D]:
	var loaded_frames: Array[Texture2D] = []
	var zone_path: String = "%s/zona %d" % [ZONE_SPRITE_BASE_PATH, zone_number]
	var dir: DirAccess = DirAccess.open(zone_path)
	if dir == null:
		push_warning("No se encontro la carpeta de sprites para zona %d: %s" % [zone_number, zone_path])
		return loaded_frames

	var frame_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			frame_paths.append(zone_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	frame_paths.sort_custom(_compare_frame_paths)
	for frame_path in frame_paths:
		var texture_resource: Resource = load(frame_path)
		if texture_resource is Texture2D:
			loaded_frames.append(texture_resource as Texture2D)

	return loaded_frames


func _compare_frame_paths(a: String, b: String) -> bool:
	return _get_sprite_number(a) < _get_sprite_number(b)


func _get_sprite_number(path: String) -> int:
	var base_name: String = path.get_file().get_basename()
	var sprite_marker_position: int = base_name.find("sprite")
	if sprite_marker_position == -1:
		return 0

	var number_text: String = base_name.substr(sprite_marker_position + "sprite".length()).strip_edges()
	return number_text.to_int()