extends CanvasLayer
class_name GameOverOverlay

signal game_over_finished

const VIDEO_PATH := "res://assets/video/game_over/game_over_you_died.ogv"
const FALLBACK_DURATION := 1.6
const DARK_FADE_DURATION := 0.55
const VIDEO_FADE_DURATION := 0.45

@onready var root: Control = $Root
@onready var dark_overlay: ColorRect = $Root/DarkOverlay
@onready var video_player: VideoStreamPlayer = $Root/AspectRatioContainer/VideoStreamPlayer

var playback_started := false


func _ready() -> void:
	layer = 100
	visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_and_wait() -> void:
	if playback_started:
		return

	playback_started = true
	visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	dark_overlay.modulate.a = 0.0
	video_player.modulate.a = 0.0

	var stream: VideoStream = null
	var video_exists: bool = ResourceLoader.exists(VIDEO_PATH)
	if video_exists:
		stream = load(VIDEO_PATH) as VideoStream
	else:
		push_warning("GameOverOverlay: falta el video OGV '%s'. Se muestra fallback temporal." % VIDEO_PATH)

	if video_exists and stream == null:
		push_warning("GameOverOverlay: no se pudo cargar el video OGV '%s'." % VIDEO_PATH)

	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(dark_overlay, "modulate:a", 1.0, DARK_FADE_DURATION)
	await fade_tween.finished

	if stream == null:
		await get_tree().create_timer(FALLBACK_DURATION).timeout
		game_over_finished.emit()
		return

	video_player.stream = stream
	video_player.play()
	var video_tween: Tween = create_tween()
	video_tween.tween_property(video_player, "modulate:a", 1.0, VIDEO_FADE_DURATION)
	await video_player.finished
	game_over_finished.emit()
