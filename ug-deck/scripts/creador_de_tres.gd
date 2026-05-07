extends Node

func _ready():
	print("Iniciando creación de archivos .tres universitarios...")
	
	# Usamos los índices numéricos de tu nuevo enum (0 al 5)
	_crear_y_guardar("clase_interactiva.tres", 0, "Clase Interactiva")
	_crear_y_guardar("examen_parcial.tres", 1, "Examen Parcial")
	_crear_y_guardar("kiosko.tres", 2, "Kiosko UGD")
	_crear_y_guardar("casilleros.tres", 3, "Casilleros")
	_crear_y_guardar("recreo.tres", 4, "Recreo")
	_crear_y_guardar("examen_final.tres", 5, "Examen Final")
	
	print("¡ÉXITO! Revisa tu carpeta res://resources/map/")

# ¡Esta es la función que faltaba!
func _crear_y_guardar(nombre_archivo: String, tipo_enum: int, nombre_visible: String):
	# Instanciamos un nuevo recurso en blanco usando tu clase
	var nuevo_recurso = nodo_mapa.new()
	
	# Le asignamos los valores
	nuevo_recurso.type = tipo_enum
	nuevo_recurso.node_name = nombre_visible
	
	# Guardamos el archivo en tu disco duro
	var ruta_completa = "res://resources/map/" + nombre_archivo
	ResourceSaver.save(nuevo_recurso, ruta_completa)
