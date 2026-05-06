extends Node
class_name Enemy

@export var max_hp: int = 50

var current_hp: int
var block: int = 0
var current_intent: String = "attack"
var intent_value: int = 8

# AGREGADO: Variable para guardar los estados (como "vulnerable")
var estados: Array = []

func _ready() -> void:
	reset_for_new_battle()

func reset_for_new_battle() -> void:
	current_hp = max_hp
	block = 0
	current_intent = "attack"
	intent_value = 8
	# AGREGADO: Limpiamos los estados al iniciar una batalla
	estados.clear()

# MODIFICADO: Ahora calcula si está vulnerable antes de restar la vida
func take_damage(amount: int) -> void:
	var daño_final := amount
	
	# AGREGADO: Si tiene el estado vulnerable, el daño aumenta un 50%
	if tiene_estado("vulnerable"):
		daño_final = int(daño_final * 1.5)
		
	var remaining_damage := daño_final

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)

# MODIFICADO: Agregada una 4ta opción al "dado" del enemigo
func choose_next_intent() -> void:
	var roll := randi_range(0, 3)

	if roll == 0:
		current_intent = "attack"
		intent_value = 8
	elif roll == 1:
		current_intent = "attack"
		intent_value = 12
	elif roll == 2:
		current_intent = "block"
		intent_value = 6
	else:
		current_intent = "debuff_estres"
		intent_value = 2 # Duración del estrés en turnos

# AGREGADO: Función para calcular el daño que hace el enemigo (aplicando debilidad)
func calcular_daño_enemigo(daño_base: int) -> int:
	var daño_final := float(daño_base)
	
	# Si el enemigo tiene el estado "debil", hace 25% menos de daño
	if tiene_estado("debil"):
		daño_final *= 0.75
		
	return int(daño_final)

# MODIFICADO: Lógica para ejecutar el debuff y el ataque considerando debilidad
func execute_intent(player: Player) -> void:
	if current_intent == "attack":
		# Usamos la nueva función para calcular el daño real
		player.take_damage(calcular_daño_enemigo(intent_value))
	elif current_intent == "block":
		block += intent_value
	elif current_intent == "debuff_estres":
		player.aplicar_estado("estres", 0, intent_value)

# MODIFICADO: Texto para la interfaz (ahora muestra el daño reducido si está débil)
func get_intent_text() -> String:
	if current_intent == "attack":
		return "Intencion: Atacar %d" % calcular_daño_enemigo(intent_value)
	if current_intent == "block":
		return "Intencion: Defenderse %d" % intent_value
	if current_intent == "debuff_estres":
		return "Intencion: Maldecir (Estres por %d turnos)" % intent_value

	return "Intencion: Desconocida"

func is_dead() -> bool:
	return current_hp <= 0

# NUEVAS FUNCIONES BÁSICAS: Para aplicar y consultar estados
func aplicar_estado(nombre: String, valor: int, duracion: int) -> void:
	estados.append({
		"nombre": nombre,
		"valor": valor,
		"duracion": duracion
	})

func tiene_estado(nombre: String) -> bool:
	for estado in estados:
		if estado.nombre == nombre:
			return true
	return false

func reducir_duracion_estados() -> void:
	for estado in estados:
		estado.duracion -= 1
		
	# Filtramos para quedarnos solo con los estados que aún tienen duración
	estados = estados.filter(func(estado): return estado.duracion > 0)
