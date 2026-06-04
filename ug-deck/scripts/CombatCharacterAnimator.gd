extends AnimatedSprite2D
class_name CombatCharacterAnimator

signal death_animation_finished

const SPRITES_ROOT := "res://assets/sprites_personajes"
const FRAME_COLUMNS := 5
const ANIMATION_SPEED_MULTIPLIER := 0.75
const ANIMATIONS := ["idle", "attack", "defend", "buff", "debuff", "hurt", "death"]
const ANIMATION_SETTINGS := {
	"idle": {"fps": 5.0, "loop": true},
	"attack": {"fps": 8.0, "loop": false},
	"defend": {"fps": 7.0, "loop": false},
	"buff": {"fps": 7.0, "loop": false},
	"debuff": {"fps": 7.0, "loop": false},
	"hurt": {"fps": 8.0, "loop": false},
	"death": {"fps": 6.0, "loop": false},
}
const FILE_PREFIXES := {
	"idle": ["idle"],
	"attack": ["attack", "atack"],
	"defend": ["defend"],
	"buff": ["buff"],
	"debuff": ["debuff"],
	"hurt": ["hurt"],
	"death": ["death"],
}
const EXPECTED_MISSING_ANIMATIONS := {
	"el_oni_fase_1": ["death"],
	"el_oni_fase_2": ["death"],
}

static var warned_messages := {}

var visual_id := ""
var loaded := false
var is_dead_visual := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_signal_connected()


func configure(new_visual_id: String) -> bool:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_signal_connected()
	visual_id = new_visual_id.strip_edges()
	is_dead_visual = false
	loaded = false
	sprite_frames = null
	visible = false

	if visual_id.is_empty():
		return false

	var frames := _build_sprite_frames(visual_id)
	if frames == null or not frames.has_animation("idle"):
		_warn_once("missing_idle_%s" % visual_id, "CombatCharacterAnimator: falta idle para '%s'. Se conserva el sprite estatico." % visual_id)
		return false

	sprite_frames = frames
	loaded = true
	visible = true
	play_idle()
	return true


func set_visual_variant(new_visual_id: String) -> bool:
	return configure(new_visual_id)


func play_idle() -> void:
	play_animation_safe("idle")


func play_attack() -> void:
	play_animation_safe("attack")


func play_defend() -> void:
	play_animation_safe("defend")


func play_buff() -> void:
	play_animation_safe("buff")


func play_debuff() -> void:
	play_animation_safe("debuff")


func play_hurt() -> void:
	play_animation_safe("hurt")


func play_death() -> void:
	if not loaded:
		death_animation_finished.emit()
		return

	is_dead_visual = true
	if has_animation_safe("death"):
		play("death")
		return

	_warn_once("missing_death_%s" % visual_id, "CombatCharacterAnimator: falta death para '%s'. Se deja el ultimo estado visual disponible." % visual_id)
	if has_animation_safe("hurt"):
		play("hurt")
	else:
		play_animation_safe("idle")
	death_animation_finished.emit()


func play_death_and_wait() -> void:
	if not loaded:
		return

	if not has_animation_safe("death"):
		play_death()
		return

	play_death()
	await death_animation_finished


func play_animation_safe(animation_name: String) -> void:
	if not loaded or sprite_frames == null:
		return

	var canonical_name := _canonical_animation_name(animation_name)
	if is_dead_visual and canonical_name != "death":
		return

	if not has_animation_safe(canonical_name):
		if canonical_name != "idle":
			_warn_once(
				"missing_%s_%s" % [canonical_name, visual_id],
				"CombatCharacterAnimator: falta animacion '%s' para '%s'. Se usa idle como fallback." % [canonical_name, visual_id]
			)
			if has_animation_safe("idle"):
				play("idle")
		return

	play(canonical_name)


func has_animation_safe(animation_name: String) -> bool:
	if sprite_frames == null:
		return false
	return sprite_frames.has_animation(_canonical_animation_name(animation_name))


func get_animation_frame_size(animation_name: String = "idle") -> Vector2:
	if sprite_frames == null:
		return Vector2.ZERO

	var canonical_name := _canonical_animation_name(animation_name)
	if not sprite_frames.has_animation(canonical_name):
		return Vector2.ZERO
	if sprite_frames.get_frame_count(canonical_name) <= 0:
		return Vector2.ZERO

	var frame_texture := sprite_frames.get_frame_texture(canonical_name, 0)
	if frame_texture == null:
		return Vector2.ZERO
	return Vector2(frame_texture.get_width(), frame_texture.get_height())


