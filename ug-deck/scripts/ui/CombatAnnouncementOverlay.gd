extends CanvasLayer
class_name CombatAnnouncementOverlay

const TITLE_COLOR := Color(1.0, 0.72, 0.24, 1.0)
const SUBTITLE_COLOR := Color(0.88, 0.86, 0.78, 1.0)
const BAND_COLOR := Color(0.04, 0.025, 0.018, 0.76)
const ENTER_DURATION := 0.20
const HOLD_DURATION := 0.68
const EXIT_DURATION := 0.30
const TITLE_FONT_SIZE := 46
const SUBTITLE_FONT_SIZE := 22
const OUTLINE_SIZE := 5

@onready var root: Control = $Root
@onready var center_band: ColorRect = $Root/CenterBand
@onready var text_container: VBoxContainer = $Root/CenterBand/TextContainer
@onready var title_label: Label = $Root/CenterBand/TextContainer/TitleLabel
@onready var subtitle_label: Label = $Root/CenterBand/TextContainer/SubtitleLabel

var is_playing := false


func _ready() -> void:
	layer = 80
	visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_band.color = BAND_COLOR
	_configure_label(title_label, TITLE_COLOR, TITLE_FONT_SIZE)
	_configure_label(subtitle_label, SUBTITLE_COLOR, SUBTITLE_FONT_SIZE)


func play_announcement(title: String, subtitle: String = "") -> void:
	if is_playing:
		return

	is_playing = true
	visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()

	root.modulate.a = 0.0
	center_band.scale = Vector2(0.72, 1.0)
	text_container.scale = Vector2(0.95, 0.95)
	text_container.modulate.a = 0.0

	await get_tree().process_frame
	center_band.pivot_offset = center_band.size / 2.0
	text_container.pivot_offset = text_container.size / 2.0

	var enter_tween := create_tween()
	enter_tween.set_parallel(true)
	enter_tween.tween_property(root, "modulate:a", 1.0, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(center_band, "scale", Vector2.ONE, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(text_container, "scale", Vector2.ONE, ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(text_container, "modulate:a", 1.0, ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await enter_tween.finished

	await get_tree().create_timer(HOLD_DURATION).timeout

	var exit_tween := create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(root, "modulate:a", 0.0, EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(center_band, "scale", Vector2(0.88, 1.0), EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(text_container, "modulate:a", 0.0, EXIT_DURATION * 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await exit_tween.finished

	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	root.modulate.a = 1.0
	center_band.scale = Vector2.ONE
	text_container.scale = Vector2.ONE
	text_container.modulate.a = 1.0
	is_playing = false


func _configure_label(label: Label, font_color: Color, font_size: int) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_font_size_override("font_size", font_size)
