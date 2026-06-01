extends Button
class_name CardUI

signal card_clicked(card_data: CardData, card_ui: CardUI)

# Region visible de la carta dentro de la imagen 800x800, ajustada con un margen
# de seguridad para evitar recortes en la energia y bordes de todas las rarezas.
const CARD_CROP_REGION := Rect2(200, 128, 376, 468)

var card_data: CardData
var _full_card_image: TextureRect = null

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var card_image: TextureRect = $MarginContainer/VBoxContainer/ArtFrame/CardImage
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var art_frame: PanelContainer = $MarginContainer/VBoxContainer/ArtFrame
@onready var margin_container: MarginContainer = $MarginContainer


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(data: CardData) -> void:
	card_data = data

	if not is_node_ready():
		await ready

	name_label.text = data.card_name
	cost_label.text = "Coste: %d" % data.cost
	description_label.text = _build_card_text(data)
	_update_card_image(data)


func _update_card_image(data: CardData) -> void:
	card_image.texture = null
	card_image.visible = false

	# Limpiar imagen previa si existia
	if _full_card_image != null:
		_full_card_image.queue_free()
		_full_card_image = null

	if data.image_path.is_empty() or not ResourceLoader.exists(data.image_path):
		# Sin imagen: mostrar layout de texto normal
		margin_container.visible = true
		name_label.visible = true
		cost_label.visible = true
		description_label.visible = true
		return

	var loaded_resource: Resource = ResourceLoader.load(data.image_path)
	if not loaded_resource is Texture2D:
		margin_container.visible = true
		name_label.visible = true
		cost_label.visible = true
		description_label.visible = true
		return

	# Imagen disponible: ocultar todo el contenido de texto
	margin_container.visible = false

	# Hacer el fondo del boton transparente
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("focus", empty_style)
	add_theme_stylebox_override("disabled", empty_style)

	# Recortar la imagen al area visible de la carta (sin transparencias)
	var atlas := AtlasTexture.new()
	atlas.atlas = loaded_resource as Texture2D
	atlas.region = CARD_CROP_REGION

	# Crear un TextureRect que llena todo el boton con la carta recortada
	_full_card_image = TextureRect.new()
	_full_card_image.texture = atlas
	_full_card_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_full_card_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_full_card_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_card_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_full_card_image)


func _on_pressed() -> void:
	card_clicked.emit(card_data, self)


func _build_card_text(data: CardData) -> String:
	var parts: Array[String] = []

	if not data.raw_effect_text.is_empty():
		parts.append(data.raw_effect_text)

	if not data.description.is_empty():
		parts.append(data.description)

	return "\n\n".join(parts)
