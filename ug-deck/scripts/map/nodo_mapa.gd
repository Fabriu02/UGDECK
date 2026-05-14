#res://scripts/map/nodo_mapa.gd
class_name nodo_mapa
extends Resource
#las cosas estan puestas como en slay the spire, jueguenlo para guiarse :D
enum NodeType {
	CLASE_INTERACTIVA,  # Combate normal
	EXAMEN_PARCIAL,     # Combate elite o dificil
	KIOSKO,             # Tienda
	CASILLEROS,         #Tesoro
	RECREO,             #Fogata
	EXAMEN_FINAL        #Jefe final
}

@export var type: NodeType
@export var node_name: String
@export var icon: Texture2D # El icono que se mostrará en el mapa
@export var escena_nivel: PackedScene
