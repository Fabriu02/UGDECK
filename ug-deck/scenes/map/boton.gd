extends TextureButton

signal node_clicked(node_data)

var node_data: Dictionary

func setup(data: Dictionary):
	node_data = data
	var resource: nodo_mapa = node_data.resource
	if resource:
		texture_normal = resource.icon
		tooltip_text = resource.node_name

func _pressed():
	node_clicked.emit(node_data)
