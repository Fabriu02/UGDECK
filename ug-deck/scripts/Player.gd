extends Node
class_name Player

@export var max_hp: int = 80
@export var max_energy: int = 5

var current_hp: int
var current_energy: int
var block: int = 0
var attack_bonus: int = 0
# AGREGADO: Variable para el bonus fijo de defensa
var bonus_defensa: int = 0 
var attack_bonus_turns: int = 0
var next_attack_multiplier: float = 1.0
var approved_with_4_turns: int = 0
var skip_next_player_turn: bool = false
var immune_to_enemy_attack_turns: int = 0

# AGREGADO: Variable para guardar los estados (como "estres" o "distraccion")
var estados: Array = []

func _ready() -> void:
	reset_for_new_battle()

func reset_for_new_battle() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = 0
	attack_bonus = 0
	bonus_defensa = 0 # AGREGADO: Reset del bonus de defensa
	attack_bonus_turns = 0
	next_attack_multiplier = 1.0
	approved_with_4_turns = 0
	skip_next_player_turn = false
	immune_to_enemy_attack_turns = 0
	# AGREGADO: Limpiamos los estados al iniciar una batalla
	estados.clear()

func reset_for_new_turn() -> void:
	block = 0
	current_energy = max_energy
	
	# AGREGADO: Lógica de Cansancio (-1 de energía al inicio del turno)
	if tiene_estado("cansancio"):
		current_energy = max(0, current_energy - 1)

	if attack_bonus_turns > 0:
		attack_bonus_turns -= 1
		if attack_bonus_turns == 0:
			attack_bonus = 0

	if approved_with_4_turns > 0:
		approved_with_4_turns -= 1

# MODIFICADO: Ahora incluye la reducción de daño por el estado "Débil"
func get_attack_damage(base_damage: int) -> int:
	var total_damage := float(base_damage + attack_bonus)
	
	# Si tiene el estado debil, hace 25% menos de daño
	if tiene_estado("debil"):
		total_damage *= 0.75
		
	total_damage = ceil(total_damage * next_attack_multiplier)
	next_attack_multiplier = 1.0
	return int(total_damage)

func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false

	current_energy -= amount
	return true

# MODIFICADO: Agregada la lógica de Bonus de Defensa y Distracción
func gain_block(amount: int) -> void:
	var escudo_final := float(amount + bonus_defensa)
	
	# Si tiene el estado distraccion, gana 25% menos de escudo
	if tiene_estado("distraccion"):
		escudo_final *= 0.75
		
	block += int(escudo_final)

# AGREGADO: Función para curar vida en combate
func curar(cantidad: int) -> void:
	var curacion_final := float(cantidad)
	
	# Si está cansado, se cura un 25% menos
	if tiene_estado("cansancio"):
		curacion_final *= 0.75
		
	current_hp = min(current_hp + int(curacion_final), max_hp)

func lose_hp(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	_apply_approved_with_4_if_needed()

func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp = min(current_hp + amount, max_hp)

# AGREGADO: Nueva lógica para aumentar la energía máxima
func increase_max_energy(amount: int) -> void:
	max_energy += amount
	current_energy += amount

# MODIFICADO: Agregada la lógica de Estrés
func take_damage(amount: int) -> void:
	if immune_to_enemy_attack_turns > 0:
		immune_to_enemy_attack_turns -= 1
		return

	var remaining_damage := amount

	# Si tiene el estado estres, recibe 25% más de daño
	if tiene_estado("estres"):
		remaining_damage = int(remaining_damage * 1.25)

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)
		_apply_approved_with_4_if_needed()

func _apply_approved_with_4_if_needed() -> void:
	if current_hp <= 0 and approved_with_4_turns > 0:
		current_hp = 4
		approved_with_4_turns = 0

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
