extends PanelContainer
class_name StatusEffectPopup

const STATUS_EFFECT_INFO_SCRIPT := preload("res://scripts/ui/StatusEffectInfo.gd")

var title_label: Label
var description_label: Label
var meta_label: Label
var close_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(260, 108)
	z_index = 200
	visible = false
	_build()


func show_status(state: Dictionary, local_position: Vector2) -> void:
	if title_label == null:
		_build()

	title_label.text = STATUS_EFFECT_INFO_SCRIPT.get_title(state)
	description_label.text = STATUS_EFFECT_INFO_SCRIPT.get_description(state)
	meta_label.text = STATUS_EFFECT_INFO_SCRIPT.get_meta_text(state)
	meta_label.visible = not meta_label.text.is_empty()
	position = local_position
	visible = true


func hide_popup() -> void:
	visible = false


func _build() -> void:
	if title_label != null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.09, 0.96)
	style.border_color = Color(0.72, 0.72, 0.72, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 15)
	header.add_child(title_label)

	close_button = Button.new()
	close_button.text = "x"
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(hide_popup)
	header.add_child(close_button)

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92, 1.0))
	vbox.add_child(description_label)

	meta_label = Label.new()
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0, 1.0))
	vbox.add_child(meta_label)