func _build_sprite_frames(character_visual_id: String) -> SpriteFrames:
	var folder_path := "%s/%s" % [SPRITES_ROOT, character_visual_id]
	var dir := DirAccess.open(folder_path)
	if dir == null:
		_warn_once("missing_folder_%s" % character_visual_id, "CombatCharacterAnimator: no existe carpeta visual '%s'." % folder_path)
		return null

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for animation_name in ANIMATIONS:
		var path := _find_spritesheet_path(folder_path, character_visual_id, animation_name)
		if path.is_empty():
			if _is_expected_missing_animation(character_visual_id, animation_name):
				continue
			if animation_name == "idle":
				_warn_once("missing_file_%s_%s" % [character_visual_id, animation_name], "CombatCharacterAnimator: falta '%s' en '%s'." % [animation_name, folder_path])
			else:
				_warn_once("missing_file_%s_%s" % [character_visual_id, animation_name], "CombatCharacterAnimator: falta animacion opcional '%s' en '%s'." % [animation_name, folder_path])
			continue

		_add_spritesheet_animation(frames, animation_name, path)

	return frames


func _find_spritesheet_path(folder_path: String, character_visual_id: String, animation_name: String) -> String:
	for prefix in FILE_PREFIXES.get(animation_name, [animation_name]):
		var path := "%s/%s_%s.png" % [folder_path, prefix, character_visual_id]
		if FileAccess.file_exists(path):
			return path
	return ""


func _add_spritesheet_animation(frames: SpriteFrames, animation_name: String, path: String) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		_warn_once("bad_texture_%s" % path, "CombatCharacterAnimator: no se pudo cargar '%s'." % path)
		return

	var texture_width := texture.get_width()
	var texture_height := texture.get_height()
	if texture_width < FRAME_COLUMNS or texture_height <= 0:
		_warn_once("bad_size_%s" % path, "CombatCharacterAnimator: spritesheet invalido '%s' (%dx%d)." % [path, texture_width, texture_height])
		return

	var frame_width := int(floor(float(texture_width) / float(FRAME_COLUMNS)))
	if frame_width <= 0:
		_warn_once("bad_frame_width_%s" % path, "CombatCharacterAnimator: frame width invalido en '%s'." % path)
		return

	var remainder := texture_width - frame_width * FRAME_COLUMNS
	if remainder != 0:
		_warn_once(
			"width_remainder_%s" % path,
			"CombatCharacterAnimator: '%s' ancho=%d no divide exacto en %d frames; se ignoran %d px sobrantes de borde." % [path, texture_width, FRAME_COLUMNS, remainder]
		)

	frames.add_animation(animation_name)
	var animation_fps: float = float(ANIMATION_SETTINGS[animation_name]["fps"]) * ANIMATION_SPEED_MULTIPLIER
	frames.set_animation_speed(animation_name, animation_fps)
	frames.set_animation_loop(animation_name, bool(ANIMATION_SETTINGS[animation_name]["loop"]))

	var image := texture.get_image()

	for frame_index in range(FRAME_COLUMNS):
		var frame_rect := Rect2i(frame_index * frame_width, 0, frame_width, texture_height)
		var frame_image: Image = image.get_region(frame_rect)
		var used_rect: Rect2i = frame_image.get_used_rect()
		
		var aligned_frame := image.get_region(Rect2i(0, 0, frame_width, texture_height))
		aligned_frame.fill(Color(0, 0, 0, 0))
		
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			var new_x: int = int((frame_width - used_rect.size.x) / 2.0)
			aligned_frame.blit_rect(frame_image, used_rect, Vector2i(new_x, used_rect.position.y))
			
		var tex := ImageTexture.create_from_image(aligned_frame)
		frames.add_frame(animation_name, tex)


func _canonical_animation_name(animation_name: String) -> String:
	var normalized := animation_name.strip_edges().to_lower()
	if normalized == "atack":
		return "attack"
	return normalized


func _is_expected_missing_animation(character_visual_id: String, animation_name: String) -> bool:
	if not EXPECTED_MISSING_ANIMATIONS.has(character_visual_id):
		return false
	return EXPECTED_MISSING_ANIMATIONS[character_visual_id].has(animation_name)


func _on_animation_finished() -> void:
	if animation == "death":
		if sprite_frames != null and sprite_frames.has_animation("death"):
			frame = max(sprite_frames.get_frame_count("death") - 1, 0)
		pause()
		death_animation_finished.emit()
		return

	if is_dead_visual:
		return

	if animation != "idle" and has_animation_safe("idle"):
		play("idle")


func _warn_once(key: String, message: String) -> void:
	if warned_messages.has(key):
		return
	warned_messages[key] = true
	push_warning(message)


func _ensure_signal_connected() -> void:
	if not animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)
