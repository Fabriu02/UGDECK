extends Button
class_name CardUI

signal card_clicked(card_data: CardData, card_ui: CardUI)

var card_data: CardData

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(data: CardData) -> void:
	card_data = data

	if not is_node_ready():
		await ready

	name_label.text = data.card_name
	cost_label.text = "Coste: %d" % data.cost
	description_label.text = _build_card_text(data)


func _on_pressed() -> void:
	card_clicked.emit(card_data, self)


func _build_card_text(data: CardData) -> String:
	var parts: Array[String] = []

	if not data.raw_effect_text.is_empty():
		parts.append(data.raw_effect_text)

	if not data.description.is_empty():
		parts.append(data.description)

	return "\n\n".join(parts)
